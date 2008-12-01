include std/unittest.e

include obj_fwd.e

export integer a
export atom b
export sequence c
export object d

test_equal( "detect uninitialized integer", 0, object( a ) )
test_equal( "detect uninitialized atom", 0, object( b ) )
test_equal( "detect uninitialized sequence", 0, object( c ) )
test_equal( "detect uninitialized object", 0, object( d ) )

forward_test_uninitialized()

a = 0
b = 0
c = "c"
d = ""

test_equal( "detect initialized integer", 1, object( a ) )
test_equal( "detect initialized atom", 1, object( b ) )
test_equal( "detect initialized sequence", 1, object( c ) )
test_equal( "detect initialized object", 1, object( d ) )

forward_test_initialized()

function regular_function()
	return 1
end function

test_equal( "regular function call", 1, object( regular_function() ) )
test_equal( "forward function call", 1, object( forward_function() ) )

function forward_function()
	return 1
end function

c = {1,2,3,{4,5,6}}

test_equal( "subscripted object call", 1, object( c[1] ) )
test_equal( "subscripted twice object call", 1, object( c[4][1] ) )
test_equal( "subscripted dollar object call", 1, object( c[$] ) )
test_equal( "subscripted dollar and number object call", 1, object( c[$][1] ) )
test_equal( "double subscripted dollar object call", 1, object( c[$][$] ) )
forward_test_subscripts()

test_report()
