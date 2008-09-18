-- t_fwd_mutual1.e
include std/unittest.e
include fwd_mutual1.e
include fwd_mutual2.e

test_equal( "mutual inclusion 1", 1, fwd1 )
test_equal( "mutual inclusion 2", 2, fwd2 )

test_equal( "forward addition", 2, fwd_add )
test_equal( "forward subtraction", 0, fwd_sub )
test_equal( "forward multiplication", 12, fwd_mult )
test_equal( "forward multiplication by 2", 4, fwd_mult2 )
test_equal( "forward division", 3, fwd_div )
test_equal( "forward division by 2", 2, fwd_div2 )
test_equal( "forward subscript assign", {1}, fwd_sub_assign )

test_report()
