-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Sequence Manipulation
-- **Page Contents**
--
-- <<LEVELTOC level=4>>

include machine.e
include search.e

--****
-- === Routines
--

--**
-- Signature:
-- global function append(sequence s1, object x)
--
-- Description:
-- Return a new sequence identical to ##s1## but with ##x## added on the end as the last element. 
-- The resulting length will be ##length(s1) + 1##.
--
-- Comments:
-- If ##x## is an atom this is equivalent to ##s2 = s1 & x##. If ##x## is a sequence it is
-- not equivalent.
--
-- The extra storage is allocated automatically and very efficiently with Euphoria's dynamic 
-- storage allocation. The case where ##s1## and ##s2## are actually the same variable (as in 
-- Example 1 below) is highly optimized.
--
-- Example 1:
--   <eucode>
--   sequence x
--
--   x = {}
--   for i = 1 to 10 do
--	     x = append(x, i)
--   end for
--   -- x is now {1,2,3,4,5,6,7,8,9,10}
--   </eucode>
--
-- Example 2:
-- <eucode>
-- sequence x, y, z
--
-- x = {"fred", "barney"}
-- y = append(x, "wilma")
-- -- y is now {"fred", "barney", "wilma"}
--
-- z = append(append(y, "betty"), {"bam", "bam"})
-- -- z is now {"fred", "barney", "wilma", "betty", {"bam", "bam"}}
-- </eucode>
--
-- See Also:
--     prepend, &

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
-- <eucode>
-- prepend({1,2,3}, {0,0})	 -- {{0,0}, 1, 2, 3}
-- -- Compare with concatenation:
-- {0,0} & {1,2,3}			 -- {0, 0, 1, 2, 3}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = {}
-- for i = 1 to 10 do
--	   s = prepend(s, i)
-- end for
-- -- s is {10,9,8,7,6,5,4,3,2,1}
-- </eucode>
--
-- See Also:
--     append, &

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
-- <eucode>
-- repeat(0, 10)	  -- {0,0,0,0,0,0,0,0,0,0}
--
-- repeat("JOHN", 4)  -- {"JOHN", "JOHN", "JOHN", "JOHN"}
-- -- The interpreter will create only one copy of "JOHN"
-- -- in memory
-- </eucode>
--
-- See Also:
--     repeat_pattern, linear

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
-- <eucode>
-- length({{1,2}, {3,4}, {5,6}})   -- 3
-- length("")	 -- 0
-- length({})	 -- 0
-- </eucode>
--
-- See Also:
--     append, prepend, &

--**
-- Signature:
-- global function sprintf(sequence st, object x)
--
-- Description:
-- This is exactly the same as printf(), except that the output is returned as a sequence 
-- of characters, rather than being sent to a file or device. st is a format string, ##x##
-- is the value or sequence of values to be formatted. ##printf(fn, st, x)## is equivalent 
-- to ##puts(fn, sprintf(st, x))##.
--
-- Comments:
-- Some typical uses of ##sprintf()## are:
--
-- # Converting numbers to strings.
-- # Creating strings to pass to system().
-- # Creating formatted error messages that can be passed to a common error message handler.
--
-- Example 1: 	
-- <eucode>
-- s = sprintf("%08d", 12345)
-- -- s is "00012345"
-- </eucode>
--
-- See Also:
--     misc:printf, sprint

--**
-- Signature:
--   global function insert(sequence st, object what, integer index)
--
-- Desiption:
--   Insert what into st at index index as a new element. The item is inserted before index, 
--   not after. 
--
-- Comments:
--   A new sequence is created. st and what can be any type of sequence, including nested 
--   sequences. What is inserted as a new element in st, so that the length of the new 
--   sequence is always length(st)+1.
--
--   insert()ing a sequence into a string returns a sequence which is no longer a string.
--
-- Example 1:
-- <eucode>
-- s = insert("John Doe", " Middle", 5)
-- -- s is {'J','o','h','n'," Middle ",'D','o','e'}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = insert({10,30,40}, 20, 2)
-- -- s is {10,20,30,40}
-- </eucode>
--
-- See Also:
--     remove, splice, remove_all

--**
-- Signature:
--   global function splice(sequence st, object what, integer index)
--
-- Insert what into st at index. The item is inserted before index, not after. 
-- What is inserted as a subsequence. splicing a string into another yields a new string.
--
-- Parameters:
--   * st - sequence to splice into.
--   * what - what to split into st.
--   * index - index position at which to splice.
--
-- Comments:
--   A new sequence is created. st and what can be any type of sequence, including nested 
--   sequences. The length of this new sequence is the sum of the lengths of st and what 
--   (atoms are of length 1 for this purpose). splice() is equivalent to insert() when x is 
--   an atom.
--
-- Example 1:
-- <eucode>
-- s = splice("John Doe", " Middle", 5)
-- -- s is "John Middle Doe"
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = splice({10,30,40}, 20, 2)
-- -- s is {10,20,30,40}
-- </eucode>
--
-- See Also:
--     insert, remove, replace, remove_all

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
-- <eucode>
-- s = sprint(12345)
-- -- s is "12345"
-- </eucode>
--
-- Example 2: 	
-- <eucode>
-- s = sprint({10,20,30}+5)
-- -- s is "{15,25,35}"
-- </eucode>
--
-- See Also:
--    sprintf, misc:printf

export function sprint(object x)
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
-- Reverse the order of elements in a sequence.
--
-- Comments:
-- A new sequence is created where the top-level elements appear in reverse order compared 
-- to the original sequence.
--
-- Example 1:
-- <eucode>
-- reverse({1,3,5,7})		   -- {7,5,3,1}
-- reverse({{1,2,3}, {4,5,6}}) -- {{4,5,6}, {1,2,3}}
-- reverse({99})			   -- {99}
-- reverse({})				   -- {}
-- </eucode>

export function reverse(sequence s)
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
-- Return the first size items of st. If size is greater than the length of st, then the 
-- entire st will be returned.
--
-- Example 1:
-- <eucode>
-- s2 = head("John Doe", 4)
-- -- s2 is John
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s2 = head("John Doe", 50)
-- -- s2 is John Doe
-- </eucode>
--
-- Example 3:
-- <eucode>
-- s2 = head({1, 5.4, "John", 30}, 3)
-- -- s2 is {1, 5.4, "John"}
-- </eucode>
--
-- See Also:
--     tail, mid, slice

export function head(sequence st, integer size=1)
	if size < length(st) then
		return st[1..size]
	end if

	return st
end function

--**
-- Return len items starting at start. If start + len is greater than the length of st, 
-- then everything in st starting at start will be returned.
--
-- Example 1:
-- <eucode>
-- s2 = mid("John Middle Doe", 6, 6)
-- -- s2 is Middle
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s2 = mid("John Middle Doe", 6, 50)
-- -- s2 is Middle Doe
-- </eucode>
--
-- Example 3:
-- <eucode>
-- s2 = mid({1, 5.4, "John", 30}, 2, 2)
-- -- s2 is {5.4, "John"}
-- </eucode>
--
-- See Also:
--     head, tail, slice

export function mid(sequence st, atom start, atom len)
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
-- Return items start to stop from st. If stop is greater than the length of st, then from 
-- start to the end of st will be returned. If stop is zero, it will be treated as the end 
-- of st. If stop is a negative value, then it will be treated as stop positions from the 
-- end of st.
--
-- Example 1:
-- <eucode>
-- s2 = slice("John Doe", 6, 8)
-- -- s2 is Doe
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s2 = slice("John Doe", 6, 50)
-- -- s2 is Doe
-- </eucode>
--
-- Example 3:
-- <eucode>
-- s2 = slice({1, 5.4, "John", 30}, 2, 3)
-- -- s2 is {5.4, "John"}
-- </eucode>
--
-- Example 4:
-- <eucode>
-- s2 = slice({1,2,3,4,5}, 2, -1)
-- -- s2 is {2,3,4}
-- </eucode>
--
-- Example 5:
-- <eucode>
-- s2 = slice({1,2,3,4,5}, 2, 0)
-- -- s2 is {2,3,4,5}
-- </eucode>
--
-- See Also:
--   head, mid, tail

export function slice(sequence st, atom start, atom stop)
	if stop < 0 then stop = length(st) + stop end if
	if stop = 0 then stop = length(st) end if
	if start < 1 then start = 1 end if
	if stop > length(st) then stop = length(st) end if
	if start > stop then return "" end if

	return st[start..stop]
end function

--**
-- Perform a vertical slice on a nested sequence
--
-- Example 1:
-- <eucode>
-- s = vsplice({5,1}, {5,2}, {5,3}}, 2)
-- -- s is {1,2,3}

-- s = vsplice({5,1}, {5,2}, {5,3}}, 1)
-- -- s is {5,5,5}
-- </eucode>
--
-- See Also:
--     slice, project

export function vslice(sequence s, atom colno)
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
-- Return the last n items of st. If n is greater than the length of st, then the entire st 
-- will be returned.
--
-- Parameters:
--   * st - sequence to get tail of.
--   * n - number of items to return. (defaults to length(st) - 1)
--
-- Comments:
--   A new sequence is created.
--
--   st can be any type of sequence, including nested sequences.
--
-- Example 1:
-- <eucode>
-- s2 = tail("John Doe", 3)
-- -- s2 is Doe
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s2 = tail("John Doe", 50)
-- -- s2 is John Doe
-- </eucode>
--
-- Example 3:
-- <eucode>
-- s2 = tail({1, 5.4, "John", 30}, 3)
-- -- s2 is {5.4, "John", 30}
-- </eucode>
--
-- See Also:
--   head, mid, slice

export function tail(sequence st, atom n=length(st) - 1)
	if n >= length(st) then
		return st
	else
		return st[$-n+1..$]
	end if
end function

--**
-- Remove an item or a range of items from st.
--
-- Parameters:
--   * st - sequence in which to remove from.
--   * start - index at which to remove (or starting index to remove)
--   * stop - index at which to stop remove (defaults to start)
--
-- Comments:
--   A new sequence is created. st can be a string or complex sequence.
--
-- Example 1:
-- <eucode>
-- s = remove("Johnn Doe", 4)
-- -- s is "John Doe"
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = remove({1,2,3,3,4}, 4)
-- -- s is {1,2,3,4}
-- </eucode>
--
-- Example 3:
-- <eucode>
-- s = remove("John Middle Doe", 6, 12)
-- -- s is "John Doe"
-- </eucode>
--
-- Example 4:
-- <eucode>
-- s = remove({1,2,3,3,4,4}, 4, 5)
-- -- s is {1,2,3,4}
-- </eucode>
--
-- See Also:
--   replace, insert, splice, remove_all

export function remove(sequence st, atom start, atom stop=start)
	if stop > length(st) then
		stop = length(st)
	end if

	if start > length(st) or start > stop or stop < 0 then
		return st
	elsif start < 2 then
		if stop >= length(st) then
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
-- Removes all ocurrences of needle from haystack
--
-- Parameters:
--   * needle - object to remove.
--   * haystack - sequence in which to remove from.
--
-- Example 1:
-- <eucode>
-- s = remove_all( 1, {1,2,4,1,3,2,4,1,2,3} )
-- -- s is {2,4,3,2,4,2,3}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = remove_all("x", "I'm toox secxksy for my shixrt.")
-- -- s is "I'm too secksy for my shirt."
-- </eucode>
--
-- See Also:
--   remove

export function remove_all(object needle, sequence haystack)
	integer ts, te, ss, se
	
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
-- Replace from index start to stop of st with object what. what can be any object.
--
-- Parameters:
--   * st - sequence in which replacement will be done.
--   * replacement - item to replace with.
--   * start - starting index.
--   * stop - stopping index.
--
-- Comments:
--   A new sequence is created. st can be a string or complex sequence.
--
--   To replace just one element, simply: s[index] = new_item
--
-- Example 1:
-- <eucode>
-- s = replace("John Middle Doe", "Smith", 6, 11)
-- -- s is "John Smith Doe"
--
-- s = replace({45.3, "John", 5, {10, 20}}, 25, 2, 3)
-- -- s is {45.3, 25, {10, 20}}
-- </eucode>
--
-- See Also:
--     splice, remove, remove_all

export function replace(sequence st, object replacement, integer start, integer stop)
	st = remove(st, start, stop)
	return splice(st, replacement, start)
end function

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
--   * st - sequence to split.
--   * delim - delimiter to split by.
--   * limit - maximum number of items to split.
--   * any - split by any atom in delim (1) or delim as a whole (0).
--
-- Comments:
-- This function may be applied to a string sequence or a complex sequence
--
-- Example 1:
-- <eucode>
-- result = split("John Middle Doe")
-- -- result is {"John", "Middle", "Doe"}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- result = split("John,Middle,Doe", ",", 2)
-- -- result is {"John", "Middle,Doe"}
-- </eucode>
--
-- Example 3:
-- <eucode>
-- result = split("One,Two|Three.Four", ".,|", 0, 1)
-- -- result is {"One", "Two", "Three", "Four"}
-- </eucode>
--
-- See Also:
--     chunk

export function split(sequence st, object delim=" ", integer limit=0, integer any=0)
	sequence ret = {}
	integer start = 1, pos, next_pos

	if atom(delim) then
		delim = {delim}
	end if

	while 1 do
		if any then
			pos = find_any(delim, st, start)
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
-- Join s by delim
--
-- Parameters:
--   * s - sequence of items to join.
--   * delim - delimiter to join by.
--
-- Comments:
--   This function may be applied to a string sequence or a complex sequence
--
-- Example 1:
-- <eucode>
-- result = join({"John", "Middle", "Doe"})
-- -- result is "John Middle Doe"
-- </eucode>
--
-- Example 2:
-- <eucode>
-- result = join({"John", "Middle", "Doe"}, ",")
-- -- result is "John,Middle,Doe"
-- </eucode>
--
-- See Also:
--     split

export function join(sequence s, object delim=" ")
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
-- Trim any item in what from the head (start) of str
--
-- Parameters:
--   * str - string to trim.
--   * what - what to trim (defaults to " \t\r\n").
--
-- Example 1:
-- <eucode>
-- s = trim_head("\r\nSentence read from a file\r\n", "\r\n")
-- -- s is "Sentence read from a file\r\n"
-- </eucode>
--
-- See Also:
--   trim_tail, trim, pad_head

export function trim_head(sequence str, object what=" \t\r\n")
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
-- Trim any item in what from the end (tail) of str
--
-- Parameters:
--   * str - string to trim.
--   * what - what to trim (defaults to " \t\r\n").
--
-- Example 1:
-- <eucode>
-- s = trim_head("\r\nSentence read from a file\r\n", "\r\n")
-- -- s is "\r\nSentence read from a file"
-- </eucode>
--
-- See Also:
--   trim_head, trim, pad_tail

export function trim_tail(sequence str, object what=" \t\r\n")
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
-- Trim any item in what from the head (start) and tail (end) of str
--
-- Parameters:
--   * str - string to trim.
--   * what - what to trim (defaults to " \t\r\n").
--
-- Example 1:
-- <eucode>
-- s = trim("\r\nSentence read from a file\r\n", "\r\n")
-- -- s is "Sentence read from a file"
-- </eucode>
--
-- See Also:
--   trim_head, trim_tail

export function trim(sequence str, object what=" \t\r\n")
	return trim_tail(trim_head(str, what), what)
end function

--**
-- Pad the beginning of a sequence with ch up to size in length.
--
-- Parameters:
--   * str - string to pad.
--   * size - size to pad str to.
--   * ch - character to pad to (defaults to ' ').
--
-- Comments:
--   pad_head() will not remove characters. If length(str) is greater than params, this
--   function simply returns str. See head() if you wish to truncate long sequences.
--
-- Example 1:
-- <eucode>
-- s = pad_head("ABC", 6)
-- -- s is "   ABC"
--
-- s = pad_head("ABC", {6, '-'})
-- -- s is "---ABC"
-- </eucode>
--
-- See Also:
--   trim_head, pad_tail, head

export function pad_head(sequence str, integer size, object ch=' ')
	if size <= length(str) then
		return str
	end if

	return repeat(ch, size - length(str)) & str
end function

--**
-- Pad the end of a sequence with ch up to size in length.
--
-- Parameters:
--   * str - string to pad.
--   * size - size to pad 'str' to.
--   * ch - character to pad to (defaults to ' ').
--
-- Comments:
--   pad_tail() will not remove characters. If length(str) is greater than params, this
--   function simply returns str. see tail() if you wish to truncate long sequences.
--
-- Example 1:
-- <eucode>
-- s = pad_tail("ABC", 6)
-- -- s is "ABC   "
--
-- s = pad_tail("ABC", {6, '-'})
-- -- s is "ABC---"
-- </eucode>
--
-- See Also:
--   trim_tail, pad_head, tail

export function pad_tail(sequence str, integer size, object ch=' ')
	if size <= length(str) then
		return str
	end if

	return str & repeat(ch, size - length(str))
end function

--**
-- Split s1 into multiple sequences of length size
--
-- Comments:
--   The very last sequence might not have size items if the length of s is not evenly 
--   divisible by size.
--
-- Example 1:
-- <eucode>
-- s = chunk("5545112133234454", 4)
-- -- s is {"5545", "1121", "3323", "4454"}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = chunk("12345", 2)
-- -- s is {"12", "34", "5"}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = chunk({1,2,3,4,5,6}, 3)
-- -- s is {{1,2,3}, {4,5,6}}
-- </eucode>
--
-- See Also:
--   split

export function chunk(sequence s, integer size)
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
-- Remove all nesting from a sequence
--
-- Example 1:
-- <eucode>
-- s = flatten({{18, 19}, 45, {18.4, 29.3}})
-- -- s is {18, 19, 45, 18.4, 29.3}
-- </eucode>

export function flatten(sequence s)
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

constant TO_LOWER = 'a' - 'A'

--**
-- Convert an atom or sequence to lower case. Only alters characters in the 'A'..'Z' range.
--
-- Example 1:
-- <eucode>
-- s = lower("Euphoria")
-- -- s is "euphoria"
--
-- a = lower('B')
-- -- a is 'b'
--
-- s = lower({"Euphoria", "Programming"})
-- -- s is {"euphoria", "programming"}
-- </eucode>
--
-- See Also:
--   upper

export function lower(object x)
-- convert atom or sequence to lower case
	return x + (x >= 'A' and x <= 'Z') * TO_LOWER
end function

--**
-- Convert an atom or sequence to upper case. Only alters characters in the 'a'..'z' range.
--
-- Example 1:
-- <eucode>
-- s = upper("Euphoria")
-- -- s is "EUPHORIA"
--
-- a = upper('b')
-- -- a is 'B'
--
-- s = upper({"Euphoria", "Programming"})
-- -- s is {"EUPHORIA", "PROGRAMMING"}
-- </eucode>
--
-- See Also:
--     lower

export function upper(object x)
-- convert atom or sequence to upper case
	return x - (x >= 'a' and x <= 'z') * TO_LOWER
end function

--**
-- Checks whether two objects can be legally added together. Returns 1 if so, else 0.
--
-- Example 1:
-- <eucode>
-- i = can_add({1,2,3},{4,5})
-- -- i is 0
--
-- i = can_add({1,2,3},4)
-- -- i is 1
--
-- i = can_add({1,2,3},{4,{5,6},7})
-- -- i is 1
-- </eucode>
--
-- See Also:
--     linear

export function can_add(object a, object b)
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
-- Returns a sequence {start, start+increment,...,start+(count-1)*increment, or 0 on failure.
--
-- Example 1:
-- <eucode>
-- s = linear({1,2,3},4,3)
-- -- s is {{1,2,3},{5,6,7},{9,10,11}}
-- </eucode>
--
-- See Also:
--     repeat_pattern

export function linear(object start, object increment, integer count)
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
-- Returns a sequence whose n first elements are those of s, as well a the n that follow, 
-- and so on for count copies.
--
-- Example 1:
-- <eucode>
-- s = repeat_pattern({1,2,5},3)
-- -- s is {1,2,5,1,2,5,1,2,5}
-- </eucode>
--
-- See Also:
--   repeat, linear

export function repeat_pattern(sequence s, integer count)
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
-- <eucode>
-- s = project({{1,-1,-1,0},{2,1,9}},{{1,2},{3,1},{2}})
-- -- s is {{{2,-1},{-1,2},{-1}},{{2,1},{9,2},{1}}}
-- </eucode>
--
-- See Also:
--   vslice

export function project(sequence vectors, sequence coords)
	sequence result, current_vector, coord_set, result_item, projection
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
-- Retrieves an element nested arbitrarily deep into a sequence.
--
-- Example 1:
-- <eucode>
-- x = fetch({0,1,2,3,{"abc","def","ghi"},6},{5,2,3})
-- -- x is 'f', or 102.
-- </eucode>
--
-- See Also:
--   store, Sequence Assignments

export function fetch(sequence s, sequence indexes)
	for i=1 to length(indexes)-1 do
		s=s[indexes[i]]
	end for
	return s[indexes[$]]
end function

--**
-- Stores something at a location nested arbitrarily deep into a sequence.
--
-- Example 1:
-- <eucode>
-- s = store({0,1,2,3,{"abc","def","ghi"},6},{5,2,3},108)
-- -- s is {0,1,2,3,{"abc","del","ghi"},6}
-- </eucode>
--
-- See Also:
--     fetch, Sequence Assignments

export function store(sequence s, sequence indexes, object x)
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
-- Checks whether s[x] makes sense. Returns 1 if so, else 0.
--
-- Example 1:
-- <eucode>
-- i = valid_index({51,27,33,14},2)
-- -- i is 1
-- </eucode>
--
-- See Also:
--     Sequence Assignments

export function valid_index(sequence s, object x)
	if sequence(x) or x<1 then
		return 0
	else
		return x<length(s)+1
	end if
end function

--**
-- Turns a sequences of indexes into the sequence of elements in source that have such indexes.
--
-- Example 1:
-- <eucode>
-- s = extract({11,13,15,17},{3,1,2,1,4})
-- -- s is {15,11,13,11,17}
-- </eucode>
--
-- See Also:
--     slice

export function extract(sequence source, sequence indexes)
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
-- Rotates a slice of a sequence to the left.
--
-- If the shift is negative, a rotation to the right will be performed instead.
--
-- Example 1:
-- <eucode>
-- s = rotate_left({11,13,15,17,19,23},2,5,1)
-- -- s is {11,15,17,19,13,23}
--
-- s = rotate_left({11,13,15,17,19,23},2,5,-1)
-- -- s is {11,19,13,15,17,23}
-- </eucode>
--
-- See Also:
--     slice

export function rotate_left(sequence source, integer start, integer stop, integer left_shift)
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
-- Converts a string containing Key/Value pairs into a set of 
-- sequences, one per K/V pair.
--
-- By default, pairs can be delimited by either a comma or semi-colon ",;" and
-- a key is delimited from its value by either an equal or a colon "=:". 
-- Whitespace between pairs, and between delimiters is ignored.
--
-- By default, each value must have a key and if you don't supply one, the
-- routine generates a key in the format "p[<n>]" where <n> is the count of
-- K/V pairs so far processed. See example #2.
--
-- If you need to have one of the delimiters in the value data, enclose it in
-- quotation marks. You can use any of single, double and back quotes, which 
-- also means you can quote quotation marks themselves. See example #3.
--
-- It is possible that the value data itself is a nested set of pairs. To do
-- this enclose the value in parentheses. Nested sets can nested to any level.
-- See example #4.
--
-- If a sublist has only data values and not keys, enclose it in either braces
-- or square brackets. See example #5.
-- If you need to have a bracket as the first character in a data value, prefix
-- it with a tilde. Actually a leading tilde will always just be stripped off
-- regardless of what it prefixes. See example #6.
--
-- Example 1:
-- <eucode>
-- s = keyvalues("foo=bar, qwe=1234, asdf='contains space, comma, and equal(=)'")
-- -- s is { {"foo", "bar"}, {"qwe", "1234"}, {"asdf", "contains space, comma, and equal(=)"}}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = keyvalues("abc fgh=ijk def")
-- -- s is { {"p[1]", "abc"}, {"fgh", "ijk"}, {"p[3]", "def"} }
-- </eucode>
--
-- Example 3:
-- <eucode>
-- s = keyvalues("abc=`'quoted'`")
-- -- s is { {"abc", "'quoted'"} }
-- </eucode>
--
-- Example 4:
-- <eucode>
-- s = keyvalues("colors=(a=black, b=blue, c=red)")
-- -- s is { {"colors", {{"a", "black"}, {"b", "blue"},{"c", "red"}}  } }
-- s = keyvalues("colors=(black=[0,0,0], blue=[0,0,FF], red=[FF,0,0])")
-- -- s is { {"colors", {{"black",{"0", "0", "0"}}, {"blue",{"0", "0", "FF"}},{"red", {"FF","0","0"}}}} }
-- </eucode>
--
-- Example 5:
-- <eucode>
-- s = keyvalues("colors=[black, blue, red]")
-- -- s is { {"colors", { "black", "blue", "red"}  } }
-- </eucode>
--
-- Example 6:
-- <eucode>
-- s = keyvalues("colors=~[black, blue, red]")
-- -- s is { {"colors", "[black, blue, red]"}  } }
-- -- The following is another way to do the same.
-- s = keyvalues("colors=`[black, blue, red]`")
-- -- s is { {"colors", "[black, blue, red]"}  } }
-- </eucode>

export function keyvalues(sequence source, object pair_delim = ";,", 
                          object kv_delim = ":=", object quotes =  "\"'`", 
                          object whitespace = " \t\n\r", integer haskeys = 1)
                          
	sequence lKeyValues
	sequence lValue
	sequence lKey
	sequence lAllDelim
	sequence lWhitePair
	sequence lStartBracket
	sequence lEndBracket
	sequence lBracketed
	integer lQuote
	integer lPos
	integer lChar
	integer lBPos

	source = trim(source)
	if length(source) = 0 then
		return {}
	end if
	
	if atom(pair_delim) then
		pair_delim = {pair_delim}
	end if		
	if atom(kv_delim) then
		kv_delim = {kv_delim}
	end if		
	if atom(quotes) then
		quotes = {quotes}
	end if		
	if atom(whitespace) then
		whitespace = {whitespace}
	end if		
	
	lAllDelim = whitespace & pair_delim & kv_delim
	lWhitePair = whitespace & pair_delim
	lStartBracket = "{[("
	lEndBracket   = "}])"
	
	lKeyValues = {}
	lPos = 1
	while lPos <= length(source) do
		-- ignore leading whitespace
		while lPos < length(source) do
			if find(source[lPos], whitespace) = 0 then
				exit
			end if
			lPos +=1 
		end while
		
		-- Get key. Ends at any of unquoted whitespace or unquoted delimiter
		lKey = ""
		lQuote = 0
		lChar = 0
		if haskeys then
			while lPos <= length(source) do
				lChar = source[lPos]
				if find(lChar, quotes) != 0 then
					if lChar = lQuote then
						-- End of quoted span
						lQuote = 0
						lChar = -1
					elsif lQuote = 0 then
						-- Start of quoted span
						lQuote = lChar
						lChar = -1
					end if
									
				elsif lQuote = 0 and find(lChar, lAllDelim) != 0 then
					exit
					
				end if
				if lChar > 0 then
					lKey &= lChar			
				end if
				lPos += 1
			end while
			
			-- ignore next whitespace
			if find(lChar, whitespace) != 0 then
				lPos += 1
				while lPos <= length(source) do
					lChar = source[lPos]
					if find(lChar, whitespace) = 0 then
						exit
					end if
					lPos +=1 
				end while
			end if
		else
			lPos -= 1	-- Put back the last char.
		end if
						
		lValue = ""
		if find(lChar, kv_delim) != 0  or not haskeys then
		
			-- ignore next whitespace
			lPos += 1
			while lPos <= length(source) do
				lChar = source[lPos]
				if find(lChar, whitespace) = 0 then
					exit
				end if
				lPos +=1 
			end while
			
			-- Get value. Ends at any of unquoted whitespace or unquoted delimiter
			lQuote = 0
			lChar = 0
			lBracketed = {}
			while lPos <= length(source) do
				lChar = source[lPos]
				if length(lBracketed) = 0 and find(lChar, quotes) != 0 then
					if lChar = lQuote then
						-- End of quoted span
						lQuote = 0
						lChar = -1		
					elsif lQuote = 0 then
						-- Start of quoted span
						lQuote = lChar
						lChar = -1		
					end if
				elsif find(lChar, lStartBracket) > 0 then
					lBPos = find(lChar, lStartBracket)
					lBracketed &= lEndBracket[lBPos]
				
				elsif length(lValue) = 1 and lValue[1] = '~' and find(lChar, lStartBracket) > 0 then
					lBPos = find(lChar, lStartBracket)
					lBracketed &= lEndBracket[lBPos]
				
				elsif length(lBracketed) != 0 and lChar = lBracketed[$] then
					lBracketed = lBracketed[1..$-1]
					
				elsif length(lBracketed) = 0 and lQuote = 0 and find(lChar, lWhitePair) != 0 then
					exit
					
				end if
				
				if lChar > 0 then
					lValue &= lChar			
				end if
				lPos += 1
			end while
			
			if find(lChar, whitespace) != 0  then			
				-- ignore next whitespace
				lPos += 1
				while lPos <= length(source) do
					lChar = source[lPos]
					if find(lChar, whitespace) = 0 then
						exit
					end if
					lPos +=1 
				end while
			end if
			
			if find(lChar, pair_delim) != 0  then
				lPos += 1
				if lPos <= length(source) then
					lChar = source[lPos]
				end if
			end if
		end if

		if find(lChar, pair_delim) != 0  then
			lPos += 1
		end if
		
		if length(lValue) = 0 then
			if length(lKey) = 0 then
				lKeyValues = append(lKeyValues, {})
				continue
			end if

			lValue = lKey
			lKey = ""
		end if
		
		if length(lKey) = 0 then
			if haskeys then			
				lKey =  sprintf("p[%d]", length(lKeyValues) + 1)
			end if
		end if
		
		lChar = lValue[1]
		lBPos = find(lChar, lStartBracket)
		if lBPos > 0 and lValue[$] = lEndBracket[lBPos] then
			if lChar = '(' then
				lValue = keyvalues(lValue[2..$-1], pair_delim, kv_delim, quotes, whitespace, haskeys)
			else
				lValue = keyvalues(lValue[2..$-1], pair_delim, kv_delim, quotes, whitespace, 0)
			end if
		elsif lChar = '~' then	
			lValue = lValue[2 .. $]
		end if
		if length(lKey) = 0 then
			lKeyValues = append(lKeyValues, lValue)
		else
			lKeyValues = append(lKeyValues, {lKey, lValue})
		end if
		
	end while
		
	return lKeyValues
end function
