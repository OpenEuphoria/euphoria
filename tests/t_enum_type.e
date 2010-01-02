include std/unittest.e
type enum weekday
	MONDAY = 2,
	TUESDAY = 1,
	WEDNESDAY = 3,
	THURSDAY = 9,
	FRIDAY = 5,
	$
end type
test_equal("assigned values", {2,1,3,9,5}, {MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY})

enum type inner_planet
	MERCURY,
	VENUS,
	EARTH,
	MARS
end type
test_equal("derived values", {1,2,3,4}, {MERCURY, VENUS, EARTH, MARS})

weekday thisday
thisday = MONDAY
thisday = TUESDAY
thisday = WEDNESDAY
thisday = THURSDAY
thisday = FRIDAY

test_pass("type enum")
test_true("MONDAY is a weekday", weekday(MONDAY))
test_true("THURSDAY is a weekday", weekday(THURSDAY))
test_true("FRIDAY is a weekday", weekday(FRIDAY))
test_true("MERCURY is an inner_planet", inner_planet(MERCURY))
test_true("VENUS is an inner_planet", inner_planet(VENUS))
test_true("EARTH is an inner_planet", inner_planet(EARTH))
test_true("MARS is an inner_planet", inner_planet(MARS))

test_false("8 is not a weekday", weekday(8))

test_report()
