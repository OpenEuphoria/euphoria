-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- Category: 
--   search
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
--   location = find_any("aeiou", "John Smith", 3)
--   -- location is 8
--
-- Example 2:
--   location = find_any("aeiou", "John Doe")
--   -- location is 2

global function find_any(sequence needles, sequence haystack, integer start=1)
	for i = start to length(haystack) do
		if find(haystack[i],needles) then
			return i
		end if
	end for
	return 0
end function
--**

--**
global function find_all(object x, sequence source, integer from=1)
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
--**

--**
global function match_all(object x, sequence source, integer from=1)
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
--**

--**
-- Find x as an element of s starting from index start going down to 1
-- If start<1 then it is an offset from the end of s

global function rfind(object x, sequence s, integer start=-1)
	integer len

	if start = -1 then
		start = length(s)
	end if

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
--**

--**
-- Try to match x against some slice of s, starting from index start and going down to 1
-- if start<0 then it is an offset from the end of s

global function rmatch(sequence x, sequence s, integer start=-1)
	integer len,lenx

	if start = -1 then
		start = length(s)
	end if

	len = length(s)
	lenx = length(x)

	if lenx = 0 then
		crash("first argument of rmatch() must be a non-empty sequence", {})
	elsif (start > len) or  (len + start < 1) then
		crash("third argument of rmatch() is out of bounds (%d)", {start})
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
--**

--**
global function find_replace(object what, object repl_with, sequence source, integer max=0)
	integer posn
	
	if atom(what) then
		what = {what}
	end if
	if atom(repl_with) then
		repl_with = {repl_with}
	end if
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
--**

--**
-- Assumes haystack is already sorted into ascending order.

global function binary_search(object needle, sequence haystack, integer startpoint = 1, 
			integer endpoint = 0)
	integer lo, hi, mid, c  -- works up to 1.07 billion records
	
	lo = startpoint
	if endpoint <= 0 then
		hi = length(haystack) - endpoint
	else
		hi = endpoint
	end if
	if lo > hi and length(haystack) > 0 then
		hi = length(haystack)
	end if
	mid = startpoint
	c = 0
	while lo <= hi do
		mid = floor((lo + hi) / 2)
		c = compare(needle, haystack[mid])
		if c < 0 then
			hi = mid - 1
		elsif c > 0 then
			lo = mid + 1
		else
			return mid
		end if
	end while
	-- return the position it would have, if inserted now
	if c > 0 then
		mid += 1
	end if
	return -mid
end function
--**

