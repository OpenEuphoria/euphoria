include common.e
include emit.e
include error.e
include global.e
include msgtext.e
include parser.e
include reswords.e
include scanner.e
include symtab.e

integer is_union = 0

export procedure MemUnion_declaration( integer scope )
	is_union = 1
	MemStruct_declaration( scope )
	is_union = 0
end procedure

export procedure MemStruct_declaration( integer scope )
	token tok = next_token() -- name
	symtab_index mem_struct = tok[T_SYM]
	DefinedYet( mem_struct )
	enter_memstruct()
	integer pointer = 0
	integer signed = -1
	integer long = 0
	while 1 with entry do
		integer tid = tok[T_ID]
		switch tid do
			case END then
				-- eventually, we probably need to handle ifdefs,
				-- which may be best handled by refactoring Ifdef_Statement in parser.e
				if is_union then
					tok_match( MEMUNION_DECL, END )
				else
					tok_match( MEMSTRUCT_DECL, END )
				end if
				exit
			
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
						Char( mem_struct, pointer, signed )
					case MS_SHORT then
						Short( mem_struct, pointer, signed )
					case MS_INT then
						if long then
							Long( mem_struct, pointer, signed )
						else
							Int( mem_struct, pointer, signed )
						end if
					case MS_LONG then
						if long then
							LongLong( mem_struct, pointer, signed )
						else
							Long( mem_struct, pointer, signed )
						end if
					case MS_FLOAT, MS_DOUBLE, MS_EUDOUBLE then
						if signed != - 1 then
							-- can't have signed modifiers here
							CompileErr( 355 )
						end if
						
						if long and tid != MS_DOUBLE then
							-- long modifier only for doubles
							CompileErr( 356 )
						end if
						
						FloatingPoint( tid, mem_struct, pointer )
					
					case MS_OBJECT then
						Object( mem_struct, pointer, signed )
					
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
	leave_memstruct()
end procedure


function read_name()
	token tok = next_token()
	switch tok[T_ID] do
		case VARIABLE, PROC, FUNC, TYPE then
			return tok
		case else
		? tok
			CompileErr( 32 )
	end switch
end function

procedure Char( symtab_index mem_struct, integer pointer, integer signed )
	token name_tok = read_name()
end procedure

procedure Short( symtab_index mem_struct, integer pointer, integer signed )
	token name_tok = read_name()
end procedure

procedure Int( symtab_index mem_struct, integer pointer, integer signed )
	token name_tok = read_name()
end procedure

procedure Long( symtab_index mem_struct, integer pointer, integer signed )
	token name_tok = read_name()
end procedure

procedure LongLong( symtab_index mem_struct, integer pointer, integer signed )
	token name_tok = read_name()
end procedure

procedure FloatingPoint( integer fp_type, symtab_index mem_struct, integer pointer )
	token name_tok = read_name()
end procedure

procedure Object( symtab_index mem_struct, integer pointer, integer signed )
	token name_tok = read_name()
end procedure

