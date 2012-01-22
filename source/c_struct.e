-- Translator code for dealing with memstructs
include std/map.e

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

integer memaccess = 0

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
	if not is_pointer( target ) and pointer != target then
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
		if target != pointer then
			dispose_temp( pointer, compile:DISCARD_TEMP, REMOVE_FROM_MAP )
		end if
	end if
	
	add_pointer( target )
	SetBBType( target, TYPE_INTEGER, {MININT, MAXINT}, TYPE_INTEGER, 0 )
	
end procedure

procedure mem_access( integer access_count, integer pointer, integer target )
	get_pointer( pointer, target )
	symtab_index sym = Code[pc+3]
	
	c_stmt( sprintf("@ = (intptr_t) &(((%s*)@)",{struct_type(sym)}), { target, target }, target )
	
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
		was_pointer = SymTab[Code[i]][S_MEM_POINTER]
	end for
	c_puts( ");\n")
end procedure

export procedure opARRAY_ACCESS()
	integer 
		access_count = Code[pc+1],
		pointer      = Code[pc+2],
		subscript    = Code[pc + 3 + access_count],
		target       = Code[pc + 4 + access_count]
	mem_access( access_count, pointer, target )
	memaccess = ARRAY_ACCESS
	symtab_index sym = Code[pc + 2 + access_count]
	c_stmt( sprintf("@ = (intptr_t) (((%s *)@) + @);\n",{get_data_type(sym)}), { target, target, subscript }, target )
	
	pc += access_count + 5
end procedure

export procedure opMEMSTRUCT_ACCESS()
	integer 
		access_count = Code[pc+1],
		pointer      = Code[pc+2],
		target       = Code[pc+ 3 + access_count]
	
	mem_access( access_count, pointer, target )
	memaccess = MEMSTRUCT_ACCESS
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

function get_tagged_name( symtab_index sym )
	sequence tag
	
	while sym_token( sym ) = MEMTYPE do
		sym = SymTab[S_MEM_PARENT]
	end while
	
	if SymTab[sym][S_TOKEN] = MEMSTRUCT then
		tag = "struct"
	else
		tag = "union"
	end if
	return sprintf( "%s %s", { tag, decorated_name( sym ) } )
end function

export procedure opPEEK_ARRAY()
	integer
		pointer   = Code[pc+1],
		sym       = Code[pc+2],
		subscript = Code[pc+3],
		target    = Code[pc+4],
		parent    = SymTab[sym][S_MEM_PARENT]
	
	integer data_type  = SymTab[sym][S_TOKEN]
	integer signed     = SymTab[sym][S_MEM_SIGNED]
	integer is_pointer = SymTab[sym][S_MEM_POINTER]
	sequence type_name, struct_name
	
	get_pointer( pointer, target )
	
	struct_name = get_tagged_name( parent )
	
	switch data_type do
		case MS_MEMBER then
			sym = SymTab[sym][S_MEM_STRUCT]
			fallthru
			
		case MEMSTRUCT, MEMUNION then
			type_name = struct_name
		case else
			type_name = mem_name( data_type )
	end switch
	
	sequence array_modifier = "[_1]"
	integer index_is_int = TypeIs( subscript, TYPE_INTEGER)
	if not index_is_int then
		c_stmt("if( !IS_ATOM_INT( @ ) && IS_ATOM( @ ) ){\n", { subscript, subscript}, subscript )
			c_stmt("_1 = (intptr_t)DBL_PTR( @)->dbl;\n", { subscript })
		c_stmt0("}\n")
		c_stmt0("else{\n")
	end if
	c_stmt( "_1 = @;\n", { subscript } )
	if not index_is_int then
		c_stmt0("}\n")
	end if
	
	c_stmt( sprintf("@ = (intptr_t)&((%s *)@)->%s;\n", {struct_name, decorated_name( sym ) }), { target, target } )
	
	peek_member_value( target, sym, data_type, is_pointer, array_modifier, type_name, signed, target )
	remove_pointer( pointer )
	remove_pointer( target )
	
	pc += 5
end procedure

--**
-- Stores the value pointed to by _0 into the target.  If target is 0,
-- then the caller has already emitted the LHS, and peek_member will
-- only print the RHS.
procedure peek_member( integer pointer, integer sym, integer target, integer array_index = -1, integer deref_ptr = 0 )
	integer data_type  = SymTab[sym][S_TOKEN]
	integer signed     = SymTab[sym][S_MEM_SIGNED]
	integer is_pointer = SymTab[sym][S_MEM_POINTER]
	sequence type_name
	sequence array_modifier = ""
	
	type_name = mem_name( sym_token( sym ) )
	if is_pointer and not deref_ptr then
		data_type = MS_OBJECT
		signed    = 0
		type_name = "object"
	end if
	
	if target then
		CDeRef( target )
	end if
	
	if not signed then
		switch data_type do
			case MS_OBJECT then
				type_name = "uintptr_t"
			case MS_FLOAT, MS_DOUBLE, MS_LONGDOUBLE, MS_EUDOUBLE then
				-- nothing
			case else
				type_name = "unsigned " & type_name
		end switch
	end if
	
	if data_type = MS_MEMBER then
		data_type = sym_token( SymTab[sym][S_MEM_STRUCT] )
	end if
	
	if array_index != -1 then
		array_modifier = sprintf("[%d]", array_index )
	elsif SymTab[sym][S_MEM_ARRAY] and memaccess = MEMSTRUCT_ACCESS then
	
		c_stmt0( sprintf( "_2 = NewS1( %d );\n", SymTab[sym][S_MEM_ARRAY] ) )
		for i = 1 to SymTab[sym][S_MEM_ARRAY] do
			peek_member( pointer, sym, 0, i-1 )
			c_stmt0( sprintf( "((s1_ptr)_2)->base[%d] = _0;\n", i ) )
		end for
		if target then
			c_stmt( "@ = MAKE_SEQ( _2 );\n", target )
		else
			c_stmt0( "_0 = MAKE_SEQ( _2 );\n" )
		end if
		return
		
	end if
	
	if deref_ptr then
		c_stmt( "@ = *(intptr_t*)@;\n", { pointer, pointer }, pointer )
	end if
	peek_member_value( pointer, sym, data_type, is_pointer, array_modifier, type_name, signed, target )
	memaccess = MEMSTRUCT_ACCESS
end procedure

procedure peek_member_value( integer pointer, integer sym, integer data_type,
							 integer is_pointer, sequence array_modifier,
							 sequence type_name, integer signed, integer target )
	integer parent
	switch data_type do
		case MS_FLOAT, MS_DOUBLE, MS_LONGDOUBLE, MS_EUDOUBLE then
			sequence indirect_float = ""
			if not length( array_modifier ) then
				indirect_float = "*"
			end if
			if target then
				c_stmt( sprintf("@ = NewDouble( (eudouble) %s((%s*)@)%s );\n",
								{indirect_float, type_name, array_modifier}),
								{ target, pointer }, target )
			else
				parent =  SymTab[sym][S_MEM_PARENT]
				sequence parent_struct
				switch sym_token( parent ) do
					case MEMSTRUCT, MEMUNION, QUALIFIED_MEMSTRUCT, QUALIFIED_MEMUNION then
						parent_struct = decorated_name( parent )
					case else
						parent_struct = decorated_name( SymTab[parent][S_MEM_STRUCT] )
				end switch
				
				c_stmt( 
						sprintf("_0 = NewDouble( (eudouble) %s(((%s*)@)%s) );\n", 
							{
								indirect_float,
								type_name,
								array_modifier
							}
						), 
						{ pointer }
					)
				
			end if
		
		case MEMUNION then
			read_memunion( pointer, sym )
			if target then
				c_stmt( "@ = _0;\n", target, target )
			end if
		case MEMSTRUCT then
			read_memstruct( pointer, sym )
			if target then
				c_stmt( "@ = _0;\n", target, target )
			end if
		case else
			sequence indirect_read = ""
			if not length( array_modifier ) then
				indirect_read = "*"
			end if
			if target then
				c_stmt( sprintf("@ = %s((%s*)@)%s;\n", {indirect_read, type_name, array_modifier}), { target, pointer }, target )
			else
				c_stmt( 
						sprintf("_0 = %s((%s*)@)%s;\n", 
							{
								indirect_read,
								type_name,
								array_modifier
							}
						),  { pointer } )
				
				if data_type != MS_CHAR and data_type != MS_SHORT label "convert" then
					ifdef E64 then
						ifdef WINDOWS then
							if data_type = MS_LONG then
								-- a long is still 32-bits on 64-bit windows
								break "convert"
							end if
						end ifdef
						
						if data_type = MS_INT /*or is_pointer*/ then
							-- these are always safe under 64-bit arch
							break "convert"
						end if
						
					end ifdef
					c_stmt0("if ((uintptr_t)_0 > (uintptr_t)MAXINT){\n" )
					if signed then
						c_stmt0("_0 = NewDouble((eudouble)(intptr_t)_0);\n" )
					else
						c_stmt0("_0 = NewDouble((eudouble)(uintptr_t)_0);\n" )
					end if
					c_stmt0("}\n")
				end if
			end if
			
	end switch
end procedure

export procedure opPEEK_MEMBER()
	integer
		pointer = Code[pc+1],
		member  = Code[pc+2],
		deref   = Code[pc+3],
		target  = Code[pc+4]
	
	get_pointer( pointer, target )
	
	peek_member( pointer, member, target, /* array index */, deref )
	
	remove_pointer( pointer )
	remove_pointer( target )
	pc += 5
end procedure

integer serialize_level = 0

--**
-- Serialize the specified memstruct into a sequence and store the object in _2.
procedure read_memstruct( integer pointer, symtab_pointer member_sym )
	
	if sym_token( member_sym ) != MEMSTRUCT then
		-- we want to walk the actual struct
		member_sym = SymTab[member_sym][S_MEM_STRUCT]
	end if
	
	
	integer size = 0
	integer size_sym = member_sym
	while size_sym with entry do
		size += 1
	entry
		size_sym = SymTab[size_sym][S_MEM_NEXT]
	end while
	
	serialize_level += 1
	c_stmt0( "{\n" )
	c_stmt0( sprintf("s1_ptr serialize_%d;\n", serialize_level ) )
	c_stmt0( sprintf("serialize_%d = NewS1( %d );\n", { serialize_level, size } ) )
	c_stmt( "_1 = @;\n", pointer )
	integer ix = 0
	sequence parent = get_tagged_name( member_sym )
	while member_sym with entry do
		ifdef DEBUG then
			c_stmt0( sprintf("// peek member: %s.%s\n", {decorated_name( SymTab[member_sym][S_MEM_PARENT] ),  decorated_name( member_sym ) }))
		end ifdef
		c_stmt( sprintf("@ = (intptr_t) & ((%s*)_1)->%s;\n",  { parent, decorated_name( member_sym )}), pointer )
		peek_member( pointer, member_sym, 0  )
		ix += 1
		c_stmt0( sprintf( "serialize_%d->base[%d] = _0;\n", { serialize_level, ix } ) )
		
	entry
		member_sym = SymTab[member_sym][S_MEM_NEXT]
	end while
	
	c_stmt0( sprintf( "_0 = MAKE_SEQ( serialize_%d );\n", serialize_level ) )
	c_stmt( "@ = _1;\n", pointer, pointer )
	c_stmt0( "}\n" )
	serialize_level -= 1
end procedure

--**
-- Serialize the specified memunion into a sequence and store the object in _0.
-- Also uses _1.
procedure read_memunion( integer pointer, symtab_pointer member_sym )
	integer union_sym
	if sym_token( member_sym ) = MEMUNION then
		union_sym = member_sym
	else
		union_sym = SymTab[member_sym][S_MEM_STRUCT]
	end if
	sequence union_name = get_tagged_name( union_sym )
	sequence index_var = sprintf("i_%d", pc )
	c_stmt0("{\n")
	c_stmt0( sprintf( "intptr_t %s;\n", { index_var } ) )
	c_stmt0( sprintf( "_1 = NewS1( sizeof( %s ) );\n", { union_name } ) )
	c_stmt0( sprintf( "for( %s = 0; %s < sizeof( %s ); ++%s){\n", { index_var, index_var, union_name, index_var } ) )
		c_stmt( sprintf( "((s1_ptr)_1)->base[%s+1] = ((unsigned char *) @)[%s];\n", { index_var, index_var } ), pointer )
	c_stmt0( "}\n")
	c_stmt0( "}\n")
	c_stmt0( "_0 = MAKE_SEQ( _1 );\n" )
end procedure

function read_member( integer pointer, integer sym  )
	symtab_pointer member_sym = sym
	integer tid = sym_token( sym )
	if tid >= MS_SIGNED and tid <= MS_OBJECT then
		-- simple serialization of primitives...
		peek_member( pointer, sym, 0 )
		return 0
	end if
	
	integer member_token = sym_token( member_sym )
	if member_token = MEMSTRUCT then
		read_memstruct( pointer, member_sym )
	
	elsif member_token = MEMUNION then
		read_memunion( pointer, member_sym  )
		
	else
		member_token = SymTab[SymTab[member_sym][S_MEM_STRUCT]][S_TOKEN]
		if member_token = MEMSTRUCT then
			read_memstruct( pointer, member_sym )
			
		elsif member_token = MEMUNION then
			read_memunion( pointer, member_sym )
		else
			InternalErr( "Cannot serialize a: [1]", { LexName( member_token )  })
		end if
	end if
	return 1
end function

export procedure opMEMSTRUCT_READ()
	integer
		pointer = Code[pc+1],
		member  = Code[pc+2],
		target  = Code[pc+3]
	
	CDeRef( target )
	get_pointer( pointer, target )
	
	integer is_sequence = read_member( target, member )
	
	c_stmt( "@ = _0;\n", target, target )
	if is_sequence then
		SetBBType( target, TYPE_SEQUENCE, {MININT, MAXINT}, TYPE_OBJECT, 0 )
	else
		SetBBType( target, TYPE_ATOM, {MININT, MAXINT}, TYPE_OBJECT, 0 )
	end if
	remove_pointer( pointer )
	
	pc += 4
end procedure

procedure poke_member_value( symtab_index target, symtab_index val, integer data_type, sequence type_name, integer array_index )
	if array_index != -1 then
		c_stmt( sprintf( "_1 = SEQ_PTR( @ )->base[%d];\n", array_index + 1), val )
	end if
	switch data_type do
		case MS_FLOAT, MS_DOUBLE, MS_LONGDOUBLE, MS_EUDOUBLE then
			integer is_double = TypeIs( val, TYPE_DOUBLE )
			if not is_double then
				
				if array_index = -1 then
					c_stmt( "if( IS_ATOM_INT( @ ) ){\n", val )
					c_stmt( sprintf("*(%s*)@ = (%s)@;\n", {type_name, type_name}), { target, val }, target )
				else
					c_stmt0( "if( IS_ATOM_INT( _1 ) ){\n" )
					c_stmt( sprintf("((%s*)@)[%d] = (%s)_1;\n", {type_name, array_index, type_name}), { target }, target )
				end if
				c_stmt0( "}\n" )
				c_stmt0( "else{\n")
			end if
			if array_index = -1 then
				c_stmt( sprintf("*(%s*)@ = (%s)DBL_PTR( @ )->dbl;\n", {type_name, type_name}), { target, val }, target )
			else
				c_stmt( sprintf("((%s*)@)[%d] = (%s)DBL_PTR( _1 )->dbl;\n", {type_name, array_index, type_name}), { target }, target )
			end if
			
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
				if array_index = -1 then
					c_stmt( "if( IS_ATOM_INT( @ ) ){\n", val )
				else
					c_stmt0( "if( IS_ATOM_INT( _1 ) ){\n" )
				end if
			end if
			
			if array_index = -1 then
				c_stmt( sprintf("*(%s*) @ = (%s) @;\n", {type_name, type_name}), {target, val}, target )
			else
				c_stmt( sprintf("((%s*) @)[%d] = (%s) _1;\n", {type_name, array_index, type_name}), {target }, target )
			end if
			
			if not is_integer then
				c_stmt0("}\n" )
				c_stmt0( "else{\n")
				if array_index = -1 then
					c_stmt( sprintf("*(%s*) @ = (%s) DBL_PTR( @ )->dbl;\n", {type_name, type_name}), {target, val}, target )
				else
					c_stmt( sprintf("((%s*) @)[%d] = (%s) DBL_PTR( _1 )->dbl;\n", {type_name, array_index, type_name}), {target }, target )
				end if
				c_stmt0("}\n" )
			end if
	end switch
end procedure

--**
-- Stores the value into the memory pointed to by _0
procedure poke_member( symtab_index target, symtab_index member, symtab_index val, integer deref_ptr )
	integer data_type = SymTab[member][S_TOKEN]
	integer signed    = SymTab[member][S_MEM_SIGNED]
	
	sequence type_name = mem_name( sym_token( member ) )
	
	if SymTab[member][S_MEM_POINTER] and not deref_ptr then
		data_type = MS_OBJECT
		signed    = 0
		type_name = "object"
	end if
	
	if not signed then
		switch data_type do
			case MS_OBJECT then
				type_name = "uintptr_t"
			case MS_FLOAT, MS_DOUBLE, MS_LONGDOUBLE, MS_EUDOUBLE then
			case else
				type_name = "unsigned " & type_name
		end switch
	end if
	
	if SymTab[member][S_MEM_ARRAY] and memaccess = MEMSTRUCT_ACCESS then
		c_stmt("switch( SEQ_PTR( @ )->length ){\n", val )
		c_stmt0("default:\n")
		for i = SymTab[member][S_MEM_ARRAY] to 1 by -1 do
			c_stmt0( sprintf("case %d:\n", i ) )
			poke_member_value( target, val, data_type, type_name, i-1 )
		end for
		c_stmt0("case 0: ;\n")
		c_stmt0("}\n")
	else
		poke_member_value( target, val, data_type, type_name, -1 )
	end if
	memaccess = MEMSTRUCT_ACCESS
end procedure

procedure poke_memstruct( symtab_index target, symtab_index struct_sym, symtab_index member, integer subscript, 
							integer depth, sequence recursed_members = {} )
	sequence access_path = build_access_path( recursed_members )
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
	
	sequence rhs
	if subscript then
		rhs = sprintf( "src_s1_%d->base[%d]", {depth, subscript} )
	else
		rhs = "0"
	end if
	
	switch data_type do
		case MS_FLOAT, MS_DOUBLE, MS_LONGDOUBLE, MS_EUDOUBLE then
			
			if subscript then
				c_stmt0( sprintf( "if( IS_ATOM_INT( %s ) ){\n", { rhs } ) )
			end if
				c_stmt( sprintf("((struct %s*)@)%s%s = (%s)%s;\n",
								{ decorated_name( struct_sym), access_path, decorated_name( member) ,type_name, rhs}), { target }, target )
			if subscript then
				c_stmt0( "}\n" )
				c_stmt0( "else{\n")
					c_stmt( sprintf("((struct %s*)@)%s%s = (%s)DBL_PTR( %s )->dbl;\n",
								{decorated_name( struct_sym), access_path, decorated_name( member) , type_name, rhs}), { target }, target )
				c_stmt0( "}\n")
			end if
		case MEMUNION then
			-- TODO
		case MEMSTRUCT then
			-- TODO
		case else
			if not signed then
				if data_type = MS_OBJECT then
					type_name = "uintptr_t"
				else
					type_name = "unsigned " & type_name
				end if
			end if
			if subscript then
				c_stmt0( sprintf("if( IS_ATOM_INT( %s ) ){\n", {rhs} ) )
			end if
				c_stmt( sprintf("((struct %s*) @)%s%s = (%s) %s;\n",
							{decorated_name( struct_sym), access_path, decorated_name( member) , type_name, rhs}), {target}, target )
			if subscript then
				c_stmt0("}\n" )
				c_stmt0( "else{\n")
				c_stmt( sprintf("((struct %s*) @)%s%s = (%s) DBL_PTR( %s )->dbl;\n",
								{decorated_name( struct_sym), access_path, decorated_name( member) , type_name, rhs}), {target}, target )
				c_stmt0("}\n" )
			end if
			
	end switch
end procedure

function set_up_assign_sequence( integer source_val, integer depth )
	
	atom seqlen
	integer is_sequence = TypeIs( source_val, TYPE_SEQUENCE )
	
	c_stmt0( sprintf( "s1_ptr src_s1_%d;\n", depth ) )
	
	if depth = 0 and is_sequence then
		-- see if we know how big the sequence is:
		seqlen = SeqLen( source_val )
		c_stmt( sprintf("src_s1_%d = SEQ_PTR( @ );\n", depth ), source_val )
	else
		c_stmt0(sprintf("int free_src_%d;\n", depth ) )
		-- might be an atom
		seqlen = NOVALUE
		if depth = 0 then
			c_stmt("if( IS_ATOM( @ ) || IS_ATOM_INT( @ ) ){\n", { source_val, source_val } )
		else
			c_stmt0("if( IS_ATOM( _1 ) || IS_ATOM_INT( _1 ) ){\n" )
		end if
			c_stmt0(sprintf("free_src_%d = 1;\n", depth ))
			c_stmt0(sprintf("src_s1_%d = NewS1( 1 );\n", depth ) )
			if depth = 0 then
				c_stmt(sprintf("src_s1_%d->base[1] = @;\n", depth ), source_val )
			else
				c_stmt0(sprintf("src_s1_%d->base[1] = _1;\n", depth ) )
			end if
		c_stmt0("}\n")
		c_stmt0("else {\n" )
			c_stmt0(sprintf("free_src_%d = 0;\n", depth ) )
			if depth = 0 then
				c_stmt(sprintf("src_s1_%d = SEQ_PTR( @ );\n", depth ), source_val )
			else
				c_stmt0(sprintf("src_s1_%d = SEQ_PTR( _1 );\n", depth ) )
			end if
		c_stmt0("}\n")
	end if
	return is_sequence & seqlen
end function

function access_type( symtab_index member )
	if SymTab[member][S_MEM_POINTER] then
		return "->"
	else
		return '.'
	end if
end function

function build_access_path( sequence members )
	sequence path = "->"
	for i = 1 to length( members ) do
		path &= decorated_name( members[i] )
		path &= access_type( members[i] )
	end for
	return path
end function

procedure poke_array_value( integer pointer, integer depth, integer data_type, sequence access_path, sequence type_name, sequence struct_name )

	switch data_type do
		case MS_FLOAT, MS_DOUBLE, MS_LONGDOUBLE, MS_EUDOUBLE then
			c_stmt0( "if( IS_ATOM_INT( _1 ) ){\n" )
			c_stmt( sprintf("((%s*)@)%s[ax%d] = (%s)_1;\n", {struct_name, access_path, depth, type_name}), pointer )
			c_stmt0( "}\n" )
			c_stmt0( "else{\n")
			c_stmt( sprintf("((%s*)@)%s[ax%d] = (%s)DBL_PTR( _1 )->dbl;\n", {struct_name, access_path, depth, type_name}), pointer )
			c_stmt0( "}\n")
			
		case MEMUNION then
			-- TODO
		case MEMSTRUCT then
			-- TODO
		case else
			c_stmt0( "if( IS_ATOM_INT( _1 ) ){\n" )
			c_stmt( sprintf("((%s*)@)%s[ax%d] = (%s) _1;\n", {struct_name, access_path, depth, type_name} ), pointer )
			c_stmt0("}\n" )
			c_stmt0( "else{\n")
			c_stmt( sprintf("((%s*)@)%s[ax%d] = (%s) DBL_PTR( _1 )->dbl;\n", {struct_name, access_path, depth, type_name } ), pointer )
			c_stmt0("}\n" )
	end switch
end procedure

procedure assign_array( integer pointer, integer struct_sym, integer source_val, sequence recursed_members = {} )
-- use a private block
	integer depth = length( recursed_members ) + 1
	
	c_stmt0("{\n")
	c_stmt0( sprintf("int ax%d;\n", depth ) )
	
	sequence seq_len     = set_up_assign_sequence( source_val, depth )
	integer  is_sequence = seq_len[1]
	atom     seqlen      = seq_len[2]
	
	integer member_sym = struct_sym
	if length( recursed_members ) then
		member_sym = recursed_members[$]
	end if
	sequence access_path = build_access_path( recursed_members[1..$-1] ) & decorated_name( member_sym )
	integer array_length = SymTab[member_sym][S_MEM_ARRAY]
	integer data_type = sym_token( member_sym )
	sequence type_name = get_data_type( member_sym )
	sequence struct_name = get_tagged_name( struct_sym )
	ifdef DEBUG then
		c_stmt0( sprintf("// %s: [%d] %s access path: %s\n", { sym_name( member_sym ), array_length, LexName( data_type ), access_path } ) )
	end ifdef
	c_stmt0( sprintf( "for( ax%d = 0; ax%d < src_s1_%d->length && ax%d < %d; ++ax%d ){\n", repeat( depth, 4 ) & array_length & depth ) )
	c_stmt0( sprintf( "_1 = src_s1_%d->base[ax%d+1];\n", depth ) )
	
	
	if data_type = MS_MEMBER then
		assign_memstruct( pointer, struct_sym, source_val, recursed_members & member_sym)
	else
		poke_array_value( pointer, depth, data_type, access_path, type_name, struct_name )
	end if
	c_stmt0("}\n")
	
	c_stmt0("_1 = 0;\n")
	c_stmt0( sprintf( "for( ; ax%d < src_s1_%d->length && ax%d < %d; ++ax%d ){\n", repeat( depth, 3 ) & array_length & depth ) )
	
	if data_type = MS_MEMBER then
		assign_memstruct( pointer, struct_sym, source_val, recursed_members & member_sym)
	else
		poke_array_value( pointer, depth, data_type, access_path, type_name, struct_name )
	end if
	c_stmt0("}\n")
	
	if not is_sequence then
		c_stmt0( sprintf( "if( free_src_%d ){\n", depth ) )
		c_stmt0( sprintf( "DeRefDS( MAKE_SEQ(src_s1_%d) );\n", depth ) )
		c_stmt0("}\n" )
	end if
	
	c_stmt0("}\n")
end procedure

procedure assign_memstruct( integer pointer, integer struct_sym, integer source_val, sequence recursed_members = {} )
	-- use a private block
	integer depth = length( recursed_members )
	c_stmt0("{\n")
	sequence seq_len     = set_up_assign_sequence( source_val, depth )
	integer  is_sequence = seq_len[1]
	atom     seqlen      = seq_len[2]
	
	integer members = 0
	integer member_sym = struct_sym
	if length( recursed_members ) then
		member_sym = SymTab[recursed_members[$]][S_MEM_STRUCT]
	end if
	sequence member_list = {}
	while member_sym with entry do
		members += 1
		member_list &= member_sym
	entry
		member_sym = SymTab[member_sym][S_MEM_NEXT]
	end while
	
	if seqlen != NOVALUE then
		ifdef DEBUG then
			c_stmt0( sprintf("// known sequence length: %d\n", seqlen ) )
		end ifdef
		integer ix = 1
		member_sym = SymTab[struct_sym][S_MEM_NEXT]
		while ix <= seqlen and member_sym do
			if sym_token( member_sym ) = MS_MEMBER then
				c_stmt0( sprintf( "_1 = src_s1_%d->base[%d];\n", { depth, ix } ) )
				assign_memstruct( pointer, struct_sym, source_val, recursed_members & member_sym )
			elsif SymTab[member_sym][S_MEM_ARRAY] then
				c_stmt0( sprintf( "_1 = src_s1_%d->base[%d];\n", { depth, ix } ) )
				ifdef DEBUG then
					c_stmt0( sprintf("// %s is an array (length %d)! now what?\n",{ sym_name( member_sym ), SymTab[member_sym][S_MEM_ARRAY] } ) )
				end ifdef
				assign_array( pointer, struct_sym, source_val, recursed_members & member_sym )
			else
				poke_memstruct( pointer, struct_sym, member_sym, ix, depth, recursed_members )
			end if
			ix += 1
			member_sym = SymTab[member_sym][S_MEM_NEXT]
		end while
		
		while member_sym do
			-- zero out the rest
			poke_memstruct( pointer, struct_sym, member_sym, 0, 0 )
			member_sym = SymTab[member_sym][S_MEM_NEXT]
		end while
	else
		-- unknown length:
		c_stmt0( sprintf( "switch( src_s1_%d->length ){\n", depth ) )
			-- the sequence is bigger than the struct:
			c_stmt0("default:\n")
			for i = members to 1 by -1 do
				c_stmt0( sprintf( "case %d:\n", i ) )
				if sym_token( member_list[i] ) = MS_MEMBER then
					c_stmt0( sprintf( "_1 = src_s1_%d->base[%d];\n", { depth, i } ) )
					assign_memstruct( pointer, struct_sym, source_val, recursed_members & member_list[i])
				else
					poke_memstruct( pointer, struct_sym, member_list[i], i, depth, recursed_members )
				end if
				
			end for
			c_stmt0( "case 0: break;\n" )
		c_stmt0("}\n")
		
		c_stmt0( sprintf("switch( src_s1_%d->length + 1 ){\n", depth ) )
			for i = 0 to members do
				c_stmt0( sprintf( "case %d:\n", i ) )
				if i then
					poke_memstruct( pointer, struct_sym, member_list[i], 0, 0, recursed_members )
				end if
			end for
			c_stmt0("default: break;\n")
		c_stmt0("}\n")
	end if
	
	if not is_sequence then
		c_stmt0( sprintf( "if( free_src_%d ){\n", depth ) )
		c_stmt0( sprintf( "DeRefDS( MAKE_SEQ(src_s1_%d) );\n", depth ) )
		c_stmt0("}\n" )
	end if
	
	c_stmt0("}\n")
end procedure

procedure assign_memunion( integer pointer, integer struct_sym, integer source_val, integer depth )
	c_stmt0("{\n")
	c_stmt0("unsigned char *ptr;\n")
	c_stmt0("int i;\n")
	sequence seq_len     = set_up_assign_sequence( source_val, depth )
	integer  is_sequence = seq_len[1]
	atom     seqlen      = seq_len[2]
	
	integer union_size = SymTab[struct_sym][S_MEM_SIZE]
	
	c_stmt("ptr = (unsigned char *) @;\n", pointer )
	if seqlen = NOVALUE then
		-- unknown length
		c_stmt0(sprintf("for( i = 1; i <= src_s1_%d->length && i <= %d; ++i, ++ptr ){\n", {depth, union_size} ) )
			c_stmt0( sprintf("*ptr = (unsigned char) src_s1_%d->base[i];\n", depth ) )
		c_stmt0("}\n")
		
		c_stmt0(sprintf("for( i = src_s1_%d->length + 1; i <= %d; ++i, ++ptr ){\n", {depth, union_size} ) )
			c_stmt0("*ptr = 0;\n")
		c_stmt0("}\n")
		
	else
		-- we know the length
		if seqlen > union_size then
			seqlen = union_size
		end if
		
		for i = 1 to seqlen do
			c_stmt0( sprintf("*ptr++ = (unsigned char) src_s1_%d->base[%d];\n", { depth, i} ) )
		end for
		
		for i = seqlen + 1 to union_size do
			c_stmt0( "*ptr++ = 0;\n" )
		end for
	end if
	
	if not is_sequence then
		c_stmt0( sprintf( "if( free_src_%d ){\n", depth ) )
		c_stmt0( sprintf( "DeRefDS( MAKE_SEQ(src_s1_%d) );\n", depth ) )
		c_stmt0("}\n" )
	end if
	c_stmt0("}\n")
end procedure


export procedure opMEMSTRUCT_ASSIGN()
	integer
		pointer   = Code[pc+1],
		member    = Code[pc+2],
		val       = Code[pc+3],
		deref_ptr = Code[pc+4]
	
	get_pointer( pointer, pointer )
	
	integer tok = sym_token( member )
	integer is_pointer = SymTab[member][S_MEM_POINTER]
	if is_pointer then
		if deref_ptr then
			c_stmt( "@ = *(intptr_t*)@;\n", { pointer, pointer }, pointer )
		else
			tok = -1
		end if
	end if
	
	ifdef DEBUG then
		c_stmt0(sprintf( "// MEMSTRUCT_ASSIGN %s\n", { LexName( tok ) } ) )
	end ifdef
	switch tok do
		case MEMSTRUCT then
			assign_memstruct( pointer, member, val )
		case MS_MEMBER then
			assign_memstruct( pointer, SymTab[member][S_MEM_STRUCT], val )
		case MEMUNION then
			assign_memunion( pointer, member, val, 0 )
		case else
			poke_member( pointer, member, val, deref_ptr )
	end switch
	
	
	dispose_temp( val, compile:DISCARD_TEMP, REMOVE_FROM_MAP )
	remove_pointer( pointer )
	
	pc += 5
end procedure


export procedure opMEMSTRUCT_ASSIGNOP()
	integer
		op        = Code[pc],
		pointer   = Code[pc+1],
		member    = Code[pc+2],
		val       = Code[pc+3],
		deref_ptr = Code[pc+4]
	
	get_pointer( pointer, pointer )
	
	if deref_ptr then
		c_stmt( "@ = *(intptr_t**) @;\n", { pointer, pointer }, pointer )
	end if
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
					c_stmt( sprintf("*(%s*)@ %s= (%s)@;\n", {type_name, optext, type_name}), { pointer, val }, pointer )
				c_stmt0( "}\n" )
				c_stmt0( "else{\n")
			end if
			
			c_stmt( sprintf("*(%s*)@ %s= (%s)DBL_PTR( @ )->dbl;\n", {type_name, optext, type_name}), { pointer, val }, pointer )
			
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
	pc += 5
end procedure

export procedure opADDRESSOF()
	integer
		ptr    = Code[pc+1],
		target = Code[pc+2]
	CDeRef( target )
	c_stmt("if( IS_ATOM_INT( @ ) ){\n", ptr )
		c_stmt("@ = @;\n", { target, ptr }, target )
	c_stmt0("}\n")
	c_stmt0("else {\n")
		c_stmt("@ = NewDouble( (eudouble) @ );\n", {target, ptr}, target )
	c_stmt0( "}\n")
	SetBBType( target, TYPE_ATOM, {MININT, MAXINT}, TYPE_OBJECT, 0 )
	
	pc += 3
end procedure

export procedure opOFFSETOF()
	integer
		count   = Code[pc+1],
		target  = Code[pc+2+count],
		parent,
		member
	
	CDeRef( target )
	sequence 
		memstruct_name,
		member_name
	
	if count = 1 then
		member  = Code[pc+2]
		parent  = SymTab[member][S_MEM_PARENT]
		memstruct_name = decorated_name( parent )
		member_name    = decorated_name( member )
		c_stmt( sprintf("@ = offsetof( %s %s, %s);\n", { mem_name( sym_token( parent ) ), memstruct_name, member_name } ), { target }, target )
	else
		c_stmt0( "_0 = 0;\n" )
		for i = 1 to count do
			member = Code[pc+i+1]
			parent = SymTab[member][S_MEM_PARENT]
			
			memstruct_name = decorated_name( parent )
			member_name    = decorated_name( member )
			c_stmt0( sprintf("_0 += offsetof( %s %s, %s);\n", { mem_name( sym_token( parent ) ), memstruct_name, member_name } ) )
		end for
		c_stmt( "@ = _0;\n", target, target )
	end if
	
	pc += 3 + count
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
		case MEMSTRUCT then
			return "struct"
		case MEMUNION then
			return "union"
		case MS_MEMBER then
			return ""
		case else
			InternalErr("error finding name for token: [1] [2]", { tid, LexName( tid ) })
	end switch
end function

function get_data_type( symtab_index member )
	integer data_type = SymTab[member][S_TOKEN]
	sequence name = ""
	
-- 	printf(1, "Writing data type for: %s - %s\n", { sym_name(member), LexName( data_type )})
	-- signed / unsigned
	if not SymTab[member][S_MEM_SIGNED]
	and data_type != MS_OBJECT
	and data_type != MS_MEMBER
	and data_type != MS_FLOAT
	and data_type != MS_DOUBLE 
	and data_type != MS_LONGDOUBLE 
	and data_type != MS_EUDOUBLE
	then
		-- floating points are always marked signed
		name &= "unsigned "
	end if
	
	if data_type = MS_OBJECT and not SymTab[member][S_MEM_SIGNED] then
		-- this one can't just take an unsigned
		name &= "uintptr_t "
	elsif data_type != MS_MEMBER then
		name &= sprintf( "%s ", { mem_name( data_type )})
	else
		data_type = SymTab[SymTab[member][S_MEM_STRUCT]][S_TOKEN]
		if data_type = MEMUNION then
			-- embedded union
			name &= sprintf( "union %s ", {decorated_name( SymTab[member][S_MEM_STRUCT] ) } )
		else
			-- embedded struct
			name &= sprintf( "struct %s ", {decorated_name( SymTab[member][S_MEM_STRUCT] ) } )
		end if
	end if
	
	if SymTab[member][S_MEM_POINTER] then
		name &= "*"
	end if
	return name
end function

procedure write_data_type( atom struct_h, symtab_index member )
	puts( struct_h, get_data_type( member ) )
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

function struct_dependencies( sequence structs, symtab_index sym, map already_declared )
	if map:get( already_declared, sym, 0 ) then
		return structs
	end if

	integer s = sym
	while s with entry do
		if not SymTab[s][S_MEM_POINTER] then
			-- we don't have to worry about pointers
			integer tok = sym_token( s )
			integer mt = s

			while tok = MEMTYPE do
				mt = SymTab[mt][S_MEM_PARENT]
				tok = sym_token( mt )
			end while
			
			if tok = MS_MEMBER then
				mt = SymTab[mt][S_MEM_STRUCT]
				if mt and not map:get( already_declared, mt ) then
					structs &= mt
					map:put( already_declared, mt, 1 )
					
				end if
			end if
		end if
	entry
		s = SymTab[s][S_MEM_NEXT]
	end while
	if not map:get( already_declared, sym ) then
		structs &= sym
		map:put( already_declared, sym, 1 )
	end if
	return structs
end function

export procedure write_struct_header()
	atom struct_h = open( output_dir & "struct.h", "w", 1 )
	generated_files = append( generated_files, "struct.h" )
	
	puts( struct_h, "#ifndef STRUCT_H_\n" )
	puts( struct_h, "#define STRUCT_H_\n\n" )
	puts( struct_h, "#include <stdint.h>\n")
	puts( struct_h, "#include <stddef.h>\n")
	puts( struct_h, "#include \"include/euphoria.h\"\n\n" )
	
	sequence structs = {}
	map already_declared = map:new()
	for i = TopLevelSub to length( SymTab ) do
		integer tok = sym_token( i )
		if tok = MEMSTRUCT then
			printf( struct_h, "struct %s %s;\n", repeat( decorated_name( i ), 2 ) )
			structs = struct_dependencies( structs, i, already_declared )
		elsif tok = MEMUNION then
			printf( struct_h, "union %s %s;\n", repeat( decorated_name( i ), 2 ) )
			structs = struct_dependencies( structs, i, already_declared )
		end if
	end for
	
	for i = 1 to length( structs ) do
		integer tok = sym_token( structs[i] )
		if SymTab[structs[i]][S_MEM_PACK] then
			printf( struct_h, "#pragma pack( push, %d )\n", SymTab[structs[i]][S_MEM_PACK] )
		end if
		if tok = MEMSTRUCT then
			printf( struct_h, "struct %s{\n", { decorated_name( structs[i] )} )
			write_memstruct( struct_h, structs[i] )
		elsif tok = MEMUNION then
			printf( struct_h, "union %s{\n", { decorated_name( structs[i])} )
			write_memstruct( struct_h, structs[i] )
		end if
		if SymTab[structs[i]][S_MEM_PACK] then
			printf( struct_h, "#pragma pack( pop )\n" )
		end if
		
	end for
	
	puts( struct_h, "#endif\n" )
	
end procedure
