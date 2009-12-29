include std/unittest.e
type enum weekdays
	MONDAY = 2,
	TUESDAY = 1,
	WEDNESDAY = 3,
	THURSDAY = 9,
	FRIDAY = 5,
	$
end type
test_equal("assigned values", {2,1,3,9,5}, {MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY})

public enum type inner_planets
	MERCURY,
	VENUS,
	EARTH,
	MARS
end type
test_equal("derived values", {1,2,3,4}, {MERCURY, VENUS, EARTH, MARS})

weekdays thisday
thisday = MONDAY
thisday = TUESDAY
thisday = WEDNESDAY
thisday = THURSDAY
thisday = FRIDAY

test_pass("type enum")
test_true("MONDAY is weekdays", weekdays(MONDAY))
test_true("THURSDAY is a weekday", weekdays(THURSDAY))
test_true("FRIDAY is a weekday", weekdays(FRIDAY))
test_false("8 is not a weekday", weekdays(8))

test_report()
