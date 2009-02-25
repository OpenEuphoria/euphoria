include std/unittest.e

-- Simple regression test for euphoria 3 callbacks and c_funcs
include dll.e as dll3
function eu3_callback( integer a, integer b )
	return a + b
end function
constant
	eu3_stdcall_cb = dll3:call_back( routine_id("eu3_callback") ),
	eu3_cdecl_db   = dll3:call_back( '+' & routine_id("eu3_callback") )
constant
	c_eu3stdcall   = dll3:define_c_func( "", eu3_stdcall_cb, { dll3:E_INTEGER, dll3:E_INTEGER }, dll3:E_INTEGER ),
	c_eu3cdecl     = dll3:define_c_func( "", '+' & eu3_stdcall_cb, { dll3:E_INTEGER, dll3:E_INTEGER }, dll3:E_INTEGER )

test_equal( "Eu3:callback regular callback/define_c_func", 3, c_func( c_eu3stdcall, {1,2} ) )
test_equal( "Eu3:callback '+' callback/define_c_func", 3, c_func( c_eu3cdecl, {1,2} ) )
