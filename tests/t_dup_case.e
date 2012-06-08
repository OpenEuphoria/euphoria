include std/unittest.e


constant HALF_DOZEN = 6
constant SIX = 6

switch 6 do
	case HALF_DOZEN, SIX then
	   test_pass("distinct symbols of the same value are allowed")
end switch

test_report()
