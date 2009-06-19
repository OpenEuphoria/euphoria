include std/unittest.e
include std/map.e
include std/sort.e
include std/text.e
include std/pretty.e

object o1, o2, o3
o1 = map:threshold()
o2 = map:threshold(60)
o3 = map:threshold()
test_equal("map get threshold #1", o1, o2 )
test_equal("map get threshold #2", 60, o3 )


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

test_equal("map m1 type #1", SMALLMAP, map:type_of(m1))

-- add 1000 integers, 5 of which are already in the map
for i = 1 to 1000 do
	map:put(m1, i, sprint(i))
end for
test_equal("map m1 type #2", LARGEMAP, map:type_of(m1))
test_true ("map m1 has #3", map:has(m1, 0))
test_false("map m1 has #4", map:has(m1, 9999))

test_equal("map m1 size#2", 1006, map:size(m1))

test_equal("map m1 get 5#2",               "5", map:get(m1,  5, 999) )
test_equal("map m1 get 1000",           "1000", map:get(m1, 1000, 999) )

-- add 2000 floats
for i = 1 to 1000 do
	map:put(m1, -i*1.333333, i)
end for

for i = 1 to 1000 do
	map:put(m1, 1e100+i*1e90, i)
end for
test_equal("map m1 get#1 -133.3333",           100, map:get(m1, -1.333333*100, 999) )

rehash(m1, 100)
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

test_true("map optimize #1", m1s[NUM_ENTRIES] = opms[NUM_ENTRIES]) -- total element unchanged

clear(m1)
test_equal( "map clear #1", 0, map:size(m1))
test_equal( "map clear #2", LARGEMAP, map:type_of(m1))

-- m2: strings and objects
map:map m2
m2 = map:new(map:threshold())	-- Create a small map


for i = 1 to 33 do
	map:put(m2, repeat('a', i), i)
end for

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
test_equal("map m3 type #1", LARGEMAP, map:type_of(m3))
map:remove(m3, 2)
test_equal("map m3 type #2", SMALLMAP, map:type_of(m3))
test_equal("map m3 size#1", 2, map:size(m3))
map:remove(m3, 2)
test_equal("map m3 size#2", 2, map:size(m3))

map:map m4
m4 = map:new()
map:put(m4, 1, 11)

test_equal("map m4 has -- yes", 1, map:has(m4, 1))
test_equal("map m4 has -- no", 0, map:has(m4, 2))

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

test_equal("map save #1", 12, save_map(m1, "save_map.txt", SM_TEXT))
m2 = load_map("save_map.txt")
test_equal("map save #2", 1, map:compare(m1,m2))
	
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
	
map:map m5
m5 = map:new(10)
map:put( m5, ADD, 1 )
map:put( m5, ADD, 1, ADD ) -- 2
test_equal( "put ADD", 2, map:get( m5, ADD, "" ) )

map:put( m5, MULTIPLY, 2 )
map:put( m5, MULTIPLY, 3, MULTIPLY ) -- 6
test_equal( "put MULTIPLY", 6, map:get( m5, MULTIPLY, "" ) )

map:put( m5, DIVIDE, 6 )
map:put( m5, DIVIDE, 2, DIVIDE ) -- 3
test_equal( "put DIVIDE", 3, map:get( m5, DIVIDE, "" ) )

map:put( m5, SUBTRACT, 3 )
map:put( m5, 3, 3, SUBTRACT )
test_equal( "put SUBTRACT", 0, map:get( m5, SUBTRACT, "" ) )

map:put( m5, CONCAT, "foo" )
map:put( m5, CONCAT, "bar", CONCAT )
test_equal( "put CONCAT", "foobar", map:get( m5, CONCAT, "" ) )

map:put( m5, APPEND, {"foo"} )
map:put( m5, APPEND, "bar", APPEND )
test_equal( "put APPEND", {"foo","bar"}, map:get( m5, APPEND, "" ) )


map:map city_population
city_population = new()
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
test_equal( "map clear #2", SMALLMAP, map:type_of(m1))
delete(m1)
test_false( "delete #1", map:map(m1))

delete(city_population)
test_false( "delete #2", map:map(city_population))

o2 = map:threshold(20)
m1 = new(30)
m2 = new(400)
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

map cm1 = new()
map cm2 = new()

put(cm1, "XY", 1)
put(cm1, "AB", 2)
put(cm2, "XY", 3)

-- Add same keys' values.
copy(cm1, cm2, ADD)

test_equal("copy w/destinaion ADD", { {"AB", 2}, {"XY", 4} }, pairs(cm2, 1))

--
-- Done with testing
--

test_report()
