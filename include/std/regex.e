-- (c) Copyright Rapid Deployment Software - See License.txt

include std/math.e
include std/text.e

--****
-- == Regular Expressions
--
-- <<LEVELTOC depth=2>>
--
-- === Introduction
--
-- Regular expressions in Euphoria are based on the Perl Compatible Regular Expressions
-- library created by Philip Hazel. 
--
-- This document will detail the Euphoria interface to Regular Expressions, not really
-- regular expression syntax. It is a very complex subject that many books have been
-- written on. Here are a few good resources online that can help while learning
-- regular expressions.
--
-- * [[EUForum Article -> http://openeuphoria.org/wiki/euwiki.cgi?EuGuide%20Regular%20Expressions ]]
-- * [[Perl Regular Expressions Man Page -> http://perldoc.perl.org/perlre.html]]
-- * [[Regular Expression Library -> http://regexlib.com/]] (user supplied regular
--   expressions for just about any task).
-- * [[WikiPedia Regular Expression Article -> http://en.wikipedia.org/wiki/Regular_expression]]
--
-- === General Use
--
-- Many functions take an optional ##options## parameter. This parameter can be either
-- a single option constant (see [[:Option Constants]], multiple option constants or'ed
-- together into a single atom or a sequence of options, in which the function will take
-- care of ensuring the are or'ed together correctly.
--

enum M_PCRE_COMPILE=68, M_PCRE_FREE, M_PCRE_EXEC, M_PCRE_REPLACE

--****
-- === Option Constants

public constant 
	DEFAULT            = #00000000,
	CASELESS           = #00000001,
	MULTILINE          = #00000002,
	DOTALL             = #00000004,
	EXTENDED           = #00000008,
	ANCHORED           = #00000010,
	DOLLAR_ENDONLY     = #00000020,
	EXTRA              = #00000040,
	NOTBOL             = #00000080,
	NOTEOL             = #00000100,
	UNGREEDY           = #00000200,
	NOTEMPTY           = #00000400,
	UTF8               = #00000800,
	NO_AUTO_CAPTURE    = #00001000,
	NO_UTF8_CHECK      = #00002000,
	AUTO_CALLOUT       = #00004000,
	PARTIAL            = #00008000,
	DFA_SHORTEST       = #00010000,
	DFA_RESTART        = #00020000,
	FIRSTLINE          = #00040000,
	DUPNAMES           = #00080000,
	NEWLINE_CR         = #00100000,
	NEWLINE_LF         = #00200000,
	NEWLINE_CRLF       = #00300000,
	NEWLINE_ANY        = #00400000,
	NEWLINE_ANYCRLF    = #00500000,
	BSR_ANYCRLF        = #00800000,
	BSR_UNICODE        = #01000000,
	STRING_OFFSETS     = #0C000000

--****
-- === Error Constants

public constant
	ERROR_NOMATCH        =  (-1),
	ERROR_NULL           =  (-2),
	ERROR_BADOPTION      =  (-3),
	ERROR_BADMAGIC       =  (-4),
	ERROR_UNKNOWN_OPCODE =  (-5),
	ERROR_UNKNOWN_NODE   =  (-5),
	ERROR_NOMEMORY       =  (-6),
	ERROR_NOSUBSTRING    =  (-7),
	ERROR_MATCHLIMIT     =  (-8),
	ERROR_CALLOUT        =  (-9),
	ERROR_BADUTF8        = (-10),
	ERROR_BADUTF8_OFFSET = (-11),
	ERROR_PARTIAL        = (-12),
	ERROR_BADPARTIAL     = (-13),
	ERROR_INTERNAL       = (-14),
	ERROR_BADCOUNT       = (-15),
	ERROR_DFA_UITEM      = (-16),
	ERROR_DFA_UCOND      = (-17),
	ERROR_DFA_UMLIMIT    = (-18),
	ERROR_DFA_WSSIZE     = (-19),
	ERROR_DFA_RECURSE    = (-20),
	ERROR_RECURSIONLIMIT = (-21),
	ERROR_NULLWSLIMIT    = (-22),
	ERROR_BADNEWLINE     = (-23)

--****
-- === Create/Destroy

--**
-- Regular expression type

public type regex(object o)
	return sequence(o)
end type

--**
-- Return an allocated regular expression
--
-- Parameters:
--   # ##pattern##: a sequence representing a human readable regular expression
--   # ##options##: defaults to [[:DEFAULT]]. See [[:Option Constants]]. 
--
-- Returns:
--   A [[:regex]] which other regular expression routines can work on or < 0 indicates an error.
--
-- Comments:
--   This is the only routine that accepts a human readable regular expression. The string is
--   compiled and a [[:regex]] is returned. Analyzing and compiling a regular expression is a
--   costly operation and should not be done more than necessary. For instance, if your application
--   looks for an email address among text frequently, you should create the regular expression
--   as a constant accessible to your source code and any files that may use it, thus, the regular
--   expression is analyzed and compiled only once per run of your application.
--
--   **Bad Example**
--   <eucode>
--   while sequence(line) do
--       re:regex proper_name = re:new("[A-Z][a-z]+ [A-Z][a-z]+")
--       if re:match(line) then
--           -- code
--       end if
--   end while
--   </eucode>
--
--   **Good Example**
--   <eucode>
--   constant re_proper_name = re:new("[A-Z][a-z]+ [A-Z][a-z]+")
--   while sequence(line) do
--       if re:match(line) then
--           -- code
--       end if
--   end while
--   </eucode>
--
-- Example 1:
--   <eucode>
--   include regex.e as re
--   re:regex number = re:new("[0-9]+")
--   </eucode>
--
-- Note:
--   For simple finds, matches or even simple wildcard matches, the built-in Euphoria
--   routines [[:find]], [[:match]] and [[:wildcard_match]] are often times easier to use and
--   a little faster. Regular expressions are faster for complex searching/matching.
--
-- See Also:
--   [[:find]], [[:find_all]]

public function new(sequence pattern, object options=DEFAULT)
	if sequence(options) then options = or_all(options) end if

	return machine_func(M_PCRE_COMPILE, { pattern, options })
end function

--****
-- === Find/Match

--**
-- Find the first match of ##re## in ##haystack##. You can optionally start at the position
-- ##from##.
--
-- Parameters:
--   # ##re##: a regex for a subject to be matched against
--   # ##haystack##: a string in which to searched
--   # ##from##: an integer setting the starting position to begin searching from. Defaults to 1
--   # ##options##: defaults to [[:DEFAULT]]. See [[:Option Constants]]. 
--
-- Returns:
--   An object which is either an atom of 0, meaning nothing found or a sequence of matched pairs.
--   For the explanation of the returned sequence, please see the first example.
--
-- Example 1:
--   <eucode>
--   r = re:new("([A-Za-z]+) ([0-9]+)") -- John 20 or Jane 45
--   object result = re:find(r, "John 20")
--
--   -- The return value will be:
--   -- {
--   --    { 1, 7 }, -- Total match
--   --    { 1, 4 }, -- First grouping "John" ([A-Za-z]+)
--   --    { 6, 7 }  -- Second grouping "20" ([0-9]+)
--   -- }
--   </eucode>
--

public function find(regex re, sequence haystack, integer from=1, object options=DEFAULT)
	if sequence(options) then options = or_all(options) end if

	return machine_func(M_PCRE_EXEC, { re, haystack, options, from })
end function

--**
-- Find all occurrences of ##re## in ##haystack## optionally starting at the sequence position
-- ##from##.
--
-- Parameters:
--   # ##re##: a regex for a subject to be matched against
--   # ##haystack##: a string in which to searched
--   # ##from##: an integer setting the starting position to begin searching from. Defaults to 1
--   # ##options##: defaults to [[:DEFAULT]]. See [[:Option Constants]]. 
--
-- Returns:
--   Returns a sequence of matches. Please see [[:find]] for a detailed description of the return
--   value.
--
-- Example 1:
--   <eucode>
--   constant re_number = re:new("[0-9]+")
--   object matches = re:find_all(re_number, "10 20 30")
--
--   -- matches is:
--   -- {
--   --     {1, 2},
--   --     {4, 5},
--   --     {7, 8}
--   -- }
--   </eucode>
--

public function find_all(regex re, sequence haystack, integer from=1, object options=DEFAULT)
	if sequence(options) then options = or_all(options) end if

	object result
	sequence results = {}
	while sequence(result) with entry do
		results = append(results, result)
		from = max(result) + 1

		if from > length(haystack) then
			exit
		end if
	entry
		result = find(re, haystack, from, options)
	end while
	
	return results
end function

--**
-- Determine if ##re## matches any portion of ##haystack##.
--
-- Parameters:
--   # ##re##: a regex for a subject to be matched against
--   # ##haystack##: a string in which to searched
--   # ##from##: an integer setting the starting position to begin searching from. Defaults to 1
--   # ##options##: defaults to [[:DEFAULT]]. See [[:Option Constants]]. 
--
-- Returns:
--   An atom. 1 if ##re## matches any portion of ##haystack## or 0 if not.
--

public function has_match(regex re, sequence haystack, integer from=1, object options=DEFAULT)
	return sequence(find(re, haystack, from, options))
end function

--**
-- Determine if the entire ##haystack## matches ##re##.
--
-- Parameters:
--   # ##re##: a regex for a subject to be matched against
--   # ##haystack##: a string in which to searched
--   # ##from##: an integer setting the starting position to begin searching from. Defaults to 1
--   # ##options##: defaults to [[:DEFAULT]]. See [[:Option Constants]]. 
--
-- Returns:
--   An atom. 1 if ##re## matches the entire ##haystack## or 0 if not.
--

public function is_match(regex re, sequence haystack, integer from=1, object options=DEFAULT)
	object m = find(re, haystack, from, options)

	if sequence(m) and length(m) > 0 and m[1][1] = 1 and m[1][2] = length(haystack) then
		return 1
	end if

	return 0
end function

--**
-- Get the matched text only.
--
-- Parameters:
--   # ##re##: a regex for a subject to be matched against
--   # ##haystack##: a string in which to searched
--   # ##from##: an integer setting the starting position to begin searching from. Defaults to 1
--   # ##options##: defaults to [[:DEFAULT]]. See [[:Option Constants]]. 
--
-- Returns:
--   Returns a sequence of strings, the first being the entire match and subsequent
--   items being each of the captured groups. The size of the sequence is the number
--   of groups in the expression plus one (for the entire match).
--
--   If ##options## contains the bit [[:STRING_OFFSETS]], then the result is different.
--   For each item, a sequence is returned containing the matched text, the starting
--   index in ##haystack## and the ending index in ##haystack##.
--
-- Example 1:
--   <eucode>
--   constant re_name = re:new("([A-Z][a-z]+) ([A-Z][a-z]+)")
--
--   object matches = re:matches(re_name, "John Doe and Jane Doe")
--   -- matches is:
--   -- {
--   --   "John Doe", -- full match data
--   --   "John",     -- first group
--   --   "Doe"       -- second group
--   -- }
--
--   matches = re:matches(re_name, "John Doe and Jane Doe", STRING_OFFSETS)
--   -- matches is:
--   -- {
--   --   { "John Doe", 1, 8 }, -- full match data
--   --   { "John",     1, 4 }, -- first group
--   --   { "Doe",      6, 8 }  -- second group
--   -- }
--   </eucode>
--
-- See Also:
--   [[:all_matches]]

public function matches(regex re, sequence haystack, integer from=1, object options=DEFAULT)
	integer str_offsets = and_bits(STRING_OFFSETS, options)
	object match_data = find(re, haystack, from, and_bits(options, not_bits(STRING_OFFSETS)))

	if atom(match_data) then return ERROR_NOMATCH end if

	for i = 1 to length(match_data) do
		sequence tmp = haystack[match_data[i][1]..match_data[i][2]]
		if str_offsets then
			match_data[i] = { tmp, match_data[i][1], match_data[i][2] }
		else
			match_data[i] = tmp
		end if
	end for

	return match_data
end function

--**
-- Get the text of all matches
-- 
-- Parameters:
--   # ##re##: a regex for a subject to be matched against
--   # ##haystack##: a string in which to searched
--   # ##from##: an integer setting the starting position to begin searching from. Defaults to 1
--   # ##options##: options, defaults to [[:DEFAULT]]. See [[:Option Constants]].
--
-- Returns:
--   Returns a sequence of a sequence of strings, the first being the entire match and
--   subsequent items being each of the captured groups. The size of the sequence is
--   the number of groups in the expression plus one (for the entire match).
--
--   If ##options## contains the bit [[:STRING_OFFSETS]], then the result is different.
--   For each item, a sequence is returned containing the matched text, the starting
--   index in ##haystack## and the ending index in ##haystack##.
--
-- Example 1:
--   <eucode>
--   constant re_name = re:new("([A-Z][a-z]+) ([A-Z][a-z]+)")
--
--   object matches = re:match_all(re_name, "John Doe and Jane Doe")
--   -- matches is:
--   -- {
--   --   {             -- first match
--   --     "John Doe", -- full match data
--   --     "John",     -- first group
--   --     "Doe"       -- second group
--   --   },
--   --   {             -- second match
--   --     "Jane Doe", -- full match data
--   --     "Jane",     -- first group
--   --     "Doe"       -- second group
--   --   }
--   -- }
--
--   matches = re:match_all(re_name, "John Doe and Jane Doe")
--   -- matches is:
--   -- {
--   --   {                         -- first match
--   --     { "John Doe",  1,  8 }, -- full match data
--   --     { "John",      1,  4 }, -- first group
--   --     { "Doe",       6,  8 }  -- second group
--   --   },
--   --   {                         -- second match
--   --     { "Jane Doe", 14, 21 }, -- full match data
--   --     { "Jane",     14, 17 }, -- first group
--   --     { "Doe",      19, 21 }  -- second group
--   --   }
--   -- }--   </eucode>
--
-- See Also:
--   [[:matches]]

public function all_matches(regex re, sequence haystack, integer from=1, object options=DEFAULT)
	integer str_offsets = and_bits(STRING_OFFSETS, options)
	object match_data = find_all(re, haystack, from, and_bits(options, not_bits(STRING_OFFSETS)))

	if length(match_data) = 0 then return ERROR_NOMATCH end if

	for i = 1 to length(match_data) do
		for j = 1 to length(match_data[i]) do
			sequence tmp = haystack[match_data[i][j][1]..match_data[i][j][2]]
			if str_offsets then
				match_data[i][j] = { tmp, match_data[i][j][1], match_data[i][j][2] }
			else
				match_data[i][j] = tmp
			end if
		end for
	end for

	return match_data
end function

--****
-- === Splitting

--**
-- Split a string based on a regex as a delimiter
--
-- Parameters:
--   # ##re##: a regex which will be used for matching
--   # ##text##: a string on which search and replace will apply
--   # ##from##: optional start position
--   # ##options##: options, defaults to [[:DEFAULT]]. See [[:Option Constants]].
--
-- Returns:
--   A sequence of string values split at the delimiter.
--   
-- Example 1:
-- <eucode>
-- regex comma_space_re = re:new(#/\s,/)
-- sequence data = re:split(comma_space_re, "euphoria programming, source code, reference data")
-- -- data is
-- -- {
-- --   "euphoria programming",
-- --   "source code",
-- --   "reference data"
-- -- }
-- </eucode>
-- 

public function split(regex re, sequence text, integer from=1, object options=DEFAULT)
	return split_limit(re, text, 0, from, options)
end function

public function split_limit(regex re, sequence text, integer limit=0, integer from=1, object options=DEFAULT)
	sequence match_data = find_all(re, text, from, options), result
	integer last = 1

	if limit = 0 then
		limit = length(match_data)
	end if

	result = repeat(0, limit)

	for i = 1 to limit do
		result[i] = text[last..match_data[i][1][1] - 1]
		last = match_data[i][1][2] + 1
	end for

	if last < length(text) then
		result &= { text[last..$] }
	end if

	return result
end function

--****
-- === Replacement
--

--**
-- Replaces all matches of a regex with the replacement text.
--
-- Parameters:
--   # ##re##: a regex which will be used for matching
--   # ##text##: a string on which search and replace will apply
--   # ##replacement##: a string, used to replace each of the full matches found
--   # ##from##: optional start position
--   # ##options##: options, defaults to [[:DEFAULT]]
--
-- Returns:
--   A **sequence**, the modified ##text##.
--
-- ===== Special replacement operators
-- 
-- * **##\##** Causes the next character to lose its special meaning. 
-- * **##\n##** Inserts a 0x0A (LF) character. 
-- * **##\r##** Inserts a 0x0D (CR) character. 
-- * **##\t##** Inserts a 0x09 (TAB) character. 
-- * **##\1##** to **##\9##** Recalls stored substrings from registers (\1, \2, \3, to \9).
-- * **##\0##** Recalls entire matched pattern. 
-- * **##\u##** Convert next character to uppercase 
-- * **##\l##** Convert next character to lowercase 
-- * **##\U##** Convert to uppercase till ##\E## or ##\e## 
-- * **##\L##** Convert to lowercase till ##\E## or ##\e##
-- * **##\E##** or **##\e##** Terminate a ##\\U## or ##\L## conversion
--
-- Example 1:
-- <eucode>
-- regex r = new(#/([A-Za-z]+)\.([A-Za-z]+)/)
-- sequence details = find_replace(r, "hello.txt", #/Filename: \U\1\e Extension: \U\2\e/)
-- -- details = "Filename: HELLO Extension: TXT"
-- </eucode>
--

public function find_replace(regex ex, sequence text, sequence replacement, integer from=1,
		object options=DEFAULT)
	return find_replace_limit(ex, text, replacement, -1, from, options)
end function

--**
-- Replaces up to ##limit## matches of ##ex## in ##text##.
--
-- This function is identical to [[:find_replace]] except it allows you to limit the number of
-- replacements to perform. Please see the documentation for [[:find_replace]] for all the
-- details.
--
-- Parameters:
--   # ##re##: a regex which will be used for matching
--   # ##text##: a string on which search and replace will apply
--   # ##replacement##: a string, used to replace each of the full matches found
--   # ##limit##: the number of matches to process
--   # ##from##: optional start position
--   # ##options##: options, defaults to [[:DEFAULT]]
--
-- Returns:
--   A **sequence**, the modified ##text##.
--
-- See Also:
--   [[:find_replace]]
--

public function find_replace_limit(regex ex, sequence text, sequence replacement, 
			integer limit, integer from=1, object options=DEFAULT)
	if sequence(options) then options = or_all(options) end if

	return machine_func(M_PCRE_REPLACE, { ex, text, replacement, options, from, limit })
end function

--**
-- Replaces up to ##limit## matches of ##ex## in ##text## with the result of a user
-- defined callback. The callback should take one sequence which will contain a string
-- representing the entire match and also a string for every group within the regular
-- expression.
--
-- Parameters:
--   # ##re##: a regex which will be used for matching
--   # ##text##: a string on which search and replace will apply
--   # ##rid##: routine id to execute for each match
--   # ##limit##: the number of matches to process
--   # ##from##: optional start position
--   # ##options##: options, defaults to [[:DEFAULT]]
--
-- Returns:
--   A **sequence**, the modified ##text##.
--
-- Example 1:
-- <eucode>
-- function my_convert(sequence params)
--     switch params[1] do
--         case "1" then 
--             return "one "
--         case "2" then
--             return "two "
--         case else
--             return "unknown "
--     end switch
-- end function
--
-- regex r = re:new(#/\d/)
-- sequence result = re:find_replace_callback(r, "125", routine_id("my_convert"))
-- -- result = "one two unknown "
-- </eucode>
--

public function find_replace_callback(regex ex, sequence text, integer rid, integer limit=0, 
		integer from=1, object options=DEFAULT)
	sequence match_data = find_all(ex, text, from, options), replace_data

	if limit = 0 then
		limit = length(match_data)
	end if
	replace_data = repeat(0, limit)

	for i = 1 to limit do
		sequence params = repeat(0, length(match_data[i]))
		for j = 1 to length(match_data[i]) do
			params[j] = text[match_data[i][j][1]..match_data[i][j][2]]
		end for

		replace_data[i] = call_func(rid, { params })
	end for

	for i = limit to 1 by -1 do
		text = replace(text, replace_data[i], match_data[i][1][1], match_data[i][1][2])
	end for

	return text
end function
