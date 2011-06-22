include common.e
include emit.e
include error.e
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
	integer signed = -1
	integer long = 0
	while 1 with entry do
		integer tid = tok[T_ID]
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
			
			case MEMSTRUCT, MEMUNION, QUALIFIED_MEMSTRUCT, QUALIFIED_MEMUNION then
				-- embedding
				MemStruct_member( tok, pointer )
			
			case VARIABLE, QUALIFIED_VARIABLE then
				if SC_UNDEFINED = SymTab[tok[T_SYM]][S_SCOPE] then
					-- forward reference
					CompileErr( "Forward memstruct references not implemented" )
				else
					CompileErr( 354 )
				end if
				
			case MS_SIGNED then
				if signed != -1 then
					-- error...multiple signed modifiers
					CompileErr( 354 )
				end if
				signed = 1
			
			case MS_UNSIGNED then
				if signed != -1 then
					-- error...multiple signed modifiers
					CompileErr( 354 )
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
						Char( pointer, signed )
					case MS_SHORT then
						Short( pointer, signed )
					case MS_INT then
						if long then
							Long( pointer, signed )
						else
							Int( pointer, signed )
						end if
					case MS_LONG then
						token int_tok = next_token()
						
						if long then
							-- this is the second long...
							if int_tok[T_ID] = MS_INT then
								-- long long int
								LongLong( pointer, signed )
							
							elsif int_tok[T_ID] = VARIABLE
							or int_tok[T_ID] = PROCEDURE
							or int_tok[T_ID] = FUNCTION
							or int_tok[T_ID] = TYPE
							or int_tok[T_ID] = NAMESPACE
							then
								-- long long
								putback( int_tok )
								LongLong( pointer, signed )
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
							Long( pointer, signed )
						end if
						
					case MS_FLOAT, MS_DOUBLE, MS_EUDOUBLE then
						if signed != - 1 then
							-- can't have signed modifiers here
							CompileErr( 355 )
						end if
						
						if long and tid != MS_DOUBLE then
							-- long modifier only for doubles
							CompileErr( 356 )
						elsif long then
							tid = MS_LONGDOUBLE
						end if
						
						FloatingPoint( tid, pointer )
					
					case MS_OBJECT then
						Object( pointer, signed )
					
					case else
						
				end switch
				symtab_index type_sym = tok[T_SYM]
				
				-- reset the flags
				pointer = 0
				long    = 0
				signed  = -1
			
			case MS_POINTER then
				-- pointer!
				pointer = 1
				
			case else
				CompileErr( 354 )
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
	return calculate_size()
end function

--**
-- Returns the size and offsets for the memstruct, or -1 if all
-- sizes have not been determined yet.
function calculate_size()
	
	symtab_pointer member_sym = mem_struct
	
	integer size = 0
	while member_sym with entry do
		integer mem_size = SymTab[member_sym][S_MEM_SIZE]
		if not mem_size then
			return -1
		end if
		
		if not is_union then
			-- make sure we're properly aligned
			integer padding = remainder( size, mem_size )
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
		
	entry
		member_sym = SymTab[member_sym][S_MEM_NEXT]
	end while
	
	SymTab[mem_struct][S_MEM_SIZE] = size
	return size
end function


function read_name()
	token tok = next_token()
	switch tok[T_ID] do
		case VARIABLE, PROC, FUNC, TYPE then
			DefinedYet( tok[T_SYM] )
			return tok
		case else
			CompileErr( 32 )
	end switch
end function

procedure add_member( token tok, object mem_type, integer size, integer pointer, integer signed = 0 )
	symtab_index sym = tok[T_SYM]
	
	SymTab[last_sym][S_MEM_NEXT] = sym
	
	SymTab[sym] &= repeat( 0, SIZEOF_MEMSTRUCT_ENTRY - length( SymTab[sym] ) )
	
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
	
	SymTab[sym][S_TOKEN]       = mem_type
	SymTab[sym][S_MEM_SIZE]    = size
	SymTab[sym][S_MEM_POINTER] = pointer
	SymTab[sym][S_MEM_SIGNED]  = signed
	
	last_sym = sym
end procedure

procedure Char( integer pointer, integer signed )
	add_member( read_name(), MS_CHAR, 1, pointer, signed )
end procedure

procedure Short( integer pointer, integer signed )
	add_member( read_name(), MS_SHORT, 2, pointer, signed )
end procedure

procedure Int( integer pointer, integer signed )
	add_member( read_name(), MS_INT, sizeof( C_INT ), pointer, signed )
end procedure

procedure Long( integer pointer, integer signed )
	add_member( read_name(), MS_LONG, sizeof( C_LONG ), pointer, signed )
end procedure

procedure LongLong( integer pointer, integer signed )
	add_member( read_name(), MS_LONGLONG, sizeof( C_LONGLONG ), pointer, signed )
end procedure

procedure FloatingPoint( integer fp_type, integer pointer )
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
	add_member( name_tok, fp_type, size, pointer )
end procedure

procedure Object( integer pointer, integer signed )
	token name_tok = read_name()
	
	add_member( name_tok, MS_OBJECT, sizeof( E_OBJECT ), pointer, signed )
end procedure

procedure MemStruct_member( token memstruct_tok, integer pointer )
	token name_tok = read_name()
	add_member( name_tok, memstruct_tok, SymTab[memstruct_tok[T_SYM]][S_MEM_SIZE], pointer )
end procedure
