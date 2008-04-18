include sequence.e
include unittest.e

setTestModuleName("sequence.e")

testEqual("left() string", "John", left("John Doe", 4))
testEqual("left() sequence", {1,2,3}, left({1,2,3,4,5,6}, 3))
testEqual("left() nested sequence", {{1,2}, {3,4}}, left({{1,2},{3,4},{5,6}}, 2))
testEqual("left() bounds", "Name", left("Name", 50))

testEqual("mid() string", "Middle", mid("John Middle Doe", 6, 6))
testEqual("mid() sequence", {2,3,4}, mid({1,2,3,4,5,6}, 2, 3))
testEqual("mid() nested sequence", {{3,4},{5,6}}, mid({{1,2},{3,4},{5,6},{7,8}}, 2, 2))
testEqual("mid() bounds", {2,3}, mid({1,2,3}, 2, 50))

testEqual("slice() string", "Middle", slice("John Middle Doe", 6, 11))
testEqual("slice() string, zero end", "Middle Doe", slice("John Middle Doe", 6, 0))
testEqual("slice() string, neg end", "Middle", slice("John Middle Doe", 6, -4))
testEqual("slice() sequence", {2,3}, slice({1,2,3,4}, 2, 3))
testEqual("slice() nested sequence", {{3,4},{5,6}}, slice({{1,2},{3,4},{5,6},{7,8}}, 2, 3))
testEqual("slice() bounds", "Middle Doe", slice("John Middle Doe", 6, 50))

testEqual("right() string", "Doe", right("John Middle Doe", 3))
testEqual("right() sequence", {3,4}, right({1,2,3,4}, 2))
testEqual("right() nested sequence", {{3,4},{5,6}}, right({{1,2},{3,4},{5,6}}, 2))
testEqual("right() bounds", {1,2,3,4}, right({1,2,3,4}, 50))
