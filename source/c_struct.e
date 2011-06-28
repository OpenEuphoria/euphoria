-- Translator code for dealing with memstructs

include c_decl.e
include c_out.e
include compile.e
include emit.e
include error.e
include global.e
include reswords.e
include symtab.e

-- Use this to communicate between ops so we can avoid changing
-- pointers into doubles.
sequence target_is_pointer = {}


function is_pointer( integer pointer )
	return find( pointer, target_is_pointer )
end function

procedure add_pointer( integer pointer )
	if not is_pointer( pointer ) then
		target_is_pointer &= pointer
	end if
end procedure

procedure remove_pointer( integer pointer )
	integer px = is_pointer( pointer )
	if px then
		target_is_pointer = remove( target_is_pointer, px )
	end if
end procedure


function struct_type( symtab_index sym )
	sym = SymTab[sym][S_MEM_PARENT]
	integer token = sym_token( sym )
	sequence type_name = ""
	if token = MEMSTRUCT then
		type_name &= "struct "
	else
		type_name &= "union "
	end if
	return type_name & decorated_name( sym )
end function

procedure get_pointer( integer pointer, integer target )
	if not is_pointer( target ) then
		CDeRef( target )
	end if
	
	if is_pointer( pointer ) then
		if target != pointer then
			
			c_stmt( "@ = @;\n", {target, pointer}, target )
		end if
	else
		c_stmt( "_0 = @;\n", pointer )
	
		if not TypeIs( pointer, TYPE_INTEGER ) then
			c_stmt0("if( !IS_ATOM_INT( _0 ) ){\n" )
				c_stmt0("_0 = (intptr_t) DBL_PTR( _0 )->dbl;\n" )
			c_stmt0( "}\n")
		end if
		
		c_stmt( "@ = _0;\n", target, target )
		dispose_temp( pointer, compile:DISCARD_TEMP, REMOVE_FROM_MAP )
	end if
	
	add_pointer( target )
	SetBBType( target, TYPE_INTEGER, {MININT, MAXINT}, TYPE_INTEGER, 0 )
	
end procedure

export procedure opMEMSTRUCT_ACCESS()
	integer 
		access_count = Code[pc+1],
		pointer      = Code[pc+2],
		target       = Code[pc+ 3 + access_count]
	
	get_pointer( pointer, target )
	
	symtab_index sym = Code[pc+3]
	
	c_stmt( sprintf("@ = (intptr_t) &((%s*)@)",{struct_type(sym)}), { target, target }, target )
	
	integer 
		first_pc    = pc + 3,
		last_pc     = pc + 2 + access_count,
		was_pointer = 1
	
	for i = first_pc to last_pc do
		if was_pointer then
			c_puts("->")
		else
			c_puts(".")
		end if
		CName( Code[i] )
	end for
	c_puts( ";\n")
	
	pc += access_count + 4
end procedure

export procedure opMEMSTRUCT_ARRAY()
	integer
		pointer   = Code[pc+1],
		member    = Code[pc+2],
		subscript = Code[pc+3],
		target    = Code[pc+4]
	
	get_pointer( pointer, target )
	
	
	sequence type_name
	integer data_type = sym_token( member )
	switch data_type do
		case MS_MEMBER then
			member = SymTab[member][S_MEM_STRUCT]
			fallthru
			
		case MEMSTRUCT, MEMUNION then
			sequence tag
			if data_type = MEMSTRUCT then
				tag = "struct"
			else
				tag = "union"
			end if
			type_name = sprintf( "%s %s", { tag, decorated_name( member ) } )
		case else
			type_name = mem_name( data_type )
	end switch
	
	integer is_integer = TypeIs( subscript, TYPE_INTEGER )
	if not is_integer then
		c_stmt("if( IS_ATOM_INT( @ ) ){\n", subscript )
	end if
	c_stmt("_1 = @;\n", subscript )
	
	if not is_integer then
		c_stmt0( "}\n" )
		c_stmt0( "else{\n" )
		c_stmt(  "_1 = (intptr_t)DBL_PTR( @ )->dbl;\n", subscript )
		c_stmt0( "}\n" )
	end if
	
	dispose_temp( subscript, compile:DISCARD_TEMP, REMOVE_FROM_MAP )
	c_stmt( sprintf( "@ = (intptr_t) &(((%s*)@)[_1]);\n", { type_name } ), { target, target }, target )
	
	pc += 5
end procedure

--**
-- Stores the value pointed to by _0 into the target.
procedure peek_member( integer pointer, integer sym, integer target )
	integer data_type = SymTab[sym][S_TOKEN]
	integer signed    = SymTab[sym][S_MEM_SIGNED]
	sequence type_name
	if SymTab[sym][S_MEM_POINTER] then
		data_type = MS_OBJECT
		signed    = 0
		type_name = "object"
	else
		type_name = mem_name( sym_token( sym ) )
	end if
	
	CDeRef( target )
	
	if not signed then
		if data_type = MS_OBJECT then
			type_name = "uintptr_t"
		else
			type_name = "unsigned " & type_name
		end if
	end if
	
	switch data_type do
		case MS_FLOAT, MS_DOUBLE, MS_LONGDOUBLE, MS_EUDOUBLE then
			c_stmt( sprintf("@ = NewDouble( (eudouble) *(%s*)@ );\n", {type_name}), { target, pointer }, target )
		
		case MEMUNION then
			-- TODO
		case MEMSTRUCT then
			-- TODO
		case else
			c_stmt( sprintf("@ = *(%s*)@;\n", {type_name}), { target, pointer }, target )
			
	end switch
	
end procedure

export procedure opPEEK_MEMBER()
	integer
		pointer = Code[pc+1],
		member  = Code[pc+2],
		target  = Code[pc+3]
	
	get_pointer( pointer, target )
	
	peek_member( pointer, member, target )
	
	remove_pointer( pointer )
	remove_pointer( target )
	pc += 4
end procedure


export procedure opMEMSTRUCT_SERIALIZE()
	? 1/0
end procedure

--**
-- Stores the value into the memory pointed to by _0
procedure poke_member( symtab_index target, symtab_index member, symtab_index val )
	integer data_type = SymTab[member][S_TOKEN]
	integer signed    = SymTab[member][S_MEM_SIGNED]
	
	sequence type_name
	
	if SymTab[member][S_MEM_POINTER] then
		data_type = MS_OBJECT
		signed    = 0
		type_name = "object"
	else
		type_name = mem_name( sym_token( member ) )
	end if
	
	if not signed then
		if data_type = MS_OBJECT then
			type_name = "uintptr_t"
		else
			type_name = "unsigned " & type_name
		end if
	end if
	
	switch data_type do
		case MS_FLOAT, MS_DOUBLE, MS_LONGDOUBLE, MS_EUDOUBLE then
			integer is_double = TypeIs( val, TYPE_DOUBLE )
			if not is_double then
				c_stmt( "if( IS_ATOM_INT( @ ) ){\n", val )
					c_stmt( sprintf("*(%s)@ = (%s)@;\n", {type_name, type_name}), { target, val }, target )
				c_stmt0( "}\n" )
				c_stmt0( "else{\n")
			end if
			
			c_stmt( sprintf("*(%s)@ = (%s)DBL_PTR( @ )->dbl;\n", {type_name, type_name}), { target, val }, target )
			
			if not is_double then
				c_stmt0( "}\n")
			end if
		
		case MEMUNION then
			-- TODO
		case MEMSTRUCT then
			-- TODO
		case else
			integer is_integer = TypeIs( val, TYPE_INTEGER )
			if not is_integer then
				c_stmt( "if( IS_ATOM_INT( @ ) ){\n", val )
			end if
			
			c_stmt( sprintf("*(%s*) @ = (%s) @;\n", {type_name, type_name}), {target, val}, target )
			
			if not is_integer then
				c_stmt0("}\n" )
				c_stmt0( "else{\n")
				c_stmt( sprintf("*(%s*) @ = (%s) DBL_PTR( @ )->dbl;\n", {type_name, type_name}), {target, val}, target )
				c_stmt0("}\n" )
			end if
	end switch
end procedure


export procedure opMEMSTRUCT_ASSIGN()
	integer
		pointer = Code[pc+1],
		member  = Code[pc+2],
		val     = Code[pc+3]
	
	get_pointer( pointer, pointer )
	
	poke_member( pointer, member, val )
	
	dispose_temp( val, compile:DISCARD_TEMP, REMOVE_FROM_MAP )
	remove_pointer( pointer )
	
	pc += 4
end procedure


export procedure opMEMSTRUCT_ASSIGNOP()
	integer
		op      = Code[pc],
		pointer = Code[pc+1],
		member  = Code[pc+2],
		val     = Code[pc+3]
	
	get_pointer( pointer, pointer )
	
	sequence optext
	switch op do
		case MEMSTRUCT_PLUS then
			optext = "+"
		case MEMSTRUCT_MINUS then
			optext = "-"
		case MEMSTRUCT_DIVIDE then
			optext = "/"
		case MEMSTRUCT_MULTIPLY then
			optext = "*"
	end switch
	
	integer data_type = sym_token( member )
	sequence type_name = mem_name( data_type )
	switch data_type do
		case MS_FLOAT, MS_DOUBLE, MS_LONGDOUBLE, MS_EUDOUBLE then
			integer is_double = TypeIs( val, TYPE_DOUBLE )
			if not is_double then
				c_stmt( "if( IS_ATOM_INT( @ ) ){\n", val )
					c_stmt( sprintf("*(%s)@ %s= (%s)@;\n", {type_name, optext, type_name}), { pointer, val }, pointer )
				c_stmt0( "}\n" )
				c_stmt0( "else{\n")
			end if
			
			c_stmt( sprintf("*(%s)@ %s= (%s)DBL_PTR( @ )->dbl;\n", {type_name, optext, type_name}), { pointer, val }, pointer )
			
			if not is_double then
				c_stmt0( "}\n")
			end if
		
		case MEMUNION then
			-- TODO
		case MEMSTRUCT then
			-- TODO
		case else
			integer is_integer = TypeIs( val, TYPE_INTEGER )
			if not is_integer then
				c_stmt( "if( IS_ATOM_INT( @ ) ){\n", val )
			end if
			
			c_stmt( sprintf("*(%s*) @ %s= (%s) @;\n", {type_name, optext, type_name}), {pointer, val}, pointer )
			
			if not is_integer then
				c_stmt0("}\n" )
				c_stmt0( "else{\n")
				c_stmt( sprintf("*(%s*) @ %s= (%s) DBL_PTR( @ )->dbl;\n", {type_name, optext, type_name}), {pointer, val}, pointer )
				c_stmt0("}\n" )
			end if
	end switch
	dispose_temp( val, compile:DISCARD_TEMP, REMOVE_FROM_MAP )
	remove_pointer( pointer )
	pc += 4
end procedure

function decorated_name( symtab_index sym )
	return sprintf( "_%d%s", { SymTab[sym][S_FILE_NO], sym_name( sym ) } )
end function

function mem_name( integer tid )
	switch tid do
		case MS_CHAR then
			return "char"
		case MS_SHORT then
			return "short"
		case MS_INT then
			return "int"
		case MS_LONG then
			return "long"
		case MS_OBJECT then
			return "object"
		case MS_LONGLONG then
			return "long long int"
		case MS_FLOAT then
			return "float"
		case MS_DOUBLE then
			return "double"
		case MS_LONGDOUBLE then
			return "long double"
		case MS_EUDOUBLE then
			return "eudouble"
		case else
			InternalErr("error finding name for token: [1] [2]", { tid, LexName( tid ) })
	end switch
end function

procedure write_data_type( atom struct_h, symtab_index member )
	
	integer data_type = SymTab[member][S_TOKEN]
	
-- 	printf(1, "Writing data type for: %s - %s\n", { sym_name(member), LexName( data_type )})
	-- signed / unsigned
	if not SymTab[member][S_MEM_SIGNED]
	and data_type != MS_OBJECT
	and data_type != MS_MEMBER then
		-- floating points are always marked signed
		puts( struct_h, "unsigned " )
	end if
	
	if data_type = MS_OBJECT and not SymTab[member][S_MEM_SIGNED] then
		-- this one can't just take an unsigned
		puts( struct_h, "uintptr_t " )
	elsif data_type != MS_MEMBER then
		printf( struct_h, "%s ", { mem_name( data_type )})
	else
		data_type = SymTab[SymTab[member][S_MEM_STRUCT]][S_TOKEN]
		if data_type = MEMUNION then
			-- embedded union
			printf( struct_h, "union %s ", {decorated_name( SymTab[member][S_MEM_STRUCT] ) } )
		else
			-- embedded struct
			printf( struct_h, "struct %s ", {decorated_name( SymTab[member][S_MEM_STRUCT] ) } )
		end if
	end if
	
	if SymTab[member][S_MEM_POINTER] then
		puts( struct_h, "*" )
	end if
	
end procedure

procedure write_memstruct( atom struct_h, symtab_index sym )
	symtab_pointer member = sym
	while member with entry do
		puts( struct_h, "\t" )
		write_data_type( struct_h, member )
		puts( struct_h, decorated_name( member ) )
		if SymTab[member][S_MEM_ARRAY] then
			printf( struct_h, "[%d]", SymTab[member][S_MEM_ARRAY] )
		end if
		printf( struct_h, "; // %d\n", SymTab[member][S_TOKEN] )
	entry
		member = SymTab[member][S_MEM_NEXT]
	end while
	puts( struct_h, "};\n\n" )
end procedure

export procedure write_struct_header()
	atom struct_h = open( output_dir & "struct.h", "w", 1 )
	
	puts( struct_h, "#ifndef STRUCT_H_\n" )
	puts( struct_h, "#define STRUCT_H_\n\n" )
	puts( struct_h, "#include <stdint.h>\n")
	puts( struct_h, "#include \"include/euphoria.h\"\n\n" )
	
	sequence structs = {}
	for i = TopLevelSub to length( SymTab ) do
		integer tok = sym_token( i )
		if tok = MEMSTRUCT then
			printf( struct_h, "struct %s %s;\n", repeat( decorated_name( i ), 2 ) )
			structs &= i
		elsif tok = MEMUNION then
			printf( struct_h, "union %s %s;\n", repeat( decorated_name( i ), 2 ) )
			structs &= i
		end if
	end for
	
	for i = 1 to length( structs ) do
		integer tok = sym_token( structs[i] )
		if tok = MEMSTRUCT then
			printf( struct_h, "struct %s{\n", { decorated_name( structs[i] )} )
			write_memstruct( struct_h, structs[i] )
		elsif tok = MEMUNION then
			printf( struct_h, "union %s{\n", { decorated_name( structs[i])} )
			write_memstruct( struct_h, structs[i] )
		end if
	end for
	
	puts( struct_h, "#endif\n" )
	
end procedure
