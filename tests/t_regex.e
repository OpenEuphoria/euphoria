include std/regex.e as regex
include std/text.e
include std/unittest.e

object ignore = 0
regex:regex re
re = regex:new("[A-Z][a-z]+")
test_true("new()", regex:ok(re))
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
test_equal("find_all() #1", {{5,7}, {13,14}},
	regex:find_all(re, "the DOG ran UP" ))
regex:free(re)

re = regex:new("^")
test_equal("find_all ^", {{1,0}}, regex:find_all(re, "hello world"))
regex:free(re)

re = regex:new("<")
test_equal("find_all <", {{1,0},{7,6}}, regex:find_all(re, "hello world"))
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

test_false("regex mismatch groups 1", regex:ok("(x}"))
test_false("regex mismatch groups 2", regex:ok("{x)"))

re = regex:new("{x}")
test_true("regex matched groups 1", regex:ok(re))
regex:free(re)

re = regex:new("(x)")
test_true("regex matched groups 2", regex:ok(re))
regex:free(re)

re = regex:new("{x?}#y")
test_false("regex runaway", regex:find(re, ""))
regex:free(re)

re = regex:new("{x?}#y")
test_equal("regex fixed runaway", {{1,3}}, regex:find(re, "xxy"))
regex:free(re)

re = regex:new("^")
test_equal("regex bol on empty string", {{1,0}}, regex:find(re, ""))
regex:free(re)

re = regex:new("$")
test_equal("regex eol on empty string", {{1,0}}, regex:find(re, ""))
regex:free(re)

re = regex:new({123,251,129,105,117,184,89,215,105,124})
ignore = regex:has_match(re, {251,129,105,117,184,89,215,105,124})
test_pass("regex new/match combo that produced a seg fault 1")
regex:free(re)

-- Runs away only to give a seg fault due to stack problems.
re = regex:new("{x?}+y")
ignore = regex:find(re, "xxy")
test_pass("regex new/match combo that produced a seg fault 1")
regex:free(re)

test_report()
