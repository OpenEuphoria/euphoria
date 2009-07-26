include dll.e

include std/unittest.e

function foo( atom a )
	return a + 1
end function


constant
	FOO_RID = routine_id("foo"),
	FOO_DEFAULT = call_back( FOO_RID ),
	FOO_CDECL   = call_back( '+' & FOO_RID ),
	CFOO_DEFAULT = define_c_func( "", FOO_DEFAULT, { C_INT }, C_INT ),
	CFOO_CDECL   = define_c_func( "", '+' & FOO_CDECL, { C_INT }, C_INT )

test_equal( "default convention", 2, c_func( CFOO_DEFAULT, {1}))
test_equal( "explicit cdecl convention", 3, c_func( CFOO_CDECL, {2}))

test_report()
