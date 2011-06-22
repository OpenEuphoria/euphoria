include common.e
include emit.e
include global.e
include parser.e
include reswords.e
include scanner.e
include symtab.e

export procedure MemStruct( integer scope )
	token tok = next_token() -- name
	symtab_index mem_struct = tok[T_SYM]
	DefinedYet( mem_struct )
	while 1 with entry do
		switch tok[T_ID] do
			case END then
				-- eventually, we probably need to handle ifdefs,
				-- which may be best handled by refactoring Ifdef_Statement in parser.e
				tok_match( MEMSTRUCT, END )
				exit
		end switch
	entry
		tok = next_token()
	end while
end procedure
