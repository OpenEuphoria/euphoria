include regex.e as regex
include text.e
include unittest.e

regex:regex re
re = regex:new("[A-Z][a-z]+")
test_true("new()", re > 0)
test_equal("search() #1", {{5,8}}, regex:search(re, "and John ran" ))

re = regex:new("([a-z]+) ([A-z]+) ([a-z]+)")
test_equal("search() #2", {{1,12}, {1,3}, {5,8}, {10,12}}, regex:search(re, "and John ran"))

re = regex:new("[a-z]+")
test_equal("search() #3", {{1,3}}, regex:search(re, "the dog is happy", 1))
test_equal("search() #4", {{5,7}}, regex:search(re, "the dog is happy", 4))
test_equal("search() #5", {{9,10}}, regex:search(re, "the dog is happy", 8))

re = regex:new("[A-Z]+")
test_equal("search_all() #1", {{{5,7}}, {{13,14}}}, 
    regex:search_all(re, "the DOG ran UP" ))

test_equal("search_replace() #1", "the ABC ran ABC", 
    regex:search_replace(re, "the DOG ran UP", "ABC", regex:DEFAULT ))

function repl(sequence data)
    return lower(data[1])
end function

test_equal("search_replace_user() #1", "the dog ran up",
    regex:search_replace_user(re, "the DOG ran UP", routine_id("repl"), regex:DEFAULT))

re = regex:new("[A-Z]+")
test_equal("full_match() #1", 1, regex:full_match(re, "JOHN"))
test_equal("full_match() #2", 0, regex:full_match(re, "john is 18 years old"))

regex:free( re )

test_report()

