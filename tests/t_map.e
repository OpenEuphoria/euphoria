include unittest.e
include map.e
include sort.e


set_test_module_name("map.e")

map m1
m1 = map_new()

-- add integers from -5 to 5 with keys -50 to 50
for i = -5 to 5 do
	m1 = map_put(m1, i, i*10)
end for

test_equal("map m1 get -5",             -50, map_get(m1, -5, 999) )
test_equal("map m1 get 0",                0, map_get(m1,  0, 999) )
test_equal("map m1 get 5",               50, map_get(m1,  5, 999) )
test_equal("map m1 get 6",              999, map_get(m1,  6, 999) )
test_equal("map m1 get 8",              999, map_get(m1,  8, 999) )
test_equal("map m1 get -199999999999",  "abc",  map_get(m1, -199999999999, "abc"))
test_equal("map m1 get \"XXXXXXXXXX\"", 999,    map_get(m1, "XXXXXXXXXX", 999))
test_equal("map m1 size#1", 11, map_size(m1))
test_equal("map m1 keys", {-5,-4,-3,-2,-1,0,1,2,3,4,5}, sort(map_keys(m1)) )

-- add 1000 integers
for i = 1 to 1000 do
	m1 = map_put(m1, i, sprint(i))
end for

test_equal("map m1 size#2", 1006, map_size(m1))

test_equal("map m1 get 5#2",               "5", map_get(m1,  5, 999) )
test_equal("map m1 get 1000",           "1000", map_get(m1, 1000, 999) )

-- add 2000 floats
for i = 1 to 1000 do
	m1 = map_put(m1, -i*1.333333, i)
end for

for i = 1 to 1000 do
	m1 = map_put(m1, 1e100+i*1e90, i)
end for

test_equal("map m1 get -133.3333",           100, map_get(m1, -1.333333*100, 999) )
test_equal("map m1 get 1e100+999e90",       999, map_get(m1, 1e100+999e90, "") )

test_equal("map m1 size#3", 3006, map_size(m1))

--?m1

-- m2: strings and objects

map m2
m2 = map_new()

for i = 1 to 33 do
	m2 = map_put(m2, repeat('a', i), i)
end for

test_equal("map m2 size#1", 33, map_size(m2))
test_equal("map m2 get a", 1, map_get(m2, "a", 999))
test_equal("map m2 get aaaaaaaaaaaaaaaaaaaaaaaaaaa", 27, map_get(m2, "aaaaaaaaaaaaaaaaaaaaaaaaaaa", 999))
test_equal("map m2 get aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", 999, map_get(m2, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", 999))

object n
for i = 1 to 7 do
	n = repeat(repeat(repeat(repeat(repeat(repeat({99, 99.9, "99"}, i), i), i), i), i), i)
	m2 = map_put(m2, n, i)
end for

test_equal("map m2 get (n)", 7, map_get(m2, n, 999))
test_equal("map m2 values",  {1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33}, sort(map_values(m2)))

test_equal("map m2 size#2", 40, map_size(m2))
m2 = map_remove(m2, n)

test_equal("map m2 size#3", 39, map_size(m2))

map m3
m3 = map_new()
m3 = map_put(m3, 1, 11)
m3 = map_put(m3, 2, 22)
m3 = map_put(m3, 3, 33)
m3 = map_remove(m3, 2)


test_equal("map m3 size#1", 2, map_size(m3))
--? map_size(m3)
