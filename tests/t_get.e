include get.e
include unittest.e

-- TODO: Many more functions to test

test_equal("value() no data supplied", {GET_EOF, 0}, value(""))
test_equal("value() integer", {GET_SUCCESS, 10}, value("10"))
test_equal("value() bad integer", {GET_FAIL, 0}, value("John"))
test_equal("value() float", {GET_SUCCESS, 10.5}, value("10.5"))
test_equal("value() sequence", {GET_SUCCESS, {1,2}}, value("{1,2}"))
test_equal("value_from() integer", {GET_SUCCESS, 10, 2, 0}, value("Data: 10", 7,GET_LONG_ANSWER))
test_equal("value_from() integer with leading whitespace",
    {GET_SUCCESS, 10, 3, 1}, value("Data: 10", 6,GET_LONG_ANSWER))

test_report()

