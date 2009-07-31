include std/unittest.e
include std/sort.e

test_equal( "default namespace include", {1,2,3}, stdsort:sort({3,2,1}, ASCENDING ) )
test_equal( "without default namespace include", {1,2,3}, sort({3,2,1}, ASCENDING ) )
