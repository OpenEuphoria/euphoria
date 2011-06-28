-- Translator code for dealing with memstructs

include c_decl.e
include c_out.e
include compile.e
include emit.e
include global.e
include reswords.e
include symtab.e

with trace

-- Use this to communicate between ops so we can avoid changing
-- pointers into doubles.
integer target_is_pointer = 0

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

procedure get_pointer( integer pointer )
	if not TypeIs( pointer, TYPE_INTEGER ) then
		c_stmt("if( IS_ATOM_INT( @ ) ){\n", pointer )
	end if
	
	c_stmt( "_0 = @;\n", pointer )
	
	if not TypeIs( pointer, TYPE_INTEGER ) then
		c_stmt0( "}\n")
		c_stmt0( "else{\n")
			c_stmt("_0 = (intptr_t) DBL_PTR( @ )->dbl;\n", pointer )
		c_stmt0( "}\n")
	end if
end procedure

export procedure opMEMSTRUCT_ACCESS()
	integer 
		access_count = Code[pc+1],
		pointer      = Code[pc+2],
		target       = Code[pc+ 3 + access_count]
	
	get_pointer( pointer )
	
	CDeRef( target )
	
	symtab_index sym = Code[pc+3]
	
	c_stmt( sprintf("@ = ((%s*)_0)",{struct_type(sym)}), { target }, target )
	
	integer 
		first_pc    = pc + 3,
		last_pc     = pc + 2 + access_count,
		was_pointer = 1
	
	for i = first_pc to last_pc - 1 do
		if was_pointer then
			c_puts("->")
		else
			c_puts(".")
		end if
		CName( Code[i] )
	end for
	c_puts( ";\n")
	dispose_temp( pointer, compile:DISCARD_TEMP, REMOVE_FROM_MAP )
	SetBBType( target, TYPE_INTEGER, {MININT, MAXINT}, TYPE_INTEGER, 0 )
	target_is_pointer = target
	pc += access_count + 4
end procedure

export procedure opMEMSTRUCT_ARRAY()
	? 1/0
end procedure

procedure peek_member( integer pointer, integer sym, integer target )
	integer data_type = SymTab[sym][S_TOKEN]
	integer signed    = SymTab[sym][S_MEM_SIGNED]
	
	if SymTab[sym][S_MEM_POINTER] then
		data_type = MS_OBJECT
		signed    = 0
	end if
	
	CDeRef( target )
	sequence type_name = mem_name( sym_token( sym ) )
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
		
		case else
			c_stmt( sprintf("@ = *(%s*)@;\n", {type_name}), { target, pointer }, target )
			
	end switch
	
end procedure

export procedure opPEEK_MEMBER()
	integer
		pointer = Code[pc+1],
		member  = Code[pc+2],
		target  = Code[pc+3]
	
	if pointer != target_is_pointer then
		get_pointer( pointer )
	end if
	
	peek_member( pointer, member, target )
	
	target_is_pointer = 0
	pc += 4
end procedure


export procedure opMEMSTRUCT_SERIALIZE()
	? 1/0
end procedure


export procedure opMEMSTRUCT_ASSIGN()
	? 1/0
end procedure


export procedure opMEMSTRUCT_ASSIGNOP()
	? 1/0
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
