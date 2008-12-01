include std/unittest.e
include t_object.e

export procedure forward_test_uninitialized()
	test_equal( "forward detect uninitialized integer", 0, object( a ) )
	test_equal( "forward detect uninitialized atom", 0, object( b ) )
	test_equal( "forward detect uninitialized sequence", 0, object( c ) )
	test_equal( "forward detect uninitialized object", 0, object( d ) )
end procedure

export procedure forward_test_initialized()
	test_equal( "forward detect initialized integer", 1, object( a ) )
	test_equal( "forward detect initialized atom", 1, object( b ) )
	test_equal( "forward detect initialized sequence", 1, object( c ) )
	test_equal( "forward detect initialized object", 1, object( d ) )
end procedure

export procedure forward_test_subscripts()
	test_equal( "subscripted object call", 1, object( c[1] ) )
	test_equal( "subscripted twice object call", 1, object( c[4][1] ) )
	test_equal( "subscripted dollar object call", 1, object( c[$] ) )
	test_equal( "subscripted dollar and number object call", 1, object( c[$][1] ) )
	test_equal( "double subscripted dollar object call", 1, object( c[$][$] ) )
end procedure
