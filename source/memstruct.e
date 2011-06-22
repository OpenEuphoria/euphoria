include common.e
include emit.e
include error.e
include global.e
include msgtext.e
include parser.e
include reswords.e
include scanner.e
include symtab.e

export procedure MemStruct( integer scope )
	token tok = next_token() -- name
	symtab_index mem_struct = tok[T_SYM]
	DefinedYet( mem_struct )
	integer pointer = 0
	while 1 with entry do
		switch tok[T_ID] do
			case END then
				-- eventually, we probably need to handle ifdefs,
				-- which may be best handled by refactoring Ifdef_Statement in parser.e
				tok_match( MEMSTRUCT, END )
				exit
			
			case TYPE then
				symtab_index type_sym = tok[T_SYM]
				if type_sym = integer_type then
					Int( mem_struct, pointer )
				else
					CompileErr( 354 )
				end if
				pointer = 0
			
			case MULTIPLY then
				-- pointer!
				pointer = 1
				
			case else
				CompileErr( 354 )
		end switch
	entry
		tok = next_token()
	end while
end procedure

function parse_size( sequence valid )
	tok_match( LEFT_ROUND )
	token tok = next_token()
	if tok[T_ID] != ATOM then
		sequence expected = LexName(ATOM)
		sequence actual = LexName(tok[T_ID])
		CompileErr(132, {expected, actual})
	end if
	atom size = SymTab[tok[T_SYM]][S_OBJ]
	if not find( size, valid ) then
		sequence expected = ""
		for i = 1 to length( valid ) do
			if i > 1 then
				expected &= ", "
			end if
			expected &= sprintf( "%g", valid[i] )
		end for
		CompileErr(132, { expected, size } )
	end if
	
	tok_match( RIGHT_ROUND )
	return size
end function

function read_name()
	token tok = next_token()
	switch tok[T_ID] do
		case VARIABLE, PROC, FUNC, TYPE then
			return tok
		case else
			CompileErr( 32 )
	end switch
end function

procedure Int( symtab_index mem_struct, integer pointer )
	integer size = parse_size( {1, 2, 4, 8 })
	token name_tok = read_name()
end procedure
