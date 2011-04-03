-- foo is not a literal but it is a constant and it is an integer.  It's
-- a forward reference.


include std/unittest.e

type enum weekday
	MONDAY = 1,
	TUESDAY = 2,
	WEDNESDAY = 3,
	THURSDAY = foo,
	FRIDAY
end type

constant foo = 4

test_pass("type enum fwd references")

test_report()
