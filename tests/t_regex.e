include regex.e as regex
include unittest.e

set_test_module_name("regex.e")

regex:regex re
re = regex:new("[A-Z][a-z]+")
test_true("new()", re > 0)
test_equal("search() #1", {{5,8}}, regex:search(re, "and John ran", regex:DEFAULT))

re = regex:new("([a-z]+) ([A-z]+) ([a-z]+)")
test_equal("search() #2", {{1,12}, {1,3}, {5,8}, {10,12}}, regex:search(re, "and John ran", regex:DEFAULT))

re = regex:new("[a-z]+")
test_equal("search_from() #1", {{1,3}}, regex:search_from(re, "the dog is happy", regex:DEFAULT, 1))
test_equal("search_from() #2", {{5,7}}, regex:search_from(re, "the dog is happy", regex:DEFAULT, 4))
test_equal("search_from() #3", {{9,10}}, regex:search_from(re, "the dog is happy", regex:DEFAULT, 8))

re = regex:new("[A-Z]+")
test_equal("search_all() #1", {{{5,7}}, {{13,14}}}, regex:search_all(re, "the DOG ran UP", regex:DEFAULT))

