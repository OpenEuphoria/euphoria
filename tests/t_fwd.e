-- t_fwd.e

include std/unittest.e

-- These files test resolution of unincluded globals, which
-- are treated as forward resolutions until the end of parsing
include fwdglobal.e
include fwdnoinc.e

global type sloppy( object s )
	return 1
end type
check_unincluded_type( 1 )
test_pass( "Unincluded global / forward type" )

integer n0=2
integer var1
public sequence result4 = repeat(0,4)
export sequence result3 = repeat(0,3)
export integer result2

foo()
test_equal("Basic declare, with def parms",4,var1)
procedure foo(integer n = n0 + 2)
     var1 = n
end procedure


foo2(0)
test_equal("define in another file", 123, result2)

--n0 = xyz:foo3( 5 )
n0 = foo3( 5 )
test_equal("with namespace #1", {1,2,3}, result3)
test_equal("with namespace #2", 8 , n0)

n0 = foo4( 6 )
test_equal("with pseudo namespace #1", {1,2,3,4}, result4)
test_equal("with pseudo namespace #2", 10 , n0)


function forward_constant_default_param( atom val = EXPORT_CONSTANT )
	return val
end function
test_equal( "forward constant default param", EXPORT_CONSTANT, forward_constant_default_param() )



include fwd.e
include fwd2.e

export constant FOO = "t_fwd"

object a, b, c, d, e, f, g, h
export atom fwd_var
test_equal("forward assign different file", 1, fwd_var )

export atom var2
foo5()
test_equal( "forward assign in a procedure", 3, var2 )
test_equal( "forward ref with multiple args (non-default)", 3, mult_args_fwd( 1, 2 ) )
test_equal( "nested forward call with different number of args", 3, mult_args_fwd( 1, single_arg_fwd( 1 ) ) )

function mult_args_fwd( integer a, integer b )
	return a + b
end function

function single_arg_fwd( integer a )
	return a + 1
end function

boolean bool = 1
test_pass( "foward integer type check" )
type boolean( integer b )
	return b = 0 or b = 1
end type

procedure bbar()
end procedure

function bbaz()
	return 0
end function

procedure ffoo( int bbar, int bbaz )
end procedure

type int( object i )
	return integer( i )
end type
test_pass( "forward type with param name reused from routine name" )

fwd_noassign()
function fwd_noassign()
	return 1
end function

test_equal( "call forward function with default parameter that is forward referenced, plus inlined",
	1, fwd_inlined_default_fwd_param() )

function fwd_inlined_default_fwd_param( object x = bar() )
	return 1
end function

function bar()
	return 1
end function

procedure ticket_560()
	forward_global_sequence = return_a_sequence()
end procedure
ticket_560()
test_pass( "ticket 560 issue is resolved" )

test_report()
