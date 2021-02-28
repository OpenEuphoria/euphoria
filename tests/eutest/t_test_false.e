-- Has a variety of unit tests that are supposed to work and 
-- some are supposed to fail.

include std/unittest.e

test_true( "test_true that should fail", 0 )
test_true( "test_true that should suceed", 1 )
test_false( "test_false that should succeed", 0)
test_false( "test_false that should fail", 1)
test_equal( "test_equal that should succeed", 1, 1 )
test_equal( "test_equal that should fail", 0, 1 )

test_report()
