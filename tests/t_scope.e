include std/unittest.e

include scope_3.e
include scope_1.e

test_equal( "public include (not on initial include)", "public constant", PUBLIC_CONSTANT )
test_equal( "public include (not on initial include) using default namespace", 1, S2:sprintf() )

test_report()
