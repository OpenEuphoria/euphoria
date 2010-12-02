
include std/unittest.e

type blah( object o )
	return 1
end type

blah type foo
	bar
end type

test_fail("should not be able to declare user defined types as typed enums")

test_report()
