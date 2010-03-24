include std/regex.e as regex
include std/regex.e as re
include std/text.e
include std/sequence.e
include std/unittest.e

object ignore = 0

object re 
	
re = regex:new("Second|Third")
test_equal("Matches normally can occur inside a string",{
	{length("First, you break the eggs.  S"),length("First, you break the eggs.  Second")}
	}, 
	regex:find(re,"First, you break the eggs.  Second, you stir the egg.  "&
	"Third, you turn on the frying pan",, regex:DEFAULT )
	)
test_equal("With regex:ANCHORED, it must match from the first place it tries", -1, 
	regex:find(re,"First, you break the eggs.  Second, you stir the egg.  "&
	"Third, you turn on the frying pan",, regex:ANCHORED )
	)

re = regex:new("[comunicate]+", regex:CASELESS)
test_true("Caseless makes matches case insensitive", is_match(re,"Communicate"))

re = regex:new("rain\\?\n$")
test_equal("When regex:DOLLAR_ENDONLY is set, $ comes after the \\n character",
	{
   }
, regex:find_all(re,"Have you ever seen the rain?\n",,regex:DOLLAR_ENDONLY) )

re = regex:new("rain\\?$")
test_equal("By default, the $ matches the place just before the newline character.",
		{
		 {24,28} -- five characters not including the \n
		}
, regex:find(re,"Have you ever seen the rain?\n") )
re = regex:new("rain\\?.$", {regex:DOLLAR_ENDONLY,regex:DOTALL})
test_equal("When regex:DOLLAR_ENDONLY is set, matches only occur at the end of the string",
		{
		 {24,29} -- six characters including the \n
		}
, regex:find(re,"Have you ever seen the rain?\n") )
re = regex:new("rain\\?$", {regex:DOLLAR_ENDONLY})
test_equal("When regex:DOLLAR_ENDONLY is set, matches only occur at the end of the string",
-1, regex:find(re,"Have you ever seen the rain?\n") )

re = regex:new("(?:where\\?|string)$", regex:MULTILINE)
sequence s =  `Here is a multiline subject string
We should get several matches can you guess where?`
test_equal("Matches occur both at the regex:EOL and at the end of the string",
	{
			{
			 {29,34}
			},
			{
			 {80,85}
			}
	},
	regex:find_all(re,s)
)

-- See www.regextester.com/pregsyntax.html
-- and
-- http://www.ambienteto.arti.beniculturali.it/cgi-bin/man2html?pcre+3
test_equal("regex:DOLLAR_ENDONLY is ignored when regex:MULTILINE is set",
regex:find_all(re,s), regex:find_all(re,s,,regex:DOLLAR_ENDONLY) )

test_equal("When regex:NOTEOL is set, matches do not occur at end of the string.", 
	{
		{
		 {29,34}
		}
   }
, regex:find_all(re,s,,regex:NOTEOL) )

re = regex:new("We should", regex:FIRSTLINE)
test_equal("Matches will not occur after the first line when regex:FIRSTLINE is set", 
	-1, regex:find(re,s) )

test_equal("Normally, dot doesn\'t match a regex:NEWLINE", -1, regex:find(regex:new("g.We", regex:DEFAULT),s) )
test_equal("regex:DOT does match a newline when regex:DOTALL is set", {{34,37}}, 
	regex:find(regex:new("g.We", regex:DOTALL),s) )

re = regex:new("((?regex:P<gender>Male|Female)|(?regex:P<gender>Boy|Girl))", regex:DUPNAMES)
test_true("DUPNAMES subpatterns", regex:regex(re))
	
-- flags to test regex:EXTENDED to regex:NOTEMPTY	
	
re = regex:new("What in the world")
test_false("find with regex:PARTIAL doesn\'t match regex:PARTIAL strings", 
	sequence(regex:find(re, "What a ride!",,regex:PARTIAL)))
test_equal("find with regex:PARTIAL matches strings", {{1, length("What in the world")}},
	regex:find(re, "What in the world is going on?",,regex:PARTIAL))

-- flags to test UNGREEDY to UTF8

re = regex:new("[e][x]press.?*")
test_equal("new() on bad expression", 0, re)
test_true("error_message() on bad expression", sequence(regex:error_message(re)))

re = regex:new("[A-Z][a-z]+")
test_true("new() on good expression", regex(re))
test_false("error_message() on good expression", regex:error_message(re))
test_equal("exec() #1", {{5,8}}, regex:find(re, "and John ran"))

re = regex:new("([a-z]+) ([A-Z][a-z]+) ([a-z]+)")
test_equal("find() #2", {{1,12}, {1,3}, {5,8}, {10,12}}, regex:find(re, "and John ran"))

re = regex:new("[a-z]+")
test_equal("find() #3", {{1,3}}, regex:find(re, "the dog is happy", 1))
test_equal("find() #4", {{5,7}}, regex:find(re, "the dog is happy", 4))
test_equal("find() #5", {{9,10}}, regex:find(re, "the dog is happy", 8))

re = regex:new(`[A-Z][a-z]+\s`, { regex:CASELESS })
test_equal("find() #6", {{1,4}}, regex:find(re, "and John ran"))
test_equal("find() #7", -1, regex:find(re, "15 dogs ran", regex:ANCHORED))

re = regex:new(`[A-Z][a-z]+\s`, { regex:CASELESS, regex:ANCHORED })
test_equal("find() #8", {{1,4}}, regex:find(re, "and John ran"))
test_equal("find() #9", -1, regex:find(re, "15 dogs ran"))

re = regex:new("[A-Z]+")
test_equal("find_all() #1", {{{5,7}}, {{13,14}}},
	regex:find_all(re, "the DOG ran UP" ))

re = regex:new("^")
test_equal("find_all ^", {{{1,0}}}, regex:find_all(re, "hello world"))

re = regex:new("\\b")
test_equal("find_all \\b", {{{1,0}},{{6,5}},{{7,6}},{{12,11}}}, regex:find_all(re, "hello world"))

re = regex:new("[A-Z]+")
test_true("is_match() #1", regex:is_match(re, "JOHN"))
test_false("is_match() #2", regex:is_match(re, "john"))
test_true("has_match() #1", regex:has_match(re, "john DOE had a DOG"))
test_false("has_match() #2", regex:has_match(re, "john doe had a dog"))

re = regex:new("([A-Z][a-z]+) ([A-Z][a-z]+)")
test_equal("matches() #1", { "John Doe", "John", "Doe" }, regex:matches(re, "John Doe Jane Doe"))
test_equal("matches() STRING_OFFSET #1",
	{ { "John Doe", 1, 8 }, { "John", 1, 4 }, { "Doe", 6, 8 } },
	regex:matches(re, "John Doe and Jane Doe", 1, regex:STRING_OFFSETS))
test_equal("matches() no match #1", ERROR_NOMATCH, regex:matches(re, "12"))

test_equal("all_matches() #1", { { "John Doe", "John", "Doe" }, { "Jane Doe", "Jane", "Doe" } },
	regex:all_matches(re, "John Doe Jane Doe"))
test_equal("all_matches() STRING_OFFSET #1",
	{
		{                           -- first match
			{ "John Doe",  1,  8 }, -- full match data
			{ "John",      1,  4 }, -- first group
			{ "Doe",       6,  8 }  -- second group
		},
		{                           -- second match
			{ "Jane Doe", 14, 21 }, -- full match data
			{ "Jane",     14, 17 }, -- first group
			{ "Doe",      19, 21 }  -- second group
		}
	},
	regex:all_matches(re, "John Doe and Jane Doe", 1, regex:STRING_OFFSETS))
test_equal("all_matches() no match #1", ERROR_NOMATCH, regex:all_matches(re, "12"))

re = regex:new(`,\s`)
test_equal("split() #1", { "euphoria programming", "source code", "reference manual" },
	regex:split(re, "euphoria programming, source code, reference manual"))

test_equal("split_limit() #1", { "euphoria programming", "source code, reference manual" },
	regex:split_limit(re, "euphoria programming, source code, reference manual", 1))

re = regex:new("(x)")
test_true("regex matched groups 1", regex(re))

re = regex:new("^")
test_equal("regex bol on empty string", {{1,0}}, regex:find(re, ""))
test_equal("regex bol on empty string with NOTBOL flag", -1, regex:find(re, "", ,regex:NOTBOL))

re = regex:new("$")
test_equal("regex eol on empty string", {{1,0}}, regex:find(re, ""))
test_equal("regex eol on empty string with NOTEOL flag", -1, regex:find(re, "", ,regex:NOTEOL))
test_equal("regex eol on empty string with NOTEMPTY flag", -1, regex:find(re, "",, regex:NOTEMPTY))

re = regex:new("([A-Z][a-z]+) ([A-Z][a-z]+)")
test_equal("find_replace() #1", "hello Doe, John!", regex:find_replace(re, "hello John Doe!", `\2, \1`))
test_equal("find_replace() #2", "hello DOE, john!", regex:find_replace(re, "hello John Doe!", `\U\2\e, \L\1\e`))
test_equal("find_replace() #3", "hello \nDoe, John!", regex:find_replace(re, "hello John Doe!", `\n\2, \1`))
test_equal("find_replace() #4", "hello John\tDoe!", regex:find_replace(re, "hello John Doe!", `\1\t\2`))
test_equal("find_replace() #5", "hello Mr. John Doe!", regex:find_replace(re, "hello John Doe!", `Mr. \1 \2`))

test_equal("find_replace_limit() #1", "JOHN DOE Jane Doe", 
	regex:find_replace_limit(re, "John Doe Jane Doe", `\U\1 \2\e`, 1))

function myupper(sequence params)
	return upper(params[1])
end function

test_equal("find_replace_callback() #1", "JOHN DOE JANE DOE",
	regex:find_replace_callback(re, "John Doe Jane Doe", routine_id("myupper")))
test_equal("find_replace_callback() #2", "JOHN DOE Jane Doe",
	regex:find_replace_callback(re, "John Doe Jane Doe", routine_id("myupper"), 1))
test_equal("find_replace_callback() #3", "John Doe JANE DOE",
	regex:find_replace_callback(re, "John Doe Jane Doe", routine_id("myupper"), 0, 9))

test_equal("escape #1", "Payroll is \\$\\*\\*\\*15\\.00", regex:escape("Payroll is $***15.00"))

test_report()
