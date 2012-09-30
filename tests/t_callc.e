include std/unittest.e
with define SAFE 
include std/dll.e
include std/machine.e
include std/math.e

ifdef EU4_0 then
	constant pointer_size = 4
	procedure poke_pointer(atom a, object x)
		poke4(a,x)
	end procedure
elsedef
	constant pointer_size = sizeof(C_POINTER)
end ifdef

constant BASE = #10 * power(#100,(pointer_size-1))
constant SEQ_MASK =  #8 * BASE
constant NOVALUE  =  #C * BASE - 1
constant MAXUINT =  #10 * BASE - 1 
integer gb = 5

function minus_1_fn() 
	return -1 
end function 
atom r_max_uint_fn  = define_c_func( "", call_back( routine_id("minus_1_fn") ), {}, C_POINTER )
test_equal( "return type C_POINTER makes unsigned value", MAXUINT32, c_func(r_max_uint_fn, {}) )

r_max_uint_fn = define_c_func( "", call_back( routine_id("minus_1_fn") ), {}, C_UINT )
test_equal( "return type C_UINT makes unsigned value", MAXUINT32, c_func(r_max_uint_fn, {}) )



test_report()

