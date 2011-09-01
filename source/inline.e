-- (c) Copyright - See License.txt
-- inline.e
-- Inlining euphoria routines

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include std/sort.e
include std/map.e as map
include std/search.e

include reswords.e
include global.e
include symtab.e
include shift.e
include emit.e
include error.e
include parser.e
include fwdref.e
include block.e

export constant DEFAULT_INLINE = 30 -- default code size that may be inlined

enum
	INLINE_PARAM,
	INLINE_TEMP,
	INLINE_TARGET,
	INLINE_ADDR,
	INLINE_SUB,
--	INLINE_SWITCH_TABLE,
	INLINE_VAR

sequence 
	inline_code,
	proc_vars,
	inline_temps,
	passed_params,
	original_params,
	inline_params,
	assigned_params

integer 
	inline_target,
	prev_pc,
	return_gotos,
	deferred_inlining = 0,
	varnum,
	inline_start

symtab_index
	inline_sub,
	last_param

sequence deferred_inline_decisions = {}
sequence deferred_inline_calls     = {}

map inline_var_map = map:new()

function advance( integer pc, sequence code )
	prev_pc = pc
	if pc > length( code ) then
		return pc
	end if
	return shift:advance( pc, code )
end function

procedure shift( integer start, integer amount, integer bound = start )
	sequence 
		temp_LineTable = LineTable,
		temp_Code = Code
	LineTable = {}
	Code = inline_code
	inline_code = {}
	
	shift:shift( start, amount, bound )
	
	LineTable = temp_LineTable
	inline_code = Code
	Code = temp_Code
end procedure


export procedure insert_code( sequence code, integer index )
	inline_code = splice( inline_code, code, index )
	shift( index, length( code ) )
end procedure

export procedure replace_code( sequence code, integer start, integer finish )
	inline_code = replace( inline_code, code, start, finish )
	shift( start , length( code ) - (finish - start + 1), finish )
end procedure

-- Records that the sub currently being examined cannot be 
-- inlined in its current form (probably due to the presence
-- of forward references).  It will be checked at the end to
-- determine if it really can be inlined.
procedure defer()
	integer dx = find( inline_sub, deferred_inline_decisions )
	if not dx then
		deferred_inline_decisions &= inline_sub
		deferred_inline_calls = append( deferred_inline_calls, {} )
	end if
end procedure

-- records the specified sym and returns the generic temp number for inline conversion
function new_inline_temp( symtab_index sym )
	inline_temps &= sym
	return length( inline_temps )
end function

-- converts a sym from the original routine IL to a temp or param num
function get_inline_temp( symtab_index sym )
	
	integer temp_num = find( sym, inline_params )
	if temp_num then
		return temp_num
	end if
	
	temp_num = find( sym, proc_vars )
	if temp_num then
		return temp_num
	end if
	
	temp_num = find( sym, inline_temps )
	if temp_num then
		return temp_num
	end if
	
	return new_inline_temp( sym )
end function

function generic_symbol( symtab_index sym )
	integer inline_type
	integer px = find( sym, inline_params )
	if px then
		inline_type = INLINE_PARAM
	else
		px = find( sym, proc_vars )
		if px then
			inline_type = INLINE_VAR
		else
			sequence eentry = SymTab[sym]
			if is_literal( sym ) or eentry[S_SCOPE] > SC_PRIVATE then
				return sym
			end if
			inline_type = INLINE_TEMP
		end if
	end if
	
	return { inline_type, get_inline_temp( sym ) }
end function

-- determines if a symbol can be genericized, and updates the IL if it can
-- returns 0 if the routine cannot be inlined
function adjust_symbol( integer pc )
	
	symtab_index sym = inline_code[pc]
	if sym < 0 then
		return 0
	elsif not sym then
		-- some ops have extra space (i.e., PLUS1)
		return 1
	end if
	
	sequence eentry = SymTab[sym]
	if is_literal( sym ) then
		return 1
		
	elsif eentry[S_SCOPE] = SC_UNDEFINED then
		defer()
		return 0
	end if
	
	inline_code[pc] = generic_symbol( sym )
	return 1
end function

function check_for_param( integer pc )
	integer px = find( inline_code[pc], inline_params )
	if px then
		if not find( px, assigned_params ) then
			assigned_params &= px
		end if
		return 1
	end if
	return 0
end function

-- checks the target to determine if a parameter is assigned to
procedure check_target( integer pc, integer op )
	sequence targets = op_info[op][OP_TARGET]
	
	if length( targets ) then
	for i = 1 to length( targets ) do
			if check_for_param( pc + targets[i] ) then
				return
			end if
		end for
	end if
end procedure

-- genericizes an address or symbol reference for inlining
function adjust_il( integer pc, integer op)
	
	for i = 1 to op_info[op][OP_SIZE] - 1 do
		
		integer addr = find( i, op_info[op][OP_ADDR] )
		integer sub  = find( i, op_info[op][OP_SUB] )
		if addr then
			if integer( inline_code[pc+i] ) then
				inline_code[pc + i] = { INLINE_ADDR, inline_code[pc + i] }
			end if
		
		elsif sub then
			inline_code[pc+i] = {INLINE_SUB}
		else
			if op != STARTLINE and op != COVERAGE_LINE and op != COVERAGE_ROUTINE then
				check_target( pc, op )
				if not adjust_symbol( pc + i ) then
					return 0
				end if
			end if
		end if
	end for
	return 1
end function

function is_temp( symtab_index sym )
	if sym <= 0 then
		return 0
	end if
	
	return (SymTab[sym][S_MODE] = M_TEMP) and (not TRANSLATE or equal( NOVALUE, SymTab[sym][S_OBJ]) )
end function

function is_literal( symtab_index sym )
	if sym <= 0 then
		return 0
	end if
	
	integer mode = SymTab[sym][S_MODE]
	if (mode = M_CONSTANT and eu:compare( NOVALUE, SymTab[sym][S_OBJ]) ) 
	or (TRANSLATE and (mode = M_TEMP) and eu:compare( SymTab[sym][S_OBJ], NOVALUE ) ) then
		return 1
	else
		return 0
	end if
end function

function file_and_name( symtab_index sym )
	return sprintf("%s:%s:%d", {known_files[SymTab[sym][S_FILE_NO]], SymTab[sym][S_NAME], sym})
end function

function returnf( integer pc )
	-- RETURNF SUB BLOCK RETSYM [BADRETURNF]
	symtab_index retsym = inline_code[pc+3]
	if equal( inline_code[$], BADRETURNF ) then
		if TRANSLATE then
			inline_code[$] = NOP1
		elsif SymTab[inline_sub][S_TOKEN] = PROC then
			replace_code( {}, length(inline_code), length(inline_code) )
		end if
		
	end if
	
	
	if is_temp( retsym ) 
	or (not is_literal( retsym) and SymTab[retsym][S_SCOPE] <= SC_PRIVATE) then
		sequence code = {}
		
		integer ret_pc = 0
		
		if not (find( retsym, inline_params ) or find( retsym, proc_vars )) then
			ret_pc = rfind( generic_symbol( retsym ), inline_code, pc )
			
		end if
		
		if ret_pc and eu:compare( inline_code[ret_pc-1], PRIVATE_INIT_CHECK ) then
			inline_code[ret_pc] = {INLINE_TARGET}
			
			if equal( inline_code[ret_pc-1], REF_TEMP ) then
				-- when returning a temp, a REF_TEMP is injected between the generating
				-- expression and the return op
				inline_code[ret_pc-2] = {INLINE_TARGET}
			end if
		else
			code = {ASSIGN, generic_symbol( retsym ), {INLINE_TARGET}}
		end if
		
		if pc != length( inline_code ) - ( 3 + TRANSLATE ) then
			code &= { ELSE, {INLINE_ADDR, -1 }}
			
		end if

		replace_code( code, pc, pc + 3 )
		ret_pc = find( { INLINE_ADDR, -1 }, inline_code, pc )
		if ret_pc then
			inline_code[ret_pc][2] = length(inline_code) + 1
		end if
		return 1
	else
		-- returning a literal or non-private variable
		sequence code = {ASSIGN, retsym, {INLINE_TARGET}}
		if pc != length( inline_code ) - ( 3 + TRANSLATE ) then
			code &= { ELSE, {INLINE_ADDR, -1 }}
			
		end if

		replace_code( code, pc, pc + 3 )
		integer ret_pc = find( { INLINE_ADDR, -1 }, inline_code, pc )
		if ret_pc then
			inline_code[ret_pc][2] = length(inline_code) + 1
		end if
		return 1
	end if
	return 0
end function

-- genericizes an op for inlining
function inline_op( integer pc )
	integer op = inline_code[pc]
	
	if op = RETURNP then
		-- RETURNP SUB BLOCK [BADRETURNF]
		-- The translator puts a BADRETURNF at the end of procedures to
		-- mark the end.  If we encounter a RETURNP that's not at the 
		-- end, then we need to change the BADRETURNF into a NOP1.  If
		-- we get to the end, then we can just leave it if it's NOP1,
		-- or get rid of it if it's still a BADRETURNF.
		sequence code = ""
		
		if pc != length( inline_code ) - 1 - TRANSLATE then
			code = { ELSE, {INLINE_ADDR, length( inline_code ) + 1 }}
			if TRANSLATE then
				inline_code[$] = NOP1
			end if
			
		elsif TRANSLATE and inline_code[$] = BADRETURNF then
			inline_code[$] = NOP1
		end if
		replace_code( code, pc, pc + 2 )
		
	elsif op = RETURNF then
		return returnf( pc )

	elsif op = ROUTINE_ID then
		
		integer
			stlen = inline_code[pc+2+TRANSLATE],
			file  = inline_code[pc+4+TRANSLATE],
			ok    = adjust_il( pc, op )
		inline_code[pc+2+TRANSLATE] = stlen
		inline_code[pc+4+TRANSLATE] = file
		
		return ok
		
	elsif op_info[op][OP_SIZE_TYPE] = FIXED_SIZE then
		switch op do
			case SWITCH, SWITCH_RT, SWITCH_I, SWITCH_SPI then
				-- make a copy of the jump table
				symtab_index original_table = inline_code[pc + 3]
				symtab_index jump_table = NewStringSym( {-2, length(SymTab) } )
				SymTab[jump_table][S_OBJ] = SymTab[original_table][S_OBJ]
				inline_code[pc+3] = jump_table
		end switch
		return adjust_il( pc, op )
		
	else
		switch op with fallthru do
			case REF_TEMP then
				inline_code[pc+1] = {INLINE_TARGET}
				
			case CONCAT_N then
			case RIGHT_BRACE_N then
				
				if check_for_param( pc + 2 + inline_code[pc+1] ) then
					-- don't need to do anything here
				end if
				
				for i = pc + 2 to pc + 2 + inline_code[pc+1] do
					if not adjust_symbol( i ) then
						return 0
					end if
					
				end for
				return 1
			case else
				return 0
		end switch
	end if
	return 1
end function

sequence temp_code
procedure restore_code()
	if length( temp_code ) then
		Code = temp_code
	end if
end procedure

-- Determine whether a routine can be inlined.
-- Can't inline if:
--    * Length of IL code is > OpInline
--    * Recursion (other than tail call)
--    * OpTrace is on
export procedure check_inline( symtab_index sub )
	
	if OpTrace or SymTab[sub][S_TOKEN] = TYPE then
		return
	end if
	inline_sub      = sub
	if get_fwdref_count() then
		defer()
		return
	end if
	temp_code = ""
	if sub != CurrentSub then
		Code = SymTab[sub][S_CODE]
	else
		temp_code = Code
	end if
	
	if length(Code) > OpInline then
		return
	end if
	
	inline_code     = Code
	return_gotos    = 0
	prev_pc         = 1
	proc_vars       = {}
	inline_temps    = {}
	inline_params   = {}
	assigned_params = {}
	
	integer pc = 1
	symtab_index s = SymTab[sub][S_NEXT]
	for p = 1 to SymTab[sub][S_NUM_ARGS] do
		inline_params &= s
		s = SymTab[s][S_NEXT]
	end for
	
	while s != 0 and 
	(sym_scope( s ) <= SC_PRIVATE or sym_scope( s ) = SC_UNDEFINED ) do
		if sym_scope( s ) != SC_UNDEFINED then
			proc_vars &= s
		end if
		
		s = SymTab[s][S_NEXT]
	end while
	sequence backpatch_op = {}
	while pc < length( inline_code ) do
	
		integer op = inline_code[pc]
		switch op do
			case PROC_FORWARD, FUNC_FORWARD then
				defer()
				restore_code()
				return
				
			case PROC, FUNC then
				symtab_index rtn_idx = inline_code[pc+1]
				if rtn_idx = sub then
					-- it's recursive, so can't be inlined (don't defer)
					restore_code()
					return
				end if
				
				integer args = SymTab[rtn_idx][S_NUM_ARGS]
				if SymTab[rtn_idx][S_TOKEN] != PROC and check_for_param( pc + args + 2 ) then
					
				end if
				for i = 2 to args + 1 + (SymTab[rtn_idx][S_TOKEN] != PROC) do
					if not adjust_symbol( pc + i ) then 
						defer()
						return
					end if
				end for
				
			case RIGHT_BRACE_N then
				-- need to check to see if any temps are duplicated
				sequence args = inline_code[pc+2..inline_code[pc+1] + pc + 1]
				
				for i = 1 to length(args) - 1 do
					if find( args[i], args, i + 1 ) then
						defer()
						restore_code()
						return
					end if
				end for
				goto "inline op"
				
			case RIGHT_BRACE_2 then
				if equal( inline_code[pc+1], inline_code[pc+2] ) then
					defer()
					restore_code()
					return
				end if
				goto "inline op"
				
			case EXIT_BLOCK then
				replace_code( "", pc, pc + 1 )
				continue
			
			case SWITCH_RT then
				sequence values = SymTab[inline_code[pc+2]][S_OBJ]
				for i = 1 to length( values ) do
					if sequence( values[i] ) then
						-- one of the values is a fwd ref
						defer()
						restore_code()
						return
					end if
				end for
				backpatch_op = append( backpatch_op, pc )
				fallthru
			
			case else
			label "inline op"
				if not inline_op( pc ) then
					-- something about this op prevents us from inlining
					defer()
					restore_code()
					return
				end if
		end switch
		
		pc = advance( pc, inline_code )
		
	end while
	
	SymTab[sub][S_INLINE] = { sort( assigned_params ), inline_code, backpatch_op }
	restore_code()
end procedure

procedure replace_temp( integer pc )
	integer temp_num = inline_code[pc][2]
	integer needed = temp_num - length( inline_temps )
	if needed > 0 then
		inline_temps &= repeat( 0, needed )
	end if
	
	if not inline_temps[temp_num] then
		if TRANSLATE then
			inline_temps[temp_num] = new_inline_var( -temp_num, 0 )
		else
			inline_temps[temp_num] = NewTempSym( TRUE )
-- 			Block_var( inline_temps[temp_num] )
		end if
	end if
	
	inline_code[pc] = inline_temps[temp_num]
end procedure

function get_param_sym( integer pc )
	object il = inline_code[pc]
	if integer( il ) then
		return inline_code[pc]
	
	elsif length( il ) = 1 then
		return inline_target
	
	end if
	
	integer px = il[2]
	return passed_params[px]
end function

function get_original_sym( integer pc )
	object il = inline_code[pc]
	if integer( il ) then
		return inline_code[pc]
	
	elsif length( il ) = 1 then
		return inline_target
	
	end if
	
	integer px = il[2]
	return original_params[px]
end function

procedure replace_param( integer pc )
	inline_code[pc] = get_param_sym( pc )
end procedure

procedure replace_var( integer pc )
	inline_code[pc] = proc_vars[inline_code[pc][2]]
end procedure

procedure fix_switch_rt( integer pc )
	symtab_index value_table = NewStringSym( {-1, length(SymTab)} )
	symtab_index jump_table  = NewStringSym( {-1, length(SymTab)} )
	
	SymTab[value_table][S_OBJ] = SymTab[inline_code[pc+2]][S_OBJ]
	SymTab[jump_table][S_OBJ]  = SymTab[inline_code[pc+3]][S_OBJ]
	
	inline_code[pc+2] = value_table
	inline_code[pc+3] = jump_table
	
end procedure

procedure fixup_special_op( integer pc )
	integer op = inline_code[pc]
	switch op with fallthru do
		case SWITCH_RT then
			fix_switch_rt( pc )
			break
	end switch
end procedure

constant INLINE_HASHVAL = NBUCKETS + 1
function new_inline_var( integer ps, integer reuse = 1 )
	-- create a new inline variable based on either a variable from the inlined routine
	-- or a temporary (ps < 1).
	-- if ps is positive use ps is taken to mean a symindex to a variable declared
	-- in the inlined routine.  Otherwise it is taken to mean a temporary and the 
	-- absolute value is used for naming the variable.
	symtab_index 
		var = 0, 
		vtype
	sequence name
	symtab_index s
	
	if reuse then
		var = map:nested_get( inline_var_map, { CurrentSub, ps } )
	end if
	
	if not var then
		if ps > 0 then
			s = ps
			if TRANSLATE then
				name = sprintf( "%s_inlined_%s", {SymTab[s][S_NAME], SymTab[inline_sub][S_NAME] })
			else
				name = sprintf( "%s (from inlined routine '%s'", {SymTab[s][S_NAME], SymTab[inline_sub][S_NAME] })
			end if
			
			if reuse then
				if not TRANSLATE then
					name &= ")"
				end if
			else
				if TRANSLATE then
					name &= sprintf( "_at_%d", inline_start)
				else
					name &= sprintf( " at %d)", inline_start)
				end if
			end if
			
			vtype = SymTab[s][S_VTYPE]
		else
			name = sprintf( "%s_%d", {SymTab[inline_sub][S_NAME], -ps})
			if reuse then
				name &= "__tmp"
			else
				name &= sprintf( "__tmp_at%d", inline_start)
			end if
			vtype = object_type
		end if
		if CurrentSub = TopLevelSub then
			var = NewEntry( name, varnum, SC_LOCAL, VARIABLE, INLINE_HASHVAL, 0, vtype )
			
		else
			var = NewBasicEntry( name, varnum, SC_PRIVATE, VARIABLE, INLINE_HASHVAL, 0, vtype )
			SymTab[var][S_NEXT] = SymTab[last_param][S_NEXT]
			SymTab[last_param][S_NEXT] = var
			if last_param = last_sym then
				last_sym = var
			end if
		end if
		if deferred_inlining then
			SymTab[CurrentSub][S_STACK_SPACE] += 1
		else
			if param_num != -1 then
				param_num += 1
			end if
		end if
		SymTab[var][S_USAGE] = U_USED
		if reuse then
			map:nested_put( inline_var_map, {CurrentSub, ps }, var )
		end if
		
	end if
	Block_var( var )
	if BIND then
		add_ref( {VARIABLE, var} )
	end if
	return var
end function

export function get_inlined_code( symtab_index sub, integer start, integer deferred = 0 )
	integer is_proc = SymTab[sub][S_TOKEN] = PROC
	clear_inline_targets()
	
	inline_temps = {}
	inline_params = {}
	assigned_params      = SymTab[sub][S_INLINE][1]
	inline_code          = SymTab[sub][S_INLINE][2]
	sequence backpatches = SymTab[sub][S_INLINE][3]
	
	passed_params = {}
	original_params = {}
	proc_vars = {}
	sequence prolog = {}
	sequence epilog = {}
	
	Start_block( EXIT_BLOCK, sprintf("Inline-%s from %s @ %d", 
		{SymTab[sub][S_NAME], SymTab[CurrentSub][S_NAME], start} ) )
	
	symtab_index s = SymTab[sub][S_NEXT]
	
	varnum = SymTab[CurrentSub][S_NUM_ARGS]
	inline_start = start
	
	last_param = CurrentSub
	for p = 1 to SymTab[CurrentSub][S_NUM_ARGS] do
		last_param = SymTab[last_param][S_NEXT]
	end for
	
	symtab_index last_sym = last_param
	while last_sym and 
	(sym_scope( last_sym ) <= SC_PRIVATE or sym_scope( last_sym ) = SC_UNDEFINED ) do
		last_param = last_sym
		last_sym = SymTab[last_sym][S_NEXT]
		varnum += 1
	end while
	for p = SymTab[sub][S_NUM_ARGS] to 1 by -1 do
		passed_params = prepend( passed_params, Pop() )
	end for
	
	original_params = passed_params
	
	symtab_index int_sym = 0
	for p = 1 to SymTab[sub][S_NUM_ARGS] do
		symtab_index param = passed_params[p]
		inline_params &= s
		integer ax = find( p, assigned_params )
		if ax or is_temp( param ) then
			-- This param is left alone in the routine, but we don't
			-- want the parser to re-use it as another temp
			varnum += 1
			symtab_index var = new_inline_var( s, 0 )
			prolog &= {ASSIGN, param, var}
			if not int_sym then
				int_sym = NewIntSym( 0 )
			end if
			
			inline_start += 3
			passed_params[p] = var
		end if
		s = SymTab[s][S_NEXT]
		
	end for
	
	symtab_index final_target = 0
	while s and 
	(sym_scope( s ) <= SC_PRIVATE or sym_scope( s ) = SC_UNDEFINED) do
		if sym_scope( s ) != SC_UNDEFINED then
			
			-- make new vars for the privates of the routine
			varnum += 1
			symtab_index var = new_inline_var( s, 0 )
			proc_vars &= var
			if int_sym = 0 then
				int_sym = NewIntSym( 0 )
			end if
		end if
		s = SymTab[s][S_NEXT]
	end while
	
	if not is_proc then
		integer create_target_var = 1
		if deferred then
			inline_target = Pop()
			if is_temp( inline_target ) then
				final_target = inline_target
			else
				create_target_var = 0
			end if
		end if
		
		if create_target_var then
			varnum += 1
			if TRANSLATE then
				inline_target = new_inline_var( sub, 0 )
				SymTab[inline_target][S_VTYPE] = object_type
				Pop_block_var()
			else
				inline_target = NewTempSym()
			end if
		end if
		proc_vars &= inline_target
	else
		inline_target = 0
	end if
	
	-- we may be able to avoid some of these...
	integer check_pc = 1
	
	while length(inline_code) > check_pc do
		integer op = inline_code[check_pc]
		
		switch op with fallthru do
			case ATOM_CHECK then
			case SEQUENCE_CHECK then
			case INTEGER_CHECK then
				symtab_index sym = get_original_sym( check_pc + 1 )
				if is_literal( sym ) then
					integer check_result
						
					if op = INTEGER_CHECK then
						check_result = integer( SymTab[sym][S_OBJ] )
					elsif op = SEQUENCE_CHECK then
						check_result = sequence( SymTab[sym][S_OBJ] )
					else
						check_result = atom( SymTab[sym][S_OBJ] )
					end if
					
					if check_result then
						replace_code( {}, check_pc, check_pc+1 )
						
					else
						-- TODO: make this more descriptive!
						CompileErr(146)
					end if
					
				elsif not is_temp( sym ) then
				
					if (op = INTEGER_CHECK and SymTab[sym][S_VTYPE] = integer_type )
					or (op = SEQUENCE_CHECK and SymTab[sym][S_VTYPE] = sequence_type )
					or (op = ATOM_CHECK and find( SymTab[sym][S_VTYPE], {integer_type, atom_type} ) ) then
						replace_code( {}, check_pc, check_pc+1 )
						
					else
						check_pc += 2
					end if
				else
					-- TODO: can we eliminate if we're passing an integer -> integer (etc)?
					check_pc += 2
				end if
				continue
			case STARTLINE then
				check_pc += 2
				continue
			
			case else
				exit
		end switch
	end while
	
	for pc = 1 to length( inline_code ) do
		if sequence( inline_code[pc] ) then
			integer inline_type = inline_code[pc][1]
			switch inline_type do
				case INLINE_SUB then
					inline_code[pc] = CurrentSub
					
				case INLINE_VAR then
					replace_var( pc )
					break
				case INLINE_TEMP then
					replace_temp( pc )
					
				case INLINE_PARAM then
					replace_param( pc )
					
				case INLINE_ADDR then
					inline_code[pc] = inline_start + inline_code[pc][2]
					
				case INLINE_TARGET then
					inline_code[pc] = inline_target
					add_inline_target( pc + inline_start )
					break
				
				case else
					InternalErr( 265, {inline_type} )
			end switch
		end if
	end for
	
	for i = 1 to length(backpatches) do
		fixup_special_op( backpatches[i] )
	end for
	
	epilog &= End_inline_block( EXIT_BLOCK )
	
	if is_proc then
		clear_op()
	else
		if not deferred then
			Push( inline_target )
			inlined_function()
		end if
		
		if final_target then
			epilog &= { ASSIGN, inline_target, final_target }
			emit_temp( final_target, NEW_REFERENCE )
		else
		
			-- This allows type checks to work properly, since they expect a 0/1 
			-- object ptr immediately before.  The PRIVATE_INIT_CHECK is skipped, 
			-- and is used since it takes a single symbol coming after it.
			emit_temp( inline_target, NEW_REFERENCE )
			if not TRANSLATE then
				epilog &= { ELSE, 0, PRIVATE_INIT_CHECK, inline_target }
				epilog[$-2] = length(inline_code) + length(epilog) + inline_start + 1
			end if
			
		end if
	end if
	
	return prolog & inline_code & epilog
end function

procedure defer_call()
	integer defer = find( inline_sub, deferred_inline_decisions )
	if defer then
		-- remember this for later
		deferred_inline_calls[defer] &= CurrentSub
	end if
end procedure

-- Either emits an inline routine or emits a call to the routine
-- if that can't be done.
export procedure emit_or_inline()
	symtab_index sub = op_info1
	inline_sub = sub
	
	if SymTab[sub][S_DEPRECATED] then
		Warning(327, deprecated_warning_flag, { SymTab[sub][S_NAME] })
	end if
	
	if Parser_mode != PAM_NORMAL then
		-- TODO:  this is probably possible in PAM_PLAYBACK mode,
		-- but it doesn't currently work.
		emit_op( PROC )
		return
		
	elsif atom( SymTab[sub][S_INLINE] ) or has_forward_params(sub) then
		defer_call()
		emit_op( PROC )
		return
	
	end if
	sequence code = get_inlined_code( sub, length(Code) )
	emit_inline( code )
	clear_last()
	
end procedure

-- Called after all parsing and forward reference resolution is complete.
-- Check the deferred routines to see if they can be inlined, and then
-- inline what we can.
export procedure inline_deferred_calls()
	deferred_inlining = 1
	for i = 1 to length( deferred_inline_decisions ) do
		
		if length( deferred_inline_calls[i] ) then
			-- only worry about stuff that's actually called
			integer sub = deferred_inline_decisions[i]
			check_inline( sub )
			if atom( SymTab[sub][S_INLINE] ) then
				continue
			end if
			for cx = 1 to length( deferred_inline_calls[i] ) do
				integer ix = 1
				symtab_index calling_sub = deferred_inline_calls[i][cx]
				CurrentSub = calling_sub
				Code = SymTab[calling_sub][S_CODE]
				LineTable = SymTab[calling_sub][S_LINETAB]
				sequence code = {}
				
				sequence calls = find_ops( 1, PROC )
				integer is_func = SymTab[sub][S_TOKEN] != PROC 
				integer offset = 0
				for o = 1 to length( calls ) do
					if calls[o][2][2] = sub then
						ix = calls[o][1]
						sequence op = calls[o][2]
						integer size = length( op ) - 1
						if is_func then
							-- push the return target
							Push( op[$] )
							op = remove( op, length(op) )
						end if
						
						-- push the parameters
						for p = 3 to length( op ) do
							Push( op[p] )
						end for
						code = get_inlined_code( sub, ix + offset - 1, 1 )
						shift:replace_code( repeat( NOP1, length(code) ), ix + offset, ix + offset + size )
						
						-- prevent unwanted code shifting...the inlining process does this for us
						Code = eu:replace( Code, code, ix + offset, ix + offset + length( code ) -1 )
						offset += length(code) - size - 1
						
					end if
				end for
				SymTab[calling_sub][S_CODE] = Code
				SymTab[calling_sub][S_LINETAB] = LineTable
			end for
		end if
	end for
end procedure

