-- (c) Copyright - See License.txt
--
----------------------------------------------------------------------------
--                                                                        --
--       Translator Declarations and Support Routines                     --
--                                                                        --
----------------------------------------------------------------------------

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include euphoria/info.e

include std/datetime.e
include std/filesys.e
include std/math.e
include std/os.e
include std/text.e

include buildsys.e
include global.e
include platform.e
include reswords.e
include symtab.e
include compile.e
include error.e
include c_out.e
include msgtext.e

--**
-- number of Translator passes

export integer LAST_PASS = FALSE

--**
-- the current pass number

export integer Pass

export enum
	--**
	-- the var / type / constant
	BB_VAR,

	--**
	-- main type
	BB_TYPE,

	--**
	-- element type for sequences
	BB_ELEM,

	--**
	-- sequence length
	BB_SEQLEN,

	--**
	-- integer value min/max
	BB_OBJ,

	--**
	-- may have a delete routine
	BB_DELETE

--**
-- What we currently know locally in this basic block about var values etc.
--
-- See Also:
-- [[:BB_VAR]], [[:BB_TYPE]], [[:BB_ELEM]], [[:BB_SEQLEN]], [[:BB_OBJ]], [[:BB_DELETE]]

export sequence BB_info = {}

export integer LeftSym = FALSE   -- to force name to appear, not value

export boolean
	dll_option = FALSE,
	con_option = FALSE

--**
-- Sequence to contain files that are generated and should be delt with
-- when creating a build file and/or removed when done compiling.

export sequence generated_files = {}

--**
-- Sequence to contain a boolean flag for each generated file to indicate
-- if the file is out of date or current.

export sequence outdated_files = {}

--**
-- Flag to determine if the source files should be kept or deleted
-- when a compile is finished.

export boolean keep = FALSE

--**
-- Debug mode is enabled. This should affect the build process.

export boolean debug_option = FALSE

--**
-- If not-empty, then the build file should link against user_library
-- not the standard %EUDIR%/bin/eu.lib file.

export sequence user_library = ""

--**
-- If not-empty, then the build file should link against user_pic_library
-- when building a shared object.  Used for gcc.

export sequence user_pic_library = ""

--**
-- Write all generated files to this directory.

export sequence output_dir = ""

--**
-- Stack size (used in Watcom only).

export integer total_stack_size = -1 -- default size for OPTION STACK

--**
-- first check ##EUCOMPILEDIR##, to allow the user to override and use a
-- different directory than ##EUDIR##. THen use ##EUDIR##, then default
-- to ##/usr/share/euphoria##

export function get_eucompiledir()
	object x = getenv("EUCOMPILEDIR")
	if is_eudir_from_cmdline() then
		x = get_eudir()
	end if

	ifdef UNIX then
		if equal(x, -1) then
			x = "/usr/local/share/euphoria"
			if not file_exists( x ) then
				-- somewhat hacky, but covers the default (and obvious)
				-- other place to look
				x = "/usr/share/euphoria"
				if not file_exists( x ) then
					x = -1
				end if
			end if
		end if
	end ifdef

	if equal(x, -1) then
		x = get_eudir()
	end if

	return x
end function

--**
-- Start a new Basic Block at a label or after a subroutine call
--

export procedure NewBB(integer a_call, integer mask, symtab_index sub)
	symtab_index s

	if a_call then
		-- Forget what we know about local & global var values,
		-- but remember that they were initialized
		for i = 1 to length(BB_info) do
			s = BB_info[i][BB_VAR]
			if SymTab[s][S_MODE] = M_NORMAL and
				(SymTab[s][S_SCOPE] = SC_GLOBAL or
				 SymTab[s][S_SCOPE] = SC_LOCAL  or
				 SymTab[s][S_SCOPE] = SC_EXPORT or
				 SymTab[s][S_SCOPE] = SC_PUBLIC ) then
				  if and_bits(mask, power(2, remainder(s, E_SIZE))) then
					  if mask = E_ALL_EFFECT or s < sub then
						  BB_info[i][BB_TYPE..BB_OBJ] =
							{TYPE_NULL, TYPE_NULL, NOVALUE, {MININT, MAXINT}}
					  end if
				  end if
			end if
		end for
	else
		-- Label: forget what we know about all temp and var types
		BB_info = {}
	end if
end procedure

--**
-- Return the local min/max value of an integer, based on BB info.
constant BB_def_values = {NOVALUE, NOVALUE}
export function BB_var_obj(integer var)
	object bbi

	for i = length(BB_info) to 1 by -1 do
		bbi = BB_info[i]
		if bbi[BB_VAR] != var then
			continue
		end if

		if SymTab[var][S_MODE] != M_NORMAL then
			continue
		end if

		if bbi[BB_TYPE] != TYPE_INTEGER then
			exit
		end if

		return bbi[BB_OBJ]
	end for
	return BB_def_values
end function

--**
-- Return the local type of a var, based on BB info (only)
export function BB_var_type(integer var)
	for i = length(BB_info) to 1 by -1 do
		if BB_info[i][BB_VAR] = var and
		   SymTab[BB_info[i][BB_VAR]][S_MODE] = M_NORMAL then
			ifdef DEBUG then
			if BB_info[i][BB_TYPE] < 0 or
			   BB_info[i][BB_TYPE] > TYPE_OBJECT then
				InternalErr(256)
			end if
			end ifdef

			if BB_info[i][BB_TYPE] = TYPE_NULL then  -- var has only been read
				return TYPE_OBJECT
			else
				return BB_info[i][BB_TYPE]
			end if
		end if
	end for
	return TYPE_OBJECT
end function

--**
-- Return our best estimate of the current type of a var or temp
export function GType(symtab_index s)
	integer t, local_t

	t = SymTab[s][S_GTYPE]
	ifdef DEBUG then
	if t < 0 or t > TYPE_OBJECT then
		InternalErr(257)
	end if
	end ifdef

	if SymTab[s][S_MODE] != M_NORMAL then
		return t
	end if
	-- check local BB info for vars only
	local_t = BB_var_type(s)
	if local_t = TYPE_OBJECT then
		return t
	end if
	if t = TYPE_INTEGER then
		return TYPE_INTEGER
	end if
	return local_t
end function

integer
	g_has_delete = 0,
	p_has_delete = 0

export function GDelete()
	return g_has_delete
end function

export function HasDelete( symtab_index s )

	for i = length(BB_info) to 1 by -1 do
		if BB_info[i][BB_VAR] = s then
			return BB_info[i][BB_DELETE]
		end if
	end for
	if length(SymTab[s]) < S_HAS_DELETE then
		return 0
	end if
	return SymTab[s][S_HAS_DELETE]
end function

--**
-- the value of an integer constant or variable
export function ObjValue(symtab_index s)
	sequence local_t
	object st
	atom tmin
	atom tmax

	st = SymTab[s]
	tmin = st[S_OBJ_MIN]
	tmax = st[S_OBJ_MAX]

	if tmin != tmax then
		tmin = NOVALUE
	end if
	if st[S_MODE] != M_NORMAL then
		return tmin
	end if

	-- check local BB info for vars only
	local_t = BB_var_obj(s)
	if local_t[MIN] = NOVALUE then
		return tmin
	end if

	if local_t[MIN] != local_t[MAX] then
		return tmin
	end if

	return local_t[MIN]

end function

export function TypeIs(integer x, integer typei)
	return GType(x) = typei
end function

export function TypeIsIn(integer x, sequence types)
	return find(GType(x), types)
end function

export function TypeIsNot(integer x, integer typei)
	return GType(x) != typei
end function

export function TypeIsNotIn(integer x, sequence types)
	return not find(GType(x), types)
end function

--**
-- OR two types to get the (least general) type that includes both
export function or_type(integer t1, integer t2)
	if t1 = TYPE_NULL then
		return t2

	elsif t2 = TYPE_NULL then
		return t1

	elsif t1 = TYPE_OBJECT or t2 = TYPE_OBJECT then
		return TYPE_OBJECT

	elsif t1 = TYPE_SEQUENCE then
		if t2 = TYPE_SEQUENCE then
			return TYPE_SEQUENCE
		else
			return TYPE_OBJECT
		end if

	elsif t2 = TYPE_SEQUENCE then
		if t1 = TYPE_SEQUENCE then
			return TYPE_SEQUENCE
		else
			return TYPE_OBJECT
		end if

	elsif t1 = TYPE_ATOM or t2 = TYPE_ATOM then
		return TYPE_ATOM

	elsif t1 = TYPE_DOUBLE then
		if t2 = TYPE_INTEGER then
			return TYPE_ATOM
		else
			return TYPE_DOUBLE
		end if

	elsif t2 = TYPE_DOUBLE then
		if t1 = TYPE_INTEGER then
			return TYPE_ATOM
		else
			return TYPE_DOUBLE
		end if

	elsif t1 = TYPE_INTEGER and t2 = TYPE_INTEGER then
		return TYPE_INTEGER

	else
		InternalErr(258, {t1, t2})

	end if
end function

export procedure RemoveFromBB( symtab_index s )
	integer int
	for i = 1 to length(BB_info) do
		int = BB_info[i][BB_VAR]
		if int = s then
			BB_info = remove( BB_info, int )
			return
		end if
	end for
end procedure

--**
-- Set the type and value, or sequence length and element type,
-- of a temp or var s locally within a BB.
--
-- Parameters:
--   # ##s##: The symbol whose type is being recorded
--   # ##t##: the type
--   # ##val##: is either the integer min & max values, or the length of a
--     sequence in min, or -1 if we are to just OR-in the etype.
--   # ##etype##: is the element type of a sequence or object. If an object is
--     subscripted or sliced that shows that it's a sequence in that instance,
--     and its element type can be used.
--   # ##has_delete##: is 1 if the object might have a delete routine attached,
-- 	   or 0 if not if has_delete then ? 1/0 end if
constant dummy_bb = {0, TYPE_NULL, TYPE_OBJECT, NOVALUE, {MININT, MAXINT}, 0}
export procedure SetBBType(symtab_index s, integer t, sequence val, integer etype, integer has_delete )
	integer found, i, tn, int
	sequence sym
	
	if has_delete then
		p_has_delete = 1
		g_has_delete = 1
	end if

	sym = SymTab[s]
	SymTab[s] = 0
	
	integer mode = sym[S_MODE]
	if mode = M_NORMAL or mode = M_TEMP  then
		-- A variable of some sort.
		found = FALSE
		if mode = M_TEMP then
			sym[S_GTYPE] = t
			sym[S_SEQ_ELEM] = etype
			integer gtype = sym[S_GTYPE]
			if gtype = TYPE_OBJECT
			or gtype = TYPE_SEQUENCE 
			then
				if val[MIN] < 0 then
					sym[S_SEQ_LEN] = NOVALUE
				else
					sym[S_SEQ_LEN] = val[MIN]
				end if
				sym[S_OBJ] = NOVALUE
				
				sym[S_OBJ_MIN] = NOVALUE
				sym[S_OBJ_MAX] = NOVALUE
			else
				sym[S_OBJ_MIN] = val[MIN]
				sym[S_OBJ_MAX] = val[MAX]
				sym[S_SEQ_LEN] = NOVALUE
			end if
			if not Initializing then
				integer new_type = or_type(temp_name_type[sym[S_TEMP_NAME]][T_GTYPE_NEW], t)
				if new_type = TYPE_NULL then
					new_type = TYPE_OBJECT
				end if
				temp_name_type[sym[S_TEMP_NAME]][T_GTYPE_NEW] = new_type
-- 				   or_type(temp_name_type[sym[S_TEMP_NAME]][T_GTYPE_NEW], t)

			end if
			tn = sym[S_TEMP_NAME]
			i = 1
			while i <= length(BB_info) do
				sequence bbsym
				int = BB_info[i][BB_VAR]
				if int = s then
					bbsym = sym
				else
					bbsym = SymTab[int]
				end if
				int = bbsym[S_MODE]
				if int = M_TEMP then
					int = bbsym[S_TEMP_NAME]
					if int = tn then
						found = TRUE
						exit
					end if
				end if
				i += 1
			end while
		 else   -- M_NORMAL
			if t != TYPE_NULL then
				if not Initializing then
					sym[S_GTYPE_NEW] = or_type(sym[S_GTYPE_NEW], t)
				end if

				if t = TYPE_SEQUENCE then
					sym[S_SEQ_ELEM_NEW] =
							  or_type(sym[S_SEQ_ELEM_NEW], etype)
					-- treat val.min as sequence length
					if val[MIN] != -1 then
						if sym[S_SEQ_LEN_NEW] = -NOVALUE then
							if val[MIN] < 0 then
								sym[S_SEQ_LEN_NEW] = NOVALUE
							else
								sym[S_SEQ_LEN_NEW] = val[MIN]
							end if
						elsif val[MIN] != sym[S_SEQ_LEN_NEW] then
							sym[S_SEQ_LEN_NEW] = NOVALUE
						end if
					end if

				elsif t = TYPE_INTEGER then
					-- treat val as integer value */
					if sym[S_OBJ_MIN_NEW] = -NOVALUE then
						-- first known value assigned in this pass */
						sym[S_OBJ_MIN_NEW] = val[MIN]
						sym[S_OBJ_MAX_NEW] = val[MAX]

					elsif sym[S_OBJ_MIN_NEW] != NOVALUE then
						-- widen the range */
						if val[MIN] < sym[S_OBJ_MIN_NEW] then
							sym[S_OBJ_MIN_NEW] = val[MIN]
						end if
						if val[MAX] > sym[S_OBJ_MAX_NEW] then
							sym[S_OBJ_MAX_NEW] = val[MAX]
						end if
					end if

				else
					sym[S_OBJ_MIN_NEW] = NOVALUE
					if t = TYPE_OBJECT then
						-- for objects, we record element type, if provided,
						-- but we don't try to record integer value or seq len
						sym[S_SEQ_ELEM_NEW] =
								 or_type(sym[S_SEQ_ELEM_NEW], etype)
						sym[S_SEQ_LEN_NEW] = NOVALUE
					end if
				end if
			end if

			i = 1
			while i <= length(BB_info) do
				int = BB_info[i][BB_VAR]
				if int = s then
					found = TRUE
					exit
				end if
				i += 1
			end while

		end if

		if not found then
			-- add space for a new entry
			BB_info = append(BB_info, repeat(0, 6))
		end if

		if t = TYPE_NULL then
			if not found then
				-- add read-only dummy reference
				BB_info[i] = dummy_bb
				BB_info[i][BB_VAR] = s
			end if
			-- don't record anything if the var already exists in this BB
		else
			sequence bbi = BB_info[i]
			BB_info[i] = 0
			bbi[BB_VAR] = s
			bbi[BB_TYPE] = t
			bbi[BB_DELETE] = has_delete
			-- etype shouldn't matter if the var is not a sequence here
			if t = TYPE_SEQUENCE and val[MIN] = -1 then
				-- assign to subscript or slice of a sequence
				if found and bbi[BB_ELEM] != TYPE_NULL then
					--kludge:
					bbi[BB_ELEM] = or_type(bbi[BB_ELEM], etype)
				else
					bbi[BB_ELEM] = TYPE_NULL
				end if
				if not found then
					bbi[BB_SEQLEN] = NOVALUE
				end if
			else
				bbi[BB_ELEM] = etype
				if t = TYPE_SEQUENCE or t = TYPE_OBJECT then
					if val[MIN] < 0 then
						bbi[BB_SEQLEN] = NOVALUE
					else
						bbi[BB_SEQLEN] = val[MIN]
					end if
				else
					bbi[BB_OBJ] = val
				end if
			end if
			BB_info[i] = bbi
		end if

	elsif mode = M_CONSTANT then
		sym[S_GTYPE] = t
		sym[S_SEQ_ELEM] = etype
		if sym[S_GTYPE] = TYPE_SEQUENCE or
		   sym[S_GTYPE] = TYPE_OBJECT then
			if val[MIN] < 0 then
				sym[S_SEQ_LEN] = NOVALUE
			else
				sym[S_SEQ_LEN] = val[MIN]
			end if
		else
			sym[S_OBJ_MIN] = val[MIN]
			sym[S_OBJ_MAX] = val[MAX]
		end if
		sym[S_HAS_DELETE] = has_delete
	end if
	
	SymTab[s] = sym
	
end procedure

--**
-- display the C name or literal value of an operand
export procedure CName(symtab_index s)
	object v

	v = ObjValue(s)
	integer mode = SymTab[s][S_MODE]
 	if mode = M_NORMAL then
		-- declared user variables

		if LeftSym = FALSE and GType(s) = TYPE_INTEGER and v != NOVALUE then
			c_printf("%d", v)
			if SIZEOF_POINTER = 8 then
				c_puts( "LL" )
			end if
		else
			if SymTab[s][S_SCOPE] > SC_PRIVATE then
				c_printf("_%d", SymTab[s][S_FILE_NO])
				c_puts(SymTab[s][S_NAME])
			else
				c_puts("_")
				c_puts(SymTab[s][S_NAME])
			end if
		end if
		if s != CurrentSub and SymTab[s][S_NREFS] < 2 then
			SymTab[s][S_NREFS] += 1
		end if
		SetBBType(s, TYPE_NULL, novalue, TYPE_OBJECT, 0) -- record that this var was referenced in this BB

 	elsif mode = M_CONSTANT then
		-- literal integers, or declared constants
		if (is_integer( sym_obj( s ) ) and SymTab[s][S_GTYPE] != TYPE_DOUBLE ) or (LeftSym = FALSE and TypeIs(s, TYPE_INTEGER) and v != NOVALUE) then
			-- integer: either literal, or
			-- declared constant rvalue with integer value
			c_printf("%d", v)
			if SIZEOF_POINTER = 8 then
				c_puts( "LL" )
			end if
		else
			-- Declared constant
			c_printf("_%d", SymTab[s][S_FILE_NO])
			c_puts(SymTab[s][S_NAME])
			if SymTab[s][S_NREFS] < 2 then
				SymTab[s][S_NREFS] += 1
			end if
		end if

 	else   -- M_TEMP
		-- literal doubles, strings, temporary vars that we create
		if LeftSym = FALSE and GType(s) = TYPE_INTEGER and v != NOVALUE then
			c_printf("%d", v)
			if SIZEOF_POINTER = 8 then
				c_puts( "LL" )
			end if
		else
			c_printf("_%d", SymTab[s][S_TEMP_NAME])
		end if
 	end if

	LeftSym = FALSE
end procedure
with warning

--**
-- output a C statement with replacements for @ or @1 @2 @3, ... @9
export procedure c_stmt(sequence stmt, object arg, symtab_index lhs_arg = 0)
	integer argcount, i

	if LAST_PASS = TRUE and Initializing = FALSE then
		cfile_size += 1
		update_checksum( stmt )

	end if

	if emit_c_output then
		adjust_indent_before(stmt)
	end if

	if atom(arg) then
		arg = {arg}
	end if

	argcount = 1
	i = 1
	while i <= length(stmt) and length(stmt) > 0 do
		if stmt[i] = '@' then
			-- argument detected
			if i = 1 then
				LeftSym = TRUE
			end if

			if i < length(stmt) and stmt[i+1] > '0' and stmt[i+1] <= '9' then
				-- numbered argument
				if arg[stmt[i+1]-'0'] = lhs_arg then
					LeftSym = TRUE
				end if
				CName(arg[stmt[i+1]-'0'])
				i += 1

			else
				-- plain argument
				if arg[argcount] = lhs_arg then
					LeftSym = TRUE
				end if
				CName(arg[argcount])

			end if
			argcount += 1

		else
			c_putc(stmt[i])
			if stmt[i] = '&' and i < length(stmt) and stmt[i+1] = '@' then
				LeftSym = TRUE -- never say: x = x &y or andy - always leave space
			end if
		end if

		if stmt[i] = '\n' and i < length(stmt) then
			if emit_c_output then
				adjust_indent_after(stmt)
			end if
			stmt = stmt[i+1..$]
			i = 0
			if emit_c_output then
				adjust_indent_before(stmt)
			end if
		end if

		i += 1
	end while

	if emit_c_output then
		adjust_indent_after(stmt)
	end if
end procedure

--**
-- output a C statement with no arguments
export procedure c_stmt0(sequence stmt)
	if emit_c_output then
		c_stmt(stmt, {})
	end if
end procedure

--**
-- emit C declaration for each local and global constant and var
export procedure DeclareFileVars()
	symtab_index s
	symtab_entry eentry

	c_puts("// Declaring file vars\n")
	s = SymTab[TopLevelSub][S_NEXT]
	while s do
		eentry = SymTab[s]
		if eentry[S_SCOPE] >= SC_LOCAL
		and (eentry[S_SCOPE] <= SC_GLOBAL or eentry[S_SCOPE] = SC_EXPORT or eentry[S_SCOPE] = SC_PUBLIC)
		and eentry[S_USAGE] != U_UNUSED
		and eentry[S_USAGE] != U_DELETED
		and not find(eentry[S_TOKEN], RTN_TOKS) then

			if eentry[S_TOKEN] = PROC then
				c_puts( "void ")
			else
				c_puts("object ")
			end if
			c_printf("_%d", eentry[S_FILE_NO])
			c_puts(eentry[S_NAME])
			if is_integer( eentry[S_OBJ] ) then
					c_printf(" = %d%s;\n", { eentry[S_OBJ], LL_suffix} )
			else
				c_puts(" = NOVALUE;\n")
			end if

			c_hputs("extern object ")
			c_hprintf("_%d", eentry[S_FILE_NO])
			c_hputs(eentry[S_NAME])

			c_hputs(";\n")
		end if
		s = SymTab[s][S_NEXT]
	end while
	c_puts("\n")
	c_hputs("\n")
end procedure

integer deleted_routines = 0

--**
-- at the end of each pass, certain info becomes valid
export function PromoteTypeInfo()
	integer updsym
	symtab_index s
	sequence sym, symo

	updsym = 0
	g_has_delete = p_has_delete
	s = SymTab[TopLevelSub][S_NEXT]
	while s do
		sym = SymTab[s]
		symo = sym
		if sym[S_TOKEN] = FUNC or sym[S_TOKEN] = TYPE then
			if sym[S_GTYPE_NEW] = TYPE_NULL then
				sym[S_GTYPE] = TYPE_OBJECT
			else
				sym[S_GTYPE] = sym[S_GTYPE_NEW]
			end if
		else
			-- variables: promote gtype_new only if it's better than gtype
			-- user may have declared it better than we can determine.
			if sym[S_GTYPE] != TYPE_INTEGER and
				sym[S_GTYPE_NEW] != TYPE_OBJECT and
				sym[S_GTYPE_NEW] != TYPE_NULL then
				if sym[S_GTYPE_NEW] = TYPE_INTEGER or
				   sym[S_GTYPE] = TYPE_OBJECT or
				   (sym[S_GTYPE] = TYPE_ATOM and
					sym[S_GTYPE_NEW] = TYPE_DOUBLE) then
						sym[S_GTYPE] = sym[S_GTYPE_NEW]
				end if
			end if
			if sym[S_ARG_TYPE_NEW] = TYPE_NULL then
				sym[S_ARG_TYPE] = TYPE_OBJECT
			else
				sym[S_ARG_TYPE] = sym[S_ARG_TYPE_NEW]
			end if
			sym[S_ARG_TYPE_NEW] = TYPE_NULL

			if sym[S_ARG_SEQ_ELEM_NEW] = TYPE_NULL then
				sym[S_ARG_SEQ_ELEM] = TYPE_OBJECT
			else
				sym[S_ARG_SEQ_ELEM] = sym[S_ARG_SEQ_ELEM_NEW]
			end if
			sym[S_ARG_SEQ_ELEM_NEW] = TYPE_NULL

			if sym[S_ARG_MIN_NEW] = -NOVALUE or
			   sym[S_ARG_MIN_NEW] = NOVALUE then
				sym[S_ARG_MIN] = MININT
				sym[S_ARG_MAX] = MAXINT
			else
				sym[S_ARG_MIN] = sym[S_ARG_MIN_NEW]
				sym[S_ARG_MAX] = sym[S_ARG_MAX_NEW]
			end if
			sym[S_ARG_MIN_NEW] = -NOVALUE

			if sym[S_ARG_SEQ_LEN_NEW] = -NOVALUE then
				sym[S_ARG_SEQ_LEN] = NOVALUE
			else
				sym[S_ARG_SEQ_LEN] = sym[S_ARG_SEQ_LEN_NEW]
			end if
			sym[S_ARG_SEQ_LEN_NEW] = -NOVALUE
		end if

		sym[S_GTYPE_NEW] = TYPE_NULL

		if sym[S_SEQ_ELEM_NEW] = TYPE_NULL then
		   sym[S_SEQ_ELEM] = TYPE_OBJECT
		else
			sym[S_SEQ_ELEM] = sym[S_SEQ_ELEM_NEW]
		end if
		sym[S_SEQ_ELEM_NEW] = TYPE_NULL

		if sym[S_SEQ_LEN_NEW] = -NOVALUE then
			sym[S_SEQ_LEN] = NOVALUE
		else
			sym[S_SEQ_LEN] = sym[S_SEQ_LEN_NEW]
		end if
		sym[S_SEQ_LEN_NEW] = -NOVALUE

		if sym[S_TOKEN] != NAMESPACE
		and sym[S_MODE] != M_CONSTANT then

			if sym[S_OBJ_MIN_NEW] = -NOVALUE or
			   sym[S_OBJ_MIN_NEW] = NOVALUE then
				sym[S_OBJ_MIN] = MININT
				sym[S_OBJ_MAX] = MAXINT
			else
				sym[S_OBJ_MIN] = sym[S_OBJ_MIN_NEW]
				sym[S_OBJ_MAX] = sym[S_OBJ_MAX_NEW]
			end if
		end if
		sym[S_OBJ_MIN_NEW] = -NOVALUE

		if sym[S_NREFS] = 1 and
		   find(sym[S_TOKEN], RTN_TOKS) then
			if sym[S_USAGE] != U_DELETED then
				sym[S_USAGE] = U_DELETED
				deleted_routines += 1
			end if
		end if
		sym[S_NREFS] = 0
		if not equal(symo, sym) then
			SymTab[s] = sym
			updsym += 1
		end if
		s = sym[S_NEXT]
	end while

	-- global temp information
	for i = 1 to length(temp_name_type) do
		integer upd = 0
		-- could be TYPE_NULL if temp is never assigned a value, i.e. not used
		if temp_name_type[i][T_GTYPE] != temp_name_type[i][T_GTYPE_NEW] then
			temp_name_type[i][T_GTYPE] = temp_name_type[i][T_GTYPE_NEW]
			upd = 1
		end if
		if temp_name_type[i][T_GTYPE_NEW] != TYPE_NULL then
			temp_name_type[i][T_GTYPE_NEW] = TYPE_NULL
			upd = 1
		end if
		updsym += upd
	end for

	return updsym
end function

procedure declare_prototype( symtab_index s )
	sequence ret_type
	if sym_token( s ) = PROC then
		ret_type = "void "
	else
		ret_type ="object "
	end if

	c_hputs(ret_type)
	
	
	if dll_option and TWINDOWS  then
		integer scope = SymTab[s][S_SCOPE]
		if (scope = SC_PUBLIC
			or scope = SC_EXPORT
			or scope = SC_GLOBAL)
		then
			-- declare the global routine as an exported DLL function
			c_hputs("__stdcall ")
		end if
	end if
	
	c_hprintf("_%d", SymTab[s][S_FILE_NO])
	c_hputs(SymTab[s][S_NAME])
	c_hputs("(")
	
	for i = 1 to SymTab[s][S_NUM_ARGS] do
		if i = 1 then
			c_hputs("object")
		else
			c_hputs(", object")
		end if
	end for
	c_hputs(");\n")
end procedure

procedure add_to_routine_list( symtab_index s, integer seq_num, integer first )
	if not first then
		c_puts(",\n")
	end if
	
	c_puts("  {\"")

	c_puts(SymTab[s][S_NAME])
	c_puts("\", ")
	c_puts("(object (*)())")
	c_printf("_%d", SymTab[s][S_FILE_NO])
	c_puts(SymTab[s][S_NAME])
	c_printf(", %d", seq_num)
	c_printf(", %d", SymTab[s][S_FILE_NO])
	c_printf(", %d", SymTab[s][S_NUM_ARGS])

	if TWINDOWS and dll_option and find( SymTab[s][S_SCOPE], { SC_GLOBAL, SC_EXPORT, SC_PUBLIC} ) then
		c_puts(", 1")  -- must call with __stdcall convention
	else
		c_puts(", 0")  -- default: call with normal or __cdecl convention
	end if

	c_printf(", %d, 0", SymTab[s][S_SCOPE] )
	c_puts("}")

	if SymTab[s][S_NREFS] < 2 then
		SymTab[s][S_NREFS] = 2 --s->nrefs++
	end if

	-- all bets are off:
	-- set element type and arg type of parameters to TYPE_OBJECT
	symtab_index p = SymTab[s][S_NEXT]
	for i = 1 to SymTab[s][S_NUM_ARGS] do
		SymTab[p][S_ARG_SEQ_ELEM_NEW] = TYPE_OBJECT
		SymTab[p][S_ARG_TYPE_NEW] = TYPE_OBJECT
		SymTab[p][S_ARG_MIN_NEW] = NOVALUE
		SymTab[p][S_ARG_SEQ_LEN_NEW] = NOVALUE
		p = SymTab[p][S_NEXT]
	end for
end procedure

--**
-- Declare the list of routines for routine_id search
export procedure DeclareRoutineList()
	symtab_index s
	integer first, seq_num

	c_hputs("extern struct routine_list _00[];\n")
	
	check_file_routines()
	for f = 1 to length( file_routines ) do
		sequence these_routines = file_routines[f]
		for r = 1 to length( these_routines ) do
			s = these_routines[r]
			if SymTab[s][S_USAGE] != U_DELETED then
			
				declare_prototype( s )
				
			end if
		end for
	end for
	c_puts("\n")

	-- add all possible routine_id targets to the routine list
	seq_num = 0
	first = TRUE
	c_puts("struct routine_list _00[] = {\n")

	for f = 1 to length( file_routines ) do
		sequence these_routines = file_routines[f]
		for r = 1 to length( these_routines ) do
			s = these_routines[r]
			if SymTab[s][S_RI_TARGET] then
				
				add_to_routine_list( s, seq_num, first )
				first = FALSE
				
			end if
			seq_num += 1
		end for
	end for
	if not first then
		c_puts(",\n")
	end if
	c_puts("  {\"\", 0, 999999999, 0, 0, 0, 0}\n};\n\n")  -- end marker

	c_hputs("extern char ** _02;\n")
	c_puts("char ** _02;\n")

	c_hputs("extern object _0switches;\n")
	c_puts("object _0switches;\n")
end procedure

--**
-- Declare the list of namespace qualifiers for routine_id search
export procedure DeclareNameSpaceList()
	symtab_index s
	integer first, seq_num

	c_hputs("extern struct ns_list _01[];\n")
	c_puts("struct ns_list _01[] = {\n")

	seq_num = 0
	first = TRUE

	s = SymTab[TopLevelSub][S_NEXT]
	while s do
		if find(SymTab[s][S_TOKEN], NAMED_TOKS) then
			if SymTab[s][S_TOKEN] = NAMESPACE then
				if not first then
					c_puts(",\n")
				end if
				first = FALSE

				c_puts("  {\"")
				c_puts(SymTab[s][S_NAME])
				c_printf("\", %d", SymTab[s][S_OBJ])
				c_printf(", %d", seq_num)
				c_printf(", %d", SymTab[s][S_FILE_NO])

				c_puts("}")
			end if
			seq_num += 1
		end if
		s = SymTab[s][S_NEXT]
	end while
	if not first then
		c_puts(",\n")
	end if
	c_puts("  {\"\", 0, 999999999, 0}\n};\n\n")  -- end marker
end procedure

--**
-- returns 1 if symbol should be exported from dll/so
export function is_exported( symtab_index s )
	sequence eentry = SymTab[s]
	integer scope = eentry[S_SCOPE]

	if eentry[S_MODE] = M_NORMAL then
		if eentry[S_FILE_NO] = 1 and find(scope, { SC_EXPORT, SC_PUBLIC, SC_GLOBAL }) then
			return 1
		end if

		if scope = SC_PUBLIC and
			and_bits( include_matrix[1][eentry[S_FILE_NO]], PUBLIC_INCLUDE )
		then
			return 1
		end if
	end if

	return 0
end function

--**
-- output the list of exported symbols for a .dll
procedure Write_def_file(integer def_file)
	symtab_index s

	if atom(wat_path) then
		puts(def_file, "EXPORTS\n")
	end if

	s = SymTab[TopLevelSub][S_NEXT]
	while s do
		if find(SymTab[s][S_TOKEN], RTN_TOKS) then
			if is_exported( s ) then
				if sequence(wat_path) then
					printf(def_file, "EXPORT %s='__%d%s@%d'\n",
						   {SymTab[s][S_NAME], SymTab[s][S_FILE_NO],
							SymTab[s][S_NAME], SymTab[s][S_NUM_ARGS] * 4})
				else
					-- Lcc
					printf(def_file, "_%d%s@%d\n",
						   {SymTab[s][S_FILE_NO], SymTab[s][S_NAME],
							SymTab[s][S_NUM_ARGS] * 4})
				end if
			end if
		end if
		s = SymTab[s][S_NEXT]
	end while
end procedure

export procedure version()
	c_puts("// Euphoria To C version " & version_string() & "\n")
end procedure

--**
-- end the old .c file and start a new one
export procedure new_c_file(sequence name)
	cfile_size = 0


	if LAST_PASS = FALSE then
		return
	end if

	write_checksum( c_code )
	close(c_code)

	c_code = open(output_dir & name & ".c", "w")
	if c_code = -1 then
		CompileErr(57)
	end if

	cfile_count += 1
	version()

	c_puts("#include \"include/euphoria.h\"\n")

	c_puts("#include \"main-.h\"\n\n")

	if not TUNIX then
		name = lower(name)  -- for faster compare later
	end if
end procedure

--**
-- These characters are assumed to be legal and safe to use
-- in a file name on any platform. We can generate up to
-- length(file_chars) squared (i.e. over 1000) .c files per Euphoria file.
constant file_chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

--**
-- See if name has been used already. If so, change the first char.
function unique_c_name(sequence name)
	integer i
	sequence compare_name
	integer next_fc

	compare_name = name & ".c"
	if not TUNIX then
		compare_name = lower(compare_name)
	end if

	next_fc = 1
	i = 1

	while i <= length(generated_files) do
		-- extract the base name
		if equal(generated_files[i], compare_name) then
			-- name conflict
			if next_fc > length(file_chars) then
				CompileErr(140)
			end if

			name[1] = file_chars[next_fc]
			compare_name = name & ".c"
			if not TUNIX then
				compare_name = lower(compare_name)
			end if

			next_fc += 1
			i = 1 -- start over and compare again

		else
			i += 1
		end if
	end while

	return name
end function

export function is_file_newer(sequence f1, sequence f2)
	object d1 = file_timestamp(f1)
	object d2 = file_timestamp(f2)

	if atom(d1) or atom(d2) then return 1 end if
	if datetime:diff(d1, d2) < 0 then
		return 1
	end if

	return 0
end function

--**
-- Add a file to the generated files list that will later be used for
-- build systems: direct, makefile, etc...

export procedure add_file(sequence filename, sequence eu_filename = "")
	if equal("c", fileext(filename)) then
		filename = filename[1..$-2]
	elsif equal("h", fileext(filename)) then
		generated_files = append(generated_files, filename)
		if build_system_type = BUILD_DIRECT then
			outdated_files  = append(outdated_files, 0)
		end if
		
		return
	end if
	
	sequence obj_fname = filename, src_fname = filename & ".c"

	if compiler_type = COMPILER_WATCOM then
		obj_fname &= ".obj"
	else
		obj_fname &= ".o"
	end if
	
	generated_files = append(generated_files, src_fname)
	generated_files = append(generated_files, obj_fname)
	if build_system_type = BUILD_DIRECT then
		outdated_files  = append(outdated_files, is_file_newer(eu_filename, output_dir & src_fname))
		outdated_files  = append(outdated_files, 0)
	end if
end procedure

--**
-- return TRUE if the corresponding C file will contain any code
-- Note: top level code goes into main-.c
function any_code(integer file_no)
	check_file_routines()
	
	sequence these_routines = file_routines[file_no]
	for i = 1 to length( these_routines ) do
		symtab_index s = these_routines[i]
		if SymTab[s][S_FILE_NO] = file_no and
		   SymTab[s][S_USAGE] != U_DELETED and
		   find(SymTab[s][S_TOKEN], RTN_TOKS) then
			return TRUE -- found a non-deleted routine in this file
		end if
	end for
	return FALSE
end function

export sequence file0

type legaldos_filename_char( integer i )
	if ('A' <= i and i <= 'Z') or
	   ('0' <= i and i <= '9') or
	   (128 <=i and  i <= 255) or
	   find( i, " !#$%'()@^_`{}~" ) != 0
	then
		return 1
	else
		return 0
	end if
end type

type legaldos_filename( sequence s )
	integer dloc

	if find( s, { "..", "." } ) then
		return 1
	end if
	dloc = find('.',s)
	if dloc > 8 or ( dloc > 0 and dloc + 3 < length(s) ) or ( dloc = 0 and length(s) > 8 ) then
		return 0
	end if
	for i = 1 to length(s) do
		if s[i] = '.' then
			for j = i+1 to length(s) do
				if not legaldos_filename_char(s[j]) then
					return 0
				end if
			end for
			exit
		end if
		if not legaldos_filename_char(s[i]) then
			return 0
		end if
	end for

	return 1
end type

export function shrink_to_83( sequence s )
	integer dl, -- dot location
		sl, -- slash location
		osl -- old slash location
	sequence se -- short extension

	osl = find( ':', s )
	sl = osl + find( '\\', s[osl+1..$] ) -- find_from osl
	-- if slash immediately follows the colon skip the part between : and slash.
	if sl=osl+1 then
		osl = sl
	end if
	sl = osl + find( '\\', s[osl+1..$] )
	dl = osl + find( '.', s[osl+1..sl] )
	if dl > osl then
		se = s[dl..min({dl+3,sl-1})]
	else
		se = ""
	end if

	while sl != osl do
		if find( ' ', s[osl+1..sl] ) or not legaldos_filename(upper(s[osl+1..sl-1])) then
			s = s[1..osl] & s[osl+1..osl+6] & "~1" & se & s[sl..$]
			sl = osl+8+length(se)
		end if
		osl = sl
		sl += find( '\\', s[sl+1..$] )
		dl = osl + find( '.', s[osl+1..sl] )
		if dl > osl then
			se = s[dl..min({dl+3,sl})]
		else
			se = ""
		end if
	end while
	if dl > osl then
		se = s[dl..min({dl+3,length(s)})]
	end if
	if find( ' ', s[osl+1..$] ) or not legaldos_filename(upper(s[osl+1..$])) then
		s = s[1..osl] & s[osl+1..osl+6] & "~1" & se
	end if

	return s
end function

export function truncate_to_83( sequence lfn )
	integer dl = find( '.', lfn )
	if dl = 0 and length(lfn) > 8 then
		return lfn[1..8]
	elsif dl = 0 and length(lfn) <= 8 then
		return lfn
	elsif dl > 9 and dl + 3 <= length(lfn) then
		return lfn[1..8] & lfn[dl..$]
	else
		CompileErr( 48, {lfn})
	end if
end function

--**
-- walk through the user-defined routines, computing types and
-- optionally generating code
sequence file_routines = {}
procedure check_file_routines()
	if not length( file_routines ) then
		file_routines = repeat( {}, length( known_files ) )
		integer s = SymTab[TopLevelSub][S_NEXT]
		while s do
			if SymTab[s][S_USAGE] != U_DELETED and
			find(SymTab[s][S_TOKEN], RTN_TOKS)
			then
				file_routines[SymTab[s][S_FILE_NO]] &= s
			end if
			s = SymTab[s][S_NEXT]
		end while
			
	end if
end procedure

export procedure GenerateUserRoutines()
	symtab_index s, sp
	integer next_c_char, q, temps
	sequence buff, base_name, long_c_file, c_file

	if not silent then
		if Pass = 1 then
			ShowMsg(1, 239,,0)
		end if

		if LAST_PASS = TRUE then
			ShowMsg(1, 240)
		else
			ShowMsg(1, 241, Pass, 0)
		end if
	end if
	
	check_file_routines()
		
	c_puts("// GenerateUserRoutines\n")
	for file_no = 1 to length(known_files) do
		if file_no = 1 or any_code(file_no) then
			-- generate a .c file for this Euphoria file
			-- (we need to use the name of the first file - don't skip it)
			next_c_char = 1
			base_name = name_ext(known_files[file_no])
			c_file = base_name

			q = length(c_file)
			while q >= 1 do
				if c_file[q] = '.' then
					c_file = c_file[1..q-1]
					exit
				end if
				q -= 1
			end while

			if find(lower(c_file), {"main-", "init-"})  then
				CompileErr(12, {base_name})
			end if

			long_c_file = c_file
			if LAST_PASS = TRUE then
				c_file = unique_c_name(c_file)
				add_file(c_file, known_files[file_no])
			end if

			if file_no = 1 then
				-- do the standard top-level files as well
				if LAST_PASS = TRUE then
					add_file("main-")
					for i = 0 to main_name_num-1 do
						buff = sprintf("main-%d", i)
						add_file(buff)
					end for
				end if

				file0 = long_c_file
			end if

			new_c_file(c_file)

			s = SymTab[TopLevelSub][S_NEXT]
			
			sequence these_routines = file_routines[file_no]
			for routine_no = 1 to length( these_routines ) do
				s = these_routines[routine_no]
				if SymTab[s][S_USAGE] != U_DELETED then
					-- a referenced routine in this file

					-- Check for oversize C file
					if LAST_PASS = TRUE and
						(cfile_size > max_cfile_size or
						(s != TopLevelSub and cfile_size > max_cfile_size/4 and
						length(SymTab[s][S_CODE]) > max_cfile_size))
					then
						-- start a new C file
						-- (we generate about 1 line of C per element of CODE)

						-- choose new file name, based on base_name
						if length(c_file) = 7 then
							-- make it size 8
							c_file &= " "
						end if

						if length(c_file) >= 8 then
							c_file[7] = '_'
							c_file[8] = file_chars[next_c_char]
						else
							-- 6 or less
							if find('_', c_file) = 0 then
								c_file &= "_ "
							end if

							c_file[$] = file_chars[next_c_char]
						end if

						-- make sure we haven't created a duplicate name
						c_file = unique_c_name(c_file)
						new_c_file(c_file)

						next_c_char += 1
						if next_c_char > length(file_chars) then
							next_c_char = 1  -- (unique_c_name will resolve)
						end if

						add_file(c_file)
					end if

					sequence ret_type
					if SymTab[s][S_TOKEN] = PROC then
						ret_type = "void "
					else
						ret_type = "object "
					end if
					if find( SymTab[s][S_SCOPE], {SC_GLOBAL, SC_EXPORT, SC_PUBLIC} ) and dll_option then
						-- mark it as a routine_id target, so it won't be deleted
						SymTab[s][S_RI_TARGET] = TRUE
						LeftSym = TRUE

						-- declare the global routine as an exported DLL function
						if TWINDOWS then
							c_stmt(ret_type & " __stdcall @(", s)
						else
							c_stmt(ret_type & "@(", s)
						end if

					else
						LeftSym = TRUE
						c_stmt( ret_type & "@(", s)
					end if

					-- declare the parameters
					sp = SymTab[s][S_NEXT]
					for p = 1 to SymTab[s][S_NUM_ARGS] do
						c_puts("object _")
						c_puts(SymTab[sp][S_NAME])
						if p != SymTab[s][S_NUM_ARGS] then
							c_puts(", ")
						end if
						sp = SymTab[sp][S_NEXT]
					end for

					c_puts(")\n")
					c_stmt0("{\n")

					NewBB(0, E_ALL_EFFECT, 0)
					Initializing = TRUE

					-- declare the private vars
					while sp do
						integer scope = SymTab[sp][S_SCOPE]
						switch scope with fallthru do
							case SC_LOOP_VAR, SC_UNDEFINED then
								-- don't need to declare this
								-- an undefined var is a forward reference
								break

							case SC_PRIVATE then
								c_stmt0("object ")
								c_puts("_")
								c_puts(SymTab[sp][S_NAME])
								-- avoid DeRef in 1st BB
								c_puts(" = NOVALUE;\n")
								target[MIN] = NOVALUE
								target[MAX] = NOVALUE
								RemoveFromBB( sp )
								
								break

							case else
								exit
						end switch
						sp = SymTab[sp][S_NEXT]
					end while

					-- declare the temps
					temps = SymTab[s][S_TEMPS]
					sequence names = {}
					while temps != 0 do
						if SymTab[temps][S_SCOPE] != DELETED then
							sequence name = sprintf("_%d", SymTab[temps][S_TEMP_NAME] )
							if temp_name_type[SymTab[temps][S_TEMP_NAME]][T_GTYPE]
																!= TYPE_NULL
								and not find( name, names ) then
								c_stmt0("object ")
								c_puts( name )
								c_puts(" = NOVALUE")
								-- avoids DeRef in 1st BB, but may hurt global type:
								target = {NOVALUE, NOVALUE}
								-- PROBLEM: sp could be temp or symtab entry?
								SetBBType(temps, TYPE_INTEGER, target, TYPE_OBJECT, 0)
								ifdef DEBUG then
									c_puts(sprintf("; // %d %d\n", {temps, SymTab[temps][S_TEMP_NAME]} ) )
								elsedef
									c_puts(";\n")
								end ifdef
								names = prepend( names, name )
							else
								ifdef DEBUG then
									c_printf("// skipping %s  name type: %d\n", { name,
										temp_name_type[SymTab[temps][S_TEMP_NAME]][T_GTYPE] } )
								end ifdef
							end if
						end if
						SymTab[temps][S_GTYPE] = TYPE_OBJECT
						temps = SymTab[temps][S_NEXT]
					end while
					Initializing = FALSE

					if SymTab[s][S_LHS_SUBS2] then
						c_stmt0("object _0, _1, _2, _3;\n\n")
						ifdef DEBUG then
							c_stmt0("_0 = 0; _1 = 1; if( _1 ) _2 = 0; else _3 = 1;\n")
						end ifdef
					else
						c_stmt0("object _0, _1, _2;\n\n")
						ifdef DEBUG then
							c_stmt0("_0 = 0; _1 = 1; if( _1 ) _2 = 0;\n")
						end ifdef
					end if

					-- set the local parameter types in BB
					-- this will kill any unnecessary INTEGER_CHECK conversions
					sp = SymTab[s][S_NEXT]
					for p = 1 to SymTab[s][S_NUM_ARGS] do
						SymTab[sp][S_ONE_REF] = FALSE
						if SymTab[sp][S_ARG_TYPE] = TYPE_SEQUENCE then
							target[MIN] = SymTab[sp][S_ARG_SEQ_LEN]
							SetBBType(sp, SymTab[sp][S_ARG_TYPE], target,
								SymTab[sp][S_ARG_SEQ_ELEM], 0)

						elsif SymTab[sp][S_ARG_TYPE] = TYPE_INTEGER then
							if SymTab[sp][S_ARG_MIN] = NOVALUE then
								target[MIN] = MININT
								target[MAX] = MAXINT
							else
								target[MIN] = SymTab[sp][S_ARG_MIN]
								target[MAX] = SymTab[sp][S_ARG_MAX]
							end if
							SetBBType(sp, SymTab[sp][S_ARG_TYPE], target, TYPE_OBJECT, 0)

						elsif SymTab[sp][S_ARG_TYPE] = TYPE_OBJECT then
							-- object might have valid seq_elem
							SetBBType(sp, SymTab[sp][S_ARG_TYPE], novalue,
									SymTab[sp][S_ARG_SEQ_ELEM], 0)

						else
							SetBBType(sp, SymTab[sp][S_ARG_TYPE], novalue, TYPE_OBJECT, 0)

						end if
						sp = SymTab[sp][S_NEXT]
					end for

					-- walk through the IL for this routine
					call_proc(Execute_id, {s})

					c_puts("    ;\n}\n")
					if TUNIX and dll_option and is_exported( s ) then
						-- create an alias for exporting routines
						LeftSym = TRUE
						if TOSX then
							-- for ticket 596: Apple's site:http://developer.apple.com/library/mac/#documentation/-
							-- DeveloperTools/gcc-4.0.1/gcc/Function-Attributes.html states that "alias" is not 
							-- supported on all machines.    
							c_stmt0( ret_type & SymTab[s][S_NAME] & " (" )
							
							sp = SymTab[s][S_NEXT]
							for p = 1 to SymTab[s][S_NUM_ARGS] do
								c_puts("int _")
								c_puts(SymTab[sp][S_NAME])
								if p != SymTab[s][S_NUM_ARGS] then
									c_puts(", ")
								end if
								sp = SymTab[sp][S_NEXT]
							end for
							
							c_puts( ") {\n")
							c_stmt("    return @(", s)
							sp = SymTab[s][S_NEXT]
							for p = 1 to SymTab[s][S_NUM_ARGS] do
								c_puts("_")
								c_puts(SymTab[sp][S_NAME])
								if p != SymTab[s][S_NUM_ARGS] then
									c_puts(", ")
								end if
								sp = SymTab[sp][S_NEXT]
							end for

							c_puts( ");\n}\n" )	
						else
							c_stmt( ret_type & SymTab[s][S_NAME] & "() __attribute__ ((alias (\"@\")));\n", s )
						end if
						LeftSym = FALSE
					end if
					c_puts("\n\n" )
				end if
			end for
		end if
	end for
end procedure
