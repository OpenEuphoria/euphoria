-- (c) Copyright 2008 Rapid Deployment Software - See License.txt

include std/math.e

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
-- written on. There are a few good resources online that can help while learning
-- regular expressions:
--
-- * [[Perl Regular Expressions Man Page -> http://perldoc.perl.org/perlre.html]]
-- * [[Regular Expression Library -> http://regexlib.com/]] (user supplied regular
--   expressions for just about any task).
-- * [[WikiPedia Regular Expression Article -> http://en.wikipedia.org/wiki/Regular_expression]]
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
	BSR_UNICODE        = #01000000

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
-- Return an allocated regular expression which must be freed using [[:free]]() when done.
--
-- Parameters:
--   # ##pattern##: a sequence representing a human redable regular expression
--   # ##options##: defaults to [[:DEFAULT]]. See [[:Option Constants]]
--
-- Returns:
--   A [[:regex]] which other regular expression routines can work on or < 0 indicates an error.
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

public function new(sequence pattern, object options=DEFAULT)
	return machine_func(M_PCRE_COMPILE, { pattern, options })
end function

--**
-- Frees the memory used by a [[:regex]].
--
-- See Also:
--   [[:new]]

public procedure free(regex re)
	machine_proc(M_PCRE_FREE, { re })
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
--   # ##options##: find options, defaults to [[:DEFAULT]]. See [[:Option Constants]].
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

public function find(regex re, sequence haystack, integer from=1, integer options=DEFAULT)
	return machine_func(M_PCRE_EXEC, { re, haystack, options, from })
end function

--**
-- Find all occurrances of ##re## in ##haystack## optionally starting at the sequence position
-- ##from##.
--
-- Parameters:
--   # ##re##: a regex for a subject to be matched against
--   # ##haystack##: a string in which to searched
--   # ##from##: an integer setting the starting position to begin searching from. Defaults to 1
--   # ##options##: find options, defaults to [[:DEFAULT]]. See [[:Option Constants]].
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

public function find_all(regex re, sequence haystack, integer from=1, integer options=0)
	object result
	
	sequence results = {}
	while sequence(result) with entry do
		results = append(results, result)
		from = max(result) + 1

		if from > length(haystack) then
			exit
		end if
	entry
		result = machine_func(M_PCRE_EXEC, { re, haystack, options, from })
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
--   # ##options##: find options, defaults to [[:DEFAULT]]. See [[:Option Constants]].
--
-- Returns:
--   An atom. 1 if ##re## matches any portion of ##haystack## or 0 if not.
--

public function has_match(regex re, sequence haystack, integer from=1, integer options=0)
	return sequence(machine_func(M_PCRE_EXEC, { re, haystack, options, from }))
end function

--**
-- Determine if the entire ##haystack## matches ##re##.
--
-- Parameters:
--   # ##re##: a regex for a subject to be matched against
--   # ##haystack##: a string in which to searched
--   # ##from##: an integer setting the starting position to begin searching from. Defaults to 1
--   # ##options##: find options, defaults to [[:DEFAULT]]. See [[:Option Constants]].
--
-- Returns:
--   An atom. 1 if ##re## matches the entire ##haystack## or 0 if not.
--

public function is_match(regex re, sequence haystack, integer from=1, integer options=0)
	object m = machine_func(M_PCRE_EXEC, { re, haystack, options, from })

	if sequence(m) and length(m) > 0 and m[1][1] = 1 and m[1][2] = length(haystack) then
		return 1
	end if

	return 0
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
--   # ##replacement##: a string, used to replace each of the full matches found.
--   # ##options##: an atom, defaulted to 0.
--
-- Returns:
--   A **sequence**, the modified ##text##.
--
-- Comments:
--   Matches may be found against the result of previous replacements. Careful experimentation is
--   highly recommended before doing things like text = regex:find_replace(re,text,whatever,something).
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

public function find_replace(regex re, sequence text, sequence replacement, integer from=1, atom options=0)
	return machine_func(M_PCRE_REPLACE, { re, text, replacement, options, from })
end function
