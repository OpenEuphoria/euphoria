include std/unittest.e
-- ERRMSG_NAME_OF_NOT_ENUM_TYPE

type boolean(integer x)
	return and_bits(x,1) = 1
end type

boolean x = false
sequence s
s = name_of(x)

test_fail("Shouldn't be able to call name_of() on a non-enumerated type.")
test_report()
