with define SAFE
include std/machine.e
include std/unittest.e
include std/dll.e

edges_only = 0

std_library_address addr

addr = allocate_protect( {1,2,3,4}, 1, PAGE_NONE )

if addr != 0 then
	test_pass("PAGE_NONE memory was allocated by allocate_protect")
	test_false("PAGE_NONE memory readable", safe_address(addr, 4, A_READ))
	test_false("PAGE_NONE memory writable", safe_address(addr, 4, A_WRITE))
	test_false("PAGE_NONE memory executable", safe_address( addr, 4, A_EXECUTE ))
	free_code(addr, 4)
else
	test_fail("PAGE_NONE memory could not be allocated by allocate_protect")
end if

addr = allocate_protect( {1,2,3,4}, 1, PAGE_READ )

if addr != 0 then
	test_pass("PAGE_READ memory was allocated by allocate_protect")
	test_true("PAGE_READ memory readable", safe_address(addr, 4, A_READ))
	test_false("PAGE_READ memory writable", safe_address(addr, 4, A_WRITE))
	test_false("PAGE_READ memory executable", safe_address( addr, 4, A_EXECUTE ))
else	
	test_fail("PAGE_READ memory could not be allocated by allocate_protect")
end if

addr = allocate_protect( {1,2,3,4}, 1, PAGE_READ_WRITE )

if addr != 0 then
	test_pass("PAGE_READ_WRITE memory was allocated by allocate_protect")
	test_true("PAGE_READ_WRITE memory readable", safe_address(addr, 4, A_READ))
	test_true("PAGE_READ_WRITE memory writable", safe_address(addr, 4, A_WRITE))
	test_false("PAGE_READ_WRITE memory executable", safe_address( addr, 4, A_EXECUTE ))
else
	test_fail("PAGE_READ_WRITE memory could not be allocated by allocate_protect")
end if

addr = allocate_protect( {1,2,3,4}, 1, PAGE_READ_WRITE_EXECUTE )

if addr != 0 then
	test_pass("PAGE_READ_WRITE_EXECUTE memory was allocated by allocate_protect")
	test_true("PAGE_READ_WRITE_EXECUTE memory readable", safe_address(addr, 4, A_READ))
	test_true("PAGE_READ_WRITE_EXECUTE memory writable", safe_address(addr, 4, A_WRITE))
	test_true("PAGE_READ_WRITE_EXECUTE memory executable", safe_address( addr, 4, A_EXECUTE ))
else
	test_fail("PAGE_READ_WRITE_EXECUTE memory could not be allocated by allocate_protect")
end if

addr = allocate_protect( {1,2,3,4}, 1, PAGE_READ_EXECUTE )

if addr != 0 then
	test_pass("PAGE_READ_EXECUTE memory was allocated by allocate_protect")
	test_true("PAGE_READ_EXECUTE memory readable", safe_address(addr, 4, A_READ))
	test_false("PAGE_READ_EXECUTE memory writable", safe_address(addr, 4, A_WRITE))
	test_true("PAGE_READ_EXECUTE memory executable", safe_address( addr, 4, A_EXECUTE ))
else
	test_fail("PAGE_READ_EXECUTE memory could not be allocated by allocate_protect")
end if


-- The address #DEADBEEF is never used in Linux (it is the dummy value for not used) 
-- but could possibly be a valid address 
-- on other platforms
ifdef LINUX then
	test_false("PAGE_READ_EXECUTE memory readable", safe_address(#DEADBEEF, 4, A_READ))
	test_false("PAGE_READ_EXECUTE memory writable", safe_address(#DEADBEEF, 4, A_WRITE))
	test_false("PAGE_READ_EXECUTE memory executable", safe_address(#DEADBEEF, 4, A_EXECUTE ))
end ifdef

addr = allocate( 4, 1 )
addr = allocate( 4, 1 )
free( addr )

export constant
        M_ALLOC = 16,
        M_FREE = 17
atom ptr = machine_func( M_ALLOC, 4 )
register_block( ptr, PAGE_READ_WRITE )
unregister_block( ptr )
free( ptr )

test_true( "safe address 0 len", safe_address( 1, 0, A_READ ) ) 
edges_only = 1
test_false( "safe_address 1", safe_address( 1, 5, A_READ ) )

addr = allocate_protect( 4, 1, PAGE_READ )
test_false( "safe address #1", safe_address( addr - 1, 2, A_READ ) )
test_false( "safe address #2", safe_address( addr, 5, A_READ ) )
test_false( "safe address #3", safe_address( addr - 100, 200, A_READ ) )
test_false( "safe address #4", safe_address( addr, 1, A_WRITE ) )
free_code( addr, 4 )

addr = allocate( 1024 )

-- poke/peek
poke(addr, 1)
test_equal( "safe peek atom", 1, peek( addr ) )

poke( addr, {1,2,3,4} )
test_equal( "safe peek sequence", {1,2, 3, 4}, peek( addr & 4 ) )

poke(addr, -1)
test_equal( "safe peeks", -1, peeks( addr ) )

poke( addr, {-1, -2, -3, -4} )
test_equal( "safe peeks sequence", {-1, -2, -3, -4}, peeks( addr & 4 ) )

-- poke2/peek2
poke2(addr, 1)
test_equal( "safe peek2 atom", 1, peek2u( addr ) )

poke2( addr, {1,2,3,4} )
test_equal( "safe peek2 sequence", {1,2, 3, 4}, peek2u( addr & 4 ) )

poke2(addr, -1)
test_equal( "safe peek2s", -1, peek2s( addr ) )

poke2( addr, {-1, -2, -3, -4} )
test_equal( "safe peek2s sequence", {-1, -2, -3, -4}, peek2s( addr & 4 ) )


-- poke4/peek4
poke4(addr, 1)
test_equal( "safe peek4 atom", 1, peek4u( addr ) )

poke4( addr, {1,2,3,4} )
test_equal( "safe peek4 sequence", {1,2, 3, 4}, peek4u( addr & 4 ) )

poke4(addr, -1)
test_equal( "safe peek4s", -1, peek4s( addr ) )

poke4( addr, {-1, -2, -3, -4} )
test_equal( "safe peek4s sequence", {-1, -2, -3, -4}, peek4s( addr & 4 ) )

-- poke/peek_string
poke( addr, "safe.e" & 0 )
test_equal( "safe peek_string", "safe.e", peek_string( addr ) )

std_library_address target = allocate( 1024 )
mem_copy( addr, target, 1024 )
test_equal( "safe mem_copy", peek(addr & 1024 ), peek( target & 1024) )

mem_set( target, 0, 1024 )
test_equal( "safe mem_set", repeat( 0, 1024 ), peek( target & 1024) )

free( addr )

function safe_call()
	return 0
end function
atom cb =  call_back( routine_id("safe_call") )
call( cb )

constant cp = define_c_proc( "", cb, {})
c_proc( cp, {} )


test_report()
