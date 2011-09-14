include std/unittest.e

-- non-continuous non-monotonic enumerated type
-- index_map implementation in the parser
type enum weekday
	MONDAY = 2,
	TUESDAY = 1,
	WEDNESDAY = 3,
	THURSDAY = 9,
	FRIDAY = 5,
	$
end type
test_equal("assigned values out of order integer enumerated type", {2,1,3,9,5}, {MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY})

-- continuous monotonic enumerated type
enum type inner_planet
	MERCURY,
	VENUS,
	EARTH,
	MARS
end type
test_equal("assigned values in order stepping by one enumerated type", {1,2,3,4}, {MERCURY, VENUS, EARTH, MARS})

-- non-integer enumerated type
type enum metric_prefix by * 1000
	nano = 0.000_000_001,
	micro,
	milli,
	kilo = 1000,
	mega,
	giga
end type
test_equal("assigned values non-integer enumerated type", {0.000_000_001, 0.000_001, 0.001, 1_000, 1_000_000, 1_000_000_000 }, {nano, micro, milli, kilo, mega, giga})

weekday thisday
thisday = MONDAY
thisday = TUESDAY
thisday = WEDNESDAY
thisday = THURSDAY
thisday = FRIDAY

inner_planet mining_target = MARS
test_pass("type enum")
test_true("MONDAY is a weekday", weekday(MONDAY))
test_true("THURSDAY is a weekday", weekday(THURSDAY))
test_true("FRIDAY is a weekday", weekday(FRIDAY))
test_true("MERCURY is an inner_planet", inner_planet(MERCURY))
test_true("VENUS is an inner_planet", inner_planet(VENUS))
test_true("EARTH is an inner_planet", inner_planet(EARTH))
test_true("MARS is an inner_planet", inner_planet(MARS))

test_false("8 is not a weekday", weekday(8))

metric_prefix mpsize

mpsize = micro
test_true("kilo is a metric prefix", metric_prefix(kilo))
test_true("mega is a metric prefix", metric_prefix(mega)) 
test_true("micro is a metric prefix", metric_prefix(micro))
test_false("micro+kilo is not a metric prefix", metric_prefix(micro+kilo))
test_false("-1 is not a metric prefix", metric_prefix(-1))
test_false(`"Hello" is not a metric prefix`, metric_prefix("Hello"))


test_equal("name_of works with defining constant","kilo",name_of(kilo))
test_equal("name_of works with a variable","micro",name_of(mpsize))

test_equal("name_of works with defining constant","WEDNESDAY",name_of(WEDNESDAY))
test_equal("name_of works with a variable","FRIDAY",name_of(thisday))

test_equal("name_of works with defining constant","VENUS",name_of(VENUS))
test_equal("name_of works with a variable","MARS",name_of(mining_target))

test_report()
