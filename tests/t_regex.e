include std/regex.e as regex
include std/regex.e as re
include std/text.e
include std/sequence.e
include std/unittest.e

object ignore = 0

object re

-- how do we do named duplicated subpatterns?
re = regex:new(`(?P<year>\d{2,4})\s*# This is the year of the extended pattern
				(?P<month>Jan|Feb|Mar|Nov)\s*#This is the month
			    \2\s*#This is the repeated month
				(?P<day>\d{1,2})# This is the day`, {regex:EXTENDED,regex:EXTRA})
test_true("Created EXTENDED EXTRA regex", regex:regex(re))
if not regex:regex(re) then
	printf(1,"%s\n", {regex:error_message(re)})
end if

test_true("Test with duplicated subpatterns in extended expression",
	sequence(regex:find(re, "1955 Nov Nov 5")))



re = regex:new("Second|Third")
test_equal("Matches normally can occur inside a string",{
	{length("First, you break the eggs.  S"),length("First, you break the eggs.  Second")}
	},
	regex:find(re,"First, you break the eggs.  Second, you stir the egg.  "&
	"Third, you turn on the frying pan",, regex:DEFAULT )
	)
test_equal("With regex:ANCHORED, it must match from the first place it tries", regex:ERROR_NOMATCH,
	regex:find(re,"First, you break the eggs.  Second, you stir the egg.  "&
	"Third, you turn on the frying pan",, regex:ANCHORED )
	)

re = regex:new("[comunicate]+", regex:CASELESS)
test_true("Caseless makes matches case insensitive", is_match(re,"Communicate"))

re = regex:new("(?i)[communicate]+")
test_true("Caseless via (?i) matches case insensitive", is_match(re, "Communicate"))

re = regex:new("rain\\?\n$")
test_equal("When regex:DOLLAR_ENDONLY is set, $ comes after the \\n character",
	{},
	regex:find_all(re,"Have you ever seen the rain?\n",,regex:DOLLAR_ENDONLY) )

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
		},
		regex:find(re,"Have you ever seen the rain?\n") )

re = regex:new("rain\\?$", {regex:DOLLAR_ENDONLY})
test_equal("When regex:DOLLAR_ENDONLY is set, matches only occur at the end of the string",
	regex:ERROR_NOMATCH, regex:find(re,"Have you ever seen the rain?\n") )

re = regex:new(`(?:where\?|string)$`, regex:MULTILINE)

sequence s =  `Here is a multiline subject string
We should get several matches can you guess where?`

test_equal("Matches occur both at the EOL and at the end of the string",
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
regex deo = regex:new( `(?:where\?|string)$`, or_bits( regex:DOLLAR_ENDONLY, regex:MULTILINE ) )
test_equal("regex:DOLLAR_ENDONLY is ignored when regex:MULTILINE is set",
	regex:find_all(re,s), regex:find_all(deo,s) )

test_equal("When regex:NOTEOL is set, matches do not occur at end of the string.",
	{
		{
		 {29,34}
		}
   }
	, regex:find_all(re,s,,regex:NOTEOL) )

re = regex:new("We should", regex:FIRSTLINE)
test_equal("Matches will not occur after the first line when regex:FIRSTLINE is set",
	regex:ERROR_NOMATCH, regex:find(re,s) )

test_equal("Normally, dot doesn\'t match a regex:NEWLINE", regex:ERROR_NOMATCH, regex:find(regex:new("g.We", regex:DEFAULT),s) )
test_equal("regex:Dot does match a newline when regex:DOTALL is set", {{34,37}},
	regex:find(regex:new("g.We", regex:DOTALL),s) )

re = regex:new("((?<gender>Male|Female)|(?<gender>Boy|Girl))", regex:DUPNAMES)
test_true("DUPNAMES subpatterns", regex:regex(re))

test_true("Test the use of backslashes infront of nonspecial letters",
	regex:regex(regex:new(`\h\i`)) )

test_false("Test the use of backslashes infront of nonspecial letters with regex:EXTRA",
	regex:regex(regex:new(`\h\i`, regex:EXTRA) ) )

-- flags with newlines to be tested.

re = regex:new("(white|red|blue) (?P<animal>fox|bear|tiger)", NO_AUTO_CAPTURE)

test_equal("Automatic subpattern capture can be disabled.",
    { {1,8}, {5,8} }, regex:find(re, "red bear") )

re = regex:new("What in the world")
test_equal("find with regex:PARTIAL doesn\'t match unmatching strings",
	ERROR_NOMATCH, regex:find(re, "What a ride!",,regex:PARTIAL))
test_equal(
	"find with regex:PARTIAL returns ERROR_PARTIAL (only) when string matches " &
	"the beginning of the pattern.",
	ERROR_PARTIAL,
	regex:find(re, "What i",,{regex:PARTIAL})
	)
test_equal("find with regex:PARTIAL returns ERROR_NOMATCH "&
	"when the string matches the end of the patttern " &
	"rather than the beginning.",
	ERROR_NOMATCH,
	regex:find(re, "the world",,regex:PARTIAL)
	)
test_equal("find with regex:PARTIAL matches strings that match the complete pattern.",
	{{1, length("What in the world")}},
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
test_equal("find() #7", regex:ERROR_NOMATCH, regex:find(re, "15 dogs ran", regex:ANCHORED))

re = regex:new(`[A-Z][a-z]+\s`, { regex:CASELESS, regex:ANCHORED })
test_equal("find() #8", {{1,4}}, regex:find(re, "and John ran"))
test_equal("find() #9", regex:ERROR_NOMATCH, regex:find(re, "15 dogs ran"))

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
test_equal("regex bol on empty string with NOTBOL flag", regex:ERROR_NOMATCH, regex:find(re, "", ,regex:NOTBOL))

re = regex:new("$")
test_equal("regex eol on empty string", {{1,0}}, regex:find(re, ""))
test_equal("regex eol on empty string with NOTEOL flag", regex:ERROR_NOMATCH, regex:find(re, "", ,regex:NOTEOL))
test_equal("regex eol on empty string with NOTEMPTY flag", regex:ERROR_NOMATCH, regex:find(re, "",, regex:NOTEMPTY))

re = regex:new("([A-Z][a-z]+) ([A-Z][a-z]+)")
test_equal("find_replace() #1", "hello Doe, John!", regex:find_replace(re, "hello John Doe!", `\2, \1`))
test_equal("find_replace() #2", "hello DOE, john!", regex:find_replace(re, "hello John Doe!", `\U\2\e, \L\1\e`))
test_equal("find_replace() #3", "hello \nDoe, John!", regex:find_replace(re, "hello John Doe!", `\n\2, \1`))
test_equal("find_replace() #4", "hello John\tDoe!", regex:find_replace(re, "hello John Doe!", `\1\t\2`))
test_equal("find_replace() #5", "hello Mr. John Doe!", regex:find_replace(re, "hello John Doe!", `Mr. \1 \2`))

re = re:new(`<[^>]+>`)
test_equal("find_replace() #6", "Howdy You",
	regex:find_replace(re, "<b>Howdy</b> <strong>You</strong>", ""))
test_equal("find_replace() #7", "^Howdy^ ^You^",
	regex:find_replace(re, "<b>Howdy</b> <strong>You</strong>", "^"))

re = regex:new("([A-Z][a-z]+) ([A-Z][a-z]+)")
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

test_equal("option names", {"STRING_OFFSETS"}, option_spec_to_string(regex:STRING_OFFSETS))
test_equal("sequence option spec", re:regex(
	re:new(`\<\?xml(.*)\?\>`, {re:MULTILINE, NEWLINE_ANY,DOTALL} )
	), 1 ) -- ticket 161

-- error reports
for i = 1 to length(error_names) do
	test_equal( sprintf("error name %d is %s.", {i, error_names[i][2]}), error_names[i][2], error_to_string( error_names[i][1] ) )
end for

test_equal( sprintf("error name %d gives the number.", 0),"0", error_to_string( 0 ) )
test_equal( sprintf("error name %d gives the number.", 21),"21", error_to_string( 21 ) )

procedure test_references()
	object x = re:find( `World`, "Hello World!" )
	test_equal( "try uncompiled regex literal", 1, atom( x ) )

	regex r=re:new( `World` )
	x = re:find( r, "Hello World!" )
	test_equal( "try compiled regex", 1, sequence(x) )

	----
	-- given a preceding re:new(`World`)
	-- this now works

	x = re:find( `World`, "Hello World!" )
	test_equal( "retry literal used to compile a regex", 0, sequence( x ) )

end procedure
test_references()

-- ticket:350 test
re = re:new(`fixes(\?)? ticket ([0-9]+)`, re:CASELESS)
test_equal("ticket #350", {
	{ "fixes? ticket 384", "?", "384" }, 
	{ "fixes ticket 999", "", "999" }
}, re:all_matches(re, "fixes? ticket 384, fixes ticket 999"))

-- ticket:363 test
regex re_full_name = re:new(`[A-Z][a-z]+ ?([A-Z][a-z]+)?`)

-- Displays the number of captured groups and displays where the first missing group is.
-- A missing group is a group that doesn't exist.
-- The first missing group is 0, if there are no missing groups.
function info(sequence params )
	integer missing = eu:find(0,params)
	--return sprintf("group count: %d.  The missing group is at %d.\n", 
	return {length(params)-1, missing}
end function

-- Test and display values.
procedure testfrc(sequence rexp, sequence str)
	--printf(1, "re:find_replace_callback(%s,%s,...)\n", {rexp,str})
	--puts(1,re:find_replace_callback(rexp, str, routine_id("info")) )
	
end procedure


test_equal("ticket 362 #1",{1,0},re:find_replace_callback(re_full_name, "John Doe", 
	routine_id("info"))) -- one group and its matched
test_equal("ticket 362 #2",{0,0},re:find_replace_callback(re_full_name, "Mary ", 
	routine_id("info"))) -- one group first group not matched.  This group not matched is trncated
	-- so it as if there are no groups.
constant data_ext = re:new(`([A-Z][a-z]+)? ?([A-Z][a-z]+)? ([0-9-]+)?`)
test_equal("ticket 362 #3",{2,0},re:find_replace_callback(data_ext, "Micheal Jackson ",
	routine_id("info"))) -- Three groups.  phone number, index value 4, is not matched.
	-- last group is not matched so it is truncated.  Therefore, two groups matching. 
test_equal("ticket 362 #4",{3,3},re:find_replace_callback(data_ext, "Cher 555-1212",
	routine_id("info"))) -- Three groups, but last name, index value 3, not matched.
constant message = "fixes? ticket 348, fixes ticket 999" 
constant re_ticket = re:new(`fixes(\?)? ticket ([0-9]+)`, re:CASELESS)
test_equal("ticket 362 #5",{2,0} & ", " & {2,2},re:find_replace_callback(re_ticket, message,
	routine_id("info")))
test_equal("Replace * with empty string on a string '*'.", regex:find_replace(re:new("\\*"), "*", ""), "")

test_report()
