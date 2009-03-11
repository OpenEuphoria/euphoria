-- (c) Copyright 2008 Rapid Deployment Software - See License.txt

include std/math.e

--****
-- == Regular Expressions
--
-- <<LEVELTOC depth=2>>
--
-- === Important Alpha Note
--
-- Euphoria has three regular expression libraries in the alpha software. It is undecided as to
-- which will prevail and make it into final. Only one will, not all three. Please be sure to look
-- also at the [[:Regular Expressions based on PCRE]] and [[:Regular Expressions based on T-Rex]]
-- libraries.
--
-- === Introduction
--
-- Regular expressions are a way to specify text patterns when searching for text in a sequence.
-- Regular expressions consist of normal characters and special operator characters with a
-- special meaning. Operators allow you to anchor matches, match classes of characters, match
-- a given pattern one or several times, match alternate patterns and more. Operators can also
-- be grouped into sub-patterns.
--
-- === Expression Syntax
--
-- * **##\##** Quotes the following character. If the following character is not alphanumeric, it will lose its special meaning, otherwise it will gain a special meaning as described below.
-- * **##\n##** Matches a 0x0A (LF) character. 
-- * **##\r##** Matches a 0x0D (CR) character. 
-- * **##\t##** Matches a 0x09 (TAB) character. 
-- * **##\e##** Matches an escape character (0x1B) 
-- * **##\s##** Matches whitespace (CR, LF, TAB, SPACE) characters. 
-- * **##\S##** Matches non-whitespace (the reverse of \s) 
-- * **##\w##** Matches word character [a-zA-Z0-9] 
-- * **##\W##** Matches non-word character 
-- * **##\d##** Matches a digit [0-9]. 
-- * **##\D##** Matches a non-digit. 
-- * **##\U##** Matches uppercase characters (A-Z) 
-- * **##\L##** Matches lowercase characters (a-z) 
-- * **##\x####** Matches specified hex value (\x0A, \x0D, \x09, etc.) 
-- * **##\o#####** Matches specified octal value (\o000, \o015, etc.) 
-- * **##\N#####** Matches specified decimal value (\N000, \N013, \N009, etc.) 
-- * **##\C##** Starts case sensitive matching. 
-- * **##\c##** Starts case insensitive matching. 
-- * **##^##** Match a beginning of line. 
-- * **##$##** Match an end of line. 
-- * **##.##** Match any character. 
-- * **##<##** Match beginning of word (word consists of [A-Za-z0-9]). 
-- * **##>##** Match end of word. 
-- * **##[ ]##** Specifies a class of characters ([abc123], [\]\x10], etc). 
-- * **##[ - ]##** Specified a range of characters ([0-9a-zA-Z_], [0-9], etc) 
-- * **##[^ ]##** Specifies complement class ([^a-z], [^\-], etc) 
-- * **##?##** Matches preceeding pattern optionally (a?bc, filename\.?, $?, etc) 
-- * **##|##** Matches preceeding or next pattern (a|b, c|d, abc|d). Only one character will be used as pattern unless grouped together using {} or (). 
-- * **##*##** Match zero or more occurances of preceeding pattern. Matching is greedy and will match as much as possible. 
-- * **##+##** Match one or more occurances of preceeding pattern. Match is greedy. 
-- * **##@##** Match zero or more occurances of preceeding pattern. Matching is non-greedy and will match as little as possible without causing the rest of the pattern match to fail. 
-- * **#####** Match one or more occurances of preceeding pattern. Matching is non-greedy. 
-- * **##{ }##** Group patterns together to form complex pattern. ( {abc}, {abc}|{cde}, {abc}?, {word}?) 
-- * **##( )##** Group patterns together to form complex pattern. Also used to save the matched substring into the register which can be used for substitution operation. Up to 9 registers can be used. 
-- 
-- ==== Special replacement operators
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
--

constant
	M_REGEX_COMPILE = 68,
	M_REGEX_EXEC    = 69,
	M_REGEX_MATCH   = 70,
	M_REGEX_REPLACE = 71,
	M_REGEX_FREE    = 72


--****
-- === Create/Destroy

--**
-- Regular expression type

public type regex(object o)
	return atom(o)
end type

--**
-- Return an allocated regular expression which must be freed using [[:free]]() when done.
--
-- Parameters:
--   # ##pattern##: a sequence representing a human redable regular expression
--
-- Returns:
--   A [[:regex]] which other regular expression routines can work on.
--
-- Comments:
--   This is the only routine that accepts a human readable regular expression. The string is
--   compiled and a [[:regex]] is returned. Analyzing and compiling a regular expression is a
--   costly operation and should not be done more than necessary. For instance, if your application
--   looks for an email address among text frequently, you should create the regular expression
--   as a constant accessable to your source code and any files that may use it, thus, the regular
--   expression is analyzed and compiled only once per run of your application.
--
--   **Bad Example**
--   <eucode>
--   while sequence(line) do
--       re:regex proper_name = re:new("[A-Z][a-z]+ [A-Z][a-z]+")
--       if re:match(line) then
--           -- code
--       end if
--       re:free(proper_name)
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
--   [[:free]], [[:find]], [[:find_all]]

public function new(sequence pattern)
	return machine_func(M_REGEX_COMPILE, {pattern})
end function

--**
-- Frees the memory used by a [[:regex]].
--
-- See Also:
--   [[:new]]

public procedure free(regex re)
	if equal(re, 0) then
		return
	end if

	machine_proc(M_REGEX_FREE, {re})
end procedure


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
--
-- Returns:
--   An object which is either an atom of 0, meaning nothing found or a sequence of matched pairs.
--   For the explanation of the returned sequence, please see the first example.
--
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

public function find(regex re, sequence haystack, integer from=1)
	return machine_func(M_REGEX_EXEC, {re, haystack, from})
end function

--**
-- Find all occurrances of ##re## in ##haystack## optionally starting at the sequence position
-- ##from##.
--
-- Parameters:
--   # ##re##: a regex for a subject to be matched against
--   # ##haystack##: a string in which to searched
--   # ##from##: an integer setting the starting position to begin searching from. Defaults to 1
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

public function find_all(regex re, sequence haystack, integer from=1)
	object result
	
	sequence results = {}
	while sequence(result) entry do
		results = append(results, result[1])
		from = max(result) + 1

		if from > length(haystack) then
			exit
		end if
	entry
		result = find(re, haystack, from)
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
--
-- Returns:
--   An atom. 1 if ##re## matches any portion of ##haystack## or 0 if not.
--

public function has_match(regex re, sequence haystack, integer from=1)
	return sequence(machine_func(M_REGEX_EXEC, {re, haystack, from}))
end function

--**
-- Determine if the entire ##haystack## matches ##re##.
--
-- Parameters:
--   # ##re##: a regex for a subject to be matched against
--   # ##haystack##: a string in which to searched
--   # ##from##: an integer setting the starting position to begin searching from. Defaults to 1
--
-- Returns:
--   An atom. 1 if ##re## matches the entire ##haystack## or 0 if not.
--

public function is_match(regex re, sequence haystack, integer from=1)
	return machine_func(M_REGEX_MATCH, {re, haystack, from})
end function

--****
-- === Replacement

--**
-- Perform a fast regular expression replacement.
--
-- Parameters:
--   # ##re##: a regex for a subject to be matched against
--   # ##haystack##: a string in which to searched
--   # ##replacement##: a string to replace with
--
-- Comments:
--   ##replacement## may contain special operators. Please see [[:Special replacement operators]]
--   for more information.
--
-- Example 1:
--   <eucode>
--   constant r = re:new("([A-za-z]+)\\.([A-Za-z]+)")
--   sequence s = re:replace(r, "myfile.txt", "Filename: \\1 Extension: \\2")
--   -- s is "Filename: myfile Extension: txt"
--   </eucode>
--

public function replace(regex re, sequence haystack, sequence replacement)
	return machine_func(M_REGEX_REPLACE, {re, haystack, replacement})
end function
