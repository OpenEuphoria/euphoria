include common.e
include emit.e
include error.e
include fwdref.e
include global.e
include msgtext.e
include parser.e
include reswords.e
include scanner.e
include symtab.e

include std/dll.e

integer is_union = 0
symtab_pointer last_sym = 0
symtab_index mem_struct

export procedure MemUnion_declaration( integer scope )
	is_union = 1
	MemStruct_declaration( scope )
	is_union = 0
end procedure

function primitive_size( integer primitive )
	switch primitive do
		case MS_CHAR then
			return 1
		case MS_SHORT then
			return 2
		case MS_INT then
			return sizeof( C_INT )
		case MS_LONG then
			return sizeof( C_LONG )
		case MS_LONGLONG then
			return sizeof( C_LONGLONG )
		case MS_OBJECT then
			return sizeof( C_POINTER )
		case MS_FLOAT then
			return 4
		case MS_DOUBLE then
			return 8
		case MS_EUDOUBLE then
			ifdef E32 then
				return 8
			elsifdef E64 then
				-- same as long double
				return 16
			end ifdef
	end switch
end function

--*
-- Creates an alias for a memstruct type.  May be a primitive or
-- a memstruct.
export procedure MemType( integer scope )
	enter_memstruct( 1 )
	token mem_type = next_token()
	symtab_index type_sym = mem_type[T_SYM]
	
	tok_match( MS_AS )
	
	token new_memtype = next_token()
	
	symtab_index sym = new_memtype[T_SYM]
	symtab:DefinedYet( sym )
	SymTab[sym] &= repeat( 0, SIZEOF_MEMSTRUCT_ENTRY - length( SymTab[sym] ) )
	SymTab[sym][S_SCOPE]    = scope
	SymTab[sym][S_TOKEN]    = MEMTYPE
	SymTab[sym][S_MODE]     = M_NORMAL
	
	switch mem_type[T_ID] do
		case MS_CHAR, MS_SHORT, MS_INT, 
			MS_FLOAT, MS_DOUBLE, MS_EUDOUBLE, 
			MS_OBJECT,
			MS_LONG, MS_LONGDOUBLE, MS_LONGLONG
		then
			SymTab[sym][S_MEM_TYPE]   = mem_type[T_ID]
			SymTab[sym][S_MEM_PARENT] = type_sym
			SymTab[sym][S_MEM_SIZE]   = primitive_size( mem_type[T_ID] )
		case else
			
			SymTab[sym][S_MEM_PARENT] = type_sym
			SymTab[sym][S_MEM_SIZE]   = SymTab[type_sym][S_MEM_SIZE]
			
			if not TRANSLATE and not SymTab[sym][S_MEM_SIZE] then
				SymTab[sym][S_MEM_SIZE] = recalculate_size( type_sym )
				-- mark it as a forward reference to have its size recalculated
				
				integer ref = new_forward_reference( MEMTYPE, sym, MEMSTRUCT_DECL )
				set_data( ref, sym )
				add_recalc( type_sym, sym )
				Show( sym ) -- creating a fwdref removes the symbol, but we just want to recalc the size later on
			end if
	end switch
	
	leave_memstruct()
end procedure

procedure DefinedYet( symtab_index sym )
	sequence name = sym_name( sym )
	symtab_pointer mem_entry = mem_struct
	
	while mem_entry with entry do
		if equal( sym_name( mem_entry ), name ) then
			CompileErr(31, {name})
		end if
	entry
		mem_entry = SymTab[mem_entry][S_MEM_NEXT]
	end while
end procedure

export procedure MemStruct_declaration( integer scope )
	token tok = next_token() -- name
	mem_struct = tok[T_SYM]
	symtab:DefinedYet( mem_struct )
	enter_memstruct( mem_struct )
	last_sym = mem_struct
	SymTab[mem_struct] &= repeat( 0, SIZEOF_MEMSTRUCT_ENTRY - length( SymTab[mem_struct] ) )
	if is_union then
		SymTab[mem_struct][S_TOKEN] = MEMUNION
	else
		SymTab[mem_struct][S_TOKEN] = MEMSTRUCT
	end if
	SymTab[mem_struct][S_SCOPE] = scope
	
	integer pointer = 0
	integer signed  = -1
	integer long    = 0
	integer eu_type = 0
	while 1 with entry do
		integer tid = tok[T_ID]
		
		if tid = MEMTYPE then
			symtab_index memtype_sym = tok[T_SYM]
			tid = SymTab[memtype_sym][S_MEM_TYPE]
			if not tid then
				symtab_index type_sym = SymTab[memtype_sym][S_MEM_PARENT]
				tid = sym_token( type_sym )
				tok[T_SYM] = type_sym
				tok[T_ID]  = tid
			end if
		end if
		
		switch tid label "token" do
			case END then
				-- eventually, we probably need to handle ifdefs,
				-- which may be best handled by refactoring Ifdef_Statement in parser.e
				if is_union then
					tok_match( MEMUNION_DECL, END )
				else
					tok_match( MEMSTRUCT_DECL, END )
				end if
				exit
			
			case TYPE, QUALIFIED_TYPE then
				tok_match( MS_AS )
				eu_type = tok[T_SYM]
				
			case MEMSTRUCT, MEMUNION, QUALIFIED_MEMSTRUCT, QUALIFIED_MEMUNION then
				-- embedding
				MemStruct_member( tok, pointer )
				-- reset the flags
				pointer = 0
				long    = 0
				signed  = -1
			
			case VARIABLE, QUALIFIED_VARIABLE then
				if SC_UNDEFINED = SymTab[tok[T_SYM]][S_SCOPE] then
					-- forward reference
					
					if pointer then
						integer ref = new_forward_reference( TYPE, tok[T_SYM], MEMSTRUCT )
						MemStruct_member( tok, pointer, 1 )
					else
					
						token nt = next_token()
						if nt[T_ID] = MS_AS then
							-- a forward reference to a type
							integer ref = new_forward_reference( TYPE, tok[T_SYM], MEMSTRUCT )
							eu_type = -ref
							break "token"
						else
							putback( nt )
							MemStruct_member( tok, pointer, 1 )
						end if
					end if
					
				else
					CompileErr( EXPECTED_VALID_MEMSTRUCT )
				end if
				-- reset the flags
				pointer = 0
				long    = 0
				signed  = -1
				
			case MS_SIGNED then
				if signed != -1 then
					-- error...multiple signed modifiers
					CompileErr( EXPECTED_VALID_MEMSTRUCT )
				end if
				signed = 1
			
			case MS_UNSIGNED then
				if signed != -1 then
					-- error...multiple signed modifiers
					CompileErr( EXPECTED_VALID_MEMSTRUCT )
				end if
				signed = 0
				
			case MS_LONG then
				token check = next_token()
				integer id = check[T_ID]
				if id = MS_INT or id = MS_LONG or id = MS_DOUBLE then
					long = 1
					tid = id
					tok = check
				else
					putback( check )
				end if
				fallthru
			case MS_CHAR, MS_SHORT, MS_INT, MS_FLOAT, MS_DOUBLE, MS_EUDOUBLE, MS_OBJECT then
				
				switch tid do
					case MS_CHAR then
						Char( eu_type, pointer, signed )
					case MS_SHORT then
						Short( eu_type, pointer, signed )
					case MS_INT then
						if long then
							Long( eu_type, pointer, signed )
						else
							Int( eu_type, pointer, signed )
						end if
					case MS_LONG then
						token int_tok = next_token()
						
						if long then
							-- this is the second long...
							if int_tok[T_ID] = MS_INT then
								-- long long int
								LongLong( eu_type, pointer, signed )
							
							elsif int_tok[T_ID] = VARIABLE
							or int_tok[T_ID] = PROCEDURE
							or int_tok[T_ID] = FUNCTION
							or int_tok[T_ID] = TYPE
							or int_tok[T_ID] = NAMESPACE
							then
								-- long long
								putback( int_tok )
								LongLong( eu_type, pointer, signed )
							else
								CompileErr( 25, { sym_name( int_tok[T_SYM] ) } )
							end if
						elsif int_tok[T_ID] = MS_DOUBLE then
							long = 1
							putback( int_tok )
							-- need to skip the part where the flags get reset
							break "token"
						else
							putback( int_tok )
							Long( eu_type, pointer, signed )
						end if
						
					case MS_FLOAT, MS_DOUBLE, MS_EUDOUBLE then
						if signed != - 1 then
							-- can't have signed modifiers here
							CompileErr( FP_NOT_SIGNED )
						end if
						
						if long and tid != MS_DOUBLE then
							-- long modifier only for doubles
							CompileErr( ONLY_DOUBLE_FP_LONG )
						elsif long then
							tid = MS_LONGDOUBLE
						end if
						
						FloatingPoint( eu_type, tid, pointer )
					
					case MS_OBJECT then
						Object( eu_type, pointer, signed )
					
					case else
						
				end switch
				symtab_index type_sym = tok[T_SYM]
				
				-- reset the flags
				pointer = 0
				long    = 0
				signed  = -1
				eu_type = 0
			
			case MS_POINTER then
				-- pointer!
				pointer = 1
				
			case else
				CompileErr( EXPECTED_VALID_MEMSTRUCT )
		end switch
	entry
		tok = next_token()
	end while
	calculate_size()
	leave_memstruct()
end procedure


--*
-- Returns the size and offsets, or -1 if all
-- sizes have not been determined yet.
export function recalculate_size( symtab_index sym )
	mem_struct = sym
	is_union   = sym_token( sym ) = MEMUNION_DECL
	integer size = calculate_size()
	
	is_union = 0
	if size > 0 then
		for i = 2 to length( SymTab[sym][S_MEM_RECALC] ) do
			symtab_index recalc_sym =  SymTab[sym][S_MEM_RECALC][i]
			
			SymTab[recalc_sym][S_MEM_SIZE] = recalculate_size( recalc_sym )
			
		end for
	end if
	return size
end function

procedure add_recalc( symtab_index parent_struct, symtab_index dependent_struct )
	if length( SymTab[parent_struct] ) >= SIZEOF_MEMSTRUCT_ENTRY
	and (atom( SymTab[parent_struct][S_MEM_RECALC] )
		or not find( dependent_struct, SymTab[parent_struct][S_MEM_RECALC] )) then
		SymTab[parent_struct][S_MEM_RECALC] &= dependent_struct
	end if
end procedure

--**
-- Returns the size and offsets for the memstruct, or -1 if all
-- sizes have not been determined yet.
function calculate_size()
	
	symtab_pointer member_sym = mem_struct
	
	if sym_token( member_sym ) = MEMTYPE then
		return SymTab[SymTab[member_sym][S_MEM_PARENT]][S_MEM_SIZE]
	end if
	
	integer size = 0
	integer indeterminate = 0
	while member_sym with entry do
		integer mem_size = SymTab[member_sym][S_MEM_SIZE]
		if mem_size < 1 then
			-- might be a struct that's been recalculated
			symtab_pointer struct_type = SymTab[member_sym][S_MEM_STRUCT]
			if struct_type then
				mem_size = SymTab[struct_type][S_MEM_SIZE]
				if mem_size < 1 then
					if length( struct_type ) >= SIZEOF_MEMSTRUCT_ENTRY then
						mem_size = recalculate_size( struct_type )
					end if
					if mem_size < 1 then
						SymTab[mem_struct][S_MEM_SIZE] = 0
						indeterminate = 1
						add_recalc( struct_type, mem_struct )
					end if
				end if
			else
				SymTab[mem_struct][S_MEM_SIZE] = 0
				indeterminate = 1
				add_recalc( struct_type, mem_struct )
			end if
		end if
		if not indeterminate then
			if not is_union then
				-- make sure we're properly aligned
				integer padding
				if sym_token( member_sym ) = MS_MEMBER then
					padding = remainder( size, sizeof( C_POINTER ) )
				else
					padding = remainder( size, mem_size )
				end if
				
				if padding then
					size += mem_size - padding
				end if
				
				SymTab[member_sym][S_MEM_OFFSET] = size
				size += mem_size
			else
				if mem_size > size then
					size = mem_size
				end if
			end if
		end if
	entry
		member_sym = SymTab[member_sym][S_MEM_NEXT]
	end while
	
	if indeterminate then
		return 0
	else
		SymTab[mem_struct][S_MEM_SIZE] = size
		return size
	end if
end function

function read_name()
	token tok = next_token()
	switch tok[T_ID] do
		case VARIABLE, PROC, FUNC, TYPE, 
				MS_CHAR, MS_SHORT, MS_INT, MS_LONG, MS_LONGLONG, MS_OBJECT, 
				MS_FLOAT, MS_DOUBLE, MS_LONGDOUBLE, MS_EUDOUBLE,
				MS_MEMBER then
			
			DefinedYet( tok[T_SYM] )
			
			symtab_index member = NewBasicEntry( sym_name( tok[T_SYM] ), 0, SC_MEMSTRUCT, MS_MEMBER, 0, 0, 00 )
			SymTab[member] &= repeat( 0, SIZEOF_MEMSTRUCT_ENTRY - length( SymTab[member] ) )
			
			return { MS_MEMBER, member }
		
		case else
			CompileErr( 68, {"identifier", LexName( tok[T_ID] )} )
	end switch
end function

function member_array( symtab_index sym )
	token tok = next_token()
	if tok[T_ID] != LEFT_SQUARE then
		putback( tok )
		return 1
	end if
	
	tok = next_token()
	object size = sym_obj( tok[T_SYM] )
	if not integer( size ) or size < 1 then
		CompileErr( 68, {"positive integer", LexName( tok[T_ID] ) } )
	end if
	
	SymTab[sym][S_MEM_ARRAY] = sym_obj( tok[T_SYM] )
	tok_match( RIGHT_SQUARE )
	return size
end function

procedure add_member( integer type_sym, token name_tok, object mem_type, integer size, integer pointer, integer signed = 0 )
	
	symtab_index sym = name_tok[T_SYM]
	
	SymTab[last_sym][S_MEM_NEXT] = sym
	
	SymTab[sym] &= repeat( 0, SIZEOF_MEMSTRUCT_ENTRY - length( SymTab[sym] ) )
	
	size *= member_array( sym )
	
	if token( mem_type ) then
		SymTab[sym][S_MEM_STRUCT] = mem_type[T_SYM]
		mem_type = MS_MEMBER
	end if
	
	if pointer then
		size = sizeof( C_POINTER )
	end if
	
	if signed = -1 then
		signed = 1
	end if
	
	SymTab[sym][S_SCOPE]       = SC_MEMSTRUCT
	SymTab[sym][S_TOKEN]       = mem_type
	SymTab[sym][S_MEM_SIZE]    = size
	SymTab[sym][S_MEM_POINTER] = pointer
	SymTab[sym][S_MEM_SIGNED]  = signed
	SymTab[sym][S_MEM_PARENT]  = mem_struct
	SymTab[sym][S_MEM_TYPE]    = type_sym
	
	if type_sym < 0 then
		register_forward_type( sym, -type_sym )
	end if
	
	last_sym = sym
end procedure

procedure Char( integer eu_type, integer pointer, integer signed )
	add_member( eu_type, read_name(), MS_CHAR, 1, pointer, signed )
end procedure

procedure Short( integer eu_type, integer pointer, integer signed )
	add_member( eu_type, read_name(), MS_SHORT, 2, pointer, signed )
end procedure

procedure Int( integer eu_type, integer pointer, integer signed )
	add_member( eu_type, read_name(), MS_INT, sizeof( C_INT ), pointer, signed )
end procedure

procedure Long( integer eu_type, integer pointer, integer signed )
	add_member( eu_type, read_name(), MS_LONG, sizeof( C_LONG ), pointer, signed )
end procedure

procedure LongLong( integer eu_type, integer pointer, integer signed )
	add_member( eu_type, read_name(), MS_LONGLONG, sizeof( C_LONGLONG ), pointer, signed )
end procedure

procedure FloatingPoint( integer eu_type, integer fp_type, integer pointer )
	token name_tok = read_name()
	integer size
	switch fp_type do
		case MS_FLOAT then
			size = 4
		case MS_DOUBLE then
			size = 8
		case MS_LONGDOUBLE then
			-- these get padded out in structs to a full 16 bytes
			-- the data is actually only 10 bytes in size
			size = 16
		case MS_EUDOUBLE then
			ifdef E32 then
				size = 8
			elsifdef E64 then
				-- same as long double
				size = 16
			end ifdef
	end switch
	add_member( eu_type, name_tok, fp_type, size, pointer )
end procedure

procedure Object( integer eu_type, integer pointer, integer signed )
	token name_tok = read_name()
	
	add_member( eu_type, name_tok, MS_OBJECT, sizeof( E_OBJECT ), pointer, signed )
end procedure

procedure MemStruct_member( token memstruct_tok, integer pointer, integer fwd = 0 )
	token name_tok = read_name()
	integer size = 0
	
	if fwd then
		integer ref = new_forward_reference( MS_MEMBER, memstruct_tok[T_SYM], MEMSTRUCT_DECL )
		set_data( ref, name_tok[T_SYM] )
	else
		size = SymTab[memstruct_tok[T_SYM]][S_MEM_SIZE]
	end if
	add_member( 0, name_tok, memstruct_tok, size, pointer )
	
	
end procedure

export function resolve_member( sequence name, symtab_index struct_sym )
	symtab_pointer member_sym = struct_sym
	
	while member_sym with entry do
		if equal( name, sym_name( member_sym ) ) then
			return member_sym
		end if
	entry
		member_sym = SymTab[member_sym][S_MEM_NEXT]
	end while
	return 0
end function

export function resolve_members( sequence names, symtab_index struct_sym )
	symtab_pointer parent = struct_sym
	symtab_pointer sym
	for i = 1 to length( names ) do
		sym = resolve_member( names[i], parent )
		if not sym then
			return 0
		end if
		parent = SymTab[sym][S_MEM_PARENT]
	end for
	return sym
end function

function parse_symstruct( token tok )
		
	symtab_index struct_sym = tok[T_SYM]
	integer ref = 0
	if SymTab[struct_sym][S_SCOPE] = SC_UNDEFINED then
		-- a forward reference
		ref = new_forward_reference( MEMSTRUCT, struct_sym, MEMSTRUCT_ACCESS )
		
	elsif tok[T_ID] != MEMSTRUCT
	and tok[T_ID]   != QUALIFIED_MEMSTRUCT
	and tok[T_ID]   != MEMTYPE then
		-- something else
		CompileErr( EXPECTED_VALID_MEMSTRUCT )
	end if
	
	tok = next_token()
	if tok[T_ID] = LEFT_SQUARE then
		emit_symstruct( struct_sym, ref )
		Expr()
		tok_match( RIGHT_SQUARE )
		emit_op( MEMSTRUCT_ARRAY )
		tok = next_token()
		
		if tok[T_ID] != DOT then
			putback( tok )
			return 0
		end if
		return { struct_sym, ref }
	elsif tok[T_ID] = DOT then
		return { struct_sym, ref }
	else
		putback( tok )
		return { struct_sym, ref, 0 }
	end if
end function

procedure emit_member( integer member, integer ref, integer op, sequence names )
	if ref then
		integer m_ref = new_forward_reference( MS_MEMBER, member, op )
		add_data( ref, m_ref )
		emit_opnd( -m_ref )
		set_data( m_ref, names )
	else
		emit_opnd( member )
	end if
end procedure

procedure emit_symstruct( integer symstruct, integer ref )
	if ref then
		emit_opnd( -ref )
	else
		emit_opnd( symstruct )
	end if
end procedure

function is_pointer( symtab_index member )
	return SymTab[member][S_MEM_POINTER]
end function

--**
-- Parse the dot notation of accessing a memstruct.
export procedure MemStruct_access( symtab_index sym, integer lhs )
	-- the sym is the pointer, and just before this, we found a DOT token
	-- First, figure out which memstruct we're using
	token tok = next_token()
	
	object sym_ref = parse_symstruct( tok )
	if atom( sym_ref ) then
		-- simple array access, nothing more needed
		return
	end if
	symtab_index struct_sym = sym_ref[1]
	integer      ref        = sym_ref[2]
	
	if length( sym_ref ) = 3 then
		-- just the sym...serialize it
		if lhs then
			CompileErr("De-serialization of memstructs not implemented")
		else
			emit_symstruct( struct_sym, ref )
			emit_op( MEMSTRUCT_SERIALIZE )
		end if
		return
	end if
	
	sequence names = {}

	No_new_entry = 1
	integer members = 0
	symtab_pointer member = 0
	integer has_dot = 1
	while 1 with entry do
		integer tid = tok[T_ID]
		switch tid do
			case VARIABLE, FUNC, PROC, TYPE, NAMESPACE then
				
				if not has_dot then
					peek_member( members, member, ref, lhs, names )
					putback( tok )
					exit
				end if
				
				putback( tok )
				-- make it look like the IGNORED token
				tok= { IGNORED, SymTab[tok[T_SYM]][S_NAME] }
				fallthru
			
			case IGNORED then
				if not has_dot then
					peek_member( members, member, ref, lhs, names )
					if tid != IGNORED then
						putback( tok )
					else
						No_new_entry = 0
						putback( keyfind( tok[T_SYM], -1 ) )
					end if
					exit
				end if
				
				-- just look at it within this memstruct's context...
				names = append( names, tok[T_SYM] )
				if ref then
					-- we don't know the memstruct yet!
					member = NewBasicEntry( tok[T_SYM], 0, SC_MEMSTRUCT, MS_MEMBER, 0, 0, 00 )
					SymTab[member] &= repeat( 0, SIZEOF_MEMSTRUCT_ENTRY - length( SymTab[member] ) )
					emit_member( member, ref, MEMSTRUCT_ACCESS, names )
				else
					if member then
						-- going into an embedded / linked struct or union
						struct_sym = SymTab[member][S_MEM_STRUCT]
					end if
					if SymTab[struct_sym][S_TOKEN] = MEMTYPE then
						-- use whatever it really is
						struct_sym = SymTab[struct_sym][S_MEM_PARENT]
					end if
					member = resolve_member( tok[T_SYM], struct_sym )
					if not member then
						
						CompileErr( NOT_A_MEMBER, { tok[T_SYM], sym_name( struct_sym ) } )
					end if
					emit_opnd( member )
				end if
				
				members += 1
				has_dot = 0
				
			case MULTIPLY then
				-- ptr.struct.ptr_to_something.*  fetch the value pointed to
				-- TODO: this is serializing, not dereferencing:
				if member then
					tid = sym_token( member )
					if tid >= MS_SIGNED and tid <= MS_OBJECT then
						if SymTab[member][S_MEM_POINTER] then
							tok_match( MULTIPLY )
						else
							CompileErr( ONLY_INT_LONG_LONG )
						end if
					elsif lhs then
						-- assignment of primitives only!
						CompileErr( NOT_A_MEMBER )
					end if
					peek_member( members, member, ref, lhs, names )
					-- re-emit the last member for serialization
					emit_member( member, ref, PEEK_MEMBER, names )
					emit_op( MEMSTRUCT_SERIALIZE )
					exit
				else
					emit_symstruct( struct_sym, ref )
					emit_op( MEMSTRUCT_SERIALIZE )
					exit
				end if
			
			
				
			case DOT then
				-- another layer...
				if not member then
					CompileErr( 68, {"a member name", LexName( tid )} )
				end if
				
				if ref then
					-- we don't know if this is a structure yet
					
-- 					CompileErr("Forward referenced memstruct ops not implemented")
				else
					tid = sym_token( member )
					if tid >= MS_SIGNED and tid <= MS_OBJECT then
						-- must be a pointer, because we've found a primitive
						if SymTab[member][S_MEM_POINTER] then
							tok_match( MULTIPLY )
							emit_opnd( 0 )
							members += 1
							peek_member( members, member, ref, lhs, names )
							exit -- DONE!
						else
							CompileErr( NOT_A_POINTER_OR_MEMSTRUCT )
						end if
					end if
				end if
				has_dot = 1
				
			case else
				peek_member( members, member, ref, lhs, names )
				putback( tok )
				exit
		end switch
	entry
		tok = next_token()
	end while
	No_new_entry = 0
end procedure

procedure peek_member( integer members, symtab_index member, integer ref, integer lhs, sequence names )
	
	emit_opnd( members )
	emit_op( MEMSTRUCT_ACCESS )
	if lhs then
		emit_member( member, ref, MEMSTRUCT_ACCESS, names )
	else
		-- geting the value...peek it
		emit_member( member, ref, PEEK_MEMBER, names )
		emit_op( PEEK_MEMBER )
	end if
end procedure
