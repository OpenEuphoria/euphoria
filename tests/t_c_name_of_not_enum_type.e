include std/unittest.e
-- ERRMSG_NAME_OF_NOT_ENUM_TYPE

type boolean(integer x)
	return and_bits(x,1) = 1
end type

boolean x = false

x = name_of(x)




test_fail()
test_report()
