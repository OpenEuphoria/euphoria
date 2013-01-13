include std/unittest.e
with define SAFE 
include std/dll.e
include std/machine.e
include std/math.e
include std/sequence.e
constant pointer_size = sizeof(C_POINTER)
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
constant MAXINT_EUPHORIA    =  0b0100 * BASE_PTR - 1
integer gb = 5
constant sum_mul_args = { 2, 5, 9, 3.125, 0.0625, 3, 8, 0.5  }
-- use floor to avoid double / long double conversion issues
-- we must ensure that the number can actually work out the exact number using 64-bit double floats.
constant pow_sum_arg = floor({#BEEF1042/power(2,32)+#B32100,1,#044,3,#BEEF1042/power(2,32)+#B32100,1,#044,3,2,50})

function minus_1_fn() 
	return -1 
end function 

function unsigned_to_signed(atom v, integer t)
	integer sign_bit  = shift_bits(1,-sizeof(t) * 8+1)
	if and_bits(sign_bit,v) then
		return v-shift_bits(sign_bit,-1)
	else
		return v
	end if
end function

constant ubyte_values = { ' ', 192, 172, ')'}

constant unsigned_types      = {  C_UCHAR,   C_UBYTE,   C_USHORT,   C_UINT,    C_POINTER }
constant unsigned_type_names = { "C_UCHAR", "C_UBYTE", "C_USHORT", "C_UINT",  "C_POINTER" }
constant minus_1_values      = { #FF,       #FF,       #FF_FF,      MAXUINT32, MAXUPTR }
constant unsigned_values     = {ubyte_values, ubyte_values,
														50_000 & 8_000 & 20_000,
																	4_000_000_000 & 420_000_000 & 42,
																				#BEEFDEAD & #C001D00D}
											

enum false=0, true=1

atom r_max_uint_fn
for i = 1 to length(minus_1_values) do
	r_max_uint_fn = define_c_func( "", call_back( routine_id("minus_1_fn") ), {}, unsigned_types[i] )
	test_equal( sprintf("return type %s makes unsigned value", {unsigned_type_names[i]}), minus_1_values[i], c_func(r_max_uint_fn, {}) )
end for

constant byte_values = ' ' & -32 & -100 & ')'
constant signed_types      = { C_CHAR,    C_BYTE,   C_SHORT,   C_INT,   C_BOOL,   C_LONG,   C_LONGLONG }
constant signed_type_names = { "C_CHAR", "C_BYTE", "C_SHORT", "C_INT", "C_BOOL", "C_LONG", "C_LONGLONG"}
constant signed_values     = { byte_values, byte_values,
													-20_000 & 10_000 & 20_000,
																(2 & -2) * 1e9,
																	true & false, (2 & -2) * power(2,20),
																							(3 & -2) * power(2,40)}
																		
constant types = signed_types & unsigned_types
constant type_names = signed_type_names & unsigned_type_names
constant values = signed_values & unsigned_values
for i = 1 to length(signed_types) do
	-- 32-bit callbacks don't return anything big enough to be a C_LONGLONG, so skip those
	if pointer_size = 8 or signed_types[i] != C_LONGLONG then
		r_max_uint_fn = define_c_func( "", call_back( routine_id("minus_1_fn") ), {}, signed_types[i] )
		test_equal( sprintf("return type %s preserves -1", {signed_type_names[i]}), -1, c_func(r_max_uint_fn, {}) )
	end if
end for

function pow_sum(sequence s)
	atom sum = 0
	for i = 1 to length(s) by 2 do
		atom p = 1
		while s[i+1] > 0 do
			p *= s[i]
			s[i+1] -= 1
		end while
		sum += p
	end for
	return sum
end function

function sum_mul(sequence s)
	atom product = 1
	for i = 1 to length(s) do
		product *= (s[i] + i)
	end for
	return product
end function



function peekf(atom expected_ptr, integer c_type)
	switch c_type do
		case C_CHAR		then return unsigned_to_signed(peek( expected_ptr ), C_CHAR)
		case C_SHORT	then return peek2s( expected_ptr )
		case C_INT      then return peek4s( expected_ptr )
		case C_LONG     then return peek_longs( expected_ptr )
		case C_LONGLONG then return peek8s( expected_ptr )
		case else
			return "Unexpected type" 
	end switch
end function

constant lib818 = open_dll("./lib818.dll")

assert( "can open lib818.dll", lib818 )
constant c_sum_mul = define_c_func(lib818, "+sum_mul", repeat( C_DOUBLE, 8), C_DOUBLE)
assert( "sum_mul present in dll", c_sum_mul != -1 ) 

integer r_near_hashC, r_below_minimum_euphoria_integer, 
	r_above_maximum_euphoria_integer, r_NOVALUE, r_half_MIN, r_half_MAX
object fs
for i = 1 to length(signed_types) do
	-- test that values get encoded well when coming out from C.
	-- test special values and ranges in EUPHORIA
	if sizeof(signed_types[i]) >= sizeof(E_OBJECT) and signed_types[i] != C_BOOL then
		-- The underlying library will return values in C values that fit into thier values 
		-- but are out of bounds amoung EUPHORIA integers. 
		r_below_minimum_euphoria_integer = define_c_func( lib818, 
			sprintf("+%s_below_EUPHORIA_MIN_INT", {signed_type_names[i]}), {}, signed_types[i] )
		r_above_maximum_euphoria_integer = define_c_func( lib818, 
			sprintf("+%s_above_EUPHORIA_MAX_INT", {signed_type_names[i]}), {}, signed_types[i] )
		r_NOVALUE = define_c_func(lib818, 
			sprintf("+%s_NOVALUE", {signed_type_names[i]}), {}, signed_types[i])			
		r_half_MIN = define_c_func( lib818, 
			sprintf("+%s_half_MIN", {signed_type_names[i]}), {}, signed_types[i] )
		r_half_MAX = define_c_func( lib818, 
			sprintf("+%s_half_MAX", {signed_type_names[i]}), {}, signed_types[i] )
			
		if r_below_minimum_euphoria_integer != -1 and r_above_maximum_euphoria_integer != -1
		and r_NOVALUE != -1 and r_half_MIN != -1 and r_half_MAX != -1 then
			test_equal(
				sprintf("detect negative values as such for type %s #1",{signed_type_names[i]}),  
				MININT_EUPHORIA-20, c_func(r_below_minimum_euphoria_integer, {}))
			test_equal(
				sprintf("detect negative values as such for type %s #2",{signed_type_names[i]}),  
				floor(MININT_EUPHORIA/2), c_func(r_half_MIN, {}))
			test_equal(
				sprintf("detect NOVALUE as its integer value for type %s",{signed_type_names[i]}),  
				NOVALUE - #10 * BASE_PTR, c_func(r_NOVALUE, {}))
			test_equal(
				sprintf("detect positive values as such for type %s #1",{signed_type_names[i]}),  
				MAXINT_EUPHORIA+20, c_func(r_above_maximum_euphoria_integer, {}))
			test_equal(
				sprintf("detect positive values as such for type %s #2",{signed_type_names[i]}),  
				floor(MAXINT_EUPHORIA/2), c_func(r_half_MAX, {}))
		else
			test_fail(sprintf("opening all functions for type %s", {signed_type_names[i]}))
		end if
	end if
	-- test that values that are sometimes large negative values in C are recognized
	-- These values are #C00...00 - 20.
	r_near_hashC = define_c_func( lib818, sprintf("+%s_BFF_FD", 
		{signed_type_names[i]}), {}, signed_types[i] )
	if r_near_hashC != -1 then
		atom expected_ptr = define_c_var( lib818, "+" & signed_type_names[i] & "_BFFD_value" )
		if expected_ptr > 0 then
			atom expected_val = peekf(expected_ptr, signed_types[i])
			test_equal(sprintf("detect #C00...00-20 correctly for type %s",{signed_type_names[i]}),
				expected_val,
				c_func(r_near_hashC, {}))
		end if
	
	end if
	integer r_get_m20 = define_c_func( lib818, sprintf("+%s_M20", 
		{signed_type_names[i]}), {}, signed_types[i] )
	if r_get_m20 != -1 then
		test_equal(sprintf("Can get -20 from a function returning that number as a %s", {signed_type_names[i]}), -20, c_func(r_get_m20, {}))
	end if
	integer r_get_m100 = define_c_func( lib818, sprintf("+%s_M100", 
		{signed_type_names[i]}), {}, signed_types[i] )
	if r_get_m100 != -1 then
		atom expected_ptr = define_c_var( lib818, signed_type_names[i] & "_M100_value" )
		if expected_ptr != 0 then
			test_equal(sprintf("Can get -100 like numbers from a function returning that number as a %s", 
				{signed_type_names[i]}), peekf(expected_ptr, signed_types[i]), c_func(r_get_m100, {}))
		end if
	end if
end for
for i = 1 to length(types) do
	integer value_test_counter = 0
	integer id_r = define_c_func(lib818, "+" & type_names[i] & "_id", {types[i]}, types[i])
	test_true(sprintf("%s id function is in our library", {type_names[i]}), id_r != -1)
	for j = 1 to length(values[i]) do
		value_test_counter += 1
		test_equal(sprintf("Value test for %s #%d", {type_names[i], value_test_counter}),
			values[i][j], c_func(id_r, {values[i][j]}))
	end for
end for

integer bit_repeat_r = define_c_func(lib818, "+bit_repeat", { C_BOOL, C_UBYTE }, C_LONGLONG)
test_equal( "5  repeat bits: ", power(2,5)-1, c_func(bit_repeat_r, {1, 5}))
test_equal( "40 repeating bits: ", power(2,40)-1, c_func(bit_repeat_r, { 1, 40 }))
test_equal( "2**50: ", power(2,50), c_func(bit_repeat_r, {1, 50})+1)
test_equal( "-(2**50): ", -power(2,50), -c_func(bit_repeat_r, {1, 50})-1)


integer pow_sum_c = define_c_func(lib818, "+powsum", repeat_pattern( { C_DOUBLE, C_USHORT }, 5 ), C_DOUBLE )
test_equal( "Can call and things are passed correctly for ten argument functions", pow_sum( pow_sum_arg ), 
	c_func( pow_sum_c, pow_sum_arg) )

test_equal("We are working within the bits of the double", 1125899930950272, pow_sum( pow_sum_arg ))


constant
	OBJECT_FUNC   = define_c_func( lib818, "+object_func", { E_OBJECT }, E_OBJECT ),
	SEQUENCE_FUNC = define_c_func( lib818, "+object_func", { E_SEQUENCE }, E_SEQUENCE ),
	ATOM_FUNC     = define_c_func( lib818, "+object_func", { E_ATOM }, E_ATOM )

test_equal( "object func integer", 5, c_func( OBJECT_FUNC, {5} ) )
test_equal( "object func double", 3.5, c_func( OBJECT_FUNC, {3.5} ) )
test_equal( "object func sequence", "abc", c_func( OBJECT_FUNC, {"abc"}) )

test_equal( "sequence func sequence", "abc", c_func( SEQUENCE_FUNC, {"abc"}) )

test_equal( "atom func integer", 5, c_func( ATOM_FUNC, {5} ) )
test_equal( "atom func double", 3.5, c_func( ATOM_FUNC, {3.5} ) )

test_equal( "Testing passing eight doubles only", c_func( c_sum_mul, sum_mul_args ), sum_mul( sum_mul_args ) )

-- Should put some tests for argument passing as well : passing floating point, double, long long, etc..

test_report()

