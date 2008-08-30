-- t_c_fwd_typecheck.e
include std/unittest.e

include c_fwd_typecheck.e

export sequence s

ifdef EC then
die a horrible death
else
-- typechecks are turned off when translated...
test_equal( "fail forward type check", 0, 1 )
end ifdef

test_report()
