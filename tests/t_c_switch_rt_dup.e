include std/unittest.e

enum A, B

procedure foo()
	switch 1 do
		case A then
			test_fail("should not get here")
		case D then
			test_fail("should not get here")
	end switch
end procedure

enum D

foo()

test_fail("should not get here")
test_report()
