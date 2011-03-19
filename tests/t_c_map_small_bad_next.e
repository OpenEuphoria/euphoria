include std/unittest.e
include std/map.e

map the_map
constant BAD_ACTION = 0
the_map = map:new(map:threshold())
map:put(the_map, 1, 2, PUT)
map:put(the_map, 1, 2, BAD_ACTION)
