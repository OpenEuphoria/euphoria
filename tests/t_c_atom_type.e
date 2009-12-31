
include std/unittest.e

atom type foo
	bar
end type

test_fail("should not be able to declare atoms as typed enums")

test_report()
