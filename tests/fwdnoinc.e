include std/unittest.e

test_equal( "non-include global type resolution", UDT(0), 1 )
test_equal( "non-include global constant", FORWARD_GLOBAL, 1 )
