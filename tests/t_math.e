include std/machine.e
include std/math.e
include std/unittest.e

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

test_equal("rad2deg() #1", "0.9998113525", sprintf("%.10f", rad2deg(0.01745)))
test_equal("rad2deg() #2", "28.6478897565", sprintf("%.10f", rad2deg(0.5)))
test_equal("rad2deg() #3", "0.9998113525,28.6478897565", sprintf("%.10f,%.10f", rad2deg({0.01745,0.5})))

test_equal("exp() #1", 7.389056, round(exp(2), 1000000))
test_equal("exp() #2", 9.97418, round(exp(2.3), 100000))

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

test_equal("mod() #1",  3573, mod(-27, 3600))
test_equal("mod() #2",  3573, mod(-3627, 3600))
test_equal("mod() #3",   -27, mod(-3627, -3600))
test_equal("mod() #4", -3573, mod(27, -3600))
test_equal("mod() #5",     0, mod(10, 2))

test_equal("left_shift() #1",  56, left_shift(7, 3))
test_equal("left_shift() #2",   0, left_shift(0, 9))
test_equal("left_shift() #3", 512, left_shift(4, 7))
test_equal("left_shift() #4", 128, left_shift(8, 4))

test_equal("right_shift() #1",  23, right_shift(184, 3))
test_equal("right_shift() #2",  12, right_shift(48, 2))
test_equal("right_shift() #3", 131, right_shift(131, 0))
test_equal("right_shift() #4",  15, right_shift(121, 3))

test_equal("sh", 0.75, sinh(LN2))
test_equal("ch", 1.25, cosh(LN2))
test_equal("argsh", 1.146215834780588843900393655674, arcsinh(SQRT2))
test_equal("argch", 1.7627471740390860504652186499596, arccosh(3))
test_equal("th", 0.46211715726000975850231848364367, tanh(0.5))
test_equal("argth", log(3)/2, arctanh(0.5))

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

test_report()

