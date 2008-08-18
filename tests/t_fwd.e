-- t_fwd.e
include std/unittest.e

integer n0=2
integer var1
foo()
test_equal("Basic declare, with def parms",4,var1)
procedure foo(integer n = n0 + 2)
     var1 = n
end procedure

export sequence result3 = repeat(0,3)
export integer result2

foo2(0)
test_equal("define in another file", 123, result2)

n0 = foo3( 5 )
test_equal("with pseudo namespace #1", {1,2,3}, result3)
test_equal("with pseudo namespace #2", 8 , n0)

include fwd.e

test_report()
