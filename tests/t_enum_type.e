-- There are several implementations used by the parser for enumerated types.  The type doesn't 
-- return just one or zero.  The type function returns a value showing the order it was defined.  
-- name_of should return a string that represents the constant defined in the enumerated type 
-- even if passed a variable which may load the value from a file.  

-- There are three distinct implementations for name_of and the generated type functions for 
-- enumerated types.  
--    ## The general case:  sequence pair
--    ## A set of non-consequtive integers and some are not obtained: index map
--    ## A set of non-consequtive integers but all values are attained in that interval: index map
--    ## A set of consequtive integers : index map
--

-- non-continuous non-monotonic enumerated type
-- index_map implementation in the parser.  If the literal set of weekday is ls then 
-- type is implemented as if integer(x) and MONDAY <= x and x <= THURSDAY then return ls[x][val] end if
-- else return 0 and 
-- name_of is implemented with ls[x][name]
-- This detail is hidden from the user.
include std/unittest.e
include std/get.e
include std/convert.e

sequence buf

type enum weekday
	MONDAY = 2,
	TUESDAY = 1,
	WEDNESDAY = 3,
	THURSDAY = 9,
	FRIDAY = 5,
	$
end type
test_equal("assigned values out of order integer (incomplete interval) enumerated type", {2,1,3,9,5}, {MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY})
test_equal("type values out of order integer (incomplete interval) enumerated type", {1,2,3,4,5}, {weekday(MONDAY), weekday(TUESDAY), weekday(WEDNESDAY), weekday(THURSDAY), weekday(FRIDAY)})
test_false("non-weekday in the numeric hull is false #1", weekday(4))
test_false("non-weekday in the numeric hull is false #2", weekday(8))
buf = value("9")
test_true("parsed integer values are also valid", weekday(buf[2]))
-- continuous monotonic enumerated type
-- internally, the parser will implement name of by using a sequence of pairs indexed by 
-- inner_planets.  So ds[MERCURY] will contain an object pair:  The appearance number and the name "MERCURY".  
-- If the literal set for inner_planet is ls then the type is implemented as if integer(x) and MERCURY <= x and x <= MARS then return x-MERCURY+1.  name_of is tested the same way but returns ls[x][name]. 
-- This is detail is not shown to the user.
enum type inner_planet
	MERCURY,
	VENUS,
	EARTH,
	MARS
end type
test_equal("assigned values in order stepping by one (complete interval) enumerated type", {1,2,3,4}, {MERCURY, VENUS, EARTH, MARS})
test_equal("type values of in order integer (complete interval) enumerated type", {1,2,3,4}, {inner_planet(MERCURY), inner_planet(VENUS), inner_planet(EARTH), inner_planet(MARS)})

-- continuous but non-monotonic enumerated type
-- internally, the parser will implement name of by using a sequence of pairs indexed by 
-- inner_planets.  So ds[MERCURY] will contain an object pair:  The appearance number and the name "MERCURY".  
-- If the literal set for inner_planet is ls then the type is implemented as if integer(x) and MERCURY <= x and x <= MARS then return ls[x][val].  name_of is tested the same way but returns ls[x][name]. 
-- This is detail is not shown to the user.
enum type outer_planet
	SATURN=6,
	URANUS,
	NEPTUNE,
	JUPITER=5
end type
test_equal("assigned values in continuous out of order integer interval (complete interval) enumerated type", {6,7,8,5}, {SATURN,URANUS,NEPTUNE,JUPITER})
test_equal("type values out of order integer (complete interval) enumerated type", {1,2,3,4}, {outer_planet(SATURN),outer_planet(URANUS),outer_planet(NEPTUNE),outer_planet(JUPITER)})

-- non-integer enumerated type
-- Internally, the parser will implement this by using a pair of same length sequences.
-- The first sequence will contain the values of the metric prefixes.  The second sequence will contain the names.
-- This is a detail is not shown to the user.
type enum metric_prefix by * 1000
	nano = 0.000_000_001,
	micro,
	milli,
	kilo = 1000,
	mega,
	giga
end type
test_equal("assigned values non-integer enumerated type", {0.000_000_001, 0.000_001, 0.001, 1_000, 1_000_000, 1_000_000_000 }, {nano, micro, milli, kilo, mega, giga})
test_equal("type values non-integer enumerated type", {1,2,3,4,5,6}, {metric_prefix(nano),
	metric_prefix(micro),
	metric_prefix(milli),
	metric_prefix(kilo),
	metric_prefix(mega),
	metric_prefix(giga)})
-- floating point parsed values
buf = value("0.000"&"001")
test_equal("micro is also the same as 0.000_001 parsed", micro, buf[2])
buf = value("0.001")
test_equal("milli is also the same as 0.001 parsed", milli, buf[2])
buf = value("1000")
test_equal("kilo is also the same as 1000 parsed", kilo, buf[2])
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
test_false("{55} is not a weekday", weekday({55}))
test_false("0.5 is not a weekday", weekday(0.5))

metric_prefix mpsize

mpsize = micro
test_true("kilo is a metric prefix", metric_prefix(kilo))
test_true("mega is a metric prefix", metric_prefix(mega)) 
test_true("micro is a metric prefix", metric_prefix(micro))
test_false("micro+kilo is not a metric prefix", metric_prefix(micro+kilo))
test_false("-1 is not a metric prefix", metric_prefix(-1))
test_false(`"Hello" is not a metric prefix`, metric_prefix("Hello"))
test_false("9.999999999999995e-07 is not a metric prefix", metric_prefix(9.999999999999995e-07))
test_equal("micro is 0.000_001", micro, 0.000_001)

outer_planet farthest
farthest = NEPTUNE
test_false("EARTH is not an outer_planet",outer_planet(EARTH))
test_false("{44} is not an outer_planet",outer_planet({44}))
test_false("0.3 is not an outer_planet",outer_planet(0.3))

test_equal("name_of works with defining constant from a out of order integer interval (complete interval) enumerated type","JUPITER",name_of(JUPITER))
test_equal("name_of works with variable from a out of order integer interval (complete interval) enumerated type","NEPTUNE",name_of(farthest))

test_equal("name_of works with defining constant from a generic enumerated type","kilo",name_of(kilo))
test_equal("name_of works with a variable from a generic enumerated type","micro",name_of(mpsize))

test_equal("name_of works with defining constant from a out of order integer (incomplete interval) enumerated type","WEDNESDAY",name_of(WEDNESDAY))
test_equal("name_of works with a variable from a out of order integer (incomplete interval) enumerated type","FRIDAY",name_of(thisday))

test_equal("name_of works with defining constant from a in order (complete interval) enumerated type","VENUS",name_of(VENUS))
test_equal("name_of works with a variable from a in order (complete interval) enumerated type","MARS",name_of(mining_target))

-- Test enum types from an included file:
include enum_type.e
test_true( "X86 is an ARCHITECTURE", architecture( X86 ) )
test_true( "X86_64 is an ARCHITECTURE", architecture( X86_64 ) )
test_true( "ARM is an ARCHITECTURE", architecture( ARM ) )

test_equal( "X86 name_of", "X86", name_of( X86 ) )
test_equal( "X86_64 name_of", "X86_64", name_of( X86_64 ) )
test_equal( "ARM name_of", "ARM", name_of( ARM ) )


test_report()
