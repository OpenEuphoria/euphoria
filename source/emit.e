-- (c) Copyright - See License.txt
--
-- Routines to emit the IL opcode stream

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include std/os.e

include global.e
include platform.e
include pathopen.e
include reswords.e as rw
include symtab.e
include scanner.e
include fwdref.e
include parser.e
include error.e
include c_out.e
include block.e
include shift.e
include coverage.e

export integer op_info1, op_info2
export integer optimized_while
export integer trace_called = FALSE
export integer last_routine_id = 0
export integer max_params = 0  -- maximum number of parameters in user routines
export integer last_max_params = 0
export sequence current_sequence = {}  -- stack needed by $ operation
export  boolean lhs_ptr = FALSE  -- are we parsing multiple LHS subscripts?
-- temps needed for LHS subscripting
export symtab_index lhs_subs1_copy_temp, lhs_target_temp
-- Code generation Stack
sequence cg_stack -- expression stack
integer cgi -- expression stack top-of-stack index

boolean assignable  = FALSE  -- did previous op have a re-assignable result?

constant LEX_NUMBER = 1
constant LEX_NAME = 2

previous_op = -1

-- descriptive names for scanner tokens - keep up-to-date
constant token_name =
{
	{AND, "and"},
	{ATOM, "a number"},
	{BANG, "!"},
	{BREAK, "break"},
	{BY, "by"},
	{CASE, "case"},
	{COLON, ":"},
	{COMMA, ","},
	{rw:CONCAT, "&"},
	{CONCAT_EQUALS,"&="},
	{CONSTANT, "constant"},
	{CONTINUE, "continue"},
	{rw:DIVIDE, "/"},
	{DIVIDE_EQUALS,"/="},
	{DO, "do"},
	{DOLLAR, "$"},
	{ELSE, "else"},
	{ELSEDEF, "elsedef"},
	{ELSIF, "elsif"},
	{ELSIFDEF, "elsifdef"},
	{END, "end"},
	{END_OF_FILE, "the end of file"},
	{ENTRY, "entry"},
	{ENUM, "enum"},
	{EQUALS, "="},
	{EXIT, "exit"},
	{FOR, "for"},
	{FUNC, "a function"},
	{FUNCTION, "function"},
	{GLABEL, "label"},
	{GLOBAL, "global"},
	{GOTO, "goto"},
	{GREATER, ">"},
	{GREATEREQ, ">="},
	{IF,  "if"},
	{IFDEF, "ifdef"},
	{ILLEGAL_CHAR, "an illegal character"},
	{INCLUDE, "include"},
	{LEFT_BRACE, "{"},
	{LEFT_ROUND, "("},
	{LEFT_SQUARE, "["},
	{LESS, "<"},
	{LESSEQ, "<="},
	{LOOP, "loop"},
	{MINUS, "-"},
	{MINUS_EQUALS,"-="},
	{rw:MULTIPLY, "*"},
	{MULTIPLY_EQUALS,"*="},
	{NAMESPACE, "a namespace qualifier"},
	{NEWLINE, "the end of a line"},
	{NOT, "not"},
	{NOTEQ, "!="},
	{OR, "or"},
	{PLUS, "+"},
	{PLUS_EQUALS,"+="},
	{PROC, "a procedure"},
	{PROCEDURE, "procedure"},
	{QUALIFIED_VARIABLE, "a variable"},
	{QUALIFIED_FUNC, "a function"},
	{QUALIFIED_PROC, "a procedure"},
	{QUALIFIED_TYPE, "a type"},
	{RETRY, "retry"},
	{RETURN, "return"},
	{RIGHT_BRACE, "}"},
	{RIGHT_ROUND, ")"},
	{RIGHT_SQUARE, "]"},
	{ROUTINE, "routine"},
	{SLICE, "a slice"},
	{STRING, "a character string"},
	{SWITCH, "switch"},
	{TO, "to"},
	{THEN, "then"},
	{TYPE, "a type"},
	{UNTIL, "until"},
	{TYPE_DECL, "type"},
	{VARIABLE, "a variable"},
	{WITH, "with"},
	{WITHOUT, "without"},
	{WHILE, "while"},
	{'?', "?"}
}

export procedure Push(symtab_pointer x)
-- Push element onto code gen stack
	cgi += 1
	if cgi > length(cg_stack) then
		cg_stack &= repeat(0, 400)
	end if
	cg_stack[cgi] = x

end procedure

export function Empty()
	return cgi = 0
end function

export function Top()
-- return top element on code gen stack
	return cg_stack[cgi]
end function

export function Pop()
-- Pop top element from code gen stack
	symtab_pointer t


	t = cg_stack[cgi]
	cgi -= 1
	if t > 0 then
		symtab_index s = t -- for type checking
		if SymTab[t][S_MODE] = M_TEMP then
			if use_private_list = 0 then  -- no problem with reusing the temp
				SymTab[t][S_SCOPE] = FREE -- mark it as being free
								-- n.b. we assume one copy of temp on stack
								-- temps are normally not Popped & Pushed back on stack
								-- but see TempKeep() and TempFree() above
			elsif find(t, private_sym) = 0 then
			-- don't mark as free if the temp could be reused in default parm expressions
				SymTab[t][S_SCOPE] = FREE -- mark it as being free
			end if
		end if
	end if
	return t
end function

export procedure TempKeep(symtab_index x)
	if x > 0 and SymTab[x][S_MODE] = M_TEMP then
		SymTab[x][S_SCOPE] = IN_USE
	end if
end procedure

export procedure TempFree(symtab_index x)
	if x > 0 then
		if SymTab[x][S_MODE] = M_TEMP then
			SymTab[x][S_SCOPE] = FREE
			clear_temp( x )
		end if
	end if
end procedure

procedure TempInteger(symtab_index x)
	if x > 0 and SymTab[x][S_MODE] = M_TEMP then
		SymTab[x][S_USAGE] = T_INTEGER
	end if
end procedure


export function LexName(integer t, sequence defname = "this ...")
-- returns token name given token number
	sequence name
	for i = 1 to length(token_name) do
		if t = token_name[i][LEX_NUMBER] then
			name = token_name[i][LEX_NAME]
			if not find(' ', name) then
				name = "'" & name & "'"
			end if
			return name
		end if
	end for
	return defname -- try to avoid this case

end function

export procedure InitEmit()
-- initialize code emission
	cg_stack = repeat(0, 400)
	cgi = 0
end procedure

function IsInteger(symtab_index sym)
-- return TRUE if sym is known to be of integer type
	integer mode
	symtab_index t, pt

	if sym < 1 then
		-- probably a forward reference
		return 0
	end if

	mode = SymTab[sym][S_MODE]
	if mode = M_NORMAL then
		t = SymTab[sym][S_VTYPE]
		if t = integer_type then
			return TRUE
		end if
		if t > 0 then
			pt = SymTab[t][S_NEXT]
			if pt and SymTab[pt][S_VTYPE] = integer_type then
				return TRUE   -- usertype(integer x)
			end if
		end if

	elsif mode = M_CONSTANT then
		if integer(SymTab[sym][S_OBJ]) then  -- bug fixed: can't allow PLUS1_I op
			return TRUE
		end if

	elsif mode = M_TEMP then
		if SymTab[sym][S_USAGE] = T_INTEGER then
			return TRUE
		end if
	end if

	return FALSE
end function

-- n.b. I don't enforce ATOM type unless type_check is on,
-- so it won't be proper to assume that a value is going
-- to be ATOM at run-time, based on type declarations or temp info.
-- Therefore "IsAtom()" would be questionable except maybe for constants.

procedure emit(integer val)
-- emit a value into the code stream
	Code = append(Code, val)
end procedure

-- When looking at previous_op, make sure that there
-- can be no jump around the previous op to the current op.
-- i.e. it is not always *really* the previous op executed
-- - BE CAREFUL! Often there must be some expression (opnd)
-- prior to the current op.

export procedure emit_opnd(symtab_pointer opnd)
-- emit an operand into the IL
		Push(opnd)
		previous_op = -1  -- N.B.
end procedure

export procedure emit_addr(atom x)
	--if Parser_mode != PAM_RECORD then
		Code = append(Code, x)
end procedure

procedure emit_opcode(integer op)
-- emit an opcode into the IL
	Code = append(Code, op)
end procedure

export constant
	NO_REFERENCE = 0,
	NEW_REFERENCE = 1,
	DISCARD_TEMP = 0,
	SAVE_TEMP = 1

type temporary_stack_entry( object s )
	if atom(s) then
		return FALSE
	end if
	if length(s)>100 then -- its too long
		return FALSE
	end if
	if length(s)>1 and equal(s[$],s[$-1]) then
		return FALSE
	end if
	return TRUE
end type

temporary_stack_entry emitted_temps = {}
sequence emitted_temp_referenced = {}
export procedure emit_temp( object tempsym, integer referenced )
	if not TRANSLATE  then -- translator has its own way of handling temps
		if sequence(tempsym) then
			for i = 1 to length(tempsym) do
				emit_temp( tempsym[i], referenced )
			end for

		elsif tempsym > 0
		and sym_mode( tempsym ) = M_TEMP
		and not IsInteger( tempsym )
		and not find( tempsym, emitted_temps )
		then
			-- don't really care about integer temps
			emitted_temps &= tempsym
			emitted_temp_referenced &= referenced
		end if

	end if
end procedure


sequence derefs = {}

--**
-- Called by the parser after a complete statement.  Emits appropriate
-- opcode + temp sym to clean up after a temp.
export procedure flush_temps( sequence except_for = {} )
	if TRANSLATE then
		return
	end if
-- 	sequence syms = map:keys( emitted_temps )
	sequence
		refs = {},
		novalues = {}

	derefs = {}
	for i = 1 to length( emitted_temps ) do
		symtab_index sym = emitted_temps[i]

		if find( sym, except_for ) then
			continue
		end if

		if emitted_temp_referenced[i] = NEW_REFERENCE then
			derefs &= sym
		else
			novalues &= sym
		end if
	end for

	if not length( except_for ) then
		clear_last()
	end if

	for i = 1 to length( derefs ) do
		emit( DEREF_TEMP )
		emit( derefs[i] )
	end for

	for i = 1 to length( novalues ) do
		emit( NOVALUE_TEMP )
		emit( novalues[i] )
	end for

	emitted_temps = {}
	emitted_temp_referenced = {}
end procedure

procedure flush_temp( symtab_index temp )
	sequence except_for = emitted_temps
	integer ix = find( temp, emitted_temps )
	if ix then
		flush_temps( remove( except_for, ix ) )
	end if
end procedure

procedure check_for_temps()
	if TRANSLATE or last_op < 1 or last_pc < 1 then
		return
	end if
	emit_temp( get_target_sym( current_op( last_pc ) ), op_temp_ref[last_op] )

end procedure

export procedure clear_temp( symtab_pointer tempsym )
	integer ix = find( tempsym, emitted_temps )
	if ix then
		emitted_temps = remove( emitted_temps, ix )
		emitted_temp_referenced = remove( emitted_temp_referenced, ix )
	end if
end procedure

--**
-- Returns a sequence containing maps holding the current knowledge
-- about temps and removes all of the temps from the stack.
export function pop_temps()
	sequence new_emitted  = emitted_temps
	sequence new_referenced = emitted_temp_referenced

	emitted_temps  = {}
	emitted_temp_referenced = {}
	return { new_emitted, new_referenced }
end function

--**
-- Returns a sequence containing maps holding the current knowledge
-- about temps.  The optional parameter add_to will concatenate the
-- data to a result from a previous call to get_temps() or pop_temps()
-- to accumulate a bigger list of temps.
export function get_temps( sequence add_to = repeat( "", 2 ) )
	add_to[1] &= emitted_temps
	add_to[2] &= emitted_temp_referenced
	return add_to
end function

--**
-- temps is a sequence of two maps that was passed by pop_temps().
-- Flushes any temps waiting to be flushed, then flushes all of the
-- temps in the maps contained in the ##temps## sequence.
export procedure push_temps( sequence temps )
	emitted_temps &= temps[1]
	emitted_temp_referenced &= temps[2]
	flush_temps()
end procedure

export procedure backpatch(integer index, integer val)
-- back patch a word of code
		Code[index] = val
end procedure

sequence op_result  -- result types of operators
op_result = repeat(T_UNKNOWN, MAX_OPCODE)
-- the operation must *always* return this type, regardless of input
op_result[RIGHT_BRACE_N] = T_SEQUENCE
op_result[RIGHT_BRACE_2] = T_SEQUENCE
op_result[REPEAT] = T_SEQUENCE
op_result[rw:APPEND] = T_SEQUENCE
op_result[RHS_SLICE] = T_SEQUENCE
op_result[rw:CONCAT] = T_SEQUENCE
op_result[CONCAT_N] = T_SEQUENCE
op_result[PREPEND] = T_SEQUENCE
op_result[COMMAND_LINE] = T_SEQUENCE
op_result[OPTION_SWITCHES] = T_SEQUENCE
op_result[SPRINTF] = T_SEQUENCE
op_result[ROUTINE_ID] = T_INTEGER
op_result[GETC] = T_INTEGER
op_result[OPEN] = T_ATOM
op_result[LENGTH] = T_INTEGER   -- assume less than a billion
op_result[PLENGTH] = T_INTEGER  -- ""
op_result[IS_AN_OBJECT] = T_INTEGER
op_result[IS_AN_ATOM] = T_INTEGER
op_result[IS_A_SEQUENCE] = T_INTEGER
op_result[COMPARE] = T_INTEGER
op_result[EQUAL] = T_INTEGER
op_result[FIND] = T_INTEGER
op_result[FIND_FROM] = T_INTEGER
op_result[MATCH]  = T_INTEGER
op_result[MATCH_FROM]  = T_INTEGER
op_result[GET_KEY] = T_INTEGER
op_result[IS_AN_INTEGER] = T_INTEGER
op_result[ASSIGN_I] = T_INTEGER
op_result[RHS_SUBS_I] = T_INTEGER
op_result[PLUS_I] = T_INTEGER
op_result[MINUS_I] = T_INTEGER
op_result[PLUS1_I] = T_INTEGER
op_result[SYSTEM_EXEC] = T_INTEGER
op_result[TIME] = T_ATOM
op_result[TASK_STATUS] = T_INTEGER
op_result[TASK_SELF] = T_ATOM
op_result[TASK_CREATE] = T_ATOM
op_result[TASK_LIST] = T_SEQUENCE
op_result[PLATFORM] = T_INTEGER
op_result[SPLICE] = T_SEQUENCE
op_result[INSERT] = T_SEQUENCE
op_result[HASH] = T_ATOM
op_result[HEAD] = T_SEQUENCE
op_result[TAIL] = T_SEQUENCE
op_result[REMOVE] = T_SEQUENCE
op_result[REPLACE] = T_SEQUENCE

sequence op_temp_ref = repeat( NO_REFERENCE, MAX_OPCODE )
op_temp_ref[RIGHT_BRACE_N]    = NEW_REFERENCE
op_temp_ref[RIGHT_BRACE_2]    = NEW_REFERENCE
op_temp_ref[PLUS1]            = NEW_REFERENCE
op_temp_ref[ASSIGN]           = NEW_REFERENCE
op_temp_ref[ASSIGN_OP_SLICE]  = NEW_REFERENCE
op_temp_ref[PASSIGN_OP_SLICE] = NEW_REFERENCE
op_temp_ref[ASSIGN_SLICE]     = NEW_REFERENCE
op_temp_ref[PASSIGN_SLICE]    = NEW_REFERENCE
op_temp_ref[PASSIGN_SUBS]     = NEW_REFERENCE
op_temp_ref[PASSIGN_OP_SUBS]  = NEW_REFERENCE
op_temp_ref[ASSIGN_SUBS]      = NEW_REFERENCE
op_temp_ref[ASSIGN_OP_SUBS]   = NEW_REFERENCE
op_temp_ref[RHS_SLICE]        = NEW_REFERENCE
op_temp_ref[RHS_SUBS]         = NEW_REFERENCE
op_temp_ref[RHS_SUBS_CHECK]   = NEW_REFERENCE
op_temp_ref[rw:APPEND]        = NEW_REFERENCE
op_temp_ref[rw:PREPEND]       = NEW_REFERENCE
op_temp_ref[rw:CONCAT]        = NEW_REFERENCE
op_temp_ref[INSERT]           = NEW_REFERENCE
op_temp_ref[HEAD]             = NEW_REFERENCE
op_temp_ref[REMOVE]           = NEW_REFERENCE
op_temp_ref[REPLACE]          = NEW_REFERENCE
op_temp_ref[TAIL]             = NEW_REFERENCE
op_temp_ref[CONCAT_N]         = NEW_REFERENCE
op_temp_ref[REPEAT]           = NEW_REFERENCE
op_temp_ref[HASH]             = NEW_REFERENCE
op_temp_ref[PEEK_STRING]      = NEW_REFERENCE
op_temp_ref[PEEK]             = NEW_REFERENCE
op_temp_ref[PEEK2U]           = NEW_REFERENCE
op_temp_ref[PEEK2S]           = NEW_REFERENCE
op_temp_ref[PEEK4U]           = NEW_REFERENCE
op_temp_ref[PEEK4S]           = NEW_REFERENCE
op_temp_ref[PEEK8U]           = NEW_REFERENCE
op_temp_ref[PEEK8S]           = NEW_REFERENCE
op_temp_ref[PEEK_POINTER]     = NEW_REFERENCE
op_temp_ref[OPEN]             = NEW_REFERENCE
op_temp_ref[GETS]             = NEW_REFERENCE
op_temp_ref[SPRINTF]          = NEW_REFERENCE
op_temp_ref[COMMAND_LINE]     = NEW_REFERENCE
op_temp_ref[OPTION_SWITCHES]  = NEW_REFERENCE
op_temp_ref[GETENV]           = NEW_REFERENCE
op_temp_ref[MACHINE_FUNC]     = NEW_REFERENCE
op_temp_ref[DELETE_ROUTINE]   = NEW_REFERENCE
op_temp_ref[C_FUNC]           = NEW_REFERENCE
op_temp_ref[TASK_CREATE]      = NEW_REFERENCE
op_temp_ref[TASK_SELF]        = NEW_REFERENCE
op_temp_ref[TASK_LIST]        = NEW_REFERENCE
op_temp_ref[TASK_STATUS]      = NEW_REFERENCE
op_temp_ref[rw:MULTIPLY]      = NEW_REFERENCE
op_temp_ref[PLUS1]            = NEW_REFERENCE
op_temp_ref[DIV2]             = NEW_REFERENCE
op_temp_ref[FLOOR_DIV2]       = NEW_REFERENCE
op_temp_ref[PLUS]             = NEW_REFERENCE
op_temp_ref[MINUS]            = NEW_REFERENCE
op_temp_ref[OR]               = NEW_REFERENCE
op_temp_ref[XOR]              = NEW_REFERENCE
op_temp_ref[AND]              = NEW_REFERENCE
op_temp_ref[rw:DIVIDE]        = NEW_REFERENCE
op_temp_ref[REMAINDER]        = NEW_REFERENCE
op_temp_ref[FLOOR_DIV]        = NEW_REFERENCE
op_temp_ref[AND_BITS]         = NEW_REFERENCE
op_temp_ref[OR_BITS]          = NEW_REFERENCE
op_temp_ref[XOR_BITS]         = NEW_REFERENCE
op_temp_ref[NOT_BITS]         = NEW_REFERENCE
op_temp_ref[POWER]            = NEW_REFERENCE
op_temp_ref[LESS]             = NEW_REFERENCE
op_temp_ref[GREATER]          = NEW_REFERENCE
op_temp_ref[EQUALS]           = NEW_REFERENCE
op_temp_ref[NOTEQ]            = NEW_REFERENCE
op_temp_ref[LESSEQ]           = NEW_REFERENCE
op_temp_ref[GREATEREQ]        = NEW_REFERENCE
op_temp_ref[FOR]              = NEW_REFERENCE
op_temp_ref[ENDFOR_GENERAL]   = NEW_REFERENCE
op_temp_ref[LHS_SUBS1]        = NEW_REFERENCE
op_temp_ref[LHS_SUBS1_COPY]   = NEW_REFERENCE
op_temp_ref[LHS_SUBS]         = NEW_REFERENCE
op_temp_ref[UMINUS]           = NEW_REFERENCE
op_temp_ref[TIME]             = NEW_REFERENCE
op_temp_ref[SPLICE]           = NEW_REFERENCE
op_temp_ref[PROC]             = NEW_REFERENCE
op_temp_ref[SIN]              = NEW_REFERENCE
op_temp_ref[COS]              = NEW_REFERENCE
op_temp_ref[TAN]              = NEW_REFERENCE
op_temp_ref[ARCTAN]           = NEW_REFERENCE
op_temp_ref[LOG]              = NEW_REFERENCE
op_temp_ref[GETS]             = NEW_REFERENCE
op_temp_ref[GETENV]           = NEW_REFERENCE
op_temp_ref[RAND]             = NEW_REFERENCE

procedure cont11ii(integer op, boolean ii)
-- if ii is TRUE then integer arg always produces integer result
	integer t, source, c

	emit_opcode(op)
	source = Pop()
	emit_addr(source)
	assignable = TRUE
	t = op_result[op]

	 -- for PEEK should really check for IsAtom(source)
	if t = T_INTEGER or (ii and IsInteger(source)) then
		c = NewTempSym()
		TempInteger(c)
	else
		c = NewTempSym() -- allocate *after* checking opnd type
	end if

	Push(c)
	emit_addr(c)
end procedure

procedure cont21d(integer op, integer a, integer b, boolean ii)
	integer c, t

	assignable = TRUE
	t = op_result[op]
	if op = C_FUNC then
		emit_addr(CurrentSub)
	end if
	if t = T_INTEGER or (ii and IsInteger(a) and IsInteger(b)) then
		c = NewTempSym()
		TempInteger(c)
	else
		c = NewTempSym() -- allocate *after* checking opnd types
	end if
	Push(c)
	emit_addr(c)
end procedure

procedure cont21ii(integer op, boolean ii)
	integer a, b

	b = Pop()
	emit_opcode(op)
	a = Pop()
	emit_addr(a)
	emit_addr(b)
	cont21d(op, a, b, ii)
end procedure

function good_string(sequence elements)
-- are all elements suitable for a string?
	object obj
	symtab_pointer ep
	symtab_index e
	sequence element_vals

	if TRANSLATE and length(elements) > 10000 then
		return -1 -- A huge string might upset the C compiler.
	end if
	element_vals = {}
	for i = 1 to length(elements) do
		ep = elements[i]
		if ep < 1 then
			-- if there's a forward reference, assume false
			return -1
		end if
		e = ep
		obj = SymTab[e][S_OBJ]
		if SymTab[e][S_MODE] = M_CONSTANT and
		   integer(obj) and
		   (not TRANSLATE or
			(obj >= 1 and obj <= 255)) then
			-- Non C chars are currently inconvenient in TRANSLATOR.
			element_vals = prepend(element_vals, obj)
		else
			return -1
		end if
	end for
	return element_vals
end function

integer last_op = 0
integer last_pc = 0
export function Last_op()
	return last_op
end function

export function Last_pc()
	return last_pc
end function

export procedure move_last_pc( integer amount )
	if last_pc > 0 then
		last_pc += amount
	end if
end procedure

export procedure clear_last()
	last_op = 0
	last_pc = 0
end procedure

export procedure clear_op()
	previous_op = -1
	assignable = FALSE
end procedure

boolean inlined = FALSE
export procedure inlined_function()
	previous_op = PROC
	assignable = TRUE
	inlined = TRUE
end procedure

sequence inlined_targets = {}
export procedure add_inline_target( integer pc )
	inlined_targets &= pc
end procedure

export procedure clear_inline_targets()
	inlined_targets = {}
end procedure

export procedure emit_inline( sequence code )
	last_pc = 0
	last_op = 0
	Code &= code
end procedure

export procedure emit_op(integer op)
-- Emit a postfix operator.
-- The cases have been sorted according to profile frequency.
-- About 60% of the time it's one of the first 6 cases.
-- You might get greater speed by converting the chain of elsif's
-- to a single call_proc(), as in execute.e.
	symtab_pointer a, b, c, d, source, target, subsym
	symtab_pointer lhs_var
	integer ib, ic, n
	object obj
	sequence elements
	object element_vals

	check_for_temps()
	integer last_pc_backup = last_pc
	integer last_op_backup = last_op

	last_op = op
	last_pc = length(Code) + 1
	-- 1 input, 0 outputs, can combine with previous op
	switch op label "EMIT" do
	case ASSIGN then
		symtab_index temp = 0
		if not TRANSLATE and
				(previous_op = RHS_SUBS_CHECK
					or previous_op = RHS_SUBS )
		then
			if Code[$-1] = DEREF_TEMP and find( Code[$], derefs ) then
				/* the DEREF_TEMP op interferes with the ASSIGN op, so
				 * we'll clean it up here and re-flush later */
				temp = Code[$]
				Code = Code[1..$-2]
				emit_temp( temp, NEW_REFERENCE )
			end if
		end if

		source = Pop()
		target = Pop()
		if assignable then

			if inlined then
				inlined = 0
				if length( inlined_targets ) then
					for i = 1 to length( inlined_targets ) do
						Code[inlined_targets[i]] = target
					end for
					clear_inline_targets()

				end if
				assignable = FALSE
				clear_last()
				break "EMIT"
			end if
			-- replace previous op (temp) target with ASSIGN target
			clear_temp( Code[$] )
			Code = remove( Code, length( Code ) ) -- drop previous target
			op = previous_op -- keep same previous op
			if IsInteger(target) then
				if previous_op = RHS_SUBS then
					op = RHS_SUBS_I
					backpatch(length(Code) - 2, op)

				elsif previous_op = PLUS1 then
					op = PLUS1_I
					backpatch(length(Code) - 2, op)

				elsif previous_op = PLUS or previous_op = MINUS then
					if IsInteger(Code[$]) and
					   IsInteger(Code[$-1]) then
						if previous_op = PLUS then
							op = PLUS_I
						else
							op = MINUS_I
						end if
						backpatch(length(Code) - 2, op)
					end if

				else
					-- if target to-be-overwritten was integer then avoid
					-- INTEGER_CHECK and ATOM_CHECK
					if IsInteger(source) then
						op = ASSIGN_I -- fake to avoid subsequent check
					end if
				end if
			end if
			last_op = last_op_backup
			last_pc = last_pc_backup
		else
			if IsInteger(source) and IsInteger(target) then
				op = ASSIGN_I
			end if
			if source > 0 and target > 0 and
			   SymTab[source][S_MODE] = M_CONSTANT and
			   SymTab[target][S_MODE] = M_CONSTANT then
				-- record: constant var=literal
				-- for interpreter
				SymTab[target][S_OBJ] = SymTab[source][S_OBJ]
			end if

			emit_opcode(op)
			emit_addr(source)
			last_op = op
		end if

		assignable = FALSE
		emit_addr(target)

		if temp then
			-- need to re-flush, since it was wiped out above
			flush_temp( temp )
		end if

	case RHS_SUBS then
		b = Pop() -- subscript
		c = Pop() -- sequence
		target = NewTempSym() -- target
		if c < 0 or length(SymTab[c]) < S_VTYPE or SymTab[c][S_VTYPE] < 0 then -- forward reference
			-- we can't know what it is, so emit the check
			op = RHS_SUBS_CHECK
		elsif SymTab[c][S_MODE] = M_NORMAL then
			if SymTab[c][S_VTYPE] != sequence_type and
			SymTab[SymTab[SymTab[c][S_VTYPE]][S_NEXT]][S_VTYPE] !=
			sequence_type then
				op = RHS_SUBS_CHECK
			end if
		elsif SymTab[c][S_MODE] != M_CONSTANT or
				 not sequence(SymTab[c][S_OBJ]) then
			op = RHS_SUBS_CHECK
		end if
		emit_opcode(op)
		emit_addr(c)
		emit_addr(b)
		assignable = TRUE
		Push(target)
		emit_addr(target)
		current_sequence = append(current_sequence, target)
		flush_temp( Code[$-2] )

	case PROC then -- procedure, function and type calls

		assignable = FALSE -- assume for now
		subsym = op_info1
		n = SymTab[subsym][S_NUM_ARGS]

		if subsym = CurrentSub then
			-- calling ourself - parameter values may
			-- get overwritten before we can use them
			for i = cgi-n+1 to cgi do
				if cg_stack[i] > 0 then -- if it's a forward reference, it's not a private
					if SymTab[cg_stack[i]][S_SCOPE] = SC_PRIVATE and
					   SymTab[cg_stack[i]][S_VARNUM] < i then
						-- copy parameter to a temp
						emit_opcode(ASSIGN)
						emit_addr(cg_stack[i])
						cg_stack[i] = NewTempSym()
						emit_addr(cg_stack[i])
						check_for_temps()
					elsif sym_mode( cg_stack[i] ) = M_TEMP then
						emit_temp( cg_stack[i], NEW_REFERENCE )
					end if
				end if
			end for
		end if
		
		if SymTab[subsym][S_DEPRECATED] then
			Warning(327, deprecated_warning_flag, { SymTab[subsym][S_NAME] })
		end if
		
		emit_opcode(op)
		emit_addr(subsym)
		for i = cgi-n+1 to cgi do
			emit_addr(cg_stack[i])
			emit_temp( cg_stack[i], NEW_REFERENCE )
		end for

		cgi -= n

		if SymTab[subsym][S_TOKEN] != PROC then
			assignable = TRUE
			c = NewTempSym() -- put final result in temp
			emit_temp( c, NEW_REFERENCE )
			Push(c)
			-- emit location to assign result to
			emit_addr(c)

		end if

	case NAMEOF_FORWARD then
		-- this is simulated with a forward function call,
		-- with the ref of the name_of() parameter as the function fwd ref
		last_op = FUNC_FORWARD
		assignable = TRUE
		emit_opcode( FUNC_FORWARD )
		emit_addr( Pop() )
		emit_addr( 0 )
		c = NewTempSym() -- put final result in temp
		Push(c)
		-- emit location to assign result to
		emit_addr(c)
		emit_temp( c, NEW_REFERENCE )
		
	case PROC_FORWARD, FUNC_FORWARD then
		assignable = FALSE -- assume for now
		integer real_op
		if op = PROC_FORWARD then
			real_op = PROC
		else
			real_op = FUNC
		end if
		integer ref
		ref = new_forward_reference( real_op, op_info1, real_op )
		n = Pop() -- number of known args

		emit_opcode(op)
		emit_addr(ref)
		emit_addr( n ) -- this changes to be the "next" instruction
		for i = cgi-n+1 to cgi do
			emit_addr(cg_stack[i])
			emit_temp( cg_stack[i], NEW_REFERENCE )
		end for
		cgi -= n

		if op != PROC_FORWARD then
			assignable = TRUE
			c = NewTempSym() -- put final result in temp
			Push(c)
			-- emit location to assign result to
			emit_addr(c)
			emit_temp( c, NEW_REFERENCE )
		end if
		
	case WARNING then
		assignable = FALSE
	    a = Pop()
		Warning(SymTab[a][S_OBJ], custom_warning_flag,"")

	case INCLUDE_PATHS then
		sequence paths

		assignable = TRUE
	    a = Pop()
	    emit_opcode(RIGHT_BRACE_N)
	    paths = Include_paths(SymTab[a][S_OBJ])
	    emit(length(paths))
	    for i=length(paths) to 1 by -1 do
	        c = NewStringSym(paths[i])
	        emit_addr(c)
	    end for
	    b = NewTempSym()
	    Push(b)
	    emit_addr(b)
		last_op = RIGHT_BRACE_N
		op = last_op

	-- 0 inputs, 0 outputs - note: parser may emit an extra word
	case NOP1, NOP2, NOPWHILE, PRIVATE_INIT_CHECK, GLOBAL_INIT_CHECK,
	STARTLINE, CLEAR_SCREEN, EXIT, RETRY, ENDWHILE, ELSE, GOTO, GLABEL,
	ERASE_PRIVATE_NAMES, BADRETURNF, ERASE_SYMBOL, UPDATE_GLOBALS,
	DISPLAY_VAR, CALL_BACK_RETURN, END_PARAM_CHECK,
	TASK_YIELD, TASK_CLOCK_START, TASK_CLOCK_STOP, NOPSWITCH,
	COVERAGE_LINE, COVERAGE_ROUTINE then
		emit_opcode(op)
		assignable = FALSE
		if op = UPDATE_GLOBALS then
			last_op = last_op_backup
			last_pc = last_pc_backup
		end if

	-- 1 input, 0 outputs - special
	case IF, WHILE then
		a = Pop()
		assignable = FALSE
		-- AND and OR will have been short-circuited:
		if previous_op >= LESS and previous_op <= NOT then
			clear_temp( Code[$] )
			Code = Code[1..$-1]
			if previous_op = NOT then
				op = NOT_IFW
				backpatch(length(Code) - 1, op)
				sequence if_code = Code[$-1..$]
				Code = Code[1..$-2]
				Code &= if_code
			else
				if IsInteger(Code[$-1]) and IsInteger(Code[$]) then
					op = previous_op + LESS_IFW_I - LESS
				else
					op = previous_op + LESS_IFW - LESS
				end if

				backpatch(length(Code) - 2, op)

				sequence if_code = Code[$-2..$]
				Code = Code[1..$-3]
				Code &= if_code

			end if

			last_pc = last_pc_backup
			last_op = op

		elsif op = WHILE and
				-- need extra code in parser to optimize IF/ELSIF too
			  a > 0 and SymTab[a][S_MODE] = M_CONSTANT and
			  integer(SymTab[a][S_OBJ]) and
			  not equal(SymTab[a][S_OBJ], 0) then
			optimized_while = TRUE   -- while TRUE ... emit nothing
			last_pc = last_pc_backup
			last_op = last_op_backup
		else
			flush_temps( {a} )
			emit_opcode(op)
			emit_addr(a)


		end if

	case INTEGER_CHECK then
		assignable = FALSE
		if previous_op = ASSIGN then
			c = Code[$-1]
			if not IsInteger(c) then
				emit_opcode(op)
				emit_addr(op_info1)
			else
				last_op = last_op_backup
				last_pc = last_pc_backup
			end if
		elsif previous_op = -1 or
			  op_result[previous_op] != T_INTEGER then  -- includes ASSIGN_I
			emit_opcode(op)
			emit_addr(op_info1)
		else
			last_op = last_op_backup
			last_pc = last_pc_backup
		end if
		clear_temp( Code[$-1] )

	case SEQUENCE_CHECK then
		assignable = FALSE
		if previous_op = ASSIGN then
			c = Code[$-1]
			if c < 1 or
			   SymTab[c][S_MODE] != M_CONSTANT or
			   not sequence(SymTab[c][S_OBJ]) then
				emit_opcode(op)
				emit_addr(op_info1)
				clear_temp( Code[$-1] )
			else
				last_op = last_op_backup
				last_pc = last_pc_backup
			end if
		elsif previous_op = -1 or op_result[previous_op] != T_SEQUENCE then
			emit_opcode(op)
			emit_addr(op_info1)
			clear_temp( Code[$-1] )
		else
			last_op = last_op_backup
			last_pc = last_pc_backup
		end if


	case ATOM_CHECK then
		assignable = FALSE
		if previous_op = ASSIGN then
			c = Code[$-1]
			if c > 1
			and SymTab[c][S_MODE] = M_CONSTANT then
				-- we might know the constant's value at compile time
				if sequence( SymTab[c][S_OBJ] ) then
					-- type check error!
					ThisLine = ExprLine
					bp = expr_bp
					CompileErr( 346 )
					
				elsif SymTab[c][S_OBJ] = NOVALUE then
					emit_opcode(op)
					emit_addr(op_info1)
				else
					last_op = last_op_backup
					last_pc = last_pc_backup
				end if
				
			elsif c < 1 
			or not IsInteger(c) then
				-- fwd ref or non-integer
				emit_opcode(op)
				emit_addr(op_info1)
			
			else
				last_op = last_op_backup
				last_pc = last_pc_backup
			end if
		elsif previous_op = -1 or
			  (op_result[previous_op] != T_INTEGER and
			   op_result[previous_op] != T_ATOM) then
			emit_opcode(op)
			emit_addr(op_info1)
		else
			last_op = last_op_backup
			last_pc = last_pc_backup
		end if
		clear_temp( Code[$-1] )

	case RIGHT_BRACE_N then
	-- form a sequence of n items
		n = op_info1
		-- could optimize if they are all constants with known values
		elements = {}
		for i = 1 to n do
			elements = append(elements, Pop())
		end for
		element_vals = good_string(elements)

		if sequence(element_vals) then
			c = NewStringSym(element_vals)  -- make a string literal
			assignable = FALSE
			last_op = last_op_backup
			last_pc = last_pc_backup
		else
			if n = 2 then
				emit_opcode(RIGHT_BRACE_2) -- faster op for two items
				last_op = RIGHT_BRACE_2
			else
				emit_opcode(op)
				emit(n)
			end if

			for i = 1 to n do
				emit_addr(elements[i])
			end for
			c = NewTempSym()
			emit_addr(c)
			emit_temp( c, NEW_REFERENCE )
			assignable = TRUE
		end if
		Push(c)

	-- 3 inputs, 0 outputs
	case ASSIGN_SUBS2,      -- can't change the op
		ASSIGN_SUBS, 
		PASSIGN_SUBS then   -- can't change the op
		b = Pop() -- rhs value
		a = Pop() -- subscript
		c = Pop() -- sequence
		if op = ASSIGN_SUBS then
			-- maybe change the op
			if (previous_op != LHS_SUBS) and
				c > 0 and
				(SymTab[c][S_MODE] != M_NORMAL or
				(SymTab[c][S_VTYPE] != sequence_type and
				(SymTab[c][S_VTYPE] > 0 and
				SymTab[SymTab[SymTab[c][S_VTYPE]][S_NEXT]][S_VTYPE] !=
				sequence_type ))) then
				op = ASSIGN_SUBS_CHECK
			else
				if IsInteger(b) then
					op = ASSIGN_SUBS_I
				end if
			end if
			emit_opcode(op)

		elsif op = PASSIGN_SUBS then
			emit_opcode(PASSIGN_SUBS) -- always

		else
			emit_opcode(ASSIGN_SUBS) -- always

		end if

		emit_addr(c) -- sequence
		emit_addr(a) -- subscript
		emit_addr(b) -- rhs value
		assignable = FALSE

	case LHS_SUBS, LHS_SUBS1, LHS_SUBS1_COPY then
		-- left hand side multiple subscripts, one step
		a = Pop() -- subs
		lhs_var = Pop() -- sequence
		emit_opcode(op)
		emit_addr(lhs_var)
		emit_addr(a)
		if op = LHS_SUBS then
			TempKeep(lhs_var) -- should be lhs_target_temp
			emit_addr(lhs_target_temp)
			Push(lhs_target_temp)
			emit_addr(0) -- place holder
		else
			-- first LHS subscript
			-- Note: LHS_SUBS1 might be patched later to LHS_SUBS1_COPY
			lhs_target_temp = NewTempSym() -- use same temp for all subscripts
			emit_addr(lhs_target_temp) -- target temp holds pointer to sequence
			Push(lhs_target_temp)
			lhs_subs1_copy_temp = NewTempSym() -- place to copy (may be ignored)
			emit_addr(lhs_subs1_copy_temp)
		end if

		current_sequence = append(current_sequence, lhs_target_temp)
		assignable = FALSE  -- need to update current_sequence like in RHS_SUBS

	-- 1 input, 1 output
	case RAND, PEEK, PEEK4S, PEEK4U, NOT_BITS, NOT, PEEK8U, PEEK8S, SIZEOF,
		TASK_STATUS, PEEK2U, PEEK2S, PEEKS, PEEK_STRING, PEEK_POINTER then
		cont11ii(op, TRUE)

	case UMINUS then
		-- check for constant folding
		a = Pop()

		if a > 0 then
			obj = SymTab[a][S_OBJ]
			if SymTab[a][S_MODE] = M_CONSTANT then
				if is_integer(obj) then
					if obj = MININT then
						Push(NewDoubleSym(-MININT))
					else
						Push(NewIntSym(-obj))
					end if
					last_pc = last_pc_backup
					last_op = last_op_backup

				elsif atom(obj) and obj != NOVALUE then
					-- N.B. a constant won't have its value set until
					-- the end of the  constant var=xxx, var=xxx, ...
					-- statement. Be careful in the future if we
					-- add any more constant folding besides unary minus.
					Push(NewDoubleSym(-obj))
					last_pc = last_pc_backup
					last_op = last_op_backup

				else
					Push(a)
					cont11ii(op, FALSE)
				end if

			elsif TRANSLATE and SymTab[a][S_MODE] = M_TEMP and
				SymTab[a][S_GTYPE] = TYPE_DOUBLE then
				Push(NewDoubleSym(-obj))

			else
				Push(a)
				cont11ii(op, FALSE)
			end if
		else
			Push(a)
			cont11ii(op, FALSE)
		end if

	case LENGTH, GETC, SQRT, SIN, COS, TAN, ARCTAN, LOG, GETS, GETENV then
		cont11ii(op, FALSE)

	case IS_AN_INTEGER, IS_AN_ATOM, IS_A_SEQUENCE, IS_AN_OBJECT then
		cont11ii(op, FALSE)
		clear_temp( Code[$-1] )

	-- special 1 input, 1 output - also emits CurrentSub
	case ROUTINE_ID then
		emit_opcode(op)
		source = Pop()
		if TRANSLATE then
			emit_addr(num_routines-1)
			last_routine_id = num_routines
			last_max_params = max_params
			MarkTargets(source, S_RI_TARGET)

		else
			emit_addr(CurrentSub)
			emit_addr(length(SymTab))

			if BIND then
				-- note reference to this routine
				MarkTargets(source, S_NREFS)
			end if

		end if
		emit_addr(source)
		emit_addr(current_file_no)  -- necessary at top level
		assignable = TRUE
		c = NewTempSym()
		TempInteger(c) -- result will always be an integer
		Push(c)
		emit_addr(c)

	-- 1 input, 1 outputs with jump address that might be patched.
	-- Output value is not used by the next op, but same temp must
	-- be used by SC2 ops.
	case SC1_OR, SC1_AND then
		emit_opcode(op)
		emit_addr(Pop())
		c = NewTempSym()
		Push(c)
		emit_addr(c)
		assignable = FALSE
		-- jump address to follow

	-- 2 inputs, 0 outputs
	case SYSTEM, PUTS, PRINT, QPRINT, POSITION, MACHINE_PROC,
		C_PROC, POKE, POKE4, TASK_SCHEDULE, POKE2, POKE8, POKE_POINTER then
		emit_opcode(op)

		b = Pop()
		emit_addr(Pop())
		emit_addr(b)
		if op = C_PROC then
			emit_addr(CurrentSub)
		end if
		assignable = FALSE

	-- 2 inputs, 1 output
	case EQUALS, LESS, GREATER, NOTEQ, LESSEQ, GREATEREQ,
					AND, OR, XOR, REMAINDER, AND_BITS, OR_BITS, XOR_BITS then
		cont21ii(op, TRUE)  -- both integer args => integer result

	case PLUS then -- elsif op = PLUS then
		-- result could overflow int
		b = Pop()
		a = Pop()

		if b < 1 or a < 1 then
			Push(a)
			Push(b)
			cont21ii(op, FALSE)
		elsif SymTab[b][S_MODE] = M_CONSTANT and equal(SymTab[b][S_OBJ], 1) then
			op = PLUS1
			emit_opcode(op)
			emit_addr(a)
			emit_addr(0)
			cont21d(op, a, b, FALSE)
		elsif SymTab[a][S_MODE] = M_CONSTANT and equal(SymTab[a][S_OBJ], 1) then
			op = PLUS1
			emit_opcode(op)
			emit_addr(b)
			emit_addr(0)
			cont21d(op, a, b, FALSE)
		else
			Push(a)
			Push(b)
			cont21ii(op, FALSE)
		end if

	case rw:MULTIPLY then
			-- result could overflow int
		b = Pop()
		a = Pop()
		if a < 1 or b < 1 then
			Push(a)
			Push(b)
			cont21ii(op, FALSE)

		elsif SymTab[b][S_MODE] = M_CONSTANT and equal(SymTab[b][S_OBJ], 2) then
			-- Note: x * 2.0 is just as fast as x + x when x is f.p.
			op = PLUS
			emit_opcode(op)
			emit_addr(a)
			emit_addr(a)
			cont21d(op, a, b, FALSE)

		elsif SymTab[a][S_MODE] = M_CONSTANT and equal(SymTab[a][S_OBJ], 2) then
			op = PLUS
			emit_opcode(op)
			emit_addr(b)
			emit_addr(b)
			cont21d(op, a, b, FALSE)

		else
			Push(a)
			Push(b)
			cont21ii(op, FALSE)

		end if

	case rw:DIVIDE then
		b = Pop()
		if b > 0 and SymTab[b][S_MODE] = M_CONSTANT and equal(SymTab[b][S_OBJ], 2) then
			op = DIV2
			emit_opcode(op)
			emit_addr(Pop()) -- n.b. "a" hasn't been set
			a = 0
			emit_addr(0)
			cont21d(op, a, b, FALSE)  -- could have fractional result
		else
			Push(b)
			cont21ii(op, FALSE)
		end if

	case FLOOR then
		if previous_op = rw:DIVIDE then
			op = FLOOR_DIV
			backpatch(length(Code) - 3, op)
			assignable = TRUE
			last_op = op
			last_pc = last_pc_backup

		elsif previous_op = DIV2 then
			op = FLOOR_DIV2
			backpatch(length(Code) - 3, op)
			assignable = TRUE
			if IsInteger(Code[$-2]) then
				TempInteger(Top()) --mark temp as integer type
			end if
			last_op = op
			last_pc = last_pc_backup
		else
			cont11ii(op, TRUE)
		end if
		-- TRUE for FLOOR
		-- but not FLOOR_DIV (x/-1)

	-- 2 inputs, 1 output
	case MINUS, rw:APPEND, PREPEND, COMPARE, EQUAL,
					SYSTEM_EXEC, rw:CONCAT, REPEAT, MACHINE_FUNC, C_FUNC,
					SPRINTF, TASK_CREATE, HASH, HEAD, TAIL, DELETE_ROUTINE then
		cont21ii(op, FALSE)

	case SC2_NULL then  -- correct the stack - we aren't emitting anything
		c = Pop()
		TempKeep(c)
		b = Pop()  -- remove SC1's temp
		Push(c)
		assignable = FALSE
		last_op = last_op_backup
		last_pc = last_pc_backup

	-- Same temp must be used by SC2 ops and SC1 ops.
	case SC2_AND, SC2_OR then
		emit_opcode(op)
		emit_addr(Pop())
		c = Pop()
		TempKeep(c)
		emit_addr(c) -- target
		TempInteger(c)
		Push(c)
		assignable = FALSE

	-- 3 inputs, 0 outputs
	case MEM_COPY, MEM_SET, PRINTF then
		emit_opcode(op)
		c = Pop()
		b = Pop()
		emit_addr(Pop())
		emit_addr(b)
		emit_addr(c)
		assignable = FALSE

	-- 3 inputs, 1 output
	case RHS_SLICE, FIND, MATCH, FIND_FROM, MATCH_FROM, SPLICE, INSERT, REMOVE, OPEN then
		emit_opcode(op)
		c = Pop()
		b = Pop()
		emit_addr(Pop())
		emit_addr(b)
		emit_addr(c)
		c = NewTempSym()
		assignable = TRUE
		Push(c)
		emit_addr(c)

	-- n inputs, 1 output
	case CONCAT_N then     -- concatenate 3 or more items
		n = op_info1  -- number of items to concatenate
		emit_opcode(CONCAT_N)
		emit(n)
		for i = 1 to n do
			symtab_index element = Pop()
			emit_addr( element )  -- reverse order
		end for
		c = NewTempSym()
		emit_addr(c)
		assignable = TRUE
		Push(c)

	case FOR then
		c = Pop() -- increment
		TempKeep(c)
		ic = IsInteger(c)
		if c < 1 or
			(SymTab[c][S_MODE] = M_NORMAL and
			SymTab[c][S_SCOPE] != SC_LOOP_VAR and
			SymTab[c][S_SCOPE] != SC_GLOOP_VAR) then
			-- must make a copy in case var is modified
			emit_opcode(ASSIGN)
			emit_addr(c)
			c = NewTempSym()
			if ic then
				TempInteger( c )
			end if
			emit_addr(c)
		end if
		b = Pop() -- limit
		TempKeep(b)
		ib = IsInteger(b)
		if b < 1 or
			(SymTab[b][S_MODE] = M_NORMAL and
			SymTab[b][S_SCOPE] != SC_LOOP_VAR and
			SymTab[b][S_SCOPE] != SC_GLOOP_VAR) then
			-- must make a copy in case var is modified
			emit_opcode(ASSIGN)
			emit_addr(b)
			b = NewTempSym()
			if ib then
				TempInteger( b )
			end if
			emit_addr(b)
		end if
		a = Pop() -- initial value
		if IsInteger(a) and ib and ic then
			SymTab[op_info1][S_VTYPE] = integer_type
			op = FOR_I
		else
			op = FOR
		end if
		emit_opcode(op)
		emit_addr(c)
		emit_addr(b)
		emit_addr(a)
		emit_addr(CurrentSub) -- in case recursion check is needed
		Push(b)
		Push(c)
		assignable = FALSE
		-- loop var, jump addr will follow

	case ENDFOR_GENERAL, ENDFOR_INT_UP1 then  -- all ENDFORs
		emit_opcode(op) -- will be patched at runtime
		a = Pop()
		emit_addr(op_info2) -- address of top of loop
		emit_addr(Pop())    -- limit
		emit_addr(op_info1) -- loop var
		emit_addr(a)        -- increment - not always used -
							-- put it last - maybe different cache line
		assignable = FALSE

	-- 3 inputs, 1 output
	case ASSIGN_OP_SUBS, PASSIGN_OP_SUBS then
		-- for x[i] op= expr
		b = Pop()      -- rhs value, keep on stack
		TempKeep(b)

		a = Pop()      -- subscript, keep on stack
		TempKeep(a)

		c = Pop()      -- lhs sequence, keep on stack
		TempKeep(c)

		emit_opcode(op)
		emit_addr(c)
		emit_addr(a)

		d = NewTempSym()
		emit_addr(d)   -- place to store result

		Push(c)
		Push(a)
		Push(d)
		Push(b)
		assignable = FALSE

	-- 4 inputs, 0 outputs
	case ASSIGN_SLICE, PASSIGN_SLICE then
		emit_opcode(op)
		b = Pop() -- rhs value
		a = Pop() -- 2nd subs
		c = Pop() -- 1st subs
		emit_addr(Pop()) -- sequence
		emit_addr(c)
		emit_addr(a)
		emit_addr(b)
		assignable = FALSE

	-- 4 inputs, 1 output
	case REPLACE then
		emit_opcode(op)

		b = Pop()  -- source
		a = Pop()  -- replacement
		c = Pop()  -- start of replaced slice
		d = Pop()  -- end of replaced slice
		emit_addr(d)
		emit_addr(c)
		emit_addr(a)
		emit_addr(b)

		c = NewTempSym()
		Push(c)
		emit_addr(c)     -- place to store result
		assignable = TRUE

	-- 4 inputs, 1 output
	case ASSIGN_OP_SLICE, PASSIGN_OP_SLICE then
		-- for x[i..j] op= expr
		emit_opcode(op)

		b = Pop()        -- rhs value not used
		TempKeep(b)

		a = Pop()        -- 2nd subs
		TempKeep(a)

		c = Pop()        -- 1st subs
		TempKeep(c)

		d = Pop()
		TempKeep(d)      -- sequence

		emit_addr(d)
		Push(d)

		emit_addr(c)
		Push(c)

		emit_addr(a)
		Push(a)

		c = NewTempSym()
		Push(c)
		emit_addr(c)     -- place to store result

		Push(b)
		assignable = FALSE

	-- special cases:
	case CALL_PROC then
		emit_opcode(op)
		b = Pop()
		emit_addr(Pop())
		emit_addr(b)
		assignable = FALSE

	case CALL_FUNC then
		emit_opcode(op)
		b = Pop()
		emit_addr(Pop())
		emit_addr(b)
		assignable = TRUE
		c = NewTempSym()
		Push(c)
		emit_addr(c)

	case EXIT_BLOCK then
		emit_opcode( op )
		emit_addr( Pop() )
		assignable = FALSE

	case RETURNP then
		emit_opcode(op)
		emit_addr(CurrentSub)
		emit_addr(top_block())
		assignable = FALSE

	case RETURNF then
		clear_temp( Top() )
		flush_temps()
		emit_opcode(op)
		emit_addr(CurrentSub)
		emit_addr(Least_block())
		emit_addr(Pop())
		assignable = FALSE

	case RETURNT then
		emit_opcode(op)
		assignable = FALSE

	case DATE, TIME, SPACE_USED, GET_KEY, TASK_LIST,
					COMMAND_LINE, OPTION_SWITCHES then
		emit_opcode(op)
		c = NewTempSym()
		assignable = TRUE
		if op = GET_KEY then  -- it's in op_result as integer
			TempInteger(c)
		end if
		Push(c)
		emit_addr(c)

	case CLOSE, ABORT, CALL, DELETE_OBJECT then
		emit_opcode(op)
		emit_addr(Pop())
		assignable = FALSE

	case POWER then
		-- result could overflow int
		b = Pop()
		a = Pop()
		if b > 0 and SymTab[b][S_MODE] = M_CONSTANT and equal(SymTab[b][S_OBJ], 2) then
			-- convert power(x,2) to x*x
			op = rw:MULTIPLY
			emit_opcode(op)
			emit_addr(a)
			emit_addr(a)
			cont21d(op, a, b, FALSE)
		else
			Push(a)
			Push(b)
			cont21ii(op, FALSE)
		end if

	-- (doesn't need) 1 input, 0 outputs
	case TYPE_CHECK then
		emit_opcode(op)
		c = Pop()
		assignable = FALSE

	-- 0 inputs, 1 output, special op
	case DOLLAR then
		if current_sequence[$] < 0 or SymTab[current_sequence[$]][S_SCOPE] = SC_UNDEFINED then
			if lhs_ptr and length(current_sequence) = 1 then
				c = PLENGTH
			else
				c = LENGTH
			end if
			c = - new_forward_reference( VARIABLE, current_sequence[$], c )
		else
			c = current_sequence[$]
		end if

		-- length of the current sequence (or pointer to current sequence)
		if lhs_ptr and length(current_sequence) = 1 then
			emit_opcode(PLENGTH)
		else
			emit_opcode(LENGTH)
		end if

		emit_addr( c )

		c = NewTempSym()
		TempInteger(c)
		Push(c)
		emit_addr(c)
		assignable = FALSE -- it wouldn't be assigned anyway

	-- 0 inputs, 1 output
	case TASK_SELF then
		c = NewTempSym()
		Push(c)
		emit_opcode(op)
		emit_addr(c)
		assignable = TRUE

	case SWITCH then
		emit_opcode( op )
		c = Pop()
		b = Pop()
		a = Pop()
		emit_addr( a ) -- Switch Expr
		emit_addr( b ) -- Case values
		emit_addr( c ) -- Jump table
--		emit_addr( 0 ) -- parser emits the else after return
		assignable = FALSE

	case CASE then
		-- only for translator
		emit_opcode( op )
		emit( cg_stack[cgi] )  -- the case index
		cgi -= 1

	-- 0 inputs, 1 output
	case PLATFORM then
		if BIND and shroud_only then
			-- must check with backend/backendw/eub.exe for platform
			c = NewTempSym()
			TempInteger(c)
			Push(c)
			emit_opcode(op)
			emit_addr(c)
			assignable = TRUE

		else
			-- front end knows platform
			n = host_platform()
			Push(NewIntSym(n))
			assignable = FALSE
		end if

	-- 1 input, 0 outputs
	case PROFILE, TASK_SUSPEND then
		a = Pop()
		emit_opcode(op)
		emit_addr(a)
		assignable = FALSE

	case TRACE then
		a = Pop()
		if OpTrace then
			-- only emit trace op in a "with trace" section
			emit_opcode(op)
			emit_addr(a)
			if TRANSLATE then
				if not trace_called then
					Warning(217,0)
				end if
				trace_called = TRUE
			end if
		end if
		assignable = FALSE
	
	case REF_TEMP then
		-- Used by the Translator to save temps
		emit_opcode( REF_TEMP )
		emit_addr( Pop() )
	
	case DEREF_TEMP then
		emit_opcode( DEREF_TEMP )
		emit_addr( Pop() )
		
	case else
		InternalErr(259, {op})

	end switch

	previous_op = op
	inlined = 0

end procedure

export procedure emit_assign_op(integer op)
-- emit the appropriate assignment operator
	if op = PLUS_EQUALS then
		emit_op(PLUS)
	elsif op = MINUS_EQUALS then
		emit_op(MINUS)
	elsif op = MULTIPLY_EQUALS then
		emit_op(rw:MULTIPLY)
	elsif op = DIVIDE_EQUALS then
		emit_op(rw:DIVIDE)
	elsif op = CONCAT_EQUALS then
		emit_op(rw:CONCAT)
	end if
end procedure

export procedure StartSourceLine(integer sl, integer dup_ok = 0, integer emit_coverage = COVERAGE_INCLUDE )
-- record code offset at start of new source statement,
-- optionally emit start of line op
-- sl is true if we want a STARTLINE emitted as well
	integer line_span

	if gline_number = LastLineNumber then
		if length(LineTable) then
			if dup_ok then
				emit_op( STARTLINE )
				emit_addr( gline_number )
			end if
			return -- ignore duplicates

		else
			sl = FALSE -- top-level new statement to execute on same line
		end if
	end if
	LastLineNumber = gline_number

	-- add new line table entry
	line_span = gline_number - SymTab[CurrentSub][S_FIRSTLINE]
	while length(LineTable) < line_span do
		LineTable = append(LineTable, -1) -- filler
	end while
	LineTable = append(LineTable, length(Code))

	if sl and (TRANSLATE or (OpTrace or OpProfileStatement)) then
		-- control point for tracing and profiling
		emit_op(STARTLINE)
		emit_addr(gline_number)
	end if

	-- emit opcode for coverage gathering
	if (sl and emit_coverage = COVERAGE_INCLUDE) or emit_coverage = COVERAGE_OVERRIDE then
		include_line( gline_number )
	end if

end procedure

export function has_forward_params(integer sym)
	for i = cgi - (SymTab[sym][S_NUM_ARGS]-1) to cgi do
		if cg_stack[i] < 0 then
			return 1
		end if
	end for
	return 0
end function

