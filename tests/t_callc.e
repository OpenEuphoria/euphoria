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


function bar(integer a)
   return gb + a
end function

function barn(integer a, integer b)
	return a*a / b*b
end function

atom r_bar = define_c_func({}, call_back(routine_id("bar")), { E_INTEGER }, E_INTEGER )
atom r_barn = define_c_func({}, call_back(routine_id("barn")), {E_INTEGER, E_INTEGER}, E_ATOM )

test_equal("return type E_ATOM: pass one argument (E_INTEGER)", 15, c_func(r_bar, {10}))
test_equal("return type E_ATOM: pass two arguments (E_INTEGER,E_INTEGER)", 16/9, c_func(r_barn, {4,3}))

function is_sequence(object x)
	return sequence(x)
end function

-- create a sequence the lowlevel way:  The function is_sequence should get a sequence.
atom r_is_sequence = define_c_func({}, call_back(routine_id("is_sequence")), {C_POINTER}, C_INT)
atom synthetic_sequence = allocate(6 * pointer_size)
if pointer_size = 4 then
	poke_pointer(synthetic_sequence, {synthetic_sequence+4*pointer_size, 0 /* length */, 1 /* ref */, 
		/* cleanup */0, /* postfill */ 0, NOVALUE})
else
	poke_pointer(synthetic_sequence, {synthetic_sequence+4*pointer_size, 0 /* cleanup */, 1 /* ref */, 
		/* length */ 0, /* postfill */ 0, NOVALUE})
end if
atom encoded_synthetic_sequence = or_bits(SEQ_MASK,shift_bits(r_is_sequence,-3))
test_true("creation of a sequence the lowlevel way", c_func(r_is_sequence, {encoded_synthetic_sequence}))
test_report()

