include std/unittest.e
include std/map.e

map the_map

the_map = map:new(map:threshold() + 1)
map:put(the_map, 1, 2, map:MULTIPLY)
