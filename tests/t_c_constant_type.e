
include std/unittest.e

constant type foo
	bar
end type

test_fail("should not be able to declare constants as typed enums")

test_report()
