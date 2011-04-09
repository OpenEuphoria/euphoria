
include std/unittest.e

sequence type foo
	bar
end type

test_fail("should not be able to declare sequences as typed enums")

test_report()
