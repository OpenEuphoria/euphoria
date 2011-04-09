
include std/unittest.e

integer type foo
	bar
end type

test_fail("should not be able to declare integers as typed enums")

test_report()
