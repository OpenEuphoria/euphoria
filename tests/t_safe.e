
with define SAFE
include std/machine.e
include std/safe.e

include std/unittest.e

edges_only = 0

std_library_address addr

addr = allocate_protect( {1,2,3,4}, 1, PAGE_NONE )

if addr != 0 then
	test_pass("PAGE_NONE memory was allocated by allocate_protect")
	ifdef WINDOWS then
		test_false("PAGE_NONE memory readable", safe_address(addr, 4, A_READ))
		test_false("PAGE_NONE memory writable", safe_address(addr, 4, A_WRITE))
		test_false("PAGE_NONE memory executable", safe_address( addr, 4, A_EXECUTE ))
	elsedef
		test_true("PAGE_NONE memory readable", safe_address(addr, 4, A_READ))
		test_true("PAGE_NONE memory writable", safe_address(addr, 4, A_WRITE))
		test_true("PAGE_NONE memory executable", safe_address( addr, 4, A_EXECUTE ))
	end ifdef
	safe:free_code(addr, 4)
else
	test_fail("PAGE_NONE memory could not be allocated by allocate_protect")
end if

addr = allocate_protect( {1,2,3,4}, 1, PAGE_READ )

if addr != 0 then
	test_pass("PAGE_READ memory was allocated by allocate_protect")
	test_true("PAGE_READ memory readable", safe_address(addr, 4, A_READ))
	ifdef WINDOWS then
		test_false("PAGE_READ memory writable", safe_address(addr, 4, A_WRITE))
		test_false("PAGE_READ memory executable", safe_address( addr, 4, A_EXECUTE ))
	elsedef
		test_true("PAGE_READ memory writable", safe_address(addr, 4, A_WRITE))
		test_true("PAGE_READ memory executable", safe_address( addr, 4, A_EXECUTE ))
	end ifdef
else	
	test_fail("PAGE_READ memory could not be allocated by allocate_protect")
end if

addr = allocate_protect( {1,2,3,4}, 1, PAGE_READ_WRITE )

if addr != 0 then
	test_pass("PAGE_READ_WRITE memory was allocated by allocate_protect")
	test_true("PAGE_READ_WRITE memory readable", safe_address(addr, 4, A_READ))
	test_true("PAGE_READ_WRITE memory writable", safe_address(addr, 4, A_WRITE))
	ifdef WINDOWS then
		test_false("PAGE_READ_WRITE memory executable", safe_address( addr, 4, A_EXECUTE ))
	elsedef
		test_true("PAGE_READ_WRITE memory executable", safe_address( addr, 4, A_EXECUTE ))
	end ifdef
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
	ifdef WINDOWS then
		test_false("PAGE_READ_EXECUTE memory writable", safe_address(addr, 4, A_WRITE))
	elsedef
		test_true("PAGE_READ_EXECUTE memory writable", safe_address(addr, 4, A_WRITE))
	end ifdef
	test_true("PAGE_READ_EXECUTE memory executable", safe_address( addr, 4, A_EXECUTE ))
else
	test_fail("PAGE_READ_EXECUTE memory could not be allocated by allocate_protect")
end if

-- The address #DEADBEEF could never be returned from allocation routines
-- for this address is not aligned by 4 and all implementations align addresses
-- that way.
test_false("PAGE_READ_EXECUTE memory readable", safe_address(#DEADBEEF, 4, A_READ))
test_false("PAGE_READ_EXECUTE memory writable", safe_address(#DEADBEEF, 4, A_WRITE))
test_false("PAGE_READ_EXECUTE memory executable", safe_address(#DEADBEEF, 4, A_EXECUTE ))


test_report()
