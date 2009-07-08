include std/unittest.e
include std/machine.e


atom addr
addr = allocate_protect( {1,2,3,4}, 1, PAGE_NOACCESS )

if addr != 0 then
	test_pass("PAGE_NONE memory was allocated by allocate_protect")
	free_code(addr, 4)
else
	test_fail("PAGE_NONE memory could not be allocated by allocate_protect")
end if

addr = allocate_protect( {1,2,3,4}, 1, PAGE_READ )

if addr != 0 then
	test_pass("PAGE_READ memory was allocated by allocate_protect")
	peek4u(addr)
	test_pass("PAGE_READ memory was read")
else	
	test_fail("PAGE_READ memory could not be allocated by allocate_protect")
end if

addr = allocate_protect( {1,2,3,4}, 1, PAGE_READ_WRITE )

if addr != 0 then
	test_pass("PAGE_READ_WRITE memory was allocated by allocate_protect")
	peek4u(addr)
	test_pass("PAGE_READ_WRITE memory was read")
	poke4(addr,{5,6,7,8})
	test_pass("PAGE_READ_WRITE memory was written to")
else
	test_fail("PAGE_READ_WRITE memory could not be allocated by allocate_protect")
end if

addr = allocate_protect( {1,2,3,4}, 1, PAGE_READ_WRITE_EXECUTE )

if addr != 0 then
	test_pass("PAGE_READ_WRITE_EXECUTE memory was allocated by allocate_protect")
	peek4u(addr)
	test_pass("PAGE_READ_WRITE memory was read")
	poke4(addr,{5,6,7,8})
	test_pass("PAGE_READ_WRITE memory was written to")
else
	test_fail("PAGE_READ_WRITE_EXECUTE memory could not be allocated by allocate_protect")
end if

addr = allocate_protect( {1,2,3,4}, 1, PAGE_READ_EXECUTE )

if addr != 0 then
	test_pass("PAGE_READ_EXECUTE memory was allocated by allocate_protect")
else
	test_fail("PAGE_READ_EXECUTE memory could not be allocated by allocate_protect")
end if



test_report()
