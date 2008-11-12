include std/unittest.e

foo()

function foo()
	return 1
end function

test_fail("should have died with 'expected a procedure, not a function'")
test_report()
