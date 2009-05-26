include std/unittest.e
include std/regex.e as re

-- benchmarking example from mastering regular expressions
-- convert python/perl/ruby example to euphoria4

regex Regex1 = re:new("^(a|b|c|d|e|f|g)+$")
regex Regex2 = re:new("^[a-g]+$")

integer TimesToDo = 1250
sequence TestString = ""

for i = 1 to 800 do
	TestString &= "abababdedfg"
end for

for i = 1 to TimesToDo do
	-- crashes here every time, with any function
	re:matches(Regex1, TestString)
end for

for i = 1 to TimesToDo do
	re:matches(Regex2, TestString)
end for

test_pass("regex alternation benchmark, bug #2794240")

test_report()
