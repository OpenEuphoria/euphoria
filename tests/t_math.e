include std/machine.e
include std/math.e
include std/unittest.e
include std/convert.e
test_equal("gcd", 17, gcd(1999*3*17,1993*17*7))
test_equal("gcd 1c ", 1,  gcd(-4, -1)  )

test_equal("is_even #1", 1, is_even(12) )
test_equal("is_even #2", 0, is_even(7) )
test_equal("is_even_obj", {1,0}, is_even_obj({2,3}) )
test_not_equal("is_even_obj 1c ", 0,  is_even_obj(4.0)  )
test_equal("is_even_obj 2c ", 0,  is_even_obj(4.1)  )

test_equal("or_all", and_bits(#DEADBEE5,-1), or_all({#D000_0000,#0E00_0000,#00AD0000,#BEE5}))
test_equal("or_all 1c ", 1,  or_all(1) )
test_equal("or_all 2c ", 7,  or_all({1, {2,4}}) )

test_equal("ceil() integer", 5, ceil(5))
test_equal("ceil() float #1", 4, ceil(4.0))
test_equal("ceil() float #2", 5, ceil(4.1))
test_equal("ceil() float #3", 5, ceil(4.5))
test_equal("ceil() float #4", 5, ceil(4.6))
test_equal("ceil() sequence", {1,2,3,4,5}, ceil({0.6, 1.2, 3.0, 3.8, 4.4}))
test_equal("ceil() large integer", 2192837283, ceil(2192837283))

test_equal("round() float #1", 5.5, round(5.49854, 10))
test_equal("round() float #2", 5.50, round(5.49854, 100))
test_equal("round() float #3", 5.498, round(5.49843, 1000))
test_equal("round() float #4", 5.4984, round(5.49843, 10000))
test_equal("round() sequence #1", {5.5, 4.3}, round({5.48, 4.25}, 10))
test_equal("round() sequence #2", {5.48, 4.26}, round({5.482, 4.256}, 100))

test_equal("round() (default) float #1", 5, round(4.6))
test_equal("round() (default) float #2", 5, round(4.5))
test_equal("round() (default) float #3", 4, round(4.4))
test_equal("round() (default) sequence", {1,2,3,4}, round({0.5, 2.1, 2.9, 3.6}))
test_equal("round 1c ", "1234",  round("1234", "xxxx" ) )

test_equal("sign() integer #1", 1, sign(10))
test_equal("sign() integer #2", -1, sign(-10))
test_equal("sign() integer #3", 0, sign(0))
test_equal("sign() float #1", 1, sign(10.5))
test_equal("sign() float #2", -1, sign(-10.5))
test_equal("sign() float #3", 0, sign(0.0))
test_equal("sign() sequence", {1, 0, -1}, sign({10, 0, -10.3}))

test_equal("abs() integer #1", 10, abs(10))
test_equal("abs() integer #2", 10, abs(-10))
test_equal("abs() integer #3", 0, abs(0))
test_equal("abs() float #1", 10.5, abs(10.5))
test_equal("abs() float #2", 10.5, abs(-10.5))
test_equal("abs() float #3", 0.0, abs(0.0))
test_equal("abs() sequence", {0, 10.5, 11, 12}, abs({0, -10.5, 11, -12}))

test_equal("sum() integer", 10, sum(10))
test_equal("sum() sequence", 10, sum({1, 2, 2, 4, 1}))
test_equal("sum() two sequences", 
    {2,4,5,6,    2,2.2,{6.3},    1.1,0.4,{3.6},   {2},{2.2},{6.3},  {6},#C000001}, 
    {1,4,2,3,    1,2  ,3    ,    0.1,0.2, 0.3,    {1},{2},  {3},    {2},#C000000} 
  + {1,0,3,3,    1,0.2,{3.3},      1,0.2,{3.3},    1, 0.2,  {3.3},  {4},       1} ) 
test_equal("sum 1c ", 7,   sum({1, {2,4}}) )

test_equal("min() integer", 5, min(5))
test_equal("min() sequence", 3, min({5,8,3,100,32}))

test_equal("max() integer", 5, max(5))
test_equal("max() integer", 109, max({5,4,3,109,108,35}))


function close_enough( object expected, object result, atom epsilon )
	return abs( expected - result ) < epsilon
end function

test_equal("log() #1", 1, close_enough( 2.30259, log(10), 0.00001 ) )
test_equal("log() #2", 1, close_enough( 2.48491, log(12), 0.00001 ) )
test_equal("log() #3", 1, close_enough( 6.84375, log(938), 0.00001 ) )
test_equal("log() #4", {1,1}, close_enough( {2.48491, 6.84375}, log({12, 938}), 0.00001 ) )

test_equal("log10() #1", 1, close_enough( 3.0, log10(1000.0), 0.00001) )
test_equal("log10() #2", 1, close_enough( 1.91908, log10(83), 0.00001) )
test_equal("log10() #3", {1,1}, close_enough( {3.0, 1.91908}, log10({1000.0, 83}), 0.00001  ) )

test_equal("deg2rad() #1", "0.0174532925", sprintf("%.10f", deg2rad(1)))
test_equal("deg2rad() #2", "3.4906585040", sprintf("%.10f", deg2rad(200)))
test_equal("deg2rad() #3", "0.0174532925,3.3859387489", sprintf("%.10f,%.10f", deg2rad({1,194})))
test_equal("deg2rad() #4", 0.01745, deg2rad(0.9998113525))
test_equal("deg2rad() #5", 0.5, deg2rad(28.6478897565))
test_equal("deg2rad() #6", {HALFPI,{PI,-HALFPI}}, deg2rad({90,{180,-90}}))
test_equal("deg2rad() #7", {}, deg2rad({}))

test_equal("rad2deg() #1", "0.9998113525", sprintf("%.10f", rad2deg(0.01745)))
test_equal("rad2deg() #2", "28.6478897565", sprintf("%.10f", rad2deg(0.5)))
test_equal("rad2deg() #3", "0.9998113525,28.6478897565", sprintf("%.10f,%.10f", rad2deg({0.01745,0.5})))


test_equal("exp() #1", 7.389056, round(exp(2), 1000000))
test_equal("exp() #2", 9.97418, round(exp(2.3), 100000))

function using_gcc()
	-- right now we don't have a good way to check the compiler used
	-- from euphoria code
	return equal(308061521170130,fib(71))
end function

-- Because it doesn't take long to calculate, let's test all valid input args.
if using_gcc() then
	for i = 1 to 69 do
		test_equal(sprintf("fib %d",i), fib(i - 1) + fib(i), fib(i + 1))
	end for
	for i = 71 to 74 do
		test_equal(sprintf("fib %d",i), fib(i - 1) + fib(i), fib(i + 1))
	end for
else
	for i = 1 to 74 do
		test_equal(sprintf("fib %d",i), fib(i - 1) + fib(i), fib(i + 1))
	end for
end if

test_equal("atan2() #1", "1.2837139576", sprintf("%.10f", atan2(10.5, 3.1)))
test_equal("atan2() #2", "-0.0927563202", sprintf("%.10f", atan2(-0.4, 4.3)))
test_equal("atan2() #3", "2.0672190802", sprintf("%.10f", atan2(1.2, -0.65)))
test_equal("atan2() #4", "-2.7697365797", sprintf("%.10f", atan2(-3.12, -8)))
test_equal("atan2() #5", 0, atan2(0,0))

object n
for i = 1 to 10 do
    n = rand_range(1, 5)
    test_true("rand_range(1,5)", n >= 1 and n <= 5)

    n = rand_range(100, 300)
    test_true("rand_range(100,300)", n >= 100 and n <= 300)

    n = rand_range(-100, -10)
    test_true("rand_range(-100,-10)", n >= -100 and n <= -10)
end for

test_equal("remainder() #1", 1, remainder(9, 4) )
test_equal("remainder() #2", 
	{1, -0.1, -1, 1.5}, 
	remainder({81, -3.5, -9, 5.5}, {8, -1.7, 2, -4}) )

test_equal("mod() #1",  3573, mod(-27, 3600))
test_equal("mod() #2",  3573, mod(-3627, 3600))
test_equal("mod() #3",   -27, mod(-3627, -3600))
test_equal("mod() #4", -3573, mod(27, -3600))
test_equal("mod() #5",     0, mod(10, 2))

atom a = 103.14
n = 34.961
atom q = a / n
atom r = mod(a,n)

test_equal ("mod() #6", a , floor(q)*n + r)

test_equal ("mod() #7",  33.218, mod( a, n))
test_equal ("mod() #8",   1.743, mod(-a, n))
test_equal ("mod() #9",   -1.743, mod( a,-n))
test_equal ("mod() #10", -33.218, mod(-a,-n))

test_equal("product:6!", 720, product({1,2,3,4,5,6}))
test_equal("product(1)",   1, product({}))
test_equal("product deep sequence", 100, product({{2,5},{2,5}}))
test_equal("product 1c ", 4,  product(4.0)  )


test_equal("rem() #1", sign(a)  * 33.218, remainder( a, n))
test_equal("rem() #2", sign(-a) * 33.218, remainder(-a, n))
test_equal("rem() #3", sign(a)  * 33.218, remainder( a,-n))
test_equal("rem() #4", sign(-a) * 33.218, remainder(-a,-n))


test_equal("div #1",  sign(a)  * sign(n)  * 2.95014444666915,   a /  n)
test_equal("div #2",  sign(a)  * sign(-n) * 2.95014444666915,   a / -n)
test_equal("div #3",  sign(-a) * sign(n)  * 2.95014444666915,  -a /  n)
test_equal("div #4",  sign(-a) * sign(-n) * 2.95014444666915,  -a / -n)

test_equal("shift_bits left #1",  56, shift_bits(7, -3))
test_equal("shift_bits left #2",   0, shift_bits(0, -9))
test_equal("shift_bits left #3", 512, shift_bits(4, -7))
test_equal("shift_bits left #4", 128, shift_bits(8, -4))
test_equal("shift_bits left #5", 0x213D5600, shift_bits(0xFE427AAC, -7))
test_equal("shift_bits left #6", 0xFFFFFFC8, shift_bits(-7, -3))

test_equal("shift_bits zero #1",  184, shift_bits(184.464, 0))
test_equal("shift_bits zero #2",  0xA4C67FFF , shift_bits(999_999_999_999_999, 0))

test_equal("shift_bits right #1",  23, shift_bits(184, 3))
test_equal("shift_bits right #2",  12, shift_bits(48, 2))
test_equal("shift_bits right #3", 131, shift_bits(131, 0))
test_equal("shift_bits right #4",  15, shift_bits(121, 3))
test_equal("shift_bits right #5", 0x01FC84F5, shift_bits(0xFE427AAC, 7))
test_equal("shift_bits right #6", 0x1FFFFFFF, shift_bits(-7, 3))
test_equal("shift_bits seq", {0x00000000, 0x00000000, 0x00000001, 0x00001E0F, 0x000000CF, 0x0FFFF791},  
							shift_bits({3,5,17,123123,3321,-34535}, 4))

test_equal("rotate bits #1", 0xFFFFFFF0,  rotate_bits(0x7FFFFFF8, -1))
test_equal("rotate bits #2", 0xFFFFFF87,  rotate_bits(0x7FFFFFF8, -4))
test_equal("rotate bits #3", 0xFFFFF87F,  rotate_bits(0x7FFFFFF8, -8))
test_equal("rotate bits #4", 0x3FFFFFFC,  rotate_bits(0x7FFFFFF8, -31))
test_equal("rotate bits #5", 0x7FFFFFF8,  rotate_bits(0x7FFFFFF8, -32))
test_equal("rotate bits #6", 0x3FFFFFFC,  rotate_bits(0x7FFFFFF8, 1))
test_equal("rotate bits #7", 0x87FFFFFF,  rotate_bits(0x7FFFFFF8, 4))
test_equal("rotate bits #8", 0xF87FFFFF,  rotate_bits(0x7FFFFFF8, 8))
test_equal("rotate bits #9", 0xFFFFFFF0,  rotate_bits(0x7FFFFFF8, 31))
test_equal("rotate bits #A", 0x7FFFFFF8,  rotate_bits(0x7FFFFFF8, 32))
test_equal("rotate bits #B", {0x30000000, 0x50000000, 0x10000001, 0x30001E0F, 0x900000CF, 0x9FFFF791}, 
							 rotate_bits({3,5,17,123123,3321,-34535}, 4))

test_equal("sinh", 0.75, sinh(LN2))
test_equal("cosh", 1.25, cosh(LN2))
test_equal("argsh", 1.146215834780588843900393655674, arcsinh(SQRT2))
test_equal("argch", 1.7627471740390860504652186499596, arccosh(3))
test_equal("tanh", 0.46211715726000975850231848364367, tanh(0.5))
test_equal("arctanh", log(3)/2, arctanh(0.5))
test_equal("arccos", 0, arccos(1.0) )
test_equal("arcsin", HALFPI, arcsin(1.0) )
test_equal("trig_range 1c ", {1.104, {1.104}}, round(arccos({.45, {.45}}), 1e4)  )
test_equal("abs_below_1 1c ", {.4847, {.4847}}, round(arctanh({.45, {.45}}), 1e4)  )
test_equal("not_below_1 1c ", {0.9163, {.9163}}, round(arccosh({1.45, {1.45}}), 1e4)  )




test_true("Hex Literal #1", #abcdef = #ABCDEF)
test_true("Hex Literal #2", #012345 = #012345)
test_true("Hex Literal #3", #01_23_45 = #012345)
test_true("Hex Literal #4", #AbC = #aBc)


test_equal("approx #1", 0, approx(10, 33.33 * 30.01 / 100))
test_equal("approx #2", 0, approx(10, 10.001))
test_equal("approx #3", {0,0,1,-1}, approx(10, {10.001,9.999, 9.98, 10.04}))
test_equal("approx #4", {0,0,-1,1}, approx({10.001,9.999, 9.98, 10.04}, 10))
test_equal("approx #5", {-1,{1,1},1,-1}, approx({10.001,{9.999, 10.01}, 9.98, 10.04}, {10.01,9.99, 9.8, 10.4}))
test_equal("approx #6", 0, approx(23,32, 10))

sequence po2 = {}
po2 &= powof2({3, 54.322, -2})
for i = -2 to 17 do
	po2 &= powof2(i)
end for
test_equal("powof2", {0,0,0,0,0,1,1,1,0,1,0,0,0,1,0,0,0,0,0,0,0,1,0}, po2)


test_equal("frac #1", 0.4, frac(9.4))
test_equal("frac #2", -0.4, frac(-9.4))
test_equal("frac #3", {0.1, -0.998, 0}, frac({1.1, -9.998, 88}))

test_equal("trunc #1", 9, trunc(9.4))
test_equal("trunc #2", -9, trunc(-9.4))
test_equal("trunc #3", {1, -9, 88}, trunc({1.1, -9.998, 88}))

test_equal("intdiv #1", 21, intdiv(101, 5))
test_equal("intdiv #2", 19, intdiv(101.5, 5.5))
test_equal("intdiv #3", {1, -2, 13}, intdiv({1.1, -9.998, 88}, 7))
test_equal("intdiv #4", {707, 78, 9}, intdiv(777, {1.1, -9.998, 88}))
test_equal("intdiv #5", {91, 21, -4}, intdiv({100, 200, -300}, {1.1, -9.998, 88}))
test_equal("intdiv #6", 20, intdiv(100, 5))
test_equal("intdiv #7", {43,4,-11}, intdiv({300,28,-73},7))
test_equal("intdiv #8", {{4,8,5},45}, intdiv({24,312},{{6,3,5},7}))

test_equal("ensure_in_range #1", 1, ensure_in_range(1, {}))
test_equal("ensure_in_range #2", 1, ensure_in_range(1, {1}))
test_equal("ensure_in_range #3", 2, ensure_in_range(1, {2,9}))
test_equal("ensure_in_range #4", 9, ensure_in_range(10, {2,9}))
test_equal("ensure_in_range #5", 2, ensure_in_range(2, {2,9}))
test_equal("ensure_in_range #6", 9, ensure_in_range(9, {2,9}))
test_equal("ensure_in_range #7", 5, ensure_in_range(5, {2,9}))

test_equal("ensure_in_list #1", 1, ensure_in_list(1, {}))
test_equal("ensure_in_list #2", 1, ensure_in_list(1, {1}))
test_equal("ensure_in_list #3", 100, ensure_in_list(1, {100, 2, 45, 9, 17, -6}))
test_equal("ensure_in_list #4", 100, ensure_in_list(100, {100, 2, 45, 9, 17, -6}))
test_equal("ensure_in_list #5", -6, ensure_in_list(-6, {100, 2, 45, 9, 17, -6}))
test_equal("ensure_in_list #6", 9, ensure_in_list(9, {100, 2, 45, 9, 17, -6}))

test_equal("not_bits int #1", repeat(1,32), int_to_bits(not_bits(0),32))

test_equal("not_bits dbl #1", repeat(1,32), int_to_bits(not_bits(0.1),32))

test_equal("larger_of #1", 15.4,    larger_of(10, 15.4))
test_equal("larger_of #2", "dog",   larger_of("cat", "dog"))
test_equal("larger_of #3", "cat",   larger_of("cat", 6))
test_equal("larger_of #4", "apple", larger_of("apple", "apes"))
test_equal("larger_of #5", 10,      larger_of(10, 10))

test_equal("smaller_of #1", 10,     smaller_of(10, 15.4))
test_equal("smaller_of #2", "cat",  smaller_of("cat", "dog"))
test_equal("smaller_of #3", 6,      smaller_of("cat", 6))
test_equal("smaller_of #4", "apes", smaller_of("apple", "apes"))
test_equal("smaller_of #5", 10,     smaller_of(10, 10))

test_report()
