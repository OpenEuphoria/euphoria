include math.e
include unittest.e

setTestModuleName("math.e")

testEqual("ceil() integer", 5, ceil(5))
testEqual("ceil() float #1", 4, ceil(4.0))
testEqual("ceil() float #2", 5, ceil(4.1))
testEqual("ceil() float #3", 5, ceil(4.5))
testEqual("ceil() float #4", 5, ceil(4.6))
testEqual("ceil() sequence", {1,2,3,4,5}, ceil({0.6, 1.2, 3.0, 3.8, 4.4}))
testEqual("ceil() large integer", 2192837283, ceil(2192837283))

testEqual("round_prec() float #1", 5.5, round_prec(5.49854, 10))
testEqual("round_prec() float #2", 5.50, round_prec(5.49854, 100))
testEqual("round_prec() float #3", 5.498, round_prec(5.49843, 1000))
testEqual("round_prec() float #4", 5.4984, round_prec(5.49843, 10000))
testEqual("round_prec() sequence #1", {5.5, 4.3}, round_prec({5.48, 4.25}, 10))
testEqual("round_prec() sequence #2", {5.48, 4.26}, round_prec({5.482, 4.256}, 100))

testEqual("round() float #1", 5, round(4.6))
testEqual("round() float #2", 5, round(4.5))
testEqual("round() float #3", 4, round(4.4))
testEqual("round() sequence", {1,2,3,4}, round({0.5, 2.1, 2.9, 3.6}))

testEqual("sign() integer #1", 1, sign(10))
testEqual("sign() integer #2", -1, sign(-10))
testEqual("sign() integer #3", 0, sign(0))
testEqual("sign() float #1", 1, sign(10.5))
testEqual("sign() float #2", -1, sign(-10.5))
testEqual("sign() float #3", 0, sign(0.0))
testEqual("sign() sequence", {1, 0, -1}, sign({10, 0, -10.3}))

testEqual("abs() integer #1", 10, abs(10))
testEqual("abs() integer #2", 10, abs(-10))
testEqual("abs() integer #3", 0, abs(0))
testEqual("abs() float #1", 10.5, abs(10.5))
testEqual("abs() float #2", 10.5, abs(-10.5))
testEqual("abs() float #3", 0.0, abs(0.0))
testEqual("abs() sequence", {0, 10.5, 11, 12}, abs({0, -10.5, 11, -12}))

testEqual("sum() integer", 10, sum(10))
testEqual("sum() sequence", 10, sum({1, 2, 2, 4, 1}))

testEqual("average() integer", 10, average(10))
testEqual("average() sequence", 11.125, average({8.5, 7.25, 10, 18.75}))

testEqual("min() integer", 5, min(5))
testEqual("min() sequence", 3, min({5,8,3,100,32}))

testEqual("max() integer", 5, max(5))
testEqual("max() integer", 109, max({5,4,3,109,108,35}))
