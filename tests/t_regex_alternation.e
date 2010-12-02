include std/unittest.e
include std/regex.e as re

regex Regex1 = re:new("^(a|b|c|d|e|f|g)+$")
sequence TestString = ""

-- Passes if for loop is 1 to 22 but begins to fail if loop is > 23
-- on Jeremy's machine
for i = 1 to 200 do 
	TestString &= "abababdedfg"
end for

re:matches(Regex1, TestString)

test_pass("regex alternation benchmark, bug #2794240")

test_report()
