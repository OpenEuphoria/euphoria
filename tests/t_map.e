include std/unittest.e
include std/map.e
include std/sort.e
include std/text.e
include std/pretty.e
include std/filesys.e
include std/io.e
include std/math.e
include std/eumem.e
include std/serialize.e
include std/datetime.e

object o1, o2, o3
constant init_small_map_key = -75960.358941
o1 = map:new(1)
test_true("map new #1", map(o1) )


map:map m1

m1 = map:new(11)

-- add integers from -5 to 5 with keys -50 to 50
for i = -5 to 5 do
	map:put(m1, i, i*10)
end for
test_equal("map m1 get -5",             -50, map:get(m1, -5, 999) )
test_equal("map m1 get 0",                0, map:get(m1,  0, 999) )
test_equal("map m1 get 5",               50, map:get(m1,  5, 999) )
test_equal("map m1 get 6",              999, map:get(m1,  6, 999) )
test_equal("map m1 get 8",              999, map:get(m1,  8, 999) )
test_equal("map m1 get -199999999999",  "abc",  map:get(m1, -199999999999, "abc"))
test_equal("map m1 get \"XXXXXXXXXX\"", 999,    map:get(m1, "XXXXXXXXXX", 999))
test_equal("map m1 size#1", 11, map:size(m1))
test_equal("map m1 keys", {-5,-4,-3,-2,-1,0,1,2,3,4,5}, map:keys(m1, 1) )

test_true ("map m1 has #1", map:has(m1, 0))
test_false("map m1 has #2", map:has(m1, 9999))


-- add 1000 integers, 5 of which are already in the map
for i = 1 to 1000 do
	map:put(m1, i, sprint(i))
end for
test_true ("map m1 has #3", map:has(m1, 0))
test_false("map m1 has #4", map:has(m1, 9999))

test_equal("map m1 size#2", 1006, map:size(m1))

test_equal("map m1 get 5#2",               "5", map:get(m1,  5, 999) )
test_equal("map m1 get 1000",           "1000", map:get(m1, 1000, 999) )

-- add 2000 floats
o2 = map:threshold(o1)
for i = 1 to 1000 do
	map:put(m1, -i*1.333333, i)
end for

for i = 1 to 1000 do
--	? i
	map:put(m1, 1e100+i*1e90, i)
end for
test_equal("map m1 get#1 -133.3333",           100, map:get(m1, -1.333333*100, 999) )


ifdef BENCHMARK then
for bb = 1 to 1000 do
for i = 1000 to 1  by -1 do
	test_equal(sprintf("large get 1 %d", i), i, map:get(m1,  1e100+i*1e90, 0))
end for

for i = 1000 to 1  by -1 do
	test_equal(sprintf("large get 2 %d", i), i, map:get(m1, -i*1.333333, 0))
end for

for i = 1000 to 1  by -1 do
	test_equal(sprintf("large get 3 %d", i), -1, map:get(m1, i*2.11, -1))
end for

end for
end ifdef

o1 = statistics(m1)
--? o1
--getc(0)
rehash(m1, 100)
o2 = statistics(m1)
--? o2

test_not_equal("Rehash works for large maps", o1, o2)

rehash(m1, 50_000) -- Force timeout for prime number determination


test_equal("map m1 get#2 -133.3333",           100, map:get(m1, -1.333333*100, 999) )
rehash(m1, 10000)
test_equal("map m1 get#3 -133.3333",           100, map:get(m1, -1.333333*100, 999) )

test_equal("map m1 get 1e100+999e90",       999, map:get(m1, 1e100+999e90, "") )

test_equal("map m1 size#3", 3006, map:size(m1))

object opm
object opms
object m1s
opm = copy(m1)
optimize(opm)
m1s = statistics(m1)
opms = statistics(opm)

test_equal("map optimize #1", m1s[NUM_IN_USE], opms[NUM_IN_USE]) -- total element unchanged
optimize(m1, 0, 0)
m1s = statistics(m1)
test_equal("map optimize #2", m1s[NUM_IN_USE], opms[NUM_IN_USE]) -- total element unchanged


clear(m1)
test_equal( "map clear #1", 0, map:size(m1))

-- m2: strings and objects
map:map m2
m2 = map:new(60)	-- Create a small map


for i = 1 to 33 do
	map:put(m2, repeat('a', i), i)
end for
o1 = statistics(m2)
rehash(m2)
o2 = statistics(m2)

test_equal("map m2 size#1", 33, map:size(m2))
test_equal("map m2 get a", 1, map:get(m2, "a", 999))
test_equal("map m2 get aaaaaaaaaaaaaaaaaaaaaaaaaaa", 27, map:get(m2, "aaaaaaaaaaaaaaaaaaaaaaaaaaa", 999))
test_equal("map m2 get aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", 999, map:get(m2, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", 999))

object n
for i = 1 to 7 do
	n = repeat(repeat(repeat(repeat(repeat(repeat({99, 99.9, "99"}, i), i), i), i), i), i)
	map:put(m2, n, i)
end for

test_equal("map m2 get (n)", 7, map:get(m2, n, 999))
test_equal("map m2 values",  {1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33}, sort(map:values(m2)))

test_equal("map m2 size#2", 40, map:size(m2))
map:remove(m2, n)

test_equal("map m2 size#3", 39, map:size(m2))

map:map m3
m3 = map:new()
map:put(m3, 1, 11)
map:put(m3, 2, 22)
map:put(m3, 3, 33)
map:remove(m3, 2)
test_equal("map m3 size#1", 2, map:size(m3))
map:remove(m3, 2)
test_equal("map m3 size#2", 2, map:size(m3))

map:map m4
m4 = map:new()
map:put(m4, 1, 11)

test_equal("map m4 has -- yes", 1, map:has(m4, 1))
test_equal("map m4 has -- no", 0, map:has(m4, 2))

test_equal("map load, bad file #1", -1, map:load_map("badfile.name"))
test_equal("map load, bad file #2", -2, map:load_map("test_bad_map.dat"))

m1 = load_map("test_map_small.txt")
test_equal("map load, small", "bcd", map:get(m1, "a",-1))

m1 = load_map("test_map.txt")
test_equal("map load #1", "bar", map:get(m1, "foo",-1))
test_equal("map load #2", "foo", map:get(m1, "bar",-1))
test_equal("map load #3", "comment", map:get(m1, "trail",-1))
test_equal("map load #4", 10, map:get(m1, "int",-1))
test_equal("map load #5", 3.4, map:get(m1, "atom",-1))
test_equal("map load #6", {"one", 2, 3.4}, map:get(m1, "seq",-1))
test_equal("map load #7", -1, map:get(m1, "missing",-1))
test_equal("map load equal", "=", map:get(m1, "equal",-1))
test_equal("map load padding", " padded ", map:get(m1, "padding",-1))
test_equal("map load embed", "--", map:get(m1, "embed",-1))

map:put(m1, 12.34, "Non alpha key - float")
map:put(m1, {{"text"}}, "Non alpha key - sequence")
map:put(m1, "This has a \\backslash", "Test back\\- slash handling")

test_equal("map save fail", -1, save_map(m1, "<//badname.txt"))

test_equal("map save #1", 12, save_map(m1, "save_map.txt", SM_TEXT))
m2 = load_map("save_map.txt")
test_equal("map save #2", 1, map:compare(m1,m2))
test_equal("map save #2 compare keys", 1, map:compare( m1, m2, 'k' ) )
test_equal("map save #2 compare values", 1, map:compare( m1, m2, 'v' ) )

test_equal("map save #3", 12, save_map(m1, "save_map.raw", SM_RAW))
m2 = load_map("save_map.raw")
test_equal("map save #4", 1, map:compare(m1,m2))


integer fhs
fhs = open("save_map.raw2", "wb")
test_equal("map save #5", 12, save_map(m1, fhs, SM_RAW))
close(fhs)

fhs = open("save_map.raw2", "rb")
m2 = load_map(fhs)
close(fhs)
test_equal("map save #6", 1, map:compare(m1,m2))

-- Tests for invalid saved map format.
fhs = open("save_map.raw3", "wb")
puts(fhs, serialize(
		{0, -- illegal saved map version
		datetime:format(now_gmt(), "%Y%m%d%H%M%S" ), -- date of this saved map
		{4,0,0,0}} -- Euphoria version
	 	))	
puts(fhs, serialize({}))
puts(fhs, serialize({}))
close(fhs)
test_equal("Bad saved map version", -2, load_map("save_map.raw3"))

map:map m5

-- Test put operations with small maps.
m5 = map:new(10)
map:put( m5, ADD, 1 )
map:put( m5, ADD, 1, ADD ) -- 2
test_equal( "small putADD", 2, map:get( m5, ADD, "" ) )

map:put( m5, MULTIPLY, 2 )
map:put( m5, MULTIPLY, 3, MULTIPLY ) -- 6
test_equal( "small put MULTIPLY", 6, map:get( m5, MULTIPLY, "" ) )

map:put( m5, DIVIDE, 6 )
map:put( m5, DIVIDE, 2, DIVIDE ) -- 3
test_equal( "small put DIVIDE", 3, map:get( m5, DIVIDE, "" ) )

map:put( m5, SUBTRACT, 3 )
map:put( m5, 3, 3, SUBTRACT )
test_equal( "small put SUBTRACT", 0, map:get( m5, SUBTRACT, "" ) )

map:put( m5, CONCAT, "foo" )
map:put( m5, CONCAT, "bar", CONCAT )
test_equal( "small put CONCAT", "foobar", map:get( m5, CONCAT, "" ) )

map:put( m5, APPEND, {"foo"} )
map:put( m5, APPEND, "bar", APPEND )
test_equal( "small put APPEND", {"foo","bar"}, map:get( m5, APPEND, "" ) )

-- Now repeat for Large maps
m5 = map:new( 8 * 2) -- Force a large map type and make sure puts don't rehash it.
map:put( m5, ADD, 1, PUT, 0 )
map:put( m5, ADD, 1, ADD, 0 ) -- 2
test_equal( "large put ADD", 2, map:get( m5, ADD, "" ) )

map:put( m5, MULTIPLY, 2, PUT, 0 )
map:put( m5, MULTIPLY, 3, MULTIPLY, 0 ) -- 6
test_equal( "large put MULTIPLY", 6, map:get( m5, MULTIPLY, "" ) )

map:put( m5, DIVIDE, 6, PUT, 0 )
map:put( m5, DIVIDE, 2, DIVIDE, 0 ) -- 3
test_equal( "large put DIVIDE", 3, map:get( m5, DIVIDE, "" ) )

map:put( m5, SUBTRACT, 3, PUT, 0 )
map:put( m5, 3, 3, SUBTRACT, 0 )
test_equal( "large put SUBTRACT", 0, map:get( m5, SUBTRACT, "" ) )

map:put( m5, CONCAT, "foo", PUT, 0 )
map:put( m5, CONCAT, "bar", CONCAT, 0 )
test_equal( "large put CONCAT", "foobar", map:get( m5, CONCAT, "" ) )

map:put( m5, APPEND, {"foo"}, PUT, 0 )
map:put( m5, APPEND, "bar", APPEND, 0 )
test_equal( "large put APPEND", {"foo","bar"}, map:get( m5, APPEND, "" ) )


map:map city_population
city_population = map:new()
nested_put(city_population, {"Canada",        "Quebec",    "SmallTown"},        100 )
nested_put(city_population, {"United States", "California", "Los Angeles"}, 3819951 )
nested_put(city_population, {"Canada",        "Ontario",    "Toronto"},     2503281 )

test_equal("nested #1", 2503281, nested_get(city_population, {"Canada", "Ontario", "Toronto"}, -1))
test_equal("nested #2", 3819951, nested_get(city_population, {"United States", "California", "Los Angeles"}, -1))
test_equal("nested #3", -1, nested_get(city_population, {"Australia", "Victoria", "Melbourne"}, -1))
test_equal("nested #4", -1, nested_get(city_population, {"United States", "California", "New York"}, -1))

map:map m6
m6 = nested_get(city_population, {"Canada"}, -1)
test_equal("nested #5", {"Ontario", "Quebec"}, keys(m6, 1))


map:map m7 = new_extra( "TOTAL RUBBISH" )
test_true( "new_extra #1", map:map(m7))
map:map m8 = new_extra( m7 )
test_equal( "new_extra #2", m7, m8)

clear(m1)
test_equal( "map clear #1", 0, map:size(m1))
delete(m1)
test_false( "delete #1", map:map(m1))

delete(city_population)
test_false( "delete #2", map:map(city_population))

o2 = map:threshold(20)
m1 = map:new(30)
m2 = map:new(400)
for i = 1 to 500 do
	map:put(m1, i, i)
	map:put(m2, i, i)
end for
test_equal("compare identity #1", 0, map:compare(m1, m1))
test_equal("compare identity #2", 0, map:compare(m2, m2))
test_equal("compare equality #1", 1, map:compare(m2, m1))
test_equal("compare equality #2", 1, map:compare(m1, m2))

optimize(m1, 30) -- Ensure that the hashing is different on the two maps.
optimize(m2, 10) -- Ensure that the hashing is different on the two maps.

test_equal("compare equality #3", 1, map:compare(m2, m1))
test_equal("compare equality #4", 1, map:compare(m1, m2))

map:put(m2, 511, 511)
test_equal("compare inequality #1", -1, map:compare(m2, m1))
test_equal("compare inequality #2", -1, map:compare(m1, m2))

--
-- Values w/key sequence tests
--

clear(m1)

map:put(m1, 10, "ten")
map:put(m1, 20, "twenty")
map:put(m1, 30, "thirty")
map:put(m1, 40, "forty")

test_equal("values w/key sequence #1a", { "ten", 0, "thirty", 0 }, map:values(m1, { 10, 50, 30, 9000 }))
test_equal("values w/key sequence #1b", { "ten", -1, "thirty", -1 }, map:values(m1, { 10, 50, 30, 9000 }, -1))
test_equal("values w/key sequence #1c", { "ten", -2, "thirty", -3 }, map:values(m1, { 10, 50, 30, 9000 }, {-1,-2,-3}))
test_equal("values w/key sequence #2",	{ 0, 0 }, map:values(m1, { 2, 1 }))
test_equal("values w/key sequence and default value sequence #1",
	{ "ten", "one", "thirty" }, map:values(m1, { 10, 1, 30 }, { "abc", "one", "def" }))

clear(m2)

map:put(m2, 10, "TEN")
map:put(m2, 20, "TWENTY")
map:put(m2, 30, "THIRTY")
map:put(m2, 40, "FORTY")
	
-- Ensure they have the same keys.
test_equal("compare equality #5", 1, map:compare(m2, m1, 'k'))
test_equal("compare inequality #5", -1, map:compare(m2, m1, 'v'))

map:put(m2, 10, "ten")
map:put(m2, 20, "twenty")
map:put(m2, 30, "thirty")
map:remove(m2, 40)
map:put(m2, 50, "forty")
-- Ensure they have the same values.
test_equal("compare equality #6", 1, map:compare(m2, m1, 'v'))
test_equal("compare inequality #6", -1, map:compare(m2, m1, 'k'))

--
-- Copy w/destination tests
--

clear(m1)
clear(m2)

map:put(m1, 10, "ten")
map:put(m1, 20, "twenty")
map:copy(m1, m2)

clear(m1)
map:put(m1, 30, "thirty")
map:put(m1, 40, "forty")
map:copy(m1, m2)

test_equal("copy w/destination #1", "ten", map:get(m2, 10))
test_equal("copy w/destination #2", "twenty", map:get(m2, 20))
test_equal("copy w/destination #3", "thirty", map:get(m2, 30))
test_equal("copy w/destination #4", "forty", map:get(m2, 40))

map cm1 = map:new()
map cm2 = map:new()

put(cm1, "XY", 1)
put(cm1, "AB", 2)
put(cm2, "XY", 3)

-- Add same keys' values.
copy(cm2, cm1, ADD)

test_equal("copy w/destination ADD", { {"AB", 2}, {"XY", 4} }, pairs(cm1, 1))


write_file("xyz.cfg", `
application = Euphoria,
version     = 4.0,
genre       = "programming language",
crc         = 4F71AE10
`)

m1 = map:new_from_string( read_file("xyz.cfg", TEXT_MODE))
 
test_equal("from string A", "Euphoria", map:get(m1, "application"))
test_equal("from string B", "programming language", map:get(m1, "genre"))
test_equal("from string C", "4.0", map:get(m1, "version"))
test_equal("from string D", "4F71AE10", map:get(m1, "crc"))


m1 = map:new_from_string(`name="John" children=["Jim", "Jane", "Judy"]`)
test_equal("from string E", "John", map:get(m1, "name"))
test_equal("from string F", {"Jim", "Jane", "Judy"}, map:get(m1, "children"))
 
m1 = new_from_kvpairs( {
{"application" , "Euphoria"},
{"version"     , "4.0"},
{"genre"       , "programming language"},
{"crc"         , 0x4F71AE10}
})
 
test_equal("from kvpairs A", "Euphoria", map:get(m1, "application"))
test_equal("from kvpairs B", "programming language", map:get(m1, "genre"))
test_equal("from kvpairs C", "4.0", map:get(m1, "version"))
test_equal("from kvpairs D", 0x4F71AE10, map:get(m1, "crc"))


sequence fer = {}
function Process_A(object k, object v, object d, integer pc)
	fer = append(fer, {k,v,d,pc})
	return 0
end function

function Process_B(object k, object v, object d, integer pc)
	if pc = 0 then
		fer = append(fer, {"The map is empty",k,v,d,pc})
	else
		integer c
		c = abs(pc)
		if c = 1 then
			fer = append(fer, {"START",k,v,d,pc }) -- Write the report title.
		end if
		fer = append(fer, {k,v,d,pc})
		if pc < 0 then
			fer = append(fer, {"END",k,v,d,pc} )
		end if
	end if
	return 0
end function

function Process_C(object k, object v, object d, integer pc)
	if pc > 0 then
		fer = append(fer, {k,v,d,pc})
		if pc = 2 then
			return 1
		end if
	end if
	return 0
end function

clear(m1)
-- Empty
map:for_each(m1, routine_id("Process_B"))
map:put(m1, "application", "Euphoria")
map:put(m1, "version", "4.0")
map:put(m1, "genre", "programming language")
map:put(m1, "crc", "4F71AE10")

-- Unsorted 
map:for_each(m1, routine_id("Process_A"))
-- Sorted
map:for_each(m1, routine_id("Process_B"), "List of Items", 1)

sequence efer = {
--	{"The map is empty",0,0,0,0},
	{"crc", "4F71AE10", 0, 1},
	{"genre", "programming language", 0, 2},
	{"version", "4.0", 0, 3},
	{"application", "Euphoria", 0, 4},
	{"START", "application", "Euphoria", "List of Items", 1},
	{"application", "Euphoria", "List of Items", 1},
	{"crc", "4F71AE10", "List of Items", 2},
	{"genre", "programming language", "List of Items", 3},
	{"version", "4.0", "List of Items", 4},
--	{"END", "version", "4.0", "List of Items", -4},
	$
}

test_equal("for_each", efer, fer)

fer = {}
efer = {
	{"application", "Euphoria", 0, 1},
	{"crc", "4F71AE10", 0, 2},
	$
}
-- Sorted
map:for_each(m1, routine_id("Process_C"), , 1)
test_equal("for_each", efer, fer)

fer = {}
efer = {
	{0,0,0,0},
	{"START", "application", "Euphoria", "List of Items", 1},
	{"application", "Euphoria", "List of Items", 1},
	{"crc", "4F71AE10", "List of Items", 2},
	{"genre", "programming language", "List of Items", 3},
	{"version", "4.0", "List of Items", -4},
	{"END", "version", "4.0", "List of Items", -4},
	$
}
clear(m1)
-- Empty
map:for_each(m1, routine_id("Process_A"),,,1)
map:put(m1, "application", "Euphoria")
map:put(m1, "version", "4.0")
map:put(m1, "genre", "programming language")
map:put(m1, "crc", "4F71AE10")
map:for_each(m1, routine_id("Process_B"), "List of Items", 1, 1)
test_equal("for_each with boundary", efer, fer)

-- Testing the removal of items from a multi-item bucket
m1 = map:new()
for i = 1 to 8 * 5 do
	put(m1, sprintf("%d", i), i,, 0)
end for

test_true("Gone #1", map:has(m1, "5"))
map:remove(m1, "5")
test_false("Gone #2", map:has(m1, "5"))


-- Test small maps using the special maginc number used to initialize its buckets.
m2 = map:new(map:threshold())	-- Create a small map
map:put(m2, init_small_map_key, "Special Key")
map:put(m2, "Special Key", init_small_map_key)
test_equal("small map magic number has #1", 1, map:has(m2, init_small_map_key))
test_equal("small map magic number #1", "Special Key", map:get(m2, init_small_map_key))
test_equal("small map magic number has #2", 1, map:has(m2, "Special Key"))
test_equal("small map magic number #2", init_small_map_key, map:get(m2, "Special Key"))
map:put(m2, init_small_map_key, "Another Special Key")
test_equal("small map magic number #3", "Another Special Key", map:get(m2, init_small_map_key))

map:clear(m2)
test_equal("no small map magic number has #1", 0, map:has(m2, init_small_map_key))
test_equal("no small map magic number #1", "No Key", map:get(m2, init_small_map_key, "No Key"))
map:put(m2, "Key1", "1")
map:put(m2, "Key2", "too")
test_equal("no small map magic number has #2", 0, map:has(m2, init_small_map_key))
test_equal("no small map magic number #2", "No Key", map:get(m2, init_small_map_key, "No Key"))


-- Copy a small map.
map:clear(m1)
map:copy(m2, m1)
test_equal("compare equality #5", 1, map:compare(m1, m2))

m3 = map:new()
map:put( m3, 1, 1, map:LEAVE )
test_equal( "LEAVE adds a new value", 1, map:get( m3, 1 ) )

map:put( m3, 1, 2, map:LEAVE )
test_equal( "LEAVE doesn't affect map #2", 1, map:get( m3, 1 ) )

map:put( m3, 2, 1, map:APPEND )
test_equal( "APPEND new entry", {1}, map:get( m3, 2 ) )

map:optimize( m3, 1, 0.5 )

m2 = map:new(map:threshold())	-- Create a small map
map:put( m2, 1, "ONE", map:APPEND )
map:put( m2, 2, "TWO", map:CONCAT )
test_equal("Initial append/concat small", {{1, {"ONE"}}, {2, "TWO"}}, pairs(m2, 1))

m2 = map:new(map:threshold() + 1)	-- Create a large map
map:put( m2, 1, "ONE", map:APPEND )
map:put( m2, 2, "TWO", map:CONCAT )
test_equal("Initial append/concat large", {{1, {"ONE"}}, {2, "TWO"}}, pairs(m2, 1))


--
-- Done with testing
--

delete_file("save_map.txt")
delete_file("save_map.raw")
delete_file("save_map.raw2")
delete_file("save_map.raw3")
delete_file("xyz.cfg")

test_report()
