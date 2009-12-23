include std/unittest.e
type enum weekdays
	MONDAY = 1,
	TUESDAY = 2,
	WEDNESDAY = 3,
	THURSDAY = 4,
	FRIDAY = 5,
	$
end type

enum type inner_planets
	MERCURY,
	VENUS,
	EARTH,
	MARS
end type

weekdays thisday = TUESDAY
thisday = WEDNESDAY


test_pass("type enum")
test_true("MONDAY is weekdays", weekdays(MONDAY))
test_true("THURSDAY is a weekday", weekdays(THURSDAY))
test_true("FRIDAY is a weekday", weekdays(FRIDAY))
test_false("8 is not a weekday", weekdays(8))

test_report()
