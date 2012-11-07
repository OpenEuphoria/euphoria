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

-- one nibble less in magnitude than the smallest number too big to fit into a pointer. 
constant BASE_PTR           = #10 * power(#100,(pointer_size-1))
constant BASE_4             = #10 * power(#100, 3)
constant SEQ_MASK           = #8 * BASE_PTR
constant NOVALUE            = #C * BASE_PTR - 1
constant MAXUPTR            = #10 * BASE_PTR - 1
constant MAXUINT32          = #10 * BASE_4 - 1 
constant MAXUSHORT          = power(2,16)-1
constant MAXUBYTE           = #FF
constant MININT_EUPHORIA    = -0b0100 * BASE_PTR -- on 32-bit: -1_073_741_824
integer gb = 5

function minus_1_fn() 
	return -1 
end function 

constant unsigned_types      = { C_UCHAR, C_UBYTE, C_USHORT, C_UINT, C_POINTER }
constant unsigned_type_names = { "C_UCHAR", "C_UBYTE", "C_USHORT", "C_UINT", "C_POINTER" }
constant minus_1_values      = { #FF, #FF, #FF_FF, MAXUINT32, MAXUPTR }
		 

		
atom r_max_uint_fn
for i = 1 to length(minus_1_values) do
	r_max_uint_fn = define_c_func( "", call_back( routine_id("minus_1_fn") ), {}, unsigned_types[i] )
	test_equal( sprintf("return type %s makes unsigned value", {unsigned_type_names[i]}), minus_1_values[i], c_func(r_max_uint_fn, {}) )
end for

constant signed_types      = { C_CHAR,    C_BYTE,   C_SHORT,   C_INT,   C_BOOL,   C_LONG,   C_LONGLONG }
constant signed_type_names = { "C_CHAR", "C_BYTE", "C_SHORT", "C_INT", "C_BOOL", "C_LONG", "C_LONGLONG" }
for i = 1 to length(signed_types) do
	r_max_uint_fn = define_c_func( "", call_back( routine_id("minus_1_fn") ), {}, signed_types[i] )
	test_equal( sprintf("return type %s preserves -1", {signed_type_names[i]}), -1, c_func(r_max_uint_fn, {}) )
end for

constant lib818 = open_dll("./lib818.dll")

test_true( "Can open lib818.dll", lib818 )
if lib818 then
	-- The underlying library will return values in C values that fit into thier values but are out of bounds 
	-- amoung EUPHORIA integers.  Large negatives can appear to be encoded pointers to sequences, the interpreter uses
	-- internally.  Hence the name 'faux sequence'
	integer r_faux_sequence
	object fs
	for i = 1 to length(signed_types) do
		r_faux_sequence = define_c_func( lib818, sprintf("%s_faux_sequence", {signed_type_names[i]}), {}, signed_types[i] )
		if r_faux_sequence != -1 then
			test_equal(sprintf("detect negative values as such for type %s",{signed_type_names[i]}),  MININT_EUPHORIA-20, c_func(r_faux_sequence, {}))
		end if
	end for
end if	

-- Should put some tests for argument passing as well : passing floating point, double, long long, etc..

test_report()
