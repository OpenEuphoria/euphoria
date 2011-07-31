-- (c) Copyright - See License.txt
--
-- Parser

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include euphoria/info.e

include std/sequence.e
include std/text.e
include std/search.e
include std/convert.e
include std/filesys.e

include global.e
include platform.e
include emit.e
include symtab.e
include scanner.e
include fwdref.e
include common.e
include inline.e
include reswords.e
include error.e
include c_out.e
include block.e
include keylist.e
include coverage.e
include memstruct.e

constant UNDEFINED = -999
constant DEFAULT_SAMPLE_SIZE = 25000  -- for time profile
constant ASSIGN_OPS = {EQUALS, PLUS_EQUALS, MINUS_EQUALS, MULTIPLY_EQUALS,
						DIVIDE_EQUALS, CONCAT_EQUALS}
constant MEMSTRUCT_ASSIGN_OPS = {MEMSTRUCT_ASSIGN, MEMSTRUCT_PLUS, MEMSTRUCT_MINUS, MEMSTRUCT_MULTIPLY,
						MEMSTRUCT_DIVIDE, 0}
constant SCOPE_TYPES = {SC_LOCAL, SC_GLOBAL, SC_PUBLIC, SC_EXPORT, SC_UNDEFINED}

--*****************
-- Local variables
--*****************
sequence branch_list = {}
sequence branch_stack = {}

integer short_circuit = 0  -- are we doing short-circuit code?
						   -- > 0 means yes - if/elsif/while but not
						   -- in args, subscripts, slices, {,,}.

boolean short_circuit_B = FALSE   -- are we in the skippable part of a short
								  -- circuit expression? given short_circuit is TRUE.

integer SC1_patch          -- place to patch jump address for SC1 ops
integer SC1_type           -- OR or AND
integer start_index        -- start of current top level command

sequence backed_up_tok       -- place to back up a token
integer FuncReturn         -- TRUE if a function return appeared
export integer param_num          -- number of parameters and private variables
					       -- in current procedure
--sequence goto_list        -- back-patch list for end if label
--sequence goto_delay        -- delay list for end if label
sequence goto_line        -- back-patch list for end if label
sequence goto_labels    -- sequence of if block labels, 0 for unlabelled blocks
sequence goto_addr
sequence goto_stack
sequence goto_ref
sequence label_block

-- flow control management
sequence break_list        -- back-patch list for end if label
sequence break_delay       -- delay list for end if label
sequence exit_list         -- stack of exits to back-patch
sequence exit_delay        -- delay list for end for/while/until
sequence continue_list     -- stack of exits to back-patch
sequence continue_delay    -- stack of exits to back-patch
sequence entry_addr, continue_addr, retry_addr -- lists of Code indexes for the entry, continue and retry keywords

-- block headers
sequence loop_labels       -- sequence of loop labels, 0 for unlabelled loops
sequence if_labels         -- sequence of if block labels, 0 for unlabelled blocks

-- general structure control
sequence block_list        -- list of opcodes for currently active blocks. This list never shrinks
integer block_index        -- index of currently active block

integer stmt_nest          -- nesting level of statement lists

sequence init_stack        -- var init stack

sequence loop_stack
sequence if_stack

sequence gListItem = {} 	-- [$] = 1 if just processed an expression in a list otherwise 0.

-- Expression statistics:
integer side_effect_calls = 0 -- number of calls to functions with side-effects
							  -- on local/global variables

integer factors = 0           -- number of factors parsed

integer lhs_subs_level = -1   -- number of levels of subscripting of lhs var on RHS
symtab_index left_sym = 0     -- var used on LHS of assignment

integer subs_depth = 0       -- nesting level of slice expression.
sequence_of_tokens canned_tokens = {}   -- recording stack when parser is in recording mode
					          -- this sequence will be saved and the tape played back whenever needed

integer canned_index = 0      -- previous playback position

procedure EndLineTable()
-- put marker at end of current line number table
	LineTable = append(LineTable, -2)
end procedure

procedure CreateTopLevel()
-- sets symbol table fields for the top level procedure
	SymTab[TopLevelSub][S_NUM_ARGS] = 0
	SymTab[TopLevelSub][S_TEMPS] = 0
	SymTab[TopLevelSub][S_CODE] = {}
	SymTab[TopLevelSub][S_LINETAB] = {}
	SymTab[TopLevelSub][S_FIRSTLINE] = 1
	SymTab[TopLevelSub][S_REFLIST] = {}
	SymTab[TopLevelSub][S_NREFS] = 1
	SymTab[TopLevelSub][S_RESIDENT_TASK] = 1
	SymTab[TopLevelSub][S_SAVED_PRIVATES] = {}

	Start_block( PROC, TopLevelSub )
end procedure

procedure CheckForUndefinedGotoLabels()
	for i = 1 to length(goto_delay) do
		if not equal(goto_delay[i],"") then
			line_number = goto_line[i][1] -- tell compiler the correct line number
			gline_number = goto_line[i][1] -- tell compiler the correct line number
			ThisLine = goto_line[i][2] -- tell compiler the correct line number
			bp = length(ThisLine)
				CompileErr(156, {goto_delay[i]})
		end if
	end for
end procedure

procedure PushGoto()
	goto_stack = append(goto_stack, {goto_addr, goto_list, goto_labels, goto_delay, goto_line, goto_ref, label_block })
	goto_addr = {}
	goto_list = {}
	goto_labels = {}
	goto_delay = {}
	goto_line = {}
	goto_ref = {}
	label_block = {}
end procedure

procedure PopGoto()
	CheckForUndefinedGotoLabels()
	goto_addr = goto_stack[$][1]
	goto_list = goto_stack[$][2]
	goto_labels = goto_stack[$][3]
	goto_delay = goto_stack[$][4]
	goto_line = goto_stack[$][5]
	goto_ref = goto_stack[$][6]
	label_block = goto_stack[$][7]
	goto_stack = goto_stack[1..$-1]
end procedure

procedure EnterTopLevel( integer end_line_table = 1 )
-- prepare to put code into the top level procedure
	if CurrentSub then
		if end_line_table then
			EndLineTable()
			SymTab[CurrentSub][S_LINETAB] = LineTable
			SymTab[CurrentSub][S_CODE] = Code
		end if
	end if
	if length(goto_stack) then
		PopGoto()
	end if
	LineTable = SymTab[TopLevelSub][S_LINETAB]
	Code = SymTab[TopLevelSub][S_CODE]
	previous_op = -1
	CurrentSub = TopLevelSub
	clear_last()
	if length( branch_stack ) then
		branch_list = branch_stack[$]
		branch_stack = tail( branch_stack )
	end if
end procedure

procedure LeaveTopLevel()
-- prepare to resume compiling normal subprograms
	branch_stack = append( branch_stack, branch_list )
	branch_list = {}
	PushGoto()
	LastLineNumber = -1
	SymTab[TopLevelSub][S_LINETAB] = LineTable
	SymTab[TopLevelSub][S_CODE] = Code
	LineTable = {}
	Code = {}
	previous_op = -1
	clear_last()
end procedure

export procedure InitParser()
	goto_stack = {}
	--goto_list = {}
	--goto_delay = {}
	goto_labels = {}
	label_block = {}
	goto_ref = {}
	goto_addr = {}
	goto_line = {}
	break_list = {}
	break_delay = {}
	exit_list = {}
	exit_delay = {}
	continue_list = {}
	continue_delay = {}
	init_stack = {}
	CurrentSub = 0
	CreateTopLevel()
	EnterTopLevel()
	backed_up_tok = {}
	loop_stack = {}
	stmt_nest = 0
	loop_labels = {}
	if_labels = {}
	if_stack = {}
	continue_addr = {}
	retry_addr = {}
	entry_addr = {}
	block_list = {}
	block_index = 0
	param_num = -1
end procedure

sequence switch_stack = {}

enum
	SWITCH_CASES,
	SWITCH_JUMP_TABLE,
	SWITCH_ELSE,
	SWITCH_PC,
	SWITCH_FALLTHRU,
	SWITCH_VALUE

procedure NotReached(integer tok, sequence keyword)
-- Issue warning about code that can't be executed
	if not find(tok, {END, ELSE, ELSIF, END_OF_FILE, CASE, IFDEF, ELSIFDEF, ELSEDEF}) then
		if equal(keyword, "goto") and find(tok, {LOOP, LABEL, WHILE}) then
			return
		end if
		if equal(keyword, "abort()") and tok = LABEL then
			-- If a label follows abort() then assume the label could be the target
			-- of a goto some where.
			return
		end if
		Warning(218, not_reached_warning_flag,
					{name_ext(known_files[current_file_no]),
					 line_number,
					 keyword})
	end if
end procedure


procedure Forward_InitCheck( token tok, integer ref )
	if ref then
		integer sym = tok[T_SYM]
		if tok[T_ID] = QUALIFIED_VARIABLE then
			set_qualified_fwd( SymTab[sym][S_FILE_NO] )
		end if
		ref = new_forward_reference( GLOBAL_INIT_CHECK, tok[T_SYM], GLOBAL_INIT_CHECK )
		emit_op( GLOBAL_INIT_CHECK )
		emit_addr( 0 )
	end if
end procedure


procedure InitCheck(symtab_index sym, integer ref)
-- emit INIT_CHECK opcode if we aren't sure if a var has been
-- initialized yet. ref is TRUE if this is a read of this var

	if sym < 0 or (SymTab[sym][S_MODE] = M_NORMAL and
	    SymTab[sym][S_SCOPE] != SC_LOOP_VAR and
	    SymTab[sym][S_SCOPE] != SC_GLOOP_VAR) then
		if sym < 0 or ((SymTab[sym][S_SCOPE] != SC_PRIVATE and
		   equal(SymTab[sym][S_OBJ], NOVALUE)) or
		   (SymTab[sym][S_SCOPE] = SC_PRIVATE and
		   SymTab[sym][S_VARNUM] >= SymTab[CurrentSub][S_NUM_ARGS])) then
			if sym < 0 or (SymTab[sym][S_INITLEVEL] = -1)
			or (SymTab[sym][S_SCOPE] != SC_PRIVATE)
			then
				if ref then
					if sym > 0 and (SymTab[sym][S_SCOPE] = SC_UNDEFINED) then
						emit_op(PRIVATE_INIT_CHECK)
					elsif sym < 0 or find(SymTab[sym][S_SCOPE], SCOPE_TYPES) then
						emit_op(GLOBAL_INIT_CHECK) -- will become NOP2
					else
						emit_op(PRIVATE_INIT_CHECK)
					end if
					emit_addr(sym)
				end if
				if sym > 0 
				and (short_circuit <= 0 or short_circuit_B = FALSE)
				and not (SymTab[sym][S_SCOPE] != SC_PRIVATE) then
					
					if CurrentSub != TopLevelSub 
					or current_file_no = length( known_files ) then
						-- if we're in top level code, and we've already included other files,
						-- we can't mark this as initialized, since one of those files could
						-- use the symbol before we initialize
						init_stack = append(init_stack, sym)
						SymTab[sym][S_INITLEVEL] = stmt_nest
					end if
				end if
			end if
			-- else we know that it must be initialized at this point
		end if
		-- else ignore parameters, already initialized global/locals
	elsif ref and sym > 0 and sym_mode( sym ) = M_CONSTANT and equal( NOVALUE, sym_obj( sym ) ) then
		emit_op( GLOBAL_INIT_CHECK )
		emit_addr(sym)
	end if
	-- else .. ignore loop vars, constants
end procedure

procedure InitDelete()
-- remove vars whose nesting level is
-- now too high from the init stack
	while length(init_stack) and
		  SymTab[init_stack[$]][S_INITLEVEL] > stmt_nest do
		SymTab[init_stack[$]][S_INITLEVEL] = -1
		init_stack = init_stack[1..$-1]
	end while
end procedure

procedure emit_forward_addr()
-- emit blank forward address and add this branch point to the list
-- for later straightening
	emit_addr(0)
	branch_list = append(branch_list, length(Code))
end procedure

procedure StraightenBranches()
-- Straighten branches within the current subprogram (or top-level)
	integer br
	integer target

	if TRANSLATE then
		return -- do it in back-end
	end if
	for i = length(branch_list) to 1 by -1 do
		if branch_list[i] > length(Code) then
			CompileErr("wtf")
		end if
		target = Code[branch_list[i]]
		if target <= length(Code) and target > 0 then
			br = Code[target]
			if br = ELSE or br = ENDWHILE or br = EXIT then
				backpatch(branch_list[i], Code[target+1])
			end if
		end if
	end for
	branch_list = {}
end procedure

procedure AppendEList(integer addr)
-- add address to list requiring back-patch at end of if statement
	break_list = append(break_list, addr)
end procedure

procedure AppendXList(integer addr)
-- add exit location to list requiring back-patch at end of loop
	exit_list = append(exit_list, addr)
end procedure

procedure AppendNList(integer addr)
-- add exit location to list requiring back-patch at end of loop
	continue_list = append(continue_list, addr)
end procedure

procedure PatchEList(integer base)
-- back-patch jump offsets for jumps to end of if block
	integer break_top,n

	if not length(break_list) then
		return
	end if

	break_top = 0
	for i=length(break_list) to base+1 by -1 do
		n=break_delay[i]
		break_delay[i] -= (n>0)
		if n>1 then
			if break_top = 0 then
				break_top = i
			end if
		elsif n=1 then
			backpatch(break_list[i],length(Code)+1)
		end if
	end for

	if break_top=0 then
	    break_top=base
	end if

	break_delay = break_delay[1..break_top]
	break_list = break_list[1..break_top]
end procedure

procedure PatchNList(integer base)
-- back-patch jump offsets for jumps to end of iteration in loops
	integer next_top,n

	if not length(continue_list) then
		return
	end if

	next_top = 0

	for i=length(continue_list) to base+1 by -1 do
		n=continue_delay[i]
		continue_delay[i] -= (n>0)
		if n>1 then
			if next_top = 0 then
				next_top = i
			end if
		elsif n=1 then
			backpatch(continue_list[i],length(Code)+1)
		end if
	end for

	if next_top=0 then
	    next_top=base
	end if

	continue_delay =continue_delay[1..next_top]
	continue_list = continue_list[1..next_top]
end procedure

procedure PatchXList(integer base)
-- back-patch jump offsets for jumps to end of loop
	integer exit_top,n

	if not length(exit_list) then
		return
	end if

	exit_top = 0

	for i=length(exit_list) to base+1 by -1 do
		n=exit_delay[i]
		exit_delay[i] -= (n>0)
		if n>1 then
			if exit_top = 0 then
				exit_top = i
			end if
		elsif n=1 then
			backpatch(exit_list[i],length(Code)+1)
		end if
	end for

	if exit_top=0 then
	    exit_top=base
	end if

	exit_delay = exit_delay [1..exit_top]
	exit_list = exit_list [1..exit_top]
end procedure

export procedure putback(token t)
-- push a scanner token back onto the input stream
	backed_up_tok = append(backed_up_tok, t)
	
	if t[T_SYM] then
		putback_ForwardLine     = ForwardLine
		putback_forward_bp      = forward_bp
		putback_fwd_line_number = fwd_line_number
		
		if last_fwd_line_number then
			ForwardLine     = last_ForwardLine
			forward_bp      = last_forward_bp
			fwd_line_number = last_fwd_line_number
		end if
	end if
end procedure

sequence
	psm_stack = {},
	can_stack = {},
	idx_stack = {},
	tok_stack = {}

procedure start_recording()
	psm_stack &= Parser_mode
	can_stack = append(can_stack,canned_tokens)
	idx_stack &= canned_index
	tok_stack = append(tok_stack,backed_up_tok)
	canned_tokens = {}
	Parser_mode = PAM_RECORD
	clear_last()
end procedure

function restore_parser()
	integer n
	object tok
	sequence x

	n=Parser_mode
	x = canned_tokens
	canned_tokens = can_stack[$]
	can_stack     = can_stack[1..$-1]
	canned_index  = idx_stack[$]
	idx_stack     = idx_stack[1..$-1]
	Parser_mode   = psm_stack[$]
	psm_stack     = psm_stack[1..$-1]
	tok 		  = tok_stack[$]
	tok_stack 	  = tok_stack[1..$-1]
	clear_last()
	if n=PAM_PLAYBACK then
		return {}

	elsif n = PAM_NORMAL then
		use_private_list = 0
	end if
	if length(backed_up_tok) > 0 then
		return x[1..$-1]
	else
		return x
	end if
end function

procedure start_playback(sequence s)
	psm_stack &= Parser_mode
	can_stack = append(can_stack,canned_tokens)
	idx_stack &= canned_index
	tok_stack = append(tok_stack,backed_up_tok)
	canned_index = 1
	canned_tokens = s
	backed_up_tok = {}
	Parser_mode = PAM_PLAYBACK
end procedure

sequence parseargs_states={}
enum -- struct parseargs_states record
	PS_POSITION,
	PS_SCAN_LOCK,
	PS_USE_LIST,
	PS_ON_ARG

sequence private_list = {}
integer lock_scanner = 0
integer on_arg = 0
sequence nested_calls = {}

procedure restore_parseargs_states()
	sequence s
	integer n

	s = parseargs_states[$]
	parseargs_states = parseargs_states[1..$-1]
	n=s[PS_POSITION]
	private_list = private_list[1..n]
	private_sym = private_sym[1..n]
	lock_scanner = s[PS_SCAN_LOCK]
	use_private_list = s[PS_USE_LIST]
	on_arg = s[PS_ON_ARG]
	nested_calls = nested_calls[1..$-1]
end procedure

function read_recorded_token(integer n)
	token t
	integer p, prev_Nne
	if atom(Ns_recorded[n]) then
		if use_private_list then
			p = find( Recorded[n], private_list)
			if p > 0 then -- the value of this parameter is known, use it
			
				if TRANSLATE
				and (private_sym[p] < 0
				or SymTab[private_sym[p]][S_MODE] = M_TEMP)
				then
					-- we're reusing a temp in a default parameter
					-- This will ensure we get an extra reference and that
					-- the source temp isn't recycled by the translator
					symtab_index ts = NewTempSym()
					Code &= { ASSIGN, private_sym[p], ts }
					return {VARIABLE, ts}
				else
					return {VARIABLE, private_sym[p]}
				end if

			end if
		end if
		prev_Nne = No_new_entry
		No_new_entry = 1
		t = keyfind(Recorded[n],-1)
		if t[T_ID] = IGNORED then
	        p = Recorded_sym[n]
	        if p = 0 then
				-- a forward reference
				No_new_entry = 0
				t = keyfind( Recorded[n], -1 )
				No_new_entry = 1
				if t[T_ID] = IGNORED then
					CompileErr(157,{Recorded[n]})
				end if
			else
				t = {SymTab[p][S_TOKEN], p}
			end if
		end if
	else
		prev_Nne = No_new_entry
		No_new_entry = 1
		t = keyfind(Ns_recorded[n],-1, , 1)
		if t[T_ID] != NAMESPACE then
			p = Ns_recorded_sym[n]
			if p = 0 or sym_token( p ) != NAMESPACE then
				CompileErr(153, {Ns_recorded[n]})
			end if
			t = {NAMESPACE, p}
		end if

		t = keyfind(Recorded[n],SymTab[t[T_SYM]][S_OBJ])
		if t[T_ID] = IGNORED then
	        p = Recorded_sym[n]
	        if p = 0 then
	        	CompileErr(157,{Recorded[n]})
	        end if
		    t = {SymTab[p][S_TOKEN], p}
		end if
		n = t[T_ID]
		if n = VARIABLE then
			n = QUALIFIED_VARIABLE
		elsif n = FUNC then
			n = QUALIFIED_FUNC
		elsif n = PROC then
			n = QUALIFIED_PROC
		elsif n = TYPE then
			n = QUALIFIED_TYPE
		end if
		t[T_ID] = n
	end if
	No_new_entry = prev_Nne
  	return t
end function

export function next_token()
-- read next scanner token
	token t
	sequence s

	if length(backed_up_tok) > 0 then
		t = backed_up_tok[$]
		backed_up_tok = remove( backed_up_tok, length( backed_up_tok ) )
		if putback_fwd_line_number then
			
			ForwardLine     = putback_ForwardLine
			forward_bp      = putback_forward_bp
			fwd_line_number = putback_fwd_line_number
			
			putback_fwd_line_number = 0
			
		end if
	elsif Parser_mode = PAM_PLAYBACK then
		if canned_index <= length(canned_tokens) then
			t = canned_tokens[canned_index]
			if canned_index < length(canned_tokens) then
				canned_index += 1
	        else -- tape ended
	            s = restore_parser()
	        end if
	    else
	    	InternalErr(266)
		end if
		if t[T_ID] = RECORDED then
			t=read_recorded_token(t[T_SYM])
		elsif t[T_ID] = DEF_PARAM then
        	for i=length(nested_calls) to 1 by -1 do
        	    if nested_calls[i] = t[T_SYM][2] then
					return {VARIABLE, private_sym[parseargs_states[i][PS_POSITION]+t[T_SYM][1]]}
				end if
			end for
			CompileErr(98)
		end if
	elsif lock_scanner then
		return {PLAYBACK_ENDS,0}
	else
	    t = Scanner()
	    if Parser_mode = PAM_RECORD then
	        canned_tokens = append(canned_tokens,t)
	    end if
	end if
	putback_fwd_line_number = 0
	return t
end function

integer forward_expr

function Expr_list()
-- parse a (possibly empty) list of expressions
	token tok
	integer n

	tok = next_token()
	putback(tok)
	if tok[T_ID] = RIGHT_BRACE then
		return 0
	else
		n = 0
		short_circuit -= 1
		while TRUE do
			gListItem &= 1
			Expr()
			n += gListItem[$]
			gListItem = gListItem[1 .. $-1]
			tok = next_token()
			if tok[T_ID] != COMMA then
				exit
			end if
		end while
		short_circuit += 1
	end if
	putback(tok)
	return n
end function

export procedure tok_match(integer tok, integer prevtok = 0)
-- match token or else syntax error
	token t
	sequence expected, actual, prevname

	t = next_token()
	if t[T_ID] != tok then
		expected = LexName(tok)
		actual = LexName(t[T_ID])
		if prevtok = 0 then
			CompileErr(132, {expected, actual})
		else
			prevname = LexName(prevtok)
			CompileErr(138, {expected, prevname, actual})
		end if
	end if
end procedure

procedure tok_optional(integer tok)
-- match token or else put it back
	token t

	t = next_token()
	if t[T_ID] != tok then
		putback(t)
	end if
end procedure

procedure UndefinedVar(symtab_index s)
-- report a possibly undefined or multiply-defined symbol
	symtab_index dup
	sequence errmsg
	sequence rname
	sequence fname

	if SymTab[s][S_SCOPE] = SC_UNDEFINED then
		CompileErr(19, {SymTab[s][S_NAME]})

	elsif SymTab[s][S_SCOPE] = SC_MULTIPLY_DEFINED then
		rname = SymTab[s][S_NAME]
		errmsg = ""
		-- extended error message
		for i = 1 to length(dup_globals) do
			dup = dup_globals[i]
			fname = known_files[SymTab[dup][S_FILE_NO]]
			errmsg &= "    " & fname & "\n"

		end for

		CompileErr(23, {rname, rname, errmsg})

	elsif length(symbol_resolution_warning) then
		Warning( symbol_resolution_warning, resolution_warning_flag)
	end if
end procedure

procedure WrongNumberArgs(symtab_index subsym, sequence only)
-- issue message for wrong number of arguments
	integer msgno

	if SymTab[subsym][S_NUM_ARGS] = 1 then
		if length(only) = 0 then
			msgno = 20
		else
			msgno = 237
		end if
	else
		if length(only) = 0 then
			msgno = 236
		else
			msgno = 238
		end if

	end if
	CompileErr(msgno, {SymTab[subsym][S_NAME], SymTab[subsym][S_NUM_ARGS]})
end procedure

procedure MissingArgs(symtab_index subsym)
	sequence eentry = SymTab[subsym]

	CompileErr(235, {eentry[S_NAME], eentry[S_DEF_ARGS][2]})
end procedure

export procedure Parse_default_arg( symtab_index subsym, integer arg, sequence fwd_private_list, sequence fwd_private_sym )
	symtab_index param = subsym
	on_arg = arg
	parseargs_states = append(parseargs_states,
				{length(private_list),lock_scanner,use_private_list,on_arg})
	nested_calls &= subsym

	for i = 1 to arg do
		param = SymTab[param][S_NEXT]
	end for

	private_list = fwd_private_list
	private_sym  = fwd_private_sym

	if atom(SymTab[param][S_CODE]) then  -- but no default set
		CompileErr(26, {arg, SymTab[subsym][S_NAME], SymTab[param][S_NAME]})
	end if

	use_private_list = 1
	lock_scanner = 1
	start_playback(SymTab[param][S_CODE] )
	call_proc(forward_expr, {})

	add_private_symbol( Top(), SymTab[param][S_NAME] )
	lock_scanner = 0
	restore_parseargs_states()
end procedure

procedure ParseArgs(symtab_index subsym)
-- parse arguments for a function, type or procedure call
	integer n, fda, lnda
	token tok
	symtab_index s
	object var_code
	sequence name

	n = SymTab[subsym][S_NUM_ARGS]
	if sequence(SymTab[subsym][S_DEF_ARGS]) then
		fda = SymTab[subsym][S_DEF_ARGS][1]
		lnda = SymTab[subsym][S_DEF_ARGS][2]
	else
		fda = 0
		lnda = 0
	end if
	s = subsym

	parseargs_states = append(parseargs_states,
				{length(private_list),lock_scanner,use_private_list,on_arg})
	nested_calls &= subsym
	lock_scanner = 0
	on_arg = 0

	short_circuit -= 1
	for i = 1 to n do

	  	tok = next_token()

		if tok[T_ID] = COMMA then
			-- defaulted arg
			if SymTab[subsym][S_OPCODE] then
				if atom(SymTab[subsym][S_CODE]) then
					var_code = 0
				else
					var_code = SymTab[subsym][S_CODE][i]
				end if
				name = ""
			else
				s = SymTab[s][S_NEXT]
				var_code = SymTab[s][S_CODE]
				name = SymTab[s][S_NAME]
			end if

			if atom(var_code) then  -- but no default set
				CompileErr(29,i)
			end if

			use_private_list = 1
			start_playback(var_code)
			lock_scanner=1

			-- read the default tokens
			Expr()
			lock_scanner=0
			on_arg += 1
			private_list = append(private_list,name)
			private_sym &= Top()
			backed_up_tok = {tok} -- ????

		elsif tok[T_ID] != RIGHT_ROUND then
			-- It's a real arg
			if SymTab[subsym][S_OPCODE] then
				name = ""
			else
				s = SymTab[s][S_NEXT]
				name = SymTab[s][S_NAME]
			end if
			-- If we're reading default, we don't want to drop out before we're actually done
			use_private_list = Parser_mode != PAM_NORMAL
			putback(tok)
			Expr()
			on_arg += 1
			private_list = append(private_list,name)
			private_sym &= Top()
		end if

		if on_arg != n then
			if tok[T_ID] = RIGHT_ROUND then
				putback( tok )
			end if
			tok = next_token()
			if tok[T_ID] != COMMA then
				--
		  		if tok[T_ID] = RIGHT_ROUND then
		  			-- not as many actual args as formal args
					if fda=0 then
						WrongNumberArgs(subsym, "")
					elsif i<lnda then
						MissingArgs(subsym)
					end if
					lock_scanner = 1
					use_private_list = 1

					-- read as many as are left
					while on_arg < n do
						on_arg += 1
						if SymTab[subsym][S_OPCODE] then
							if atom(SymTab[subsym][S_CODE]) then
								var_code = 0
							else
								var_code = SymTab[subsym][S_CODE][on_arg]
							end if

							name = ""
						else

							s = SymTab[s][S_NEXT]
							var_code = SymTab[s][S_CODE]
							name = SymTab[s][S_NAME]
						end if
						if sequence(var_code) then
						-- some defaulted arg follows with a default value
							putback( tok )
							start_playback(var_code)

							-- read the recorded tokens
							Expr()
							if on_arg < n then
								private_list = append(private_list,name)
								private_sym &= Top()
							end if
						else -- just not enough args
							CompileErr(29, on_arg)
						end if
		  		    end while
					-- all missing args had default values
					short_circuit += 1
					if backed_up_tok[$][T_ID] = PLAYBACK_ENDS then
						backed_up_tok = {}
					end if

					restore_parseargs_states()

					return
				else
					putback(tok)
					tok_match(COMMA)
				end if
			end if
		end if

	end for
	tok = next_token()
	short_circuit += 1
	if tok[T_ID] != RIGHT_ROUND then
		if tok[T_ID] = COMMA then
			WrongNumberArgs(subsym, "only ")
		else
			putback(tok)
			tok_match(RIGHT_ROUND)
		end if
	end if

	restore_parseargs_states()
end procedure

procedure Forward_var( token tok, integer init_check = -1, integer op = tok[T_ID] )
	integer ref
	ref = new_forward_reference( VARIABLE, tok[T_SYM], op )
	emit_opnd( - ref )
	if init_check != -1 then
		Forward_InitCheck( tok, init_check )
	end if
	
end procedure

procedure Forward_call(token tok, integer opcode = PROC_FORWARD )
	integer args = 0
	symtab_index proc = tok[T_SYM]
	integer tok_id = tok[T_ID]
	remove_symbol( proc )
	short_circuit -= 1
	while 1 do
		tok = next_token()
		integer id = tok[T_ID]

		switch id do
			case COMMA then
				emit_opnd( 0 ) -- clean this up later
				args += 1

			case RIGHT_ROUND then
				exit

			case else
				putback( tok )
				call_proc( forward_expr, {} )
				args += 1

				tok = next_token()
				id = tok[T_ID]
				if id = RIGHT_ROUND then
					exit
				end if

				if id != COMMA then
						CompileErr(69)
				end if
		end switch
	end while

	integer fc_pc = length( Code ) + 1
	emit_opnd( args )

	op_info1 = proc
	if tok_id = QUALIFIED_VARIABLE then
		set_qualified_fwd( SymTab[proc][S_FILE_NO] )
	else
		set_qualified_fwd( -1 )
	end if
	emit_op( opcode )
	if not TRANSLATE then
		if OpTrace then
			emit_op(UPDATE_GLOBALS)
		end if
	end if
	short_circuit += 1
end procedure

procedure Object_call( token tok )
	token tok2, tok3
	integer save_factors, save_lhs_subs_level
	symtab_index sym

	tok2 = next_token()
	if tok2[T_ID] = VARIABLE or tok2[T_ID] = QUALIFIED_VARIABLE then
		tok3 = next_token()
		if tok3[T_ID] = RIGHT_ROUND then
			-- what we are looking for
			sym = tok2[T_SYM]
			if SymTab[sym][S_SCOPE] = SC_UNDEFINED then
				Forward_var( tok2 )
			else
				SymTab[sym][S_USAGE] = or_bits(SymTab[sym][S_USAGE], U_READ)
				-- don't emit an INIT_CHECK, so object() can see if it is NOVALUE or not
				emit_opnd(sym)
			end if
			putback( tok3 )

		elsif tok3[T_ID] = COMMA then
			-- give a sane error message
			WrongNumberArgs(tok[T_SYM], "")

		elsif tok3[T_ID] = LEFT_ROUND then
			if SymTab[tok2[T_SYM]][S_SCOPE] = SC_UNDEFINED then
				Forward_call( tok2, FUNC_FORWARD )
			else
				Function_call( tok2 )
			end if
		else
			-- since we can only put back
			-- one token, and we already took
			-- two, we need to manually do the
			-- parse args ourselves.
			-- The only possible valid case is
			-- a variable followed by a slice
			sym = tok2[T_SYM]
			if SymTab[sym][S_SCOPE] = SC_UNDEFINED then
				Forward_var( tok2, TRUE )
			else
				SymTab[sym][S_USAGE] = or_bits(SymTab[sym][S_USAGE], U_READ)
				InitCheck(sym, TRUE)
				emit_opnd(sym)
			end if


			if sym = left_sym then
				lhs_subs_level = 0
				-- start counting subscripts
			end if

			--short_circuit -= 1
			tok2 = tok3
			current_sequence = append(current_sequence, sym)
			while tok2[T_ID] = LEFT_SQUARE do
				subs_depth += 1
				if lhs_subs_level >= 0 then
					lhs_subs_level += 1
				end if
				save_factors = factors
				save_lhs_subs_level = lhs_subs_level
				call_proc(forward_expr, {})
				tok2 = next_token()
				if tok2[T_ID] = SLICE then
					call_proc(forward_expr, {})
					emit_op(RHS_SLICE)
					tok_match(RIGHT_SQUARE)
					tok2 = next_token()
					exit
				else
					putback(tok2)
					tok_match(RIGHT_SQUARE)
					subs_depth -= 1
					current_sequence = current_sequence[1..$-1]
					emit_op(RHS_SUBS)
					-- current_sequence will be updated
				end if
				factors = save_factors
				lhs_subs_level = save_lhs_subs_level
				tok2 = next_token()
			end while
			current_sequence = current_sequence[1..$-1]
			putback(tok2)
			--short_circuit += 1

		end if
		tok_match( RIGHT_ROUND )
	else
		putback(tok2)
		ParseArgs(tok[T_SYM])
	end if
end procedure

procedure Function_call( token tok )
--	token tok2, tok3
	integer id, scope, opcode, e

	id = tok[T_ID]
	if id = FUNC or id = TYPE then
		-- to warn if not in include tree
		UndefinedVar( tok[T_SYM] )
	end if

	e = SymTab[tok[T_SYM]][S_EFFECT]
	if e then
		-- the routine we are calling has side-effects
		if e = E_ALL_EFFECT or tok[T_SYM] > left_sym then
			-- it can access the LHS var (it uses indirect calls or comes later)
			side_effect_calls = or_bits(side_effect_calls, e)
		end if

		SymTab[CurrentSub][S_EFFECT] = or_bits(SymTab[CurrentSub][S_EFFECT], e)

		if short_circuit > 0 and short_circuit_B and
				  find(id, FUNC_TOKS) then
			Warning(219, short_circuit_warning_flag,
				{abbreviate_path(known_files[current_file_no]), line_number,SymTab[tok[T_SYM]][S_NAME]})
		end if
	end if
	tok_match(LEFT_ROUND)
	scope = SymTab[tok[T_SYM]][S_SCOPE]
	opcode = SymTab[tok[T_SYM]][S_OPCODE]
	if equal(SymTab[tok[T_SYM]][S_NAME],"object") and scope = SC_PREDEF then
		-- handled specially to check for uninitialized variables
		Object_call( tok )

	else
		ParseArgs(tok[T_SYM])
	end if

	if scope = SC_PREDEF then
		emit_op(opcode)
	else
		op_info1 = tok[T_SYM]
-- 		emit_op(PROC)
		emit_or_inline()
		if not TRANSLATE then
			if OpTrace then
				emit_op(UPDATE_GLOBALS)
			end if
		end if
	end if
end procedure

procedure Factor()
-- parse a factor in an expression
	token tok
	integer id, n
	integer save_factors, save_lhs_subs_level
	symtab_index sym

	factors += 1
	tok = next_token()
	id = tok[T_ID]
	if id = RECORDED then
		tok = read_recorded_token(tok[T_SYM])
		id = tok[T_ID]
	end if
	switch id label "factor" do
		case MEMSTRUCT, QUALIFIED_MEMSTRUCT, MEMUNION, QUALIFIED_MEMUNION then
			-- probably needs error checking or something to make sure 
			-- the struct makes sense
			-- So far, only sizeof() can use this
			emit_opnd( tok[T_SYM] )
			
		case VARIABLE, QUALIFIED_VARIABLE then
			sym = tok[T_SYM]
			if sym < 0 or SymTab[sym][S_SCOPE] = SC_UNDEFINED then
				token forward = next_token()
				if forward[T_ID] = LEFT_ROUND then
					Forward_call( tok, FUNC_FORWARD )
					break "factor"
				else
					putback( forward )
					Forward_var( tok, TRUE )
				end if

			else
				UndefinedVar(sym)
				SymTab[sym][S_USAGE] = or_bits(SymTab[sym][S_USAGE], U_READ)
				InitCheck(sym, TRUE)
				emit_opnd(sym)
			end if

			if sym = left_sym then
				lhs_subs_level = 0 -- start counting subscripts
			end if

			short_circuit -= 1
			tok = next_token()
			
			
			if tok[T_ID] = DOT then
				MemStruct_access( sym, FALSE )
			else
				current_sequence = append(current_sequence, sym)
				while tok[T_ID] = LEFT_SQUARE do
					subs_depth += 1
					if lhs_subs_level >= 0 then
						lhs_subs_level += 1
					end if
					save_factors = factors
					save_lhs_subs_level = lhs_subs_level
					call_proc(forward_expr, {})
					tok = next_token()
					if tok[T_ID] = SLICE then
						call_proc(forward_expr, {})
						emit_op(RHS_SLICE)
						tok_match(RIGHT_SQUARE)
						tok = next_token()
						exit
					else
						putback(tok)
						tok_match(RIGHT_SQUARE)
						subs_depth -= 1
						current_sequence = head( current_sequence, length( current_sequence ) - 1 )
						emit_op(RHS_SUBS) -- current_sequence will be updated
					end if
					factors = save_factors
					lhs_subs_level = save_lhs_subs_level
					tok = next_token()
				end while
				current_sequence = head( current_sequence, length( current_sequence ) - 1 )
				putback(tok)
			end if
			
			short_circuit += 1

		case DOLLAR then
			tok = next_token()
			putback(tok)
			if tok[T_ID] = RIGHT_BRACE then
				gListItem[$] = 0
			else
				if subs_depth > 0 and length(current_sequence) then
					emit_op(DOLLAR)
				else
					CompileErr(21)
				end if
 			end if

		case ATOM then
			emit_opnd(tok[T_SYM])

		case LEFT_BRACE then
			n = Expr_list()
			tok_match(RIGHT_BRACE)
			op_info1 = n
			emit_op(RIGHT_BRACE_N)

		case STRING then
			emit_opnd(tok[T_SYM])

		case LEFT_ROUND then
			call_proc(forward_expr, {})
			tok_match(RIGHT_ROUND)

		case FUNC, TYPE, QUALIFIED_FUNC, QUALIFIED_TYPE then
			Function_call( tok )

		case else
			CompileErr(135, {LexName(id)})
	end switch
end procedure

procedure UFactor()
-- parse an optional unary op applied to a factor
	token tok

	tok = next_token()

	if tok[T_ID] = MINUS then
		Factor()
		emit_op(UMINUS)

	elsif tok[T_ID] = NOT then
		Factor()
		emit_op(NOT)

	elsif tok[T_ID] = PLUS then
		Factor()

	else
		putback(tok)
		Factor()

	end if
end procedure

function Term()
-- parse a term in an expression
	token tok

	UFactor()
	tok = next_token()
	while tok[T_ID] = MULTIPLY or tok[T_ID] = DIVIDE do
		UFactor()
		emit_op(tok[T_ID])
		tok = next_token()
	end while
	return tok
end function

function aexpr()
-- Parse an arithmetic expression
	token tok
	integer id

	tok = Term()
	while tok[T_ID] = PLUS or tok[T_ID] = MINUS do
		id = tok[T_ID]
		tok = Term()
		emit_op(id)
	end while
	return tok
end function

function cexpr()
-- Parse a concatenation expression
	token tok
	integer concat_count

	tok = aexpr()
	concat_count = 0
	while tok[T_ID] = CONCAT do
		tok = aexpr()
		concat_count += 1
	end while

	if concat_count = 1 then
		emit_op(CONCAT)

	elsif concat_count > 1 then
		op_info1 = concat_count+1
		emit_op(CONCAT_N)
	end if

	return tok
end function

-- Parse a relational expression
function rexpr()
	token tok
	integer id

	tok = cexpr()
	while tok[T_ID] <= GREATER and tok[T_ID] >= LESS do
		id = tok[T_ID]
		tok = cexpr()
		emit_op(id)
	end while
	return tok
end function

constant boolOps = {OR, AND, XOR}
export sequence ExprLine
export integer expr_bp
export procedure Expr()
-- Parse a general expression
-- Use either short circuit or full evaluation.
	token tok
	integer id
	integer patch

	ExprLine = ThisLine
	expr_bp = bp
	id = -1
	patch = 0
	while TRUE do
		if id != -1 then
			if id != XOR then
				if short_circuit > 0 then
					if id = OR then
						emit_op(SC1_OR)
					else
						emit_op(SC1_AND)
					end if
					patch = length(Code)+1
					emit_forward_addr()
					short_circuit_B = TRUE
				end if
			end if
		end if

		tok = rexpr()

		if id != -1 then
			if id != XOR then
				if short_circuit > 0 then
					if tok[T_ID] != THEN and tok[T_ID] != DO then
						if id = OR then
							emit_op(SC2_OR)
						else
							emit_op(SC2_AND)
						end if
					else
						SC1_type = id -- if/while/elsif must patch
						emit_op(SC2_NULL)
					end if
					if TRANSLATE then
						emit_op(NOP1)   -- to get label here
					end if
					backpatch(patch, length(Code)+1)
				else
					emit_op(id)
				end if
			else
				emit_op(id)
			end if
		end if
		id = tok[T_ID]
		if not find(id, boolOps) then
			exit
		end if
	end while
	putback(tok)
	SC1_patch = patch -- extra line
end procedure

forward_expr = routine_id("Expr")

procedure emit_mem_type_check( symtab_index var, symtab_index type_sym, symtab_index member_sym, symtab_index pointer, integer op )
	if op != MEMSTRUCT_ASSIGN then
		-- We have to read the value first via PEEK_MEMBER
		emit_opnd( pointer )
		emit_opnd( member_sym )
		emit_op( PEEK_MEMBER )
	else
		emit_opnd( var )
	end if
	
	op_info1 = type_sym
	emit_or_inline()
	emit_opnd( member_sym )
	emit_op(MEM_TYPE_CHECK)
end procedure

procedure MemTypeCheck( symtab_index var, symtab_index member_sym, symtab_index pointer, integer op )
	integer type_sym = SymTab[member_sym][S_MEM_TYPE]
	if 0 = type_sym then
		-- no type for this member
		return
	end if
	
	if TRANSLATE then
		if OpTypeCheck then
			if SymTab[type_sym][S_EFFECT] then
				-- only call those with side effects
				emit_mem_type_check( var, type_sym, member_sym, pointer, op )
			end if
		end if
	else
		if OpTypeCheck then
			emit_mem_type_check( var, type_sym, member_sym, pointer, op )
		end if
	end if
	
end procedure

procedure TypeCheck(symtab_index var)
-- emit code to type-check a var (after it has been assigned-to)
	integer which_type

	if var < 0 or SymTab[var][S_SCOPE] = SC_UNDEFINED then
		-- forward reference, so defer type check until later
		integer ref = new_forward_reference( TYPE_CHECK, var, TYPE_CHECK_FORWARD )
		Code &= { TYPE_CHECK_FORWARD, var, OpTypeCheck }
		return
	end if

	which_type = SymTab[var][S_VTYPE]
	if which_type = 0 then
		return	-- Not a typed identifier.
	end if
	if which_type > 0 and length(SymTab[which_type]) < S_TOKEN then
		return	-- Not a typed identifier.
	end if

	if which_type < 0 or SymTab[which_type][S_TOKEN] = VARIABLE  then
		integer ref = new_forward_reference( TYPE_CHECK, which_type, TYPE )
		Code &= { TYPE_CHECK_FORWARD, var, OpTypeCheck }

		return
	end if

	if TRANSLATE then
		if OpTypeCheck then
			switch which_type do
				case object_type, sequence_type, atom_type then
					-- do nothing
				case integer_type then
					-- need to do this to coerce atoms to integers
					op_info1 = var
					emit_op(INTEGER_CHECK)
				case else
					if SymTab[which_type][S_EFFECT] then
						-- only call user-defined types that have side-effects
						emit_opnd(var)
						op_info1 = which_type
						--emit_op(PROC)
						emit_or_inline()
						emit_op(TYPE_CHECK)
					end if
			end switch
		end if

	else
		if OpTypeCheck then
			if which_type != object_type then
				if which_type = integer_type then
						op_info1 = var
						emit_op(INTEGER_CHECK)

				elsif which_type = sequence_type then
						op_info1 = var
						emit_op(SEQUENCE_CHECK)

				elsif which_type = atom_type then
						op_info1 = var
						emit_op(ATOM_CHECK)

				else
						-- user-defined
						if SymTab[SymTab[which_type][S_NEXT]][S_VTYPE] =
						   integer_type then
							op_info1 = var
							emit_op(INTEGER_CHECK) -- need integer conversion
						end if
						emit_opnd(var)
						op_info1 = which_type
						emit_or_inline()
-- 						emit_op(PROC)
						emit_op(TYPE_CHECK)
				end if
			end if
		end if
	end if

	if TRANSLATE or not OpTypeCheck then
		op_info1 = var
		if which_type = sequence_type or
			SymTab[SymTab[which_type][S_NEXT]][S_VTYPE] = sequence_type then
			-- check sequences anyway, so we can avoid it on subscripting etc.
			emit_op(SEQUENCE_CHECK)

		elsif which_type = integer_type or
				 SymTab[SymTab[which_type][S_NEXT]][S_VTYPE] = integer_type then
				 -- check integers too
			emit_op(INTEGER_CHECK)
		end if
	end if
end procedure

function check_assign_op( token left_var )
	token tok = next_token()
	integer assign_op = tok[T_ID]
	
	if not find(assign_op, ASSIGN_OPS) then
		sequence lname = sym_name( left_var[T_SYM] )
		if assign_op = DOT then
			-- memstruct
			MemStruct_access( left_var[T_SYM], TRUE )
			assign_op = check_assign_op( left_var )
			integer ox = find( assign_op, ASSIGN_OPS )
			assign_op = 0
			if ox then
				assign_op = MEMSTRUCT_ASSIGN_OPS[ox]
			end if
			if not assign_op then
				CompileErr(76, {lname})
			end if
			return assign_op
		
		elsif assign_op = COLON then
			CompileErr(133, {lname})
		else
			CompileErr(76, {lname})
		end if
	end if
	return assign_op
end function

procedure Assignment(token left_var)
-- parse an assignment statement
	token tok
	integer subs, slice, assign_op, subs1_patch
	boolean dangerous  -- tricky subscripted assignment

	left_sym = left_var[T_SYM]
	if SymTab[left_sym][S_SCOPE] = SC_UNDEFINED then
		Forward_var( left_var, ,ASSIGN )
		left_sym = Pop() -- pops off what forward var emitted, because it gets emitted later
	else
		UndefinedVar(left_sym)
		if SymTab[left_sym][S_SCOPE] = SC_LOOP_VAR or
		SymTab[left_sym][S_SCOPE] = SC_GLOOP_VAR then
			CompileErr(109)

		elsif SymTab[left_sym][S_MODE] = M_CONSTANT then
			CompileErr(110)

		elsif find(SymTab[left_sym][S_SCOPE], SCOPE_TYPES) then
			-- this helps us to optimize things below
			SymTab[CurrentSub][S_EFFECT] = or_bits(SymTab[CurrentSub][S_EFFECT],
											power(2, remainder(left_sym, E_SIZE)))
		end if

		SymTab[left_sym][S_USAGE] = or_bits(SymTab[left_sym][S_USAGE], U_WRITTEN)
	end if



	tok = next_token()
	subs = 0
	slice = FALSE

	dangerous = FALSE
	side_effect_calls = 0

	-- Process LHS subscripts and slice
	emit_opnd(left_sym)
	current_sequence = append(current_sequence, left_sym)

	while tok[T_ID] = LEFT_SQUARE do
		subs_depth += 1
		if lhs_ptr then
			-- multiple lhs subscripts, evaluate first n-1 of them with this
			current_sequence = head( current_sequence, length( current_sequence ) - 1 )
			if subs = 1 then
				-- first subscript of 2 or more
				subs1_patch = length(Code)+1
				emit_op(LHS_SUBS1) -- creates new current_sequence
								   -- opcode might be patched (below)
			else
				emit_op(LHS_SUBS) -- adds to current_sequence
			end if
		end if
		subs += 1
		if subs = 1 then
			InitCheck(left_sym, TRUE)
		end if
		Expr()
		tok = next_token()
		if tok[T_ID] = SLICE then
			Expr()
			slice = TRUE
			tok_match(RIGHT_SQUARE)
			tok = next_token()
			exit  -- no further subs or slices allowed
		else
			putback(tok)
			tok_match(RIGHT_SQUARE)
			subs_depth -= 1
		end if
		tok = next_token()
		lhs_ptr = TRUE
	end while

	lhs_ptr = FALSE
	
	putback( tok )
	assign_op = check_assign_op( left_var )

	if subs = 0 label "subs_if" then
		-- not subscripted
		integer temp_len = length(Code)
		switch assign_op do
			case EQUALS then
				Expr() -- RHS expression
				InitCheck(left_sym, FALSE)
			
			case MEMSTRUCT_ASSIGN, MEMSTRUCT_PLUS, MEMSTRUCT_MINUS, 
					MEMSTRUCT_MULTIPLY, MEMSTRUCT_DIVIDE then
				
				Expr()
				integer top = length( Code )
				emit_op( assign_op )
				MemTypeCheck( Code[$], Code[$-1], Code[top], assign_op )
				break "subs_if"
			case else
				InitCheck(left_sym, TRUE)
				if left_sym > 0 then
					SymTab[left_sym][S_USAGE] = or_bits(SymTab[left_sym][S_USAGE], U_READ)
				end if
				emit_opnd(left_sym)
				Expr() -- RHS expression
				emit_assign_op(assign_op)
				
		end switch
		emit_op(ASSIGN)
		TypeCheck(left_sym)
	else
		-- subscripted
		factors = 0
		lhs_subs_level = -1
		Expr() -- RHS expression

		if subs > 1 then
			if left_sym < 0 or SymTab[left_sym][S_SCOPE] != SC_PRIVATE and
			   and_bits(side_effect_calls,
						power(2, remainder(left_sym, E_SIZE))) then
				-- this var might be overwritten by a function call while
				-- we are executing this statement
				dangerous = TRUE
			end if

			if factors = 1 and
			   lhs_subs_level >= 0 and
			   lhs_subs_level < subs+slice then
				-- must avoid a possible circular reference
				dangerous = TRUE
			end if

			if dangerous then
				-- Patch earlier op so it will copy lhs var to
				-- a temp to avoid any problem.
				-- (This danger became greater when we implemented $ for 2.5,
				-- and had to interleave LHS subscripting with expression
				-- evaluation).
				backpatch(subs1_patch, LHS_SUBS1_COPY)
			end if
		end if

		if slice then
			if assign_op != EQUALS then
				if subs = 1 then
					emit_op(ASSIGN_OP_SLICE)
				else
					emit_op(PASSIGN_OP_SLICE)
				end if
				emit_assign_op(assign_op)
			end if
			if subs = 1 then
				emit_op(ASSIGN_SLICE)
			else
				emit_op(PASSIGN_SLICE)
			end if
		else
			if assign_op = EQUALS then
				if subs = 1 then
					emit_op(ASSIGN_SUBS)
				else
					emit_op(PASSIGN_SUBS)
				end if
			else
				if subs = 1 then
					emit_op(ASSIGN_OP_SUBS)
				else
					emit_op(PASSIGN_OP_SUBS)
				end if
				emit_assign_op(assign_op)
				if subs = 1 then
					emit_op(ASSIGN_SUBS2)
				else
					emit_op(PASSIGN_SUBS)
				end if
			end if
		end if

		if subs > 1 then
			if dangerous then
				-- copy temp back into lhs var
				emit_opnd(left_sym)
				emit_opnd(lhs_subs1_copy_temp) -- will be freed
				emit_temp( lhs_subs1_copy_temp, NEW_REFERENCE )
				emit_op(ASSIGN)

			else
				TempFree(lhs_subs1_copy_temp)
			end if
		end if

		if OpTypeCheck and (left_sym < 0 or SymTab[left_sym][S_VTYPE] != sequence_type) then
			TypeCheck(left_sym)
		end if
	end if

	current_sequence = head( current_sequence, length( current_sequence ) - 1 )

	if not TRANSLATE then
		if OpTrace then
			emit_op(DISPLAY_VAR)
			emit_addr(left_sym)
		end if
	end if
end procedure

procedure Return_statement()
-- Parse a return statement
	token tok
	integer pop
	if CurrentSub = TopLevelSub then
		CompileErr(130)
	end if

	integer
		last_op = Last_op(),
		last_pc = Last_pc(),
		is_tail = 0

	if last_op = PROC and length(Code) > last_pc and Code[last_pc+1] = CurrentSub then
		is_tail = 1
	end if

	if not TRANSLATE then
		if OpTrace then
			emit_op(ERASE_PRIVATE_NAMES)
			emit_addr(CurrentSub)
		end if
	end if
	if SymTab[CurrentSub][S_TOKEN] != PROC then
		Expr()
		last_op = Last_op()
		last_pc = Last_pc()
		if last_op = PROC and length(Code) > last_pc and Code[last_pc+1] = CurrentSub then
			pop = Pop() -- prevent cg_stack (code generation stack) leakage
			Code[Last_pc()] = PROC_TAIL
			if object(pop_temps()) then end if
		else
			FuncReturn = TRUE
			emit_op(RETURNF)
		end if
	else
		if is_tail then
			Code[Last_pc()] = PROC_TAIL
		end if
		emit_op(RETURNP)

	end if
	tok = next_token()
	putback(tok)
	NotReached(tok[T_ID], "return")
end procedure

function exit_level(token tok, integer flag)
-- determines optional parameter for continue/exit/retry/switch
	atom arg
	integer n
	integer num_labels
	integer negative = 0
	sequence labels

	if flag then
		labels = if_labels
	else
		labels = loop_labels
	end if
	num_labels = length(labels)

	if tok[T_ID] = MINUS then
		tok = next_token()
		negative = 1
	end if

	if tok[T_ID]=ATOM then
		arg = SymTab[tok[T_SYM]][S_OBJ]
		n = floor(arg)
		if negative then
			n = num_labels - n
		elsif n = 0 then
			n = num_labels
		end if
		if n<=0 or n>num_labels then
			CompileErr(87)
		end if
		return {n, next_token()}
	elsif tok[T_ID]=STRING then
		n = find(SymTab[tok[T_SYM]][S_OBJ],labels)
		if n = 0 then
			CompileErr(152)
		end if
		return {num_labels + 1 - n, next_token()}
	else
		return {1, tok} -- no parameters
	end if
end function

procedure GLabel_statement()
	token tok
	object labbel
	object laddr
	integer n

	tok = next_token()

	if tok[T_ID] != STRING then
		CompileErr(35)
	end if

	labbel = SymTab[tok[T_SYM]][S_OBJ]
	laddr = length(Code) + 1

	if find(labbel, goto_labels) then
		CompileErr(59)
	end if

	goto_labels = append(goto_labels, labbel)
	goto_addr = append(goto_addr, laddr)
	label_block = append( label_block, top_block() )

	while n with entry do
		backpatch(goto_list[n], laddr)
		set_glabel_block( goto_ref[n], top_block() )
		goto_delay[n] = "" --clear it
		goto_line[n] = {-1,""} --clear it

	entry
		n = find(labbel, goto_delay)
	end while

	if TRANSLATE then
		emit_op(GLABEL)
		emit_addr(laddr)
	end if
end procedure

procedure Goto_statement()
-- Parse an exit statement
	token tok
	integer n
	integer num_labels

	tok = next_token()
	num_labels = length(goto_labels)

	if tok[T_ID]=STRING then
		n = find(SymTab[tok[T_SYM]][S_OBJ],goto_labels)
		if n = 0 then
			goto_delay &= {SymTab[tok[T_SYM]][S_OBJ]}
			goto_list &= length(Code)+2 --not 1???
			goto_line &= {{line_number,ThisLine}}
			goto_ref &= new_forward_reference( GOTO, top_block() )
			add_data( goto_ref[$], sym_obj( tok[T_SYM] ) )
			set_line( goto_ref[$], line_number, ThisLine, bp )
		else
			Goto_block( top_block(), label_block[n] )
		end if
		tok = next_token()
	else
		CompileErr(96)
	end if

	emit_op(GOTO)
	if n = 0 then
		emit_addr(0) -- to be back-patched
	else
		emit_addr(goto_addr[n])
	end if

	putback(tok)
	NotReached(tok[T_ID], "goto")
end procedure

procedure Exit_statement()
-- Parse an exit statement
	token tok
	sequence by_ref

	if not length(loop_stack) then
		CompileErr(88)
	end if

	by_ref = exit_level(next_token(),0) -- can't pass tok by reference
	Leave_blocks( by_ref[1], LOOP_BLOCK )
	emit_op(EXIT)
	AppendXList(length(Code)+1)
	exit_delay &= by_ref[1]
	emit_forward_addr()    -- to be back-patched
	tok = by_ref[2]
	putback(tok)
end procedure

procedure Continue_statement()
-- Parse a continue statement
	token tok
	sequence by_ref
	integer loop_level

	if not length(loop_stack) then
		CompileErr(49)
	end if

	by_ref = exit_level(next_token(),0) -- can't pass tok by reference
	Leave_blocks( by_ref[1], LOOP_BLOCK )
	emit_op(ELSE)
	loop_level = by_ref[1]

	-- num_labels+1-n
	if continue_addr[$+1-loop_level] then -- address is known for while loops
		if continue_addr[$+1-loop_level] < 0 then
			-- it's in a switch statement
			CompileErr(49)
		end if
		emit_addr(continue_addr[$+1-loop_level])
	else  -- for loop increment code/repeat loop end of loop test
		AppendNList(length(Code)+1)
		continue_delay &= loop_level
		emit_forward_addr()    -- to be back-patched
	end if

	tok = by_ref[2]
	putback(tok)

	NotReached(tok[T_ID], "continue")
end procedure

procedure Retry_statement()
-- Parse a retry statement
-- no backpatching here, since top of loop is always known
	sequence by_ref
	token tok

	if not length(loop_stack) then
		CompileErr(131)
	end if

	by_ref = exit_level(next_token(),0) -- can't pass tok by reference
	Leave_blocks( by_ref[1], LOOP_BLOCK )
	if loop_stack[$+1-by_ref[1]]=FOR then
		emit_op(RETRY) -- for Translator to emit a label at the right place
	else
		if retry_addr[$+1-by_ref[1]] < 0 then
			-- it's in a switch statement
			CompileErr(131)
		end if
		emit_op(ELSE)
	end if

	emit_addr(retry_addr[$+1-by_ref[1]])
	tok = by_ref[2]
	putback(tok)
	NotReached(tok[T_ID], "retry")
end procedure

function in_switch()
	if length( if_stack ) and if_stack[$] = SWITCH then
		return 1
	else
		return 0
	end if
end function

procedure Break_statement()
	token tok
	sequence by_ref

	if not length(if_labels) then
		CompileErr(40)
	end if

	by_ref = exit_level(next_token(),1)
	Leave_blocks( by_ref[1], CONDITIONAL_BLOCK )
	emit_op(ELSE)
	AppendEList(length(Code)+1)

	break_delay &= by_ref[1]
	emit_forward_addr()    -- to be back-patched
	tok = by_ref[2]
	putback(tok)
	NotReached(tok[T_ID], "break")
end procedure

integer forward_Statement_list

function finish_block_header(integer opcode)
	token tok
	object labbel
	integer has_entry

	tok = next_token()
	has_entry=0

	if tok[T_ID] = WITH then
		tok = next_token()
		switch tok[T_ID] do
		    case ENTRY then
				if not (opcode = WHILE or opcode = LOOP) then
					CompileErr(14)
				end if

			    has_entry = 1

			case FALLTHRU then
				if not opcode = SWITCH then
					CompileErr(13)
				end if

				switch_stack[$][SWITCH_FALLTHRU] = 1

			case else
			    CompileErr(27)
        end switch

        tok = next_token()
	elsif tok[T_ID] = WITHOUT then
		tok = next_token()
		if tok[T_ID] = FALLTHRU then
			if not opcode = SWITCH then
				CompileErr(15)
			end if

			switch_stack[$][SWITCH_FALLTHRU] = 0

		else
			CompileErr(27)
		end if
        tok = next_token()
	end if

	labbel=0
	if tok[T_ID]=LABEL then
		tok = next_token()
		if tok[T_ID] != STRING then
			CompileErr(38)
		end if
		labbel = SymTab[tok[T_SYM]][S_OBJ]
		block_label( labbel )
		tok = next_token()
	end if
	if opcode = IF or opcode = SWITCH then
		if_labels = append(if_labels,labbel)
	else
		loop_labels = append(loop_labels,labbel)
	end if
	if block_index=length(block_list) then
	    block_list &= opcode
	    block_index += 1
	else
	    block_index += 1
	    block_list[block_index] = opcode
	end if
	if tok[T_ID]=ENTRY then
	    if has_entry then
	        CompileErr(64)
	    end if
	    has_entry=1
	    tok=next_token()
	end if
	if has_entry and (opcode = IF or opcode = SWITCH) then
		CompileErr(80)
	end if
	if opcode = IF then
		opcode = THEN
	else
		opcode = DO
	end if
	putback(tok)
	tok_match(opcode)
	return has_entry
end function


procedure If_statement()
-- parse an if statement with optional elsif's and optional else
	token tok
	integer prev_false
	integer prev_false2
	integer elist_base

	if_stack &= IF

	Start_block( IF )

	elist_base = length(break_list)
	short_circuit += 1
	short_circuit_B = FALSE
	SC1_type = 0
	Expr()

	sequence temps = get_temps()

	emit_op(IF)
	prev_false = length(Code)+1
	emit_forward_addr() -- to be patched
	prev_false2=finish_block_header(IF)  -- 0
	if SC1_type = OR then
		backpatch(SC1_patch-3, SC1_OR_IF)
		if TRANSLATE then
			emit_op(NOP1)  -- to get label here
		end if
		backpatch(SC1_patch, length(Code)+1)
	elsif SC1_type = AND then
		backpatch(SC1_patch-3, SC1_AND_IF)
		prev_false2 = SC1_patch
	end if
	short_circuit -= 1


	Statement_list()
	tok = next_token()

	while tok[T_ID] = ELSIF do
		Sibling_block( IF )


		emit_op(ELSE)
		AppendEList(length(Code)+1)
		break_delay &= 1
		emit_forward_addr()  -- to be patched
		if TRANSLATE then
			emit_op(NOP1)
		end if
		backpatch(prev_false, length(Code)+1)
		if prev_false2 != 0 then
			backpatch(prev_false2, length(Code)+1)
		end if

		StartSourceLine(TRUE)
		short_circuit += 1
		short_circuit_B = FALSE
		SC1_type = 0

		push_temps( temps )
		Expr()

		temps = get_temps( temps )

		emit_op(IF)
		prev_false = length(Code)+1
		prev_false2 = 0
		emit_forward_addr() -- to be patched
		if SC1_type = OR then
			backpatch(SC1_patch-3, SC1_OR_IF)
			if TRANSLATE then
				emit_op(NOP1)
			end if
			backpatch(SC1_patch, length(Code)+1)
		elsif SC1_type = AND then
			backpatch(SC1_patch-3, SC1_AND_IF)
			prev_false2 = SC1_patch
		end if
		short_circuit -= 1
		tok_match(THEN)


		Statement_list()
		tok = next_token()
	end while

	if tok[T_ID] = ELSE or length(temps[1]) then
		-- if there was no else, but temps were emitted during
		-- the initial if condition check, then we need to
		-- create a 'fake' else block to release those temps

		Sibling_block( IF )

		StartSourceLine(FALSE, , COVERAGE_SUPPRESS )
		emit_op(ELSE)
		AppendEList(length(Code)+1)
		break_delay &= 1
		emit_forward_addr() -- to be patched
		if TRANSLATE then
			emit_op(NOP1)
		end if
		backpatch(prev_false, length(Code)+1)
		if prev_false2 != 0 then
			backpatch(prev_false2, length(Code)+1)
		end if

		push_temps( temps )

		if tok[T_ID] = ELSE then
			Statement_list()
		else
			putback(tok)
		end if
	else
		putback(tok)
		if TRANSLATE then
			emit_op(NOP1)
		end if
		backpatch(prev_false, length(Code)+1)
		if prev_false2 != 0 then
			backpatch(prev_false2, length(Code)+1)
		end if
	end if

	tok_match(END)
	tok_match(IF, END)

	End_block( IF )

	if TRANSLATE then
		if length(break_list) > elist_base then
			emit_op(NOP1)  -- to emit label here
		end if
	end if
	PatchEList(elist_base)
	if_labels = if_labels[1..$-1]
	block_index -= 1
	if_stack = if_stack[1..$-1]

end procedure

procedure exit_loop(integer exit_base)
	PatchXList(exit_base)
	loop_labels = loop_labels[1..$-1]
	loop_stack = loop_stack[1..$-1]
	continue_addr = continue_addr[1..$-1]
	retry_addr = retry_addr[1..$-1]
	entry_addr = entry_addr[1..$-1]
	block_index -= 1
end procedure

procedure push_switch()
	if_stack &= SWITCH
	switch_stack = append( switch_stack, { {}, {}, 0, 0, 0, 0 })
end procedure

procedure pop_switch( integer break_base )
--	loop_stack    = loop_stack[1..$-1]
--	loop_labels   = loop_labels[1..$-1]
	PatchEList( break_base )
	block_index -= 1
	if length(switch_stack[$][SWITCH_CASES]) > 0 then
		End_block( CASE )
	end if
	if_labels = if_labels[1..$-1]
	if_stack  = if_stack[1..$-1]
	switch_stack  = switch_stack[1..$-1]
end procedure

procedure add_case( object sym, integer sign )

	if sign < 0 then
		sym = -sym
	end if

	if find(sym, switch_stack[$][SWITCH_CASES] ) = 0 then
		switch_stack[$][SWITCH_CASES]       = append( switch_stack[$][SWITCH_CASES], sym )
		switch_stack[$][SWITCH_JUMP_TABLE] &= length(Code) + 1

		if TRANSLATE then
			emit_addr( CASE )
			emit_addr( length( switch_stack[$][SWITCH_CASES] ) )
		end if
	else
		CompileErr( 63 )
	end if
end procedure

function else_case()
	return switch_stack[$][SWITCH_ELSE]
end function

procedure case_else()
	switch_stack[$][SWITCH_ELSE] = length(Code) + 1
	if TRANSLATE then
		emit_addr( CASE )
		emit_addr( 0 )
	end if

end procedure

integer fallthru_case = 0
procedure Case_statement()
	token tok
	symtab_index condition

	if not in_switch() then
		CompileErr( 34 )
	end if

	if length(switch_stack[$][SWITCH_CASES]) > 0 then
		-- Not the first case in this switch so end the current block and start a new one.
		Sibling_block( CASE )

		if not switch_stack[$][SWITCH_FALLTHRU] and
		   not fallthru_case then
			-- This is not a 'fallthru' switch and the previous case did not
			-- end with a fallthru statement so we must insert a 'break' now.
			putback( {CASE, 0} )
			Break_statement()
			tok = next_token()
		end if
	else
		Start_block( CASE )
	end if

	StartSourceLine(TRUE, , COVERAGE_SUPPRESS)

	fallthru_case = 0
	integer start_line = line_number
	while 1 do

		if else_case() then
			CompileErr( 33 )
		end if
		maybe_namespace()
		tok = next_token()
		integer sign = 1
		if tok[T_ID] = MINUS then
			sign = -1
			tok = next_token()
		elsif tok[T_ID] = PLUS then
			tok = next_token()
		end if

		integer fwd
		if not find( tok[T_ID], {ATOM, STRING, ELSE} ) then

			integer symi = tok[T_SYM]
			fwd = -1
			if symi > 0 then
				if find(tok[T_ID] , VAR_TOKS) then
					if SymTab[symi][S_SCOPE] = SC_UNDEFINED then
						-- forward reference to a variable
						fwd = symi
					elsif SymTab[symi][S_MODE] = M_CONSTANT then
						fwd = 0
						if SymTab[symi][S_CODE] then
							tok[T_SYM] = SymTab[symi][S_CODE]
						end if
						SymTab[symi][S_USAGE] = or_bits( SymTab[symi][S_USAGE], U_READ )
					end if
				end if
			end if
		else
			fwd = 0
		end if

		if fwd < 0 then
			CompileErr( 91, {find_category(tok[T_ID])})
		end if

		if tok[T_ID] = ELSE then
			if sign = -1 then
				CompileErr( 71 )
			end if
			if length(switch_stack[$][SWITCH_CASES]) = 0 then
				CompileErr( 44 )
			end if
			case_else()
			exit

		elsif fwd then
			integer fwdref = new_forward_reference( CASE, fwd )
			add_case( {fwdref}, sign )
			fwd:set_data( fwdref, switch_stack[$][SWITCH_PC] )

		else
			condition = tok[T_SYM]
			add_case( condition, sign )
		end if

		tok = next_token()
		if tok[T_ID] = THEN then
			tok = next_token()

			if tok[T_ID] = CASE then
				if switch_stack[$][SWITCH_FALLTHRU] then
					start_line = line_number
				else
					putback( tok )
					Warning(220, empty_case_warning_flag,
						{known_files[current_file_no], start_line} )
					exit
				end if
			else
				putback( tok )
				exit
			end if

		elsif tok[T_ID] != COMMA then
			CompileErr(66,{LexName(tok[T_ID])})

		end if
	end while
	StartSourceLine( TRUE )
	emit_temp( switch_stack[$][SWITCH_VALUE], NEW_REFERENCE )
	flush_temps()
end procedure

procedure Fallthru_statement()
	if not in_switch() then
		CompileErr( 22 )
	end if
	tok_match( CASE )
	fallthru_case = 1
	Case_statement()
end procedure

-- We modified the value of something, and need to update translator info,
-- or else it may improperly optimize things.
procedure update_translator_info( symtab_index sym, integer all_ints, integer has_integer, integer has_atom, integer has_sequence )
	SymTab[sym][S_MODE] = M_TEMP    -- override CONSTANT for compile
	SymTab[sym][S_GTYPE] = TYPE_SEQUENCE
	SymTab[sym][S_SEQ_LEN] = length( SymTab[sym][S_OBJ] )

	if SymTab[sym][S_SEQ_LEN] > 0 then
		if all_ints then
			SymTab[sym][S_SEQ_ELEM] = TYPE_INTEGER

		elsif has_atom + has_sequence + has_integer > 1 then
			SymTab[sym][S_SEQ_ELEM] = TYPE_OBJECT

		elsif has_atom then
			SymTab[sym][S_SEQ_ELEM] = TYPE_ATOM

		else
			SymTab[sym][S_SEQ_ELEM] = TYPE_SEQUENCE
		end if

	else
		SymTab[sym][S_SEQ_ELEM] = TYPE_NULL
	end if
end procedure

procedure optimize_switch( integer switch_pc, integer else_bp, integer cases, integer jump_table )

	-- fix up the case values
	sequence values = switch_stack[$][SWITCH_CASES]
	atom min =  1e+300
	atom max = -1e+300
	integer all_ints = 1
	integer has_integer    = 0
	integer has_atom       = 0
	integer has_sequence   = 0
	integer has_unassigned = 0
	integer has_fwdref     = 0
	for i = 1 to length( values ) do
		if sequence( values[i] ) then
			has_fwdref = 1
			exit
		end if
		integer sym = values[i]
		integer sign
		if sym < 0 then
			sign = -1
			sym = -sym
		else
			sign = 1
		end if
		if not equal(SymTab[sym][S_OBJ], NOVALUE) then
			values[i] = sign * SymTab[sym][S_OBJ]
			if not is_integer( values[i] ) then
				all_ints = 0
				if atom( values[i] ) then
					has_atom = 1
				else
					has_sequence = 1
				end if
			else
				has_integer = 1

				if values[i] < min then
					min = values[i]
				end if

				if values[i] > max then
					max = values[i]
				end if
			end if
		else
			has_unassigned = 1
			exit
		end if
	end for

	if has_unassigned or has_fwdref then
		values = switch_stack[$][SWITCH_CASES]
	end if

	if switch_stack[$][SWITCH_ELSE] then
			Code[else_bp] = switch_stack[$][SWITCH_ELSE]
	else
		-- just go to the end
		Code[else_bp] = length(Code) + 1 + TRANSLATE
	end if

	if TRANSLATE then
		-- This prevents the translator from getting confused.  It might
		-- otherwise use this as a temp somewhere else, leading to wrong
		-- code being emitted.  A '0' should never be part of a real temp
		-- string.
		SymTab[cases][S_OBJ] &= 0

	end if

	integer else_target = Code[else_bp]
	integer opcode = SWITCH
	if has_unassigned or has_fwdref then
		opcode = SWITCH_RT

	elsif all_ints then
		atom delta = max - min
		if not TRANSLATE and  delta < 1024 and delta >= 0 then
			opcode = SWITCH_SPI
			sequence jump = switch_stack[$][SWITCH_JUMP_TABLE]
			sequence switch_table = repeat( else_target, delta + 1 )
			integer offset = min - 1
			for i = 1 to length( values ) do
				switch_table[values[i] - offset] = jump[i]
			end for
			Code[switch_pc + 2] = offset
			switch_stack[$][SWITCH_JUMP_TABLE] = switch_table
		else
			opcode = SWITCH_I
		end if
	end if

	Code[switch_pc] = opcode
	if opcode != SWITCH_SPI then
		SymTab[cases][S_OBJ] = values
		if TRANSLATE then
			update_translator_info( cases, all_ints, has_integer, has_atom, has_sequence )
		end if
	end if
	
	-- convert to relative offsets
	SymTab[jump_table][S_OBJ] = switch_stack[$][SWITCH_JUMP_TABLE] - switch_pc

end procedure

procedure Switch_statement()
	integer break_base
	symtab_index cases, jump_table
	integer else_bp
	integer switch_pc

	push_switch()
	break_base = length(break_list)

	Expr()
	switch_stack[$][SWITCH_VALUE] = Top()
	clear_temp( switch_stack[$][SWITCH_VALUE] )

	cases = NewStringSym( {-1, length(SymTab) } )

	emit_opnd( cases )

	jump_table = NewStringSym( {-2, length(SymTab) } )
	emit_opnd( jump_table )

	if finish_block_header(SWITCH) then end if

	switch_pc = length(Code) + 1
	switch_stack[$][SWITCH_PC] = switch_pc

	emit_op(SWITCH)
	emit_forward_addr()  -- the else
	else_bp = length( Code )

	token t
	t = next_token()
	if t[T_ID] = CASE then

		Case_statement()

		Statement_list()

	else
		putback(t)
	end if

	optimize_switch( switch_pc, else_bp, cases, jump_table )
	tok_match(END)
	tok_match(SWITCH, END)
	if TRANSLATE then
		emit_op(NOPSWITCH)
	end if

	if not else_case() then
		if not TRANSLATE then
			StartSourceLine( TRUE, , COVERAGE_SUPPRESS )
			emit_temp( switch_stack[$][SWITCH_VALUE], NEW_REFERENCE )
			flush_temps()
		end if

		Warning(221, no_case_else_warning_flag,
				{known_files[current_file_no], line_number})
	end if
	pop_switch( break_base )
end procedure

procedure While_statement()
-- Parse a while loop
	integer bp1
	integer bp2
	integer exit_base, next_base

	Start_block( WHILE )

	exit_base = length(exit_list)
	next_base = length(continue_list)
	entry_addr &= length(Code)+1
	emit_op(NOP2) -- Entry_statement may patch this later
	emit_addr(0)
	if TRANSLATE then
		emit_op(NOPWHILE)
	end if
	bp1 = length(Code)+1
	continue_addr &= bp1
	short_circuit += 1
	short_circuit_B = FALSE
	SC1_type = 0
	Expr()
	optimized_while = FALSE
	emit_op(WHILE)
	short_circuit -= 1
	if not optimized_while then
		-- WHILE was emitted or combined into IFW op
		bp2 = length(Code)+1
		emit_forward_addr() -- will be patched
	else -- WHILE TRUE was optimized to nothing
		bp2 = 0
	end if
	if finish_block_header(WHILE)=0 then
		entry_addr[$]=-1
	end if

	loop_stack &= WHILE

	exit_base = length(exit_list)
	if SC1_type = OR then
		backpatch(SC1_patch-3, SC1_OR_IF)
		if TRANSLATE then
			emit_op(NOP1)
		end if
		backpatch(SC1_patch, length(Code)+1)
	elsif SC1_type = AND then
		backpatch(SC1_patch-3, SC1_AND_IF)
		AppendXList(SC1_patch)
		exit_delay &= 1
	end if
	retry_addr &= length(Code)+1

	sequence temps = pop_temps()

	push_temps( temps )

	Statement_list()
	PatchNList(next_base)
	tok_match(END)
	tok_match(WHILE, END)

	End_block( WHILE )

	StartSourceLine(TRUE)
	emit_op(ENDWHILE)
	emit_addr(bp1)
	if TRANSLATE then
		emit_op(NOP1)
	end if
	if bp2 != 0 then
		backpatch(bp2, length(Code)+1)
	end if
	exit_loop(exit_base)
	push_temps( temps )
end procedure

procedure Loop_statement()
-- Parse a loop-until loop
	integer bp1
	integer exit_base,next_base
	token t

	Start_block( LOOP )

	exit_base = length(exit_list)
	next_base = length(continue_list)
	emit_op(NOP2) -- Entry_statement() may patch this
	emit_addr(0)
	if finish_block_header(LOOP) then
	    entry_addr &= length(Code)-1
	else
		entry_addr &= -1
	end if
	-- do ... until <expr> is implemented as:
	-- while 1 do ... if not (<expr>) then exit end if end while
	if TRANSLATE then
		emit_op(NOP1)
	end if
	bp1 = length(Code)+1
	retry_addr &= length(Code)+1
	continue_addr &= 0
	loop_stack &= LOOP

	Statement_list()

	End_block( LOOP )

	tok_match(UNTIL)
	if TRANSLATE then
		emit_op(NOP1)
	end if
	PatchNList(next_base)
	StartSourceLine(TRUE)
	short_circuit += 1
	short_circuit_B = FALSE
	SC1_type = 0
	Expr()
	if SC1_type = OR then
		backpatch(SC1_patch-3, SC1_OR_IF)
		if TRANSLATE then
		    emit_op(NOP1)  -- to get label here
		end if
		backpatch(SC1_patch, length(Code)+1)
	elsif SC1_type = AND then
		backpatch(SC1_patch-3, SC1_AND_IF)
	end if
	short_circuit -= 1
	emit_op(IF)
	emit_addr(bp1)
	if TRANSLATE then
		emit_op(NOP1)
	end if
	exit_loop(exit_base)

	tok_match(END)
	tok_match(LOOP, END)

end procedure

integer top_level_parser
integer live_ifdef = 0
sequence ifdef_lineno = {}

procedure Ifdef_statement()
	sequence option
	integer matched = 0, has_matched = 0,  in_matched = 0, dead_ifdef = 0, in_elsedef = 0
	token tok
	sequence keyw ="ifdef"

	live_ifdef += 1
	ifdef_lineno &= line_number

	integer parser_id
	if CurrentSub != TopLevelSub or length(if_labels) or length(loop_labels) then
		parser_id = forward_Statement_list
	else
		parser_id = top_level_parser
	end if

	while 1 label "top" do
		if matched = 0 and in_elsedef = 0 then
			integer negate = 0, conjunction = 0
			integer at_start = 1
			sequence prev_conj = ""

			while 1 label "deflist" do
				option = StringToken()
				if equal(option, "then") then
					if at_start = 1 then
						CompileErr(6, {keyw})
					elsif conjunction = 0 then
						if negate = 0 then
							exit "deflist"
						else
							CompileErr(11, {keyw})
						end if
					else
						CompileErr(8, {keyw, prev_conj})
					end if
				elsif equal(option, "not") then
					if negate = 0 then
						negate = 1
						continue "deflist"
					else
						CompileErr(7, {keyw})
					end if
				elsif equal(option, "and") then
					if at_start = 1 then
						CompileErr(2, {keyw})
					elsif conjunction = 0 then
						conjunction = 1
						prev_conj = option
						continue "deflist"
					else
						CompileErr(10,{keyw,prev_conj})
					end if
				elsif equal(option, "or") then
					if at_start = 1 then
						CompileErr(6, {keyw})
					elsif conjunction = 0 then
						conjunction = 2
						prev_conj = option
						continue "deflist"
					else
						CompileErr(9, {keyw, prev_conj})
					end if
				elsif length(option) = 0 then
					if at_start = 1 then
						CompileErr(122, {keyw})
					else
						CompileErr(82)
					end if
				elsif not at_start and length(prev_conj) = 0 then
					CompileErr(4, {keyw})
				elsif t_identifier(option) = 0 then
					CompileErr(3, {keyw})
				else
					at_start = 0
				end if

				integer this_matched = find(option, OpDefines)
				if negate then
					this_matched = not this_matched
					negate = 0
				end if

				if conjunction = 0 then
					matched = this_matched
				else
					if conjunction = 1 then
						matched = matched and this_matched
					elsif conjunction = 2 then
						matched = matched or this_matched
					end if
					conjunction = 0
					prev_conj = ""
				end if
			end while

			in_matched = matched
			if matched then
				No_new_entry = 0
				call_proc(parser_id, {})
			end if
		end if

		-- Read to END IFDEF or to the next ELSIFDEF which sets the loop
		-- up for another comparison.
		integer gotword = 0
		integer gotthen = 0
		integer if_lvl  = 0
		No_new_entry = not matched
		has_matched = has_matched or matched
		keyw = "elsifdef"
		while 1 do
			tok = next_token()
			if tok[T_ID] = END_OF_FILE then
				CompileErr(65, ifdef_lineno[$])
			elsif tok[T_ID] = END then
				tok = next_token()
				if tok[T_ID] = IFDEF then
					if dead_ifdef then
						dead_ifdef -= 1
					else
						exit "top"
					end if
				elsif in_matched then
					-- we hit either an "end if" or some other kind of end statement that we shouldn't have.
					CompileErr(75, ifdef_lineno[$])
				else
					if tok[T_ID] = IF then
						if if_lvl > 0 then
							if_lvl -= 1
						else
							CompileErr(111, ifdef_lineno[$])
						end if
					end if
				end if
			elsif tok[T_ID] = IF then
				if_lvl += 1
			elsif tok[T_ID] = ELSE then
				if not in_matched then
					if if_lvl = 0 then
						CompileErr(108, ifdef_lineno[$])
					end if
				end if
			elsif tok[T_ID] = ELSIFDEF and not dead_ifdef then
				if has_matched then
					in_matched = 0
					No_new_entry = 1
					gotword = 0
					gotthen = 0
					while length(option) > 0 with entry do
						if equal(option, "then") then
							gotthen = 1
							exit
						else
							gotword = 1
						end if
					entry
						option = StringToken()
					end while
					if gotword = 0 then
						CompileErr(78)
					end if
					if gotthen = 0 then
						CompileErr(77)
					end if
					read_line()
				else
					exit
				end if
			elsif tok[T_ID] = ELSEDEF then
				gotword = line_number
				option = StringToken()
				if length(option) > 0 then
					if line_number = gotword then
						CompileErr(116)
					end if
					bp -= length(option)
				end if
				if not dead_ifdef then
					if has_matched then
						in_matched = 0
						No_new_entry = 1
						read_line()
					else
						No_new_entry = 0
						in_elsedef = 1
						call_proc(parser_id, {})
						tok_match(END)
						tok_match(IFDEF, END)
						live_ifdef -= 1
						ifdef_lineno = ifdef_lineno[1..$-1]
						return
					end if
				end if
			elsif tok[T_ID] = IFDEF then
				dead_ifdef += 1

			elsif tok[T_ID] = INCLUDE then
				-- Skip whatever is on rest of current line.
				read_line()

			elsif tok[T_ID] = CASE then
				-- Skip over whatever is next token. It could be 'else' which would confuse things.
				tok = next_token()

			end if
		end while
	end while

	live_ifdef -= 1
	ifdef_lineno = ifdef_lineno[1..$-1]
	No_new_entry = 0
end procedure

function SetPrivateScope(symtab_index s, symtab_index type_sym, integer n)
-- establish private scope for variable s in SymTab
-- (index may be changed - new value is returned)
	integer hashval, scope
	symtab_index t

	scope = SymTab[s][S_SCOPE]
	switch scope do
		case SC_PRIVATE then
			DefinedYet(s)
			Block_var( s )
			return s

		case SC_LOOP_VAR then
			DefinedYet(s)
			return s

		case SC_UNDEFINED, SC_MULTIPLY_DEFINED then
			SymTab[s][S_SCOPE] = SC_PRIVATE
			SymTab[s][S_VARNUM] = n
			SymTab[s][S_VTYPE] = type_sym
			if type_sym < 0 then
				register_forward_type( s, type_sym )
			end if
			Block_var( s )
			return s

		case SC_LOCAL, SC_GLOBAL, SC_PREDEF, SC_PUBLIC, SC_EXPORT then
			hashval = SymTab[s][S_HASHVAL]
			t = buckets[hashval]
			buckets[hashval] = NewEntry(SymTab[s][S_NAME], n, SC_PRIVATE,
										VARIABLE, hashval, t, type_sym)
			Block_var( buckets[hashval] )
			return buckets[hashval]

		case else
			InternalErr(267, {scope})

	end switch

	return 0
end function

procedure For_statement()
-- Parse a for statement
	integer bp1, bp2
	integer exit_base,next_base,end_op
	token tok, loop_var
	symtab_index loop_var_sym
	sequence save_syms

	Start_block( FOR )
	loop_var = next_token()
	if not find(loop_var[T_ID], ADDR_TOKS) then
		CompileErr(28)
	end if

	if BIND then
		add_ref(loop_var)
	end if

	tok_match(EQUALS)
	exit_base = length(exit_list)
	next_base = length(continue_list)
	Expr()
	tok_match(TO)
	exit_base = length(exit_list)
	Expr()
	tok = next_token()
	if tok[T_ID] = BY then
		Expr()
		end_op = ENDFOR_GENERAL -- will be set at runtime by FOR op
								-- loop var might not be integer
	else
		emit_opnd(NewIntSym(1))
		putback(tok)
		end_op = ENDFOR_INT_UP1
	end if

	loop_var_sym = loop_var[T_SYM]
	if CurrentSub = TopLevelSub then
		DefinedYet(loop_var_sym)
		SymTab[loop_var_sym][S_SCOPE] = SC_GLOOP_VAR
		SymTab[loop_var_sym][S_VTYPE] = object_type
	else
		loop_var_sym = SetPrivateScope(loop_var_sym, object_type, param_num)
		param_num += 1
		SymTab[loop_var_sym][S_SCOPE] = SC_LOOP_VAR
		Pop_block_var()
	end if
	SymTab[loop_var_sym][S_USAGE] = or_bits(SymTab[loop_var_sym][S_USAGE], U_USED)

	op_info1 = loop_var_sym
	emit_op(FOR)
	emit_addr(loop_var_sym)
	if finish_block_header(FOR) then
		CompileErr(83)
	end if
	entry_addr &= 0
	bp1 = length(Code)+1
	emit_addr(0) -- will be patched - don't straighten

	save_syms = Code[$-5..$-3] -- could be temps, but can't get rid of them yet
	for i = 1 to 3 do
		clear_temp( save_syms[i] )
	end for
	flush_temps()

	bp2 = length(Code)
	retry_addr &= bp2 + 1
	continue_addr &= 0

	loop_stack &= FOR

	if not TRANSLATE then
		if OpTrace then
			emit_op(DISPLAY_VAR)
			emit_addr(loop_var_sym)
		end if
	end if

	Statement_list()
	tok_match(END)
	tok_match(FOR, END)

	End_block( FOR )

	StartSourceLine(TRUE, TRANSLATE)
	op_info1 = loop_var_sym
	op_info2 = bp2 + 1
	PatchNList(next_base)
	emit_op(end_op)
	backpatch(bp1, length(Code)+1)
	if not TRANSLATE then
		if OpTrace then
			emit_op(ERASE_SYMBOL)
			emit_addr(loop_var_sym)
		end if
	end if

	Hide(loop_var_sym)
	exit_loop(exit_base)
	for i = 1 to 3 do
		emit_temp( save_syms[i], NEW_REFERENCE )
	end for
	flush_temps()
end procedure

export function CompileType(symtab_index type_ptr)
-- Translator only: set the compile type for a variable
	integer t

	if type_ptr < 0 then
		-- forward reference.  patch it later
		return type_ptr
	end if

	if SymTab[type_ptr][S_TOKEN] = OBJECT then
		return TYPE_OBJECT

	elsif type_ptr = integer_type then
		return TYPE_INTEGER

	elsif type_ptr = atom_type then
		return TYPE_ATOM

	elsif type_ptr = sequence_type then
		return TYPE_SEQUENCE

	elsif type_ptr = object_type then
		return TYPE_OBJECT

	else
		-- user defined - look at type of the parameter of the type
		t = SymTab[SymTab[type_ptr][S_NEXT]][S_VTYPE]
		if t = integer_type then
			return TYPE_INTEGER
		elsif t = atom_type then
			return TYPE_ATOM
		elsif t = sequence_type then
			return TYPE_SEQUENCE
		else
			return TYPE_OBJECT
		end if
	end if
end function

function get_assigned_sym()
-- call right after an assignment to get the sym that was assigned
-- 	a = Code[pc+1]
-- 	target = Code[pc+2]
-- 	val[target] = val[a]
	if not find( Code[$-2], {ASSIGN, ASSIGN_I}) then
		return 0
	end if
	return Code[$-1]
end function

procedure Assign_Constant( symtab_index sym )
	symtab_index valsym = Pop() -- pop the sym for the constant, too
	object val = SymTab[valsym][S_OBJ]

	SymTab[sym][S_OBJ] = val
	SymTab[sym][S_INITLEVEL] = 0

	if TRANSLATE then
		-- Let the translator know about its value
		SymTab[sym][S_GTYPE] = SymTab[valsym][S_GTYPE]
		SymTab[sym][S_SEQ_ELEM] = SymTab[valsym][S_SEQ_ELEM]
		SymTab[sym][S_OBJ_MIN] = SymTab[valsym][S_OBJ_MIN]
		SymTab[sym][S_OBJ_MAX] = SymTab[valsym][S_OBJ_MAX]
		SymTab[sym][S_SEQ_LEN] = SymTab[valsym][S_SEQ_LEN]
	end if
end procedure

function Global_declaration(integer type_ptr, integer scope)
-- parse a command-level variable or constant declaration
-- type_ptr is NULL if a list of constants (where each must be assigned to something)
-- type_ptr is -1 if it is an enumerated list of constants (where the first is assigned one and
-- each value is assumed to be one greater than the previous one unless assigned )
-- type_ptr otherwise must point to a valid symbol index of a variable.
	sequence new_symbols
	token tok
	object tsym
	object prevtok = 0
	symtab_index sym, valsym
	integer h, count = 0
	atom val = 1, usedval
	integer deltafunc = '+'
	atom delta = 1

	new_symbols = {}
	integer is_fwd_ref = 0
	if type_ptr > 0 and SymTab[type_ptr][S_SCOPE] = SC_UNDEFINED then
		is_fwd_ref = 1
		Hide(type_ptr)
		type_ptr = -new_forward_reference( TYPE, type_ptr )
	end if

	if type_ptr = -1 then
		-- special enum processing
		sequence ptok = next_token()
		if ptok[T_ID] = TYPE_DECL then
			-- Handle 'auto' type defn for this enum.
			-- syntax form is "enum type TYPENAME ENUMID, ENUMID, ..., ENUMID end type"
			putback(keyfind("enum",-1))
			SubProg(TYPE_DECL, scope)
			return {}
		elsif ptok[T_ID] = BY then

			integer negate = 0
			ptok = next_token()
			switch ptok[T_ID] do
				case MULTIPLY then
					deltafunc = '*'
					ptok = next_token()

				case DIVIDE then
					deltafunc = '/'
					ptok = next_token()

				case MINUS then
					deltafunc = '-'
					ptok = next_token()

				case PLUS then
					deltafunc = '+'
					ptok = next_token()

				case else
					deltafunc = '+'

			end switch

			if ptok[T_ID] = MINUS then
				negate = 1
				ptok = next_token()
			end if
			if ptok[T_ID] != ATOM then
				CompileErr( 344 )
			end if

			delta = SymTab[ptok[T_SYM]][S_OBJ]
			if negate then
				delta = -delta
			end if

			switch deltafunc do
				case '/' then
					delta = 1 / delta
					deltafunc = '*'

				case '-' then
					delta = -delta
					deltafunc = '+'

			end switch

		else
			putback(ptok)
		end if
	end if

	valsym = 0
	while TRUE do
		tok = next_token()
		if tok[T_ID] = DOLLAR then
			if not equal(prevtok, 0) then
				if prevtok[T_ID] = COMMA then
					-- The source code sequence ",$" signals the end of a list.
					tok = next_token()
					exit
				end if
			end if
		end if
		if tok[T_ID] = END_OF_FILE then
			CompileErr( 32 )
		end if

		if not find(tok[T_ID], ADDR_TOKS) then
			CompileErr(25, {find_category(tok[T_ID])} )
		end if
		sym = tok[T_SYM]
		DefinedYet(sym)
		if find(SymTab[sym][S_SCOPE], {SC_GLOBAL, SC_PREDEF, SC_PUBLIC, SC_EXPORT}) then
			h = SymTab[sym][S_HASHVAL]
			-- create a new entry at beginning of this hash chain
			sym = NewEntry(SymTab[sym][S_NAME], 0, 0, VARIABLE, h, buckets[h], 0)
			buckets[h] = sym
			-- more fields set below:
		end if
		new_symbols = append(new_symbols, sym)
		Block_var( sym )
		if SymTab[sym][S_SCOPE] = SC_UNDEFINED and SymTab[sym][S_FILE_NO] != current_file_no then
			SymTab[sym][S_FILE_NO] = current_file_no
		end if
		SymTab[sym][S_SCOPE] = scope

		if type_ptr = 0 then
			-- CONSTANT
			SymTab[sym][S_MODE] = M_CONSTANT
			-- temporarily hide sym so it can't be used in defining itself
			buckets[SymTab[sym][S_HASHVAL]] = SymTab[sym][S_SAMEHASH]
			tok_match(EQUALS)
			StartSourceLine(FALSE, , COVERAGE_OVERRIDE)
			emit_opnd(sym)
			Expr()  -- no new symbols can be defined in here
			buckets[SymTab[sym][S_HASHVAL]] = sym
			SymTab[sym][S_USAGE] = U_WRITTEN
			if TRANSLATE then
				SymTab[sym][S_GTYPE] = TYPE_OBJECT
				SymTab[sym][S_OBJ] = NOVALUE     -- distinguish from literals
			end if
			valsym = Top()
			
			if valsym > 0 and compare( SymTab[valsym][S_OBJ], NOVALUE ) then
				Assign_Constant( sym )
				sym = Pop()
			else
				
				emit_op(ASSIGN)
				if Last_op() = ASSIGN then
					valsym = get_assigned_sym()
				else
					-- something else happened...could be a built-in
					valsym = -1
				end if
				if valsym > 0 and compare( SymTab[valsym][S_OBJ], NOVALUE ) then
					-- need to remember this for select/case statements
					SymTab[sym][S_CODE] = valsym
				end if

				if TRANSLATE then
					count += 1
					if count = 10 then
						count = 0
						-- break up really long declarations
						emit_op( RETURNT )
					end if
				end if

			end if
		elsif type_ptr = -1 and not is_fwd_ref then
			-- ENUM
			StartSourceLine(FALSE, , COVERAGE_OVERRIDE )
			SymTab[sym][S_MODE] = M_CONSTANT
			-- temporarily hide sym so it can't be used in defining itself
			buckets[SymTab[sym][S_HASHVAL]] = SymTab[sym][S_SAMEHASH]
			tok = next_token()


			emit_opnd(sym)

			if tok[T_ID] = EQUALS then
				integer negate = 1

				tok = next_token()
				if tok[T_ID] = MINUS then
					negate = -1
					tok = next_token()
				end if

				if tok[T_ID] = ATOM then
					valsym = tok[T_SYM]
				elsif tok[T_SYM] > 0 then
					tsym = SymTab[tok[T_SYM]]
					if tsym[S_MODE] = M_CONSTANT then
						if length(tsym) >= S_CODE and tsym[S_CODE] then
							valsym = tsym[S_CODE]

						elsif not equal( tsym[S_OBJ], NOVALUE ) then
							if is_integer(tsym[S_OBJ]) then
								valsym = tok[T_SYM]
							else
								CompileErr(30)
							end if
						else
							CompileErr(70)
						end if
					elsif tsym[S_OBJ] = NOVALUE then
						-- forward reference
						CompileErr(ENUM_FWD_REFERENCES_NOT_SUPPORTED)
					else
						CompileErr(99)

					end if
				else -- tok[T_ID] != ATOM and tok[T_SYM] !> 0
						CompileErr(99)
				end if
				valsym = tok[T_SYM]
				if not atom( SymTab[valsym][S_OBJ] ) and tsym[S_SCOPE] != SC_UNDEFINED then
					CompileErr(84)
				end if
				val = SymTab[valsym][S_OBJ] * negate
				if is_integer(val) then
					Push(NewIntSym(val))
				else
					Push(NewDoubleSym(val))
				end if
				usedval = val
				if deltafunc = '+' then
					val += delta
				else
					val *= delta
				end if
			else
				putback(tok)
				if is_integer(val) then
					Push(NewIntSym(val))
				else
					Push(NewDoubleSym(val))
				end if
				usedval = val
				if deltafunc = '+' then
					val += delta
				else
					val *= delta
				end if
				valsym = 0
			end if
			buckets[SymTab[sym][S_HASHVAL]] = sym
			SymTab[sym][S_USAGE] = U_WRITTEN

			if TRANSLATE then
				SymTab[sym][S_GTYPE] = TYPE_OBJECT
				SymTab[sym][S_OBJ] = NOVALUE     -- distinguish from literals
			end if

			if valsym < 0 then
				-- fwd reference

			end if

			if valsym and compare( SymTab[valsym][S_OBJ], NOVALUE ) then
				-- need to remember this for select/case statements
				SymTab[sym][S_CODE] = valsym
				SymTab[sym][S_OBJ]  = usedval

				if TRANSLATE then
					-- Let the translator know about its value
					SymTab[sym][S_GTYPE] = SymTab[valsym][S_GTYPE]
					SymTab[sym][S_SEQ_ELEM] = SymTab[valsym][S_SEQ_ELEM]
					SymTab[sym][S_OBJ_MIN] = usedval
					SymTab[sym][S_OBJ_MAX] = usedval
					SymTab[sym][S_SEQ_LEN] = SymTab[valsym][S_SEQ_LEN]
				end if
			else
				SymTab[sym][S_OBJ] = usedval
				if TRANSLATE then
					-- Let the translator know about its value
					if is_integer( usedval ) then
						SymTab[sym][S_GTYPE] = TYPE_INTEGER
					else
						SymTab[sym][S_GTYPE] = TYPE_DOUBLE
					end if
					SymTab[sym][S_SEQ_ELEM] = 0
					SymTab[sym][S_OBJ_MIN] = usedval
					SymTab[sym][S_OBJ_MAX] = usedval
					SymTab[sym][S_SEQ_LEN] = 0 --SymTab[valsym][S_SEQ_LEN]
				end if
			end if
			valsym = Pop()
			valsym = Pop()
		else
			-- variable
			SymTab[sym][S_MODE] = M_NORMAL
			if type_ptr > 0 and SymTab[type_ptr][S_TOKEN] = OBJECT then
				SymTab[sym][S_VTYPE] = object_type
			else
				SymTab[sym][S_VTYPE] = type_ptr
				if type_ptr < 0 then
					register_forward_type( sym, type_ptr )
				end if
			end if

			if TRANSLATE then
				SymTab[sym][S_GTYPE] = CompileType(type_ptr)
			end if

	   		tok = next_token()
   			putback(tok)
	   		if tok[T_ID] = EQUALS then -- assign on declare
	   			StartSourceLine( FALSE, , COVERAGE_OVERRIDE )
	   			Assignment({VARIABLE,sym})
			end if
		end if
		tok = next_token()
		if tok[T_ID] != COMMA then
			exit
		end if
		prevtok = tok
	end while
	putback(tok)
	return new_symbols
end function

procedure Private_declaration(symtab_index type_sym)
-- parse a private declaration of one or more variables
	token tok
	symtab_index sym

	if SymTab[type_sym][S_SCOPE] = SC_UNDEFINED then
		Hide( type_sym )
		type_sym = -new_forward_reference( TYPE, type_sym )
	end if

	while TRUE do
		tok = next_token()
		if not find(tok[T_ID], ID_TOKS) then
			CompileErr(24)
		end if
		sym = SetPrivateScope(tok[T_SYM], type_sym, param_num)
		param_num += 1

		if TRANSLATE then
			SymTab[sym][S_GTYPE] = CompileType(type_sym)
		end if

   		tok = next_token()
   		if tok[T_ID] = EQUALS then -- assign on declare
		    putback(tok)
		    StartSourceLine( TRUE )
		    -- TODO: MWL 7/6/08: This line and its companion below allow use of another,
		    -- previously declared variable to be used when initializing a private variable.
		    -- I think this should be removed, and caught at run-time as a variable not
		    -- assigned error.  Using a previous variable seems counter-intuitive.  It's
		    -- a side effect when a constant is declared, but I think that's because we don't
		    -- check to see if constants have been assigned already, not because we want to
		    -- allow other, earlier constants with the same name to be used to initialize
		    -- a constant.
-- 		    symtab_index old_hash = SymTab[sym][S_SAMEHASH]
-- 			buckets[SymTab[sym][S_HASHVAL]] = old_hash -- recover any shadowed var
		    -- MWL 10/14/08: removed No_new_entry, since we may need forward references
		    Assignment({VARIABLE,sym})
-- 			buckets[SymTab[sym][S_HASHVAL]] = sym  -- put new var back in place
-- 			SymTab[sym][S_SAMEHASH] = old_hash
			tok = next_token()
			if tok[T_ID]=IGNORED then
				tok = keyfind(tok[T_SYM],-1)
			end if
		end if

		if tok[T_ID] != COMMA then
			exit
		end if
	end while
	putback(tok)
end procedure


procedure Procedure_call(token tok)
-- parse a procedure call statement
	integer n, scope, opcode
	token temp_tok
	symtab_index s, sub

	tok_match(LEFT_ROUND)
	s = tok[T_SYM]
	sub=s
	n = SymTab[s][S_NUM_ARGS]
	scope = SymTab[s][S_SCOPE]
	opcode = SymTab[s][S_OPCODE]
	if SymTab[s][S_EFFECT] then
		SymTab[CurrentSub][S_EFFECT] = or_bits(SymTab[CurrentSub][S_EFFECT],
											   SymTab[s][S_EFFECT])
	end if
	ParseArgs(s)

	-- check for any initialisation code for variables
	for i=1 to n+1 do
		s = SymTab[s][S_NEXT]
	end for
	while s and SymTab[s][S_SCOPE]=SC_PRIVATE do
		if sequence(SymTab[s][S_CODE]) then
			start_playback(SymTab[s][S_CODE])
			Assignment({VARIABLE,s})
		end if
		s = SymTab[s][S_NEXT]
	end while

	s = sub
	if scope = SC_PREDEF then
		emit_op(opcode)
		if opcode = ABORT then
			temp_tok = next_token()
			putback(temp_tok)
			NotReached(temp_tok[T_ID], "abort()")
		end if
	else
		op_info1 = s
		--emit_op(PROC)
		emit_or_inline()
		if not TRANSLATE then
			if OpTrace then
				emit_op(UPDATE_GLOBALS)
			end if
		end if
	end if
end procedure

procedure Print_statement()
-- parse a '?' print statement
	emit_opnd(NewIntSym(1)) -- stdout
	Expr()
	emit_op(QPRINT)
	SymTab[CurrentSub][S_EFFECT] = or_bits(SymTab[CurrentSub][S_EFFECT],
										   E_OTHER_EFFECT)
end procedure

procedure Entry_statement()
-- defines an entry statement
-- must check that it is not in the middle of an if block
	integer addr

	if not length(loop_stack) or block_index=0 then
		CompileErr(144)
	end if
	if block_list[block_index]=IF or block_list[block_index]=SWITCH then
		CompileErr(143)
	elsif loop_stack[$] = FOR then  -- not allowed in an innermost for loop
		CompileErr(142)
	end if
	addr = entry_addr[$]
	if addr=0  then
		CompileErr(141)
	elsif addr<0 then
		CompileErr(73)
	end if
	backpatch(addr,ELSE)
	backpatch(addr+1,length(Code)+1+(TRANSLATE>0))
	entry_addr[$] = 0
	if TRANSLATE then
	    emit_op(NOP1)
	end if
end procedure

procedure Statement_list()
-- Parse a list of statements
	token tok
	integer id

	stmt_nest += 1
	while TRUE do
		tok = next_token()
		id = tok[T_ID]
		if id = VARIABLE or id = QUALIFIED_VARIABLE then
			if SymTab[tok[T_SYM]][S_SCOPE] = SC_UNDEFINED then
				token forward = next_token()
				switch forward[T_ID] do
					case LEFT_ROUND then
						StartSourceLine( TRUE )

						Forward_call( tok )
						flush_temps()
						continue

					case VARIABLE then
						putback( forward )
						if param_num != -1 then
							-- if we're in a routine, we need to know how much stack space will be required
							param_num += 1
							Private_declaration( tok[T_SYM] )
						else
							Global_declaration( tok[T_SYM], SC_LOCAL )
						end if
						flush_temps()
						continue

				end switch
				putback( forward )
			end if
			StartSourceLine(TRUE)
			Assignment(tok)

		elsif id = PROC or id = QUALIFIED_PROC then
			if id = PROC then
				-- possibly warn for non-inclusion
				UndefinedVar( tok[T_SYM] )
			end if
			StartSourceLine(TRUE)
			Procedure_call(tok)

		elsif id = FUNC or id = QUALIFIED_FUNC then
			if id = FUNC then
				-- possibly warn for non-inclusion
				UndefinedVar( tok[T_SYM] )
			end if
			StartSourceLine(TRUE)
			Procedure_call(tok)
			clear_op()
			if Pop() then end if

		elsif id = IF then
			StartSourceLine(TRUE)
			If_statement()

		elsif id = FOR then
			StartSourceLine(TRUE)
			For_statement()

		elsif id = RETURN then
			StartSourceLine(TRUE)
			Return_statement()

		elsif id = LABEL then
			StartSourceLine(TRUE, , COVERAGE_SUPPRESS )
			GLabel_statement()

		elsif id = GOTO then
			StartSourceLine(TRUE)
			Goto_statement()

		elsif id = EXIT then
			StartSourceLine(TRUE)
			Exit_statement()

		elsif id = BREAK then
			StartSourceLine(TRUE)
			Break_statement()

		elsif id = WHILE then
			StartSourceLine(TRUE)
			While_statement()

		elsif id = LOOP then
		    StartSourceLine(TRUE)
	        Loop_statement()

		elsif id = ENTRY then
		    StartSourceLine(TRUE, , COVERAGE_SUPPRESS )
		    Entry_statement()

		elsif id = QUESTION_MARK then
			StartSourceLine(TRUE)
			Print_statement()

		elsif id = CONTINUE then
			StartSourceLine(TRUE)
			Continue_statement()

		elsif id = RETRY then
			StartSourceLine(TRUE)
			Retry_statement()

		elsif id = IFDEF then
			StartSourceLine(TRUE)
			Ifdef_statement()

		elsif id = CASE then
			Case_statement()

		elsif id = SWITCH then
			StartSourceLine(TRUE)
			Switch_statement()

		elsif id = FALLTHRU then
			Fallthru_statement()

		elsif id = TYPE or id = QUALIFIED_TYPE then
			StartSourceLine(TRUE)
			token test = next_token()
			putback( test )
			if test[T_ID] = LEFT_ROUND then
				StartSourceLine( TRUE )
				Procedure_call(tok)
				clear_op()
				if Pop() then end if
				ExecCommand()
				continue
			else

				if param_num != -1 then
					-- if we're in a routine, we need to know how much stack space will be required
					param_num += 1
					Private_declaration( tok[T_SYM] )
				else
					Global_declaration( tok[T_SYM], SC_LOCAL )
				end if
			end if



		else
			if id = ELSE then
				if length(if_stack) = 0 then
					if live_ifdef > 0 then
						CompileErr(134, ifdef_lineno[$])
					else
						CompileErr(118)
					end if
				end if
			elsif id = ELSIF then
				if length(if_stack) = 0 then
					if live_ifdef > 0 then
						CompileErr(139, ifdef_lineno[$])
					else
						CompileErr(119)
					end if
				end if
			end if
			
			putback( tok )
				
			switch id do
				case END, ELSEDEF, ELSIFDEF, ELSIF, ELSE, UNTIL then
					-- something to mark the end of the block...
					stmt_nest -= 1
					InitDelete()
					flush_temps()
					return
					
				case else
					tok_match( END )
			end switch

		end if

		flush_temps()
	end while
end procedure
forward_Statement_list = routine_id("Statement_list")

procedure SubProg(integer prog_type, integer scope)
-- parse a function, type or procedure declaration
-- global is 1 if it's global
	integer h, pt
	symtab_index p, type_sym, sym
	token tok, prog_name
	integer first_def_arg
	integer again
	integer type_enum
	object seq_sym
	object i1_sym
	sequence enum_syms = {}
	integer type_enum_gline, real_gline

	LeaveTopLevel()
	prog_name = next_token()
	if prog_name[T_ID] = END_OF_FILE then
		CompileErr( 32 )
	end if
	type_enum =  0
	if prog_type = TYPE_DECL then
		object tsym = prog_name[T_SYM]
		if equal(sym_name(prog_name[T_SYM]),"enum") then
			-- Because enum types are both top level declarations and type routines, we
			-- have to Enter and Leave the top level, fixing up the LineTable, in order
			-- to prevent corruption of the LineTables
			EnterTopLevel( FALSE )
			type_enum_gline = gline_number
			type_enum = 1
			sequence seq_symbol
			prog_name = next_token()
			if not find(prog_name[T_ID], ADDR_TOKS) then
				CompileErr(25, {find_category(prog_name[T_ID])} )
			end if
			enum_syms = Global_declaration(-1, scope)
			seq_symbol = enum_syms
			for i = 1 to length( enum_syms ) do
				seq_symbol[i] = sym_obj(enum_syms[i])
			end for
			-- boot strap in a type routine
			-- so that anything falling in the
			-- range of the enum is accepted
			-- as valid.
			i1_sym = keyfind("i1",-1)
			seq_sym = NewStringSym(seq_symbol)
			putback(keyfind("return",-1))
			putback({RIGHT_ROUND,0})
			putback(i1_sym)
			putback(keyfind("object",-1))
			putback({LEFT_ROUND,0})
			
			LeaveTopLevel()
		end if
	end if
	if not find(prog_name[T_ID], ADDR_TOKS) then
		CompileErr(25, {find_category(prog_name[T_ID])} )
	end if
	p = prog_name[T_SYM]
	DefinedYet(p)
	if prog_type = PROCEDURE then
		pt = PROC
	elsif prog_type = FUNCTION then
		pt = FUNC
	else
		pt = TYPE
	end if

	clear_fwd_refs()
	if find(SymTab[p][S_SCOPE], {SC_PREDEF, SC_GLOBAL, SC_PUBLIC, SC_EXPORT, SC_OVERRIDE}) then
		-- redefine by creating new symbol table entry
		if scope = SC_OVERRIDE then
			if SymTab[p][S_SCOPE] = SC_PREDEF or SymTab[p][S_SCOPE] = SC_OVERRIDE then
					if SymTab[p][S_SCOPE] = SC_OVERRIDE then
						again = 223
					else
						again = 222
					end if
					Warning(again, override_warning_flag,
								{known_files[current_file_no],line_number, SymTab[p][S_NAME]})
			end if
		end if

		h = SymTab[p][S_HASHVAL]
		sym = buckets[h]
		p = NewEntry(SymTab[p][S_NAME], 0, 0, pt, h, sym, 0)
		buckets[h] = p
	end if

	Start_block( pt, p )

	CurrentSub = p
	first_def_arg = 0
	temps_allocated = 0

	SymTab[p][S_SCOPE] = scope

	SymTab[p][S_TOKEN] = pt

	if length(SymTab[p]) < SIZEOF_ROUTINE_ENTRY then
		-- expand var entry to routine entry
		SymTab[p] = SymTab[p] & repeat(0, SIZEOF_ROUTINE_ENTRY -
									   length(SymTab[p]))
	end if

	SymTab[p][S_CODE] = 0
	SymTab[p][S_LINETAB] = 0
	SymTab[p][S_EFFECT] = E_PURE
	SymTab[p][S_REFLIST] = {}
	SymTab[p][S_FIRSTLINE] = gline_number
	SymTab[p][S_TEMPS] = 0
	SymTab[p][S_RESIDENT_TASK] = 0
	SymTab[p][S_SAVED_PRIVATES] = {}
	
	if type_enum then
		SymTab[p][S_FIRSTLINE] = type_enum_gline
		real_gline = gline_number
		gline_number = type_enum_gline
		StartSourceLine( FALSE, , COVERAGE_OVERRIDE )
		gline_number = real_gline
	else
		StartSourceLine(FALSE, , COVERAGE_OVERRIDE)
	end if
	
	tok_match(LEFT_ROUND)
	tok = next_token()
	param_num = 0

	-- start of executable code for subprogram:
	sequence middle_def_args = {}
	integer last_nda = 0, start_def = 0
	symtab_index last_link = p
	while tok[T_ID] != RIGHT_ROUND do
		-- parse the parameter declarations

		if tok[T_ID] != TYPE and tok[T_ID] != QUALIFIED_TYPE then
			if tok[T_ID] = VARIABLE or tok[T_ID] = QUALIFIED_VARIABLE then
				-- I've got a name of something, so let's see if the next token is also a name.
				token temptok = next_token()
				integer undef_type = 0
				if temptok[T_ID] != TYPE and temptok[T_ID] != QUALIFIED_TYPE then
					if find( temptok[T_ID], FULL_ID_TOKS) then
						-- -- So there are two names next to each other.
						if SymTab[tok[T_SYM]][S_SCOPE] = SC_UNDEFINED then
							-- The first name is undefined so it might be a type
							-- that is declared later on. So for now, let's assume that.
							undef_type = - new_forward_reference( TYPE, tok[T_SYM] )
						else
							CompileErr(37)
						end if
					end if
				end if
				putback(temptok) -- Return whatever came after the name back onto the token stream.
				if undef_type != 0 then
					-- The name is assumed to be a forward declared type.
					tok[T_SYM] = undef_type
				else
					CompileErr(37)
				end if
			else
				CompileErr(37)
			end if
		end if
		type_sym = tok[T_SYM]
		tok = next_token()
		if not find(tok[T_ID], ID_TOKS) then
			sequence tokcat = find_category(tok[T_ID])
			if tok[T_SYM] != 0 and length(SymTab[tok[T_SYM]]) >= S_NAME then
				CompileErr(90, {tokcat, SymTab[tok[T_SYM]][S_NAME]})
			else
				CompileErr(92, {LexName(tok[T_ID])})
			end if
		end if
		sym = SetPrivateScope(tok[T_SYM], type_sym, param_num)
		param_num += 1

		if SymTab[last_link][S_NEXT] != sym
		and SymTab[SymTab[last_link][S_NEXT]][S_SCOPE] = SC_UNDEFINED then
			-- ignore SC_UNDEFINED symbols (should be forward declared types)
			SymTab[SymTab[last_link][S_NEXT]][S_NEXT] = 0
			SymTab[last_link][S_NEXT] = sym
		end if

		last_link = sym

		if TRANSLATE then
			SymTab[sym][S_GTYPE] = CompileType(type_sym)
		end if

--		SymTab[sym][S_USAGE] = U_WRITTEN
		tok = next_token()
		if tok[T_ID] = EQUALS then -- defaulted parameter
			start_recording()
			Expr()
			SymTab[sym][S_CODE] = restore_parser()
			if Pop() then end if -- don't leak the default argument
			tok = next_token()
			if first_def_arg = 0 then
				first_def_arg = param_num
			end if
			previous_op = -1 -- no interferences betwen defparms, or them and subsequent code
			if start_def = 0 then
				start_def = param_num
			end if
		else
			last_nda = param_num
			if start_def then
				if start_def = param_num-1 then
					middle_def_args &= start_def
				else
					middle_def_args = append(middle_def_args, {start_def, param_num-1})
				end if
				start_def = 0
			end if
		end if
		if tok[T_ID] = COMMA then
			tok = next_token()
			if tok[T_ID] = RIGHT_ROUND then
				CompileErr(85)
			end if
		elsif tok[T_ID] != RIGHT_ROUND then
			CompileErr(41)
		end if
	end while
	Code = {} -- removes any spurious code emitted while recording parameters
			  -- but don't scrub SymTab, because created temps may be referenced somewhere else
	SymTab[p][S_NUM_ARGS] = param_num
	SymTab[p][S_DEF_ARGS] = {first_def_arg, last_nda, middle_def_args}
	if TRANSLATE then
		if param_num > max_params then
			max_params = param_num
		end if
		num_routines += 1
	end if
	if SymTab[p][S_TOKEN] = TYPE and param_num != 1 then
		CompileErr(148)
	end if

	include_routine()

	-- code to perform type checks on all the parameters
	sym = SymTab[p][S_NEXT]
	for i = 1 to SymTab[p][S_NUM_ARGS] do
		while SymTab[sym][S_SCOPE] != SC_PRIVATE do
			sym = SymTab[sym][S_NEXT]
		end while
		TypeCheck(sym)
		sym = SymTab[sym][S_NEXT]
	end for

	-- parse private variable declarations
	-- (parameters are numbered: 0, 1, ... num_args-1 and
	--  other privates are numbered: num_args, num_args+1, ...)
	tok = next_token()
	while tok[T_ID] = TYPE or tok[T_ID] = QUALIFIED_TYPE do
		Private_declaration(tok[T_SYM])
		tok = next_token()
	end while

	if not TRANSLATE then
		if OpTrace then
			-- clear any private names from screen
			emit_op(ERASE_PRIVATE_NAMES)
			emit_addr(p)
			-- display initial values of all the parameters
			sym = SymTab[p][S_NEXT]
			for i = 1 to SymTab[p][S_NUM_ARGS] do
				emit_op(DISPLAY_VAR)
				emit_addr(sym)
				sym = SymTab[sym][S_NEXT]
			end for
			-- globals may have changed
			emit_op(UPDATE_GLOBALS)
		end if
	end if
	putback(tok)

	-- parse body of routine.
	FuncReturn = FALSE
	if type_enum then
		-- Parse a list of statements
		stmt_nest += 1
		tok_match(RETURN)
		putback({RIGHT_ROUND,0})
		putback({VARIABLE,seq_sym})
		putback({COMMA,0})
		putback(i1_sym)
		putback({LEFT_ROUND,0})
		putback(keyfind("find",-1))
		if not TRANSLATE then
			if OpTrace then
				emit_op(ERASE_PRIVATE_NAMES)
				emit_addr(CurrentSub)
			end if
		end if
		Expr()
		FuncReturn = TRUE
		emit_op(RETURNF)
		flush_temps()
		stmt_nest -= 1
		InitDelete()
		flush_temps()
	else
		Statement_list()
		-- parse routine end.
		tok_match(END)
	end if

	-- parse routine end.
	tok_match(prog_type, END)

	if prog_type != PROCEDURE then
		if not FuncReturn then
			if prog_type = FUNCTION then
				CompileErr(120)
			else
				CompileErr(149)
			end if
		end if
		emit_op(BADRETURNF) -- function/type shouldn't reach here

	else
		StartSourceLine(TRUE)
		if not TRANSLATE then
			if OpTrace then
				emit_op(ERASE_PRIVATE_NAMES)
				emit_addr(p)
			end if
		end if
		emit_op(RETURNP)
		if TRANSLATE then
			emit_op(BADRETURNF) -- just to mark end of procedure
		end if
	end if
	Drop_block( pt )

	if Strict_Override > 0 then
		Strict_Override -= 1	-- Reset at the end of each routine.
	end if

	SymTab[p][S_STACK_SPACE] += temps_allocated + param_num
	if temps_allocated + param_num > max_stack_per_call then
		max_stack_per_call = temps_allocated + param_num
	end if
	param_num = -1
	
	StraightenBranches()
	check_inline( p )
	param_num = -1
	EnterTopLevel()

	-- need to patch up the SYM_NEXT chain in case of enum type
	if length( enum_syms ) then
		SymTab[p][S_NEXT] = SymTab[enum_syms[$]][S_NEXT]
		SymTab[last_sym][S_NEXT] = enum_syms[1]
		last_sym = enum_syms[$]
		SymTab[last_sym][S_NEXT] = 0
	end if
end procedure

export procedure InitGlobals()
-- initialize global variables
	ResetTP()
	OpTypeCheck = TRUE

	OpDefines &= {
	    sprintf("EU%d", { version_major() }),
		sprintf("EU%d_%d", { version_major(), version_minor() }),
		sprintf("EU%d_%d_%d", { version_major(), version_minor(), version_patch() })
	}

	OpDefines &= GetPlatformDefines()

	if repl then
		-- disable inlining in REPL mode
		OpInline = 0
	else
		OpInline = DEFAULT_INLINE
	end if
	OpIndirectInclude = 1
end procedure

procedure not_supported_compile(sequence feature)
-- Report that a compile-time feature is not supported in this platform
	CompileErr(5, {feature, version_name})
end procedure

procedure SetWith(integer on_off)
-- set a with/without option
	sequence option
	integer idx
	integer reset_flags = 1


	option = StringToken("&+=")

	if equal(option, "type_check") then
		OpTypeCheck = on_off

	elsif equal(option, "profile") then
		if not TRANSLATE and not BIND then
			OpProfileStatement = on_off
			if OpProfileStatement then
				if AnyTimeProfile then
					Warning(224, mixed_profile_warning_flag)
					OpProfileStatement = FALSE
				else
					AnyStatementProfile = TRUE
				end if
			end if
		end if

	elsif equal(option, "profile_time") then
		if not TRANSLATE and not BIND then
			if not IWINDOWS then
				if on_off then
					not_supported_compile("profile_time")
				end if
			end if
			OpProfileTime = on_off
			if OpProfileTime then
				if AnyStatementProfile then
					Warning(224,mixed_profile_warning_flag)
					OpProfileTime = FALSE
				end if
				token tok = next_token()
				if tok[T_ID] = ATOM then
					if is_integer(SymTab[tok[T_SYM]][S_OBJ]) then
						sample_size = SymTab[tok[T_SYM]][S_OBJ]
					else
						sample_size = -1
					end if
					if sample_size < 1 and OpProfileTime then
						CompileErr(136)
					end if
				else
					putback(tok)
					sample_size = DEFAULT_SAMPLE_SIZE
				end if
				if OpProfileTime then
					if IWINDOWS then
						AnyTimeProfile = TRUE
					end if
				end if
			end if
		end if

	elsif equal(option, "trace") then
		if not BIND then
			OpTrace = on_off
		end if

	elsif equal(option, "warning") then
		integer good_sofar = line_number
		reset_flags = 1
		token tok = next_token()
		integer warning_extra = 1
		if find(tok[T_ID], {CONCAT_EQUALS, PLUS_EQUALS}) != 0 then
			tok = next_token()
			if tok[T_ID] != LEFT_BRACE and tok[T_ID] != LEFT_ROUND then
				CompileErr(160)
			end if
			reset_flags = 0
		elsif tok[T_ID] = EQUALS then
			tok = next_token()
			if tok[T_ID] != LEFT_BRACE and tok[T_ID] != LEFT_ROUND then
				CompileErr(160)
			end if
			reset_flags = 1
		elsif tok[T_ID] = VARIABLE then
			option = SymTab[tok[T_SYM]][S_NAME]
			if equal(option, "save") then
				prev_OpWarning = OpWarning
				warning_extra = FALSE

			elsif equal(option, "restore") then
				OpWarning = prev_OpWarning
				warning_extra = FALSE

			elsif equal(option, "strict") then
				if on_off = 0 then
					Strict_Override += 1
				elsif Strict_Override > 0 then
					Strict_Override -= 1
				end if
				warning_extra = FALSE
			end if
		end if

		if warning_extra = TRUE then
			if reset_flags then
				if on_off = 0 then
					OpWarning = no_warning_flag
				else
					OpWarning = all_warning_flag
				end if
			end if

			if find(tok[T_ID], {LEFT_BRACE, LEFT_ROUND}) then
				integer endlist
				if tok[T_ID] = LEFT_BRACE then
					endlist = RIGHT_BRACE
				else
					endlist = RIGHT_ROUND
				end if
				tok = next_token()
				while tok[T_ID] != endlist do
					if tok[T_ID] = COMMA then
						tok = next_token()
						continue
					end if

					if tok[T_ID] = STRING then
						option = SymTab[tok[T_SYM]][S_OBJ]
					elsif length(SymTab[tok[T_SYM]]) >= S_NAME then
						option = SymTab[tok[T_SYM]][S_NAME]
					else
						option = ""
						for k = 1 to length(keylist) do
							if keylist[k][S_SCOPE] = SC_KEYWORD and
								keylist[k][S_TOKEN] = tok[T_ID]
							then
									option = keylist[k][S_NAME]
									exit
							end if
						end for

					end if

					idx = find(option, warning_names)
					if idx = 0 then
	 					if good_sofar != line_number then
 							CompileErr(147)
 						end if
						Warning(225, 0,
							{known_files[current_file_no], line_number, option})
						tok = next_token()
						continue
					end if

					idx = warning_flags[idx]
					if idx = 0 then
						if on_off then
							OpWarning = no_warning_flag
						else
						    OpWarning = all_warning_flag
						end if
					else
						if on_off then
							OpWarning = or_bits(OpWarning, idx)
						else
						    OpWarning = and_bits(OpWarning, not_bits(idx))
						end if
					end if
					tok = next_token()
				end while
			else
				putback(tok)
			end if
		end if
	elsif equal(option, "define") then
		option = StringToken()
		if length(option) = 0 then
			CompileErr(81)

		elsif not t_identifier(option) then
			CompileErr(61)

		end if
		if on_off = 0 then
			idx = find(option, OpDefines)
			if idx then
				OpDefines = OpDefines[1..idx-1]&OpDefines[idx+1..$]
			end if
		else
			OpDefines &= {option}
		end if

	elsif equal(option, "inline") then
		-- disable inlining in REPL mode
		if on_off and not repl then
			token tok = next_token()
			if tok[T_ID] = ATOM then
				OpInline = floor( SymTab[tok[T_SYM]][S_OBJ] )
			else
				putback(tok)
				OpInline = DEFAULT_INLINE
			end if
		else
			OpInline = 0

		end if

	elsif equal( option, "indirect_includes" ) then
		OpIndirectInclude = on_off

	elsif equal(option, "batch") then
		batch_job = on_off

	elsif integer(to_number(option, -1)) then
		-- ignore security stamp as it is no longer required.

	else
		CompileErr(154, {option})

	end if
end procedure

procedure ExecCommand()
-- execute a top-level command
	if TRANSLATE then
		emit_op(RETURNT)
	end if
	StraightenBranches()  -- straighten top-level
end procedure

function undefined_var( token tok, integer scope )
	token forward = next_token()
		switch forward[T_ID] do
			case LEFT_ROUND then
				StartSourceLine( TRUE )
				Forward_call( tok )
				return 1

			case VARIABLE then
				putback( forward )
				Global_declaration( tok[T_SYM], scope )
				return 1

			case else
				putback( forward )
				return 0
		end switch
end function

export procedure real_parser(integer nested)
-- top level of the parser - command level
	token tok
	integer id
	integer scope

	while TRUE do  -- infinite loop until scanner aborts
		if OpInline = 25000 then
			CompileErr("OpInline went nuts: [1]", OpInline )
		end if
		start_index = length(Code)+1
		tok = next_token()
		id = tok[T_ID]
		if id = VARIABLE or id = QUALIFIED_VARIABLE then
			if SymTab[tok[T_SYM]][S_SCOPE] = SC_UNDEFINED
			and undefined_var( tok, SC_LOCAL ) then
				continue
			end if
			StartSourceLine(TRUE)
			Assignment(tok)
			ExecCommand()

		elsif id = PROCEDURE or id = FUNCTION or id = TYPE_DECL then
			SubProg(tok[T_ID], SC_LOCAL)

		elsif id = GLOBAL or id = EXPORT or id = OVERRIDE or id = PUBLIC then
			if id = GLOBAL then
			    scope = SC_GLOBAL
			elsif id = EXPORT then
				scope = SC_EXPORT
			elsif id = OVERRIDE then
				scope = SC_OVERRIDE
			elsif id = PUBLIC then
				scope = SC_PUBLIC
			end if

			tok = next_token()
			id = tok[T_ID]

			if id = TYPE or id = QUALIFIED_TYPE then
				Global_declaration(tok[T_SYM], scope )

			elsif id = CONSTANT then
				Global_declaration(0, scope )
				ExecCommand()

			elsif id = ENUM then
				Global_declaration(-1, scope )
				ExecCommand()

			elsif id = PROCEDURE or id = FUNCTION or id = TYPE_DECL then
				SubProg(id, scope )
				

			elsif id = MEMSTRUCT_DECL then
				MemStruct_declaration( scope )
			
			elsif id = MEMUNION_DECL then
				MemUnion_declaration( scope )
				
			elsif (scope = SC_PUBLIC) and id = INCLUDE then
				IncludeScan( 1 )
				PushGoto()
			elsif (id = VARIABLE or id = QUALIFIED_VARIABLE)
			and SymTab[tok[T_SYM]][S_SCOPE] = SC_UNDEFINED
			and undefined_var( tok, scope ) then
			
				continue
				
			elsif scope = SC_GLOBAL then
				CompileErr( 18 )
			else
				CompileErr( 16 )
			end if
			
		elsif id = TYPE or id = QUALIFIED_TYPE then
			token test = next_token()
			putback( test )
			if test[T_ID] = LEFT_ROUND then
					StartSourceLine( TRUE )
					Procedure_call(tok)
					clear_op()
					if Pop() then end if
					ExecCommand()

			else
				Global_declaration( tok[T_SYM], SC_LOCAL )

			end if
			continue

		elsif id = CONSTANT then
			Global_declaration(0, SC_LOCAL)
			ExecCommand()

		elsif id = ENUM then
			Global_declaration(-1, SC_LOCAL)
			ExecCommand()

		elsif id = IF then
			StartSourceLine(TRUE)
			If_statement()
			ExecCommand()

		elsif id = FOR then
			StartSourceLine(TRUE)
			For_statement()
			ExecCommand()

		elsif id = WHILE then
			StartSourceLine(TRUE)
			While_statement()
			ExecCommand()

		elsif id = LOOP then
		    StartSourceLine(TRUE)
		    Loop_statement()
		    ExecCommand()

		elsif id = PROC or id = QUALIFIED_PROC then
			StartSourceLine(TRUE)
			if id = PROC then
				-- to check for warning if proc not in include tree
				UndefinedVar( tok[T_SYM] )
			end if

			Procedure_call(tok)
			ExecCommand()

		elsif id = FUNC or id = QUALIFIED_FUNC then
			StartSourceLine(TRUE)
			if id = FUNC then
				-- to check for warning if proc not in include tree
				UndefinedVar( tok[T_SYM] )
			end if

			Procedure_call(tok)
			clear_op()
			if Pop() then end if
			ExecCommand()

		elsif id = RETURN then
			Return_statement() -- will fail - not allowed at top level

		elsif id = EXIT then
			if nested then
			StartSourceLine(TRUE)
			Exit_statement()
			else
			CompileErr(89)
			end if

		elsif id = INCLUDE then
			IncludeScan( 0 )
			PushGoto()

		elsif id = WITH then
			SetWith(TRUE)

		elsif id = WITHOUT then
			SetWith(FALSE)

		elsif id = END_OF_FILE then
			if IncludePop() then
				backed_up_tok = {}
				PopGoto()
				read_line()
				
				last_ForwardLine     = ThisLine
				last_fwd_line_number = line_number
				last_forward_bp      = bp
				
				putback_ForwardLine     = ThisLine
				putback_fwd_line_number = line_number
				putback_forward_bp      = bp
				
				ForwardLine     = ThisLine
				fwd_line_number = line_number
				forward_bp      = bp
				
			else
				CheckForUndefinedGotoLabels()
				exit -- all finished
			end if

		elsif id = QUESTION_MARK then
			StartSourceLine(TRUE)
			Print_statement()
			ExecCommand()

		elsif id = LABEL then
			StartSourceLine(TRUE, , COVERAGE_SUPPRESS)
			GLabel_statement()

		elsif id = GOTO then
			StartSourceLine(TRUE)
			Goto_statement()

		elsif id = CONTINUE then
			if nested then
				StartSourceLine(TRUE)
				Continue_statement()
			else
				CompileErr(50)
			end if

		elsif id = RETRY then
			if nested then
				StartSourceLine(TRUE)
				Retry_statement()
			else
				CompileErr(128)
			end if

		elsif id = BREAK then
			if nested then
				StartSourceLine(TRUE)
				Break_statement()
			else
				CompileErr(39)
			end if

		elsif id = ENTRY then
			if nested then
			    StartSourceLine(TRUE, , COVERAGE_SUPPRESS)
			    Entry_statement()
			else
				CompileErr(72)
			end if

		elsif id = IFDEF then
			StartSourceLine(TRUE)
			Ifdef_statement()

		elsif id = CASE then
			Case_statement()

		elsif id = SWITCH then
			StartSourceLine(TRUE)
			Switch_statement()


		elsif id = MEMSTRUCT_DECL then
			MemStruct_declaration( SC_LOCAL )
		
		elsif id = MEMUNION_DECL then
			MemUnion_declaration( SC_LOCAL )
		
		elsif id = ILLEGAL_CHAR then
			CompileErr(102)

		else
			if nested then
				if id = ELSE then
					if length(if_stack) = 0 then
						if live_ifdef > 0 then
							CompileErr(134, ifdef_lineno[$])
						else
							CompileErr(118)
						end if
					end if
				elsif id = ELSIF then
					if length(if_stack) = 0 then
						if live_ifdef > 0 then
							CompileErr(139, ifdef_lineno[$])
						else
							CompileErr(119)
						end if
					end if
				end if
				putback(tok)
				if stmt_nest > 0 then
					stmt_nest -= 1
					InitDelete()
				end if
				return
			else
				if id = END then
					tok = next_token()
					CompileErr(17, {find_token_text(tok[T_ID])})
				end if

				CompileErr(117, { match_replace(",", find_token_text(id), "") })

			end if

		end if
		flush_temps()
	end while
	emit_op(RETURNT)
	clear_last()
	StraightenBranches()
	SymTab[TopLevelSub][S_CODE] = Code
	EndLineTable()
	SymTab[TopLevelSub][S_LINETAB] = LineTable
end procedure

export procedure parser()
	real_parser(0)
	mark_final_targets()
	resolve_unincluded_globals( 1 )
	Resolve_forward_references( 1 )
	inline_deferred_calls()
	if not repl then
	End_block( PROC )
	Code = {}
	LineTable = {}
	end if
end procedure

export procedure nested_parser()
	real_parser(1)
end procedure

top_level_parser = routine_id("nested_parser")

