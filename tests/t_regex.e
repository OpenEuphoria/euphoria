include std/regex.e as regex
include std/text.e
include std/unittest.e

regex:regex re = regex:new("[A-Z][a-z]+")
test_true("new()", re > 0)
test_equal("exec() #1", {{5,8}}, regex:find(re, "and John ran"))
regex:free(re)

re = regex:new("([a-z]+) ([A-Z][a-z]+) ([a-z]+)")
test_equal("find() #2", {{1,12}, {1,3}, {5,8}, {10,12}}, regex:find(re, "and John ran"))
regex:free(re)

re = regex:new("[a-z]+")
test_equal("find() #3", {{1,3}}, regex:find(re, "the dog is happy", 1))
test_equal("find() #4", {{5,7}}, regex:find(re, "the dog is happy", 4))
test_equal("find() #5", {{9,10}}, regex:find(re, "the dog is happy", 8))
regex:free(re)

re = regex:new("[A-Z]+")
test_equal("find_all() #1", {{{5,7}}, {{13,14}}},
	regex:find_all(re, "the DOG ran UP" ))
regex:free(re)

re = regex:new("([A-Za-z0-9]+)\\.([A-Za-z0-9]+)")
test_equal("replace() #1", "Filename: filename Extension: txt",
	regex:replace(re, "filename.txt", "Filename: \\1 Extension: \\2"))
regex:free(re)

re = regex:new("[A-Z]+")
test_true("is_match() #1", regex:is_match(re, "JOHN"))
test_false("is_match() #2", regex:is_match(re, "john"))
test_true("has_match() #1", regex:has_match(re, "john DOE had a DOG"))
test_false("has_match() #2", regex:has_match(re, "john doe had a dog"))
regex:free(re)

test_report()
