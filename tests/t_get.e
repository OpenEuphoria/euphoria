include get.e
include unittest.e

setTestModuleName("get.e")

-- TODO: Many more functions to test

testEqual("value() no data supplied", {GET_EOF, 0}, value(""))
testEqual("value() integer", {GET_SUCCESS, 10}, value("10"))
testEqual("value() bad integer", {GET_FAIL, 0}, value("John"))
testEqual("value() float", {GET_SUCCESS, 10.5}, value("10.5"))
testEqual("value() sequence", {GET_SUCCESS, {1,2}}, value("{1,2}"))
testEqual("value_from() integer", {GET_SUCCESS, 10, 2, 0}, value_from("Data: 10", 7))
testEqual("value_from() integer with leading whitespace",
    {GET_SUCCESS, 10, 3, 1}, value_from("Data: 10", 6))

