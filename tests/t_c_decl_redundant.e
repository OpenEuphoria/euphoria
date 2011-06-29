-- t_c_fwd_reduandant.e
include std/unittest.e

include x1.e
include x2.e

? x
test_equal( "fail forward redundancy check", 0, 1 )
test_report()
