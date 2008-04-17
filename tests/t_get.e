include get.e
include unittest.e

setTestModuleName("get.e")

-- TODO: Many more functions to test

testEqual("value() No data supplied", {GET_EOF, 0}, value(""))
testEqual("value() Integer", {GET_SUCCESS, 10}, value("10"))
testEqual("value() Bad integer", {GET_FAIL, 0}, value("John"))
testEqual("value() Float", {GET_SUCCESS, 10.5}, value("10.5"))
testEqual("value() Sequence", {GET_SUCCESS, {1,2}}, value("{1,2}"))
testEqual("value_from() Integer", {GET_SUCCESS, 10, 2, 0}, value_from("Data: 10", 7))
testEqual("value_from() Integer with leading whitespace",
    {GET_SUCCESS, 10, 3, 1}, value_from("Data: 10", 6))

