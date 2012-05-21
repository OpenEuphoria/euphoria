include std/unittest.e

enum A, B
enum D

switch 1 do
	case A then
		test_fail("should not get here")
	case D then
		test_fail("should not get here")
end switch

test_fail("should not get here")
test_report()
