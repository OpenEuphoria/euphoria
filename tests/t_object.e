
include std/unittest.e

ifdef not EC then
include obj_fwd.e

export integer integer_sym
export atom atom_sym
export sequence sequence_sym
export object object_sym

test_equal( "detect uninitialized integer", 0, object( integer_sym ) )
test_equal( "detect uninitialized atom", 0, object( atom_sym ) )
test_equal( "detect uninitialized sequence", 0, object( sequence_sym ) )
test_equal( "detect uninitialized object", 0, object( object_sym ) )

forward_test_uninitialized()

integer_sym = 0
atom_sym = 0.1
sequence_sym = "sequence_sym"
object_sym = ""

test_equal( "detect initialized integer", 1, object( integer_sym ) )
test_equal( "detect initialized atom", 2, object( atom_sym ) )
test_equal( "detect initialized sequence", 3, object( sequence_sym ) )
test_true ( "detect initialized object", object( object_sym ) )

forward_test_initialized()

function regular_function()
	return 1
end function

test_true( "regular function call", object( regular_function() ) )
test_true( "forward function call", object( forward_function() ) )

function forward_function()
	return 1
end function

sequence_sym = {1,2,3,{4,5,6}}

test_true( "subscripted object call", object( sequence_sym[1] ) )
test_true( "subscripted twice object call", object( sequence_sym[4][1] ) )
test_true( "subscripted dollar object call", object( sequence_sym[$] ) )
test_true( "subscripted dollar and number object call", object( sequence_sym[$][1] ) )
test_true( "double subscripted dollar object call", object( sequence_sym[$][$] ) )
forward_test_subscripts()

end ifdef

test_report()
