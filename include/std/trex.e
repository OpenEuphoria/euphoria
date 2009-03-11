include std/math.e

--****
-- == Regular Expressions based on T-Rex
--
-- <<LEVELTOC depth=2>>
--
-- === Important Alpha Note
--
-- Euphoria has three regular expression libraries in the alpha software. It is undecided as to
-- which will prevail and make it into final. Only one will, not all three. Please be sure to look
-- also at the [[:Regular Expressions]] and [[:Regular Expressions based on PCRE]] libraries.
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
-- * ##\##	Quote the next metacharacter
-- * ##^##	Match the beginning of the string
-- * ##.##	Match any character
-- * ##$##	Match the end of the string
-- * ##|##	Alternation
-- * ##()##	Grouping (creates a capture)
-- * ##[]##	Character class
--
-- ==== Greedy Closures
-- * ##*##	   Match 0 or more times
-- * ##+##	   Match 1 or more times
-- * ##?##	   Match 1 or 0 times
-- * ##{n}##    Match exactly n times
-- * ##{n,}##   Match at least n times
-- * ##{n,m}##  Match at least n but not more than m times
--
-- ==== Escape Characters
-- * ##\t##		tab                   (HT, TAB)
-- * ##\n##		newline               (LF, NL)
-- * ##\r##		return                (CR)
-- * ##\f##		form feed             (FF)
--
-- ==== Predefined Classes
-- * ##\l##		lowercase next char
-- * ##\u##		uppercase next char
-- * ##\a##		letters
-- * ##\A##		non letters
-- * ##\w##		alphanimeric [0-9a-zA-Z]
-- * ##\W##		non alphanimeric
-- * ##\s##		space
-- * ##\S##		non space
-- * ##\d##		digits
-- * ##\D##		non nondigits
-- * ##\x##		exadecimal digits
-- * ##\X##		non exadecimal digits
-- * ##\c##		control charactrs
-- * ##\C##		non control charactrs
-- * ##\p##		punctation
-- * ##\P##		non punctation
-- * ##\b##		word boundary
-- * ##\B##		non word boundary
--

enum M_TREX_COMPILE=76, M_TREX_EXEC, M_TREX_FREE

--****
-- === Create/Destroy

--**
-- Return an allocated regular expression which must be freed using [[:free]]() when done.
--
-- Parameters:
--   # ##pattern##: a sequence representing a human redable regular expression
--
-- Returns:
--   An atom on success or a sequence containing the error message.
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
--   include trex.e as re
--   object number_regex = re:new("[0-9]+")
--   if sequence(number_regex) then
--       printf(1, "Regular expression failed to compile: %s\n", { number_regex })
--   end if
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
	return machine_func(M_TREX_COMPILE, { pattern, 0 })
end function

--**
-- Frees the memory used by a regular expression.
--
-- See Also:
--   [[:new]]

public procedure free(atom re)
	machine_proc(M_TREX_FREE, { re })
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

public function find(atom re, sequence haystack, integer from=1)
	return machine_func(M_TREX_EXEC, { re, haystack, from })
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

public function find_all(atom re, sequence haystack, integer from=1)
	object result
	
	sequence results = {}
	while sequence(result) entry do
		results = append(results, result[1])
		from = max(result) + 1

		if from > length(haystack) then
			exit
		end if
	entry
		result = machine_func(M_TREX_EXEC, { re, haystack, from })
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

public function has_match(atom re, sequence haystack, integer from=1)
	return sequence(machine_func(M_TREX_EXEC, { re, haystack, from }))
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

public function is_match(atom re, sequence haystack, integer from=1)
	object m = machine_func(M_TREX_EXEC, { re, haystack, from })

	if sequence(m) and length(m) > 0 and m[1][1] = 1 and m[1][2] = length(haystack) then
		return 1
	end if

	return 0
end function

--****
-- === Replacement
--
-- The trex regular expression library does not yet have a replace method like the
-- brother [[:Regular Expressions]] library does. It will, however, have a replace method
-- if it is choosen as the library to keep. If we have problems deciding, a method
-- will be created to help the decision.
--
