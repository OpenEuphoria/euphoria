-- t_c_fwd_inint.e
include std/unittest.e

include c_fwd_init.e

export atom x
ifdef EC then
die because init checks aren't done for the translator
end ifdef
test_equal( "fail forward init check", 0, 1 )
test_report()
