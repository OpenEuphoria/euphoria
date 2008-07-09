include unittest.e
include map.e as m
include sort.e
include text.e

map m1
m1 = m:new()

-- add integers from -5 to 5 with keys -50 to 50
for i = -5 to 5 do
	m1 = m:put(m1, i, i*10)
end for
test_equal("map m1 get -5",             -50, m:get(m1, -5, 999) )
test_equal("map m1 get 0",                0, m:get(m1,  0, 999) )
test_equal("map m1 get 5",               50, m:get(m1,  5, 999) )
test_equal("map m1 get 6",              999, m:get(m1,  6, 999) )
test_equal("map m1 get 8",              999, m:get(m1,  8, 999) )
test_equal("map m1 get -199999999999",  "abc",  m:get(m1, -199999999999, "abc"))
test_equal("map m1 get \"XXXXXXXXXX\"", 999,    m:get(m1, "XXXXXXXXXX", 999))
test_equal("map m1 size#1", 11, m:size(m1))
test_equal("map m1 keys", {-5,-4,-3,-2,-1,0,1,2,3,4,5}, sort(m:keys(m1)) )

-- add 1000 integers, 5 of which are already in the map
for i = 1 to 1000 do
	m1 = m:put(m1, i, sprint(i))
end for

test_equal("map m1 size#2", 1006, m:size(m1))

test_equal("map m1 get 5#2",               "5", m:get(m1,  5, 999) )
test_equal("map m1 get 1000",           "1000", m:get(m1, 1000, 999) )

-- add 2000 floats
for i = 1 to 1000 do
	m1 = m:put(m1, -i*1.333333, i)
end for

for i = 1 to 1000 do
	m1 = m:put(m1, 1e100+i*1e90, i)
end for
test_equal("map m1 get#1 -133.3333",           100, m:get(m1, -1.333333*100, 999) )

m1 = rehash(m1, 100)
test_equal("map m1 get#2 -133.3333",           100, m:get(m1, -1.333333*100, 999) )
m1 = rehash(m1, 10000)
test_equal("map m1 get#3 -133.3333",           100, m:get(m1, -1.333333*100, 999) )

test_equal("map m1 get 1e100+999e90",       999, m:get(m1, 1e100+999e90, "") )

test_equal("map m1 size#3", 3006, m:size(m1))

object opm
object opms
object m1s
opm = optimize(m1)
m1s = statistics(m1)
opms = statistics(opm)

test_true("map optimize #1", m1s[1] = opms[1]) -- total element unchanged
test_true("map optimize #2", m1s[2] > opms[2]) -- In Use buckets should reduce
test_true("map optimize #3", m1s[3] > opms[3]) -- Total Buckets should reduce


-- m2: strings and objects
map m2
m2 = m:new(33)


for i = 1 to 33 do
	m2 = m:put(m2, repeat('a', i), i)
end for

test_equal("map m2 size#1", 33, m:size(m2))
test_equal("map m2 get a", 1, m:get(m2, "a", 999))
test_equal("map m2 get aaaaaaaaaaaaaaaaaaaaaaaaaaa", 27, m:get(m2, "aaaaaaaaaaaaaaaaaaaaaaaaaaa", 999))
test_equal("map m2 get aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", 999, m:get(m2, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", 999))

object n
for i = 1 to 7 do
	n = repeat(repeat(repeat(repeat(repeat(repeat({99, 99.9, "99"}, i), i), i), i), i), i)
	m2 = m:put(m2, n, i)
end for

test_equal("map m2 get (n)", 7, m:get(m2, n, 999))
test_equal("map m2 values",  {1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33}, sort(m:values(m2)))

test_equal("map m2 size#2", 40, m:size(m2))
m2 = m:remove(m2, n)

test_equal("map m2 size#3", 39, m:size(m2))

map m3
m3 = m:new()
m3 = m:put(m3, 1, 11)
m3 = m:put(m3, 2, 22)
m3 = m:put(m3, 3, 33)
m3 = m:remove(m3, 2)

test_equal("map m3 size#1", 2, m:size(m3))

map m4
m4 = m:new()
m4 = m:put(m4, 1, 11)

test_equal("map m4 has -- yes", 1, m:has(m4, 1))
test_equal("map m4 has -- no", 0, m:has(m4, 2))

m1 = load_map("test_map.txt")

test_equal("map load #1", "bar", m:get(m1, "foo",-1))
test_equal("map load #2", "foo", m:get(m1, "bar",-1))
test_equal("map load #3", "comment", m:get(m1, "trail",-1))
test_equal("map load #4", 10, m:get(m1, "int",-1))
test_equal("map load #5", 3.4, m:get(m1, "atom",-1))
test_equal("map load #6", {"one", 2, 3.4}, m:get(m1, "seq",-1))
test_equal("map load #7", -1, m:get(m1, "missing",-1))
test_equal("map load equal", "=", m:get(m1, "equal",-1))
test_equal("map load padding", " padded ", m:get(m1, "padding",-1))
test_equal("map load embed", "--", m:get(m1, "embed",-1))

map m5
m5 = m:new()
m5 = m:put( m5, ADD, 1 )
m5 = m:put( m5, ADD, 1, ADD ) -- 2
test_equal( "put ADD", 2, m:get( m5, ADD, "" ) )

m5 = m:put( m5, MULTIPLY, 2 )
m5 = m:put( m5, MULTIPLY, 3, MULTIPLY ) -- 6
test_equal( "put MULTIPLY", 6, m:get( m5, MULTIPLY, "" ) )

m5 = m:put( m5, DIVIDE, 6 )
m5 = m:put( m5, DIVIDE, 2, DIVIDE ) -- 3
test_equal( "put DIVIDE", 3, m:get( m5, DIVIDE, "" ) )

m5 = m:put( m5, SUBTRACT, 3 )
m5 = m:put( m5, 3, 3, SUBTRACT )
test_equal( "put SUBTRACT", 0, m:get( m5, SUBTRACT, "" ) )

m5 = m:put( m5, CONCAT, "foo" )
m5 = m:put( m5, CONCAT, "bar", CONCAT )
test_equal( "put CONCAT", "foobar", m:get( m5, CONCAT, "" ) )

m5 = m:put( m5, APPEND, {"foo"} )
m5 = m:put( m5, APPEND, "bar", APPEND )
test_equal( "put APPEND", {"foo","bar"}, m:get( m5, APPEND, "" ) )

test_report()

