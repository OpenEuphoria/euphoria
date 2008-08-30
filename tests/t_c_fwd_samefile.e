-- t_c_fwd_samefile.e
include std/unittest.e

x = 1

atom x

test_equal( "fail forward ref of variable, same file", 0, 1 )
test_report()
