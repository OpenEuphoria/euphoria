-- inline.e
-- Inlining euphoria routines

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
			if op != STARTLINE then
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
	return sprintf("%s:%s:%d", {file_name[SymTab[sym][S_FILE_NO]], SymTab[sym][S_NAME], sym})
end function


function returnf( integer pc )
	-- RETURNF SUB RETSYM [BADRETURNF]
	symtab_index retsym = inline_code[pc+2]
	inline_code[$] = NOP1
	
	if is_temp( retsym ) or (not is_literal( retsym) and SymTab[retsym][S_SCOPE] <= SC_PRIVATE) then
		sequence code = {}
		
		integer ret_pc = 0
		
		if not (find( retsym, inline_params ) or find( retsym, proc_vars )) then
			ret_pc = rfind( generic_symbol( retsym ), inline_code, pc )
		end if
		
		if ret_pc then
			inline_code[ret_pc] = {INLINE_TARGET}
		else
			code = {ASSIGN, generic_symbol( retsym ), {INLINE_TARGET}}
		end if
		
		if pc != length( inline_code ) - 3 then
			code &= { ELSE, {INLINE_ADDR, length( inline_code ) + 1 }}
			
		elsif not TRANSLATE then -- or inline_code[$] = BADRETURNF then
			replace_code( {}, length(inline_code), length(inline_code) )
			
		end if
		
		replace_code( code, pc, pc + 2 )
		return 1
	else
		-- returning a literal or non-private variable
		sequence code = {ASSIGN, retsym, {INLINE_TARGET}}
		if pc != length( inline_code ) - 3 then
			code &= { ELSE, {INLINE_ADDR, length( inline_code ) + 1 }}
			
		elsif not TRANSLATE or inline_code[$] = BADRETURNF then
			replace_code( {}, length(inline_code), length(inline_code) )
		end if
		
		replace_code( code, pc, pc + 2 )

		return 1
	end if
	return 0
end function

-- genericizes an op for inlining
function inline_op( integer pc )
	integer op = inline_code[pc]
	
	if op = RETURNP then
		-- RETURNP SUB [BADRETURNF]
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
		replace_code( code, pc, pc + 1 )
		
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
	
		return adjust_il( pc, op )
		
	else
		switch op with fallthru do
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
	
	if OpTrace then
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
	
	while s != 0 and SymTab[s][S_SCOPE] <= SC_PRIVATE do
		proc_vars &= s
		s = SymTab[s][S_NEXT]
	end while
	
	sequence backpatch_op = {}
	while pc < length( inline_code ) do
	
		integer op = inline_code[pc]
		switch op with fallthru do
			case PROC_FORWARD then
			case FUNC_FORWARD then
				defer()
				restore_code()
				return
				
			case PROC then
			case FUNC then
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
				
				
				break
			
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
				goto "inline op"
				
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
			inline_temps[temp_num] = new_inline_var( -temp_num )
		else
			inline_temps[temp_num] = NewTempSym( TRUE )
			
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

function new_inline_var( symtab_index s, integer reuse = 1 )
	symtab_index 
		var = 0, 
		vtype
	sequence name
	
	if reuse then
		var = map:nested_get( inline_var_map, { CurrentSub, s } )
	end if
	
	if not var then
		if s > 0 then
			if reuse then
				name = sprintf( "pvt_%s_%s", {SymTab[s][S_NAME], SymTab[inline_sub][S_NAME]})
			else
				name = sprintf( "pvt_%s_at%d_%s", {SymTab[s][S_NAME], inline_start, SymTab[inline_sub][S_NAME]})
			end if
			
			vtype = SymTab[s][S_VTYPE]
		else
			if reuse then
				name = sprintf( "tmp_%d_%s", {-s, SymTab[inline_sub][S_NAME]})
			else
				name = sprintf( "tmp_%d_at%d_%s", {-s, inline_start, SymTab[inline_sub][S_NAME]})
			end if
			vtype = object_type
		end if
		if CurrentSub = TopLevelSub then
			var = NewEntry( name, varnum, SC_LOCAL, VARIABLE, 1, 0, vtype )
			
		else
			var = NewBasicEntry( name, varnum, SC_PRIVATE, VARIABLE, 1, 0, vtype )
			SymTab[var][S_NEXT] = SymTab[last_param][S_NEXT]
			SymTab[last_param][S_NEXT] = var
			if last_param = last_sym then
				last_sym = var
			end if
		end if
		if deferred_inlining then
			SymTab[CurrentSub][S_STACK_SPACE] += 1
		else
			param_num += 1
		end if
		SymTab[var][S_USAGE] = U_READ + U_WRITTEN
		if reuse then
			map:nested_put( inline_var_map, {CurrentSub, s }, var )
		end if
		
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
	proc_vars = {}
	sequence prolog = {}
	sequence epilog = {}
	
	symtab_index s = SymTab[sub][S_NEXT]
	
	varnum = SymTab[CurrentSub][S_NUM_ARGS]
	inline_start = start
	
	last_param = CurrentSub
	for p = 1 to SymTab[CurrentSub][S_NUM_ARGS] do
		last_param = SymTab[last_param][S_NEXT]
	end for
	
	symtab_index last_sym = last_param
	while last_sym and (SymTab[last_sym][S_SCOPE] <= SC_PRIVATE) do
		last_param = last_sym
		last_sym = SymTab[last_sym][S_NEXT]
		varnum += 1
	end while
	for p = SymTab[sub][S_NUM_ARGS] to 1 by -1 do
		passed_params = prepend( passed_params, Pop() )
	end for
	
	symtab_index int_sym = 0
	for p = 1 to SymTab[sub][S_NUM_ARGS] do
		symtab_index param = passed_params[p]
		inline_params &= s
		integer ax = find( p, assigned_params )
		if ax or is_temp( param ) then
			-- This param is left alone in the routine, but we don't
			-- want the parser to re-use it as another temp
			if not ax then
				TempKeep( param )
			else
				varnum += 1
				symtab_index var = new_inline_var( s )
				prolog &= {ASSIGN, param, var}
				if not int_sym then
					int_sym = NewIntSym( 0 )
				end if
				
				-- force earlier deref of temps to prevent unnecessary COWs
				epilog &= {ASSIGN, int_sym, var}
				inline_start += 3
				passed_params[p] = var
			end if
		end if
		s = SymTab[s][S_NEXT]
		
	end for
	
	symtab_index final_target = 0
	while s and SymTab[s][S_SCOPE] <= SC_PRIVATE do
		-- make new vars for the privates of the routine
		varnum += 1
		symtab_index var = new_inline_var( s )
		proc_vars &= var
		if int_sym = 0 then
			int_sym = NewIntSym( 0 )
		end if
		
		-- force earlier deref of temps to prevent unnecessary COWs
		epilog &= {ASSIGN, int_sym, var}
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
				symtab_index sym = get_param_sym( check_pc + 1 )
				
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
						CompileErr("Type Check Error when inlining literal")
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
				case INLINE_TEMP then
					replace_temp( pc )
					
				case INLINE_PARAM then
					replace_param( pc )
					
				case INLINE_ADDR then
					inline_code[pc] = inline_start + inline_code[pc][2]
					
				case INLINE_TARGET then
					inline_code[pc] = inline_target
					add_inline_target( pc + inline_start )
					
				case INLINE_SUB then
					inline_code[pc] = CurrentSub
					
				case INLINE_VAR then
					replace_var( pc )
					
				case else
					InternalErr( sprintf("Unhandled inline type: %d", inline_type) )
			end switch
		end if
	end for
	
	for i = 1 to length(backpatches) do
		fixup_special_op( backpatches[i] )
	end for
	
	for i = 1 to length(inline_temps) do
		if inline_temps[i] then
			
			if int_sym = 0 then
				int_sym = NewIntSym( 0 )
			end if
			
			-- force earlier deref of temps to prevent unnecessary COWs
			epilog &= {ASSIGN, int_sym, inline_temps[i]}
		
		end if
	end for
	
	if is_proc then
		clear_op()
	else
		if not deferred then
			Push( inline_target )
			inlined_function()
		end if
		
		if final_target then
			epilog &= { ASSIGN, inline_target, final_target }
		else
		
		if int_sym 
		and is_temp( inline_target )
		and SymTab[sub][S_TOKEN] = TYPE then
			-- This allows type checks to work properly, since they expect a 0/1 
			-- object ptr immediately before.  The PRIVATE_INIT_CHECK is skipped, 
			-- and is used since it takes a single symbol coming after it.
			epilog &= { ELSE, length(prolog) + length(inline_code) + length(epilog) + inline_start + 5,
				PRIVATE_INIT_CHECK, inline_target }
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

function forward_params()
	for i = length(cg_stack) - (SymTab[inline_sub][S_NUM_ARGS]-1) to length(cg_stack) do
		if cg_stack[i] < 0 then
			return 1
		end if
	end for
	return 0
end function

-- Either emits an inline routine or emits a call to the routine
-- if that can't be done.
export procedure emit_or_inline()
	symtab_index sub = op_info1
	inline_sub = sub
	if Parser_mode != PAM_NORMAL then
		-- TODO:  this is probably possible in PAM_PLAYBACK mode,
		-- but it doesn't currently work.
		emit_op( PROC )
		return
		
	elsif atom( SymTab[sub][S_INLINE] ) or forward_params() then
		defer_call()
		emit_op( PROC )
		return
	
	end if
	sequence code = get_inlined_code( sub, length(Code) )
	Code &= code
	
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
				while ix and ix < length( Code ) with entry do
					
					if SymTab[sub][S_TOKEN] != PROC then
						Push( Code[ix + SymTab[sub][S_NUM_ARGS] + 2] )
					end if
					
					for p = 2 to SymTab[sub][S_NUM_ARGS] + 1 do
						Push( Code[ix + p] )
					end for
					
					sequence code = get_inlined_code( sub, ix - 1, 1 )
					shift:replace_code( 
						repeat( NOP1, length( code )), ix, ix + 1 + SymTab[sub][S_NUM_ARGS] + (SymTab[sub][S_TOKEN] != PROC) )
					Code = replace( Code, code, ix, ix + length(code) - 1 )
				entry
					ix = match_from( PROC & sub, Code, ix + 1 )
				end while
				SymTab[calling_sub][S_CODE] = Code
			end for
		end if
	end for
--	delete( inline_var_map )
end procedure

