with trace


include std/unittest.e

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
	token_id as int token
	pointer char name
	U u
end memstruct

memstruct SymbolTable
	symtab_entry entries[5]
end memstruct

memtype SymbolTable as SymTab5

integer bits32 = (sizeof( pointer ) = 4)
procedure basic()
	atom symtab = allocate( sizeof( SymTab5 ) )
	poke( symtab,  repeat( 0, 5 * sizeof( symtab_entry ) ) )
	symtab.symtab_entry.obj = 9
	symtab.symtab_entry.obj += 5
	symtab.symtab_entry.obj -= 2
	symtab.symtab_entry.obj *= 6
	symtab.symtab_entry.obj /= 3
	
	test_equal("object read / write assignment / read", peek_pointer( symtab ), symtab.symtab_entry.obj )
	
	test_equal("addressof 1", symtab, addressof( symtab.symtab_entry.obj ) )
	
	test_equal("offsetof 1", 0, offsetof( symtab_entry.obj ) )
	
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
	
	object serialized = symtab.symtab_entry.u
	test_equal( "addressof vs offsetof", symtab + offsetof( symtab_entry.u ), addressof( symtab.symtab_entry.u ) )
	test_equal("serialize union", {1,1,1,1} & repeat( 0, sizeof( U ) - 4), serialized )
	serialized = {
				symtab.symtab_entry.obj,
				symtab.symtab_entry.next,
				symtab.symtab_entry.next_in_block,
				symtab.symtab_entry.mode,
				symtab.symtab_entry.scope,
				symtab.symtab_entry.file_no,
				symtab.symtab_entry.dummy,
				symtab.symtab_entry.token,
				symtab.symtab_entry.name,
				symtab.symtab_entry.u
			}
	test_equal("serialize struct", serialized, symtab.symtab_entry )
	test_equal("serialize union", 
			peek( { addressof( symtab.symtab_entry.u ), sizeof( U ) } ),
			symtab.symtab_entry.u )
	
	sequence SymTab_Serialized = symtab.SymbolTable
	test_equal( "sizeof arrays of structs", sizeof( symtab_entry ) * 5, sizeof( SymbolTable ) )
	test_equal( "serialize array length", 5, length( SymTab_Serialized[1] ) )
end procedure
basic()

memstruct ASSIGN
	char a
	unsigned short b
	int c
	long d
	float e
	double f
	long long g
	object h
end memstruct

memunion UNION_ASSIGN
	char a
	short b
	int c
	long d
	long long e
end memunion

procedure bulk_assign()
	atom ptr = allocate( sizeof( ASSIGN ), 1 )
	ptr.ASSIGN = {}
	test_equal( "assign an empty sequence -> memset 0", repeat( 0, 8 ), ptr.ASSIGN )
	
	ptr.ASSIGN = { 1, 2, 3, 4, 5, 6, 7, 8}
	test_equal( "bulk assign #1", { 1, 2, 3, 4, 5, 6, 7, 8}, ptr.ASSIGN )
	
	ptr = allocate( sizeof( UNION_ASSIGN ), 1 )
	ptr.UNION_ASSIGN = 0
	test_equal( "union assign atom", repeat( 0, sizeof( UNION_ASSIGN ) ), ptr.UNION_ASSIGN )
	
	ptr.UNION_ASSIGN = {255, 255, 255, 255}
	test_equal( "union assign sequence", -1, ptr.UNION_ASSIGN.c )
	
end procedure
bulk_assign()

-- Make sure we correctly parse all of these multi-part primitive types:
memtype unsigned int as uint
export memtype signed int as sint

global memtype long int as lint
memtype signed long int as slint
memtype unsigned long int as ulint

memtype long long as llong
memtype signed long long as sllong
memtype unsigned long long as ullong

-- list of memtypes
public memtype 
	long long int as llint,
	signed long long int as sllint,
	unsigned long long int as ullint,
	$

memtype long double as ldouble

test_pass( "multi-part memtype declarations" )

test_equal("sizeof( memtype ) vs sizeof( primitive )", sizeof( uint ), sizeof( unsigned int ) )

memstruct one_pointer
	pointer int p
end memstruct
test_equal( "sizeof( object ) same as pointer", sizeof( object ), sizeof( one_pointer ) )

test_equal( "sizeof( float ) = 4", 4, sizeof( float ) )
test_equal( "sizeof( double ) = 8", 8, sizeof( double ) )

ifdef BITS32 then
	test_equal( "sizeof( eudouble ) = sizeof( double )", sizeof( double ), sizeof( eudouble ) )
elsedef
	test_equal( "sizeof( eudouble ) = sizeof( long double )", sizeof( long double), sizeof( eudouble ) )
end ifdef

test_equal( "sizeof( pointer ) = sizeof( object )", sizeof( pointer ), sizeof( object ) )

test_equal( "sizeof( signed int) = sizeof( sint )", sizeof( signed int ), sizeof( sint ) )
test_equal( "sizeof( unsigned int) = sizeof( uint )", sizeof( unsigned int ), sizeof( uint ) )

test_equal( "sizeof( long int) = sizeof( lint )", sizeof( long int ), sizeof( lint ) )
test_equal( "sizeof( signed long int) = sizeof( slint )", sizeof( signed long int ), sizeof( slint ) )
test_equal( "sizeof( unsigned long int) = sizeof( ulint )", sizeof( unsigned long int ), sizeof( ulint ) )

test_equal( "sizeof( long long ) = sizeof( llong )", sizeof( long long ), sizeof( llong ) )
test_equal( "sizeof( signed long long ) = sizeof( sllong )", sizeof( signed long long ), sizeof( sllong ) )
test_equal( "sizeof( unsigned long long ) = sizeof( ullong )", sizeof( unsigned long long ), sizeof( ullong ) )

memstruct ARRAYS
	int   five_ints[5]
	long  ten_longs[10]
	float three_floats[3]
	double four_doubles[4]
end memstruct

procedure arrays()
	atom ptr = allocate( sizeof( ARRAYS ), 1 )
	
	ptr.ARRAYS.five_ints = { 1, 2, 3, 4, 5 }
	test_equal( "array bulk assign and peek ints", {1,2,3,4,5}, ptr.ARRAYS.five_ints )
	ptr.ARRAYS.five_ints[0] = -1
	test_equal( "array assign and peek element ints", -1, ptr.ARRAYS.five_ints[0] )
	
	ptr.ARRAYS.ten_longs = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
	test_equal( "array bulk assign and peek longs", { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }, ptr.ARRAYS.ten_longs )
	ptr.ARRAYS.ten_longs[9] = -1
	test_equal( "array assign and peek element longs", -1, ptr.ARRAYS.ten_longs[9] )
	
	ptr.ARRAYS.three_floats = {1.25, 1.5, 1.375 }
	test_equal( "array bulk assign and peek floats", {1.25, 1.5, 1.375 }, ptr.ARRAYS.three_floats )
	ptr.ARRAYS.three_floats[1] = -1
	test_equal( "array assign and peek element floats", -1, ptr.ARRAYS.three_floats[1] )
	
	ptr.ARRAYS.four_doubles = {1.1, 1.2, 1.3, 4.1 }
	test_equal( "array bulk assign and peek doubles", {1.1, 1.2, 1.3, 4.1 }, ptr.ARRAYS.four_doubles )
	ptr.ARRAYS.four_doubles[2] = 8.6
	test_equal( "array assign and peek element doubles", 8.6, ptr.ARRAYS.four_doubles[2] )
	
end procedure
arrays()

memstruct POINTERS
	pointer int a
	pointer object b
	pointer unsigned long c
	pointer float d
	pointer double dbl
end memstruct

procedure pointers()
	atom ptr = allocate( sizeof( POINTERS ), 1 )
	atom secondary = allocate( 1024 )
	ptr.POINTERS = repeat( secondary, 5 )
	
	ptr.POINTERS.a.* = 1234
	test_equal( "dereferenced pointer assign / read int", 1234, ptr.POINTERS.a.* )
	
	ptr.POINTERS.a.* += 5
	test_equal( "dereferenced pointer += int", 1239, ptr.POINTERS.a.* )
	
	ptr.POINTERS.b.* = 123456
	test_equal( "dereferenced pointer assign / read object", 123456, ptr.POINTERS.b.* )
	
	ptr.POINTERS.b.* -= 4
	test_equal( "dereferenced pointer -= object", 123452, ptr.POINTERS.b.* )
	
	ptr.POINTERS.c.* = 51234
	test_equal( "dereferenced pointer assign / read unsigned long", 51234, ptr.POINTERS.c.* )
	
	ptr.POINTERS.c.* *= 2
	test_equal( "dereferenced pointer *= unsigned long", 51234 * 2, ptr.POINTERS.c.* )
	
	ptr.POINTERS.d.* = 3.5
	test_equal( "dereferenced pointer assign / read float", 3.5, ptr.POINTERS.d.* )
	
	ptr.POINTERS.d.* /= 2
	test_equal( "dereferenced pointer /= float", 1.75, ptr.POINTERS.d.* )
	
	ptr.POINTERS.dbl.* = 9.75
	test_equal( "dereferenced pointer assign / read double", 9.75, ptr.POINTERS.dbl.* )
	
end procedure
pointers()

memstruct ESTRUCT
	int e
end memstruct
procedure not_scientific_notation()
	atom ptr = allocate( sizeof( ESTRUCT ), 1 )
	test_equal("offsetof not scientific notation", 0, offsetof( ESTRUCT.e ) )
	test_equal("addressof not scientific notation", ptr, addressof( ptr.ESTRUCT.e ) )
end procedure
not_scientific_notation()


test_report()
