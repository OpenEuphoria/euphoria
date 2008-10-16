-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Forward reference resolution

include global.e
include parser.e
include symtab.e
include error.e
include scanner.e

-- Tracking forward references
sequence forward_references = {}
enum
	FR_TYPE,
	FR_NAME,
	FR_FILE,
	FR_SUBPROG,
	FR_PC,
	FR_LINE,
	FR_THISLINE,
	FR_BP,
	FR_QUALIFIED,
	FR_OP,
	FR_PRIVATE_LIST

constant FR_SIZE = FR_PRIVATE_LIST

-- # extra default parameters to leave space when
-- emitting a forward call
export constant FORWARD_DEFAULT_PADDING = 5


-- TODO: update side effects tracking for routines
export integer parse_arg_rid
export integer pop_rid

sequence patch_code_temp = {}
symtab_index patch_code_sub
symtab_index patch_current_sub
procedure set_code( integer ref )
	patch_code_sub = forward_references[ref][FR_SUBPROG]
	
	if patch_code_sub != CurrentSub then
		patch_code_temp = Code
		Code = SymTab[patch_code_sub][S_CODE]
		patch_current_sub = CurrentSub
		CurrentSub = patch_code_sub
	else
		patch_current_sub = patch_code_sub
	end if
	
end procedure

procedure reset_code( )
	SymTab[patch_code_sub][S_CODE] = Code
	if patch_code_sub != patch_current_sub then
		CurrentSub = patch_current_sub
		Code = patch_code_temp
	end if
end procedure

sequence fwd_private_sym  = {}
sequence fwd_private_name = {}
export procedure add_private_symbol( symtab_index sym, sequence name )
	
	fwd_private_sym &= sym
	fwd_private_name = append( fwd_private_name, name )
	
end procedure

procedure reset_private_lists()
	fwd_private_sym  = {}
	fwd_private_name = {}
end procedure

procedure patch_forward_call( token tok, integer ref )
	-- Format of IL:
	-- pc   OPCODE
	-- pc+1 Proc Sym
	-- pc+2 Num args supplied => Next pc
	-- pc+3 Args... [/ padding...] [/ Func target]
	
	sequence fr = forward_references[ref]
	integer code_sub = fr[FR_SUBPROG]
	symtab_index sub = tok[T_SYM]
	integer args = SymTab[sub][S_NUM_ARGS]
	integer is_func = (SymTab[sub][S_TOKEN] = FUNC)
	
	integer real_file = current_file_no
	current_file_no = fr[FR_FILE]
	
	sequence code
	if code_sub = CurrentSub then
		code = Code
	else
		code = SymTab[code_sub][S_CODE]
	end if
	
	integer pc = fr[FR_PC]
	integer next_pc = pc
	integer supplied_args = code[pc+2]
	sequence name = fr[FR_NAME]
	next_pc +=
		4                           -- possible goto padding 
		+ 3                         -- sym, #args
		+ code[next_pc + 2]         -- # args emitted
		+ FORWARD_DEFAULT_PADDING   -- extra padding in case of default args
		+ is_func                   -- target sym for func assignment
	
	integer has_defaults = 0
	integer goto_target = length( code ) + 1
	integer defarg = 0
	integer code_len = length(code)
	code &= NOP1 & NOP1
	
	integer extra_default_args = 0
	set_dont_read( 1 )
	reset_private_lists()
	integer param_sym = sub
	for i = pc + 3 to pc + args + 2 do
		defarg += 1
		param_sym = SymTab[param_sym][S_NEXT]
		if not code[i] then
			-- default arg!
			has_defaults = 1
			
			extra_default_args += 1
			
			-- now we need to parse the args
			-- set up the environment
			sequence code_temp = Code
			Code = code
			
			symtab_index temp_current_sub = CurrentSub
			CurrentSub = code_sub
			
			show_params( sub )
			call_proc( parse_arg_rid, { sub, defarg, fwd_private_name, fwd_private_sym } )
			hide_params( sub )
			Code[pc+2+defarg] = call_func( pop_rid, {}) -- Pop()
			-- restore stuff to how it was before parsing
			code = Code
			CurrentSub = temp_current_sub
			Code = code_temp
		else
			extra_default_args = 0
			add_private_symbol( code[i], SymTab[param_sym][S_NAME] )
		end if
	end for
	set_dont_read( 0 )
	current_file_no = real_file
	
	integer from_file = fr[FR_FILE]
	integer line      = fr[FR_LINE]
	sequence routine_type
	if is_func then 
		routine_type = "function"
	else
		routine_type = "procedure"
	end if
	sequence err_msg = ""
	
	if extra_default_args > FORWARD_DEFAULT_PADDING then
		err_msg = sprintf( 
			"Too many trailing default parameters in forward reference\n\t%s (%d): %s %s Limit is %d, but found %d.",
			{ file_name[from_file], line, routine_type, name, FORWARD_DEFAULT_PADDING, extra_default_args } )
	
	elsif args != ( supplied_args + extra_default_args ) then
		err_msg = sprintf( "Wrong number of arguments supplied for forward reference\n\t%s (%d): %s %s.  Expected %d, but found %d.",
			{ file_name[from_file], line, routine_type, name, args, supplied_args + extra_default_args } )
	
	end if
	
	if length( err_msg ) then
		current_file_no = from_file
		line_number = line
		CompileErr( err_msg )
	end if
	
	if has_defaults and code_len != length(code) then
		-- shift the code
		-- we don't need the #args parameter any more
		code[pc+4..next_pc-2] = code[pc+3..next_pc-3]
		if TRANSLATE then
			
			-- change the flow of the translator
			code[pc..pc+1] = { TRANSGOTO, code_len + 3 }
			code &= { TRANSGOTO, pc + 2 }
			
			code[goto_target..goto_target+1] = { TRANSGOTO, length(code) + 1 }
		else
			code[pc] = ELSE
			code[pc+1] = goto_target + 2
			
			code[goto_target] = ELSE
			code[goto_target+1] = length(code) + 3 -- jump over the default stuff
			code &= ELSE
			
			code &= pc + 2
		end if
		pc += 2
		
	else
		code[pc+2..next_pc-2] = code[pc+3..next_pc-1]
		code[next_pc-2] = NOP1
		code = code[1..$-2]  -- remove the NOP1s that we put there just in case
	end if
	
	
	if is_func then
		code[pc + args + 2] = code[next_pc-1]
	end if
	code[next_pc - 1] = NOP1
	
	for i = pc to next_pc - 1 do
		if not code[i] then
			code[i] = NOP1 -- don't leave zeroes here
		end if
	end for
	
	
	if TRANSLATE then
		code[pc + 2 + args + is_func] = TRANSGOTO	
	else
		
		code[pc + 2 + args + is_func] = ELSE
	end if
	
	code[pc + 3 + args + is_func] = next_pc
	
	-- convert it to a normal call, and put in the index for the routine
	code[pc] = PROC
	code[pc+1] = sub
	
	if code_sub = CurrentSub then
		Code = code
	else
		SymTab[code_sub][S_CODE] = code
	end if
	
	-- mark this one as resolved already
	forward_references[ref] = 0
			
end procedure

procedure set_error_info( integer ref )
	sequence fr = forward_references[ref]
	ThisLine        = fr[FR_THISLINE]
	bp              = fr[FR_BP]
	line_number     = fr[FR_LINE]
	current_file_no = fr[FR_FILE]
end procedure

procedure patch_forward_variable( token tok, integer ref )
-- forward reference for a variable
	sequence fr = forward_references[ref]
	symtab_index sym = tok[T_SYM]
	
	if SymTab[sym][S_FILE_NO] = fr[FR_FILE] then
		return
	end if
	
	if fr[FR_OP] = ASSIGN and SymTab[sym][S_MODE] = M_CONSTANT then
		prep_forward_error( ref )
		CompileErr( "may not change the value of a constant" )
	end if
	
	set_code( ref )
	integer vx = find_from( -ref, Code, fr[FR_PC] )
	if vx then
		while vx do
			-- subscript assignments might cause the
			-- sym to be emitted multiple times
			Code[vx] = sym
			vx = find_from( -ref, Code, fr[FR_PC] )
		end while
		forward_references[ref] = 0
	end if
	reset_code()
end procedure

procedure patch_forward_init_check( token tok, integer ref )
-- forward reference for a variable
	sequence fr = forward_references[ref]
	set_code( ref )
	Code[fr[FR_PC]+1] = tok[T_SYM]
	forward_references[ref] = 0
	reset_code()
end procedure


function expected_name( integer id )
	
	switch id do
		case PROC:
		case PROC_FORWARD:
			return "a procedure"
			
		case FUNC:
		case FUNC_FORWARD:
			return "a function"
		
		case VARIABLE:
			return "a variable, constant or enum"
		case else
			return "something"
	end switch
	
end function

procedure patch_forward_type_check( token tok, integer ref )
	symtab_index which_type = SymTab[tok[T_SYM]][S_VTYPE]
	if not which_type then
		return
	end if
	set_code( ref )
	sequence fr = forward_references[ref]
	integer pc = fr[FR_PC]
	symtab_index var = tok[T_SYM]
	integer with_type_check = Code[pc + 3 + (not TRANSLATE) * 2]
	integer next_pc
	
	if TRANSLATE then
		next_pc = pc + 5
		if with_type_check then
			if which_type != object_type then
				if SymTab[which_type][S_EFFECT] then
					-- only call user-defined types that have side-effects
					integer c = NewTempSym()
					Code[pc..pc+3] = { PROC, which_type, var, c }
					pc += 3
					
					Code[pc] = TYPE_CHECK
					pc += 1
				end if
			end if
		end if

	else
		next_pc = pc + 7
		if with_type_check then
			
			if which_type = object_type then
					-- skip it
					Code[pc..pc+6] = { ELSE, next_pc, NOP1, NOP1, NOP1, NOP1, NOP1 }
			
			else
				-- TODO:  Some of these could be optimized away
				if which_type = integer_type then
					Code[pc..pc+6] = { INTEGER_CHECK, var, ELSE, next_pc, NOP1, NOP1, NOP1 }
					
				elsif which_type = sequence_type then
					Code[pc..pc+6] = { SEQUENCE_CHECK, var, ELSE, next_pc, NOP1, NOP1, NOP1 }
					
				elsif which_type = atom_type then
					Code[pc..pc+6] = { ATOM_CHECK, var, ELSE, next_pc, NOP1, NOP1, NOP1 }
					
				else
					integer start_pc = pc
					if SymTab[SymTab[which_type][S_NEXT]][S_VTYPE] =
						integer_type then
					
						Code[pc..pc+1] = { INTEGER_CHECK, var }
						pc += 2
					end if
					symtab_index c = NewTempSym()
					Code[pc..pc+4] = { PROC, which_type, var, c, TYPE_CHECK }
					
				end if
			end if
		end if
	end if

	if TRANSLATE or not with_type_check then
		integer start_pc = pc

		if which_type = sequence_type or
			SymTab[SymTab[which_type][S_NEXT]][S_VTYPE] = sequence_type then
			-- check sequences anyway, so we can avoid it on subscripting etc.
			Code[pc..pc+3] = { SEQUENCE_CHECK, var, 0, next_pc } 
			pc += 4
			
		elsif which_type = integer_type or
				 SymTab[SymTab[which_type][S_NEXT]][S_VTYPE] = integer_type then
				 -- check integers too
			Code[pc..pc+3] = { INTEGER_CHECK, var, ELSE, next_pc }
			pc += 4
			
		end if
		
		if TRANSLATE then
			if pc = start_pc then
				Code[pc..pc+1] = { TRANSGOTO, next_pc }
			else
				Code[pc-2] = TRANSGOTO
			end if
		else
			if pc = start_pc then
				Code[pc..pc+1] = { ELSE, next_pc }
				Code[pc+2..next_pc-1] = NOP1
			else
				Code[pc-2] = ELSE
				Code[pc..next_pc-1] = NOP1
			end if
		end if
	end if
	forward_references[ref] = 0
	reset_code()
end procedure

procedure prep_forward_error( integer ref )
	ThisLine = forward_references[ref][FR_THISLINE]
	bp = forward_references[ref][FR_BP]
end procedure

procedure forward_error( token tok, integer ref )
	prep_forward_error( ref )
	
	CompileErr(sprintf("expected %s, not %s", 
		{ expected_name( forward_references[ref][FR_TYPE] ),
			expected_name( tok[T_ID] ) } ) )
end procedure

function find_reference( sequence fr )
	
	sequence name = fr[FR_NAME]
	integer file  = fr[FR_FILE]
	
	integer ns_file = -1
	integer ix = find( ':', name )
	if ix then
		sequence ns = name[1..ix-1]
		token ns_tok = keyfind( ns, ns_file, file, 1 )
		if ns_tok[T_ID] != NAMESPACE then
			return ns_tok
		end if
	else
		ns_file = fr[FR_QUALIFIED]
	end if
	
	No_new_entry = 1
	token tok = keyfind( name, ns_file, file )
	No_new_entry = 0
	return tok
end function


export function new_forward_reference( integer fwd_op, symtab_index sym, integer op = fwd_op  )
	forward_references = append( forward_references, repeat( 0, FR_SIZE ) )
	integer ref = length( forward_references )
	
	
	forward_references[ref][FR_TYPE]      = fwd_op
	if sym < 0 then
		forward_references[ref][FR_NAME] = forward_references[-sym][FR_NAME]
	else
		forward_references[ref][FR_NAME] = SymTab[sym][S_NAME]
	end if
	
	forward_references[ref][FR_FILE]      = current_file_no
	forward_references[ref][FR_SUBPROG]   = CurrentSub
	forward_references[ref][FR_PC]        = length( Code ) + 1
	forward_references[ref][FR_LINE]      = line_number
	forward_references[ref][FR_THISLINE]  = ThisLine
	forward_references[ref][FR_BP]        = bp
	forward_references[ref][FR_QUALIFIED] = get_qualified_fwd()
	forward_references[ref][FR_OP]        = op
	
	return ref
end function
	
export procedure Resolve_forward_references( integer report_errors = 0 )
	sequence errors = {}
	sequence code = {}
	
	for ref = 1 to length( forward_references ) do
		
		if sequence( forward_references[ref] ) then
			sequence fr = forward_references[ref]
			token tok = find_reference( fr )
			
			if tok[T_ID] = IGNORED then
				errors &= ref
				continue
			end if
			
			sequence fname = file_name[fr[FR_FILE]]
			sequence cname = file_name[current_file_no]
			
			-- found a match...
			integer code_sub = fr[FR_SUBPROG]
			integer fr_type  = fr[FR_TYPE]
			integer sym_tok
			switch fr_type label "fr_type" do
				case PROC:
				case FUNC:
					
					sym_tok = SymTab[tok[T_SYM]][S_TOKEN]
					if sym_tok != fr_type then
						forward_error( tok, ref )
					end if
					switch sym_tok do
						case PROC:
						case FUNC:
					
							patch_forward_call( tok, ref )
							continue
							
						case else
							forward_error( tok, ref )
							
					end switch
					
				case VARIABLE:
					sym_tok = SymTab[tok[T_SYM]][S_TOKEN]
					if SymTab[tok[T_SYM]][S_SCOPE] = SC_UNDEFINED then
						errors &= ref
						continue
					end if
					switch sym_tok do
						case CONSTANT:
						case ENUM:
						case VARIABLE:
							patch_forward_variable( tok, ref )
							if sequence( forward_references[ref] ) then
								errors &= ref
							end if
							continue
						case else
							forward_error( tok, ref )
					end switch
				case TYPE_CHECK:
					patch_forward_type_check( tok, ref )
					continue
				
				case GLOBAL_INIT_CHECK:
					patch_forward_init_check( tok, ref )
					continue
					
				case else
					-- ?? what is it?
					InternalErr( sprintf("unrecognized forward reference type: %d (%s)", {fr[FR_TYPE], fr[FR_NAME]} ))
			end switch
		end if
	end for
	
	if report_errors and length( errors ) then
		sequence msg = "Errors resolving the following references:\n"
		integer error_count = 0
		for e = 1 to length( errors ) do
			sequence ref = forward_references[errors[e]]
			if ref[FR_TYPE] = TYPE_CHECK then
				continue
				msg &= sprintf("\t%s (%d): type check for %s\n", {file_name[ref[FR_FILE]], ref[FR_LINE], ref[FR_NAME]} )
			else
				msg &= sprintf("\t%s (%d): %s\n", {file_name[ref[FR_FILE]], ref[FR_LINE], ref[FR_NAME]} )
			end if
			error_count += 1
			ThisLine    = ref[FR_THISLINE]
			bp          = ref[FR_BP]
			CurrentSub  = ref[FR_SUBPROG]
			line_number = ref[FR_LINE]
			
		end for
		if error_count then
			puts(1, msg ) ? 1/0
			CompileErr( msg )
		end if
	end if
end procedure
