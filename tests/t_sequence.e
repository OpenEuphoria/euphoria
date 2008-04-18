include sequence.e
include unittest.e

setTestModuleName("sequence.e")

testEqual("findany_from() string", 7, findany_from("aeiou", "John Doe", 3))
testEqual("findany_from() integers", 6, findany_from({1,3,5,8}, {2,4,5,6,7,8,9}, 4))
testEqual("findany_from() floats", 6,
        findany_from({1.3,3.5,5.6,8.3}, {2.1,4.2,5.3,6.4,7.5,8.3,9.1}, 4))

testEqual("findany() string", 2, findany("aeiou", "John Doe"))
testEqual("findany() integers", 3, findany({1,3,5,7,9}, {2,4,5,6,7,8,9}))
testEqual("findany() floats", 3, findany({1.1,3.2,5.3,7.4,9.5}, {2.1,4.2,5.3,6.4,7.5,8.6,9.7}))

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

testEqual("split() simple string", {"a","b","c"}, split("a,b,c", ','))
testEqual("split() sequence", {{1},{2},{3},{4}}, split({1,0,2,0,3,0,4}, 0))
testEqual("split() nested sequence", {{"John"}, {"Doe"}}, split({"John", 0, "Doe"}, 0))
testEqual("split_adv() limit set", {"a", "b,c"}, split_adv("a,b,c", ',', 2, 0))
testEqual("split_adv() any character", {"a", "b", "c"}, split_adv("a,b.c", ",.", 0, 1))
testEqual("split_adv() limit and any character", {"a", "b", "c|d"},
    split_adv("a,b.c|d", ",.|", 3, 1))

testEqual("join() simple string", "a,b,c", join({"a", "b", "c"}, ","))
testEqual("join() nested sequence", {"John", 0, "Doe"}, join({{"John"}, {"Doe"}}, 0))
