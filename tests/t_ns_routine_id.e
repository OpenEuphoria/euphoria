--
-- This test is a bit contorted, but it was the smallest test I could come
-- up with that produced the machine exception. When trying 
-- routine_id("t:t_upper") outside of the type function, call_func reported
-- an invalid routine_id. When trying it on a non-map type, it seemed to
-- work just fine also.
--

include std/unittest.e
include std/map.e as map
include std/types.e as t

type str_key_map(object o)
	integer srid = routine_id("t:t_upper")
	return 1
end type

str_key_map m = map:new(10)
map:put(m, "a", 1)

test_pass("type check cause machine exception?")

test_report()
