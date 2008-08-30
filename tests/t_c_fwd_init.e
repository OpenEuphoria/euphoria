-- t_c_fwd_inint.e
include std/unittest.e

include c_fwd_init.e

export atom x

test_equal( "fail forward init check", 0, 1 )
test_report()
