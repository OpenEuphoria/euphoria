
include std/unittest.e
include std/sort.e as srt

without indirect_includes
include indirect.e
with indirect_includes

test_equal( "global w/out indirect_includes doesn't interfere", {1,2,3}, sort({3,2,1}, ASCENDING ) )

integer 
	qualified_rid = routine_id("srt:sort"),
	unqualified_rid = routine_id("sort")

test_not_equal( "qualified routine id with namespace", -1, qualified_rid )
test_not_equal( "unqualified routine id with namespace", -1, unqualified_rid )
test_equal( "qualified rid = unqualified rid", qualified_rid, unqualified_rid )

test_equal( "qualified rid call_func", {3,2,1}, call_func( qualified_rid, { {2,3,1}, DESCENDING} ) )
test_equal( "unqualified rid call_func", {3,2,1}, call_func( unqualified_rid, { {2,3,1}, DESCENDING} ) )

test_report()
