-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Sequence routines
--
--****
-- Category: 
--   search
--
-- File:
--   lib_srch
--
-- Title:
--   Searching
--****

include machine.e

--
-- Internal Function Documentation
--

--**
-- Signature:
--   global function compare(object x1, object x2)
--
-- Description:
--   Returns 0 if objects are identical, 1 if x1 is greater, -1 if x1 is 
--   less than.
--
-- Comments:
--   Atoms are considered to be less than sequences. Sequences are compared
--   alphabetically starting with the first element until a difference is
--   found.
--
-- Example 1:
--   x = compare({1,2,{3,{4}},5}, {2-1,1+1,{3,{4}},6-1})
--   -- identical, x is 0
-- 
-- Example 2:
--   if compare("ABC", "ABCD") < 0 then   -- -1
--       -- will be true: ABC is "less" because it is shorter
--   end if
--
-- Example 3:
--   x = compare('a', "a")
--   -- x will be -1 because 'a' is an atom
--   -- while "a" is a sequence
--
-- Example 4:
--   x = compare('a', "a")
--   -- x will be -1 because 'a' is an atom
--   -- while "a" is a sequence
--
-- See Also:
--   search:equal, 
--   <a href="refman_2.htm#23">relational operators</a>,
--   <a href="refman_2.htm#26">operations on sequences</a>
--
--**

--
-- Functions
--

--**
-- Find any element from s1 in s2 starting at position i2 and return
-- its position or 0 if not found.
--
-- Comments:
--   This function may be applied to a string sequence or a complex
--   sequence.
--
-- Example 1:
--   location = find_any_from("aeiou", "John Smith", 3)
--   -- location is 8
--
-- See Also: 
--   search:find_any

global function find_any_from(sequence needles, sequence haystack, 
	integer start)
	for i = start to length(haystack) do
		if find(haystack[i],needles) then
			return i
		end if
	end for
	return 0
end function

--**

--**
-- Find any element from needles in haystack and return the smallest position of
-- haystack at which anything is found or 0 if nothing is found.
--
-- Comments:
--    This function may be applied to a string sequence or a complex sequence.
--
-- Example 1:
--   location = find_any("aeiou", "John Doe")
--   -- location is 2
--
-- See Also:
--   search:find_any_from
--

global function find_any(sequence needles, sequence haystack)
	return find_any_from(needles, haystack, 1)
end function

--**

global function find_all(object x, sequence source, integer from)
	sequence ret

	ret = {}
	while from > 0 entry do
		ret &= from
		from += 1
	entry
		from = find_from(x, source, from)
	end while
	return ret
end function

global function match_all(object x, sequence source, integer from)
	sequence ret

	ret = {}
	while from > 0 entry do
		ret &= from
		from += length(x)
	entry
		from = match_from(x, source, from)
	end while

	return ret
end function

--Find x as an element of s starting from index start going down to 1
--If start<1 then it is an offset from the end of s
global function rfind_from(object x, sequence s, integer start)
	integer len

	len=length(s)

	if (start > len) or (len + start < 1) then
		crash("third argument of rfind_from() is out of bounds (%d)", {start})
	end if

	if start < 1 then
		start = len + start
	end if

	for i = start to 1 by -1 do
		if equal(s[i], x) then
			return i
		end if
	end for

	return 0
end function

global function rfind(object x, sequence s)
	return rfind_from(x, s, length(s))
end function

--Try to match x against some slice of s, starting from index start and going down to 1
--if start<0 then it is an offset from the end of s
global function rmatch_from(sequence x, sequence s, integer start)
	integer len,lenx

	len = length(s)
	lenx = length(x)

	if lenx = 0 then
		crash("first argument of rmatch_from() must be a non-empty sequence", {})
	elsif (start > len) or  (len + start < 1) then
		crash("third argument of rmatch_from is out of bounds (%d)", {start})
	end if

	if start < 1 then
		start = len + start
	end if

	if start + lenx - 1 > len then
		start = len - lenx + 1
	end if

	lenx-= 1

	for i=start to 1 by -1 do
		if equal(x, s[i..i + lenx]) then
			return i
		end if
	end for

	return 0
end function

global function rmatch(sequence x, sequence s)
	if length(x)=0 then
		crash("first argument of rmatch_from() must be a non-empty string", {})
	end if

	return rmatch_from(x, s, length(s))
end function

global function find_replace(sequence what, sequence repl_with, sequence source, integer max)
	integer posn
	
	if length(what) then
		posn = match(what, source)
		while posn do
			source = source[1..posn-1] & repl_with & source[posn+length(what)..length(source)]
			posn = match_from(what, source, posn+length(repl_with))
			max -= 1
			if max = 0 then
				exit
			end if
		end while
	end if

	return source
end function
