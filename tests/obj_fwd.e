include std/unittest.e
include t_object.e

export procedure forward_test_uninitialized()
	test_equal( "forward detect uninitialized integer", 0, object( integer_sym ) )
	test_equal( "forward detect uninitialized atom", 0, object( atom_sym ) )
	test_equal( "forward detect uninitialized sequence", 0, object( sequence_sym ) )
	test_equal( "forward detect uninitialized object", 0, object( object_sym ) )
end procedure

export procedure forward_test_initialized()
	test_equal( "forward detect initialized integer", 1, object( integer_sym ) )
	test_equal( "forward detect initialized atom", 2, object( atom_sym ) )
	test_equal( "forward detect initialized sequence", 3, object( sequence_sym ) )
	test_true( "forward detect initialized object", object( object_sym ) )
end procedure

export procedure forward_test_subscripts()
	test_true( "subscripted object call", object( sequence_sym[1] ) )
	test_true( "subscripted twice object call", object( sequence_sym[4][1] ) )
	test_true( "subscripted dollar object call", object( sequence_sym[$] ) )
	test_true( "subscripted dollar and number object call", object( sequence_sym[$][1] ) )
	test_true( "double subscripted dollar object call", object( sequence_sym[$][$] ) )
end procedure
