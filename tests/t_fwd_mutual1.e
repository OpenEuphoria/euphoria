-- t_fwd_mutual1.e
include std/unittest.e
include fwd_mutual1.e
include fwd_mutual2.e

test_equal( "mutual inclusion 1", 1, fwd1 )
test_equal( "mutual inclusion 2", 2, fwd2 )
test_report()
