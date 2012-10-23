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

constant BASE_PTR = #10 * power(#100,(pointer_size-1))
constant BASE_4 = #10 * power(#100, 3)
constant SEQ_MASK =  #8 * BASE_PTR
constant NOVALUE  =  #C * BASE_PTR - 1
constant MAXUPTR =  #10 * BASE_PTR - 1
constant MAXUINT =  #10 * BASE_4 - 1 
constant MAXUSHORT = power(2,16)-1
constant MAXUBYTE  = #FF
integer gb = 5

function minus_1_fn() 
	return -1 
end function 

constant unsigned_types      = { C_UCHAR, C_UBYTE, C_USHORT, C_UINT, C_POINTER }
constant unsigned_type_names = { "C_UCHAR", "C_UBYTE", "C_USHORT", "C_UINT", "C_POINTER" }
constant minus_1_values      = { #FF, #FF, #FF_FF, MAXUINT, MAXUPTR }
		 

		
atom r_max_uint_fn
for i = 1 to length(minus_1_values) do
	r_max_uint_fn = define_c_func( "", call_back( routine_id("minus_1_fn") ), {}, unsigned_types[i] )
	test_equal( sprintf("return type %s makes unsigned value", {unsigned_type_names[i]}), minus_1_values[i], c_func(r_max_uint_fn, {}) )
end for

constant signed_types      = { C_CHAR, C_BYTE, C_SHORT, C_INT, C_BOOL, C_LONG }
constant signed_type_names = { "C_CHAR", "C_BYTE", "C_SHORT", "C_INT", "C_BOOL", "C_LONG" }
for i = 1 to length(signed_types) do
	r_max_uint_fn = define_c_func( "", call_back( routine_id("minus_1_fn") ), {}, signed_types[i] )
	test_equal( sprintf("return type %s preserves -1", {signed_type_names[i]}), -1, c_func(r_max_uint_fn, {}) )
end for

test_report()

