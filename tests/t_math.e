include math.e
include unittest.e

set_test_module_name("math.e")

test_equal("ceil() integer", 5, ceil(5))
test_equal("ceil() float #1", 4, ceil(4.0))
test_equal("ceil() float #2", 5, ceil(4.1))
test_equal("ceil() float #3", 5, ceil(4.5))
test_equal("ceil() float #4", 5, ceil(4.6))
test_equal("ceil() sequence", {1,2,3,4,5}, ceil({0.6, 1.2, 3.0, 3.8, 4.4}))
test_equal("ceil() large integer", 2192837283, ceil(2192837283))

test_equal("round_prec() float #1", 5.5, round_prec(5.49854, 10))
test_equal("round_prec() float #2", 5.50, round_prec(5.49854, 100))
test_equal("round_prec() float #3", 5.498, round_prec(5.49843, 1000))
test_equal("round_prec() float #4", 5.4984, round_prec(5.49843, 10000))
test_equal("round_prec() sequence #1", {5.5, 4.3}, round_prec({5.48, 4.25}, 10))
test_equal("round_prec() sequence #2", {5.48, 4.26}, round_prec({5.482, 4.256}, 100))

test_equal("round() float #1", 5, round(4.6))
test_equal("round() float #2", 5, round(4.5))
test_equal("round() float #3", 4, round(4.4))
test_equal("round() sequence", {1,2,3,4}, round({0.5, 2.1, 2.9, 3.6}))

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

test_equal("average() integer", 10, average(10))
test_equal("average() sequence", 11.125, average({8.5, 7.25, 10, 18.75}))

test_equal("min() integer", 5, min(5))
test_equal("min() sequence", 3, min({5,8,3,100,32}))

test_equal("max() integer", 5, max(5))
test_equal("max() integer", 109, max({5,4,3,109,108,35}))

test_equal("log() #1", 2.30259, round_prec(log(10), 100000))
test_equal("log() #2", 2.48491, round_prec(log(12), 100000))
test_equal("log() #3", 6.84375, round_prec(log(938), 100000))
test_equal("log() #4", {2.48491, 6.84375}, round_prec(log({12, 938}), 100000))

test_equal("log10() #1", 3.0, round_prec(log10(1000.0), 100000))
test_equal("log10() #2", 1.91908, round_prec(log10(83), 100000))
test_equal("log10() #3", {3.0, 1.91908}, round_prec(log10({1000.0, 83}), 100000))

test_equal("deg2rad() #1", 0.01745329251994329547437168059786927187815308570862, deg2rad(1))
test_equal("deg2rad() #2", 3.490658503988659067118760503944940865039825439453125, deg2rad(200))
test_equal("deg2rad() #3", {0.01745329251994329547437168059786927187815308570862,
                            3.38593874886899914855575843830592930316925048828125}, deg2rad({1,194}))

test_equal("rad2deg() #1", 0.999811352503286787651859413017518818378448486328125, rad2deg(0.01745))
test_equal("rad2deg() #2", 28.647889756541161432323860935866832733154296875, rad2deg(0.5))
test_equal("rad2deg() #3", {0.999811352503286787651859413017518818378448486328125,
                            28.647889756541161432323860935866832733154296875}, rad2deg({0.01745,0.5}))

test_equal("exp() #1", 7.389056, round_prec(exp(2), 1000000))
test_equal("exp() #2", 9.97418, round_prec(exp(2.3), 100000))
