-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- Category:
--	 sequence
--
-- Title:
--	 Sequence Manipulation
--****

include machine.e
include search.e
include misc.e

--**
-- Signature:
-- global function append(sequence s1, object x)
--
-- Description:
-- Create a new sequence (s2) identical to s1 but with x added on the end as the last element. 
-- The length of s2 will be length(s1) + 1.
--
-- Comments:
-- If x is an atom this is equivalent to <strong>s2 = s1 & x</strong>. If x is a sequence it is
-- not equivalent.
--
-- The extra storage is allocated automatically and very efficiently with Euphoria's dynamic 
-- storage allocation. The case where s1 and s2 are actually the same variable (as in 
-- Example 1 below) is highly optimized.
--
-- Example 1:
--   sequence x
--
--   x = {}
--   for i = 1 to 10 do
--	     x = append(x, i)
--   end for
--   -- x is now {1,2,3,4,5,6,7,8,9,10}
--
-- Example 2:
--
-- sequence x, y, z
--
-- x = {"fred", "barney"}
-- y = append(x, "wilma")
-- -- y is now {"fred", "barney", "wilma"}
--
-- z = append(append(y, "betty"), {"bam", "bam"})
-- -- z is now {"fred", "barney", "wilma", "betty", {"bam", "bam"}}
--
-- See Also:
--     prepend, &
--**

--**
-- Signature:
-- global function prepend(sequence s1, object x)
--
-- Description:
-- Create a new sequence (s2) identical to s1 but with x added onto the start of s1 as the 
-- first element. The length of s2 will be length(s1) + 1.
--
-- Comments:
-- If x is an atom this is the same as s2 = x & s1. If x is a sequence it is not the same.
--
-- The case where s1 and s2 are the same variable is handled very efficiently.
--
-- Example 1:
-- prepend({1,2,3}, {0,0})	 -- {{0,0}, 1, 2, 3}
-- -- Compare with concatenation:
-- {0,0} & {1,2,3}			 -- {0, 0, 1, 2, 3}
--
-- Example 2:
-- s = {}
-- for i = 1 to 10 do
--	   s = prepend(s, i)
-- end for
-- -- s is {10,9,8,7,6,5,4,3,2,1}
--
-- See Also:
--     append, &
--**

--**
-- Signature:
-- global function repeat(sequence x, atom a)
--
-- Description:
-- Create a sequence of length a where each element is x.
--
-- Comments:
-- When you repeat a sequence or a floating-point number the
-- interpreter does not actually make multiple copies in memory.
-- Rather, a single copy is "pointed to" a number of times.
--
-- Example 1:
-- repeat(0, 10)	  -- {0,0,0,0,0,0,0,0,0,0}
--
-- repeat("JOHN", 4)  -- {"JOHN", "JOHN", "JOHN", "JOHN"}
-- -- The interpreter will create only one copy of "JOHN"
-- -- in memory
--
-- See Also:
--     repeat_pattern, linear
--**

--**
-- Signature:
-- global function length(sequence s)
--
-- Description:
-- Return the length of a sequence s. An error will occur if s is an atom.
--
-- Comments:
-- The length of each sequence is stored internally by the
-- interpreter for quick access. (In other languages this
-- operation requires a search through memory for an end marker.)
--
-- Example 1:
-- length({{1,2}, {3,4}, {5,6}})   -- 3
-- length("")	 -- 0
-- length({})	 -- 0
--
-- See Also:
--     append, prepend, &
--**

--**
-- Signature:
-- global function sprintf(sequence st, object x)
--
-- Description:
-- This is exactly the same as printf(), except that the output is returned as a sequence 
-- of characters, rather than being sent to a file or device. st is a format string, x 
-- is the value or sequence of values to be formatted. printf(fn, st, x)  is equivalent 
-- to puts(fn, sprintf(st, x)).
--
-- Comments:
-- Some typical uses of sprintf() are:
--
-- <ol>
-- <li>Converting numbers to strings.</li>
-- <li>Creating strings to pass to system().</li>
-- <li>Creating formatted error messages that can be passed to a common error message 
--     handler.</li>
-- </ol>
--
-- Example 1: 	
-- s = sprintf("%08d", 12345)
-- -- s is "00012345"
--
-- See Also:
--     misc:printf, sprint
--**

--**
-- The representation of x as a string of characters is returned. This is exactly the same 
-- as print(fn, x), except that the output is returned as a sequence of characters, rather 
-- than being sent to a file or device. x can be any Euphoria object.
--
-- Comments:
-- The atoms contained within x will be displayed to a maximum of 10 significant digits, 
-- just as with print().
--
-- Example 1:
-- s = sprint(12345)
-- -- s is "12345"
--
-- Example 2: 	
-- s = sprint({10,20,30}+5)
-- -- s is "{15,25,35}"
--
-- See Also:
--    sprintf, misc:printf

global function sprint(object x)
-- Return the string representation of any Euphoria data object. 
-- This is the same as the output from print(1, x) or '?', but it's
-- returned as a string sequence rather than printed.
	sequence s
								 
	if atom(x) then
		return sprintf("%.10g", x)
	else
		s = "{"
		for i = 1 to length(x) do
			s &= sprint(x[i])  
			if i < length(x) then
				s &= ','
			end if
		end for
		s &= "}"
		return s
	end if
end function
--**

--**
-- Reverse the order of elements in a sequence.
--
-- Comments:
-- A new sequence is created where the top-level elements appear in reverse order compared 
-- to the original sequence.
--
-- Example 1:
-- reverse({1,3,5,7})		   -- {7,5,3,1}
-- reverse({{1,2,3}, {4,5,6}}) -- {{4,5,6}, {1,2,3}}
-- reverse({99})			   -- {99}
-- reverse({})				   -- {}

global function reverse(sequence s)
	integer lower, n, n2
	sequence t

	n = length(s)
	n2 = floor(n/2)+1
	t = repeat(0, n)
	lower = 1
	for upper = n to n2 by -1 do
		t[upper] = s[lower]
		t[lower] = s[upper]
		lower += 1
	end for
	return t
end function
--**

--**
-- Return the first size items of st. If size is greater than the length of st, then the 
-- entire st will be returned.
--
-- Example 1:
-- s2 = head("John Doe", 4)
-- -- s2 is John
--
-- Example 2:
-- s2 = head("John Doe", 50)
-- -- s2 is John Doe
--
-- Example 3:
-- s2 = head({1, 5.4, "John", 30}, 3)
-- -- s2 is {1, 5.4, "John"}
--
-- See Also:
--     tail, mid, slice

global function head(sequence st, integer size=1)
	if size < length(st) then
		return st[1..size]
	end if

	return st
end function
--**

--**
-- Return len items starting at start. If start + len is greater than the length of st, 
-- then everything in st starting at start will be returned.
--
-- Example 1:
-- s2 = mid("John Middle Doe", 6, 6)
-- -- s2 is Middle
--
-- Example 2:
-- s2 = mid("John Middle Doe", 6, 50)
-- -- s2 is Middle Doe
--
-- Example 3:
-- s2 = mid({1, 5.4, "John", 30}, 2, 2)
-- -- s2 is {5.4, "John"}
--
-- See Also:
--     head, tail, slice

global function mid(sequence st, atom start, atom len)
	if len<0 then
		len += length(st)
		if len<0 then
			crash("mid(): len was %d and should be greater than %d.",
				{len-length(st),-length(st)})
		end if
	end if
	if start > length(st) or len=0 then
		return ""
	end if
	if start<1 then
		start=1
	end if
	if start+len-1 >= length(st) then
		return st[start..$]
	else
		return st[start..len+start-1]
	end if
end function
--**

--**
-- Return items start to stop from st. If stop is greater than the length of st, then from 
-- start to the end of st will be returned. If stop is zero, it will be treated as the end 
-- of st. If stop is a negative value, then it will be treated as stop positions from the 
-- end of st.
--
-- Example 1:
-- s2 = slice("John Doe", 6, 8)
-- -- s2 is Doe
--
-- Example 2:
-- s2 = slice("John Doe", 6, 50)
-- -- s2 is Doe
--
-- Example 3:
-- s2 = slice({1, 5.4, "John", 30}, 2, 3)
-- -- s2 is {5.4, "John"}
--
-- Example 4:
-- s2 = slice({1,2,3,4,5}, 2, -1)
-- -- s2 is {2,3,4}
--
-- Example 5:
-- s2 = slice({1,2,3,4,5}, 2, 0)
-- -- s2 is {2,3,4,5}
--
-- See Also:
--     head, mid, tail

global function slice(sequence st, atom start, atom stop)
	if stop < 0 then stop = length(st) + stop end if
	if stop = 0 then stop = length(st) end if
	if start < 1 then start = 1 end if
	if stop > length(st) then stop = length(st) end if
	if start > stop then return "" end if

	return st[start..stop]
end function
--**

--**
-- Perform a vertical slice on a nested sequence
--
-- Example 1:
-- s = vsplice({5,1}, {5,2}, {5,3}}, 2)
-- -- s is {1,2,3}

-- s = vsplice({5,1}, {5,2}, {5,3}}, 1)
-- -- s is {5,5,5}
--
-- See Also:
--     slice, project
global function vslice(sequence s, atom colno)
	sequence ret

	if colno<1 then
		crash("sequence:vslice(): colno should be a valid index, but was %d",colno)
	end if

	ret = s

	for i = 1 to length(s) do
		if colno >= 1+length(s[i]) then
			crash("sequence:vslice(): colno should be a valid index on the %d-th element, " &
			      "but was %d", {i,colno})
		end if
		ret[i] = s[i][colno]
	end for

	return ret
end function
--**

-- TODO: document default parameter usage
-- TODO: =0.03... Yuk! We need NULL :-)

--**
-- Return the last n items of st. If n is greater than the length of st, then the entire st 
-- will be returned.
--
-- Parameters:
--     st - sequence to get tail of.
--     n - number of items to return. (defaults to length(st) - 1)
--
-- Comments:
--     A new sequence is created.
--
--     st can be any type of sequence, including nested sequences.
--
-- Example 1:
-- s2 = tail("John Doe", 3)
-- -- s2 is Doe
--
-- Example 2:
-- s2 = tail("John Doe", 50)
-- -- s2 is John Doe
--
-- Example 3:
-- s2 = tail({1, 5.4, "John", 30}, 3)
-- -- s2 is {5.4, "John", 30}
--
-- See Also:
--     head, mid, slice

global function tail(sequence st, atom n=0.03)
	if n = 0.03 then
		n = length(st) - 1
	end if
	if n >= length(st) then
		return st
	else
		return st[$-n+1..$]
	end if
end function
--**

--**
-- Remove an item or a range of items from st. If index is an integer, then only that
-- element will be removed. If index is a sequence, it must be a sequence of two
-- integers representing start and stop index.
--
-- Parameters:
--     st - sequence in which to remove from.
--     start - index at which to remove (or starting index to remove)
--     stop - index at which to stop remove (defaults to start)
--
-- Comments:
-- A new sequence is created. st can be a string or complex sequence.
--
-- Example 1:
-- s = remove("Johnn Doe", 4)
-- -- s is "John Doe"
--
-- Example 2:
-- s = remove({1,2,3,3,4}, 4)
-- -- s is {1,2,3,4}
--
-- Example 3:
-- s = remove("John Middle Doe", 6, 12)
-- -- s is "John Doe"
--
-- Example 4:
-- s = remove({1,2,3,3,4,4}, 4, 5)
-- -- s is {1,2,3,4}
--
-- See Also:
--     replace, insert, splice, remove_all

global function remove(sequence st, atom start, atom stop=0.003)
	if stop = 0.003 then
		stop = start
	end if

	if stop > length(st) then
		stop = length(st)
	end if

	if start > length(st) or start > stop or stop < 0 then
		return st
	elsif start<2 then
		if stop>=length(st) then
			return ""
		else
			return st[stop+1..$]
		end if
	elsif stop >= length(st) then
		return st[1..start-1]
	end if

	return st[1..start-1] & st[stop+1..$]
end function
--**

--**
-- Removes all ocurrences of needle from haystack
--
-- Parameters:
--     needle - object to remove.
--     haystack - sequence in which to remove from.
--
-- Example 1:
-- s = remove_all( 1, {1,2,4,1,3,2,4,1,2,3} )
-- -- s is {2,4,3,2,4,2,3}
--
-- Example 2:
-- s = remove_all("x", "I'm toox secxksy for my shixrt.")
-- -- s is "I'm too secksy for my shirt."
--
-- See Also:
--     remove

global function remove_all(object needle, sequence haystack)
	integer ts,te,ss,se
	
	-- See if we have to anything at all.    
	se = find(needle, haystack)
	if se = 0 then
		return haystack
	end if
	
	-- Now we know there is at least one occurance and because
	-- it's the first one, we don't have to move anything yet.
	-- So pretend we have and set up the 'end' variables
	-- as if we had moved stuff.
	se -= 1
	te = se
	
	while se > 0 entry do
		-- Shift elements down the sequence.
		haystack[ts .. te] = haystack[ss .. se]
		
	entry
		-- Calc where the next target start is (1 after the previous end)
		ts = te + 1
		
		-- Calc where to start the next search (2 after the previous end)
		ss = se + 2
		
		-- See if we got another one.
		se = find_from(needle, haystack, ss)
		
		-- We have another one, so calculate the source end(1 before the needle)
		se = se - 1
		
		-- Calc the target end (start + length of what we are moving)
		te = ts + se - ss 
	end while
	
	-- Check to see if there is anything after the final needle
	-- and move it.
	if ss <= length(haystack) then
		te = ts + length(haystack) - ss
		haystack[ts .. te] = haystack[ss .. $]
	else
		-- Need to backtrack one needle.
		te = ts - 1
	end if
	
	-- Return only the stuff we moved.
	return haystack[1 .. te]
end function
--**

constant dummy = 0

--**
-- Insert what into st at index index as a new element. The item is inserted before index, 
-- not after. 
--
-- Comments:
--     A new sequence is created. st and what can be any type of sequence, including nested 
--     sequences. What is inserted as a new element in st, so that the length of the new 
--     sequence is always length(st)+1.
--
--     insert()ing a sequence into a string returns a sequence which is no longer a string.
--
-- Example 1:
-- s = insert("John Doe", " Middle", 5)
-- -- s is {'J','o','h','n'," Middle ",'D','o','e'}
--
-- Example 2:
-- s = insert({10,30,40}, 20, 2)
-- -- s is {10,20,30,40}
--
-- See Also:
--     remove, splice, remove_all

global function insert(sequence st, object what, integer index)
	if index > length(st) then
		return append(st, what)
	elsif index <= 1 then
		return prepend(what, st)
	end if

	st &= dummy -- avoids creating/destroying a temp on each invocation
	st[index+1..$] = st[index..$-1]
	st[index] = what
	return st
end function
--**

--**
-- Insert what into st at index. The item is inserted before index, not after. 
-- What is inserted as a subsequence. splicing a string into another yields a new string.
--
-- Parameters:
--     st - sequence to splice into.
--     what - what to split into st.
--     index - index position at which to splice.
--
-- Comments:
--     A new sequence is created. st and what can be any type of sequence, including nested 
--     sequences. The length of this new sequence is the sum of the lengths of st and what 
--     (atoms are of length 1 for this purpose). splice() is equivalent to insert() when x is 
--     an atom.
--
-- Example 1:
-- s = splice("John Doe", " Middle", 5)
-- -- s is "John Middle Doe"
--
-- Example 2:
-- s = splice({10,30,40}, 20, 2)
-- -- s is {10,20,30,40}
--
-- See Also:
--     insert, remove, replace, remove_all

global function splice(sequence st, object what, integer index)
	if index > length(st) then
		return st & what
	elsif index <= 1 then
		return what & st
	end if

	return st[1..index-1] & what & st[index..$]
end function
--**

--**
-- Replace from index start to stop of st with object what. what can be any object.
--
-- Parameters:
--     st - sequence in which replacement will be done.
--     replacement - item to replace with.
--     start - starting index.
--     stop - stopping index.
--
-- Comments:
--   A new sequence is created. st can be a string or complex sequence.
--
--   To replace just one element, simply: s[index] = new_item
--
-- Example 1:
-- s = replace("John Middle Doe", "Smith", 6, 11)
-- -- s is "John Smith Doe"

-- s = replace({45.3, "John", 5, {10, 20}}, 25, 2, 3)
-- -- s is {45.3, 25, {10, 20}}
--
-- See Also:
--     splice, remove, remove_all

global function replace(sequence st, object replacement, integer start, integer stop)
	st = remove(st, start, stop)
	return splice(st, replacement, start)
end function
--**

--**
-- TODO: Limit seems wrong, 1 should split off one item, returning 2 items total.
--
-- Split the sequence st by delim creating a new sequence. 
--
-- If limit is > 0 then limit the number of tokens that will be split to limit.
--
-- If any is 1 then split by any one item in delim not delim as a whole. If any is 0 then 
-- split by delim as a whole.
--
-- Paramters:
--     st - sequence to split.
--     delim - delimiter to split by.
--     limit - maximum number of items to split.
--     any - split by any atom in delim (1) or delim as a whole (0).
--
-- Comments:
-- This function may be applied to a string sequence or a complex sequence
--
-- Example 1:
-- result = split("John Middle Doe")
-- -- result is {"John", "Middle", "Doe"}
--
-- Example 2:
-- result = split("John,Middle,Doe", ",", 2)
-- -- result is {"John", "Middle,Doe"}
--
-- Example 3:
-- result = split("One,Two|Three.Four", ".,|", 0, 1)
-- -- result is {"One", "Two", "Three", "Four"}
--
-- See Also:
--     chunk

global function split(sequence st, object delim=" ", integer limit=0, integer any=0)
	sequence ret
	integer pos, start, next_pos

	ret={}
	start=1

	if atom(delim) then
		delim = {delim}
	end if

	while 1 do
		if any then
			pos = find_any_from(delim, st, start)
			next_pos = pos+1
		else
			pos = match_from(delim, st, start)
			next_pos = pos+length(delim)
		end if

		if pos then
			ret = append(ret, st[start..pos-1])
			start = next_pos
			if limit = 2 then
				exit
			end if
			limit -= 1
		else
			exit
		end if
	end while

	ret = append(ret, st[start..$])

	return ret
end function
--**

--**
-- Join s by delim
--
-- Parameters:
--     s - sequence of items to join.
--     delim - delimiter to join by.
--
-- Comments:
--     This function may be applied to a string sequence or a complex sequence
--
-- Example 1:
-- result = join({"John", "Middle", "Doe"})
-- -- result is "John Middle Doe"
--
-- Example 2:
-- result = join({"John", "Middle", "Doe"}, ",")
-- -- result is "John,Middle,Doe"
--
-- See Also:
--     split

global function join(sequence s, object delim=" ")
	object ret

	if not length(s) then return {} end if

	ret = {}
	for i=1 to length(s)-1 do
		ret &= s[i] & delim
	end for

	ret &= s[length(s)]

	return ret
end function
--**

--**
-- Trim any item in what from the head (start) of str
--
-- Parameters:
--     str - string to trim.
--     what - what to trim (defaults to " \t\r\n").
--
-- Example 1:
-- s = trim_head("\r\nSentence read from a file\r\n", "\r\n")
-- -- s is "Sentence read from a file\r\n"
--
-- See Also:
-- trim_tail, trim, pad_head

global function trim_head(sequence str, object what=" \t\r\n")
	if atom(what) then
		what = {what}
	end if

	for i = 1 to length(str) do
		if find(str[i], what) = 0 then
			return str[i..$]
		end if
	end for

	return ""
end function
--**

--**
-- Trim any item in what from the end (tail) of str
--
-- Parameters:
--     str - string to trim.
--     what - what to trim (defaults to " \t\r\n").
--
-- Example 1:
-- s = trim_head("\r\nSentence read from a file\r\n", "\r\n")
-- -- s is "\r\nSentence read from a file"
--
-- See Also:
--     trim_head, trim, pad_tail

global function trim_tail(sequence str, object what=" \t\r\n")
	if atom(what) then
		what = {what}
	end if

	for i = length(str) to 1 by -1 do
		if find(str[i], what) = 0 then
			return str[1..i]
		end if
	end for

	return ""
end function
--**

--**
-- Trim any item in what from the head (start) and tail (end) of str
--
-- Parameters:
--     str - string to trim.
--     what - what to trim (defaults to " \t\r\n").
--
-- Example 1:
-- s = trim("\r\nSentence read from a file\r\n", "\r\n")
-- -- s is "Sentence read from a file"
--
-- See Also:
--     trim_head, trim_tail

global function trim(sequence str, object what=" \t\r\n")
	return trim_tail(trim_head(str, what), what)
end function
--**

--**
-- Pad the beginning of a sequence with ch up to size in length.
--
-- Parameters:
--     str - string to pad.
--     size - size to pad str to.
--     ch - character to pad to (defaults to ' ').
--
-- Comments:
-- pad_head() will not remove characters. If length(str) is greater than params, this
-- function simply returns str. See head() if you wish to truncate long sequences.
--
-- Example 1:
-- s = pad_head("ABC", 6)
-- -- s is "   ABC"
--
-- s = pad_head("ABC", {6, '-'})
-- -- s is "---ABC"
--
-- See Also:
--     trim_head, pad_tail, head

global function pad_head(sequence str, integer size, object ch=' ')
	if size <= length(str) then
		return str
	end if

	return repeat(ch, size - length(str)) & str
end function
--**

--**
-- Pad the end of a sequence with ch up to size in length.
--
-- Parameters:
--     str - string to pad.
--     size - size to pad 'str' to.
--     ch - character to pad to (defaults to ' ').
--
-- Comments:
--   pad_tail() will not remove characters. If length(str) is greater than params, this
--   function simply returns str. see tail() if you wish to truncate long sequences.
--
-- Example 1:
-- s = pad_tail("ABC", 6)
-- -- s is "ABC   "
--
-- s = pad_tail("ABC", {6, '-'})
-- -- s is "ABC---"
--
-- See Also:
--     trim_tail, pad_head, tail

global function pad_tail(sequence str, integer size, object ch=' ')
	if size <= length(str) then
		return str
	end if

	return str & repeat(ch, size - length(str))
end function
--**

--**
-- Split s1 into multiple sequences of length size
--
-- Comments:
-- The very last sequence might not have i items if the length of s1 is not evenly 
-- divisible by i
--
-- Example 1:
-- s = chunk("5545112133234454", 4)
-- -- s is {"5545", "1121", "3323", "4454"}
--
-- Example 2:
-- s = chunk("12345", 2)
-- -- s is {"12", "34", "5"}
--
-- Example 2:
-- s = chunk({1,2,3,4,5,6}, 3)
-- -- s is {{1,2,3}, {4,5,6}}
--
-- See Also:
--     split

global function chunk(sequence s, integer size)
	sequence ns
	integer stop

	ns = {}

	for i = 1 to length(s) by size do
		stop = i + size - 1
		if stop > length(s) then
			stop = length(s)
		end if

		ns = append(ns, s[i..stop])
	end for

	return ns
end function
--**

--**
-- Remove all nesting from a sequence
--
-- Example 1:
-- s = flatten({{18, 19}, 45, {18.4, 29.3}})
-- -- s is {18, 19, 45, 18.4, 29.3}

global function flatten(sequence s)
	sequence ret
	object x

	ret = {}
	for i = 1 to length(s) do
		x = s[i]
		if atom(x) then
			ret &= x
		else
			ret &= flatten(x)
		end if
	end for

	return ret
end function
--**

constant TO_LOWER = 'a' - 'A'

--**
-- Convert an atom or sequence to lower case. Only alters characters in the 'A'..'Z' range.
--
-- Example 1:
-- s = lower("Euphoria")
-- -- s is "euphoria"
--
-- a = lower('B')
-- -- a is 'b'
--
-- s = lower({"Euphoria", "Programming"})
-- -- s is {"euphoria", "programming"}
--
-- See Also:
--     upper

global function lower(object x)
-- convert atom or sequence to lower case
	return x + (x >= 'A' and x <= 'Z') * TO_LOWER
end function
--**

--**
-- Convert an atom or sequence to upper case. Only alters characters in the 'a'..'z' range.
--
-- Example 1:
-- s = upper("Euphoria")
-- -- s is "EUPHORIA"
--
-- a = upper('b')
-- -- a is 'B'
--
-- s = upper({"Euphoria", "Programming"})
-- -- s is {"EUPHORIA", "PROGRAMMING"}
--
-- See Also:
--     lower

global function upper(object x)
-- convert atom or sequence to upper case
	return x - (x >= 'a' and x <= 'z') * TO_LOWER
end function

--**
-- Checks whether two objects can be legally added together. Returns 1 if so, else 0.
--
-- Example 1:
-- i = can_add({1,2,3},{4,5})
-- -- i is 0
--
-- i = can_add({1,2,3},4)
-- -- i is 1
--
-- i = can_add({1,2,3},{4,{5,6},7})
-- -- i is 1
--
-- See Also:
--     linear

global function can_add(object a, object b)
	if atom(a) or atom(b) then
		return 1
	end if
	if length(a)!=length(b) then
		return 0
	end if
	for i=1 to length(a) do
		if not can_add(a[i],b[i]) then
			return 0
		end if
	end for
	return 1
end function
--**

--**
-- Returns a sequence {start, start+increment,...,start+(count-1)*increment, or 0 on failure.
--
-- Example 1:
-- s = linear({1,2,3},4,3)
-- -- s is {{1,2,3},{5,6,7},{9,10,11}}
--
-- See Also:
--     repeat_pattern

global function linear(object start, object increment, integer count)
	sequence result

	if count<0 or not can_add(start,increment) then
		return 0
	end if
	result=repeat(start,count)
	for i=2 to count do
		start+=increment
		result[i]=start
	end for
	return result
end function
--**

--**
-- Returns a sequence whose n first elements are those of s, as well a the n that follow, 
-- and so on for count copies.
--
-- Example 1:
-- s = repeat_pattern({1,2,5},3)
-- -- s is {1,2,5,1,2,5,1,2,5}
--
-- See Also:
--     repeat, linear

global function repeat_pattern(sequence s, integer count)
	integer ls
	sequence result

	if count<=0 then
		return {}
	end if
	ls=length(s)
	count *= ls
	result=repeat(0,count)
	for i=1 to count by ls do
		result[i..i+ls-1]=s
	end for
	return result
end function
--**

--**
-- Extracts subvectors from vectors, and returns a list of requested subvectors by vector.
--
-- vectors is a rectangular matrix, ie a sequence of sequences of objects.
-- coords is a list of coordinate index lists, ie a sequence of sequences of small positive 
-- integers.
--
-- Returns a sequence the length of vectors. Each of its elements is a sequence,
-- the length of coords, of sequences. Each innermost sequence is made of the
-- coordinates of the vector whose indexes are on the given coordinate list.
--
-- Example 1:
-- s = project({{1,-1,-1,0},{2,1,9}},{{1,2},{3,1},{2}})
-- -- s is {{{2,-1},{-1,2},{-1}},{{2,1},{9,2},{1}}}
--
-- See Also:
--     vslice

global function project(sequence vectors, sequence coords) -- currently in sets.e
	sequence result,current_vector,coord_set,result_item,projection
	integer current_index

	result=vectors
	for i=1 to length(vectors) do
		current_vector=vectors[i]
		result_item=coords
		for j=1 to length(coords) do
			coord_set=coords[j]
			projection=coord_set
			for k=1 to length(coord_set) do
				current_index=coord_set[k]
				if current_index<1 or current_index>length(current_vector) then
					crash("Invalid coordinate %d in set #%d for vector #%d",
					  {coord_set[k],j,i})
				end if
				projection[k]=current_vector[current_index]
			end for
			result_item[j]=projection
		end for
		result[i]=result_item
	end for
	return result
end function
--**

--**
-- Retrieves an element nested arbitrarily deep into a sequence.
--
-- Example 1:
-- x = fetch({0,1,2,3,{"abc","def","ghi"},6},{5,2,3})
-- -- x is 'f', or 102.
--
-- See Also:
--     store, Sequence Assignments

global function fetch(sequence s, sequence indexes)
	for i=1 to length(indexes)-1 do
		s=s[indexes[i]]
	end for
	return s[indexes[$]]
end function
--**

--**
-- Stores something at a location nested arbitrarily deep into a sequence.
--
-- Example 1:
-- s = store({0,1,2,3,{"abc","def","ghi"},6},{5,2,3},108)
-- -- s is {0,1,2,3,{"abc","del","ghi"},6}
--
-- See Also:
--     fetch, Sequence Assignments

global function store(sequence s, sequence indexes, object x)
	sequence partials,result,branch

	partials=repeat(s,length(indexes)-1)
	branch=s
	for i=1 to length(indexes)-1 do
		branch=branch[indexes[i]]
		partials[i]=branch
	end for
	branch[indexes[$]]=x
	partials=prepend(partials,0) -- avoids computing temp=i+1 a few times
	for i=length(indexes)-1 to 2 by -1 do
		result=partials[i]
		result[indexes[i]]=branch
		branch=result
	end for
	s[indexes[1]]=branch
	return s
end function
--**

--**
-- Checks whether s[x] makes sense. Returns 1 if so, else 0.
--
-- Example 1:
-- i = valid_index({51,27,33,14},2)
-- -- i is 1
--
-- See Also:
--     Sequence Assignments

global function valid_index(sequence s, object x)
	if sequence(x) or x<1 then
		return 0
	else
		return x<length(s)+1
	end if
end function
--**

--**
-- Turbs a sequences of indexes into the sequence of elements in source that have such indexes.
--
-- Example 1:
-- s = extract({11,13,15,17},{3,1,2,1,4})
-- -- s is {15,11,13,11,17}
--
-- See Also:
--     slice

global function extract(sequence source, sequence indexes)
	object p

	for i=1 to length(indexes) do
		p=indexes[i]
		if not valid_index(source,p) then
			crash("%s is not a valid index on the input sequence",{sprint(p)})
		end if
		indexes[i]=source[p]
	end for
	return indexes
end function
--**

--**
-- Rotates a slice of a sequence to the left.
--
-- If the shift is negative, a rotation to the right will be performed instead.
--
-- Example 1:
-- s = rotate_left({11,13,15,17,19,23},2,5,1)
-- -- s is {11,15,17,19,13,23}
--
-- s = rotate_left({11,13,15,17,19,23},2,5,-1)
-- -- s is {11,19,13,15,17,23}
--
-- See Also:
--     slice

global function rotate_left(sequence source, integer start, integer stop, integer left_shift)
	sequence shifted
	integer len

	if start >= stop or length(source)=0 then
		return source
	end if
	if not valid_index(source,start) or not valid_index(source,stop) then
		crash("sequence:rotate_left(): invalid slice specification",0)
	end if
	len = stop - start + 1
	left_shift = remainder(left_shift, len)
	if left_shift<0 then -- convert right shift to left shift
		left_shift += len
	end if
	shifted = source[start..start+left_shift-1]
	source[start..stop-left_shift] = source[start+left_shift..stop]
	source[stop-left_shift+1..stop] = shifted
	return source
end function
--**

