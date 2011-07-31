-- (c) Copyright - See License.txt
--
-- The Translator - Acts as a Back-end to the standard Front-end.
--
-- After the front-end is finished, this thing takes over and makes
-- several passes through the IL, trying to optimize things more and more.
-- With each pass, it refines its idea of the type and range of
-- values of each variable and operand. This allows it to emit C code that
-- is more precise and efficient. It doesn't actually emit the C code
-- until the final pass.
namespace compile
ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include std/types.e as t
include std/filesys.e
include std/io.e
include std/sort.e
include std/map.e as map
include std/search.e

include buildsys.e
include c_decl.e
include c_out.e
include c_struct.e
include cominit.e
include compress.e
include emit.e
include error.e
include global.e
include mode.e as mode
include opnames.e
include platform.e
include reswords.e as rw
include scanner.e
include symtab.e
include shift.e
include fwdref.e


export integer np, pc

constant MAXLEN = MAXINT - 1000000  -- assumed maximum length of a sequence

constant INT16 = #00007FFF,
		 INT15 = #00003FFF,
		 INT32 = #7FFFFFFF,
		 INT31 = #3FFFFFFF

-- Machine Operations - avoid renumbering existing constants
-- update C copy in execute.h
constant M_COMPLETE = 0,    -- determine Complete Edition
		 -- M_SOUND = 1,
		 -- M_LINE = 2,
		 M_PALETTE = 3,
		 M_SOCK_INFO = 4,
		 M_GRAPHICS_MODE = 5,
		 -- M_CURSOR = 6,
		 -- M_WRAP = 7,
		 -- M_SCROLL = 8,
		 -- M_SET_T_COLOR = 9,
		 -- M_SET_B_COLOR = 10,
		 -- M_POLYGON = 11,
		 M_TEXTROWS = 12,
		 M_VIDEO_CONFIG = 13,
		 -- M_GET_MOUSE = 14,
		 -- M_MOUSE_EVENTS = 15,
		 M_ALLOC = 16,
		 -- M_FREE = 17,
		 -- M_ELLIPSE = 18,
		 M_SEEK = 19,
		 M_WHERE = 20,
		 M_SET_SYNCOLOR = 21,
		 -- M_DIR = 22,
		 M_CURRENT_DIR = 23,
		 -- M_MOUSE_POINTER = 24,
		 M_GET_POSITION = 25,
		 M_WAIT_KEY = 26,
		 -- M_ALL_PALETTE = 27,
		 M_GET_DISPLAY_PAGE = 28,
		 -- M_SET_DISPLAY_PAGE = 29,
		M_GET_ACTIVE_PAGE = 30,
		-- M_SET_ACTIVE_PAGE = 31,
		M_ALLOC_LOW    = 32,
		-- M_FREE_LOW     = 33,
		M_INTERRUPT    = 34,
		-- M_SET_RAND     = 35,
		M_SET_COVERAGE     = 36,
		-- M_CRASH_MESSAGE = 37,
		-- M_TICK_RATE    = 38,
		M_GET_VECTOR   = 39,
		-- M_SET_VECTOR   = 40,
		-- M_LOCK_MEMORY  = 41,
		-- M_ALLOW_BREAK  = 42,
		M_CHECK_BREAK  = 43,
		-- M_MEM_COPY     = 44,  -- obsolete, but keep for now
		-- M_MEM_SET      = 45,  -- obsolete, but keep for now
		M_A_TO_F64     = 46,
		M_F64_TO_A     = 47,
		M_A_TO_F32     = 48,
		M_F32_TO_A     = 49,
		M_OPEN_DLL     = 50,
		M_DEFINE_C     = 51,
		M_CALLBACK     = 52,
		-- M_PLATFORM     = 53,  -- obsolete, but keep for now
		-- M_FREE_CONSOLE = 54,
		M_INSTANCE     = 55,
		M_DEFINE_VAR   = 56,
		-- 	M_CRASH_FILE   = 57,
		M_GET_SCREEN_CHAR = 58,
		-- M_PUT_SCREEN_CHAR = 59,
		-- M_FLUSH        = 60,
		M_LOCK_FILE    = 61,
		-- M_UNLOCK_FILE  = 62,
		M_CHDIR        = 63,
		-- M_SLEEP        = 64,
		-- M_BACKEND      = 65,
		M_CRASH        = 67
		--, M_WARNING_FILE = 72
		-- M_GET_RAND     = 98


constant INIT_CHUNK = 2500 -- maximum number of literals to
						   -- initialize in one init-*.c file (one routine)

export sequence target   -- struct minmax
target = {0, 0}

constant LOOP_VAR = 1 --, LOOP_TYPE = 2, LOOP_LABEL = 3
sequence loop_stack

-- Key:   temp sym
-- Value: 1 = reference count incremented when created
map:map dead_temp_walking = map:new()

export constant
	NO_REFERENCE = 0,
	NEW_REFERENCE = 1,
	KEEP_IN_MAP = 0,
	REMOVE_FROM_MAP = 1,
	DISCARD_TEMP = 0,
	SAVE_TEMP = 1

/*
	Scenarios:
		Temp creation:
		1. Temp is just a pointer to something (e.g., RHS_SUBS), no new references
		2. Temp is a new reference (e.g., function result or slice)

		Temp disposition:
		A. Temp is consumed, and needs to be dereferenced (e.g., length not part of a $-op)
		B. Temp is stored somewhere, and shouldn't be dereferenced

			All temps get set to NOVALUE, * indicates dereference
			A	B
		1	-   ?
		2	*   -

*/

--**
-- Called when an assignment is made, or an object is created.
-- Checks whether the sym is a temp, and records it if it is.
-- If the object's reference count was incremented, then referenced
-- should be NEW_REFERENCE, so that it can be cleaned up properly later.
-- Otherwise, ##referenced## should be NO_REFERENCE.
export procedure create_temp( symtab_index sym, integer referenced )
	if is_temp( sym ) then
		map:put( dead_temp_walking, sym, referenced )
	end if
end procedure

--**
-- Disposes of a temp.  If keep = DISCARD_TEMP, then the temp will be
-- dereferenced if its reference count was incremented when
-- it was created.  If remove_from_map is REMOVE_FROM_MAP, then the temp will
-- be cleared from the map.  If remove_from_map is KEEP_IN_MAP, then the
-- temp will be left in the map.
export procedure dispose_temp( symtab_index sym, integer keep, integer remove_from_map )
	if is_temp( sym ) then
		integer referenced = map:get( dead_temp_walking, sym, 0 )
		if remove_from_map then
			map:remove( dead_temp_walking, sym )
		end if

		if referenced = NEW_REFERENCE
		and keep = DISCARD_TEMP then
			CDeRef( sym )
		end if
		c_stmt("@ = NOVALUE;\n", sym)
		SetBBType( sym, TYPE_OBJECT, novalue, TYPE_OBJECT, 0 )
	end if
end procedure

--**
-- Normally not used by the translator, but may be used in some cases
-- where a forward procedure call was transformed into a forward function
-- call.
procedure opDEREF_TEMP()
	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 2
end procedure

--**
-- Disposes ##count## temps starting at ##start## in the Code using
-- the specified value of ##keep##.
procedure dispose_temps( integer start, integer count, integer keep, integer remove_from_map )
	for i = start to start + count - 1 do
		dispose_temp( Code[i], keep, remove_from_map )
	end for
end procedure

--**
-- Calls [:dispose_temp] for all temps that have been queued, but not yet
-- disposed with the specified keep value.
procedure dispose_all_temps( integer keep, integer remove_from_map, integer except = 0 )
	sequence syms = map:keys( dead_temp_walking )
	for i = 1 to length( syms ) do
		if except = syms[i] then
			continue
		end if
		dispose_temp( syms[i], keep, remove_from_map )
	end for
end procedure

function min(atom a, atom b)
	if a < b then
		return a
	else
		return b
	end if
end function

function max(atom a, atom b)
	if a > b then
		return a
	else
		return b
	end if
end function

function abs(atom a)
	if a < 0 then
		return -a
	else
		return a
	end if
end function

function savespace()
-- should try to save space and reduce complexity
   return length(loop_stack) = 0 and (CurrentSub = TopLevelSub or
		  length(SymTab[CurrentSub][S_CODE]) > (max_cfile_size/2))
end function

function BB_temp_type(integer var)
-- return the local type for a temp *name*, based on BB info */
	integer t, tn
	object bbi
	object st

	tn = SymTab[var][S_TEMP_NAME]
	for i = length(BB_info) to 1 by -1 do
		bbi = BB_info[i]
		st = SymTab[bbi[BB_VAR]]
		if st[S_MODE] != M_TEMP then
			continue
		end if

		if st[S_TEMP_NAME] != tn then
			continue
		end if

		t = bbi[BB_TYPE]

		ifdef DEBUG then
		if t <= 0 or t > TYPE_OBJECT then
			InternalErr(250)
		end if
		end ifdef

		return t

	end for
	-- no info in BB, so fall back to global temp name info
	return or_type(TYPE_INTEGER,   -- for initialization = 0
				   temp_name_type[tn][T_GTYPE])
end function

function BB_temp_elem(integer var)
-- return the local element type for a temp *name*, based on BB info */
	integer t, tn

	tn = SymTab[var][S_TEMP_NAME]
	for i = length(BB_info) to 1 by -1 do
		if SymTab[BB_info[i][BB_VAR]][S_MODE] = M_TEMP and
		   SymTab[BB_info[i][BB_VAR]][S_TEMP_NAME] = tn then
			t = BB_info[i][BB_ELEM]
			if t = TYPE_NULL then
				t = TYPE_OBJECT
			end if

			ifdef DEBUG then
			if t <= 0 or t > TYPE_OBJECT then
				InternalErr(251)
			end if
			end ifdef

			return t
		end if
	end for
	-- no info in BB, so fall back to global temp name info
	return TYPE_OBJECT -- Later we might track temp element types globally
end function

function BB_var_elem(integer var)
-- return the local element type of a var, based on BB info */
	integer t

	for i = length(BB_info) to 1 by -1 do
		if SymTab[BB_info[i][BB_VAR]][S_MODE] = M_NORMAL and
			BB_info[i][BB_VAR] = var then
			t = BB_info[i][BB_ELEM]

			ifdef DEBUG then
			if t < 0 or t > TYPE_OBJECT then
				InternalErr(252)
			end if
			end ifdef

			if t = TYPE_NULL then   -- var has only been read
				return TYPE_OBJECT
			else
				return t
			end if
		end if
	end for
	return TYPE_OBJECT
end function

function BB_var_seqlen(integer var)
-- return the sequence length of a var, based on BB info. */
	for i = length(BB_info) to 1 by -1 do
		if SymTab[BB_info[i][BB_VAR]][S_MODE] = M_NORMAL and
		   BB_info[i][BB_VAR] = var then
			if BB_info[i][BB_TYPE] != TYPE_SEQUENCE and -- makes sense? (was or)
			   BB_info[i][BB_TYPE] != TYPE_OBJECT then
				return NOVALUE
			end if
			return BB_info[i][BB_SEQLEN]
		end if
	end for
	return NOVALUE
end function

function SeqElem(integer x)
-- the type of all elements of a sequence
	symtab_index s
	integer t, local_t

	s = x
	t = SymTab[s][S_SEQ_ELEM]

	ifdef DEBUG then
	if t < 0 or t > TYPE_OBJECT then
		InternalErr(253)
	end if
	end ifdef

	if SymTab[s][S_MODE] != M_NORMAL then
		return t
	end if
	-- check local BB info for vars only
	local_t = BB_var_elem(x)
	if local_t = TYPE_OBJECT then
		return t
	end if
	if t = TYPE_INTEGER then
		return TYPE_INTEGER
	end if
	return local_t
end function

function SeqLen(integer x)
-- the length of a sequence
	symtab_index s
	atom len, local_len

	s = x
	len = SymTab[s][S_SEQ_LEN]
	if SymTab[s][S_MODE] != M_NORMAL then
		return len
	end if
	-- check local BB info for vars only - min has local seq_len
	local_len = BB_var_seqlen(x)
	if local_len = NOVALUE then
		return len
	else
		return local_len
	end if
end function

function ObjMinMax(integer x)
-- the value of an integer constant or variable
	symtab_index s
	sequence t, local_t

	s = x
	t = {SymTab[s][S_OBJ_MIN], SymTab[s][S_OBJ_MAX]}

	if SymTab[s][S_MODE] != M_NORMAL then
		return t
	end if

	-- check local BB info for vars only
	local_t = BB_var_obj(x)
	if local_t[MIN] = NOVALUE then
		return t
	else
		return local_t
	end if
end function

function IntegerSize(integer pc, integer var)
-- return TRUE if var (or temp) must be in the
-- magnitude range of a Euphoria integer for this op
-- (N.B. although it could be in double form)
	integer op

	op = Code[pc]

	if find(op, {ASSIGN_OP_SUBS, PASSIGN_OP_SUBS, RHS_SUBS_CHECK, RHS_SUBS,
				 RHS_SUBS_I, ASSIGN_SUBS_CHECK, ASSIGN_SUBS,
				 ASSIGN_SUBS_I}) then   -- FOR NOW - ADD MORE
		return Code[pc+2] = var

	elsif op = LHS_SUBS or op = LHS_SUBS1 or op = LHS_SUBS1_COPY then
		return Code[pc+2] = var

	elsif op = REPEAT then
		return Code[pc+2] = var

	elsif op = RHS_SLICE or op = ASSIGN_SLICE then
		return Code[pc+2] = var or Code[pc+3] = var

	elsif op = POSITION then
		return Code[pc+1] = var or Code[pc+2] = var

	elsif op = MEM_COPY or op = MEM_SET then
		return Code[pc+3] = var

	else
		return FALSE

	end if
end function

-- we map code indexes into small integers for better readability
sequence label_map
label_map = {}

function find_label(integer addr)
-- get the label number, given the address,
-- or create a new label number
	integer m

	m = find(addr, label_map)
	if m then
		return m
	end if

	label_map = append(label_map, addr)
	return length(label_map)
end function

function forward_branch_into(integer addr1, integer addr2)
-- is there a possible forward branch into the code from addr1 to addr2
-- inclusive? i.e. is there a label defined already in that range
-- Note: NOP1 defines a label at the *next* location - be careful
-- not to delete it accidentally
	for i = 1 to length(label_map) do
		if label_map[i] >= addr1 and label_map[i] <= addr2+1 then
			return TRUE
		end if
	end for
	return FALSE
end function

map:map label_usage = map:new()
enum
	LABEL_UNKNOWN = 0,
	LABEL_EMITTED,
	LABEL_UNUSED,
	LABEL_USED

function can_emit_label( integer addr, integer r_label = 0 )
	sequence label_key = { CurrentSub, addr, r_label }
	integer usage = map:get( label_usage, label_key, LABEL_UNKNOWN )

	switch usage do
		case LABEL_UNKNOWN then
			map:put( label_usage, label_key, LABEL_EMITTED )
			return 1
		case LABEL_EMITTED, LABEL_USED then
			return 1
		case else
	end switch
	return 0
end function

function prune_labels()
	sequence labels = map:pairs( label_usage )
	label_usage = map:new()
	for i = 1 to length( labels ) do
		if labels[i][2] = LABEL_UNUSED
		or labels[i][2] = LABEL_EMITTED then
			map:put( label_usage, labels[i][1], LABEL_UNUSED )
		end if
	end for
	return map:size( label_usage )
end function

procedure Label(integer addr)
-- emit a label, and start a new basic block
	integer label_index

	NewBB(0, E_ALL_EFFECT, 0)

	if can_emit_label( addr ) then
		label_index = find_label(addr)
		ifdef DEBUG then
			c_printf("L%x: // addr: %d pc: %d sub: %d op: %d\n", {label_index, addr, pc, CurrentSub, Code[pc]})
		elsedef
			c_printf("L%x: \n", label_index)
		end ifdef
	end if
end procedure

procedure RLabel(integer addr)
-- emit a label, and start a new basic block
	integer label_index

	NewBB(0, E_ALL_EFFECT, 0)
	if can_emit_label( addr, 1 ) then
		label_index = find_label(addr)
		ifdef DEBUG then
			c_printf("R%x: // addr: %d pc: %d sub: %d op: %d\n", {label_index, addr, pc, CurrentSub, Code[pc]})
		elsedef
			c_printf("R%x:\n", label_index)
		end ifdef
	end if
end procedure

procedure Goto(integer addr)
-- emits a C goto statement.
-- does branch straightening
	integer label_index, br, new_addr

	while TRUE do
		new_addr = addr
		br = Code[new_addr]
		while (br = NOP1 or br = STARTLINE or br = NOP2) and new_addr < length(Code)-2 do
			-- skip no-ops
			if br = NOP1 then
				new_addr += 1
			else
				new_addr += 2
			end if
			br = Code[new_addr]
		end while

		if addr < 6 or
		   not find(Code[addr-5], {ENDFOR_INT_UP1, ENDFOR_GENERAL})
--         or
--         SymTab[Code[addr-2]][S_GTYPE] = TYPE_INTEGER  -- could get subscript error
		then
			-- careful: general ENDFOR might emit a label followed by
			-- code that shouldn't be skipped
			if find(br, {ELSE, ENDWHILE, EXIT}) then
				addr = Code[new_addr+1]
			else
				exit
			end if
		else
			exit
		end if
	end while

	label_index = find_label(addr)
	c_stmt0("goto ")
	c_printf("L%x; // [%d] %d\n", {label_index, pc, addr})
	map:put( label_usage, { CurrentSub, addr, 0 }, LABEL_USED )
end procedure

procedure RGoto(integer addr)
-- emits a C goto statement.
-- does not do branch straightening
	c_stmt0("goto ")
	c_printf("R%x;\n", find_label(addr))
	map:put( label_usage, { CurrentSub, addr, 1 }, LABEL_USED )
end procedure

function BB_exist(integer var)
-- return TRUE if a var or temp was read or written
-- already in the current BB
	for i = length(BB_info) to 1 by -1 do
		if BB_info[i][BB_VAR] = var then
			return TRUE
		end if
	end for
	return FALSE
end function

procedure c_fixquote(sequence c_source)
-- output a string of C source code with backslashes before quotes
	integer c

	if emit_c_output then
		for p = 1 to length(c_source) do
			c = c_source[p]
			if c = '"' or c = '\\' then
				puts(c_code, '\\')
			end if
			if c != '\n' and c != '\r' then
				puts(c_code, c)
			end if
		end for
	end if
end procedure

function IsParameter(symtab_index v)
-- TRUE if v is a parameter of the current subroutine
	if SymTab[v][S_MODE] = M_NORMAL and
	   SymTab[v][S_SCOPE] = SC_PRIVATE and
	   SymTab[v][S_VARNUM] < SymTab[CurrentSub][S_NUM_ARGS] then
		return TRUE
	else
		return FALSE
	end if
end function

procedure CRef(integer v)
-- Ref a var or temp in the quickest way
	if TypeIs(v, TYPE_INTEGER) then
		return
	end if
	if TypeIsIn(v, TYPES_DS) then
		c_stmt0("RefDS(")
	else
		c_stmt0("Ref(") -- TYPE_ATOM, TYPE_OBJECT
	end if
	LeftSym = TRUE
	CName(v)
	c_puts(");\n")
end procedure

procedure CRefn(integer v, integer n)
-- Ref a var or temp n times in the quickest way
	if TypeIs(v, TYPE_INTEGER) then
		return
	end if

	if TypeIsIn(v, TYPES_DS) then
		c_stmt0("RefDSn(")
	else
		c_stmt0("Refn(") -- TYPE_ATOM, TYPE_OBJECT
	end if

	LeftSym = TRUE
	CName(v)
	c_printf(", %d);\n", n)
end procedure

function target_differs(integer target, integer opnd1, integer opnd2,
						integer opnd3)
	integer tmode
	integer tname

-- see if target is not used as an operand - it can be DeRef'd early
	tmode = SymTab[target][S_MODE]
	if tmode = M_NORMAL then
		if target = opnd1 then
			return FALSE
		end if
		if target = opnd2 then
			return FALSE
		end if
		if target = opnd3 then
			return FALSE
		end if
		return TRUE

	elsif tmode = M_TEMP then
		tname = SymTab[target][S_TEMP_NAME]
		if opnd1 then
			if tname = SymTab[opnd1][S_TEMP_NAME] then
				return FALSE
			end if
		end if

		if opnd2 then
			if tname = SymTab[opnd2][S_TEMP_NAME] then
				return FALSE
			end if
		end if

		if opnd3 then
			if tname = SymTab[opnd3][S_TEMP_NAME] then
				return FALSE
			end if
		end if

		return TRUE

	else
		return FALSE

	end if
end function

sequence deref_str
integer deref_type
integer deref_elem_type
integer deref_short

export procedure CSaveStr(sequence target, integer v, integer a, integer b, integer c)
-- save a value (to be deref'd) in immediate target
-- if value isn't known to be an integer
	boolean deref_exist

	deref_str = target
	deref_exist = FALSE

	if SymTab[v][S_MODE] = M_TEMP then
		deref_type = TYPE_INTEGER
		deref_elem_type = BB_temp_elem(v)

	elsif SymTab[v][S_MODE] = M_NORMAL then
		deref_type = GType(v)
		if deref_type != TYPE_INTEGER then
			deref_exist = BB_exist(v)
		end if
		deref_elem_type = SeqElem(v)

	else
		deref_type = TYPE_INTEGER

	end if

	deref_short = (deref_type = TYPE_DOUBLE or
				   deref_type = TYPE_SEQUENCE) and
				 (SymTab[v][S_MODE] = M_TEMP or
				  IsParameter(v) or
				  deref_exist)
	if deref_type != TYPE_INTEGER then
		if  target_differs(v, a, b, c) then
			-- target differs from operands - can DeRef it immediately
			if savespace() then
				c_stmt0("DeRef1(")  -- less machine code

			else
				if deref_short then
					-- we know it's initialized to an actual pointer
					if deref_elem_type = TYPE_INTEGER then  -- could do all-sequence/all-double dref later
						c_stmt0("DeRefDSi(")
					else
						c_stmt0("DeRefDS(")
					end if
				else
					if deref_elem_type = TYPE_INTEGER then
						c_stmt0("DeRefi(")
					else
						c_stmt0("DeRef(")
					end if
				end if
			end if
			LeftSym = TRUE
			CName(v)
			c_puts(");\n")
			deref_str = ""  -- cancel it

		else
			c_stmt0(target)
			c_puts(" = ")
			CName(v)
			c_puts(";\n")

		end if
	end if
end procedure

export procedure CDeRefStr(sequence s)
-- DeRef a string name  - see CSaveStr()
	if length(deref_str) = 0 then
		return
	end if

	if not equal(s, deref_str) then
		CompileErr(106)
	end if

	if deref_type != TYPE_INTEGER then
		if savespace() then
			c_stmt0("DeRef1(")  -- less machine code

		else
			if deref_short then
				-- we know it's initialized to an actual pointer
				if deref_elem_type = TYPE_INTEGER then
				-- could do all-sequence/all-double dref later
					c_stmt0("DeRefDSi(")
				else
					c_stmt0("DeRefDS(")
				end if
			else
				if deref_elem_type = TYPE_INTEGER then
					c_stmt0("DeRefi(")
				else
					c_stmt0("DeRef(")
				end if
			end if
		end if
		c_puts(s)
		c_puts(");\n")
	end if
end procedure

export procedure CDeRef(integer v)
-- DeRef a var or temp
	integer temp_type, elem_type

	if SymTab[v][S_MODE] = M_TEMP then
		temp_type = BB_temp_type(v)
		elem_type = BB_temp_elem(v)
		if temp_type = TYPE_INTEGER then
			return
		end if
		if savespace() then
			c_stmt0("DeRef1(")  -- less machine code

		else
			if temp_type = TYPE_DOUBLE or
			   temp_type = TYPE_SEQUENCE then
				c_stmt0("DeRefDS(")

			else
				c_stmt0("DeRef(")  -- TYPE_ATOM, TYPE_OBJECT, TYPE_NULL
			end if
		end if

	else
		-- var
		if TypeIs(v, TYPE_INTEGER) then
			return
		end if

		elem_type = SeqElem(v)

		if savespace() then
			c_stmt0("DeRef1(")  -- less machine code

		else
			if TypeIsIn(v, TYPES_DS) and
				(IsParameter(v) or BB_exist(v)) then
				-- safe: parameters are always initialized
				if elem_type = TYPE_INTEGER then
					c_stmt0("DeRefDSi(")
				else
					c_stmt0("DeRefDS(")
				end if

			else
				-- TYPE_ATOM, TYPE_OBJECT
				if elem_type = TYPE_INTEGER then
					c_stmt0("DeRefi(")
				else
					c_stmt0("DeRef(")
				end if
			end if
		end if
	end if

	LeftSym = TRUE
	CName(v)
	c_puts(");\n")

	if HasDelete( v ) then
		NewBB(1, E_ALL_EFFECT, 0)
	end if
end procedure

procedure CUnaryOp(integer pc, sequence op_int, sequence op_gen)
-- handle several unary ops where performance of
-- calling a routine for int case, and calling
-- unary_op() for non-ints is acceptable
	integer target_type

	CSaveStr("_0", Code[pc+2], Code[pc+1], 0, 0)

	if TypeIsIn(Code[pc+1], TYPES_AO) then
		-- test for integer
		c_stmt("if (IS_ATOM_INT(@))\n", Code[pc+1])
	end if

	if TypeIsNotIn(Code[pc+1], TYPES_DS) then
		-- handle integer
		c_stmt("@ = ", Code[pc+2])
		c_puts(op_int)
		temp_indent = -indent
		c_stmt("(@);\n", Code[pc+1])
	end if

	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt0("else\n")
	end if

	if TypeIsNot(Code[pc+1], TYPE_INTEGER) then
		-- handle double or sequence
		c_stmt("@ = unary_op(", Code[pc+2])
		c_puts(op_gen)
		temp_indent = -indent
		c_stmt(", @);\n", Code[pc+1])
	end if
	CDeRefStr("_0")

	if TypeIs(Code[pc+1], TYPE_INTEGER) then
		target_type = TYPE_ATOM
	elsif Code[pc] = NOT_BITS and TypeIsIn( Code[pc+1], TYPES_IAD ) then
		target_type = TYPE_ATOM
	else
		target_type = GType(Code[pc+1])
	end if
	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	SetBBType(Code[pc+2], target_type, novalue, TYPE_OBJECT, HasDelete( Code[pc+1] ) )
	create_temp( Code[pc+2], 1 )
end procedure

procedure seg_peek_string(integer target, integer source, integer mode)
-- emit code for a single-byte peek  - uses _1 as a temp
	if mode = 1 then
		c_stmt("@ = NewString((char *)(uintptr_t)(DBL_PTR(@)->dbl));\n",
				{target, source})
	else
		c_stmt("@ =  NewString((char *)@);\n", {target, source})
	end if

end procedure

procedure seg_peek_pointer(integer target, integer source, integer mode)
-- emit code for a pointer sized peek
	if mode = 1 then
		c_stmt( "@ = *(uintptr_t *)(uintptr_t)(DBL_PTR(@)->dbl);\n", {target, source})
	else
		c_stmt( "@ = *(intptr_t *)@;\n", {target, source})
	end if
	
	c_stmt("if ((uintptr_t)@ > (uintptr_t)MAXINT){\n",
				target)
	c_stmt("@ = NewDouble((eudouble)(uintptr_t)@);\n",
				{target, target})
	c_stmt0("}\n")
	-- FIX: in first BB we might assume TYPE_INTEGER, value 0
	-- so CName will output a 0 instead of the var's name
	SetBBType( target, GType(target), novalue, TYPE_OBJECT, 0)
end procedure

procedure seg_peek1(integer target, integer source, integer mode)
-- emit code for a single-byte peek  - uses _1 as a temp
	sequence sign
	if Code[pc] = PEEK then
		sign = "u"
	else
		sign = ""
	end if
	
	if mode = 1 then
		c_stmt(sprintf("@ = *(%sint8_t *)(uintptr_t)(DBL_PTR(@)->dbl);\n", {sign}),
				{target, source})
	else
		c_stmt(sprintf("@ = *(%sint8_t *)@;\n",{sign}), {target, source})
	end if
end procedure

procedure seg_peek2(integer target, integer source, integer mode)
-- emit code for a single-word peek  - uses _1 as a temp
	sequence sign
	if Code[pc] = PEEK2U then
		sign = "u"
	else
		sign = ""
	end if
	if mode = 1 then
		c_stmt(sprintf("@ = *(%sint16_t *)(uintptr_t)(DBL_PTR(@)->dbl);\n",{sign}),
				{target, source})
	else
		c_stmt(sprintf("@ = *(%sint16_t *)@;\n",{sign}), {target, source})
	end if
end procedure

procedure seg_peek4(integer target, integer source, boolean dbl)
-- emit code for a 4-byte signed or unsigned peek
	-- WATCOM: memory is seamless
	sequence sign
	if Code[pc] = PEEK4U then
		sign = "u"
	else
		sign = ""
	end if
	if dbl then
		c_stmt( sprintf( "@ = (object)*(%sint32_t *)(uintptr_t)(DBL_PTR(@)->dbl);\n", {sign} ),
				{target, source})

	else
		c_stmt( sprintf( "@ = (object)*(%sint32_t *)@;\n", {sign} ),  {target, source})
	end if
	if Code[pc] = PEEK4S then
		c_stmt("if (@ < MININT || @ > MAXINT){\n",
					{target, target})
		c_stmt("@ = NewDouble((eudouble)(object)@);\n",
				{target, target})
		c_stmt0("}\n")
	else  -- PEEK4U */
		c_stmt("if ((uintptr_t)@ > (uintptr_t)MAXINT){\n", target)
		c_stmt("@ = NewDouble((eudouble)(uintptr_t)@);\n", {target, target})
		c_stmt0("}\n")
	end if
	-- FIX: in first BB we might assume TYPE_INTEGER, value 0
	-- so CName will output a 0 instead of the var's name
	SetBBType( target, GType(target), novalue, TYPE_OBJECT, 0)

end procedure

procedure seg_peek8(integer target_sym, integer source, boolean dbl, integer op)
-- emit code for a 4-byte signed or unsigned peek
	sequence sign
	if Code[pc] = PEEK4U then
		sign = "u"
	else
		sign = ""
	end if
	if dbl then
		c_stmt( sprintf( "peek8_longlong = *(%sint64_t *)(uintptr_t)(DBL_PTR(@)->dbl);\n", {sign} ), 
			source)

	else
		c_stmt( sprintf( "peek8_longlong = *(%sint64_t *)@;\n", {sign} ), source)
	end if
	
	-- FIX: in first BB we might assume TYPE_INTEGER, value 0
	-- so CName will output a 0 instead of the var's name
	SetBBType( target_sym, GType(target_sym), novalue, TYPE_OBJECT, 0)

	if op = PEEK8S then
		c_stmt0("if (peek8_longlong < (int64_t)MININT || peek8_longlong > (int64_t) MAXINT){\n")
		c_stmt("@ = NewDouble((eudouble) peek8_longlong);\n", target_sym)
		c_stmt0("}\n")
		c_stmt0("else{\n")
			c_stmt("@ = (object) peek8_longlong;\n", target_sym, target_sym )
		c_stmt0("}\n")
		

	elsif op = PEEK8U then
		c_stmt0("if (peek8_longlong > (uint64_t)MAXINT){\n")
		c_stmt("@ = NewDouble((eudouble)(uint64_t)peek8_longlong);\n", target_sym)
		c_stmt0("}\n")
		c_stmt0("else{\n")
			c_stmt("@ = (object) peek8_longlong;\n", target_sym, target_sym )
		c_stmt0("}\n")
		
	end if
	-- FIX: in first BB we might assume TYPE_INTEGER, value 0
	-- so CName will output a 0 instead of the var's name
	SetBBType( target_sym, GType(target_sym), novalue, TYPE_OBJECT, 0)
end procedure

procedure seg_poke1(integer source, boolean dbl)
-- poke a single byte value into poke_addr
	-- WATCOM etc.
	if dbl then
		c_stmt("*poke_addr = (uint8_t)DBL_PTR(@)->dbl;\n", source)
	else
		c_stmt("*poke_addr = (uint8_t)@;\n", source)
	end if

end procedure

procedure seg_poke2(integer source, boolean dbl)
-- poke a word value into poke2_addr
	if dbl then
		c_stmt("*poke2_addr = (uint16_t)DBL_PTR(@)->dbl;\n", source)
	else
		c_stmt("*poke2_addr = (uint16_t)@;\n", source)
	end if
end procedure

procedure seg_poke4(integer source, boolean dbl)
-- poke a 4-byte value into poke4_addr
	-- WATCOM etc.
	if dbl then
		c_stmt("*poke4_addr = (uint32_t)DBL_PTR(@)->dbl;\n", source)
	else
		c_stmt("*poke4_addr = (uint32_t)@;\n", source)
	end if

end procedure

procedure seg_poke8(integer source, boolean dbl)
-- poke an 8-byte value into poke8_addr
	-- WATCOM etc.
	if dbl then
		c_stmt("*poke8_addr = (uint64_t)DBL_PTR(@)->dbl;\n", source)
	else
		c_stmt("*poke8_addr = (uint64_t)@;\n", source)
	end if

end procedure

procedure seg_pokeptr(integer source, boolean dbl)
-- poke an 8-byte value into poke8_addr
	-- WATCOM etc.
	if dbl then
		c_stmt("*pokeptr_addr = (uintptr_t)DBL_PTR(@)->dbl;\n", source)
	else
		c_stmt("*pokeptr_addr = (uintptr_t)@;\n", source)
	end if

end procedure

function machine_func_type(integer x)
-- return the type and min/max when x is an integer constant value
	symtab_index s
	integer func_num
	sequence range

	s = x

	-- we aren't tracking var (and temp?) constant values in the BB (yet)

	if SymTab[s][S_MODE] = M_CONSTANT then
		if GType(x) = TYPE_INTEGER then
			func_num = ObjValue(x)
			if func_num != NOVALUE then
				if func_num = M_COMPLETE then
					range = {MININT, MAXINT}
					return {TYPE_INTEGER, range}

				elsif func_num = M_GRAPHICS_MODE then
					range = {MININT, MAXINT}
					return {TYPE_INTEGER, range}

				elsif func_num = M_TEXTROWS then
					range = {20, 500}
					return {TYPE_INTEGER, range}

				elsif func_num = M_SEEK then
					range = {MININT, MAXINT}
					return {TYPE_INTEGER, range}

				elsif func_num = M_LOCK_FILE then
					range = {0, 1}
					return {TYPE_INTEGER, range}

				elsif func_num = M_CHDIR then
					range = {0, 1}
					return {TYPE_INTEGER, range}

				elsif func_num = M_CRASH then
					range = {0, 1}
					return {TYPE_INTEGER, range}

				elsif func_num = M_CHECK_BREAK then
					range = {0, MAXINT-1000}
					return {TYPE_INTEGER, range}

				elsif func_num = M_GET_DISPLAY_PAGE then
					range = {0, 64}
					return {TYPE_INTEGER, range}

				elsif func_num = M_GET_ACTIVE_PAGE then
					range = {0, 64}
					return {TYPE_INTEGER, range}

				elsif func_num = M_ALLOC_LOW then
					range = {0, 1500000}
					return {TYPE_INTEGER, range}

				elsif func_num = M_DEFINE_C then
					range = {-1, 100000000}
					return {TYPE_INTEGER, range}

				elsif func_num = M_WAIT_KEY then
					range = {-1, 1000}
					return {TYPE_INTEGER, range}

				elsif find(func_num, {M_WHERE, M_OPEN_DLL,
									  M_DEFINE_VAR, M_INSTANCE, M_ALLOC,
									  M_F64_TO_A, M_F32_TO_A}) then
					return {TYPE_ATOM, novalue}

				elsif find(func_num, {M_VIDEO_CONFIG, M_GET_POSITION,
									  M_CURRENT_DIR, M_GET_SCREEN_CHAR,
									  M_INTERRUPT, M_GET_VECTOR,
									  M_A_TO_F64, M_A_TO_F32}) then
					return {TYPE_SEQUENCE, novalue}

				else
					return {TYPE_OBJECT, novalue}

				end if
			end if
		end if
	end if
	return {TYPE_OBJECT, novalue}
end function

function machine_func_elem_type(integer x)
-- return the sequence element type when x is an integer constant value
	symtab_index s
	integer func_num

	s = x

	-- we aren't tracking var (and temp?) constant values in the BB (yet)

	if SymTab[s][S_MODE] = M_CONSTANT then
		if GType(x) = TYPE_INTEGER then
			func_num = ObjValue(x)
			if func_num != NOVALUE then
				if find(func_num, {M_VIDEO_CONFIG, M_GET_POSITION,
						M_PALETTE, -- but type itself could be integer
						M_CURRENT_DIR, M_INTERRUPT, M_A_TO_F64, M_A_TO_F32}) then
						return TYPE_INTEGER
				else
					return TYPE_OBJECT
				end if
			end if
		end if
	end if
	return TYPE_OBJECT
end function

procedure main_temps()
-- declare main's temps (for each main_ file)
	symtab_index sp

	NewBB(0, E_ALL_EFFECT, 0)
	sp = SymTab[TopLevelSub][S_TEMPS]
	Initializing = TRUE
	sequence names = {}
	while sp != 0 do
		if SymTab[sp][S_SCOPE] != DELETED then
			sequence name = sprintf("_%d", SymTab[sp][S_TEMP_NAME] )
			if temp_name_type[SymTab[sp][S_TEMP_NAME]][T_GTYPE] != TYPE_NULL
			and not find( name, names ) then
				c_stmt0("object ")
				c_printf("%s", {name})
				names = append( names, name )
				if temp_name_type[SymTab[sp][S_TEMP_NAME]][T_GTYPE] != TYPE_INTEGER then
					c_puts(" = 0")
					-- avoids DeRef in 1st BB, but may hurt global type:
					target = {0, 0}
					SetBBType(sp, TYPE_INTEGER, target, TYPE_OBJECT, 0 )
				end if
				c_puts(";\n")
			end if
		end if
		SymTab[sp][S_GTYPE] = TYPE_OBJECT
		sp = SymTab[sp][S_NEXT]
	end while
	if SymTab[TopLevelSub][S_LHS_SUBS2] then
		c_stmt0("object _0, _1, _2, _3;\n\n")
	else
		c_stmt0("object _0, _1, _2;\n\n")
	end if
	Initializing = FALSE
end procedure

export sequence LL_suffix = ""
if SIZEOF_POINTER = 8 then
	LL_suffix = "LL"
end if
function FoldInteger(integer op, integer target, integer left, integer right)
-- try to fold an integer operation: + - * power floor_div
-- we know that left and right are of type integer.
-- we compute the min/max range of the result (if integer)
	sequence left_val, right_val, result
	atom intres
	atom d1, d2, d3, d4
	object p1, p2, p3, p4

	left_val = ObjMinMax(left)
	right_val = ObjMinMax(right)
	result = {NOVALUE, NOVALUE}

	if op = PLUS or op = PLUS_I then
		intres = left_val[MIN] + right_val[MIN]

		if intres >= MININT and intres <= MAXINT then
			result[MIN] = intres
		else
			result[MIN] = NOVALUE
		end if

		intres = left_val[MAX] + right_val[MAX]

		if intres >= MININT and intres <= MAXINT then
			result[MAX] = intres
		else
			result[MIN] = NOVALUE
		end if

		if result[MIN] = result[MAX] and result[MIN] != NOVALUE then
			c_stmt("@ = ", target)
			c_printf("%d%s;\n", {result[MIN], LL_suffix})
		end if

	elsif op = MINUS or op = MINUS_I then

		intres = left_val[MIN] - right_val[MAX]

		if intres >= MININT and intres <= MAXINT then
			result[MIN] = intres
		else
			result[MIN] = NOVALUE
		end if

		intres = left_val[MAX] - right_val[MIN]

		if intres >= MININT and intres <= MAXINT then
			result[MAX] = intres
		else
			result[MIN] = NOVALUE
		end if

		if result[MIN] = result[MAX] and result[MIN] != NOVALUE then
			c_stmt("@ = ", target)
			c_printf("%d%s;\n", {result[MIN], LL_suffix})
		end if

	elsif op = rw:MULTIPLY then

		d1 = left_val[MIN] * right_val[MIN]
		d2 = left_val[MIN] * right_val[MAX]
		d3 = left_val[MAX] * right_val[MIN]
		d4 = left_val[MAX] * right_val[MAX]

		if d1 <= MAXINT_DBL and d1 >= MININT_DBL and
		   d2 <= MAXINT_DBL and d2 >= MININT_DBL and
		   d3 <= MAXINT_DBL and d3 >= MININT_DBL and
		   d4 <= MAXINT_DBL and d4 >= MININT_DBL then

			p1 = d1
			p2 = d2
			p3 = d3
			p4 = d4

			result[MIN] = p1

			if p2 < result[MIN] then
				result[MIN] = p2
			end if

			if p3 < result[MIN] then
				result[MIN] = p3
			end if

			if p4 < result[MIN] then
				result[MIN] = p4
			end if

			result[MAX] = p1

			if p2 > result[MAX] then
				result[MAX] = p2
			end if

			if p3 > result[MAX] then
				result[MAX] = p3
			end if

			if p4 > result[MAX] then
				result[MAX] = p4
			end if

			if result[MIN] = result[MAX] and result[MIN] != NOVALUE then
				intres = result[MIN]
				c_stmt("@ = ", target)
				c_printf("%d%s;\n", {intres, LL_suffix})
			end if
		end if

	elsif op = POWER then
		-- be careful - we could cause "overflow" error in power()
		if left_val[MIN] = left_val[MAX] and
		   right_val[MIN] = right_val[MAX] then
			-- try it
			p1 = power(left_val[MIN], right_val[MIN])

			if is_integer(p1) then
				result[MIN] = p1
				result[MAX] = result[MIN]
				c_stmt("@ = ", target)
				c_printf("%d%s;\n", {result[MIN], LL_suffix})
			end if

		else
			-- range of values - crude estimate
			-- note: power(x,2) is changed to ` in emit.c
			-- so we try to handle powers up to 4
			if right_val[MAX] <= 4 and right_val[MIN] >= 0 and
				left_val[MAX] < 177 and left_val[MIN] > -177 then
				-- should get integer result
				result[MIN] = MININT
				result[MAX] = MAXINT
			end if

		end if

	else
		-- L_FLOOR_DIV */

		-- watch out for MININT / -1 */

		if left_val[MIN] = left_val[MAX] and
		   right_val[MIN] = right_val[MAX] and right_val[MIN] != 0 then
			-- try to constant fold
--          if right_val[MIN] > 0 and left_val[MIN] >= 0 then
--              intres = left_val[MIN] / right_val[MIN]
--          else
				intres = floor(left_val[MIN] / right_val[MIN])
--          end if

			if intres >= MININT and intres <= MAXINT then
				c_stmt("@ = ", target)
				c_printf("%d%s;\n", {intres, LL_suffix})
				result[MIN] = intres
				result[MAX] = result[MIN]
			end if

		else
			-- a rough stab at it - could do better */
			if right_val[MIN] >= 2 then
				-- narrow the result range */
				result[MIN] = left_val[MIN] / right_val[MIN] - 1
				result[MAX] = left_val[MAX] / right_val[MIN] + 1
			end if
		end if
	end if
	return result
end function

constant DEREF_PACK = 5
sequence deref_buff
deref_buff = {}

procedure FlushDeRef()
	for i = 1 to length(deref_buff) do
		LeftSym = TRUE
		c_stmt("DeRef(@);\n", deref_buff[i])
	end for
	deref_buff = {}
end procedure

procedure FinalDeRef(symtab_index sym)
-- do final deref of a temp at end of a function, type or procedure
	integer i, t

	if is_temp( sym ) then
		i = BB_temp_type(sym)
		t = BB_temp_elem(sym)
	else
		i = BB_temp_type(sym)
		t = BB_temp_elem(sym)
		if i != TYPE_INTEGER and i != TYPE_NULL then
			LeftSym = TRUE
			if i = TYPE_ATOM then
				deref_buff = append(deref_buff, sym)

			elsif i = TYPE_OBJECT then
				if t = TYPE_INTEGER then
					c_stmt("DeRefi(@);\n", sym)
				else
					deref_buff = append(deref_buff, sym)
				end if

			elsif i = TYPE_SEQUENCE then
				if t = TYPE_INTEGER then
					c_stmt("DeRefDSi(@);\n", sym)
				else
					c_stmt("DeRefDS(@);\n", sym)
				end if

			else
				-- TYPE_DOUBLE
				c_stmt("DeRefDS(@);\n", sym)
			end if

			-- try to bundle sets of 5 DeRef's
			if length(deref_buff) = DEREF_PACK then
				LeftSym = TRUE
				c_stmt("DeRef5(@", deref_buff[1])
				for d = 2 to DEREF_PACK do
					c_puts(", ")
					LeftSym = TRUE
					CName(deref_buff[d])
				end for
				c_puts(");\n")
				deref_buff = {}
			end if
		end if
	end if
end procedure

function NotInRange(integer x, integer badval)
-- return TRUE if x can't be badval
	sequence range

	range = ObjMinMax(x)
	if range[MIN] > badval then
		return TRUE
	end if
	if range[MAX] < badval then
		return TRUE
	end if
	return FALSE
end function

function int32_mult_testa( sequence range_a )
	sequence test_a
	if range_a[MIN] >= -INT16 and range_a[MAX] <= INT16 then
		test_a = ""     -- will pass for sure
	elsif range_a[MAX] < -INT16 or range_a[MIN] > INT16 then
		return 0  -- will fail for sure
	else
		test_a = "@2 == (short)@2"  -- not sure
	end if
	return test_a
end function

function int64_mult_testa( sequence range_a )
	sequence test_a
	if range_a[MIN] >= -INT32 and range_a[MAX] <= INT32 then
		test_a = ""     -- will pass for sure
	elsif range_a[MAX] < -INT32 or range_a[MIN] > INT32 then
		return 0  -- will fail for sure
	else
		test_a = "@2 == (int32_t)@2"  -- not sure
	end if
	return test_a
end function

function int32_mult_testb1( sequence range_b )
	sequence test_b1
	if range_b[MAX] <= INT15 then
		test_b1 = ""    -- will pass for sure
	elsif range_b[MIN] > INT15 then
		return 0  -- will fail for sure
	else
		test_b1 = "@3 <= INT15"  -- not sure
	end if
	return test_b1
end function

function int64_mult_testb1( sequence range_b )
	sequence test_b1
	if range_b[MAX] <= INT31 then
		test_b1 = ""    -- will pass for sure
	elsif range_b[MIN] > INT31 then
		return 0  -- will fail for sure
	else
		test_b1 = "@3 <= INT31"  -- not sure
	end if
	return test_b1
end function

function int32_mult_testb2( sequence range_b )
	sequence test_b2
	if range_b[MIN] >= -INT15 then
		test_b2 = ""    -- will pass for sure
	elsif range_b[MAX] < -INT15 then
		return 0  -- will fail for sure
	else
		test_b2 = "@3 >= -INT15"  -- not sure
	end if
	return test_b2
end function

function int64_mult_testb2( sequence range_b )
	sequence test_b2
	if range_b[MIN] >= -INT31 then
		test_b2 = ""    -- will pass for sure
	elsif range_b[MAX] < -INT31 then
		return 0  -- will fail for sure
	else
		test_b2 = "@3 >= -INT31"  -- not sure
	end if
	return test_b2
end function


function IntegerMultiply(integer a, integer b)
-- create the optimal code for multiplying two integers,
-- based on their min and max values.
-- a must be from -INT16 to +INT16
-- b must be from -INT15 to +INT15
	sequence multiply_code
	sequence dblcode
	object test_a, test_b1, test_b2
	sequence range_a, range_b

	if TypeIs(a, TYPE_INTEGER) then
		range_a = ObjMinMax(a)
	else
		range_a = {MININT, MAXINT}
	end if

	if TypeIs(b, TYPE_INTEGER) then
		range_b = ObjMinMax(b)
	else
		range_b = {MININT, MAXINT}
	end if

	dblcode = "@1 = NewDouble(@2 * (eudouble)@3);\n"

	-- test_a
	if SIZEOF_POINTER = 4 then
		test_a = int32_mult_testa( range_a )
		
	else
		test_a = int64_mult_testa( range_a )
	end if
	
	if atom( test_a ) then
		return dblcode
	end if
	
	-- test_b1
	if SIZEOF_POINTER = 4 then
		test_b1 = int32_mult_testb1( range_b )
	else
		test_b1 = int64_mult_testb1( range_b )
	end if
	if atom( test_b1 ) then
		return dblcode
	end if
	
	
	-- test_b2
	if SIZEOF_POINTER = 4 then
		test_b2 = int32_mult_testb2( range_b )
	else
		test_b2 = int64_mult_testb2( range_b )
	end if
	if atom( test_b2 ) then
		return dblcode
	end if
	
	-- put it all together
	multiply_code = "if ("

	multiply_code &= test_a

	if length(test_a) and length(test_b1) then
		multiply_code &= " && "
	end if

	multiply_code &= test_b1

	if (length(test_a) or length(test_b1)) and length(test_b2) then
		multiply_code &= " && "
	end if

	multiply_code &= test_b2

	if length(test_a) or length(test_b1) or length(test_b2) then
		multiply_code &= "){\n" &
						 "@1 = @2 * @3;\n}\n" &
						 "else{\n"
		if SIZEOF_POINTER = 4 then
			multiply_code &= "@1 = NewDouble(@2 * (eudouble)@3);\n}\n"
		else
			multiply_code &= "long double ld = ((long double)@2) * ((long double)@3);\n"
			multiply_code &= "if( ld <= (long double)MAXINT && ld >= (long double)MININT ){\n"
			multiply_code &= "@1 = (object)ld;\n"
			multiply_code &= "}\nelse{\n"
			multiply_code &= "@1 = NewDouble( (eudouble)ld );\n"
			multiply_code &= "}\n}\n"
		end if
	else
		multiply_code = "@1 = @2 * @3;\n"  -- no tests, must be integer
	end if

	return multiply_code
end function

procedure unary_div(integer pc, integer target_type, sequence intcode,
					sequence gencode)
-- unary divide ops
	CSaveStr("_0", Code[pc+3], Code[pc+1], 0, 0)

	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt("if (IS_ATOM_INT(@)) {\n", Code[pc+1])
	end if

	if TypeIsIn(Code[pc+1], TYPES_IAO) then
		-- handle integer
		c_stmt(intcode, {Code[pc+3], Code[pc+1]}, Code[pc+3])
	end if

	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt0("}\n")
		c_stmt0("else {\n")
	end if

	if TypeIsNot(Code[pc+1], TYPE_INTEGER) then
		-- handle double or sequence
		c_stmt(gencode, {Code[pc+3], Code[pc+1]}, Code[pc+3])
	end if

	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt0("}\n")
	end if

	CDeRefStr("_0")
	SetBBType(Code[pc+3], target_type, novalue, TYPE_OBJECT, HasDelete( Code[pc+3] ))
	create_temp( Code[pc+3], NEW_REFERENCE )
	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
end procedure

function unary_optimize(integer pc, integer target_type, sequence target_val,
						sequence intcode, sequence intcode2, sequence gencode)
-- handle a few special unary ops
	CSaveStr("_0", Code[pc+2], Code[pc+1], 0, 0)

	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt("if (IS_ATOM_INT(@)) {\n", Code[pc+1])
	end if

	if TypeIsIn(Code[pc+1], TYPES_IAO) then
		-- handle integer
		if Code[pc] = UMINUS then
			if (target_type = TYPE_INTEGER or
			   SymTab[Code[pc+2]][S_GTYPE] = TYPE_INTEGER) and
			   TypeIs(Code[pc+1], TYPE_INTEGER) then
				c_stmt(intcode2, {Code[pc+2], Code[pc+1]})
				CDeRefStr("_0")
				SetBBType(Code[pc+2], TYPE_INTEGER, target_val, TYPE_OBJECT, HasDelete( Code[pc+2] ) )
				pc += 3
				if Code[pc] = INTEGER_CHECK then
					pc += 2 -- skip it
				end if
				return pc
			end if
		end if
		c_stmt(intcode, {Code[pc+2], Code[pc+1]})
	end if

	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt0("}\n")
		c_stmt0("else {\n")
	end if

	if TypeIsNot(Code[pc+1], TYPE_INTEGER) then
		-- handle double or sequence
		c_stmt(gencode, {Code[pc+2], Code[pc+1]})
	end if

	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt0("}\n")
	end if

	CDeRefStr("_0")
	SetBBType(Code[pc+2], target_type, target_val, TYPE_OBJECT, HasDelete( Code[pc+2] ) )
	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+2], 1 )
	return pc + 3
end function

function ifwi(integer pc, sequence op)
-- relational ops, integer operands
	atom result
	sequence left_val, right_val

	result = NOVALUE
	left_val = ObjMinMax(Code[pc+1])
	right_val = ObjMinMax(Code[pc+2])

	if equal(op, ">=") then
		if left_val[MIN] >= right_val[MAX] then
			result = TRUE
		elsif left_val[MAX] < right_val[MIN] then
			result = FALSE
		end if

	elsif equal(op, "<=") then
		if left_val[MAX] <= right_val[MIN] then
			result = TRUE
		elsif left_val[MIN] > right_val[MAX] then
			result = FALSE
		end if

	elsif equal(op, "!=") then
		if left_val[MAX] < right_val[MIN] then
			result = TRUE
		elsif left_val[MIN] > right_val[MAX] then
			result = TRUE
		elsif left_val[MAX] = left_val[MIN] and
			  right_val[MAX] = right_val[MIN] and
			  left_val[MIN] = right_val[MIN] then
			result = FALSE
		end if

	elsif equal(op, "==") then
		if left_val[MAX] < right_val[MIN] then
			result = FALSE
		elsif left_val[MIN] > right_val[MAX] then
			result = FALSE
		elsif left_val[MAX] = left_val[MIN] and
			  right_val[MAX] = right_val[MIN] and
			  left_val[MIN] = right_val[MIN] then
			result = TRUE
		end if

	elsif equal(op, ">") then
		if left_val[MIN] > right_val[MAX] then
			result = TRUE
		elsif left_val[MAX] <= right_val[MIN] then
			result = FALSE
		end if

	elsif equal(op, "<") then
		if left_val[MAX] < right_val[MIN] then
			result = TRUE
		elsif left_val[MIN] >= right_val[MAX] then
			result = FALSE
		end if

	end if

	if result = TRUE then

		if forward_branch_into(pc+4, Code[pc+3]-1) then
			-- there's a goto or something here, so we can't just optimize away
			Goto( Code[pc+3] )
			return pc + 4
		else
			-- skip the entire IF statement_list END IF
			return Code[pc+3]
		end if

	elsif result = NOVALUE then
		c_stmt("if (@ " & op & " @)\n", {Code[pc+1], Code[pc+2]})
		Goto(Code[pc+3])
		return pc + 4

	else
		return pc + 4
	end if
end function

function ifw(integer pc, sequence op, sequence intop)
-- relational ops, integers or atoms
	-- could be better optimized
	if TypeIs(Code[pc+1], TYPE_INTEGER) and
	   TypeIs(Code[pc+2], TYPE_INTEGER) then
--      c_stmt("if (@ ", Code[pc+1])
--      c_puts(intop)
--      temp_indent = -indent
--      c_stmt(" @)\n", Code[pc+2])   -- leading blank to avoid LeftSym
		return ifwi(pc, intop)
	else
		c_stmt0("if (binary_op_a(")
		c_puts(op)
		temp_indent = -indent
		c_stmt(", @, @)){\n", {Code[pc+1], Code[pc+2]})
	end if
	dispose_temps( pc+1, 2, DISCARD_TEMP, KEEP_IN_MAP )
	Goto(Code[pc+3])
	c_stmt0( "}\n" )
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	return pc + 4
end function

function binary_op(integer pc, integer ResAlwaysInt, sequence target_val,
				   sequence intcode, sequence intcode2, sequence intcode_extra,
				   sequence gencode, sequence dblfn, integer atom_type)
-- handle the completion of many binary ops
	integer target_elem, target_type, np, check
	boolean close_brace
	symtab_index rhs1  = Code[pc+1]
	symtab_index rhs2 = Code[pc+2]
	symtab_index lhs = Code[pc+3]

	target_elem = TYPE_OBJECT
	create_temp( lhs, NEW_REFERENCE )

	if TypeIs(rhs1, TYPE_SEQUENCE) then
		target_type = TYPE_SEQUENCE
		if ResAlwaysInt and
			SeqElem(rhs1) = TYPE_INTEGER and
			(TypeIs(rhs2, TYPE_INTEGER) or
			(TypeIs(rhs2, TYPE_SEQUENCE) and
			SeqElem(rhs2) = TYPE_INTEGER)) then
			target_elem = TYPE_INTEGER
		end if

	elsif TypeIs(rhs2, TYPE_SEQUENCE) then
		target_type = TYPE_SEQUENCE
		if ResAlwaysInt and
			  SeqElem(rhs2) = TYPE_INTEGER and
			  TypeIs(rhs1, TYPE_INTEGER) then
			target_elem = TYPE_INTEGER
		end if

	elsif TypeIs(rhs1, TYPE_OBJECT) then
		target_type = TYPE_OBJECT

	elsif TypeIs(rhs2, TYPE_OBJECT) then
		target_type = TYPE_OBJECT

	else
		target_type = atom_type

	end if

	CSaveStr("_0", lhs, rhs1, rhs2, 0)

	close_brace = FALSE

	check = 0

	if TypeIs(rhs1, TYPE_INTEGER) and
	   TypeIs(rhs2, TYPE_INTEGER) then
		-- uncertain about neither

		if find(Code[pc], {PLUS, PLUS_I, MINUS, MINUS_I,
						   rw:MULTIPLY, FLOOR_DIV, POWER}) then

			np = pc + 4 + 2 * (Code[pc+4] = INTEGER_CHECK)
			target = FoldInteger(Code[pc], lhs, rhs1, rhs2)
			if target[MIN] != NOVALUE and
			   target[MIN] = target[MAX] then
				-- constant folding code was emitted
				CDeRefStr("_0")
				SetBBType(lhs, TYPE_INTEGER, target,
									  TYPE_OBJECT, 0)
				dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
				return np

			elsif SymTab[lhs][S_GTYPE] = TYPE_INTEGER or
				  IntegerSize(np, lhs) or
				  target[MIN] != NOVALUE then
				-- result will be an integer
				c_stmt(intcode2, {lhs, rhs1, rhs2}, lhs)
				CDeRefStr("_0")
				if target[MIN] = NOVALUE then
					target = novalue
				end if
				SetBBType(lhs, TYPE_INTEGER, target, TYPE_OBJECT, 0)
				dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
				return np
			end if
		end if

		c_stmt(intcode, {lhs, rhs1, rhs2}, lhs)

		if ResAlwaysInt then
			-- int operands => int result
			SetBBType(lhs, TYPE_INTEGER, target_val, TYPE_OBJECT, 0)
		else
			SetBBType(lhs, TYPE_ATOM, novalue, TYPE_OBJECT, 0 )
		end if

		-- now that Code[pc+3]'s type and value have been updated:
		if find(Code[pc], {PLUS, PLUS_I, MINUS, MINUS_I}) then
			c_stmt(intcode_extra, {lhs, rhs1, rhs2}, lhs)
		end if

		CDeRefStr("_0")

		dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
		return pc + 4

	elsif TypeIs(rhs2, TYPE_INTEGER) and
		  TypeIsIn(rhs1, TYPES_AO) then
		-- uncertain about Code[pc+1] only
		check = 1
		c_stmt("if (IS_ATOM_INT(@)) {\n", Code[pc+1])

		if find(Code[pc], {PLUS, PLUS_I, MINUS, MINUS_I,
						   rw:MULTIPLY, FLOOR_DIV}) and
				(SymTab[lhs][S_GTYPE] = TYPE_INTEGER or
					IntegerSize(pc+4, lhs)) then
			c_stmt(intcode2, {lhs, rhs1, rhs2}, lhs)

		else
			c_stmt(intcode, {lhs, rhs1, rhs2}, lhs)
			if find(Code[pc], {PLUS, PLUS_I, MINUS, MINUS_I}) then
				SetBBType(lhs, GType(lhs), target_val, target_elem, 0)
				-- now that Code[pc+3]'s value has been updated:
				c_stmt(intcode_extra, {lhs, rhs1, rhs2}, lhs)
			end if

		end if

		c_stmt0("}\n")
		c_stmt0("else {\n")
		close_brace = TRUE

	elsif TypeIs(rhs1, TYPE_INTEGER) and
		  TypeIsIn(rhs2, TYPES_AO) then
		-- uncertain about Code[pc+2] only
		check = 2
		c_stmt("if (IS_ATOM_INT(@)) {\n", rhs2 )

		if find(Code[pc], {PLUS, PLUS_I, MINUS, MINUS_I,
						   rw:MULTIPLY, FLOOR_DIV}) and
						(SymTab[Code[pc+3]][S_GTYPE] = TYPE_INTEGER or
						 IntegerSize(pc+4, Code[pc+3])) then
			c_stmt(intcode2, {lhs, rhs1, rhs2}, lhs)
		else
			c_stmt(intcode, {lhs, rhs1, rhs2}, lhs)
			if find(Code[pc], {PLUS, PLUS_I, MINUS, MINUS_I}) then
				SetBBType(Code[pc+3], GType(lhs),
									  target_val, target_elem, 0)
				-- now that Code[pc+3]'s value has been updated:
				c_stmt(intcode_extra, {lhs, rhs1, rhs2}, lhs)
			end if
		end if
		c_stmt0("}\n")
		c_stmt0("else {\n")
		close_brace = TRUE

	elsif TypeIsIn(rhs1, TYPES_AO) and
		  TypeIsIn(rhs2, TYPES_AO) then
		-- uncertain about both types being TYPE_INTEGER or not
		c_stmt("if (IS_ATOM_INT(@) && IS_ATOM_INT(@)) {\n", {rhs1, rhs2})

		if find(Code[pc], {PLUS, PLUS_I, MINUS, MINUS_I,
						   rw:MULTIPLY, FLOOR_DIV}) and
						(SymTab[lhs][S_GTYPE] = TYPE_INTEGER or
						 IntegerSize(pc+4, lhs)) then
			c_stmt(intcode2, {lhs, rhs1, rhs2}, lhs)

		else
			c_stmt(intcode, {lhs, rhs1, rhs2}, lhs)
			if find(Code[pc], {PLUS, PLUS_I, MINUS, MINUS_I}) then
				SetBBType(lhs, GType(lhs), target_val, target_elem,0)
				-- now that Code[pc+3]'s value has been updated:
				c_stmt(intcode_extra, {lhs, rhs1, rhs2}, lhs)
			end if
		end if
		c_stmt0("}\n")
		c_stmt0("else {\n")
		close_brace = TRUE
	end if

	if TypeIsNot(rhs1, TYPE_INTEGER) or
	   TypeIsNot(rhs2, TYPE_INTEGER) then
		if Code[pc] != FLOOR_DIV and
		   TypeIsNotIn(rhs1, TYPES_SO) and
		   TypeIsNotIn(rhs2, TYPES_SO) then
			-- both are known to be atoms and integer:integer
			-- possibility has been handled - do it in-line

			if check != 1 and
			   TypeIsIn(rhs1, TYPES_AO) then
				c_stmt("if (IS_ATOM_INT(@)) {\n", rhs1)
			end if

			if check != 1 and
			   TypeIsIn(rhs1, TYPES_IAO) then
				if length(dblfn) > 2 then
					c_stmt("temp_d.dbl = (eudouble)@;\n", rhs1)
					c_stmt("@ = ", lhs, lhs)
					c_puts(dblfn)
					temp_indent = -indent
					c_stmt("(&temp_d, DBL_PTR(@));\n", rhs2)
				else
					c_stmt("@ = ", lhs, lhs)
					temp_indent = -indent
					if atom_type = TYPE_INTEGER then
						c_stmt("((eudouble)@ ", rhs1)
					else
						c_stmt("NewDouble((eudouble)@ ", rhs1)
					end if
					c_puts(dblfn)
					temp_indent = -indent
					c_stmt(" DBL_PTR(@)->dbl);\n", rhs2)
				end if
			end if

			if check != 1 and
			   TypeIsIn(rhs1, TYPES_AO) then
				c_stmt0("}\n")
				c_stmt0("else {\n")
			end if

			if TypeIsNot(rhs1, TYPE_INTEGER) then
				if check != 2 and
				   TypeIsIn(rhs2, TYPES_AO) then
					c_stmt("if (IS_ATOM_INT(@)) {\n", rhs2)
				end if

				if check != 2 and
				   TypeIsIn(rhs2, TYPES_IAO) then
					if length(dblfn) > 2 then
						c_stmt("temp_d.dbl = (eudouble)@;\n", rhs2)
						c_stmt("@ = ", lhs, lhs)
						c_puts(dblfn)
						temp_indent = -indent
						c_stmt("(DBL_PTR(@), &temp_d);\n", rhs1)
					else
						c_stmt("@ = ", lhs, lhs)
						temp_indent = -indent
						if atom_type = TYPE_INTEGER then
							c_stmt("(DBL_PTR(@)->dbl ", rhs1)
						else
							c_stmt("NewDouble(DBL_PTR(@)->dbl ", rhs1)
						end if
						c_puts(dblfn)
						temp_indent = -indent
						c_stmt(" (eudouble)@);\n", rhs2)
					end if
				end if

				if check != 2 and
				   TypeIsIn(rhs2, TYPES_AO) then
					c_stmt0("}\n")
					c_stmt0("else\n")
				end if

				if TypeIsNot(rhs2, TYPE_INTEGER) then
					if length(dblfn) > 2 then
						c_stmt("@ = ", lhs, lhs)
						c_puts(dblfn)
						temp_indent = -indent
						c_stmt("(DBL_PTR(@), DBL_PTR(@));\n",
											{rhs1, rhs2})
					else
						c_stmt("@ = ", lhs, lhs)
						temp_indent = -indent
						if atom_type = TYPE_INTEGER then
							c_stmt("(DBL_PTR(@)->dbl ", rhs1)
						else
							c_stmt("NewDouble(DBL_PTR(@)->dbl ", rhs1)
						end if
						c_puts(dblfn)
						temp_indent = -indent
						c_stmt(" DBL_PTR(@)->dbl);\n", rhs2)
					end if
				end if
			end if

			if check != 1 and
			   TypeIsIn(rhs1, TYPES_AO) then
				c_stmt0("}\n")
			end if

		else
			-- one might be a sequence - use general call
			c_stmt(gencode, {lhs, rhs1, rhs2}, lhs)

		end if
	end if

	if close_brace then
		c_stmt0("}\n")
	end if

	CDeRefStr("_0")
	SetBBType(lhs, target_type, target_val, target_elem, 0)
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )

	return pc + 4
end function

integer previous_previous_op
previous_previous_op = 0
integer previous_op
previous_op = 0
integer opcode
opcode = 0

procedure arg_list(integer i)
-- list of arguments for CALL_PROC / CALL_FUNC
	indent += 20
	for k = 1 to i do
		c_stmt0("*( ((intptr_t *)_2) + ")
		c_printf("%d)", k )
		if k != i then
			c_puts(", ")
		end if
		c_puts("\n")
	end for
	c_stmt0(" );\n")
	indent -= 20
end procedure

-- common vars for do_exec ops
integer n, t, ov
atom len
integer const_subs
symtab_index sub, sym
sequence gencode, intcode, intcode_extra, intcode2
sequence main_name
integer target_type, target_elem, atom_type
sequence target_val

sequence dblfn
boolean all_done

export procedure opSIZEOF()
	integer
		datatype_sym = Code[pc+1],
		target_sym   = Code[pc+2]
	
	switch sym_token( datatype_sym ) do
		case MEMSTRUCT, MEMUNION then
			sequence tag
			if sym_token( datatype_sym ) = MEMSTRUCT then
				tag = "struct"
			else
				tag = "union"
			end if
			c_stmt( sprintf( "@ = sizeof( %s @);\n", {tag} ), { target_sym, datatype_sym } )
			CDeRef( target_sym )
			
		case else
			c_stmt("@ = eu_sizeof( @ );\n", { target_sym, datatype_sym }, target_sym )
			CSaveStr( "_0", target_sym, datatype_sym, 0, 0 )
			CDeRef( target_sym )
			dispose_temp( datatype_sym, compile:DISCARD_TEMP, compile:REMOVE_FROM_MAP )
			
	end switch
	
	SetBBType( target_sym, TYPE_INTEGER, {0, MAXINT}, TYPE_INTEGER, 0 )
	create_temp( target_sym, 1 )
	pc += 3
end procedure


procedure opSTARTLINE()
-- common in Translator, not in Interpreter
	sequence line
	integer offset
	integer close_comment = 1

	c_putc('\n')
	offset = slist[Code[pc+1]][SRC]
	line = fetch_line(offset)
	if trace_called and
		and_bits(slist[Code[pc+1]][OPTIONS], SOP_TRACE)
	then
		c_stmt0("ctrace(\"")
		c_puts(name_ext(known_files[slist[Code[pc+1]][LOCAL_FILE_NO]]))
		c_printf(":%d\t", slist[Code[pc+1]][LINE])
		c_fixquote(line)
		c_puts("\");\n")

	else
		if not match("*/", line ) and not match( "/*", line ) then
			c_stmt0("/** ")
		else
			c_stmt0("//")
			close_comment = 0
		end if
		for i = length(line) to 1 by -1 do
			if not find(line[i], " \t\r\n") then
				if line[i] = '\\' then
					-- \ char at end of line causes line continuation in C
					line &= " --"
				end if
				exit
			end if
		end for
		c_puts(name_ext(known_files[slist[Code[pc+1]][LOCAL_FILE_NO]]))
		c_printf(":%d\t", slist[Code[pc+1]][LINE])
		c_puts(line)
		if close_comment then
			c_puts("*/\n")
		else
			c_puts("\n")
		end if
	end if
	pc += 2
end procedure


procedure opPROC_TAIL()
	for i = 1 to length(loop_stack) do
		if loop_stack[i][LOOP_VAR] != 0 then
			-- active for-loop var
			CDeRef(loop_stack[i][LOOP_VAR])
		end if
	end for

	-- deref the temps and privates
	sub = Code[pc+1]

	-- assign the params
	sym = SymTab[sub][S_NEXT]
	for i = 1 to SymTab[sub][S_NUM_ARGS] do
		if sym != Code[pc+1+i] then
			c_stmt( "_0 = @;\n", sym )
			c_stmt( "@ = @;\n", {sym, Code[pc+1+i]})
			CRef( sym )
			c_stmt( "DeRef(_0);\n", {} )
		end if
		sym = SymTab[sym][S_NEXT]
	end for

	while sym != 0 and SymTab[sym][S_SCOPE] <= SC_PRIVATE do
		if SymTab[sym][S_SCOPE] != SC_LOOP_VAR and
		   SymTab[sym][S_SCOPE] != SC_GLOOP_VAR then
			CDeRef(sym)
		end if
		sym = SymTab[sym][S_NEXT]
	end while

	sym = SymTab[sub][S_TEMPS]
	while sym != 0 do
		if SymTab[sym][S_SCOPE] != DELETED then
			dispose_all_temps( 0, 1 )
-- 			c_stmt( "DeRef( @ );\n", sym )
-- 			c_stmt( "@ = 0;\n", sym )
		end if
		sym = SymTab[sym][S_NEXT]
	end while


	Goto( 1 )
	pc += 2 + SymTab[sub][S_NUM_ARGS] + (SymTab[sub][S_TOKEN] != PROC)
end procedure

procedure opPROC()
-- Normal subroutine call
-- generate code for a procedure/function call
	symtab_index sub
	integer n, t, p
	object stnext
	integer eltype
	sequence temps = {}

	sub = Code[pc+1]

	n = 2 + SymTab[sub][S_NUM_ARGS] + (SymTab[sub][S_TOKEN] != PROC)

	-- update argument types
	p = SymTab[sub][S_NEXT]
	for i = 1 to SymTab[sub][S_NUM_ARGS] do
		stnext = SymTab[p]
		t = Code[pc+1+i]
		if is_temp( t ) then
			temps &= t
			if map:get( dead_temp_walking, t, NEW_REFERENCE ) = NO_REFERENCE then
				CRef(t)
			end if
		else
			CRef(t)
		end if


		SymTab[t][S_ONE_REF] = FALSE
		stnext[S_ARG_TYPE_NEW] = or_type(stnext[S_ARG_TYPE_NEW], GType(t))

		if TypeIsIn(t, TYPES_SO) then
			stnext[S_ARG_MIN_NEW] = NOVALUE
			eltype = SeqElem(t)
			if eltype != stnext[S_ARG_SEQ_ELEM_NEW] then
				eltype = or_type(stnext[S_ARG_SEQ_ELEM_NEW], eltype)
				stnext[S_ARG_SEQ_ELEM_NEW] = eltype
			end if

			if stnext[S_ARG_SEQ_LEN_NEW] = -NOVALUE then
				stnext[S_ARG_SEQ_LEN_NEW] = SeqLen(t)
			elsif stnext[S_ARG_SEQ_LEN_NEW] != SeqLen(t) then
				stnext[S_ARG_SEQ_LEN_NEW] = NOVALUE
			end if

		elsif TypeIs(t, TYPE_INTEGER) then
			target = ObjMinMax(t)
			if stnext[S_ARG_MIN_NEW] = -NOVALUE then
				-- first value in this pass
				stnext[S_ARG_MIN_NEW] = target[MIN]
				stnext[S_ARG_MAX_NEW] = target[MAX]

			elsif stnext[S_ARG_MIN_NEW] != NOVALUE then
				-- widen the range
				if target[MIN] < stnext[S_ARG_MIN_NEW] then
					stnext[S_ARG_MIN_NEW] = target[MIN]
				end if
				if target[MAX] > stnext[S_ARG_MAX_NEW] then
					stnext[S_ARG_MAX_NEW] = target[MAX]
				end if
			end if

		else
			stnext[S_ARG_MIN_NEW] = NOVALUE

		end if
		SymTab[p] = stnext
		p = SymTab[p][S_NEXT]
	end for

	if SymTab[sub][S_TOKEN] != PROC then
		p = Code[pc+n-1]
		if SymTab[p][S_MODE] = M_NORMAL then
			if find(SymTab[p][S_SCOPE], { SC_GLOBAL, SC_LOCAL, SC_EXPORT, SC_PUBLIC }) then
				-- global/local might be modified during the call,
				-- so complete the call before setting DeRef value
				c_stmt("_0 = ", p)
			else
				CSaveStr("_0", p, p, 0, 0)
				c_stmt("@ = ", p)
			end if
		else
			c_stmt("@ = ", p)
		end if
		temp_indent = -indent

	end if
	LeftSym = TRUE
	c_stmt("@", sub)
	c_puts("(")
	for i = 1 to SymTab[sub][S_NUM_ARGS] do
		CName(Code[pc+1+i])
		if i != SymTab[sub][S_NUM_ARGS] then
			c_puts(", ")
		end if
	end for
	c_puts(");\n")

	if SymTab[sub][S_EFFECT] then
		NewBB(1, SymTab[sub][S_EFFECT], sub) -- forget some local & global var values
	end if

	if SymTab[sub][S_TOKEN] != PROC then
		if SymTab[p][S_MODE] = M_NORMAL then
			if find(SymTab[p][S_SCOPE], { SC_GLOBAL, SC_LOCAL, SC_EXPORT, SC_PUBLIC} ) then
				CDeRef(p)  -- DeRef latest value, not old one
				c_stmt("@ = _0;\n", p)
			else
				CDeRefStr("_0")
			end if
		else
			create_temp( Code[pc+n-1], 1 )
		end if

		if SymTab[sub][S_GTYPE] = TYPE_INTEGER then
			target = {SymTab[sub][S_OBJ_MIN], SymTab[sub][S_OBJ_MAX]}
			SetBBType(Code[pc+n-1], SymTab[sub][S_GTYPE], target, TYPE_OBJECT,
				HasDelete( sub ) )

		elsif SymTab[sub][S_GTYPE] = TYPE_SEQUENCE then
			target[MIN] = SymTab[sub][S_SEQ_LEN]
			SetBBType(Code[pc+n-1], SymTab[sub][S_GTYPE], target,
							  SymTab[sub][S_SEQ_ELEM],
							  HasDelete( sub ) )

		else
			SetBBType(Code[pc+n-1], SymTab[sub][S_GTYPE], novalue,
							  SymTab[sub][S_SEQ_ELEM],
							  HasDelete( sub ) )

		end if
		SymTab[Code[pc+n-1]][S_ONE_REF] = FALSE
	end if

	for i = 1 to length(temps) do
		-- the proc will deref the parameter
		dispose_temp( temps[i], SAVE_TEMP, REMOVE_FROM_MAP )
	end for
	pc += n
end procedure

constant ALL_RHS_SUBS = { RHS_SUBS, RHS_SUBS_I, RHS_SUBS_CHECK }
symtab_pointer prev_rhs_subs_source = 0
procedure opRHS_SUBS()
-- RHS_SUBS / RHS_SUBS_CHECK / RHS_SUBS_I / ASSIGN_SUBS / PASSIGN_SUBS
-- var[subs] op= expr
-- generate code for right-hand-side subscripting
-- pc+1 (or _3 from above) is the sequence
-- pc+2 is the subscript
-- pc+3 is the target
	integer skip = 0
	integer op  = Code[pc]
	symtab_index
		source = Code[pc+1],
		subs   = Code[pc+2],
		target = Code[pc+3]
	symtab_pointer prev_opnd = 0

	if find( previous_op, ALL_RHS_SUBS ) then
		-- prevent early dereference if self assigning
		prev_opnd = prev_rhs_subs_source

	else
		prev_rhs_subs_source = source
	end if

	CSaveStr("_0", target, subs, source, prev_opnd )
	SymTab[target][S_ONE_REF] = FALSE

	switch op do
		case PASSIGN_OP_SUBS then
			c_stmt0("_2 = (object)SEQ_PTR(*(intptr_t *)_3);\n")
		case ASSIGN_OP_SUBS then
			c_stmt("_2 = (object)SEQ_PTR(@);\n", Code[pc+1])
			-- element type of pc[1] is changed
			SetBBType(Code[pc+1], TYPE_SEQUENCE, novalue, TYPE_OBJECT, 0 )
		case else
			c_stmt("_2 = (object)SEQ_PTR(@);\n", Code[pc+1])
	end switch

	-- _2 has the sequence
	if TypeIsNot( subs, TYPE_INTEGER) then
		c_stmt("if (!IS_ATOM_INT(@)){\n", subs )
		c_stmt("@ = (object)*(((s1_ptr)_2)->base + (object)(DBL_PTR(@)->dbl));\n",
				{ target, subs })
		c_stmt0("}\n")
		c_stmt0("else{\n")
	end if
	c_stmt("@ = (object)*(((s1_ptr)_2)->base + @);\n", {target, subs} )
	
	if TypeIsNot( subs, TYPE_INTEGER) then
		c_stmt0("}\n")
	end if

	if op = PASSIGN_OP_SUBS then -- simplified
		LeftSym = TRUE
		if sym_mode( target ) = M_NORMAL then
			c_stmt("Ref(@);\n", target )
		end if
		CDeRefStr("_0")
		SetBBType( target,
						 TYPE_OBJECT,    -- we don't know the element type
						 novalue, TYPE_OBJECT, 0)
	else
		if op = RHS_SUBS_I then
			-- target is integer var - convert doubles to ints
			if SeqElem( source ) != TYPE_INTEGER then
				SetBBType( target, TYPE_OBJECT, novalue, TYPE_OBJECT, 0 )
				c_stmt("if (!IS_ATOM_INT(@))\n", target )
				c_stmt("@ = (object)DBL_PTR(@)->dbl;\n", { target, target } )
			end if
			CDeRefStr("_0")
			SetBBType( target, TYPE_INTEGER, novalue, TYPE_OBJECT,
				HasDelete( target ) )

		elsif Code[pc+4] = INTEGER_CHECK and Code[pc+5] = Code[pc+3] then
			-- INTEGER_CHECK coming next
			if SeqElem( source ) != TYPE_INTEGER then
				SetBBType( target, TYPE_OBJECT, novalue, TYPE_OBJECT,
					HasDelete( target ) )
				c_stmt("if (!IS_ATOM_INT(@)){\n", target )
					c_stmt("@ = (object)DBL_PTR(@)->dbl;\n", { target, target } )
				c_stmt0("}\n")
			end if
			CDeRefStr("_0")
			SetBBType( target, TYPE_INTEGER, novalue, TYPE_OBJECT, 0 )
			skip = 2 -- skip INTEGER_CHECK

		else
			if SeqElem( source ) != TYPE_INTEGER then
				LeftSym = TRUE
				if sym_mode( target ) = M_NORMAL then
					if SeqElem( source ) = TYPE_OBJECT or
					SeqElem( source ) = TYPE_ATOM then
						c_stmt("Ref(@);\n", target )
					else
						c_stmt("RefDS(@);\n", target )
					end if
				end if
			end if
			CDeRefStr("_0")
			SetBBType( target, SeqElem( source ), novalue, TYPE_OBJECT,
				HasDelete( source ) )
		end if
	end if

	dispose_temp( source, DISCARD_TEMP, REMOVE_FROM_MAP )
-- 	dispose_all_temps( DISCARD_TEMP, KEEP_IN_MAP )  -- ?? Why was this here
	create_temp( target, NO_REFERENCE )
	pc += 4 + skip
end procedure

procedure opNOP1()
-- NOP1 / NOPWHILE
-- no-op - one word in translator, emit a label, not used in interpreter
	if opcode = NOPWHILE then
		loop_stack &= {{0, WHILE, pc+1}}
	end if
	Label(pc+1)
	pc += 1
end procedure

procedure opINTERNAL_ERROR()
	InternalErr(254,
		{ Code[pc], SymTab[CurrentSub][S_NAME] } )
end procedure

sequence switch_stack = {}

procedure opSWITCH_I()
	-- pc+1 = switch value
	-- pc+2 = cases seq
	-- pc+3 = jump table  (ignored)
	-- pc+4 = else offset

	integer var_type = GType( Code[pc+1] )

	switch_stack = append( switch_stack, { Code[pc], pc, var_type } )
	if var_type != TYPE_INTEGER then

		if var_type = TYPE_SEQUENCE then
			-- it will never work
			switch_stack[$][3] = -1

			-- The commented code below is meant to avoid emitting the switch
			-- block, since we know it won't work.  The problem occurs if
			-- there is a backwards goto into the switch somewhere.  We
			-- don't know about the label yet, so we might incorrectly
			-- optimize this away.  The extra code emitted will probably
			-- be optimized away by the compiler, so it's probably no big
			-- deal.
-- 			if not forward_branch_into(pc+5, Code[pc+4]-1) then
-- 				-- ...just go to the default because there's a label in there
-- 				pc = Code[pc+4]
-- 				return
-- 			end if
			-- just jump ahead
			Goto( Code[pc+4] )
			pc += 5
			return
		end if

		-- find something that's not a case
		atom min = MAXINT
		sequence cases = SymTab[Code[pc+2]][S_OBJ]
		for i = 1 to length( cases ) do
			if cases[i] < min then
				min = cases[i]-1
			end if
		end for

		-- it's possibly an atom or a sequence, so we have extra checking to do
		c_stmt("if (IS_SEQUENCE(@) ){\n", Code[pc+1] )
		Goto( Code[pc+4] )
		c_stmt0("}\n")
		c_stmt( "if(!IS_ATOM_INT(@)){\n", Code[pc+1] )
		c_stmt( "if( (DBL_PTR(@)->dbl != (eudouble) ((object) DBL_PTR(@)->dbl) ) ){\n",
						repeat( Code[pc+1], 2) )
		Goto( Code[pc+4] )
		c_stmt0( "}\n" )
		c_stmt( "_0 = (object) DBL_PTR(@)->dbl;\n", Code[pc+1] )
		c_stmt0( "}\n" )
		c_stmt0( "else {\n" )
		c_stmt( "_0 = @;\n", Code[pc+1] )
		c_stmt0( "};\n")
	else
		c_stmt( "_0 = @;\n", Code[pc+1] )
	end if

	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	c_stmt0("switch ( _0 ){ \n" )
	pc += 5

end procedure

procedure opSWITCH()
	-- pc+1 = switch value
	-- pc+2 = cases seq
	-- pc+3 = jump table  (ignored)
	-- pc+4 = else offset (ignored)
	switch_stack = append( switch_stack, { Code[pc], pc, 0 } )
	c_stmt("_1 = find(@, @);\n", { Code[pc+1], Code[pc+2]})
	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	c_stmt0("switch ( _1 ){ \n" )
	pc += 5
end procedure

procedure opSWITCH_RT()
	-- pc+1 = switch value
	-- pc+2 = cases seq
	-- pc+3 = jump table  (ignored)
	-- pc+4 = else offset
	sequence cases = SymTab[Code[pc+2]][S_OBJ]
	integer all_ints = 1
	sequence values = cases
	for i = 1 to length( cases ) do
		object c = ObjValue( cases[i] )
		if not is_integer( c ) then
			all_ints = 0
			exit
		end if
		values[i] = c
	end for

	if all_ints then
		SymTab[Code[pc+2]][S_OBJ] = values
		Code[pc] = SWITCH_I
		SymTab[CurrentSub][S_CODE] = Code
		-- don't increment pc, because we'll just let it go to opSWITCH_I
		return
	end if

	-- Need to turn this into a regular SWITCH, but the trick is that
	-- the sequence needs to reference the actual literals / variables.
	integer s = CurrentSub
	sequence init_var = sprintf( "_%d_cases", Code[pc+2] )
	while SymTab[s][S_NEXT] != 0 and eu:compare( init_var, SymTab[s][S_NAME] ) do
		s = SymTab[s][S_NEXT]
	end while
	if eu:compare( SymTab[s][S_NAME], init_var ) then
		-- need to add the variable
		sequence eentry
		eentry = repeat( 0, SIZEOF_VAR_ENTRY )
		eentry[S_NAME]  = init_var
		eentry[S_MODE]  = M_NORMAL
		eentry[S_SCOPE] = SC_LOCAL
		eentry[S_FILE_NO] = SymTab[CurrentSub][S_FILE_NO]
		eentry[S_USAGE] = U_READ
		SymTab = append( SymTab, eentry )
		SymTab[s][S_NEXT] = length( SymTab )
	end if

	c_stmt( "if( @ == 0 ){\n", s )
	c_stmt( "@ = 1;\n", s )
	for i = 1 to length( cases ) do
		if cases[i] < 0 then
			if is_integer( ObjValue( -cases[i] ) ) then
				c_stmt( sprintf("SEQ_PTR( @ )->base[%d] = -@;\n", i ), { Code[pc+2], -cases[i] } )
			else
				c_stmt( sprintf("SEQ_PTR( @ )->base[%d] = unary_op(UMINUS, @);\n", i ), { Code[pc+2], -cases[i] } )
			end if
		else
			c_stmt( sprintf("SEQ_PTR( @ )->base[%d] = @;\n", i ), { Code[pc+2], cases[i] } )
		end if
	end for
	c_stmt0( "}\n" )
	opSWITCH()

end procedure

procedure opCASE()
	integer caseval = Code[pc+1]
	integer stmt = 1
	if find( switch_stack[$][1], {SWITCH_I, SWITCH_SPI}) then
		-- Get the actual value from the case sequence
		if caseval = 0 then
			if switch_stack[$][3] != -1 then
				c_stmt0( "default:\n" )
				if switch_stack[$][3] != TYPE_SEQUENCE then
					-- this label might throw off the optimization
					-- and emit needless code
					Label( pc )
				end if
				stmt = 0
			else
				-- caseval was a sequence for an integer switch
				-- so do nothing
				stmt = 0
				Label( pc )
			end if

		else
			if switch_stack[$][3] = -1 then
				-- the switch has been optimized away, so don't emit the case
				stmt = 0
			else
				integer sym = Code[switch_stack[$][2] + 2]
				caseval = SymTab[sym][S_OBJ][Code[pc+1]]
			end if
		end if

	end if
	if stmt then
		c_stmt0( sprintf("case %d:\n", caseval) )
	end if
	NewBB(0, E_ALL_EFFECT, 0)
	pc += 2
end procedure

procedure opNOPSWITCH()
	if switch_stack[$][3] != -1 then
		c_stmt0( ";}" )
	end if

	Label( pc + 1 )
	switch_stack = switch_stack[1..$-1]
	pc += 1
end procedure

procedure opIF()
-- IF / WHILE
	if TypeIsNot(Code[pc+1], TYPE_INTEGER) then
		if opcode = WHILE then
			c_stmt("if (@ <= 0) {\n", Code[pc+1]) -- quick test
		end if
		c_stmt("if (@ == 0) {\n", Code[pc+1])
		dispose_temp( Code[pc+1], DISCARD_TEMP, KEEP_IN_MAP )
		Goto(Code[pc+2])
		c_stmt0("}\n")
		c_stmt0("else {\n")
			c_stmt("if (!IS_ATOM_INT(@) && DBL_PTR(@)->dbl == 0.0){\n",
							{Code[pc+1], Code[pc+1]})
				dispose_temp( Code[pc+1], DISCARD_TEMP, KEEP_IN_MAP )
				Goto(Code[pc+2])
			c_stmt0("}\n")
			dispose_temp( Code[pc+1], DISCARD_TEMP, KEEP_IN_MAP )
		c_stmt0("}\n")
		if opcode = WHILE then
			c_stmt0("}\n")
		end if
		dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
		pc += 3

	elsif ObjValue(Code[pc+1]) != NOVALUE and
		  ObjValue(Code[pc+1]) != 0 then
		-- non-zero integer  - front-end can optimize this for "while 1"
		-- no code to emit for test
		dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
		pc += 3 -- if/while TRUE - skip the test and goto

	elsif ObjValue(Code[pc+1]) = NOVALUE or
		  forward_branch_into(pc+3, Code[pc+2]-1) then
		object obj_value =  ObjValue(Code[pc+1])
		if obj_value != 0 then  -- non-zero handled above
			c_stmt("if (@ == 0)\n", Code[pc+1])
			c_stmt0( "{\n" )
		end if
		
		dispose_temp( Code[pc+1], 0, 0 )
		Goto(Code[pc+2])
		
		if obj_value != 0 then  -- non-zero handled above
			c_stmt0( "}\n" )
			c_stmt0( "else{\n" )
			dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
			c_stmt0( "}\n" )
		end if
		pc += 3

	elsif pc < Code[pc+2] then  -- it's 0, and this is a forward IF
		pc = Code[pc+2]  -- if/while FALSE - skip the whole block
						 -- (no branch into from short-circuit)
	else  -- it's 0, and this is a backward IF, ie an until statement
		Goto(Code[pc+2]) -- branch to top of loop
		pc += 3

	end if
end procedure

procedure opINTEGER_CHECK()
-- INTEGER_CHECK
	symtab_index sym = Code[pc+1]
	if SymTab[sym][S_MODE] = M_CONSTANT and is_integer( SymTab[sym][S_OBJ] ) then
		-- do nothing: an inlined routine could cause this situation

	elsif BB_var_type(sym) != TYPE_INTEGER then
		c_stmt("if (!IS_ATOM_INT(@)) {\n", sym)
		LeftSym = TRUE
		c_stmt("_1 = (object)(DBL_PTR(@)->dbl);\n", sym)
		LeftSym = TRUE
		c_stmt("DeRefDS(@);\n", sym)
		c_stmt("@ = _1;\n", sym)
		c_stmt0("}\n")
		SetBBType(sym, TYPE_INTEGER, novalue, TYPE_OBJECT, 0 )
	end if
	pc += 2
end procedure

procedure opATOM_CHECK()
-- ATOM_CHECK / SEQUENCE_CHECK
-- other type checks - ignored by compiler */
	pc += 2
end procedure

procedure opASSIGN_SUBS()
-- Final subscript and assignment
-- Code[pc+1] has the sequence or temp containing a pointer
-- Code[pc+2] has the subscript
-- Code[pc+3] has the source

	const_subs = -1
	symtab_index rhs = Code[pc+3]

	-- get the subscript */

	if not is_temp( rhs )
	or map:get( dead_temp_walking, rhs, NEW_REFERENCE ) = NO_REFERENCE  then
		CRef( rhs) -- takes care of ASSIGN_SUBS_I
	end if
	SymTab[rhs][S_ONE_REF] = FALSE

	if Code[pc+1] = rhs then
		-- must point to original sequence
		c_stmt("_0 = @;\n", rhs)
	end if

	-- check for uniqueness
	if opcode = PASSIGN_SUBS then
		-- sequence is pointed-to from a temp
		c_stmt0("_2 = (object)SEQ_PTR(*(intptr_t *)_3);\n")
		c_stmt0("if (!UNIQUE(_2)) {\n")
		c_stmt0("_2 = (object)SequenceCopy((s1_ptr)_2);\n")
		c_stmt0("*(intptr_t *)_3 = MAKE_SEQ(_2);\n")
		c_stmt0("}\n")

	else
		c_stmt("_2 = (object)SEQ_PTR(@);\n", Code[pc+1])

		if SymTab[Code[pc+1]][S_ONE_REF] = FALSE then
			c_stmt0("if (!UNIQUE(_2)) {\n")
			c_stmt0("_2 = (object)SequenceCopy((s1_ptr)_2);\n")
			c_stmt("@ = MAKE_SEQ(_2);\n", Code[pc+1])
			c_stmt0("}\n")
		end if

	end if

	if TypeIsNot(Code[pc+2], TYPE_INTEGER) then
		c_stmt("if (!IS_ATOM_INT(@))\n", Code[pc+2])
		c_stmt("_2 = (object)(((s1_ptr)_2)->base + (object)(DBL_PTR(@)->dbl));\n",
				Code[pc+2])
		c_stmt0("else\n")
	end if
	c_stmt("_2 = (object)(((s1_ptr)_2)->base + @);\n", Code[pc+2])

	if opcode = PASSIGN_SUBS then
		-- or previous_previous_op = ASSIGN_OP_SUBS  ???

		-- Do we need to SetBBType in this _3 case????
		-- multiple lhs subs may be ok, but what about
		-- a[i] += expr ?
		-- That could change the element type of a.
		-- ... we set element type to TYPE_OBJECT
		-- in ASSIGN_OP_SUBS above

		c_stmt0("_1 = *(intptr_t *)_2;\n")
		if Code[pc+1] = rhs then
			c_stmt0("*(intptr_t *)_2 = _0;\n")
		else
			c_stmt("*(intptr_t *)_2 = @;\n", Code[pc+3])
		end if
		if is_temp( Code[pc+3] ) then
			c_stmt("if( _1 != @ ){\n", Code[pc+3] )
		end if

		c_stmt0("DeRef(_1);\n")

		if is_temp( Code[pc+3] ) then
			c_stmt0("}\n" )
		end if

	else
		if SeqElem(Code[pc+1]) != TYPE_INTEGER then
			c_stmt0("_1 = *(intptr_t *)_2;\n")
		end if

		if Code[pc+1] = rhs then
			c_stmt0("*(intptr_t *)_2 = _0;")
		else
			c_stmt("*(intptr_t *)_2 = @;\n", Code[pc+3])
		end if

		if is_temp( Code[pc+3] ) then
			c_stmt("if( _1 != @ ){\n", Code[pc+3] )
		end if
		if SeqElem(Code[pc+1]) != TYPE_INTEGER then
			if SeqElem(Code[pc+1]) = TYPE_OBJECT or
			   SeqElem(Code[pc+1]) = TYPE_ATOM then
				c_stmt0("DeRef(_1);\n")
			else
				c_stmt0("DeRefDS(_1);\n")
			end if
		end if
		if is_temp( Code[pc+3] ) then
			c_stmt0("}\n" )
		end if
		-- we can't say that all element types are GType(Code[pc+3])
		-- at this point, but we must adjust the global view
		-- of the element type. We shouldn't say TYPE_OBJECT either.
		target[MIN] = -1
		SetBBType(Code[pc+1], TYPE_SEQUENCE, target, GType(Code[pc+3]),
			HasDelete(Code[pc+1]) )
	end if
	dispose_temp( rhs, SAVE_TEMP, REMOVE_FROM_MAP )
	dispose_temp( Code[pc+1], SAVE_TEMP, REMOVE_FROM_MAP )
	pc += 4
end procedure

procedure opLENGTH()
-- LENGTH / PLENGTH
	integer 
		source_sym = Code[pc+1],
		target_sym = Code[pc+2]
	
	CSaveStr("_0", target_sym, source_sym, 0, 0)
	if opcode = LENGTH then
		if TypeIsIn( source_sym, TYPES_SO) then
			-- For sequences and object we need to check the length.
			if SeqLen( source_sym ) != NOVALUE then
				-- we know the length already, so no need for a runtime check.
				ifdef DEBUG then
					c_stmt0("// Known sequence length:\n" )
				end ifdef
				c_stmt("@ = ", target_sym )
				c_printf("%d;\n", SeqLen( source_sym ) )
				target = repeat(SeqLen( source_sym ), 2)
			else
				
				-- Fetch the current length from the struct
				c_stmt ("if (IS_SEQUENCE(@)){\n", source_sym )
					c_stmt ("    @ = SEQ_PTR(@)->length;\n", { target_sym, source_sym }, target_sym )
				c_stmt0("}\n")
				c_stmt0("else {\n" )
					c_stmt ("@ = 1;\n", Code[pc+2], Code[pc+2])
				c_stmt0("}\n")
				target = {0, MAXLEN}
			end if
		else
			ifdef DEBUG then
				c_stmt0("// Length of an atom (always 1):\n")
			end ifdef
			c_stmt("@ = 1;\n", target_sym )
			target = {1,1}
		end if
		CDeRefStr("_0")
		SetBBType( target_sym, TYPE_INTEGER, target, TYPE_OBJECT, 0 )
	else -- opcode = PLENGTH
		-- we have a pointer to an argument
		c_stmt0("if (IS_SEQUENCE(*(object_ptr)_3)){\n")
			c_stmt ("    @ = SEQ_PTR(*(object_ptr)_3)->length;\n", target_sym )
		c_stmt0("}\n")
		c_stmt0("else {\n" )
			c_stmt ("@ = 1;\n", target_sym )
		c_stmt0("}\n")
		CDeRefStr("_0")
		SetBBType( target_sym, TYPE_INTEGER, novalue, TYPE_OBJECT, 0 )
	end if

	if dispose_length() then
		dispose_temp( source_sym, DISCARD_TEMP, REMOVE_FROM_MAP )
	end if
	create_temp( source_sym, NO_REFERENCE )

	pc += 3
end procedure

--**
-- Returns 1 if a LENGTH op should dispose of its temp sequence
function dispose_length()
	symtab_index seq_sym = Code[pc+1]
	if not is_temp( seq_sym ) then
		return 0
	end if

	integer offset = 0
	sequence op
	while length( op ) and op[1] != STARTLINE and op[1] != RETURNT with entry do
		integer opnum = op[1]
		switch opnum do
			case RHS_SUBS, RHS_SUBS_I, RHS_SUBS_CHECK, RHS_SLICE, PROC then
				if find( seq_sym, op[2..$] ) then
					return 0
				end if
		end switch
	entry
		offset += 1
		op = get_ops( pc, offset )
		if length( op ) then
			op = op[1]
		end if
	end while

	return 1
end function

procedure opASSIGN()
	symtab_index
		sourcesym = Code[pc+1],
		targetsym = Code[pc+2]
	integer
		source_is_temp = is_temp( sourcesym ),
		-- This will happen when we re-use a temp parameter that gets
		-- used in a default parameter...we need the extra ref in this case
		both_are_temps = source_is_temp and is_temp( targetsym )

	if not source_is_temp or both_are_temps or map:get( dead_temp_walking, sourcesym, NO_REFERENCE ) = NO_REFERENCE then
		CRef(sourcesym)
		SymTab[Code[pc+1]][S_ONE_REF] = FALSE
		SymTab[Code[pc+2]][S_ONE_REF] = FALSE
	end if

	if SymTab[targetsym][S_MODE] != M_CONSTANT then
		CDeRef( targetsym )
	end if

	c_stmt("@ = @;\n", {targetsym, sourcesym})

	if TypeIsIn(sourcesym, TYPES_SO) then
		target[MIN] = SeqLen(Code[pc+1])
		SetBBType(targetsym, GType(sourcesym), target, SeqElem(sourcesym),
			HasDelete( sourcesym ) )
	else
		SetBBType(targetsym, GType(sourcesym), ObjMinMax(sourcesym),
				  TYPE_OBJECT, HasDelete( sourcesym ) )
	end if

	if not both_are_temps then
		dispose_temp( sourcesym, SAVE_TEMP, REMOVE_FROM_MAP )
	end if

	pc += 3
end procedure

procedure opASSIGN_I()
-- source & destination are known to be integers */
	c_stmt("@ = @;\n", {Code[pc+2], Code[pc+1]})
	SetBBType(Code[pc+2], TYPE_INTEGER, ObjMinMax(Code[pc+1]), TYPE_OBJECT, 0)
	pc += 3
end procedure

procedure opGLABEL()
	integer label_index
	integer addr

	NewBB(0, E_ALL_EFFECT, 0)
	addr = Code[pc+1]
	label_index = find_label(addr)
	c_printf("G%x:\n", label_index)
	pc += 2
end procedure

procedure opGOTO()
	integer addr

	addr = Code[pc+1]
	c_stmt0("goto ")
	c_printf("G%x;\n", find_label(addr))
	pc += 2
end procedure

procedure opEXIT()
-- EXIT / ELSE / ENDWHILE
	if opcode = ENDWHILE then
		loop_stack = loop_stack[1..$-1]
	end if
	if opcode = RETRY then
		RGoto(Code[pc+1])
	else
		Goto(Code[pc+1])
	end if
	pc += 2
end procedure

procedure opRIGHT_BRACE_N()
-- form a sequence of any length
	len = Code[pc+1]+2
	if Code[pc+1] = 0 then
		CSaveStr("_0", Code[pc+len], 0, 0, 0) -- no need to delay DeRef
	else
		CSaveStr("_0", Code[pc+len], Code[pc+len], 0, 0)
		-- must delay DeRef
	end if
	c_stmt0("_1 = NewS1(")
	c_printf("%d);\n", Code[pc+1])

	if Code[pc+1] > 0 then
		c_stmt0("_2 = (object)((s1_ptr)_1)->base;\n")
	end if

	n = 0 -- repeat count
	integer has_delete = 0
	for i = 1 to Code[pc+1] do
		t = Code[pc+len-i]
		SymTab[t][S_ONE_REF] = FALSE
		has_delete = has_delete or HasDelete( t )
		if i < Code[pc+1] and t = Code[pc+len-i-1] then
			n += 1   -- same as the next one
		else
			-- not same, or end of list
			if n <= 6 then
				if n > 0 then
					CRefn(t, n+1 - (map:get( dead_temp_walking, t, NO_REFERENCE ) = NEW_REFERENCE ))

				elsif map:get( dead_temp_walking, t, NO_REFERENCE ) = NO_REFERENCE then
					CRef(t)
				end if
				while n >= 0 do
					c_stmt( sprintf( "((intptr_t*)_2)[%d] = @;\n", i-n), t )
					n -= 1
				end while
			else
				-- 8 or more of the same in a row
				c_stmt( sprintf( "RepeatElem( (((intptr_t*) _2)+ %d), @, %d );\n", { i-n, n+1 } ), t )
			end if
			n = 0
		end if
	end for
	c_stmt("@ = MAKE_SEQ(_1);\n", Code[pc+len])
	CDeRefStr("_0")
	t = TYPE_NULL
	for i = 1 to Code[pc+1] do
		t = or_type(t, GType(Code[pc+len-i]))
	end for
	target[MIN] = Code[pc+1]
	SetBBType(Code[pc+len], TYPE_SEQUENCE, target, t, has_delete )
	dispose_temps( pc + 2, Code[pc+1], SAVE_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+len], NEW_REFERENCE )
	pc += 3 + Code[pc+1]
end procedure

procedure opRIGHT_BRACE_2()
-- form a sequence of length 2
	for i = pc + 1 to pc + 2 do
		if not is_temp( Code[i] )
		or map:get( dead_temp_walking, Code[i], NO_REFERENCE ) = NO_REFERENCE then
			CRef(Code[i])
		end if
	end for

	CSaveStr("_0", Code[pc+3], Code[pc+1], Code[pc+2], 0)
	c_stmt0("_1 = NewS1(2);\n")
	c_stmt0("_2 = (object)((s1_ptr)_1)->base;\n")
	c_stmt("((intptr_t *)_2)[1] = @;\n", Code[pc+2])

	SymTab[Code[pc+2]][S_ONE_REF] = FALSE
	c_stmt("((intptr_t *)_2)[2] = @;\n", Code[pc+1])

	SymTab[Code[pc+1]][S_ONE_REF] = FALSE
	c_stmt("@ = MAKE_SEQ(_1);\n", Code[pc+3])
	CDeRefStr("_0")
	target[MIN] = 2
	SetBBType(Code[pc+3], TYPE_SEQUENCE, target,
			  or_type(GType(Code[pc+1]), GType(Code[pc+2])),
			  HasDelete( Code[pc+1] ) or HasDelete( Code[pc+2] ) )
	dispose_temps( pc+1, 2, SAVE_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+3], NEW_REFERENCE )
	pc += 4
end procedure

procedure opPLUS1()
-- PLUS1 / PLUS1_I
	CSaveStr("_0", Code[pc+3], Code[pc+1], 0, 0)

	target_type = GType(Code[pc+1])
	if target_type = TYPE_INTEGER then
		target_type = TYPE_ATOM
	end if

	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt("if (IS_ATOM_INT(@)) {\n", Code[pc+1])
	end if

	np = pc + 4
	target_val = novalue
	if TypeIsIn(Code[pc+1], TYPES_IAO) then
		if TypeIs(Code[pc+1], TYPE_INTEGER) then
			target_val = ObjMinMax(Code[pc+1])
		end if
		ov = TRUE
		np = pc + 4 + 2 * (Code[pc+4] = INTEGER_CHECK)
		if TypeIs(Code[pc+1], TYPE_INTEGER) and
			target_val[MIN] = target_val[MAX] and
			target_val[MAX]+1 <= MAXINT then
			-- constant fold
			c_stmt("@ = ", Code[pc+3])
			c_printf("%d;\n", target_val[MIN]+1)
			target_type = TYPE_INTEGER
			target_val[MIN] += 1
			target_val[MAX] += 1
			ov = FALSE

		else
			c_stmt("@ = @ + 1;\n", {Code[pc+3], Code[pc+1]})

			if TypeIs(Code[pc+1], TYPE_INTEGER) then
				if target_val[MAX] < MAXINT then
					target_val[MIN] += 1
					target_val[MAX] += 1
					ov = FALSE

				else
					target_val = novalue
				end if
			end if

			if SymTab[Code[pc+3]][S_GTYPE] = TYPE_INTEGER or
				IntegerSize(np, Code[pc+3]) or
				not ov then
				-- no overflow possible
				if TypeIs(Code[pc+1], TYPE_INTEGER) then
					target_type = TYPE_INTEGER
				end if

			else
				-- destroy any value, check for overflow
				SetBBType(Code[pc+3], GType(Code[pc+3]), target_val,
								  target_elem, HasDelete( Code[pc+3] ) )
				c_stmt("if (@ > MAXINT){\n", Code[pc+3])
				c_stmt("@ = NewDouble((eudouble)@);\n", {Code[pc+3], Code[pc+3]})
				c_stmt0("}\n")
			end if
		end if
	end if

	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt0("}\n")
		c_stmt0("else\n")
	end if

	if TypeIsNot(Code[pc+1], TYPE_INTEGER) then
		integer target_is_int = (not is_temp( Code[pc+3] )) and GType( Code[pc+3] ) = TYPE_INTEGER
		if target_is_int then
			c_stmt(sprintf("{ // coercing @ to an integer %d\n", GType(Code[pc+3])), Code[pc+3])
			target_type = TYPE_INTEGER
		end if
		if Code[pc] = PLUS1 then
			c_stmt("@ = binary_op(PLUS, 1, @);\n", {Code[pc+3], Code[pc+1]})
		else
			c_stmt("@ = 1+(object)(DBL_PTR(@)->dbl);\n", {Code[pc+3], Code[pc+1]})
		end if
		if target_is_int then
			-- this could lead to overflow, but you should have found that while interpreting
			c_stmt("if( !IS_ATOM_INT(@) ){\n", Code[pc+3] )
			c_stmt("@ = (object)DBL_PTR(@)->dbl;\n", { Code[pc+3], Code[pc+3] })
			c_stmt0("}\n")
			c_stmt0("}\n")
		end if
	end if

	CDeRefStr("_0")

	SetBBType(Code[pc+3], target_type, target_val, target_elem, HasDelete( Code[pc+3] ) )
	create_temp( Code[pc+3], NEW_REFERENCE )
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	pc = np
end procedure

procedure opRETURNT()
-- return from top-level "procedure"
	dispose_all_temps( 0, 1 )
	if cfile_size > max_cfile_size then
		c_stmt0("main")
		c_printf("%d();\n", main_name_num)
		c_stmt0("}\n")
		main_name = sprintf("main-%d", main_name_num)
		new_c_file(main_name)
		--add_file(main_name)
		c_stmt0("main")
		c_printf("%d()\n", main_name_num)
		c_stmt0("{\n")
		main_temps()
		c_stmt0("\n")
		main_name_num += 1
	end if
	pc += 1
	if pc > length(Code) then
		all_done = TRUE
	end if
end procedure

procedure opGLOBAL_INIT_CHECK()
-- init checks - ignored by Translator
-- <built-in>_INIT_CHECK / PRIVATE_INIT_CHECK
	pc += 2
end procedure

procedure opLHS_SUBS()
-- LHS_SUBS / LHS_SUBS1 / LHS_SUBS1_COPY
	SymTab[CurrentSub][S_LHS_SUBS2] = TRUE -- need to declare _3

	if opcode = LHS_SUBS then
		-- temp has pointer to sequence
		c_stmt0("_2 = (object)SEQ_PTR(*(object_ptr)_3);\n")

	elsif opcode = LHS_SUBS1 then
		-- sequence is stored in a variable
		c_stmt("_2 = (object)SEQ_PTR(@);\n", Code[pc+1])

	else
		-- LHS_SUBS1_COPY
		c_stmt("Ref(@)\n", Code[pc+1])
		c_stmt("DeRef(@);\n", Code[pc+4])
		c_stmt("@ = @;\n", {Code[pc+4], Code[pc+1]})
		if not is_temp( Code[pc+4] ) then
			c_stmt("Ref(@);\n", Code[pc+4])
		end if
		c_stmt("_2 = (object)SEQ_PTR(@);\n", Code[pc+4])
		target[MIN] = SeqLen(Code[pc+1])
		create_temp( Code[pc+4], NEW_REFERENCE )
		SetBBType(Code[pc+4], TYPE_SEQUENCE, target, SeqElem(Code[pc+1]), HasDelete( Code[pc+1] ) )
	end if

	c_stmt0("if (!UNIQUE(_2)) {\n")
	c_stmt0("_2 = (object)SequenceCopy((s1_ptr)_2);\n")

	if opcode = LHS_SUBS then
		c_stmt0("*(object_ptr)_3 = MAKE_SEQ(_2);\n")

	elsif opcode = LHS_SUBS1 then
		c_stmt("@ = MAKE_SEQ(_2);\n", Code[pc+1])

	else
		-- LHS_SUBS1_COPY
		c_stmt("@ = MAKE_SEQ(_2);\n", Code[pc+4])
	end if

	c_stmt0("}\n")

	if TypeIsNot(Code[pc+2], TYPE_INTEGER) then
		c_stmt("if (!IS_ATOM_INT(@))\n", Code[pc+2])
		c_stmt("_3 = (object)(((s1_ptr)_2)->base + (object)(DBL_PTR(@)->dbl));\n",
				Code[pc+2])
		c_stmt0("else\n")
	end if

	c_stmt("_3 = (object)(@ + ((s1_ptr)_2)->base);\n", Code[pc+2])
	target[MIN] = -1
	-- SetBBType(Code[pc+3], TYPE_SEQUENCE, target, TYPE_OBJECT)
	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+3], NO_REFERENCE )
	pc += 5
end procedure

procedure opASSIGN_OP_SLICE()
-- ASSIGN_OP_SLICE / PASSIGN_OP_SLICE
-- var[i..j] op= expr
-- Note: _3 is set by above op
	integer has_delete = 0
	c_stmt("rhs_slice_target = (object_ptr)&@;\n", Code[pc+4])
	if opcode = PASSIGN_OP_SLICE then
		-- adjust etype of Code[pc+1]? - no, not the top level
		c_stmt0("assign_slice_seq = (s1_ptr *)_3;\n")
		c_stmt("RHS_Slice(*(intptr_t *)_3, @, @);\n",
			   {Code[pc+2], Code[pc+3]})

	else
		c_stmt("assign_slice_seq = (s1_ptr *)&@;\n", Code[pc+1])
		target[MIN] = -1
		SetBBType(Code[pc+1], TYPE_SEQUENCE, target, TYPE_OBJECT, HasDelete( Code[pc+1] ) )
		-- OR-in the element type
		c_stmt("RHS_Slice(@, @, @);\n",
			   {Code[pc+1], Code[pc+2], Code[pc+3]})
	end if
	SetBBType(Code[pc+4], TYPE_SEQUENCE, novalue, TYPE_OBJECT, HasDelete( Code[pc+1] ) )
	--length might be knowable
	dispose_temps( pc+1, 3, DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+4], NEW_REFERENCE )
	pc += 5
end procedure

procedure opASSIGN_SLICE()
-- ASSIGN_SLICE / PASSIGN_SLICE
-- var[i..j] = expr
	if previous_previous_op = ASSIGN_OP_SLICE or
	   previous_previous_op = PASSIGN_OP_SLICE then
		-- optimization, assumes no call to other Euphoria routine
		-- between [P]ASSIGN_OP_SLICE and here
		-- assign_slice_seq has already been set
		-- adjust etype - handle assign_op_slice too!!!
	elsif opcode = PASSIGN_SLICE then
		c_stmt0("assign_slice_seq = (s1_ptr *)_3;\n")
	else
		c_stmt("assign_slice_seq = (s1_ptr *)&@;\n", Code[pc+1])
		target[MIN] = -1
		SetBBType(Code[pc+1], TYPE_SEQUENCE, target, GType(Code[pc+4]), HasDelete( Code[pc+4] ) )
		-- OR-in the element type
	end if
	c_stmt("AssignSlice(@, @, @);\n", {Code[pc+2], Code[pc+3], Code[pc+4]})
	dispose_temps( pc+2, 3, DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+1], NEW_REFERENCE )
	pc += 5
end procedure

procedure opRHS_SLICE()
-- rhs slice of a sequence a[i..j]
	sequence left_val, right_val
	integer t, preserve

	t = Code[pc+4]
	c_stmt("rhs_slice_target = (object_ptr)&@;\n", t)
	c_stmt("RHS_Slice(@, @, @);\n", {Code[pc+1], Code[pc+2], Code[pc+3]})
	target = {NOVALUE, 0}
	left_val = ObjMinMax(Code[pc+2])
	right_val = ObjMinMax(Code[pc+3])
	if left_val[MIN] = left_val[MAX] and right_val[MIN] = right_val[MAX] and
	   left_val[MIN] != NOVALUE and right_val[MIN] != NOVALUE then
		-- we have definite values
		target[MIN] = right_val[MIN] - left_val[MIN] + 1
	end if

	if t = Code[pc+1] and SymTab[t][S_MODE] = M_NORMAL then
		-- don't let this operation affect our
		-- global idea of sequence element type
		preserve = SymTab[t][S_SEQ_ELEM_NEW]
		SetBBType(t, TYPE_SEQUENCE, target, SeqElem(Code[pc+1]), HasDelete(Code[pc+1]) )
		SymTab[t][S_SEQ_ELEM_NEW] = preserve
	else
		SetBBType(t, TYPE_SEQUENCE, target, SeqElem(Code[pc+1]), HasDelete(Code[pc+1]) )
	end if
	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+4], NEW_REFERENCE )
	pc += 5
end procedure

procedure opTYPE_CHECK() -- MEM_TYPE_CHECK
-- type check for a user-defined type
-- this always follows a type-call
-- The Translator only performs the type-call and check,
-- when there are side-effects, and "with type_check" is ON
	if TypeIs(Code[pc-1], TYPE_INTEGER) then
		c_stmt("if (@ == 0)\n", Code[pc-1])
		c_stmt0("RTFatal(\"user-defined type_check failure\");\n")
	else
		c_stmt("if (@ != 1) {\n", Code[pc-1])
		c_stmt("if (@ == 0)\n", Code[pc-1])
		c_stmt0("RTFatal(\"user-defined type_check failure\");\n")
		c_stmt("if (!IS_ATOM_INT(@)) {\n", Code[pc-1])
		c_stmt("if (!(IS_ATOM_DBL(@) && DBL_PTR(@)->dbl != 0.0))\n",
				{Code[pc-1], Code[pc-1]})
		c_stmt0("RTFatal(\"user-defined type_check failure\");\n")
		c_stmt0("}\n")
		c_stmt0("}\n")
	end if
	
	if Code[pc] = TYPE_CHECK then
		pc += 1
	else
		pc += 2
	end if
	
end procedure

function is_temp( symtab_index sym )
	if sym > 1 and sym <= length(SymTab)
		and sym_mode( sym ) = M_TEMP
		and equal( sym_obj( sym ), NOVALUE ) then
		return 1
	end if
	return 0
end function

procedure opIS_AN_INTEGER()
	CSaveStr("_0", Code[pc+2], Code[pc+1], 0, 0)
	if TypeIs(Code[pc+1], TYPE_INTEGER) then
		c_stmt("@ = 1;\n", Code[pc+2])
	elsif TypeIs(Code[pc+1], TYPE_SEQUENCE) then
		c_stmt("@ = 0;\n", Code[pc+2])
	elsif TypeIs(Code[pc+1], TYPE_DOUBLE) then
		c_stmt("@ = IS_ATOM_INT(DoubleToInt(@));\n", {Code[pc+2], Code[pc+1]})
	else
		c_stmt("if (IS_ATOM_INT(@))\n", Code[pc+1])
		c_stmt("@ = 1;\n", Code[pc+2])
		c_stmt("else if (IS_ATOM_DBL(@))\n", Code[pc+1])
		c_stmt("@ = IS_ATOM_INT(DoubleToInt(@));\n", {Code[pc+2], Code[pc+1]})
		c_stmt0("else\n")
		c_stmt("@ = 0;\n", Code[pc+2])
	end if
	CDeRefStr("_0")
	target = {0, 1}
	SetBBType(Code[pc+2], TYPE_INTEGER, target, TYPE_OBJECT, 0)

	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 3
end procedure

procedure opIS_AN_ATOM()
	CSaveStr("_0", Code[pc+2], Code[pc+1], 0, 0)
	if TypeIsIn(Code[pc+1], TYPES_IAD) then
		c_stmt("@ = 1;\n", Code[pc+2])
	elsif TypeIs(Code[pc+1], TYPE_SEQUENCE) then
		c_stmt("@ = 0;\n", Code[pc+2])
	else
		c_stmt("@ = IS_ATOM(@);\n", {Code[pc+2], Code[pc+1]})
	end if
	CDeRefStr("_0")
	target = {0, 1}
	SetBBType(Code[pc+2], TYPE_INTEGER, target, TYPE_OBJECT, 0 )
	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 3
end procedure

procedure opIS_A_SEQUENCE()
	CSaveStr("_0", Code[pc+2], Code[pc+1], 0, 0)
	if TypeIsIn(Code[pc+1], TYPES_IAD) then
		c_stmt("@ = 0;\n", Code[pc+2])
	elsif TypeIs(Code[pc+1], TYPE_SEQUENCE) then
		c_stmt("@ = 1;\n", Code[pc+2])
	else
		c_stmt("@ = IS_SEQUENCE(@);\n", {Code[pc+2], Code[pc+1]})
	end if
	CDeRefStr("_0")
	target = {0, 1}
	SetBBType(Code[pc+2], TYPE_INTEGER, target, TYPE_OBJECT, 0)
	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 3
end procedure

procedure opIS_AN_OBJECT()
	CSaveStr("_0", Code[pc+2], Code[pc+1], 0, 0)
	-- check 
	c_stmt("if( NOVALUE == @ ){\n", {Code[pc+1]}, Code[pc+1])
		c_stmt("@ = 0;\n", Code[pc+2])
	c_stmt0("}\n")
	c_stmt0("else{\n")
	if TypeIs(Code[pc+1], TYPE_SEQUENCE) then
		c_stmt("@ = 3;\n", Code[pc+2])
	elsif TypeIs(Code[pc+1], TYPE_INTEGER) then
		c_stmt("@ = 1;\n", Code[pc+2])
	elsif TypeIs(Code[pc+1], TYPE_DOUBLE) then
		c_stmt("if (IS_ATOM_INT(DoubleToInt(@)))\n", Code[pc+1])
		c_stmt("@ = 1;\n", Code[pc+2])
		c_stmt0("else\n")
		c_stmt("@ = 2;\n", Code[pc+2])
	else
		c_stmt("if (IS_ATOM_INT(@))\n", Code[pc+1])
		c_stmt("@ = 1;\n", Code[pc+2])
		c_stmt("else if (IS_ATOM_DBL(@)) {\n", Code[pc+1])
		c_stmt(" if (IS_ATOM_INT(DoubleToInt(@))) {\n", Code[pc+1])
		c_stmt(" @ = 1;\n", Code[pc+2])
		c_stmt0(" } else {\n")
		c_stmt(" @ = 2;\n", Code[pc+2])
		c_stmt("} } else if (IS_SEQUENCE(@))\n", Code[pc+1])
		c_stmt("@ = 3;\n", Code[pc+2])
		c_stmt0("else\n")
		c_stmt("@ = 0;\n", Code[pc+2])
	end if
	c_stmt0("}\n")
	CDeRefStr("_0")
	target = {0, 1}
	SetBBType(Code[pc+2], TYPE_INTEGER, target, TYPE_OBJECT, 0)
	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 3
end procedure

		-- ---------- start of unary ops -----------------
procedure unary_type()
	if TypeIs( Code[pc+2], TYPE_SEQUENCE ) then
		SetBBType(Code[pc+2], TYPE_SEQUENCE, novalue, TYPE_OBJECT, 0 )

	elsif TypeIsIn( Code[pc+2], TYPES_IAD ) then
		SetBBType(Code[pc+2], TYPE_DOUBLE, novalue, TYPE_OBJECT, 0 )

	end if
end procedure

procedure opSQRT()
	CUnaryOp(pc, "e_sqrt", "SQRT")
	unary_type()
	pc += 3
end procedure

procedure opSIN()
	CUnaryOp(pc, "e_sin", "SIN")
	unary_type()
	pc += 3
end procedure

procedure opCOS()
	CUnaryOp(pc, "e_cos", "COS")
	unary_type()
	pc += 3
end procedure

procedure opTAN()
	CUnaryOp(pc, "e_tan", "TAN")
	unary_type()
	pc += 3
end procedure

procedure opARCTAN()
	CUnaryOp(pc, "e_arctan", "ARCTAN")
	unary_type()
	pc += 3
end procedure

procedure opLOG()
	CUnaryOp(pc, "e_log", "LOG")
	unary_type()
	pc += 3
end procedure

procedure opNOT_BITS()
	CUnaryOp(pc, "not_bits", "NOT_BITS")
	pc += 3
end procedure

procedure opFLOOR()
	CUnaryOp(pc, "e_floor", "FLOOR")
	SetBBType(Code[pc+2], TYPE_ATOM, novalue, TYPE_OBJECT, HasDelete( Code[pc+1] ) )
	pc += 3
end procedure

		-- more unary ops - better optimization

procedure opNOT_IFW()
	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt("if (IS_ATOM_INT(@)) {\n", Code[pc+1])
	end if

	if TypeIs(Code[pc+1], TYPE_INTEGER) then
		-- optimize if possible

		if ObjValue(Code[pc+1]) = 0 then
			-- optimize: no jump, continue into the block

		elsif ObjValue(Code[pc+1]) = NOVALUE or
			  forward_branch_into(pc+3, Code[pc+2]-1) then
			if ObjValue(Code[pc+1]) = NOVALUE then -- zero handled above
				c_stmt("if (@ != 0)\n", Code[pc+1])
			end if
			Goto(Code[pc+2])

		else
			pc = Code[pc+2] -- known, non-zero value, skip whole block
			return
		end if

	elsif TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt("if (@ != 0){\n", Code[pc+1])
		dispose_temp( Code[pc+1], DISCARD_TEMP, KEEP_IN_MAP )
		Goto(Code[pc+2])
		c_stmt0("}\n")

	end if

	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt0("}\n")
		c_stmt0("else {\n")
	end if

	if TypeIsNot(Code[pc+1], TYPE_INTEGER) then
		c_stmt("if (DBL_PTR(@)->dbl != 0.0){\n", Code[pc+1])
		dispose_temp( Code[pc+1], DISCARD_TEMP, KEEP_IN_MAP )
		Goto(Code[pc+2])
		c_stmt0("}\n")
	end if

	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt0("}\n")
	end if

	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 3
end procedure

procedure opNOT()
	gencode = "@ = unary_op(NOT, @);\n"
	intcode = "@ = (@ == 0);\n"
	if TypeIsIn(Code[pc+1], TYPES_SO) then
		target_type = GType(Code[pc+1])
	else
		target_type = TYPE_INTEGER
	end if
	pc = unary_optimize(pc, target_type, target_val, intcode, intcode2,
						gencode)
end procedure

procedure opUMINUS()
	gencode = "@ = unary_op(UMINUS, @);\n"
	intcode2= "@1 = - @2;\n"    -- careful about -- occurring
	intcode = "if ((uintptr_t)@2 == (uintptr_t)HIGH_BITS){\n" &
			  "@1 = (object)NewDouble((eudouble) -HIGH_BITS);\n" &
			  "}\nelse{\n" &
			  "@1 = - @2;\n}\n"    -- careful about -- occurring
	if GType(Code[pc+1]) = TYPE_INTEGER then
		if NotInRange(Code[pc+1], MININT) then
			target_type = TYPE_INTEGER
		else
			target_type = TYPE_ATOM
		end if
	else
		target_type = GType(Code[pc+1])
	end if
	pc = unary_optimize(pc, target_type, target_val, intcode, intcode2,
						gencode)
end procedure

procedure opRAND()
	gencode = "@ = unary_op(RAND, @);\n"
	intcode = "@ = good_rand() % ((uint32_t)@) + 1;\n"
	if TypeIs(Code[pc+1], TYPE_INTEGER) then
 		target_type = TYPE_INTEGER
		target = ObjMinMax(Code[pc+1])
		target_val = {1, target[MAX]}
	else
		target_type = GType(Code[pc+1])
		if target_type = TYPE_DOUBLE then
			target_type = TYPE_ATOM
		end if
	end if

	pc = unary_optimize(pc, target_type, target_val, intcode, intcode2,
						gencode)
end procedure

procedure opDIV2()
-- like unary, but pc+=4, Code[pc+2] ignored
	gencode = "@ = binary_op(DIVIDE, @, 2);\n"
	intcode = "if (@2 & 1) {\n" &
			  "@1 = NewDouble((@2 >> 1) + 0.5);\n" &
			  "}\n" &
			  "else\n" &
			  "@1 = @2 >> 1;\n"
	if GType(Code[pc+1]) = TYPE_INTEGER then
		target_type = TYPE_ATOM
	else
		target_type = GType(Code[pc+1])
	end if
	unary_div(pc, target_type, intcode, gencode)

	pc += 4
end procedure

procedure opFLOOR_DIV2()
	gencode = "_1 = binary_op(DIVIDE, @2, 2);\n" &
			  "@1 = unary_op(FLOOR, _1);\n" &
			  "DeRef(_1);\n"
	intcode = "@ = @ >> 1;\n"
	if TypeIsIn(Code[pc+1], TYPES_SO) then
		target_type = GType(Code[pc+1])
	elsif GType(Code[pc+1]) = TYPE_INTEGER then
		target_type = TYPE_INTEGER
	else
		target_type = TYPE_ATOM
	end if

	unary_div(pc, target_type, intcode, gencode)

	pc += 4
end procedure

		------------ start of binary ops ----------

procedure opGREATER_IFW()
	pc = ifw(pc, "LESSEQ", "<=")
end procedure

procedure opNOTEQ_IFW()
	pc = ifw(pc, "EQUALS", "==")
end procedure

procedure opLESSEQ_IFW()
	pc = ifw(pc, "GREATER", ">")
end procedure

procedure opGREATEREQ_IFW()
	pc = ifw(pc, "LESS", "<")
end procedure

procedure opEQUALS_IFW()
	pc = ifw(pc, "NOTEQ", "!=")
end procedure

procedure opLESS_IFW()
	pc = ifw(pc, "GREATEREQ", ">=")
end procedure

-- relops part of if or while with integers condition

procedure opLESS_IFW_I()
	pc = ifwi(pc, ">=")
end procedure

procedure opGREATER_IFW_I()
	pc = ifwi(pc, "<=")
end procedure

procedure opEQUALS_IFW_I()
	pc = ifwi(pc, "!=")
end procedure

procedure opNOTEQ_IFW_I()
	pc = ifwi(pc, "==")
end procedure

procedure opLESSEQ_IFW_I()
	pc = ifwi(pc, ">")
end procedure

procedure opGREATEREQ_IFW_I()
	pc = ifwi(pc, "<")
end procedure

-- other binary ops

procedure opMULTIPLY()
	gencode = "@ = binary_op(MULTIPLY, @, @);\n"
	intcode2= "@1 = @2 * @3;\n"
	-- quick range test - could expand later maybe
	intcode = IntegerMultiply(Code[pc+1], Code[pc+2])
	if TypeIs(Code[pc+1], TYPE_DOUBLE) or
	   TypeIs(Code[pc+2], TYPE_DOUBLE) then
		atom_type = TYPE_DOUBLE
	end if
	dblfn="*"
	pc = binary_op(pc, FALSE, target_val, intcode, intcode2,
				   intcode_extra, gencode, dblfn, atom_type)
end procedure

procedure opPLUS()
-- PLUS / PLUS_I

	gencode = "@ = binary_op(PLUS, @, @);\n"
	intcode2= "@1 = @2 + @3;\n"
	intcode = "@1 = @2 + @3;\n"
	intcode_extra = "if ((object)((uintptr_t)@1 + (uintptr_t)HIGH_BITS) >= 0){\n" &
					"@1 = NewDouble((eudouble)@1);\n}\n"
	if TypeIs(Code[pc+1], TYPE_DOUBLE) or
	   TypeIs(Code[pc+2], TYPE_DOUBLE) then
		atom_type = TYPE_DOUBLE
	end if
	dblfn="+"

	pc = binary_op(pc, FALSE, target_val, intcode, intcode2,
				   intcode_extra, gencode, dblfn, atom_type)
end procedure

procedure opMINUS()
-- MINUS / MINUS_I
	gencode = "@ = binary_op(MINUS, @, @);\n"
	intcode2 ="@1 = @2 - @3;\n"
	intcode = "@1 = @2 - @3;\n"
	intcode_extra = "if ((object)((uintptr_t)@1 +(uintptr_t) HIGH_BITS) >= 0){\n" &
					"@1 = NewDouble((eudouble)@1);\n}\n"
	if TypeIs(Code[pc+1], TYPE_DOUBLE) or
	   TypeIs(Code[pc+2], TYPE_DOUBLE) then
		atom_type = TYPE_DOUBLE
	end if
	dblfn="-"
	pc = binary_op(pc, FALSE, target_val, intcode, intcode2,
				   intcode_extra, gencode, dblfn, atom_type)
end procedure

procedure opOR()
	gencode = "@ = binary_op(OR, @, @);\n"
	intcode = "@ = (@ != 0 || @ != 0);\n"
	atom_type = TYPE_INTEGER
	dblfn="Dor"
	pc = binary_op(pc, TRUE, target_val, intcode, intcode2,
				   intcode_extra, gencode, dblfn, atom_type)
end procedure

procedure opXOR()
	gencode = "@ = binary_op(XOR, @, @);\n"
	intcode = "@ = ((@ != 0) != (@ != 0));\n"
	atom_type = TYPE_INTEGER
	dblfn="Dxor"
	pc = binary_op(pc, TRUE, target_val, intcode, intcode2,
				   intcode_extra, gencode, dblfn, atom_type)
end procedure

procedure opAND()
	gencode = "@ = binary_op(AND, @, @);\n"
	intcode = "@ = (@ != 0 && @ != 0);\n"
	atom_type = TYPE_INTEGER
	dblfn="Dand"
	pc = binary_op(pc, TRUE, target_val, intcode, intcode2,
				   intcode_extra, gencode, dblfn, atom_type)
end procedure

procedure opDIVIDE()
	if TypeIs(Code[pc+2], TYPE_INTEGER) and
	   ObjValue(Code[pc+2]) = 0 then
		intcode = "RTFatal(\"divide by 0\");\n"
		gencode = intcode
	else
		gencode = "@ = binary_op(DIVIDE, @, @);\n"
		intcode = "@1 = (@2 % @3) ? NewDouble((eudouble)@2 / @3) : (@2 / @3);\n"
	end if
	if TypeIs(Code[pc+1], TYPE_DOUBLE) or
	   TypeIs(Code[pc+2], TYPE_DOUBLE) then
		atom_type = TYPE_DOUBLE
	end if
	dblfn="/"
	pc = binary_op(pc, FALSE, target_val, intcode, intcode2,
				   intcode_extra, gencode, dblfn, atom_type)
end procedure

procedure opREMAINDER()
	gencode = "@ = binary_op(REMAINDER, @, @);\n"
	intcode = "@ = (@ % @);\n"
	if TypeIs(Code[pc+2], TYPE_INTEGER) then
		if ObjValue(Code[pc+2]) = 0 then
			intcode = "RTFatal(\"remainder of a number divided by 0\");\n"
			gencode = intcode
		elsif TypeIs(Code[pc+1], TYPE_INTEGER) then
			target_val = ObjMinMax(Code[pc+2])
			target_val[MAX] = max(abs(target_val[MIN]),
											abs(target_val[MAX])) - 1
			target_val[MIN] = -target_val[MAX]
		end if
	end if
	if TypeIs(Code[pc+1], TYPE_DOUBLE) or
	   TypeIs(Code[pc+2], TYPE_DOUBLE) then
		atom_type = TYPE_DOUBLE
	end if
	dblfn="Dremainder"
	pc = binary_op(pc, TRUE, target_val, intcode, intcode2,
				   intcode_extra, gencode, dblfn, atom_type)
end procedure

procedure opFLOOR_DIV()
	integer intresult
	gencode = "_2 = binary_op(DIVIDE, @2, @3);\n" &
			  "@1 = unary_op(FLOOR, _2);\n" &
			  "DeRef(_2);\n"

	-- N.B. floor_div(MININT/-1) is not an integer

	intcode2 = "if (@3 > 0 && @2 >= 0) {\n" &
			   "@1 = @2 / @3;\n" &
			   "}\n" &
			   "else {\n" &
			   "temp_dbl = EUFLOOR((eudouble)@2 / (eudouble)@3);\n" &
			   "@1 = (object)temp_dbl;\n" &
			   "}\n"

	if GType(Code[pc+1]) = TYPE_INTEGER and
	   GType(Code[pc+2]) = TYPE_INTEGER and
	   NotInRange(Code[pc+1], MININT) and
	   NotInRange(Code[pc+2], -1) then
		intcode = intcode2
		intresult = TRUE
	else
		intcode = "if (@3 > 0 && @2 >= 0) {\n" &
				  "@1 = @2 / @3;\n" &
				  "}\n" &
				  "else {\n" &
				  "temp_dbl = EUFLOOR((eudouble)@2 / (eudouble)@3);\n" &
				  "if (@2 != MININT)\n" &
				  "@1 = (object)temp_dbl;\n" &
				  "else\n" &
				  "@1 = NewDouble(temp_dbl);\n" &
				  "}\n"
		intresult = FALSE
	end if
	pc = binary_op(pc, intresult, target_val, intcode, intcode2,
				   intcode_extra, gencode, dblfn, atom_type)
end procedure

procedure opAND_BITS()
	gencode = "@ = binary_op(AND_BITS, @, @);\n"
	intcode = "{uintptr_t tu;\n tu = (uintptr_t)@2 & (uintptr_t)@3;\n @1 = MAKE_UINT(tu);\n}\n"
	dblfn="Dand_bits"
	pc = binary_op(pc, FALSE, target_val, intcode, intcode2,
				   intcode_extra, gencode, dblfn, atom_type)
end procedure

procedure opOR_BITS()
	gencode = "@ = binary_op(OR_BITS, @, @);\n"
	intcode = "{uintptr_t tu;\n tu = (uintptr_t)@2 | (uintptr_t)@3;\n @1 = MAKE_UINT(tu);\n}\n"
	dblfn="Dor_bits"
	pc = binary_op(pc, FALSE, target_val, intcode, intcode2,
				   intcode_extra, gencode, dblfn, atom_type)
end procedure

procedure opXOR_BITS()
	gencode = "@ = binary_op(XOR_BITS, @, @);\n"
	intcode = "{uintptr_t tu;\n tu = (uintptr_t)@2 ^ (uintptr_t)@3;\n @1 = MAKE_UINT(tu);\n}\n"
	dblfn="Dxor_bits"
	pc = binary_op(pc, FALSE, target_val, intcode, intcode2,
				   intcode_extra, gencode, dblfn, atom_type)
end procedure

procedure opPOWER()
	gencode = "@ = binary_op(POWER, @, @);\n"
	intcode = "@ = power(@, @);\n"
	intcode2 = intcode
	if TypeIs(Code[pc+1], TYPE_DOUBLE) or
	   TypeIs(Code[pc+2], TYPE_DOUBLE) then
		atom_type = TYPE_DOUBLE
	end if
	dblfn="Dpower"
	pc = binary_op(pc, FALSE, target_val, intcode, intcode2,
				   intcode_extra, gencode, dblfn, atom_type)
end procedure

procedure opLESS()
	gencode = "@ = binary_op(LESS, @, @);\n"
	intcode = "@ = (@ < @);\n"
	atom_type = TYPE_INTEGER
	if TypeIsNotIn(Code[pc+1], TYPES_SO) and
	   TypeIsNotIn(Code[pc+2], TYPES_SO) then
		target_val = {0, 1}
	end if
	dblfn="<"
	pc = binary_op(pc, TRUE, target_val, intcode, intcode2,
				   intcode_extra, gencode, dblfn, atom_type)
end procedure

procedure opGREATER()
	gencode = "@ = binary_op(GREATER, @, @);\n"
	intcode = "@ = (@ > @);\n"
	atom_type = TYPE_INTEGER
	if TypeIsNotIn(Code[pc+1], TYPES_SO) and
	   TypeIsNotIn(Code[pc+2], TYPES_SO) then
		target_val = {0, 1}
	end if
	dblfn=">"
	pc = binary_op(pc, TRUE, target_val, intcode, intcode2,
				   intcode_extra, gencode, dblfn, atom_type)
end procedure

procedure opEQUALS()
	gencode = "@ = binary_op(EQUALS, @, @);\n"
	intcode = "@ = (@ == @);\n"
	atom_type = TYPE_INTEGER
	if TypeIsNotIn(Code[pc+1], TYPES_SO) and
	   TypeIsNotIn(Code[pc+2], TYPES_SO) then
		target_val = {0, 1}
	end if
	dblfn="=="
	pc = binary_op(pc, TRUE, target_val, intcode, intcode2,
				   intcode_extra, gencode, dblfn, atom_type)
end procedure

procedure opNOTEQ()
	gencode = "@ = binary_op(NOTEQ, @, @);\n"
	intcode = "@ = (@ != @);\n"
	atom_type = TYPE_INTEGER
	if TypeIsNotIn(Code[pc+1], TYPES_SO) and
	   TypeIsNotIn(Code[pc+2], TYPES_SO) then
		target_val = {0, 1}
	end if
	dblfn="!="
	pc = binary_op(pc, TRUE, target_val, intcode, intcode2,
				   intcode_extra, gencode, dblfn, atom_type)
end procedure

procedure opLESSEQ()
	gencode = "@ = binary_op(LESSEQ, @, @);\n"
	intcode = "@ = (@ <= @);\n"
	atom_type = TYPE_INTEGER
	if TypeIsNotIn(Code[pc+1], TYPES_SO) and
	   TypeIsNotIn(Code[pc+2], TYPES_SO) then
		target_val = {0, 1}
	end if
	dblfn="<="
	pc = binary_op(pc, TRUE, target_val, intcode, intcode2,
				   intcode_extra, gencode, dblfn, atom_type)
end procedure

procedure opGREATEREQ()
	gencode = "@ = binary_op(GREATEREQ, @, @);\n"
	intcode = "@ = (@ >= @);\n"
	atom_type = TYPE_INTEGER
	if TypeIsNotIn(Code[pc+1], TYPES_SO) and
	   TypeIsNotIn(Code[pc+2], TYPES_SO) then
		target_val = {0, 1}
	end if
	dblfn = ">="
	pc = binary_op(pc, TRUE, target_val, intcode, intcode2,
				   intcode_extra, gencode, dblfn, atom_type)
end procedure
-- end of binary ops

-- short-circuit ops

procedure opSC1_AND()
-- SC1_AND / SC1_AND_IF
-- no need to store ATOM_0
	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt("if (IS_ATOM_INT(@)) {\n", Code[pc+1])
	end if

	if TypeIsIn(Code[pc+1], TYPES_IAO) then
		c_stmt("if (@ == 0) {\n", Code[pc+1])
		if Code[pc] = SC1_AND then
			CDeRef(Code[pc+2])
			c_stmt("@ = 0;\n", Code[pc+2]) -- hard to suppress
		end if
		Goto(Code[pc+3])
		c_stmt0("}\n")
	end if

	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt0("}\n")
		c_stmt0("else {\n")
	end if

	if TypeIsNot(Code[pc+1], TYPE_INTEGER) then
		c_stmt("if (DBL_PTR(@)->dbl == 0.0) {\n", Code[pc+1])
		if Code[pc] = SC1_AND then
			CDeRef(Code[pc+2])
			c_stmt("@ = 0;\n", Code[pc+2])
		end if
		Goto(Code[pc+3])
		c_stmt0("}\n")
	end if

	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt0("}\n")
	end if

	if TypeIs(Code[pc+1], TYPE_INTEGER) then
		SetBBType(Code[pc+2], TYPE_INTEGER, novalue, TYPE_OBJECT, 0)
	else
		SetBBType(Code[pc+2], TYPE_ATOM, novalue, TYPE_OBJECT, 0)
	end if
	pc += 4
end procedure

procedure opSC1_OR()
-- SC1_OR / SC1_OR_IF
-- no need to store ATOM_1
	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt("if (IS_ATOM_INT(@)) {\n", Code[pc+1])
	end if

	if TypeIsIn(Code[pc+1], TYPES_IAO) then
		c_stmt("if (@ != 0) {\n", Code[pc+1]) -- optimize this???
		if Code[pc] = SC1_OR then
			CDeRef(Code[pc+2])
			c_stmt("@ = 1;\n", Code[pc+2])
		end if
		Goto(Code[pc+3])
		c_stmt0("}\n")
	end if

	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt0("}\n")
		c_stmt0("else {\n")
	end if

	if TypeIsNot(Code[pc+1], TYPE_INTEGER) then
		c_stmt("if (DBL_PTR(@)->dbl != 0.0) {\n", Code[pc+1])
		if Code[pc] = SC1_OR then
			CDeRef(Code[pc+2])
			c_stmt("@ = 1;\n", Code[pc+2])
		end if
		Goto(Code[pc+3])
		c_stmt0("}\n")
	end if

	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt0("}\n")
	end if

	if Code[pc] = SC1_OR then
		if TypeIs(Code[pc+1], TYPE_INTEGER) then
			SetBBType(Code[pc+2], TYPE_INTEGER, novalue, TYPE_OBJECT, 0)
		else
			SetBBType(Code[pc+2], TYPE_ATOM, novalue, TYPE_OBJECT, 0 )
		end if
	end if
	pc += 4
end procedure

procedure opSC2_OR()
-- SC2_OR / SC2_AND
	CDeRef(Code[pc+2])

	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt("if (IS_ATOM_INT(@))\n", Code[pc+1])
	end if

	if TypeIsIn(Code[pc+1], TYPES_IAO) then
		c_stmt("@ = (@ != 0);\n", {Code[pc+2], Code[pc+1]})
	end if

	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt("else\n", Code[pc+1])
	end if

	if TypeIsNot(Code[pc+1], TYPE_INTEGER) then
		c_stmt("@ = DBL_PTR(@)->dbl != 0.0;\n", {Code[pc+2], Code[pc+1]})
	end if

	SetBBType(Code[pc+2], TYPE_INTEGER, novalue, TYPE_OBJECT, 0)
	pc += 3
end procedure

-- for loops

procedure opFOR()
-- generate code for FOR, FOR_I
	sequence range1, range2, inc

	loop_stack &= {{Code[pc+5], FOR, pc+7}} -- loop var, type, Label
	integer is_loop_var = find( SymTab[Code[pc+5]][S_SCOPE] , {SC_LOOP_VAR, SC_GLOOP_VAR})
	c_stmt0("{\n")
		if is_loop_var then
			-- inlined loop vars are regular vars
			c_stmt("object @;\n", Code[pc+5])
		end if

		CRef(Code[pc+3])
		c_stmt("@ = @;\n", {Code[pc+5], Code[pc+3]})

		Label(pc+7)

		inc = ObjMinMax(Code[pc+1])
		if TypeIs(Code[pc+1], TYPE_INTEGER) then
			-- increment is an integer

			if TypeIs(Code[pc+3], TYPE_INTEGER) and
			TypeIs(Code[pc+2], TYPE_INTEGER) then
				-- loop var is an integer
				range1 = ObjMinMax(Code[pc+3])  -- start
				range2 = ObjMinMax(Code[pc+2])  -- limit
				SymTab[Code[pc+5]][S_GTYPE] = TYPE_INTEGER
			else
				range1 = {NOVALUE, NOVALUE}
				if TypeIs(Code[pc+3], TYPE_DOUBLE) then
					SymTab[Code[pc+5]][S_GTYPE] = TYPE_DOUBLE
				else
					SymTab[Code[pc+5]][S_GTYPE] = TYPE_ATOM
				end if
				SymTab[Code[pc+5]][S_OBJ] = NOVALUE
			end if

			if inc[MIN] >= 0 then
				-- going up
				LeftSym = TRUE
				if TypeIs(Code[pc+5], TYPE_INTEGER) and
				TypeIs(Code[pc+2], TYPE_INTEGER) then
					c_stmt("if (@ > @){\n", {Code[pc+5], Code[pc+2]})
				else
					c_stmt("if (binary_op_a(GREATER, @, @)){\n", {Code[pc+5], Code[pc+2]})
				end if
					Goto(Code[pc+6])
				c_stmt0("}\n")
				if range1[MIN] != NOVALUE then
					SymTab[Code[pc+5]][S_OBJ_MIN] = range1[MIN]
					SymTab[Code[pc+5]][S_OBJ_MAX] = max(range1[MAX], range2[MAX])
				end if

			elsif inc[MAX] < 0 then
				-- going down
				LeftSym = TRUE
				if TypeIs(Code[pc+5], TYPE_INTEGER) and
				TypeIs(Code[pc+2], TYPE_INTEGER) then
					c_stmt("if (@ < @){\n", {Code[pc+5], Code[pc+2]})
				else
					c_stmt("if (binary_op_a(LESS, @, @)){\n", {Code[pc+5], Code[pc+2]})
				end if
					Goto(Code[pc+6])
				c_stmt0("}\n")
				if range1[MIN] != NOVALUE then
					SymTab[Code[pc+5]][S_OBJ_MIN] = min(range1[MIN], range2[MIN])
					SymTab[Code[pc+5]][S_OBJ_MAX] = range1[MAX]
				end if

			else
				-- integer, but value could be + or -
				c_stmt("if (@ >= 0) {\n", Code[pc+1])

					LeftSym = TRUE
					if TypeIs(Code[pc+5], TYPE_INTEGER) and
					TypeIs(Code[pc+2], TYPE_INTEGER) then
						c_stmt("if (@ > @){\n", {Code[pc+5], Code[pc+2]})
					else
						c_stmt("if (binary_op_a(GREATER, @, @)){\n",
													{Code[pc+5], Code[pc+2]})
					end if
						Goto(Code[pc+6])
					c_stmt0("}\n")
				c_stmt0("}\n")
				c_stmt0("else {\n")
					LeftSym = TRUE
					if TypeIs(Code[pc+5], TYPE_INTEGER) and
					TypeIs(Code[pc+2], TYPE_INTEGER) then
						c_stmt("if (@ < @) {\n", {Code[pc+5], Code[pc+2]})
					else
						c_stmt("if (binary_op_a(LESS, @, @)){\n",
													{Code[pc+5], Code[pc+2]})
					end if
						Goto(Code[pc+6])
					c_stmt0("}\n")
					if range1[MIN] != NOVALUE then
						SymTab[Code[pc+5]][S_OBJ_MIN] = min(range1[MIN], range2[MIN])
						SymTab[Code[pc+5]][S_OBJ_MAX] = max(range1[MAX], range2[MAX])
					end if
				c_stmt0("}\n")
			end if

		else
			-- increment type is not known to be integer

			c_stmt("if (@ >= 0) {\n", Code[pc+1])
					c_stmt("if (binary_op_a(GREATER, @, @)){\n", {Code[pc+5], Code[pc+2]})
						Goto(Code[pc+6])
					c_stmt0("}\n")
				c_stmt0("}\n")
				c_stmt("else if (IS_ATOM_INT(@)) {\n", Code[pc+1])
					c_stmt("if (binary_op_a(LESS, @, @)){\n", {Code[pc+5], Code[pc+2]})
						Goto(Code[pc+6])
					c_stmt0("}\n")
				c_stmt0("}\n")

				c_stmt0("else {\n")
					c_stmt("if (DBL_PTR(@)->dbl >= 0.0) {\n", Code[pc+1])
						c_stmt("if (binary_op_a(GREATER, @, @)){\n", {Code[pc+5], Code[pc+2]})
							Goto(Code[pc+6])
						c_stmt0("}\n")
					c_stmt0("}\n")
					c_stmt0("else {\n")
						c_stmt("if (binary_op_a(LESS, @, @)){\n", {Code[pc+5], Code[pc+2]})
							Goto(Code[pc+6])
						c_stmt0("}\n")
					c_stmt0("}\n")
				c_stmt0("}\n")

		end if

	pc += 7

	-- Retry label
	RLabel(pc)

end procedure

procedure opENDFOR_GENERAL()
-- ENDFOR_INT_UP1 / ENDFOR_INT_UP / ENDFOR_UP / ENDFOR_INT_DOWN1
-- ENDFOR_INT_DOWN / ENDFOR_DOWN / ENDFOR_GENERAL
	boolean close_brace
	sequence gencode, intcode

	loop_stack = loop_stack[1..$-1]
	if Code[pc-1] != NOP1 then
		Label(pc) -- for continue to work
	end if

	CSaveStr("_0", Code[pc+3], Code[pc+3], Code[pc+4], 0)
	-- always delay the DeRef

	close_brace = FALSE
	gencode = "@ = binary_op_a(PLUS, @, @);\n"

	-- rvalue for CName should be ok - we've initialized loop var
	intcode = "@1 = @2 + @3;\n" &
			  "if ((object)((uintptr_t)@1 +(uintptr_t) HIGH_BITS) >= 0){\n" &
			  "@1 = NewDouble((eudouble)@1);\n}\n"

	if TypeIs(Code[pc+3], TYPE_INTEGER) and
	   TypeIs(Code[pc+4], TYPE_INTEGER) then
		-- uncertain about neither operand and target is integer
		c_stmt("@1 = @2 + @3;\n", {Code[pc+3], Code[pc+3], Code[pc+4]})

	elsif TypeIs(Code[pc+3], TYPE_INTEGER) and
		  TypeIsIn(Code[pc+4], TYPES_AO) then
			-- target and one operand are integers
		c_stmt("if (IS_ATOM_INT(@)) {\n", Code[pc+4])
		c_stmt("@1 = @2 + @3;\n", {Code[pc+3], Code[pc+3], Code[pc+4]})
		c_stmt0("}\n")
		c_stmt0("else {\n")
		close_brace = TRUE

	elsif TypeIs(Code[pc+4], TYPE_INTEGER) and
		  TypeIsIn(Code[pc+3], TYPES_AO) then
		c_stmt("if (IS_ATOM_INT(@)) {\n", Code[pc+3])
		c_stmt(intcode, {Code[pc+3], Code[pc+3], Code[pc+4]})
		c_stmt0("}\n")
		c_stmt0("else {\n")
		close_brace = TRUE
	end if

	if TypeIsIn(Code[pc+3], TYPES_AO) and
	   TypeIsIn(Code[pc+4], TYPES_AO) then
		-- uncertain about both types being TYPE_INTEGER or not
		c_stmt("if (IS_ATOM_INT(@) && IS_ATOM_INT(@)) {\n",
			   {Code[pc+3], Code[pc+4]})
		c_stmt(intcode, {Code[pc+3], Code[pc+3], Code[pc+4]})
		c_stmt0("}\n")
		c_stmt0("else {\n")
		close_brace = TRUE
	end if

	if TypeIsNot(Code[pc+3], TYPE_INTEGER) or
	   TypeIsNot(Code[pc+4], TYPE_INTEGER) then
		c_stmt(gencode, {Code[pc+3], Code[pc+3], Code[pc+4]})
	end if

	if close_brace then
		c_stmt0("}\n")
	end if

	CDeRefStr("_0")

	Goto(Code[pc+1])

	Label(pc+5)
	c_stmt0(";\n")

	CDeRef(Code[pc+3])
	c_stmt0("}\n")

	 -- no SetBB needed here - it's a loop variable
	 -- (and it's in a local block)

	pc += 5

end procedure

procedure opCALL_PROC()
-- CALL_PROC / CALL_FUNC
-- Call by routine id to Euphoria procedure, function or type.
-- Note that dlls and main programs can't share routine ids, so it's
-- OK to compute last_max_params just within dll or within main program.

	if last_routine_id > 0 or Code[pc] = CALL_FUNC then
		-- only generate code if routine_id()
		-- was called somewhere, or it's a call_func - otherwise
		-- return value temp might be used but not declared

		if TypeIs(Code[pc+2], TYPE_SEQUENCE) then
			len = SeqLen(Code[pc+2])
		else
			len = NOVALUE
		end if

		if len != 0 then
			c_stmt("_1 = (object)SEQ_PTR(@);\n", Code[pc+2])
			c_stmt0("_2 = (object)((s1_ptr)_1)->base;\n")
		end if

		c_stmt("_0 = (object)_00[@].addr;\n", Code[pc+1])

		if len = NOVALUE then
			c_stmt0("switch(((s1_ptr)_1)->length) {\n")
		end if

		for i = 0 to last_max_params do
			if len = NOVALUE then
				c_stmt0("case ")
				c_printf("%d:\n", i)
				indent += 4
				-- N.B. have to Ref all the args too
			end if
			if len = NOVALUE or len = i then
				for k = 1 to i do
					c_stmt0( sprintf( "Ref( *(( (intptr_t*)_2) + %d) );\n", k ) )
				end for

				if TWINDOWS and dll_option then
					c_stmt("if (_00[@].convention) {\n", Code[pc+1])
					if Code[pc] = CALL_FUNC then
						c_stmt0("_1 = (*(intptr_t (__stdcall *)())_0)(\n")
						arg_list(i)
						c_stmt0("}\n")
						c_stmt0("else {\n")
						c_stmt0("_1 = (*(intptr_t (*)())_0)(\n")
					else
						c_stmt0("(*(intptr_t (__stdcall *)())_0)(\n")
						arg_list(i)
						c_stmt0("}\n")
						c_stmt0("else {\n")
						c_stmt0("(*(intptr_t (*)())_0)(\n")
					end if
					arg_list(i)
					c_stmt0("}\n")
				else
					if Code[pc] = CALL_FUNC then
						c_stmt0("_1 = (*(intptr_t (*)())_0)(\n")
					else
						c_stmt0("(*(intptr_t (*)())_0)(\n")
					end if
					arg_list(i)
				end if

			end if
			if len = NOVALUE then
				c_stmt0("break;\n")
				indent -= 4
			end if
		end for
		if len = NOVALUE then
			c_stmt0("}\n")
		end if

		NewBB(1, E_ALL_EFFECT, 0) -- Windows call-back to Euphoria routine could occur

		if Code[pc] = CALL_FUNC then
			CDeRef(Code[pc+3])
			c_stmt("@ = _1;\n", Code[pc+3])
			SymTab[Code[pc+3]][S_ONE_REF] = FALSE
			-- hard to ever know the return type here
			SetBBType(Code[pc+3], TYPE_OBJECT, novalue, TYPE_OBJECT, GDelete() )
			create_temp( Code[pc+3], 1 )
		end if
	end if
	dispose_temp( Code[pc+2], DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 3 + (Code[pc] = CALL_FUNC)
end procedure

procedure opCALL_BACK_RETURN()
	pc += 1
	all_done = TRUE
end procedure

procedure opBADRETURNF()
-- shouldn't reach here
	pc += 1
	all_done = TRUE  -- end of a function
end procedure

procedure opRETURNF()
-- generate code for return from function
	symtab_index sym, sub, ret
	sequence x
	object stsub
	integer eltype

	sub = Code[pc+1]
	ret = Code[pc+3]

	if (not is_temp( ret ) and sym_scope( ret ) != SC_PRIVATE)
	or map:get( dead_temp_walking, ret, NEW_REFERENCE ) != NEW_REFERENCE then
		CRef( ret )
	end if

	-- update function return type, and sequence element type
	stsub = SymTab[sub]
	stsub[S_GTYPE_NEW] = or_type(stsub[S_GTYPE_NEW],
									   GType(Code[pc+2]))
	eltype = SeqElem(Code[pc+2])
	if eltype != stsub[S_SEQ_ELEM_NEW] then
		eltype = or_type(stsub[S_SEQ_ELEM_NEW], eltype)
		stsub[S_SEQ_ELEM_NEW] = eltype
	end if

	if GType(ret) = TYPE_INTEGER then
		x = ObjMinMax(ret)
		if stsub[S_OBJ_MIN_NEW] = -NOVALUE then
			stsub[S_OBJ_MIN_NEW] = x[MIN]
			stsub[S_OBJ_MAX_NEW] = x[MAX]

		elsif stsub[S_OBJ_MIN_NEW] != NOVALUE then
			if x[MIN] < stsub[S_OBJ_MIN_NEW] then
				stsub[S_OBJ_MIN_NEW] = x[MIN]
			end if
			if x[MAX] > stsub[S_OBJ_MAX_NEW] then
				stsub[S_OBJ_MAX_NEW] = x[MAX]
			end if
		end if

	elsif GType(ret) = TYPE_SEQUENCE then
		if stsub[S_SEQ_LEN_NEW] = -NOVALUE then
			stsub[S_SEQ_LEN_NEW] = SeqLen(ret)
		elsif stsub[S_SEQ_LEN_NEW] != SeqLen(ret) then
			stsub[S_SEQ_LEN_NEW] = NOVALUE
		end if

	else
		stsub[S_OBJ_MIN_NEW] = NOVALUE
		stsub[S_SEQ_LEN_NEW] = NOVALUE

	end if
	SymTab[sub] = stsub

	-- deref any active for-loop vars
	for i = 1 to length(loop_stack) do
		if loop_stack[i][LOOP_VAR] != 0 then
			-- active for-loop var
			if loop_stack[i][LOOP_VAR] != ret then
				CDeRef(loop_stack[i][LOOP_VAR])
			end if
		end if
	end for

	-- deref the temps and privates
	-- check if we are derefing the return var/temp
	if SymTab[ret][S_MODE] = M_TEMP then
		sym = SymTab[sub][S_TEMPS]
		while sym != 0 do
			if SymTab[sym][S_SCOPE] != DELETED and
			   SymTab[sym][S_TEMP_NAME] = SymTab[ret][S_TEMP_NAME] then
				exit
			end if
			sym = SymTab[sym][S_NEXT]
		end while

	else
		-- non-temps
		sym = SymTab[sub][S_NEXT]
		while sym != 0 and SymTab[sym][S_SCOPE] <= SC_PRIVATE do
			if SymTab[sym][S_SCOPE] != SC_LOOP_VAR and
			   SymTab[sym][S_SCOPE] != SC_GLOOP_VAR then
				if sym = ret then
					exit
				end if
			end if
			sym = SymTab[sym][S_NEXT]
		end while
	end if

	SymTab[ret][S_ONE_REF] = FALSE

	-- DeRef private vars/temps before returning
	symtab_index block = Code[pc+2]
	symtab_index sub_block = SymTab[sub][S_BLOCK]
	while block != sub_block do
		exit_block( block, 0, ret )
		block = SymTab[block][S_BLOCK]
	end while
	exit_block( sub_block, 0, ret )

	sym = SymTab[sub][S_TEMPS]
	while sym != 0 do
		if SymTab[sym][S_SCOPE] != DELETED then
			if SymTab[ret][S_MODE] != M_TEMP or
			   SymTab[sym][S_TEMP_NAME] != SymTab[ret][S_TEMP_NAME] then
				-- temp type can be TYPE_NULL here if temp was not used
				FinalDeRef(sym)
			end if
		end if
		sym = SymTab[sym][S_NEXT]
	end while
	FlushDeRef()

	dispose_all_temps( 0, 0, ret )

	c_stmt0("return ")
	CName(ret)
	c_puts(";\n")

	pc += 4
end procedure

procedure exit_block( symtab_index block, integer no_value = 1, integer except_sym = 0, integer set_bb_type = 1 )
	ifdef DEBUG then
		c_puts(sprintf("\n// Exiting block %s\n", {SymTab[block][S_NAME]}))
	end ifdef

	sym = block
	integer deref = 1

	while sym != 0 with entry do
		if sym != except_sym
		and not find( sym_usage( sym ), {U_UNUSED, U_DELETED}) then

			ifdef DEBUG then
				c_puts(sprintf("\n// block var %s\n", {sym_name(sym)}))
			end ifdef

			if deref then
				CDeRef(sym)
			end if
			if no_value and not except_sym and not TypeIs( sym, T_INTEGER ) then
				c_stmt( "@ = NOVALUE;\n", sym )
			end if

			if set_bb_type then
				-- set the type to an integer to prevent de-referencing
				SetBBType(sym, TYPE_INTEGER, novalue, TYPE_OBJECT, 0)
			end if
		end if
	entry
		sym = SymTab[sym][S_NEXT_IN_BLOCK]
	end while

end procedure

procedure opEXIT_BLOCK()

	exit_block( Code[pc+1] )
	pc += 2
end procedure

procedure opRETURNP()
-- return from procedure
	-- deref any active for-loop vars
	for i = 1 to length(loop_stack) do
		if loop_stack[i][LOOP_VAR] != 0 then
			-- active for-loop var
			CDeRef(loop_stack[i][LOOP_VAR])
		end if
	end for

	-- deref the temps and privates
	sub = Code[pc+1]

	symtab_index block = Code[pc+2]
	symtab_index sub_block = SymTab[sub][S_BLOCK]
	while block != sub_block do
		exit_block( block, 0 )
		block = SymTab[block][S_BLOCK]
	end while
	exit_block( sub_block, 0 )

	sym = SymTab[sub][S_TEMPS]
	while sym != 0 do
		if SymTab[sym][S_SCOPE] != DELETED then
			FinalDeRef(sym)
		end if
		sym = SymTab[sym][S_NEXT]
	end while
	FlushDeRef()
	dispose_all_temps( 0, 0 )
	c_stmt0("return;\n")
	pc += 3
end procedure

procedure opROUTINE_ID()
	CSaveStr("_0", Code[pc+4], Code[pc+2], 0, 0)
	c_stmt("@ = CRoutineId(", Code[pc+4])
	c_printf("%d, ", Code[pc+1])  -- sequence number
	c_printf("%d", Code[pc+3])  -- current file number
	temp_indent = -indent
	c_stmt(", @);\n", Code[pc+2])  -- name
	CDeRefStr("_0")
	target = {-1, 1000000}
	SetBBType(Code[pc+4], TYPE_INTEGER, target, TYPE_OBJECT, 0 )
	pc += 5
end procedure

procedure opAPPEND()
-- APPEND
	integer preserve, t

	CRef(Code[pc+2])
	SymTab[Code[pc+2]][S_ONE_REF] = FALSE
	c_stmt("Append(&@, @, @);\n", {Code[pc+3], Code[pc+1], Code[pc+2]})
	target = {NOVALUE, 0}
	if TypeIs(Code[pc+1], TYPE_SEQUENCE) then
		target[MIN] = SeqLen(Code[pc+1]) + 1
	end if

	t = Code[pc+3]
	if t = Code[pc+1] and SymTab[t][S_MODE] = M_NORMAL then
		-- don't let this operation destroy our
		-- global idea of sequence element type
		preserve = or_type(SymTab[t][S_SEQ_ELEM_NEW], GType(Code[pc+2]))
		SetBBType(t, TYPE_SEQUENCE, target,
				  or_type(SeqElem(Code[pc+1]), GType(Code[pc+2])),
				  HasDelete( t ) or HasDelete( Code[pc+1] )
				  or HasDelete( Code[pc+2] ))
		SymTab[t][S_SEQ_ELEM_NEW] = preserve
	else
		SetBBType(t, TYPE_SEQUENCE, target,
				  or_type(SeqElem(Code[pc+1]), GType(Code[pc+2])),
				  HasDelete( t ) or HasDelete( Code[pc+1] )
				  or HasDelete( Code[pc+2] ))
	end if
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+3], NEW_REFERENCE )
	pc += 4
end procedure

procedure opPREPEND()
-- PREPEND
	integer preserve, t

	CRef(Code[pc+2])
	SymTab[Code[pc+2]][S_ONE_REF] = FALSE
	c_stmt("Prepend(&@, @, @);\n", {Code[pc+3], Code[pc+1], Code[pc+2]})
	target = {NOVALUE, 0}
	if TypeIs(Code[pc+1], TYPE_SEQUENCE) then
		target[MIN] = SeqLen(Code[pc+1]) + 1
	end if

	t = Code[pc+3]
	if t = Code[pc+1] and SymTab[t][S_MODE] = M_NORMAL then
		-- don't let this operation destroy our
		-- global idea of sequence element type
		preserve = or_type(SymTab[t][S_SEQ_ELEM_NEW], GType(Code[pc+2]))
		SetBBType(t, TYPE_SEQUENCE, target,
				  or_type(SeqElem(Code[pc+1]), GType(Code[pc+2])),
				  HasDelete( t ) or HasDelete( Code[pc+1] )
				  or HasDelete( Code[pc+2] ))
		SymTab[t][S_SEQ_ELEM_NEW] = preserve
	else
		SetBBType(t, TYPE_SEQUENCE, target,
				  or_type(SeqElem(Code[pc+1]), GType(Code[pc+2])),
				  HasDelete( t ) or HasDelete( Code[pc+1] )
				  or HasDelete( Code[pc+2] ))
	end if
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+3], NEW_REFERENCE )
	pc += 4
end procedure

procedure opCONCAT()
-- generate code for concatenation
	integer t, p3, preserve
	atom j
	sequence target
	integer ones_an_object = TypeIs(Code[pc+1], TYPE_OBJECT) or
	   TypeIs(Code[pc+2], TYPE_OBJECT)

	if ones_an_object then
		c_stmt("if (IS_SEQUENCE(@) && IS_ATOM(@)) {\n", {Code[pc+1], Code[pc+2]})
	end if

	if TypeIsIn(Code[pc+1], TYPES_SO) and
	   TypeIsNot(Code[pc+2], TYPE_SEQUENCE) then
		CRef(Code[pc+2])
		c_stmt("Append(&@, @, @);\n", {Code[pc+3], Code[pc+1], Code[pc+2]})
	end if

	if ones_an_object then
		c_stmt0("}\n")
		c_stmt("else if (IS_ATOM(@) && IS_SEQUENCE(@)) {\n",
					  {Code[pc+1], Code[pc+2]})
	end if

	if TypeIsIn(Code[pc+2], TYPES_SO) and
	   TypeIsNot(Code[pc+1], TYPE_SEQUENCE) then
		CRef(Code[pc+1])
		c_stmt("Prepend(&@, @, @);\n", {Code[pc+3], Code[pc+2], Code[pc+1]})
	end if

	if ones_an_object then
		c_stmt0("}\n")
		c_stmt0("else {\n")
	end if

	if ones_an_object or
		(TypeIs(Code[pc+1], TYPE_SEQUENCE) and
		 TypeIs(Code[pc+2], TYPE_SEQUENCE)) or
		   (TypeIsNot(Code[pc+1], TYPE_SEQUENCE) and
			TypeIsNot(Code[pc+2], TYPE_SEQUENCE)) then
		c_stmt("Concat((object_ptr)&@, @, @);\n",
					   {Code[pc+3], Code[pc+1], Code[pc+2]})
	end if


	target = {0, 0}
	-- compute length of result
	if TypeIsIn(Code[pc+1], TYPES_AS) and
	   TypeIsIn(Code[pc+2], TYPES_AS) then
		if TypeIs(Code[pc+1], TYPE_ATOM) then
			target[MIN] = 1
		else
			target[MIN] = SeqLen(Code[pc+1])
		end if
		if target[MIN] != NOVALUE then
			if TypeIs(Code[pc+2], TYPE_ATOM) then
				target[MIN] += 1
			else
				j = SeqLen(Code[pc+2])
				if j = NOVALUE then
					target[MIN] = NOVALUE
				else
					target[MIN] += j
				end if
			end if
		end if

	else
		target[MIN] = NOVALUE

	end if

	if TypeIs(Code[pc+1], TYPE_SEQUENCE) then
		j = SeqElem(Code[pc+1])
	else
		j = GType(Code[pc+1])
	end if
	if TypeIs(Code[pc+2], TYPE_SEQUENCE) then
		t = SeqElem(Code[pc+2])
	else
		t = GType(Code[pc+2])
	end if

	p3 = Code[pc+3]
	if p3 = Code[pc+1] and SymTab[p3][S_MODE] = M_NORMAL then
		-- don't let this operation affect our
		-- global idea of sequence element type
		preserve = or_type(SymTab[p3][S_SEQ_ELEM_NEW], t)
		SetBBType(p3, TYPE_SEQUENCE, target, or_type(j, t),
			HasDelete( p3 ) or HasDelete( Code[pc+1] )
				  or HasDelete( Code[pc+2] ))
		SymTab[p3][S_SEQ_ELEM_NEW] = preserve

	elsif p3 = Code[pc+2] and SymTab[p3][S_MODE] = M_NORMAL then
		-- don't let this operation affect our
		-- global idea of sequence element type
		preserve = or_type(SymTab[p3][S_SEQ_ELEM_NEW], j)
		SetBBType(p3, TYPE_SEQUENCE, target, or_type(j, t),
			HasDelete( p3 ) or HasDelete( Code[pc+1] )
				  or HasDelete( Code[pc+2] ))
		SymTab[p3][S_SEQ_ELEM_NEW] = preserve

	else
		SetBBType(p3, TYPE_SEQUENCE, target, or_type(j, t),
			HasDelete( p3 ) or HasDelete( Code[pc+1] )
				  or HasDelete( Code[pc+2] ))

	end if
	if ones_an_object or
		(TypeIs(Code[pc+1], TYPE_SEQUENCE) and
		 TypeIs(Code[pc+2], TYPE_SEQUENCE)) or
		   (TypeIsNot(Code[pc+1], TYPE_SEQUENCE) and
			TypeIsNot(Code[pc+2], TYPE_SEQUENCE)) then
		dispose_temp( Code[pc+1], DISCARD_TEMP, KEEP_IN_MAP )
	end if

	if ones_an_object then
		c_stmt0("}\n")
	end if

	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+3], NEW_REFERENCE )

	pc += 4
end procedure

procedure splins()
-- writes the portion common to splice() and insert()
	c_stmt0("{\n")
	c_stmt0("s1_ptr assign_space;\n")
	--c_stmt0("_2 = (object_ptr)pc[3];\n")
	--c_stmt("_2 = (object_ptr)@;\n",{Code[pc+3]})
	if not TypeIsNot(Code[pc+2],TYPE_ATOM) then
		c_stmt("if (IS_SEQUENCE(@))\n",{Code[pc+3]})
		c_stmt0("RTFatal(\"Third argument to splice/insert() must be an atom\");\n")
	end if

	if TypeIs( Code[pc+3], TYPE_INTEGER ) then
		c_stmt("insert_pos = @;\n", Code[pc+3] )
	else
		c_stmt("insert_pos = IS_ATOM_INT(@) ? @ : DBL_PTR(@)->dbl;\n",{Code[pc+3],Code[pc+3],Code[pc+3]})
	end if

-- 	CSaveStr("_0", Code[pc+4], Code[pc+1], Code[pc+2], 0)
end procedure

procedure opSPLICE()
	splins()
	integer
		target_pc = Code[pc+4],
		source_pc = Code[pc+1],
		splice_pc = Code[pc+2],
		splicing_sequence = TypeIs( splice_pc, TYPE_SEQUENCE )
	
	c_stmt0( "if (insert_pos <= 0) {\n" )
		if not splicing_sequence then
			c_stmt("if (IS_SEQUENCE(@)) {\n",{splice_pc})
		end if
		c_stmt( "Concat(&@,@,@);\n",{target_pc, splice_pc, source_pc} )
		if not splicing_sequence then
			c_stmt0("}\n")
			c_stmt0("else{\n")
				c_stmt( "Prepend(&@,@,@);\n", {target_pc, source_pc, splice_pc})
			c_stmt0("}\n")
		end if
	c_stmt0( "}\n" )
	c_stmt( "else if (insert_pos > SEQ_PTR(@)->length){\n", source_pc )
		if not splicing_sequence then
			c_stmt("if (IS_SEQUENCE(@)) {\n",{splice_pc})
		end if
		c_stmt( "Concat(&@,@,@);\n", {target_pc, source_pc, splice_pc} )
		if not splicing_sequence then
			c_stmt0("}\n")
			c_stmt0("else{\n")
				c_stmt( "Append(&@,@,@);\n", {target_pc, source_pc, splice_pc})
			c_stmt0("}\n")
		end if
	c_stmt0( "}\n")
	c_stmt("else if (IS_SEQUENCE(@)) {\n",{splice_pc})
		c_stmt( "if( @ != @ || SEQ_PTR( @ )->ref != 1 ){\n", {target_pc, source_pc, source_pc} )
			--  not in place: need to deref the target and ref the orig seq
			c_stmt( "DeRef( @ );\n", target_pc )
			-- ensures that Add_internal_space will make a copy
			c_stmt( "RefDS( @ );\n", source_pc )
		c_stmt0( "}\n" )
		c_stmt("assign_space = Add_internal_space( @, insert_pos,((s1_ptr)SEQ_PTR(@))->length);\n", {source_pc, splice_pc} )
		c_stmt0("assign_slice_seq = &assign_space;\n")
		c_stmt("assign_space = Copy_elements( insert_pos, SEQ_PTR(@), @ == @ );\n", {splice_pc, source_pc, target_pc})
		c_stmt("@ = MAKE_SEQ( assign_space );\n",{target_pc})
	c_stmt0("}\n")
	c_stmt0( "else {\n" )
		c_stmt( "if( @ != @ && SEQ_PTR( @ )->ref != 1 ){\n", {target_pc, source_pc, source_pc})
			c_stmt("@ = Insert( @, @, insert_pos);\n", {target_pc, source_pc, splice_pc})
		c_stmt0("}\n")
		c_stmt0("else {\n")
			c_stmt("DeRef( @ );\n", target_pc )
			c_stmt("RefDS( @ );\n", source_pc )
			c_stmt("@ = Insert( @, @, insert_pos);\n", {target_pc, source_pc, splice_pc})
		c_stmt0("}\n")
	c_stmt0("}\n")
	
	-- splins() starts a block that we need to close:
	c_stmt0("}\n")
	
	if splicing_sequence then
		t = or_type(SeqElem( source_pc ),SeqElem( splice_pc ) )
	elsif TypeIs(splice_pc, TYPE_ATOM) then
		t = or_type(SeqElem( source_pc ),GType( splice_pc ))
	else
		t = TYPE_OBJECT
	end if
	SetBBType( target_pc, TYPE_SEQUENCE, novalue, t,
		HasDelete( target_pc ) or HasDelete( splice_pc )
		or HasDelete( Code[pc+3] ) )
	dispose_temps( pc+1, 3, DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( target_pc, NEW_REFERENCE )
	pc += 5
end procedure

procedure opINSERT()
	splins() -- _0 = obj_ptr
	c_stmt0( "if (insert_pos <= 0){\n" )
	c_stmt( "Prepend(&@,@,@);\n", {Code[pc+4],Code[pc+1],Code[pc+2]})
	c_stmt0( "}\n" )

	if TypeIs( Code[pc+2], TYPE_SEQUENCE ) or TypeIs( Code[pc+2], TYPE_ATOM ) then
		c_stmt("else if (insert_pos > SEQ_PTR(@)->length) {\n",{Code[pc+1]})
		c_stmt("RefDS( @ );\n", { Code[pc+2] } )
		c_stmt("Append(&@,@,@);\n",{ Code[pc+4], Code[pc+1], Code[pc+2] })
		c_stmt0("}\n")
		c_stmt0("else {\n" )
		c_stmt("RefDS( @ );\n", { Code[pc+2] } )
		c_stmt("RefDS( @ );\n", { Code[pc+1] } )
		c_stmt("@ = Insert(@,@,insert_pos);\n",{Code[pc+4],Code[pc+1],Code[pc+2]})
		c_stmt0("}\n")
	elsif TypeIs( Code[pc+2], TYPE_INTEGER ) then
		c_stmt("else if (insert_pos > SEQ_PTR(@)->length){\n", Code[pc+1] )
		c_stmt("Append(&@,@,@);\n", { Code[pc+4], Code[pc+1], Code[pc+2] } )
		c_stmt0( "}\n" )
		c_stmt0( "else {\n" )
		c_stmt("RefDS( @ );\n", Code[pc+1] )
		c_stmt("@ = Insert(@,@,insert_pos);\n",{Code[pc+4],Code[pc+1],Code[pc+2]})
		c_stmt0( "}\n" )
	else
		c_stmt("else if (insert_pos > SEQ_PTR(@)->length) {\n",{Code[pc+1]})
		c_stmt("Ref( @ );\n", { Code[pc+2] } )
		c_stmt("Append(&@,@,@);\n",{ Code[pc+4], Code[pc+1], Code[pc+2] })
		c_stmt0("}\n")
		c_stmt0("else {\n" )
		c_stmt("Ref( @ );\n", { Code[pc+2] } )
		c_stmt("RefDS( @ );\n", Code[pc+1] )
		c_stmt("@ = Insert(@,@,insert_pos);\n",{Code[pc+4],Code[pc+1],Code[pc+2]})
		c_stmt0("}\n")
	end if

	c_stmt0("}\n")
	SetBBType(Code[pc+4], TYPE_SEQUENCE, novalue, or_type(SeqElem(Code[pc+1]),GType(Code[pc+2])),
		HasDelete( Code[pc+1] ) or HasDelete( Code[pc+2] ) or HasDelete( Code[pc+4] ))
	dispose_temps( pc+1, 3, DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+4], NEW_REFERENCE )
	pc += 5
end procedure

procedure opHEAD()
	--CSaveStr("_0", Code[pc+3], Code[pc+1], Code[pc+2], 0)
	c_stmt0("{\n")
	c_stmt("int len = SEQ_PTR(@)->length;\n",{Code[pc+1]})
	c_stmt("int size = (IS_ATOM_INT(@)) ? @ : (object)(DBL_PTR(@)->dbl);\n",repeat(Code[pc+2],3))
	c_stmt("if (size <= 0) @ = MAKE_SEQ(NewS1(0));\n", {Code[pc+3]})
	c_stmt0("else if (len <= size) {\n")
	c_stmt("RefDS(@);\n", {Code[pc+1]})
	c_stmt("DeRef(@);\n", {Code[pc+3]})
	c_stmt("@ = @;\n",{Code[pc+3], Code[pc+1]})
	c_stmt0("}\n")
	c_stmt("else Head(SEQ_PTR(@),size+1,&@);\n",{Code[pc+1], Code[pc+3]})
	c_stmt0("}\n")
	SetBBType(Code[pc+3], TYPE_SEQUENCE, novalue, SeqElem(Code[pc+1]),
		HasDelete( Code[pc+1] ) )
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+3], NEW_REFERENCE )
	pc += 4
end procedure

procedure opTAIL()
	c_stmt0("{\n")
	c_stmt("int len = SEQ_PTR(@)->length;\n",{Code[pc+1]})
	c_stmt("int size = (IS_ATOM_INT(@)) ? @ : (object)(DBL_PTR(@)->dbl);\n",repeat(Code[pc+2],3))
	c_stmt0("if (size <= 0) {\n")
	c_stmt("DeRef(@);\n", {Code[pc+3]})
	c_stmt("@ = MAKE_SEQ(NewS1(0));\n", {Code[pc+3]})
	c_stmt0("}\n")
	c_stmt0("else if (len <= size) {\n")
	c_stmt("RefDS(@);\n", {Code[pc+1]})
	c_stmt("DeRef(@);\n", {Code[pc+3]})
	c_stmt("@ = @;\n",{Code[pc+3], Code[pc+1]})
	c_stmt0("}\n")
	c_stmt("else Tail(SEQ_PTR(@), len-size+1, &@);\n",{Code[pc+1], Code[pc+3]})
	c_stmt0("}\n")
	SetBBType(Code[pc+3], TYPE_SEQUENCE, novalue, SeqElem(Code[pc+1]),
		HasDelete(Code[pc+1]) )
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+3], NEW_REFERENCE )
	pc += 4
end procedure

procedure opREMOVE()
	c_stmt0("{\n")
	c_stmt("s1_ptr assign_space = SEQ_PTR(@);\n", {Code[pc+1]})
	c_stmt0("int len = assign_space->length;\n")
	c_stmt("int start = (IS_ATOM_INT(@)) ? @ : (object)(DBL_PTR(@)->dbl);\n",repeat(Code[pc+2],3))
	c_stmt("int stop = (IS_ATOM_INT(@)) ? @ : (object)(DBL_PTR(@)->dbl);\n",repeat(Code[pc+3],3))
	c_stmt0("if (stop > len){\n")
		c_stmt0("stop = len;\n")
	c_stmt0("}\n")
	c_stmt0("if (start > len || start > stop || stop<0) {\n")
	if Code[pc+1] != Code[pc+4] then
		-- only do this if it's a different target...
		c_stmt("RefDS(@);\n", {Code[pc+1]})
		c_stmt("DeRef(@);\n", {Code[pc+4]})
		c_stmt("@ = @;\n",{Code[pc+4], Code[pc+1]})
	end if
	c_stmt0("}\n")
	c_stmt0("else if (start < 2) {\n")
	c_stmt0("if (stop >= len) {\n")
	-- use Head() here, which might result in an in-place modification
	c_stmt("Head( SEQ_PTR(@), start, &@ );\n", { Code[pc+1], Code[pc+4] })
	c_stmt0("}\n")
	c_stmt("else Tail(SEQ_PTR(@), stop+1, &@);\n",{Code[pc+1], Code[pc+4]})
	c_stmt0("}\n")
	c_stmt0("else if (stop >= len){\n")
		c_stmt("Head(SEQ_PTR(@), start, &@);\n",{Code[pc+1], Code[pc+4]})
	c_stmt0("}\n")
	c_stmt0("else {\n")
	c_stmt0("assign_slice_seq = &assign_space;\n")
	if Code[pc+1] = Code[pc+4] then
		c_stmt("@ = Remove_elements(start, stop, (SEQ_PTR(@)->ref == 1));\n", repeat( Code[pc+4], 2 ))
	else
		c_stmt0("_1 = Remove_elements(start, stop, 0);\n")
		c_stmt("DeRef(@);\n", Code[pc+4])
		c_stmt("@ = _1;\n", Code[pc+4])
	end if

	c_stmt0("}\n")
	c_stmt0("}\n")
	SetBBType(Code[pc+4], TYPE_SEQUENCE, novalue, SeqElem(Code[pc+1]),
		HasDelete(Code[pc+1]))
	dispose_temps( pc+1, 3, DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+4], NEW_REFERENCE )
	pc += 5
end procedure

procedure opREPLACE()
-- Uses the same replace code as the interpreter.  This is unoptimized,
-- and could be greatly improved.

-- 	symtab_index
-- 		copy_to   = Code[pc+1],
-- 		copy_from = Code[pc+2],
-- 		start     = Code[pc+3],
-- 		stop      = Code[pc+4],
-- 		target    = Code[pc+5]

	c_stmt0("{\n")
		for i = 1 to 4 do
			c_stmt(sprintf("intptr_t p%d = @;\n", i ), Code[pc+i])
		end for
		c_stmt0("struct replace_block replace_params;\n")
		c_stmt0( "replace_params.copy_to   = &p1;\n" )
		c_stmt0( "replace_params.copy_from = &p2;\n" )
		c_stmt0( "replace_params.start     = &p3;\n" )
		c_stmt0( "replace_params.stop      = &p4;\n" )
		c_stmt(  "replace_params.target    = &@;\n", Code[pc+5] )
		c_stmt0( "Replace( &replace_params );\n")

		target[MIN] = SeqLen(Code[pc+1])
		SetBBType(Code[pc+5], TYPE_SEQUENCE, {-1,-1}, or_type( SeqElem(Code[pc+1]), SeqElem(Code[pc+2])),
			HasDelete( Code[pc+1] ) or HasDelete( Code[pc+2] ) )

	c_stmt0("}\n")
	dispose_temps( pc+1, 4, DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+5], NEW_REFERENCE )
	pc += 6
end procedure


procedure opCONCAT_N()
-- concatenate 3 or more items
	n = Code[pc+1]
	c_stmt0("{\n")
	c_stmt0("object concat_list[")
	c_printf("%d];\n\n", n)

	t = TYPE_NULL
	integer has_delete = 0
	for i = 0 to n-1 do
		c_stmt0("concat_list[")
		c_printf("%d] = ", i)
		CName(Code[pc+2+i])
		has_delete = has_delete or HasDelete( Code[pc+2+i] )
		c_puts(";\n")
		if TypeIs(Code[pc+2+i], TYPE_SEQUENCE) then
			t = or_type(t, SeqElem(Code[pc+2+i]))
		else
			t = or_type(t, GType(Code[pc+2+i]))
		end if
	end for
	c_stmt("Concat_N((object_ptr)&@, concat_list", Code[pc+n+2])
	c_printf(", %d);\n", n)
	c_stmt0("}\n")
	SetBBType(Code[pc+n+2], TYPE_SEQUENCE, novalue, t, has_delete)
	dispose_temps( pc+2, n, DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+n+2], NEW_REFERENCE )
	pc += n+3
end procedure

procedure opREPEAT()
	CSaveStr("_0", Code[pc+3], Code[pc+1], Code[pc+2], 0)
	c_stmt("@ = Repeat(@, @);\n", {Code[pc+3], Code[pc+1], Code[pc+2]})
	SymTab[Code[pc+1]][S_ONE_REF] = FALSE
	CDeRefStr("_0")
	if TypeIs(Code[pc+2], TYPE_INTEGER) then
		target[MIN] = ObjValue(Code[pc+2])
		SetBBType(Code[pc+3], TYPE_SEQUENCE, target, GType(Code[pc+1]), 0)
	else
		SetBBType(Code[pc+3], TYPE_SEQUENCE, novalue, GType(Code[pc+1]),
			HasDelete( Code[pc+1] ) )
	end if
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+3], NEW_REFERENCE )

	pc += 4
end procedure

procedure opDATE()
	CDeRef(Code[pc+1])  -- Code[pc+1] not used in next expression
	c_stmt("@ = Date();\n", Code[pc+1])
	target[MIN] = 8
	SetBBType(Code[pc+1], TYPE_SEQUENCE, target, TYPE_INTEGER, 0)
	create_temp( Code[pc+1], 1 )
	pc += 2
end procedure

procedure opTIME()
	CDeRef(Code[pc+1]) -- Code[pc+1] not used in next expression
	c_stmt("@ = NewDouble(current_time());\n", Code[pc+1])
	SetBBType(Code[pc+1], TYPE_DOUBLE, novalue, TYPE_OBJECT, 0)
	create_temp( Code[pc+1], 1 )
	pc += 2
end procedure

procedure opSPACE_USED() -- #ifdef EXTRA_STATS or HEAP_CHECK
	CSaveStr("_0", Code[pc+1], 0, 0, 0)
	c_stmt("@ = bytes_allocated;\n", Code[pc+1])
	CDeRefStr("_0")
	SetBBType(Code[pc+1], TYPE_INTEGER, novalue, TYPE_OBJECT, 0)
	pc += 2
end procedure

procedure opPOSITION()
	c_stmt("Position(@, @);\n", {Code[pc+1], Code[pc+2]})
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 3
end procedure

procedure opEQUAL()
	CSaveStr("_0", Code[pc+3], Code[pc+1], Code[pc+2], 0)
	c_stmt("if (@ == @)\n", {Code[pc+1], Code[pc+2]})
	c_stmt("@ = 1;\n", Code[pc+3])
	c_stmt("else if (IS_ATOM_INT(@) && IS_ATOM_INT(@))\n",
						 {Code[pc+1], Code[pc+2]})
	c_stmt("@ = 0;\n", Code[pc+3])
	c_stmt0("else\n")
	c_stmt("@ = (compare(@, @) == 0);\n", {Code[pc+3], Code[pc+1], Code[pc+2]})
	CDeRefStr("_0")
	target = {0, 1}
	SetBBType(Code[pc+3], TYPE_INTEGER, target, TYPE_OBJECT, 0)
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 4
end procedure

procedure opHASH()
	CSaveStr("_0", Code[pc+3], Code[pc+1], Code[pc+2], 0)
	c_stmt("@ = calc_hash(@, @);\n",
		   {Code[pc+3], Code[pc+1], Code[pc+2]})
	CDeRefStr("_0")
	target = {0, MAXLEN}
	SetBBType(Code[pc+3], TYPE_ATOM, target, TYPE_OBJECT, 0)
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+3], NEW_REFERENCE )
	pc += 4
end procedure

procedure opCOMPARE()
	-- OPTIMIZE THIS SOME MORE - IMPORTANT FOR SORTING
	CSaveStr("_0", Code[pc+3], Code[pc+1], Code[pc+2], 0)
	c_stmt("if (IS_ATOM_INT(@) && IS_ATOM_INT(@)){\n", {Code[pc+1], Code[pc+2]})
		c_stmt("@ = (@ < @) ? -1 : ", {Code[pc+3], Code[pc+1], Code[pc+2]})
		temp_indent = -indent
		c_stmt("(@ > @);\n", {Code[pc+1], Code[pc+2]})
	c_stmt0("}\n")
	c_stmt0("else{\n")
		c_stmt("@ = compare(@, @);\n", {Code[pc+3], Code[pc+1], Code[pc+2]})
		CDeRefStr("_0")
	c_stmt0("}\n")
	target = {-1, 1}
	SetBBType(Code[pc+3], TYPE_INTEGER, target, TYPE_OBJECT, 0)
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )

	pc += 4
end procedure

procedure opFIND()
	CSaveStr("_0", Code[pc+3], Code[pc+1], Code[pc+2], 0)
	c_stmt("@ = find(@, @);\n",
		   {Code[pc+3], Code[pc+1], Code[pc+2]})
	CDeRefStr("_0")
	target = {0, MAXLEN}
	SetBBType(Code[pc+3], TYPE_INTEGER, target, TYPE_OBJECT, 0)
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 4
end procedure

procedure opFIND_FROM() -- extra 3rd atom arg
	CSaveStr("_0", Code[pc+4], Code[pc+1], Code[pc+2], Code[pc+3])
	c_stmt("@ = find_from(@, @, @);\n",
		   {Code[pc+4], Code[pc+1], Code[pc+2], Code[pc+3]})
	CDeRefStr("_0")
	target = {0, MAXLEN}
	SetBBType(Code[pc+4], TYPE_INTEGER, target, TYPE_OBJECT, 0)
	dispose_temps( pc+1, 3, DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 5
end procedure

procedure opMATCH()
	CSaveStr("_0", Code[pc+3], Code[pc+1], Code[pc+2], 0)
	c_stmt("@ = e_match(@, @);\n",
		   {Code[pc+3], Code[pc+1], Code[pc+2]})
	CDeRefStr("_0")
	target = {0, MAXLEN}
	SetBBType(Code[pc+3], TYPE_INTEGER, target, TYPE_OBJECT, 0)
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 4
end procedure

procedure opMATCH_FROM()
	CSaveStr("_0", Code[pc+4], Code[pc+1], Code[pc+2], Code[pc+3])
	c_stmt("@ = e_match_from(@, @, @);\n",
		   {Code[pc+4], Code[pc+1], Code[pc+2], Code[pc+3]})
	CDeRefStr("_0")
	target = {0, MAXLEN}
	SetBBType(Code[pc+4], TYPE_INTEGER, target, TYPE_OBJECT, 0)
	dispose_temps( pc+1, 3, DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 5
end procedure

procedure opPEEK_STRING()
	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt("if (IS_ATOM_INT(@)) {\n", Code[pc+1])
	end if

	if TypeIsIn(Code[pc+1], TYPES_IAO) then
		if Code[pc] = PEEK then
			seg_peek1(Code[pc+2], Code[pc+1], 0)
		elsif Code[pc] = PEEKS then
			seg_peek1(Code[pc+2], Code[pc+1], 0)
		elsif find( Code[pc], {PEEK4U, PEEK4S}) then

			seg_peek4(Code[pc+2], Code[pc+1], 0)

			-- FIX: in first BB we might assume TYPE_INTEGER, value 0
			-- so CName will output a 0 instead of the var's name
			SetBBType(Code[pc+2], GType(Code[pc+2]), novalue, TYPE_OBJECT, 0)

			if Code[pc] = PEEK4S then
				c_stmt("if (@ < MININT || @ > MAXINT)\n",
							  {Code[pc+2], Code[pc+2]})
				c_stmt("@ = NewDouble((eudouble)(object)@);\n",
							  {Code[pc+2], Code[pc+2]})

			elsif Code[pc] = PEEK4U then
				c_stmt("if ((uintptr_t)@ > (uintptr_t)MAXINT)\n",
							  Code[pc+2])
				c_stmt("@ = NewDouble((eudouble)(uintptr_t)@);\n",
							  {Code[pc+2], Code[pc+2]})

			end if
		elsif find( Code[pc], {PEEK2U, PEEK2S}) then
			seg_peek2(Code[pc+2], Code[pc+1], 0)
		else
			-- peek_string

		end if
	end if

	if TypeIs(Code[pc+1], TYPE_ATOM) then
		c_stmt0("}\n")
		c_stmt("else {\n", Code[pc+1])

	elsif TypeIs(Code[pc+1], TYPE_OBJECT) then
		c_stmt0("}\n")
		c_stmt("else if (IS_ATOM(@)) {\n", Code[pc+1])
	end if

	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+2], NEW_REFERENCE )
end procedure

procedure opPEEK()
-- PEEK / PEEKS / PEEK2S / PEEK2U / PEEK4U / PEEK4S / PEEK8U / PEEK8S / PEEK_POINTER
	integer
		op         = Code[pc],
		arg        = Code[pc+1], -- either ptr or {ptr,length}
		target_sym = Code[pc+2]
	
	CSaveStr("_0", target_sym, arg, 0, 0)
	
	if op = PEEK8U or op = PEEK8S then
		c_stmt0("{\n")
		c_stmt0("int64_t peek8_longlong;\n")
	end if
	if TypeIsIn( arg, TYPES_AO) then
		c_stmt("if (IS_ATOM_INT(@)) {\n", arg)
	end if

	if TypeIsIn(arg, TYPES_IAO) then
		switch op do
			case PEEK then            seg_peek1( target_sym, arg, 0)
			case PEEKS then           seg_peek1( target_sym, arg, 0)
			case PEEK4U, PEEK4S then  seg_peek4( target_sym, arg, 0)
			case PEEK8U, PEEK8S then  seg_peek8(target_sym, arg, 0, op)
			case PEEK_POINTER then    seg_peek_pointer( target_sym, arg, 0 )
			case PEEK2U, PEEK2S then  seg_peek2( target_sym, arg, 0)
			case else
				-- peek_string
				seg_peek_string( target_sym, arg, 0 )
		end switch
	end if

	if TypeIs( arg, TYPE_ATOM) then
		c_stmt0("}\n")
		c_stmt("else {\n", Code[pc+1])

	elsif TypeIs( arg, TYPE_OBJECT) then
		c_stmt0("}\n")
		c_stmt("else if (IS_ATOM(@)) {\n", arg)
	end if

	if TypeIsNotIn( arg, TYPES_IS) then
		switch op do
			case PEEK, PEEKS then      seg_peek1( target_sym, arg, 1)
			case PEEK2U, PEEK2S then   seg_peek2( target_sym, arg, 1)
			case PEEK4U, PEEK4S then   seg_peek4(target_sym, arg, 1)
			case PEEK8U, PEEK8S then   seg_peek8( target_sym, arg, 1, op )
			case PEEK_POINTER then    seg_peek_pointer( target_sym, arg, 1 )
			case else
				-- peek_string
				seg_peek_string( target_sym, arg, 1 )
		end switch
		
	end if

	if TypeIsIn( arg, TYPES_AO) then
		c_stmt0("}\n")
	end if

	if TypeIs( arg, TYPE_OBJECT) then
		c_stmt0("else {\n")
	end if

	if TypeIsIn( arg, TYPES_SO) then
		-- sequence {start, length} */
		c_stmt("_1 = (object)SEQ_PTR(@);\n", arg)
		switch op do
			case PEEK, PEEKS  then
				c_stmt0("peek_addr = (uint8_t *)get_pos_int(\"peek\", *(((s1_ptr)_1)->base+1));\n")
			case PEEK2S, PEEK2U then
				c_stmt0("peek2_addr = (uint16_t *)get_pos_int(\"peek2s/peek2u\", *(((s1_ptr)_1)->base+1));\n")
			case PEEK4S, PEEK4U then
				c_stmt0("peek4_addr = (uint32_t *)get_pos_int(\"peek4s/peek4u\", *(((s1_ptr)_1)->base+1));\n")
			case PEEK8S, PEEK8U then
				c_stmt0("peek8_addr = (uint64_t *)get_pos_int(\"peek8s/peek8u\", *(((s1_ptr)_1)->base+1));\n")
			case PEEK_POINTER then
				c_stmt0("peekptr_addr = (uintptr_t *)get_pos_int(\"peek_pointer/peek_pointer\", *(((s1_ptr)_1)->base+1));\n")
		end switch
		c_stmt0("_2 = get_pos_int(\"peek\", *(((s1_ptr)_1)->base+2));\n")
		c_stmt("pokeptr_addr = (uintptr_t *)NewS1(_2);\n", Code[pc+2])
		c_stmt("@ = MAKE_SEQ(pokeptr_addr);\n", Code[pc+2])
		c_stmt0("pokeptr_addr = (uintptr_t *)((s1_ptr)pokeptr_addr)->base;\n")

		c_stmt0("while (--_2 >= 0) {\n")  -- FAST WHILE
		c_stmt0("pokeptr_addr++;\n")
		switch op do
			case PEEKS then
				c_stmt0("*pokeptr_addr = (object)(int8_t)*peek_addr++;\n")
			case PEEK then
				c_stmt0("*pokeptr_addr = (object)*peek_addr++;\n")
				
			case PEEK2S then
				c_stmt0("*pokeptr_addr = (object)(int16_t)*peek2_addr++;\n")
			case PEEK2U then
				c_stmt0("*pokeptr_addr = (object)*peek2_addr++;\n")
				
			case PEEK8S then
				c_stmt0("peek8_longlong = *peek8_addr++;\n")
				c_stmt0("if (peek8_longlong < (int64_t) MININT || peek8_longlong > (int64_t) MAXINT){\n")
					c_stmt0("_1 = NewDouble((eudouble)peek8_longlong);\n")
				c_stmt0("}\n")
				c_stmt0("else{\n")
					c_stmt0("_1 = (object)(int64_t) peek8_longlong;\n" )
				c_stmt0("}\n")
				c_stmt0("*pokeptr_addr = _1;\n")
				
			case PEEK8U then
				c_stmt0("peek8_longlong = *peek8_addr++;\n")
				c_stmt0("if ((uint64_t)peek8_longlong > (uint64_t)MAXINT){\n")
					c_stmt0("_1 = NewDouble((eudouble) (uint64_t) peek8_longlong);\n")
				c_stmt0("}\n")
				c_stmt0("else{\n")
					c_stmt0("_1 = (object)peek8_longlong;\n" )
				c_stmt0("}\n")
				c_stmt0("*pokeptr_addr = _1;\n")
				
			case PEEK_POINTER then
				c_stmt0("_1 = (object)*peekptr_addr++;\n")
				c_stmt0("if ((uintptr_t)_1 > (uintptr_t)MAXINT){\n")
				c_stmt0("_1 = NewDouble((eudouble)(uintptr_t)_1);\n")
				c_stmt0("}\n")
				c_stmt0("*pokeptr_addr = _1;\n")
			case PEEK4U then
				c_stmt0("_1 = (object)*peek4_addr++;\n")
				c_stmt0("if ((uintptr_t)_1 > (uintptr_t)MAXINT){\n")
				c_stmt0("_1 = NewDouble((eudouble)(uintptr_t)_1);\n")
				c_stmt0("}\n")
				c_stmt0("*pokeptr_addr = _1;\n")
			case PEEK4S then
				c_stmt0("_1 = (object)(int32_t)*peek4_addr++;\n")
				
				c_stmt0("if (_1 < MININT || _1 > MAXINT){\n")
				c_stmt0("_1 = NewDouble((eudouble)_1);\n")
				c_stmt0("}\n")
				c_stmt0("*pokeptr_addr = _1;\n")
		end switch
		
		c_stmt0("}\n")
	end if

	if TypeIs( arg, TYPE_OBJECT) then
		c_stmt0("}\n")
	end if

	CDeRefStr("_0")

	if TypeIsIn( arg, TYPES_IAD) then
		
		switch op do
			case PEEK then
				target = {0, 255}
				SetBBType( target_sym, TYPE_INTEGER, target, TYPE_OBJECT,0 )
			case PEEKS then
				target = {-127, 127}
				SetBBType( target_sym, TYPE_INTEGER, target, TYPE_OBJECT,0 )
			case PEEK2S then
				target = {-32768, 32767}
				SetBBType( target_sym, TYPE_INTEGER, target, TYPE_OBJECT, 0)
			case PEEK2U then
				target = {0, #FFFF}
				SetBBType( target_sym, TYPE_INTEGER, target, TYPE_OBJECT, 0)
			case PEEK_STRING then
				SetBBType( target_sym, TYPE_SEQUENCE, novalue, TYPE_INTEGER, 0 )
			case else
				-- peek4, peek8
				SetBBType( target_sym, TYPE_ATOM, novalue, TYPE_OBJECT, 0)
		end switch

	elsif TypeIs( arg, TYPE_SEQUENCE) then
		if find(op, { PEEK, PEEKS, PEEK2U, PEEK2S }) then
			SetBBType( target_sym, TYPE_SEQUENCE, novalue, TYPE_INTEGER, 0)
		else
			SetBBType( target_sym, TYPE_SEQUENCE, novalue, TYPE_ATOM, 0)
		end if
	else
		if op = PEEK_STRING then
			SetBBType( target_sym, TYPE_SEQUENCE, novalue, TYPE_INTEGER, 0 )
		end if
		-- TYPE_OBJECT */
		SetBBType( target_sym, TYPE_OBJECT, novalue, TYPE_OBJECT, 0)

	end if
	if op = PEEK8U or op = PEEK8S then
		c_stmt0("}\n")
	end if
	dispose_temp( arg, DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( target_sym, NEW_REFERENCE )
	pc += 3
end procedure

procedure opPOKE()
-- generate code for poke/2/4/8
-- should optimize constant address
	integer 
		op  = Code[pc],
		ptr = Code[pc+1],
		val = Code[pc+2]
	if TypeIsIn( ptr, TYPES_AO) then
		c_stmt("if (IS_ATOM_INT(@)){\n", Code[pc+1])
	end if

	if TypeIsIn( ptr, TYPES_IAO) then
		switch op do
			case POKE_POINTER then
				c_stmt("pokeptr_addr = (uintptr_t *)@;\n", ptr )
			case POKE8 then
				c_stmt("poke8_addr = (uint64_t *)@;\n", ptr )
			case POKE4 then
				c_stmt("poke4_addr = (uint32_t *)@;\n", ptr )
			case POKE2 then
				c_stmt("poke2_addr = (uint16_t *)@;\n", ptr )
			case else
				c_stmt("poke_addr = (uint8_t *)@;\n", ptr )
		end switch
	end if

	if TypeIsIn( ptr, TYPES_AO) then
		c_stmt0("}\n" )
		c_stmt0("else {\n")
	end if

	if TypeIsNotIn( ptr, TYPES_IS) then
		switch op do
			case POKE_POINTER then
				c_stmt("pokeptr_addr = (uintptr_t *)(uintptr_t)(DBL_PTR(@)->dbl);\n",
							ptr)
			case POKE8 then
				c_stmt("poke8_addr = (uint64_t *)(uintptr_t)(DBL_PTR(@)->dbl);\n",
							ptr)
			case POKE4 then
				c_stmt("poke4_addr = (uint32_t *)(uintptr_t)(DBL_PTR(@)->dbl);\n",
							ptr)
			case POKE2 then
				c_stmt("poke2_addr = (uint16_t *)(uintptr_t)(DBL_PTR(@)->dbl);\n",
							ptr)
			case else
				c_stmt("poke_addr = (uint8_t *)(uintptr_t)(DBL_PTR(@)->dbl);\n",
							ptr)
		end switch
	end if
	
	if TypeIsIn( ptr, TYPES_AO) then
		c_stmt0("}\n" )
	end if
	
	if TypeIsIn( val, TYPES_AO) then
		c_stmt("if (IS_ATOM_INT(@)) {\n", val)
	end if

	if TypeIsIn( val, TYPES_IAO) then
		switch op do
			case POKE_POINTER then
				seg_pokeptr( val, 0 )
			case POKE8 then
				seg_poke8( val, 0)
			case POKE4 then
				seg_poke4( val, 0)
			case POKE2 then
				seg_poke2( val, 0)
			case else
				seg_poke1( val, 0)
		end switch
	end if

	if TypeIs( val, TYPE_ATOM) then
		c_stmt0("}\n")
		c_stmt0("else {\n")
	elsif TypeIs( val, TYPE_OBJECT) then
		c_stmt0("}\n")
		c_stmt("else if (IS_ATOM(@)) {\n", val )
	end if

	if TypeIsNotIn( val, TYPES_IS) then
		switch op do
			case POKE_POINTER then
				seg_pokeptr( val, 1 )
			case POKE8 then
				seg_poke8( val, 1)
			case POKE4 then
				seg_poke4( val, 1)
			case POKE2 then
				seg_poke2( val, 1)
			case else
				seg_poke1( val, 1)
		end switch
	end if

	if TypeIsIn( val, TYPES_AO) then
		c_stmt0("}\n")
	end if

	if TypeIs( val, TYPE_OBJECT) then
		c_stmt0("else {\n")
	end if

	if TypeIsIn( val, TYPES_SO) then
		c_stmt("_1 = (object)SEQ_PTR(@);\n", val)
		c_stmt0("_1 = (object)((s1_ptr)_1)->base;\n")

		c_stmt0("while (1) {\n") -- FAST WHILE
		c_stmt0("_1 += sizeof(object);\n")
		c_stmt0("_2 = *((object *)_1);\n")
		c_stmt0("if (IS_ATOM_INT(_2)) {\n")
		switch op do
			case POKE_POINTER then
				c_stmt0("*pokeptr_addr++ = (uintptr_t)_2;\n")
			case POKE8 then
				c_stmt0("*poke8_addr++ = (uint64_t)_2;\n")
			case POKE4 then
				c_stmt0("*poke4_addr++ = (uint32_t)_2;\n")
			case POKE2 then
				c_stmt0("*poke2_addr++ = (uint16_t)_2;\n")
			case else
				c_stmt0("*poke_addr++ = (uint8_t)_2;\n")
		end switch
		c_stmt0("}\nelse if (_2 == NOVALUE) {\n")
		c_stmt0("break;\n}\n")
		c_stmt0("else {\n")
		switch op do
			case POKE_POINTER then
				c_stmt0("*pokeptr_addr++ = (uintptr_t)DBL_PTR(_2)->dbl;\n")
			
			case POKE8 then
				c_stmt0("*poke8_addr++ = (uint64_t)DBL_PTR(_2)->dbl;\n")
				
			case POKE4 then
				c_stmt0("*(object *)poke4_addr++ = (uint32_t)DBL_PTR(_2)->dbl;\n")
				
			case POKE2 then
					c_stmt0("*poke2_addr++ = (uint16_t)DBL_PTR(_2)->dbl;\n")
				
			case else
					c_stmt0("*poke_addr++ = (uint8_t)DBL_PTR(_2)->dbl;\n")
				
		end switch
		c_stmt0("}\n")
		c_stmt0("}\n") -- while(1)

	end if

	if TypeIs( val, TYPE_OBJECT) then
		c_stmt0("}\n")
	end if
	dispose_temps( pc + 1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 3
end procedure

procedure opMEM_COPY()
	c_stmt("memory_copy(@, @, @);\n", {Code[pc+1], Code[pc+2], Code[pc+3]})
	dispose_temps( pc+1, 3, DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 4
end procedure

procedure opMEM_SET()
	c_stmt("memory_set(@, @, @);\n", {Code[pc+1], Code[pc+2], Code[pc+3]})
	dispose_temps( pc+1, 3, DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 4
end procedure

function file_and_line()
	integer ix = rfind( STARTLINE, Code, pc )
	integer line = Code[ix+1]
	return {known_files[slist[line][LOCAL_FILE_NO]], slist[line][LINE]}
end function

procedure opCALL()
	c_stmt("if (IS_ATOM_INT(@))\n", Code[pc+1])
	c_stmt("_0 = (object)@;\n", Code[pc+1])
	c_stmt0("else\n")
	c_stmt("_0 = (object)(uintptr_t)(DBL_PTR(@)->dbl);\n", Code[pc+1])
	c_stmt0("(*(void(*)())_0)();\n")
	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 2
end procedure

procedure opSYSTEM()
	c_stmt("system_call(@, @);\n", {Code[pc+1], Code[pc+2]})
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 3
end procedure

procedure opSYSTEM_EXEC()
	CSaveStr("_0", Code[pc+3], Code[pc+1], Code[pc+2], 0)
	c_stmt("@ = system_exec_call(@, @);\n",
			{Code[pc+3], Code[pc+1], Code[pc+2]})
	CDeRefStr("_0")
	-- probably 0..255, but we can't be totally sure
	SetBBType(Code[pc+3], TYPE_INTEGER, novalue, TYPE_OBJECT, 0)
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 4
end procedure

-- start of I/O routines */

procedure opOPEN()
	CSaveStr("_0", Code[pc+4], Code[pc+1], Code[pc+2], 0)
	c_stmt("@ = EOpen(@, @, @);\n", {Code[pc+4], Code[pc+1], Code[pc+2], Code[pc+3]})
	CDeRefStr("_0")
	target = {-1, 100000}
	if ObjValue( Code[pc+3] ) = 0 then
		SetBBType(Code[pc+4], TYPE_INTEGER, target, TYPE_OBJECT, 0)
	else
		SetBBType(Code[pc+4], TYPE_ATOM, target, TYPE_OBJECT, 1)
	end if
	dispose_temps( pc+1, 3, DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+4], NEW_REFERENCE )
	pc += 5
end procedure

procedure opCLOSE()
-- CLOSE / ABORT
	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt("if (IS_ATOM_INT(@))\n", Code[pc+1])
	end if

	if TypeIsIn(Code[pc+1], TYPES_IAO) then
		if Code[pc] = ABORT then
			c_stmt("UserCleanup(@);\n", Code[pc+1])
		else
			c_stmt("EClose(@);\n", Code[pc+1])
		end if
	end if

	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt0("else\n")
	end if

	if TypeIsNot(Code[pc+1], TYPE_INTEGER) then
		if Code[pc] = ABORT then
			c_stmt("UserCleanup((object)DBL_PTR(@)->dbl);\n", Code[pc+1])
		else
			c_stmt("EClose((object)DBL_PTR(@)->dbl);\n", Code[pc+1])
		end if
	end if
	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 2
end procedure

procedure opGETC()
-- read a character from a file
	CSaveStr("_0", Code[pc+2], Code[pc+1], 0, 0)
	c_stmt("if (@ != last_r_file_no) {\n", Code[pc+1])
	c_stmt("last_r_file_ptr = which_file(@, EF_READ);\n", Code[pc+1])

	if TypeIsNot(Code[pc+1], TYPE_INTEGER) then
		c_stmt("if (IS_ATOM_INT(@)){\n", Code[pc+1])
	end if

	c_stmt("last_r_file_no = @;\n", Code[pc+1])

	if TypeIsNot(Code[pc+1], TYPE_INTEGER) then
		c_stmt0("}\nelse{\n")
		c_stmt0("last_r_file_no = NOVALUE;\n}\n")
	end if

	c_stmt0("}\n")
	c_stmt0("if (last_r_file_ptr == xstdin) {\n")
	if TWINDOWS then
		c_stmt0("show_console();\n")
	end if
	c_stmt0("if (in_from_keyb) {\n")
	if TUNIX then
		if EGPM then
			c_stmt("@ = mgetch(1);\n", Code[pc+2])  -- echo the character
		else
			-- c_stmt("@ = getch(1);\n", Code[pc+2])   -- echo the character
			c_stmt("@ = getc((FILE*)xstdin);\n", Code[pc+2])   -- echo the character
		end if
	else
		c_stmt("@ = wingetch();\n", Code[pc+2])
	end if
	c_stmt0("}\n")
	c_stmt0("else{\n")

	-- don't bother with mygetc() - it might not be portable
	-- to other DOS C compilers
	c_stmt("@ = getc(last_r_file_ptr);\n", Code[pc+2])
	c_stmt0("}\n")
	c_stmt0("}\n")
	c_stmt0("else{\n")

	c_stmt("@ = getc(last_r_file_ptr);\n}\n", Code[pc+2])

	CDeRefStr("_0")
	target = {-1, 255}
	SetBBType(Code[pc+2], TYPE_INTEGER, target, TYPE_OBJECT, 0)
	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 3
end procedure

procedure opGETS()
-- read a line from a file
	CSaveStr("_0", Code[pc+2], Code[pc+1], 0, 0)
	c_stmt("@ = EGets(@);\n", {Code[pc+2], Code[pc+1]})
	CDeRefStr("_0")
	SetBBType(Code[pc+2], TYPE_OBJECT, novalue, TYPE_INTEGER, 0) -- N.B.
	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+2], NEW_REFERENCE )
	pc += 3
end procedure

procedure opGET_KEY()
-- read an immediate key (if any) from the keyboard or return -1
	if TWINDOWS then
		c_stmt0("show_console();\n")
	end if
	CSaveStr("_0", Code[pc+1], 0, 0, 0)
	c_stmt("@ = get_key(0);\n", Code[pc+1])
	CDeRefStr("_0")
	target = {-1, 1000}
	SetBBType(Code[pc+1], TYPE_INTEGER, target, TYPE_OBJECT, 0)
	pc += 2
end procedure

procedure opCLEAR_SCREEN()
	c_stmt0("ClearScreen();\n")
	pc += 1
end procedure

procedure opPUTS()
	c_stmt("EPuts(@, @); // DJP \n", {Code[pc+1], Code[pc+2]})
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 3
end procedure

procedure opPRINT()
-- PRINT / QPRINT
	if Code[pc] = QPRINT then
		c_stmt("StdPrint(@, @, 1);\n", {Code[pc+1], Code[pc+2]})
	else
		c_stmt("StdPrint(@, @, 0);\n", {Code[pc+1], Code[pc+2]})
	end if
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 3
end procedure

procedure opPRINTF()
	c_stmt("EPrintf(@, @, @);\n", {Code[pc+1], Code[pc+2], Code[pc+3]})
	dispose_temps( pc+1, 3, DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 4
end procedure

constant DOING_SPRINTF = -9999999

procedure opSPRINTF()
	CSaveStr("_0", Code[pc+3], Code[pc+1], Code[pc+2], 0)
	c_stmt("@ = EPrintf(" & sprintf("%d", DOING_SPRINTF) & ", @, @);\n",
		   {Code[pc+3], Code[pc+1], Code[pc+2]})
	CDeRefStr("_0")
	SetBBType(Code[pc+3], TYPE_SEQUENCE, novalue, TYPE_INTEGER, 0)
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+3], NEW_REFERENCE )
	pc += 4
end procedure

-- TODO: this doesn't work yet...
procedure opCOMMAND_LINE()
	CSaveStr("_0", Code[pc+1], 0, 0, 0)
	c_stmt("@ = Command_Line();\n" , Code[pc+1])
	CDeRefStr("_0")
	SetBBType(Code[pc+1], TYPE_SEQUENCE, novalue, TYPE_SEQUENCE, 0)
	create_temp( Code[pc+1], NEW_REFERENCE )
	pc += 2
end procedure

procedure opOPTION_SWITCHES()
	CSaveStr("_0", Code[pc+1], 0, 0, 0)
	c_stmt0("RefDS(_0switches);\n")
	c_stmt("@ = _0switches;\n", Code[pc+1] )
	CDeRefStr("_0")
	SetBBType(Code[pc+1], TYPE_SEQUENCE, novalue, TYPE_SEQUENCE, 0)
	create_temp( Code[pc+1], NEW_REFERENCE )
	pc += 2
end procedure

procedure opGETENV()
	CSaveStr("_0", Code[pc+2], Code[pc+1], 0, 0)
	c_stmt("@ = EGetEnv(@);\n", {Code[pc+2], Code[pc+1]})
	CDeRefStr("_0")
	SetBBType(Code[pc+2], TYPE_OBJECT, novalue, TYPE_INTEGER, 0) -- N.B.
	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+2], NEW_REFERENCE )
	pc += 3
end procedure

procedure opMACHINE_FUNC()
	CSaveStr("_0", Code[pc+3], Code[pc+1], Code[pc+2], 0)
	c_stmt("@ = machine(@, @);\n", {Code[pc+3], Code[pc+1], Code[pc+2]})
	CDeRefStr("_0")
	target = machine_func_type(Code[pc+1])
	SetBBType(Code[pc+3], target[1], target[2],
			  machine_func_elem_type(Code[pc+1]), 0)
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+3], NEW_REFERENCE )
	pc += 4
end procedure

procedure opMACHINE_PROC()
	c_stmt("machine(@, @);\n", {Code[pc+1], Code[pc+2]})
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 3
end procedure

procedure delete_double( symtab_index obj )
	c_stmt("if(DBL_PTR(@)->cleanup != 0 ){\n", obj )
		c_stmt("_1 = (object) ChainDeleteRoutine( (cleanup_ptr)_1, DBL_PTR(@)->cleanup );\n", obj )
	c_stmt0("}\n")
	c_stmt("else if( !UNIQUE(DBL_PTR(@)) ){\n", obj )
		CDeRef( obj )
		c_stmt("@ = NewDouble( DBL_PTR(@)->dbl );\n", {obj, obj} )
	c_stmt0("}\n")
	c_stmt("DBL_PTR(@)->cleanup = (cleanup_ptr)_1;\n", obj )
end procedure

procedure delete_sequence( symtab_index obj )
	c_stmt("if(SEQ_PTR(@)->cleanup != 0 ){\n", obj )
		c_stmt("_1 = (object) ChainDeleteRoutine( (cleanup_ptr)_1, SEQ_PTR(@)->cleanup );\n", obj )
	c_stmt0("}\n")
	c_stmt("else if( !UNIQUE(SEQ_PTR(@)) ){\n", obj )
		c_stmt("@ = MAKE_SEQ(SequenceCopy( SEQ_PTR(@) ));\n", {obj, obj} )
	c_stmt0("}\n")
	c_stmt("SEQ_PTR(@)->cleanup = (cleanup_ptr)_1;\n", obj )
end procedure

procedure promote_integer_delete( symtab_index obj, symtab_index target )
	c_stmt("@ = NewDouble( (eudouble) @ );\n", {target, obj})
	SetBBType( target, TYPE_DOUBLE, ObjMinMax( obj ), TYPE_OBJECT, 1)
end procedure

procedure assign_delete_target( symtab_index target, symtab_index obj )
	CDeRef( target )

	if TypeIsIn( obj, TYPES_AO ) then
		c_stmt( "if( IS_ATOM_INT(@) ){\n", obj )
			promote_integer_delete( obj, target )
		c_stmt0("}\n")
		c_stmt0("else {\n")
	end if

	c_stmt( "if( !UNIQUE(SEQ_PTR(@)) ){\n", obj )
		if TypeIs( obj, TYPE_DOUBLE ) then
			c_stmt( "@ = NewDouble( DBL_PTR(@)->dbl );\n", {target, obj})
		elsif TypeIs( obj, TYPE_SEQUENCE ) then
			c_stmt( "@ = MAKE_SEQ(SequenceCopy( SEQ_PTR(@) ));\n", {target, obj} )
		else
			c_stmt( "if( IS_ATOM_DBL( @ ) ){\n", obj )
				c_stmt( "@ = NewDouble( DBL_PTR(@)->dbl );\n", {target, obj})
			c_stmt0( "}\n")
			c_stmt0( "else {\n" )
				c_stmt("RefDS(@);\n", obj )
				c_stmt( "@ = MAKE_SEQ(SequenceCopy( SEQ_PTR(@) ));\n", {target, obj} )
			c_stmt0( "}\n" )
		end if
	c_stmt0( "}\n")
	c_stmt0( "else {\n" )
		c_stmt( "@ = @;\n", {target, obj})
	c_stmt0( "}\n")

	if TypeIsIn( obj, TYPES_AO ) then
		c_stmt0("}\n")
	end if

	if TypeIsIn( obj, TYPES_SO) then
		SetBBType(target, GType(obj), {SeqLen(Code[pc+1]), 0}, SeqElem(obj), 1)
	else
		SetBBType(target, GType(obj), ObjMinMax(obj), TYPE_OBJECT, 1)
	end if

end procedure


procedure DeleteRoutine( symtab_index rid )
	c_stmt("_1 = (object) _00[@].cleanup;\n", rid )
	c_stmt0("if( _1 == 0 ){\n")
		c_stmt0("_1 = (object) TransAlloc( sizeof(struct cleanup) );\n")
		c_stmt( "_00[@].cleanup = (cleanup_ptr)_1;\n", rid)
	c_stmt0("}\n")
	c_stmt0("((cleanup_ptr)_1)->type = CLEAN_UDT_RT;\n")
	c_stmt( "((cleanup_ptr)_1)->func.rid = @;\n", rid)
	c_stmt0("((cleanup_ptr)_1)->next = 0;\n")
end procedure

procedure opDELETE_ROUTINE()
	symtab_index
		obj = Code[pc+1],
		rid = Code[pc+2],
		target = Code[pc+3]

	if (sym_mode( obj ) = M_TEMP and eu:compare( sym_obj( obj ), NOVALUE ))
	then
		-- make a copy of a literal
		DeleteRoutine( rid )

		if SymTab[target][S_MODE] != M_TEMP then
			CDeRef( target )
		end if

		object val = SymTab[obj][S_OBJ]
		if atom(val) then
			if integer(val) then
				c_stmt( "_2 = NewDouble( (eudouble) @ );\n", obj )
			elsif atom(val) then
				c_stmt( "_2 = NewDouble( DBL_PTR(@)->dbl );\n", obj )
			end if
			c_stmt0("DBL_PTR(_2)->cleanup = (cleanup_ptr)_1;\n")
			SetBBType(target, GType(obj), ObjMinMax(obj), TYPE_OBJECT, 1)
		else
			c_stmt("RefDS(@);\n", obj )
			c_stmt("_2 = MAKE_SEQ(SequenceCopy( SEQ_PTR(@) ));\n", obj )
			c_stmt0("SEQ_PTR(_2)->cleanup = (cleanup_ptr)_1;\n")
			SetBBType(target, GType(obj), {SeqLen(obj), 0}, SeqElem(obj), 1)
		end if

		c_stmt( "@ = _2;\n", target )

	else
		-- b = (pc[1] != pc[3]) && (((symtab_ptr)pc[1])->mode != M_TEMP);
		if TypeIs( obj, TYPE_INTEGER ) then
			promote_integer_delete( obj, target )

		elsif TypeIs( obj, TYPE_ATOM ) and not TypeIsNot( obj, TYPE_DOUBLE ) then
			c_stmt("if( !IS_ATOM_DBL(@) ){\n", obj )
				c_stmt("@ = NewDouble( @ );\n", {target, obj})
			c_stmt0("}\n")
			c_stmt0("else{\n")
				assign_delete_target( target, obj )
			c_stmt0("}\n")
		elsif obj != target then
			assign_delete_target( target, obj )
		end if


		DeleteRoutine( rid )

		if TypeIs( target, TYPE_DOUBLE ) then
			delete_double( target )
		elsif TypeIs( target, TYPE_SEQUENCE ) then
			delete_sequence( target )
		else
			c_stmt("if( IS_ATOM(@) ){\n", target )
				c_stmt("if( IS_ATOM_INT(@) ){\n", target )
					promote_integer_delete( obj, target )
				c_stmt0("}\n")
				delete_double( target )
			c_stmt0("}\n")
			c_stmt0("else{\n")
				delete_sequence( target )
			c_stmt0("}\n")
		end if

		if obj != target and sym_mode( obj ) = M_NORMAL then
			if not TypeIs( obj, TYPE_INTEGER ) then
				if TypeIsNotIn( obj, TYPES_DS ) then
					c_stmt( "if( !IS_ATOM_INT(@) ){\n", obj )
						c_stmt("RefDS(@);\n", target )
					c_stmt0("}\n")
				else
					c_stmt("RefDS(@);\n", target )
				end if

			end if
		end if
	end if
	dispose_temps( pc+1, 2, SAVE_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+3], NEW_REFERENCE )
	pc += 4
end procedure

procedure opDELETE_OBJECT()
	symtab_index obj = Code[pc+1]
	NewBB(1, E_ALL_EFFECT, 0)
	if TypeIs( obj, TYPE_SEQUENCE ) then
		c_stmt( "cleanup_sequence( SEQ_PTR( @ ) );\n", obj )
		if SeqElem( obj ) = TYPE_INTEGER then
			SetBBType( obj, TYPE_SEQUENCE, {SeqLen(Code[pc+1]), 0}, TYPE_INTEGER, 0)
		end if
	elsif TypeIs( obj, TYPE_DOUBLE ) then
		c_stmt( "cleanup_double( DBL_PTR( @ ) );\n", obj )
		SetBBType( obj, TYPE_DOUBLE, ObjValue(obj), TYPE_OBJECT, 0 )

	elsif not TypeIs( obj, TYPE_INTEGER ) then
		c_stmt("if( IS_SEQUENCE(@) ){\n", obj )
			c_stmt("cleanup_sequence(SEQ_PTR(@));\n", obj )
		c_stmt0("}\n")
		c_stmt("if( IS_ATOM_DBL(@)){\n", obj )
			c_stmt("cleanup_double(DBL_PTR(@));\n", obj )
		c_stmt0("}\n")
	end if
	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 2
end procedure

procedure opC_FUNC()
	-- not available under DOS, but better to leave it in
	-- [3] not used
	CSaveStr("_0", Code[pc+4], Code[pc+2], Code[pc+1], 0)
	c_stmt("@ = call_c(1, @, @);\n", {Code[pc+4], Code[pc+1], Code[pc+2]})
	SymTab[Code[pc+4]][S_ONE_REF] = FALSE
	-- in elsif opcode = it's a sequence returned by Euphoria .dll
	CDeRefStr("_0")

	NewBB(1, E_ALL_EFFECT, 0) -- Windows call-back to Euphoria routine could occur

	SetBBType(Code[pc+4], TYPE_OBJECT, -- might be call to Euphoria routine
			  novalue, TYPE_OBJECT, GDelete())
	dispose_temps( pc+1, 3, DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+4], NEW_REFERENCE )
	pc += 5
end procedure

procedure opC_PROC()
	c_stmt("call_c(0, @, @);\n", {Code[pc+1], Code[pc+2]})
	-- [3] not used
	dispose_temps( pc+1, 3, DISCARD_TEMP, REMOVE_FROM_MAP )
	NewBB(1, E_ALL_EFFECT, 0) -- Windows call-back to Euphoria routine could occur
	pc += 4
end procedure

procedure opTRACE()
	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt("if (IS_ATOM_INT(@))\n", Code[pc+1])
	end if

	if TypeIsIn(Code[pc+1], TYPES_IAO) then
		c_stmt("TraceOn = @;\n", Code[pc+1])
	end if

	if TypeIsIn(Code[pc+1], TYPES_AO) then
		c_stmt0("else\n")
	end if

	if TypeIsNot(Code[pc+1], TYPE_INTEGER) then
		c_stmt("TraceOn = DBL_PTR(@)->dbl != 0.0;\n", Code[pc+1])
	end if
	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 2
end procedure

		-- other tracing/profiling ops - ignored by compiler
procedure opPROFILE()
-- PROFILE / DISPLAY_VAR / ERASE_PRIVATE_NAMES / ERASE_SYMBOL / NOP2
	pc += 2
end procedure

procedure opUPDATE_GLOBALS()
	pc += 1
end procedure



-- Multitasking ops

boolean tasks_created
tasks_created = FALSE

procedure dll_tasking()
	if dll_option then
		CompileErr(112)
	end if
end procedure

procedure opTASK_CREATE()
	dll_tasking()
	CSaveStr("_0", Code[pc+3], Code[pc+1], Code[pc+2], 0)
	c_stmt("@ = ctask_create(@, @);\n", {Code[pc+3], Code[pc+1], Code[pc+2]})
	CDeRefStr("_0")
	SetBBType(Code[pc+3], TYPE_DOUBLE, novalue, TYPE_OBJECT, 0) -- always TYPE_DOUBLE
	tasks_created = TRUE
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+3], NEW_REFERENCE )
	pc += 4
end procedure

procedure opTASK_SCHEDULE()
	dll_tasking()
	c_stmt("task_schedule(@, @);\n", {Code[pc+1], Code[pc+2]})
	dispose_temps( pc+1, 2, DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 3
end procedure

procedure opTASK_YIELD()
	if not dll_option then
		c_stmt0("task_yield();\n")
	end if
	pc += 1
end procedure

procedure opTASK_SELF()
	dll_tasking()
	CDeRef(Code[pc+1]) -- Code[pc+1] not used in next expression
	c_stmt("@ = NewDouble(tcb[current_task].tid);\n", {Code[pc+1]})
	SetBBType(Code[pc+1], TYPE_DOUBLE, novalue, TYPE_OBJECT, 0) -- always TYPE_DOUBLE
	create_temp( Code[pc+1], NEW_REFERENCE )
	pc += 2
end procedure

procedure opTASK_SUSPEND()
	dll_tasking()
	c_stmt("task_suspend(@);\n", {Code[pc+1]})
	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	pc += 2
end procedure

procedure opTASK_LIST()
	dll_tasking()
	CDeRef(Code[pc+1]) -- Code[pc+1] not used in next expression
	c_stmt("@ = task_list();\n", {Code[pc+1]})
	SetBBType(Code[pc+1], TYPE_SEQUENCE, novalue, TYPE_DOUBLE, 0)
	create_temp( Code[pc+1], NEW_REFERENCE )
	pc += 2
end procedure

procedure opTASK_STATUS()
	dll_tasking()
	CSaveStr("_0", Code[pc+2], Code[pc+1], 0, 0)
	c_stmt("@ = task_status(@);\n", {Code[pc+2], Code[pc+1]})
	CDeRefStr("_0")
	SetBBType(Code[pc+2], TYPE_INTEGER, {-1,+1}, TYPE_OBJECT, 0)
	dispose_temp( Code[pc+1], DISCARD_TEMP, REMOVE_FROM_MAP )
	create_temp( Code[pc+2], NEW_REFERENCE )
	pc += 3
end procedure

procedure opTASK_CLOCK_STOP()
	dll_tasking()
	c_stmt0("task_clock_stop();\n")
	pc += 1
end procedure

procedure opTASK_CLOCK_START()
	dll_tasking()
	c_stmt0("task_clock_start();\n")
	pc += 1
end procedure


sequence operation -- routine ids for all opcode handlers

export procedure init_opcodes()
-- initialize routine id's for opcode handlers
	sequence name

	operation = repeat(-1, length(opnames))
	for i = 1 to length(opnames) do
		name = opnames[i]
		-- some similar ops are handled by a common routine
		switch name do
			case "AND_BITS" then
				operation[i] = routine_id("opAND_BITS")

			case "AND" then
				operation[i] = routine_id("opAND")

			case "APPEND" then
				operation[i] = routine_id("opAPPEND")

			case "ARCTAN" then
				operation[i] = routine_id("opARCTAN")

			case "ASSIGN_I" then
				operation[i] = routine_id("opASSIGN_I")

			case "ASSIGN_OP_SLICE" then
				operation[i] = routine_id("opASSIGN_OP_SLICE")

			case "ASSIGN_SLICE" then
				operation[i] = routine_id("opASSIGN_SLICE")

			case "ASSIGN_SUBS" then
				operation[i] = routine_id("opASSIGN_SUBS")

			case "ASSIGN" then
				operation[i] = routine_id("opASSIGN")

			case "ATOM_CHECK" then
				operation[i] = routine_id("opATOM_CHECK")

			case "BADRETURNF" then
				operation[i] = routine_id("opBADRETURNF")

			case "C_FUNC" then
				operation[i] = routine_id("opC_FUNC")

			case "C_PROC" then
				operation[i] = routine_id("opC_PROC")

			case "CALL_BACK_RETURN" then
				operation[i] = routine_id("opCALL_BACK_RETURN")

			case "CALL_PROC" then
				operation[i] = routine_id("opCALL_PROC")

			case "CALL" then
				operation[i] = routine_id("opCALL")

			case "CASE" then
				operation[i] = routine_id("opCASE")

			case "CLEAR_SCREEN" then
				operation[i] = routine_id("opCLEAR_SCREEN")

			case "CLOSE" then
				operation[i] = routine_id("opCLOSE")

			case "COMMAND_LINE" then
				operation[i] = routine_id("opCOMMAND_LINE")

			case "COMPARE" then
				operation[i] = routine_id("opCOMPARE")

			case "CONCAT_N" then
				operation[i] = routine_id("opCONCAT_N")

			case "CONCAT" then
				operation[i] = routine_id("opCONCAT")

			case "COS" then
				operation[i] = routine_id("opCOS")

			case "DATE" then
				operation[i] = routine_id("opDATE")

			case "DIV2" then
				operation[i] = routine_id("opDIV2")

			case "DIVIDE" then
				operation[i] = routine_id("opDIVIDE")

			case "ENDFOR_GENERAL" then
				operation[i] = routine_id("opENDFOR_GENERAL")

			case "EQUAL" then
				operation[i] = routine_id("opEQUAL")

			case "EQUALS_IFW_I" then
				operation[i] = routine_id("opEQUALS_IFW_I")

			case "EQUALS_IFW" then
				operation[i] = routine_id("opEQUALS_IFW")

			case "EQUALS" then
				operation[i] = routine_id("opEQUALS")

			case "EXIT" then
				operation[i] = routine_id("opEXIT")

			case "FIND_FROM" then
				operation[i] = routine_id("opFIND_FROM")

			case "FIND" then
				operation[i] = routine_id("opFIND")

			case "FLOOR_DIV" then
				operation[i] = routine_id("opFLOOR_DIV")

			case "FLOOR_DIV2" then
				operation[i] = routine_id("opFLOOR_DIV2")

			case "FLOOR" then
				operation[i] = routine_id("opFLOOR")

			case "FOR" then
				operation[i] = routine_id("opFOR")

			case "GET_KEY" then
				operation[i] = routine_id("opGET_KEY")

			case "GETC" then
				operation[i] = routine_id("opGETC")

			case "GETENV" then
				operation[i] = routine_id("opGETENV")

			case "GETS" then
				operation[i] = routine_id("opGETS")

			case "GLABEL" then
				operation[i] = routine_id("opGLABEL")

			case "GLOBAL_INIT_CHECK" then
				operation[i] = routine_id("opGLOBAL_INIT_CHECK")

			case "GOTO" then
				operation[i] = routine_id("opGOTO")

			case "GREATER_IFW_I" then
				operation[i] = routine_id("opGREATER_IFW_I")

			case "GREATER_IFW" then
				operation[i] = routine_id("opGREATER_IFW")

			case "GREATER" then
				operation[i] = routine_id("opGREATER")

			case "GREATEREQ_IFW_I" then
				operation[i] = routine_id("opGREATEREQ_IFW_I")

			case "GREATEREQ_IFW" then
				operation[i] = routine_id("opGREATEREQ_IFW")

			case "GREATEREQ" then
				operation[i] = routine_id("opGREATEREQ")

			case "HASH" then
				operation[i] = routine_id("opHASH")

			case "HEAD" then
				operation[i] = routine_id("opHEAD")

			case "IF" then
				operation[i] = routine_id("opIF")

			case "INSERT" then
				operation[i] = routine_id("opINSERT")

			case "INTEGER_CHECK" then
				operation[i] = routine_id("opINTEGER_CHECK")

			case "IS_A_SEQUENCE" then
				operation[i] = routine_id("opIS_A_SEQUENCE")

			case "IS_AN_ATOM" then
				operation[i] = routine_id("opIS_AN_ATOM")

			case "IS_AN_INTEGER" then
				operation[i] = routine_id("opIS_AN_INTEGER")

			case "IS_AN_OBJECT" then
				operation[i] = routine_id("opIS_AN_OBJECT")

			case "LENGTH" then
				operation[i] = routine_id("opLENGTH")

			case "LESS_IFW_I" then
				operation[i] = routine_id("opLESS_IFW_I")

			case "LESS_IFW" then
				operation[i] = routine_id("opLESS_IFW")

			case "LESS" then
				operation[i] = routine_id("opLESS")

			case "LESSEQ_IFW_I" then
				operation[i] = routine_id("opLESSEQ_IFW_I")

			case "LESSEQ_IFW" then
				operation[i] = routine_id("opLESSEQ_IFW")

			case "LESSEQ" then
				operation[i] = routine_id("opLESSEQ")

			case "LHS_SUBS" then
				operation[i] = routine_id("opLHS_SUBS")

			case "LOG" then
				operation[i] = routine_id("opLOG")

			case "MACHINE_FUNC" then
				operation[i] = routine_id("opMACHINE_FUNC")

			case "MACHINE_PROC" then
				operation[i] = routine_id("opMACHINE_PROC")

			case "MATCH_FROM" then
				operation[i] = routine_id("opMATCH_FROM")

			case "MATCH" then
				operation[i] = routine_id("opMATCH")

			case "MEM_COPY" then
				operation[i] = routine_id("opMEM_COPY")

			case "MEM_SET" then
				operation[i] = routine_id("opMEM_SET")

			case "MEMSTRUCT_ACCESS" then
				operation[i] = routine_id("opMEMSTRUCT_ACCESS")
				
			case "MEMSTRUCT_ARRAY" then
				operation[i] = routine_id("opMEMSTRUCT_ARRAY")
				
			case "PEEK_MEMBER" then
				operation[i] = routine_id("opPEEK_MEMBER")
				
			case "MEMSTRUCT_SERIALIZE" then
				operation[i] = routine_id("opMEMSTRUCT_SERIALIZE")
				
			case "MEMSTRUCT_ASSIGN" then
				operation[i] = routine_id("opMEMSTRUCT_ASSIGN")
				
			case "MEMSTRUCT_PLUS", "MEMSTRUCT_MINUS", "MEMSTRUCT_MULTIPLY", "MEMSTRUCT_DIVIDE" then
				operation[i] = routine_id("opMEMSTRUCT_ASSIGNOP")
				
			case "MINUS" then
				operation[i] = routine_id("opMINUS")

			case "MULTIPLY" then
				operation[i] = routine_id("opMULTIPLY")

			case "NOP1" then
				operation[i] = routine_id("opNOP1")

			case "NOPSWITCH" then
				operation[i] = routine_id("opNOPSWITCH")

			case "NOT_BITS" then
				operation[i] = routine_id("opNOT_BITS")

			case "NOT_IFW" then
				operation[i] = routine_id("opNOT_IFW")

			case "NOT" then
				operation[i] = routine_id("opNOT")

			case "NOTEQ_IFW_I" then
				operation[i] = routine_id("opNOTEQ_IFW_I")

			case "NOTEQ_IFW" then
				operation[i] = routine_id("opNOTEQ_IFW")

			case "NOTEQ" then
				operation[i] = routine_id("opNOTEQ")

			case "OPEN" then
				operation[i] = routine_id("opOPEN")

			case "OPTION_SWITCHES" then
				operation[i] = routine_id("opOPTION_SWITCHES")

			case "OR_BITS" then
				operation[i] = routine_id("opOR_BITS")

			case "OR" then
				operation[i] = routine_id("opOR")

			case "PEEK" then
				operation[i] = routine_id("opPEEK")

			case "PLUS" then
				operation[i] = routine_id("opPLUS")

			case "PLUS1" then
				operation[i] = routine_id("opPLUS1")

			case "POKE" then
				operation[i] = routine_id("opPOKE")

			case "POSITION" then
				operation[i] = routine_id("opPOSITION")

			case "POWER" then
				operation[i] = routine_id("opPOWER")

			case "PREPEND" then
				operation[i] = routine_id("opPREPEND")

			case "PRINT" then
				operation[i] = routine_id("opPRINT")

			case "PRINTF" then
				operation[i] = routine_id("opPRINTF")

			case "PROC_TAIL" then
				operation[i] = routine_id("opPROC_TAIL")

			case "PROC" then
				operation[i] = routine_id("opPROC")

			case "PROFILE" then
				operation[i] = routine_id("opPROFILE")

			case "PUTS" then
				operation[i] = routine_id("opPUTS")

			case "RAND" then
				operation[i] = routine_id("opRAND")

			case "REMAINDER" then
				operation[i] = routine_id("opREMAINDER")

			case "REMOVE" then
				operation[i] = routine_id("opREMOVE")

			case "REPEAT" then
				operation[i] = routine_id("opREPEAT")

			case "REPLACE" then
				operation[i] = routine_id("opREPLACE")

			case "RETURNF" then
				operation[i] = routine_id("opRETURNF")

			case "RETURNP" then
				operation[i] = routine_id("opRETURNP")

			case "RETURNT" then
				operation[i] = routine_id("opRETURNT")

			case "RHS_SLICE" then
				operation[i] = routine_id("opRHS_SLICE")

			case "RHS_SUBS" then
				operation[i] = routine_id("opRHS_SUBS")

			case "RIGHT_BRACE_2" then
				operation[i] = routine_id("opRIGHT_BRACE_2")

			case "RIGHT_BRACE_N" then
				operation[i] = routine_id("opRIGHT_BRACE_N")

			case "ROUTINE_ID" then
				operation[i] = routine_id("opROUTINE_ID")

			case "SC1_AND" then
				operation[i] = routine_id("opSC1_AND")

			case "SC1_OR" then
				operation[i] = routine_id("opSC1_OR")

			case "SC2_OR" then
				operation[i] = routine_id("opSC2_OR")

			case "SIN" then
				operation[i] = routine_id("opSIN")

			case "SIZEOF" then
				operation[i] = routine_id("opSIZEOF")

			case "SPACE_USED" then
				operation[i] = routine_id("opSPACE_USED")

			case "SPLICE" then
				operation[i] = routine_id("opSPLICE")

			case "SPRINTF" then
				operation[i] = routine_id("opSPRINTF")

			case "SQRT" then
				operation[i] = routine_id("opSQRT")

			case "STARTLINE", "STARTLINE_BREAK" then
				operation[i] = routine_id("opSTARTLINE")

			case "SWITCH_RT" then
				operation[i] = routine_id("opSWITCH_RT")

			case "SWITCH" then
				operation[i] = routine_id("opSWITCH")

			case "SYSTEM_EXEC" then
				operation[i] = routine_id("opSYSTEM_EXEC")

			case "SYSTEM" then
				operation[i] = routine_id("opSYSTEM")

			case "TAIL" then
				operation[i] = routine_id("opTAIL")

			case "TAN" then
				operation[i] = routine_id("opTAN")

			case "TASK_CLOCK_START" then
				operation[i] = routine_id("opTASK_CLOCK_START")

			case "TASK_CLOCK_STOP" then
				operation[i] = routine_id("opTASK_CLOCK_STOP")

			case "TASK_CREATE" then
				operation[i] = routine_id("opTASK_CREATE")

			case "TASK_LIST" then
				operation[i] = routine_id("opTASK_LIST")

			case "TASK_SCHEDULE" then
				operation[i] = routine_id("opTASK_SCHEDULE")

			case "TASK_SELF" then
				operation[i] = routine_id("opTASK_SELF")

			case "TASK_STATUS" then
				operation[i] = routine_id("opTASK_STATUS")

			case "TASK_SUSPEND" then
				operation[i] = routine_id("opTASK_SUSPEND")

			case "TASK_YIELD" then
				operation[i] = routine_id("opTASK_YIELD")

			case "TIME" then
				operation[i] = routine_id("opTIME")

			case "TRACE" then
				operation[i] = routine_id("opTRACE")

			case "TYPE_CHECK", "MEM_TYPE_CHECK" then
				operation[i] = routine_id("opTYPE_CHECK")
			
			case "UMINUS" then
				operation[i] = routine_id("opUMINUS")

			case "UPDATE_GLOBALS" then
				operation[i] = routine_id("opUPDATE_GLOBALS")

			case "XOR_BITS" then
				operation[i] = routine_id("opXOR_BITS")

			case "XOR" then
				operation[i] = routine_id("opXOR")

			case "ASSIGN_OP_SUBS", "PASSIGN_OP_SUBS", "RHS_SUBS_CHECK", "RHS_SUBS_I" then
				operation[i] = routine_id("opRHS_SUBS")

			case "NOPWHILE" then
				operation[i] = routine_id("opNOP1")

			case "WHILE" then
				operation[i] = routine_id("opIF")

			case "SEQUENCE_CHECK" then
				operation[i] = routine_id("opATOM_CHECK")

			case "ASSIGN_SUBS_CHECK", "ASSIGN_SUBS_I", "PASSIGN_SUBS" then
				operation[i] = routine_id("opASSIGN_SUBS")

			case "PLENGTH" then
				operation[i] = routine_id("opLENGTH")

			case "ELSE", "ENDWHILE", "RETRY" then
				operation[i] = routine_id("opEXIT")

			case "PLUS1_I" then
				operation[i] = routine_id("opPLUS1")

			case "PRIVATE_INIT_CHECK" then
				operation[i] = routine_id("opGLOBAL_INIT_CHECK")

			case "LHS_SUBS1", "LHS_SUBS1_COPY" then
				operation[i] = routine_id("opLHS_SUBS")

			case "PASSIGN_OP_SLICE" then
				operation[i] = routine_id("opASSIGN_OP_SLICE")

			case "PASSIGN_SLICE" then
				operation[i] = routine_id("opASSIGN_SLICE")

			case "PLUS_I" then
				operation[i] = routine_id("opPLUS")

			case "MINUS_I" then
				operation[i] = routine_id("opMINUS")

			case "SC1_AND_IF" then
				operation[i] = routine_id("opSC1_AND")

			case "SC1_OR_IF" then
				operation[i] = routine_id("opSC1_OR")

			case "SC2_AND" then
				operation[i] = routine_id("opSC2_OR")

			case "FOR_I" then
				operation[i] = routine_id("opFOR")

			-- assume only these two ENDFORs are emitted by the front end
			case "ENDFOR_INT_UP1" then
				operation[i] = routine_id("opENDFOR_GENERAL")

			case "CALL_FUNC" then
				operation[i] = routine_id("opCALL_PROC")

			case "PEEK4U", "PEEK4S", "PEEKS", "PEEK2U", "PEEK2S", "PEEK_STRING", 
				"PEEK8S", "PEEK8U", "PEEK_POINTER" then
				
				operation[i] = routine_id("opPEEK")

			case "POKE4", "POKE2", "POKE8", "POKE_POINTER" then
				operation[i] = routine_id("opPOKE")
			
			case "ABORT" then
				operation[i] = routine_id("opCLOSE")

			case "QPRINT" then
				operation[i] = routine_id("opPRINT")

			case "DISPLAY_VAR", "ERASE_PRIVATE_NAMES", "ERASE_SYMBOL", "NOP2" then
				operation[i] = routine_id("opPROFILE")

			case "SWITCH_SPI", "SWITCH_I" then
				operation[i] = routine_id("opSWITCH_I")

			case "ENDFOR_INT_UP",
			     "ENDFOR_UP",
			     "SC2_NULL",
			     "ENDFOR_DOWN",
			     "ENDFOR_INT_DOWN1",
			     "ASSIGN_SUBS2",
			     "PLATFORM",
			     "ENDFOR_INT_DOWN",
			     "END_PARAM_CHECK",
			     "PROC_FORWARD",
			     "FUNC_FORWARD",
			     "TYPE_CHECK_FORWARD",
				 "REF_TEMP",
				 "NOVALUE_TEMP",
				 "COVERAGE_LINE",
				 "COVERAGE_ROUTINE" then
				-- never emitted
				operation[i] = routine_id("opINTERNAL_ERROR")

			case "DELETE_ROUTINE" then
				operation[i] = routine_id("opDELETE_ROUTINE")

			case "DELETE_OBJECT" then
				operation[i] = routine_id("opDELETE_OBJECT")

			case "EXIT_BLOCK" then
				operation[i] = routine_id("opEXIT_BLOCK" )

			case "DEREF_TEMP" then
				operation[i] = routine_id("opDEREF_TEMP")

			case else
				operation[i] = -1
		end switch

		ifdef DEBUG then
		if operation[i] = -1 then
			InternalErr(255, { name })
		end if
		end ifdef

	end for
end procedure

procedure do_exec(integer start_pc)
-- generate code, starting at pc
	pc = start_pc
	loop_stack = {}
	label_map = {}
	all_done = FALSE
	map:clear( dead_temp_walking )
	if start_pc = 1 and CurrentSub != TopLevelSub then
		if match( {PROC_TAIL, CurrentSub}, Code ) != 0 then
			Label(1)
		end if
	end if

	while not all_done do
		previous_previous_op = previous_op
		previous_op = opcode
		opcode = Code[pc]
		-- default some vars
		target_type = TYPE_OBJECT
		target_val = novalue      -- integer value or sequence length
		target_elem = TYPE_OBJECT -- seqeunce element type
		atom_type = TYPE_ATOM
		intcode2 = ""
		dblfn = ""
		intcode_extra = ""
		ifdef DEBUG then
			c_stmt0( sprintf("// SubProg %s pc: %d op: %s (%d)\n", { SymTab[CurrentSub][S_NAME], pc, opnames[opcode], opcode }))
		end ifdef
		call_proc(operation[opcode], {})
	end while


end procedure

export procedure Execute(symtab_index proc)
-- top level executor

	CurrentSub = proc
	Code = SymTab[CurrentSub][S_CODE]

	do_exec(1)

	indent = 0
	temp_indent = 0
end procedure

Execute_id = routine_id("Execute")

constant hex_chars = "0123456789ABCDEF"

function hex_char(integer c)
-- return hex escape sequence for a char

	return "\\x" & hex_chars[1+floor(c/16)] & hex_chars[1+remainder(c, 16)]
end function

export function is_string( sequence s )
	for i = 1 to length(s) do
		if not integer(s[i]) or s[i] > 255  or s[i] <= 0 then
			return 0
		end if
	end for
	return 1
end function

export procedure escape_string( t:string string )
	integer use_hex = FALSE
	for elem = 1 to length(string) do
		if (string[elem] < 32 or string[elem] > 127) and
		   not find(string[elem], "\n\t\r") then
			use_hex = TRUE
			exit
		end if
	end for

	if use_hex then
		for elem = 1 to length(string) do
				c_puts(hex_char(string[elem]))
				if remainder(elem, 15) = 0 and elem < length(string) then
					c_puts("\"\n\"") -- start a new string chunk,
									-- avoid long line
				end if
		end for
	else
		for elem = 1 to length(string) do
			integer c = string[elem]
			if c = '\t' then
				c_puts("\\t")
			elsif c = '\n' then
				c_puts("\\n")
			elsif c = '\r' then
				c_puts("\\r")
			elsif c = '\"' then
				c_puts("\\\"")
			elsif c = '\\' then
				c_puts("\\\\")
			else
				c_putc(c)
			end if
		end for
	end if
end procedure

procedure init_string( symtab_index tp )
-- string
	sequence string

	string = SymTab[tp][S_OBJ]
	integer decompress = not is_string( string )

	if decompress then
		-- it's a more complex object, so we'll compress
		string = compress( string )
		c_stmt0("string_ptr = \"")
	else
		c_stmt0("_")
		c_printf("%d = NewString(\"", SymTab[tp][S_TEMP_NAME])
	end if

	escape_string( string )

	if decompress then
		c_printf("\";\n\t_%d = decompress( 0 );\n", SymTab[tp][S_TEMP_NAME])
	else
		c_puts("\");\n")
	end if
end procedure

--**
-- Translate the IL into C
procedure BackEnd(atom ignore)
	symtab_index tp
	sequence string, init_name, switches, cmd_switch
	integer tp_count, slash_ix
	integer max_len

	write_checksum( c_code )
	close(c_code)

	emit_c_output = FALSE

	slist = s_expand(slist)

	-- prevent conflicts
	for i = TopLevelSub+1 to length(SymTab) do
		if sequence(SymTab[i][S_NAME]) and  sym_mode( i ) = M_NORMAL and not find( sym_token( i ), { PROC, FUNC, TYPE} ) then --find( SymTab[i][S_TOKEN], {VARIABLE, CONSTANT, ENUM}) then
			SymTab[i][S_NAME] &= sprintf( "_%d", i )
		end if
	end for

	-- Perform Multiple Passes through the IL

	Pass = 0
	LAST_PASS = FALSE
	integer prev_updsym
	integer updsym = 0
	integer prev_unused_labels
	integer unused_labels = 0
	while not LAST_PASS do

		Pass += 1
		-- no output to .c files
		main_temps()

		-- walk through top-level, gathering type info
		Execute(TopLevelSub)

		-- walk through user-defined routines, gathering type info
		GenerateUserRoutines()

		DeclareRoutineList() -- forces routine_id target
							-- parameter type info to TYPE_OBJECT

		prev_updsym = updsym
		updsym = PromoteTypeInfo()    -- at very end after each FULL pass:
							-- promotes seq_elem_new, arg_type_new
							-- for all symbols
							-- sets U_DELETED, resets nrefs

		prev_unused_labels = unused_labels
		unused_labels = prune_labels() -- eliminate unused goto labels
		if updsym = prev_updsym and unused_labels = prev_unused_labels then
			LAST_PASS = TRUE
		end if
	end while

	-- Now, actually emit the C code */
	emit_c_output = TRUE

	c_code = open(output_dir & "main-.c", "w")
	if c_code = -1 then
		CompileErr(54)
	end if

	version()

	if TWINDOWS then
		-- this has to be included before stdint.h (in euphoria.h) at least on Watcom
		c_puts("#include <windows.h>\n")
	end if
	c_puts("#include <time.h>\n")
	c_puts("#include \"include/euphoria.h\"\n")
	c_puts("#include \"main-.h\"\n")
	c_puts("#include \"struct.h\"\n\n")

	if TUNIX then
		c_puts("#include <unistd.h>\n")
	end if
	c_puts("\n\n")
	c_puts("int Argc;\n")
	c_hputs("extern int Argc;\n")

	c_puts("char **Argv;\n")
	c_hputs("extern char **Argv;\n")

	if TWINDOWS then
		c_puts("HANDLE default_heap;\n")
		if sequence(wat_path) then
			c_puts("/* this is in the header */\n")
			c_puts("/*__declspec(dllimport) unsigned __stdcall GetProcessHeap(void)*/;\n")
		else
			c_puts("//\'test me!\' is this in the header?: unsigned __stdcall GetProcessHeap(void);\n")
		end if
	end if

	c_puts("uintptr_t *peekptr_addr;\n")
	c_hputs("extern uintptr_t *peekptr_addr;\n")
	
	c_puts("uint8_t *peek_addr;\n")
	c_hputs("extern uint8_t *peek_addr;\n")
	
	c_puts("uint16_t *peek2_addr;\n")
	c_hputs("extern uint16_t *peek2_addr;\n")
	
	c_puts("uint64_t *peek8_addr;\n")
	c_hputs("extern uint64_t *peek8_addr;\n")

	c_puts("uint32_t *peek4_addr;\n")
	c_hputs("extern uint32_t *peek4_addr;\n")

	c_puts("uint8_t *poke_addr;\n")
	c_hputs("extern uint8_t *poke_addr;\n")

	c_puts("uint16_t *poke2_addr;\n")
	c_hputs("extern uint16_t *poke2_addr;\n")

	c_puts("uint32_t *poke4_addr;\n")
	c_hputs("extern uint32_t *poke4_addr;\n")

	c_puts("uint64_t *poke8_addr;\n")
	c_hputs("extern uint64_t *poke8_addr;\n")
	
	c_puts("uintptr_t *pokeptr_addr;\n")
	c_hputs("extern uintptr_t *pokeptr_addr;\n")
	
	c_puts("struct d temp_d;\n")
	c_hputs("extern struct d temp_d;\n")

	c_puts("double temp_dbl;\n")
	c_hputs("extern double temp_dbl;\n")

	c_puts("char *stack_base;\n")
	c_hputs("extern char *stack_base;\n")
	
	c_puts("void init_literal();\n")

	if TWINDOWS and not dll_option then
			c_puts("extern long __stdcall Win_Machine_Handler(LPEXCEPTION_POINTERS p);\n")
	end if

	if total_stack_size = -1 then
		-- user didn't set the option
		if tasks_created then
			total_stack_size = (1016 + 8) * 1024
		else
			total_stack_size = (248 + 8) * 1024
		end if
	end if
	c_printf("int total_stack_size = %d;\n", total_stack_size)
	c_hputs("extern int total_stack_size;\n")

	if EXTRA_CHECK then
		c_hputs("extern long bytes_allocated;\n")
	end if

	if TWINDOWS then
		if dll_option then
			if sequence(wat_path) then
				c_stmt0("\nint __stdcall _CRT_INIT (int, int, void *);\n")
				c_stmt0("\n")
			end if
			c_stmt0("\nint EuInit()\n")  -- __declspec(dllexport) __stdcall
		else
			c_stmt0("\nint __stdcall WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR szCmdLine, int iCmdShow)\n")
		end if

	else -- TUNIX
		if dll_option then
			c_stmt0("\nint __attribute__ ((constructor)) eu_init()\n")
		else
			c_stmt0("\nint main(int argc, char *argv[])\n")
		end if
	end if
	c_stmt0("{\n")

	c_stmt0("s1_ptr _0switch_ptr;\n")


	main_temps()

	if TWINDOWS then
		if dll_option then
			c_stmt0("\nArgc = 0;\n")
			c_stmt0("default_heap = GetProcessHeap();\n")
			--c_stmt0("Backlink = bl;\n")
		else
			c_stmt0("int argc;\n")
			c_stmt0("char **argv;\n\n")
			c_stmt0("SetUnhandledExceptionFilter(Win_Machine_Handler);\n")
			c_stmt0("default_heap = GetProcessHeap();\n")
			c_stmt0("argc = 1;\n")
			c_stmt0("Argc = 1;\n")
			c_stmt0("argv = make_arg_cv(szCmdLine, &argc);\n")
			c_stmt0("winInstance = hInstance;\n")
		end if
	else --TUNIX
		if dll_option then
			c_stmt0("\nArgc = 0;\n")
		else
			c_stmt0("Argc = argc;\n")
			c_stmt0("Argv = argv;\n")
		end if

	end if

	if not dll_option then
		c_stmt0("stack_base = (char *)&_0;\n")
		c_stmt0("check_has_console();\n")
	end if

	-- include path initialization
	c_puts("\n")
	max_len = 0
	for i = 1 to length(file_include) do
		if length(file_include[i]) > max_len then
			max_len = length(file_include[i])
		end if
	end for
	c_stmt0(sprintf("_02 = (char**) malloc( sizeof( char* ) * %d );\n", length(file_include) + 1 ))
	c_stmt0("_02[0] = (char*) malloc( sizeof( char* ) );\n" )
	c_stmt0(sprintf("_02[0][0] = %d;\n", length(file_include) ))

	for i = 1 to length(include_matrix) do
		c_stmt0( sprintf( "_02[%d] = \"", i ) )
		escape_string( i & include_matrix[i] )
		c_puts( "\";\n" )
	end for
	
	c_puts("\n")

	-- fail safe mechanism in case
	-- Complete Edition library gets out by mistake
	if TWINDOWS then
		if atom(wat_path) then
			c_stmt0("eu_startup(_00, _01, _02, (object)CLOCKS_PER_SEC, (object)CLOCKS_PER_SEC);\n")
		else
			c_stmt0("eu_startup(_00, _01, _02, (object)CLOCKS_PER_SEC, (object)CLK_TCK);\n")
		end if
	else
		c_puts("#ifdef CLK_TCK\n")
		c_stmt0("eu_startup(_00, _01, _02, (object)CLOCKS_PER_SEC, (object)CLK_TCK);\n")
		c_puts("#else\n")
		c_stmt0("eu_startup(_00, _01, _02, (object)CLOCKS_PER_SEC, (object)sysconf(_SC_CLK_TCK));\n")
		c_puts("#endif\n")
	end if

	-- options_switch initialization
	switches = get_switches()
	c_stmt0(sprintf("_0switch_ptr = (s1_ptr) NewS1( %d );\n", length(switches) ))
	for i = 1 to length(switches) do
		cmd_switch = switches[i]
		slash_ix = 1
		if find('\\', cmd_switch) then
			while slash_ix <= length(cmd_switch) do
				if cmd_switch[slash_ix] = '\\' then
					if slash_ix = length(cmd_switch) then
						cmd_switch &= '\\'
					elsif cmd_switch[slash_ix+1] != '\\' then
						cmd_switch = cmd_switch[1..slash_ix] & '\\' & cmd_switch[slash_ix+1..$]
					end if
					slash_ix += 1
				end if
				slash_ix += 1
			end while
		end if
		c_stmt0(sprintf("_0switch_ptr->base[%d] = NewString(\"", i ) )
		escape_string( cmd_switch )
		c_stmt0("\");\n")
	end for
	c_stmt0( "_0switches = MAKE_SEQ( _0switch_ptr );\n")
	c_puts("\n")

	c_stmt0("init_literal();\n")

	if not dll_option then
		c_stmt0("shift_args(argc, argv);\n")
	end if

	-- Final walk through top-level code, constant and var initializations,
	-- outputing code

	Execute(TopLevelSub)

	indent = 4

	if dll_option then
		c_stmt0(";\n")
	else
		c_stmt0("Cleanup(0);\n")
	end if

	c_stmt0("return 0;\n}\n")

	if TWINDOWS then
	if dll_option then
		c_stmt0("\n")
		-- Lcc and WATCOM seem to need this instead
		-- (Lcc had __declspec(dllexport))
		c_stmt0("int __stdcall LibMain(int hDLL, int Reason, void *Reserved)\n")
		c_stmt0("{\n")
		c_stmt0("if (Reason == 1)\n")
		c_stmt0("EuInit();\n")
		c_stmt0("return 1;\n")
		c_stmt0("}\n")
	end if
	end if

	-- Final walk through user-defined routines, generating C code
	GenerateUserRoutines()  -- needs init_name_num

	write_checksum( c_code )
	close(c_code)

	c_code = open(output_dir & "init-.c", "a")
	if c_code = -1 then
		CompileErr(53)
	end if

-- declare all *used* constants, and local and global variables as ints

	-- writing to init-.c

	DeclareFileVars()
	DeclareRoutineList()
	DeclareNameSpaceList()

	c_stmt0("void init_literal()\n{\n")
	c_stmt0("extern char *string_ptr;\n")
	c_stmt0("extern double sqrt();\n")
	c_stmt0("setran(); /* initialize random generator seeds */\n")

	-- initialize the (non-integer) literals
	tp = literal_init
	tp_count = 0

	while tp != 0 do

		if tp_count > INIT_CHUNK then
			-- close current .c and start a new one
			c_stmt0("init_literal")
			c_printf("%d();\n", init_name_num)
			c_stmt0("}\n")
			init_name = sprintf("init-%d", init_name_num)
			new_c_file(init_name)
			add_file(init_name)
			c_stmt0("init_literal")
			c_printf("%d()\n", init_name_num)
			c_stmt0("{\n")
			c_stmt0("extern double sqrt();\n")
			c_stmt0("extern char *string_ptr;\n")
			init_name_num += 1
			tp_count = 0
		end if

		if atom(SymTab[tp][S_OBJ]) then -- can't be NOVALUE
			-- double
			c_stmt0("_")
			c_printf("%d = NewDouble((eudouble)", SymTab[tp][S_TEMP_NAME])
			c_printf8(SymTab[tp][S_OBJ])
			c_puts(");\n")
		else
			init_string( tp )
		end if
		tp = SymTab[tp][S_NEXT]
		tp_count += 1
	end while

	for csym = TopLevelSub to length(SymTab) do
		if eu:compare( SymTab[csym][S_OBJ], NOVALUE ) then
		if not is_integer( SymTab[csym][S_OBJ] )
		or TYPE_DOUBLE = SymTab[csym][S_GTYPE] then
		if SymTab[csym][S_MODE] != M_TEMP then
			if tp_count > INIT_CHUNK then
				-- close current .c and start a new one
				c_stmt0("init_literal")
				c_printf("%d();\n", init_name_num)
				c_stmt0("}\n")
				init_name = sprintf("init-%d", init_name_num)
				new_c_file(init_name)
				add_file(init_name)
				c_stmt0("init_literal")
				c_printf("%d()\n", init_name_num)
				c_stmt0("{\n")
				c_stmt0("extern double sqrt();\n")
				init_name_num += 1
				tp_count = 0
			end if

			-- non-integer constant
			if sequence( SymTab[csym][S_OBJ] ) then
				string = SymTab[csym][S_OBJ]
				integer decompress = not is_string( string )

				if decompress then
					-- it's a more complex object, so we'll compress
					string = compress( string )
					c_stmt0("string_ptr = \"")
				else
					c_printf( "\t_%d", SymTab[csym][S_FILE_NO] )
					c_puts( SymTab[csym][S_NAME] )
					c_puts(" = NewString(\"" )
				end if

				escape_string( string )

				if decompress then
					c_printf( "\";\n\t_%d", SymTab[csym][S_FILE_NO] )
					c_puts( SymTab[csym][S_NAME] )
					c_printf(" = decompress( 0 );\n", SymTab[csym][S_TEMP_NAME])
				else
					c_puts("\");\n")
				end if
			else
				c_printf( "\t_%d", SymTab[csym][S_FILE_NO] )
				c_puts( SymTab[csym][S_NAME] )
				c_printf( " = NewDouble( %0.20fL );\n", SymTab[csym][S_OBJ] )
			end if

			tp_count += 1
		end if
		end if
		end if
	end for
	c_stmt0("}\n")


	if TWINDOWS then
		c_hputs("extern void *winInstance;\n\n")
	end if

	close(c_code)
	close(c_h)
	
	write_struct_header()

	write_buildfile()
end procedure
mode:set_backend( routine_id("BackEnd") )

procedure OutputIL()
-- not used
end procedure
set_output_il( routine_id("OutputIL" ))


