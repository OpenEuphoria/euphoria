with trace


include std/unittest.e

include std/dll.e
include std/machine.e

type token_id( object id )
	if integer(id) then
		if id < 542 then
			if id > -101 then
				return 1
			end if
		end if
	end if
	return 0
end type

set_test_verbosity( TEST_SHOW_ALL )
memstruct Var
	pointer symtab_entry declared_in
end memstruct

memstruct Block
	unsigned int first_line
	unsigned int last_line
end memstruct

memstruct private_block
	int task_number
	pointer private_block next
	object block[2]
end memstruct

memstruct Subp
	pointer object code
	pointer symtab_entry temps
	pointer private_block saved_privates
	pointer object block
	pointer int linetab
	unsigned int firstline
	unsigned int num_args
	int resident_task
	unsigned int stack_space
end memstruct

memunion U
	Var var
	Subp subp
	Block block
end memunion

memstruct symtab_entry
	object obj
	pointer symtab_entry next
	pointer symtab_entry next_in_block
	char mode
	char scope
	unsigned char file_no
	unsigned char dummy
	int as token_id token
	pointer char name
	U u
end memstruct

memstruct SymbolTable
	symtab_entry entries[5]
end memstruct

integer bits32 = sizeof( C_POINTER ) = 4
procedure basic()
	atom symtab = allocate( 5 * sizeof( symtab_entry ) )
	poke( symtab,  repeat( 0, 5 * sizeof( symtab_entry ) ) )
	symtab.symtab_entry.obj = 9
	symtab.symtab_entry.obj += 5
	symtab.symtab_entry.obj -= 2
	symtab.symtab_entry.obj *= 6
	symtab.symtab_entry.obj /= 3
	
	test_equal("object read / write assignment / read", peek_pointer( symtab ), symtab.symtab_entry.obj )
	
	symtab.symtab_entry[1].obj = 1
	symtab.symtab_entry.next = symtab.symtab_entry[1]
	
	integer offset
	if bits32 then
		offset = 4
	else
		offset = 8
	end if
	
	test_equal("pointer read / write", peek_pointer( symtab + offset ), symtab.symtab_entry.next)
	
	symtab.symtab_entry.next.obj = -42
	if bits32 then
		test_equal( "read / write following pointer (32)", peek4s( symtab + sizeof( symtab_entry)), symtab.symtab_entry.next.obj )
	else
		test_equal( "read / write following pointer (64)", peek8s( symtab + sizeof( symtab_entry)), symtab.symtab_entry.next.obj )
	end if
	
	symtab.symtab_entry.u.var.declared_in = 0x01010101
	test_equal("read / write union member", 0x01010101, symtab.symtab_entry.u.var.declared_in )
-- 	object serialized = symtab.symtab_entry.u.* 
-- 	test_equal("serialize union", {1,1,1,1} & repeat( 0, sizeof( U ) - 4), serialized )
-- 	serialized = {
-- 				symtab.symtab_entry.obj,
-- 				symtab.symtab_entry.next,
-- 				symtab.symtab_entry.next_in_block,
-- 				symtab.symtab_entry.mode,
-- 				symtab.symtab_entry.scope,
-- 				symtab.symtab_entry.file_no,
-- 				symtab.symtab_entry.dummy,
-- 				symtab.symtab_entry.token,
-- 				symtab.symtab_entry.name,
-- 				symtab.symtab_entry.u.*
-- 			}
-- 	test_equal("serialize struct", serialized, symtab.symtab_entry.* )
-- 	
-- 	test_equal( "sizeof arrays of structs", sizeof( symtab_entry ) * 5, sizeof( SymbolTable ) )
-- 	test_equal( "serialize array length", 5, length( symtab.SymbolTable.* ) )
end procedure
basic()

test_report()
