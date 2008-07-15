-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Sequence Manipulation
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>

include error.e
include search.e
include text.e
include sort.e

--****
-- === Constants

--****	
-- === Routines
--

--**
-- Signature:
-- global function append(sequence target, object x)
--
-- Description:
-- Adds an object as the last element of a sequence.
--
-- Parameters:
--		# ##source##: the sequence to add to
--      # ##x##: the object to add
--
-- Returns:
-- 		A **sequence** whose first elements are those of ##target## and whose last element is ##x##.
--
-- Comments:
--
-- The length of the resulting sequence will be ##length(target) + 1##, no matter what ##x## is.
--
-- If ##x## is an atom this is equivalent to ##result = target & x##. If ##x## is a sequence it is
-- not equivalent.
--
-- The extra storage is allocated automatically and very efficiently with Euphoria's dynamic 
-- storage allocation. The case where ##target## itself is append()ed to (as in
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
--     [[:prepend]], [[:&]]

--**
-- Signature:
-- global function prepend(sequence target, object x)
--
-- Description:
-- Adds an object as the first element of a sequence.
--
-- Parameters:
--		# ##source##: the sequence to add to
--      # ##x##: the object to add
--
-- Returns:
-- 		A **sequence** whose last elements are those of ##target## and whose first element is ##x##.
--
-- Comments:
-- The length of the returned sequence will be ##length(target) + 1## always.
--
-- If ##x## is an atom this is the same as ##result = x & target##. If ##x## is a sequence it is not the same.
--
-- The case where ##target## itself is prepend()ed to is handled very efficiently.
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
--     [[:append]], [[:&]]

--**
-- Signature:
-- global function repeat(object item, atom count)
--
-- Description:
-- Create a sequence whose all elements are identical, with given length.
--
-- Parameters:
--		# ##item##: an object, to which all elements of the result will be equal
--		# ##count##: the requested length of the result sequence
--
-- Returns:
--		A **sequence** of length ##count## each element of which is ##item##.
--
-- Comments:
-- When you repeat() a sequence or a floating-point number the
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
--     [[:repeat_pattern]], [[:linear]]

--**
-- Signature:
-- global function length(sequence target)
--
-- Description:
-- Return the length of a sequence.
--
-- Parameters:
--		# ##target##: the sequence being queried
--
-- Returns:
--		An **integer**, the number of elements ##target## has.
--
-- Comments:
-- The length of each sequence is stored internally by the
-- interpreter for quick access. In other languages this
-- operation requires a search through memory for an end marker.
--
-- Example 1:
-- <eucode>
-- length({{1,2}, {3,4}, {5,6}})   -- 3
-- length("")	 -- 0
-- length({})	 -- 0
-- </eucode>
--
-- See Also:
--     [[:append]], [[:prepend]], [[:&]]


--**
-- Signature:
--   global function insert(sequence target, object what, integer index)
--
-- Description:
--   Insert an object into a sequence as a new element at a given location.
--
--- Parameters:
--		# ##target##: the sequence to insert into
--		# ##what##: the object to insert
--		# ##index##: an integer, the position in ##target## where ##what## should appear
--
-- Returns:
--		A **sequence**, which is ##target## with one more element at ##index##, which is ##what##.
--
-- Comments:
-- ##target## can be a sequence of any shape, and ##what## any kind of object.
--
-- The length of the returned sequence is ##length(target)+1## always.
--
-- insert()ing a sequence into a string returns a sequence which is no longer a string.
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
--     [[:remove]], [[:splice]], [[:append]], [[:prepend]]

--**
-- Signature:
--   global function splice(sequence target, object what, integer index)
--
-- Description:
-- Inserts an object as a new slice in a sequence at a given position.
--
-- Parameters:
--		# ##target##: the sequence to insert into
--		# ##what##: the object to insert
--		# ##index##: an integer, the position in ##target## where ##what## should appear
--
-- Returns:
--		A **sequence**, which is ##target## with one or more elements, those of ##what##, inserted at locations starting at ##index##.
--
-- Comments:
-- ##target## can be a sequence of any shape, and ##what## any kind of object.
--
-- The length of this new sequence is the sum of the lengths of ##target## and ##what##
-- (atoms are of length 1 for this purpose). ##splice##() is equivalent to [[:insert]]() when ##what## is
--   an atom, but not when it is a sequence.
--
-- Splicing a string into a string results into a new string.
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
--     [[:insert]], [[:remove]], [[:replace]], [[:&]]

--**
-- Reverse the order of elements in a sequence.
--
-- Parameters:
--		# ##target##: the sequence to reverse.
--		# ##pFrom##: an integer, the starting point. Defaults to 1.
--		# ##pTo##: an integer, the end point. Defaults to 0.
--
-- Returns:
--		A **sequence** if ##target## is a sequence, the same length as ##target## and the same elements, but those with index between ##pFrom## and ##pTo## appear in reverse order.
--
-- Comments:
-- In the result sequence, some or all top-level elements appear in reverse order compared
-- to the original sequence. This does not reverse any sub-sequences found in the original
-- sequence.\\
-- The ##pTo## parameter can be negative, which indicates an offset from the last element.
-- Thus {{{-1}}} means the second-last element and {{{0}}} means the last element.
--
-- Example 1:
-- <eucode>
-- reverse({1,3,5,7})          -- {7,5,3,1}
-- reverse({1,3,5,7,9}, 2, -1) -- {1,7,5,3,9}
-- reverse({1,3,5,7,9}, 2)     -- {1,9,7,5,3}
-- reverse({{1,2,3}, {4,5,6}}) -- {{4,5,6}, {1,2,3}}
-- reverse({99})               -- {99}
-- reverse({})                 -- {}
-- reverse(42)                 -- 42
-- </eucode>

export function reverse(object target, integer pFrom = 1, integer pTo = 0)
	integer uppr, n, lLimit
	sequence t

	if atom(target) or length(target) < 2 then
		return target
	end if
	
	n = length(target)
	if pFrom < 1 then
		pFrom = 1
	end if
	if pTo < 1 then
		pTo = n + pTo
	end if
	if pTo < pFrom or pFrom >= n then
		return target
	end if
	if pTo > n then
		pTo = n
	end if
	
	lLimit = floor((pFrom+pTo-1)/2)
	t = target
	uppr = pTo
	for lowr = pFrom to lLimit do
		t[uppr] = target[lowr]
		t[lowr] = target[uppr]
		uppr -= 1
	end for
	return t
end function

--**
-- Return the first items of a sequence.
--
-- Parameters:
--		# ##source##: the sequence from which elements will be returned
--		# ##size##: an integer, how many head elements at most will be returned. Defaults to 1.
--
-- Returns:
--		A **sequence**, ##source## if its length is not greater than ##size##, or the ##size## first elements of ##source## otherwise.
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
--     [[:tail]], [[:mid]], [[:slice]]

export function head(sequence source, integer size=1)
	if size < length(source) then
		return source[1..size]
	end if

	return source
end function

--**
-- Returns a slice of a sequence, given by a starting point and a length.
--
-- Parameters:
--		# ##source##: the sequence some elements of which will be returned
--		# ##start##: an integer, the lower index of the slice to return
--		# ##len##: an integer, the length of the slice to return
--
-- Returns:
--		A **sequence**, made of at most ##len## elements of ##source##. These elements are at contiguous positions in ##source## starting at ##start##.
--
-- Errors:
-- If ##len## is less than ##-length(source)##, an error occurs.
--
-- Comments:
-- ##len## may be negative, in which case it is added ##length(source)## once.
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
--     [[:head]], [[:tail]], [[:slice]]

export function mid(sequence source, atom start, atom len)
	if len<0 then
		len += length(source)
		if len<0 then
			crash("mid(): len was %d and should be greater than %d.",
				{len-length(source),-length(source)})
		end if
	end if
	if start > length(source) or len=0 then
		return ""
	end if
	if start<1 then
		start=1
	end if
	if start+len-1 >= length(source) then
		return source[start..$]
	else
		return source[start..len+start-1]
	end if
end function

--**
-- Return a slice from a sequence, after adjusting its bounds.
--
-- Parameters:
--		# ##source##: the sequence from which to get a slice
--		# ##start##: an integer, normally the lower index of the slice to return
--		# ##stop##: an integer, normally the upper index of the slice to return
--
-- Returns:
--		A **sequence**, as close as possible from ##source[start..stop]]##.
--
-- Comments:
-- ##start## is set to 1 if below.
--
-- ##stop## is added ##length(source)## once if not positive, and set to ##length(source)## if above.
--
-- After these adjustments, and if ##source[start..stop]## makes sense, it is returned. Otherwise, ##{}## is returned.
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
--   [[:head]], [[:mid]], [[:tail]]

export function slice(sequence source, atom start, atom stop)
	if stop <= 0 then stop += length(source) end if
	if start < 1 then start = 1 end if
	if stop > length(source) then stop = length(source) end if
	if start > stop then return "" end if

	return source[start..stop]
end function

--**
-- Perform a vertical slice on a nested sequence
--
-- Parameters:
--		# ##source##: the sequence to take a vertical slice from
--		# ##colno##: an atom, the column number to extract (rounded down)
--		# ##error_control##: an object which says what to do if some element does not exist. Defaults to 0 (crash in such a circumstance).
--
-- Returns:
--		A **sequence**, usually of the same length as ##source##, made of all the ##source[x][colno]##.
--
-- Errors:
-- If an element is not defined and ##error_control## is 0, an error occurs.
-- If ##colno## is less than 1, it cannot be any valid column, and an error occurs.
--
-- Comments:
-- If it is not possible to return the sequence of all ##source[x][colno]]## for all available ##x##, the outcome is decided by ##error_control##:
-- * If 0 (the default), program is aborted.
-- * If a nonzero atom, the short vertical slice is returned.
-- * Otherwise, elements of ##error_control## will be taken to make for any missing element. A short vertical slice is returned if ##error_control## is exhausted.
--
-- Example 1:
-- <eucode>
-- s = vslice({5,1}, {5,2}, {5,3}}, 2)
-- -- s is {1,2,3}
--
-- s = vslice({5,1}, {5,2}, {5,3}}, 1)
-- -- s is {5,5,5}
-- </eucode>
--
-- See Also:
--   [[:slice]], [[:project]]

export function vslice(sequence source, atom colno, object error_control=0)
	sequence ret
	integer substitutes, current_sub

	if colno < 1 then
		crash("sequence:vslice(): colno should be a valid index, but was %d",colno)
	end if

	ret = source
	if atom(error_control) then
		substitutes =-(not error_control)
	else
		substitutes = length(error_control)
		current_sub = 1
	end if

	for i = 1 to length(source) do
		if colno >= 1+length(source[i]) then
			if substitutes=-1 then
				crash("sequence:vslice(): colno should be a valid index on the %d-th element, but was %d", {i,colno})
			elsif substitutes=0 then
				return ret[1..i-1]
			else
				substitutes -= 1
				ret[i] = error_control[current_sub]
				current_sub += 1
			end if
		else
			ret[i] = source[i][colno]
		end if
	end for

	return ret
end function

--**
-- Return the last items of a sequence.
--
-- Parameters:
--   # ##source##: the sequence to get the tail of.
--   # ##size##: an integer, the number of items to return. (defaults to length(source) - 1)
--
-- Returns:
--		A **sequence** of length at most ##size##. If the length is less than ##size##, then ##source## was returned. Otherwise, the ##size## last elements of ##source## were returned.
--
-- Comments:
--   ##source## can be any type of sequence, including nested sequences.
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
--   [[:head]], [[:mid]], [[:slice]]

export function tail(sequence source, atom n=length(source) - 1)
	if n >= length(source) then
		return source
	else
		return source[$-n+1..$]
	end if
end function

--**
-- Remove an item or a range of items from a sequence.
--
-- Parameters:
--   # ##target##: the sequence to remove from.
--   # ##start##: an atom, the (starting) index at which to remove
--   # ##stop##: an atom, the index at which to stop removing (defaults to ##start##)
--
-- Returns:
-- 		A **sequence** obtained from ##target## by carving the ##start..stop## slice out of it.
-- Comments:
--   A new sequence is created. ##target## can be a string or complex sequence.
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
--   [[:replace]], [[:insert]], [[:splice]], [[:remove_all]]

export function remove(sequence target, atom start, atom stop=start)
	if stop > length(target) then
		stop = length(target)
	end if

	if start > length(target) or start > stop or stop < 0 then
		return target
	elsif start < 2 then
		if stop >= length(target) then
			return ""
		else
			return target[stop+1..$]
		end if
	elsif stop >= length(target) then
		return target[1..start-1]
	end if

	return target[1..start-1] & target[stop+1..$]
end function

--**
-- Removes all occurrences of some object from a sequence.
--
-- Parameters:
--   # ##needle##: the object to remove.
--   # ##haystack##: the sequence to remove from.
--
-- Returns:
--		A **sequence** of length at most ##length(haystack)##, and which has the same elements, without any copy of ##needle## left
--
-- Comments:
-- This function weeds elements out, not subsequences.
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
--   [[:remove]], [[:replace]]

export function remove_all(object needle, sequence haystack)
	integer ts, te, ss, se
	
	-- See if we have to anything at all.    
	se = find(needle, haystack)
	if se = 0 then
		return haystack
	end if
	
	-- Now we know there is at least one occurrence and because
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
-- Replace a slice in a sequence by an object.
--
-- Parameters:
--   # ##target##: the sequence in which replacement will be done.
--   # ##replacement##: an object, the item to replace with.
--   # ##start##: an integer, the starting index of the slice to replace.
--   # ##stop##: an integer, the stopping index of the slice to replace.
--
-- Returns:
--		A **sequence, which is made of ##target## with the ##start..stop## slice removed and replaced by ##replacement##, which is [[:splice]]()d in.
--
-- Comments:
--   A new sequence is created. ##target## can be a string or complex sequence of any shape.
--
--   To replace by just one element, enclose ##replacement## in curly braces, which will be removed at replace time.
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
--     [[:splice]], [[:remove]], [[:remove_all]]

export function replace(sequence target, object replacement, integer start, integer stop=start)
	target = remove(target, start, stop)
	return splice(target, replacement, start)
end function

--**
-- Split a sequence on some delimiters.
--
-- Parameters:
--   # ##source##: the sequence to split.
--   # ##delim##: an object, the delimiter(s) to split by.
--   # ##limit##: an integer, the maximum number of items to split. Default is 0 (no limit)
--
-- Returns:
--		A **sequence** of subsequences of ##source##. Delimiters are removed.
--
-- Comments:
-- This function may be applied to a string sequence or a complex sequence
--
-- If ##limit## is > 0, the number of tokens that will be split is capped by ##limit##. Otherwise there is no limit.
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
-- See Also:
--     [[:split_any]], [[:chunk]], [[:join]]

export function split(sequence st, object delim=" ", integer limit=0)
	sequence ret = {}
	integer start = 1, pos, next_pos

	if atom(delim) then
		delim = {delim}
	end if

	while 1 do
		pos = match_from(delim, st, start)
		next_pos = pos+length(delim)

		if pos then
			ret = append(ret, st[start..pos-1])
			start = next_pos
			limit -= 1
			if limit = 0 then
				exit
			end if
		else
			exit
		end if
	end while

	ret = append(ret, st[start..$])

	return ret
end function

--**
-- Split a sequence by any item in a list of delimiters.
--
-- If limit is > 0 then limit the number of tokens that will be split to limit.
--
-- Parameters:
-- # ##source##: the sequence to split.
-- # ##delim##: a list of delimiters to split by.
-- # ##limit##: maximum number of items to split.
--
-- Comments:
-- This function may be applied to a string sequence or a complex sequence. It works like ##split##(), but splits on any delimiter on ##delim## rather than on a single delimiter.
--
-- You cannot split by any substring in a list.
--
-- Example 1:
-- <eucode>
-- result = split("One,Two|Three.Four", ".,|")
-- -- result is {"One", "Two", "Three", "Four"}
-- </eucode>
--
-- See Also:
--   [[:split]], [[:chunk]], [[:join]]

export function split_any(sequence source, object delim, integer limit=0)
	sequence ret = {}
	integer start = 1, pos, next_pos

	if atom(delim) then
		delim = {delim}
	end if

	while 1 do
		pos = find_any(delim, source, start)
		next_pos = pos + 1
		if pos then
			ret = append(ret, source[start..pos-1])
			start = next_pos
			limit -= 1
			if limit = 0 then
				exit
			end if
		else
			exit
		end if
	end while

	ret = append(ret, source[start..$])

	return ret
end function

--**
-- Join sequences together using a delimiter.
--
-- Parameters:
--   # ##items##: the sequence of items to join.
--   # ##delim##: an object, the delimiter to join by. Defaults to " ".
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
--     [[:split]], [[:split_any]], [[:chunk]]

export function join(sequence items, object delim=" ")
	object ret

	if not length(items) then return {} end if

	ret = {}
	for i=1 to length(items)-1 do
		ret &= items[i] & delim
	end for

	ret &= items[$]

	return ret
end function

--**
-- Pad the beginning of a sequence with an object so as to meet a minimum length condition.
--
-- Parameters:
--   # ##target##: the sequence to pad.
--   # ##size##: an integer, the target minimum size for ##target##
--   # ##padding##: an object, usually the character to pad to (defaults to ' ').
--
-- Returns:
--		A **sequence**, either ##target## if it was long enough, or a sequence of length ##size## whose last elements are those of ##target## and whose first few head elements all equal ##padding##.
--
-- Comments:
--   ##pad_head##() will not remove characters. If ##length(target)## is greater than ##size##, this
--   function simply returns ##target##. See [[:head]]() if you wish to truncate long sequences.
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
--   [[:trim_head]], [[:pad_tail]], [[:head]]

export function pad_head(sequence target, integer size, object ch=' ')
	if size <= length(target) then
		return target
	end if

	return repeat(ch, size - length(target)) & target
end function

--**
-- Pad the end of a sequence with an object so as to meet a minimum length condition.
--
-- Parameters:
--   # ##target##: the sequence to pad.
--   # ##size##: an integer, the target minimum size for ##target##
--   # ##padding##: an object, usually the character to pad to (defaults to ' ').
--
-- Returns:
--		A **sequence**, either ##target## if it was long enough, or a sequence of length ##size## whose first elements are those of ##target## and whose last few head elements all equal ##padding##.
--
-- Comments:
--   ##pad_tail##() will not remove characters. If ##length(target)## is greater than ##size##, this
--   function simply returns ##target##. See [[:tail]]() if you wish to truncate long sequences.
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
--   [[:trim_tail]], [[:pad_head]], [[:tail]]

export function pad_tail(sequence target, integer size, object ch=' ')
	if size <= length(target) then
		return target
	end if

	return target & repeat(ch, size - length(target))
end function

--**
-- Split a sequence into multiple sequences of a given length.
--
-- Parameters:
-- 		# ##source##: the sequence to split up
--		# ##size##: an integer, the hunk size in the results.
--
-- Returns:
--		A **sequence** of sequences. The inner sequences have length ##size##, except possibly the last one, which may be shorter. When concatenated, these inner sequences yield ##source## back.
--
-- Comments:
--   The very last inner sequence in the returned value has [[:remainder]](##length(source),size##) items if the length of ##source## is not evenly  divisible by ##size##.
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
--   [[:split]]

export function chunk(sequence source, integer size)
	sequence ns
	integer stop

	ns = {}

	for i = 1 to length(source) by size do
		stop = i + size - 1
		if stop > length(source) then
			stop = length(source)
		end if

		ns = append(ns, source[i..stop])
	end for

	return ns
end function

--**
-- Remove all nesting from a sequence.
--
-- Parameters:
--		# ##s##: the sequence to flatten up.
--
-- Returns:
--		A **sequence** of atoms, all the atoms in ##s## enumerated.
--
-- Comments:
--	If you consider a sequence as a tree, then the enumeration is performed by left-right reading of the tree. The elements are simply read left to right, without any care for braces.
--
-- Example 1:
-- <eucode>
-- s = flatten({{18, 19}, 45, {18.4, 29.3}})
-- -- s is {18, 19, 45, 18.4, 29.3}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = flatten({18,{ 19, {45}}, {18.4, {}, 29.3}})
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

--**
-- Checks whether two objects can be legally added together.
--
-- Parameters:
--		# ##a##: one of the objects to test for compatible shape
--		# ##b##: the other object
--
-- Returns:
--		An **integer**, 1 if an addition (or any [[:binary operation]]) is possible between ##a## and ##b##, else 0.
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
--     [[:linear]]

export function can_add(object a, object b)
	if atom(a) or atom(b) then
		return 1
	end if
	if length(a)!=length(b) then
		return 0
	end if
	for i=1 to length(a) do
		if not can_add(a[i], b[i]) then
			return 0
		end if
	end for
	return 1
end function

--**
-- Returns a sequence in arithmetic progression.
--
-- Parameters:
--		# ##start##: the initial value from which to start
--		# ##increment##: the value to recursively add to ##start## to get new elements
--		# ##count##:  an integer, the number of additions to perform.
--
-- Returns:
--		An **object**, either 0 on failure or ##
--{start, start+increment,...,start+count*increment}##
--
-- Comments:
-- If ##count## is negative, or if adding ##start## to  ##increment## would prove to be impossible, then 0 is returned. Otherwise, a sequence, of length ##count+1##, staring with ##start## and whose adjacent elements differ exactly by ##increment##, is returned.
--
-- Example 1:
-- <eucode>
-- s = linear({1,2,3},4,3)
-- -- s is {{1,2,3},{5,6,7},{9,10,11}}
-- </eucode>
--
-- See Also:
--     [[:repeat_pattern]]

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
-- Returns a periodic sequence, given a pattern and a count.
--
-- Parameters:
--		# ##pattern##: the sequence whose elements are to be repeated
--		# ##count##: an integer, the number of times the pattern is to be repeated.
--
-- Returns:
--		A **sequence**, empty on failure, and of length ##count*length(pattern)## otherwise. The first elements of the returned sequence are those of #pattern##. So are those that follow, on to the end.
--
-- Example 1:
-- <eucode>
-- s = repeat_pattern({1,2,5},3)
-- -- s is {1,2,5,1,2,5,1,2,5}
-- </eucode>
--
-- See Also:
--   [[:repeat]], [[:linear]]

export function repeat_pattern(sequence pattern, integer count)
	integer ls
	sequence result

	if count<=0 then
		return {}
	end if
	ls = length(pattern)
	count *= ls
	result=repeat(0,count)
	for i=1 to count by ls do
		result[i..i+ls-1] = pattern
	end for
	return result
end function

--**
-- Extracts subvectors from vectors, and returns a list of requested subvectors by vector.
--
-- Parameters:
--		# ##vectors##: a sequence of sequences of objects. Subsequences will be extracted from the inner sequences.
--		# ##coords##: q list of coordinate index lists, ie a sequence of sequences of small positive integers.
--
-- Returns:
--		A **sequence** the length of ##vectors##. Each of its elements is a sequence,
-- the length of ##coords##, of sequences. Each innermost sequence is made of the
-- coordinates of the vector whose indexes are on the given coordinate list.
--
-- Comments:
--	Another way to describe the output is as follows. For each vector in ##vectors##, and for each coordinate set in ##coords##, the vector is projected on those coordinates. The results are arranged by vector.
--
-- Example 1:
-- <eucode>
-- s = project({{1,-1,-1,0},{2,1,9}},{{1,2},{3,1},{2}})
-- -- s is {{{2,-1},{-1,2},{-1}},{{2,1},{9,2},{1}}}
-- </eucode>
--
-- See Also:
--   [[:vslice]]

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
-- Parameters:
--		# ##source##: the sequence from which to fetch
--		# ##indexes##: a sequence of integers, th path to follow to reach the element to return.
--
-- Returns:
--		An **object**, which is ##source[indexes[1]][indexes[2]]...[indexes[$]]##
--
-- Errors:
--		If the path cannot be followed to its end, an error about reading an inexistent element, or subscripting an atom, will occur.
--
-- Comments:
-- The last element of ##indexes## may be a pair {lower,upper}, in which case a slice of the innermostly referenced sequence is returned.
--
-- Example 1:
-- <eucode>
-- x = fetch({0,1,2,3,{"abc","def","ghi"},6},{5,2,3})
-- -- x is 'f', or 102.
-- </eucode>
--
-- See Also:
--   [[:store]], [[:Sequence Assignments]]

export function fetch(sequence source, sequence indexes)
	object x

	for i=1 to length(indexes)-1 do
		source = source[indexes[i]]
	end for
	x = indexes[$]
	if atom(x) then
		return source[x]
	else
		return source[x[1]..x[2]]
	end if
end function

--**
-- Stores something at a location nested arbitrarily deep into a sequence.
--
-- Parameters:
--		# ##target##: the sequence in which to store something
--		# ##indexes##: a sequence of integers, the path to follow to reach the place where to store
--		# ##x##: the object to store.
--
-- Returns:
--		A **sequence**, a **copy** of ##target## with the specified place ##indexes## modified by storing ##x## into it.
--
-- Errors:
--		If the path to storage location cannot be followed to its end, or an index is not what one would expect or is not valid, an error about illegal sequence operations will occur.
--
-- Comments:
-- If the last element of ##indexes## is a pair of integers, ##x## will be stored as a slice thee, the bounding indexes being given in the pair as {lower,upper}..
--
-- In Euphoria, you can never modify an object by passing it to a routine. You have to get a modified copy and then assign it back to the original.
--
-- Example 1:
-- <eucode>
-- s = store({0,1,2,3,{"abc","def","ghi"},6},{5,2,3},108)
-- -- s is {0,1,2,3,{"abc","del","ghi"},6}
-- </eucode>
--
-- See Also:
--     [[:fetch]], [[:Sequence Assignments]]

export function store(sequence target, sequence indexes, object x)
	sequence partials,result,branch
	object last_idx

	partials = repeat(target,length(indexes)-1)
	branch = target
	for i=1 to length(indexes)-1 do
		branch=branch[indexes[i]]
		partials[i]=branch
	end for

	last_idx = indexes[$]
	if atom(last_idx) then
		branch[last_idx]=x
	else
		branch[last_idx[1]..last_idx[2]]=x
	end if

	partials = prepend(partials,0) -- avoids computing temp=i+1 a few times

	for i=length(indexes)-1 to 2 by -1 do
		result = partials[i]
		result[indexes[i]] = branch
		branch = result
	end for
	target[indexes[1]] = branch
	return target
end function

--**
-- Checks whether an index exists on a sequence.
--
-- Parameters:
--		# ##s##: the sequence for which to check
--		# ##x##: an object, the index to check.
--
-- Returns:
-- 		An **integer**, 1 if ##s[x]## makes sense, else 0.
--
-- Example 1:
-- <eucode>
-- i = valid_index({51,27,33,14},2)
-- -- i is 1
-- </eucode>
--
-- See Also:
--     [[:Sequence Assignments]]

export function valid_index(sequence st, object x)
	if sequence(x) then
		return 0
	end if
	if x < 1 then
		return 0
	end if
	return x < length(st)+1
end function

--**
-- Turns a sequences of indexes into the sequence of elements in a source that have such indexes.
--
-- Parameters:
--		# ##source##: the sequence from which to extract elements
--		# ##indexes##: a sequence of atoms, the indexes of the elements to be fetched in ##source##.
--
-- Returns:
--		A **sequence** of length at most ##length(indexes)##. If ##p## is the r-th element of ##indexes## which is valid on ##source##, then ##result[r]## is ##source[p]##.
--
-- Example 1:
-- <eucode>
-- s = extract({11,13,15,17},{3,1,2,1,4})
-- -- s is {15,11,13,11,17}
-- </eucode>
--
-- See Also:
--     [[:slice]]

export function extract(sequence source, sequence indexes)
	object p

	for i=1 to length(indexes) do
		p=indexes[i]
		if not valid_index(source,p) then
			crash("%d is not a valid index on the input sequence",p)
		end if
		indexes[i]=source[p]
	end for
	return indexes
end function

--**
export constant
	ROTATE_LEFT  = 1,
	ROTATE_RIGHT = -1

--**
-- Rotates a slice of a sequence.
--
-- Parameters:
-- # ##source##: sequence to be rotated
-- # ##shift##: direction and count to be shifted (##ROTATE_LEFT## or ##ROTATE_RIGHT##)
-- # ##start##: starting position for shift, defaults o 1
-- # ##stop##: stopping position for shift, defaults to ##length(source)##
--
-- Comments:
-- Use ##amount * direction## to specify the shift. direction is either ##ROTATE_LEFT##
-- or ##ROTATE_RIGHT##. This enables to shift multiple places in a single call. For instance,
-- use {{{ROTATE_LEFT * 5}}} to rotate left, 5
--   positions.
--
-- A null shift does nothing and returns source unchanged.
--
-- Example 1:
-- <eucode>
-- s = rotate({1, 2, 3, 4, 5}, ROTATE_LEFT)
-- -- s is {2, 3, 4, 5, 1}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = rotate({1, 2, 3, 4, 5}, ROTATE_RIGHT * 2)
-- -- s is {4, 5, 1, 2, 3}
-- </eucode>
--
-- Example 3:
-- <eucode>
-- s = rotate({11,13,15,17,19,23}, ROTATE_LEFT, 2, 5)
-- -- s is {11,15,17,19,13,23}
-- </eucode>
--
-- Example 4:
-- <eucode>
-- s = rotate({11,13,15,17,19,23}, ROTATE_RIGHT, 2, 5)
-- -- s is {11,19,13,15,17,23}
-- </eucode>
--
-- See Also:
-- [[:slice]], [[:head]], [[:tail]]

export function rotate(sequence source, integer shift, integer start=1, integer stop=length(source))
	sequence shifted
	integer len
	integer lSize

	if start >= stop or length(source)=0 or not shift then
		return source
	end if

	if not valid_index(source, start) then
		crash("sequence:rotate(): invalid 'start' parameter %d", start)
	end if

	if not valid_index(source, stop) then
		crash("sequence:rotate(): invalid 'stop' parameter %d", stop)
	end if

	len = stop - start + 1
	lSize = remainder(shift, len)
	if lSize = 0 then
		return source
	end if

	if lSize < 0 then -- convert right shift to left shift
		lSize += len
	end if

	shifted = source[start .. start + lSize-1]
	source[start .. stop - lSize] = source[start + lSize .. stop]
	source[stop - lSize + 1.. stop] = shifted
	return source
end function

--**
export enum
	ADD_PREPEND,
	ADD_APPEND,
	ADD_SORT_UP,
	ADD_SORT_DOWN

--**
-- Adds an item to the sequence if its not already there. If it already exists
-- in the list, the list is returned unchanged.
--
-- Parameters:
-- # ##needle##:   object to add.
-- # ##haystack##: sequence in which to add it to.
-- # ##order##:    an integer in the ADD_* enum, the position the way to add ##needle## to ##haystack##.
--
-- Returns:
-- 		A **sequence** which is ##haystack## with the possible addition of ##needle##. If ##pOrder## is ##ADD_SORT_UP## or ##ADD_SORT_DOWN##, then ##haystack## is sorted accordingly.
--
-- Comments:
-- The following enum is provided for specifying pOrder:
-- * ADD_PREPEND   : prepend ##needle## to ##haystack##. This is the default option.
-- * ADD_APPEND    : append ##needle## to ##haystack##.
-- * ADD_SORT_UP   : sort ##haystack## in ascending order after inserting ##needle##
-- * ADD_SORT_DOWN : sort ##haystack## in descending order after inserting ##needle##
--
-- Example 1:
-- <eucode>
-- s = add_item( 1, {3,4,2} ) -- prepend
-- -- s is {1,3,4,2}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = add_item( 1, {3,4,2}, 2 ) -- append
-- -- s is {3,4,2,1}
-- </eucode>
--
-- Example 3:
-- <eucode>
-- s = add_item( 1, {3,4,2}, 3 ) -- ascending
-- -- s is {1,2,3,4}
-- </eucode>
--
-- Example 4:
-- <eucode>
-- s = add_item( 1, {3,4,2}, 4 ) -- descending
-- -- s is {4,3,2,1}
-- </eucode>
--
-- Example 5:
-- <eucode>
-- s = add_item( 1, {3,1,4,2} )
-- -- s is {3,1,4,2} -- Item was already in list so no change.
-- </eucode>
--
-- See Also:
--   [[:remove_all]]

export function add_item(object needle, sequence haystack, integer pOrder = 1)
	if find(needle, haystack) then
		return haystack
	end if
	switch pOrder do
		case ADD_PREPEND:
			return prepend(haystack, needle)
			
		case ADD_APPEND:
			return append(haystack, needle)
			
		case ADD_SORT_UP:
			return sort(append(haystack, needle))
			
		case ADD_SORT_DOWN:
			return sort_reverse(append(haystack, needle))
			
	end switch
	
	return haystack
end function

--**
-- Returns a sequence of three sub-sequences. The sub-sequences contain
-- all the elements less than the supplied pivot value, equal to the pivot,
-- and greater than the pivot.
--
-- Parameters:
--   # ##pData##: Either an atom or a list. An atom is treated as if it is one-element sequence.
--   # ##pPivot##: An object. Default is zero.
--
-- Returns:
--   A **sequence**: { {less than pivot}, {equal to pivot}, {greater than pivot} }
--
-- Comments: 
-- ##pivot()## is used as a split up a sequence relative to a specific value.
--
-- Example 1:
--   <eucode>
--   ? pivot( {7, 2, 8.5, 6, 6, -4.8, 6, 6, 3.341, -8, "text"}, 6 ) 
--     -- Ans: {{2, -4.8, 3.341, -8}, {6, 6, 6, 6}, {7, 8.5, "text"}}
--   ? pivot( {4, 1, -4, 6, -1, -7, 9, 10} ) 
--     -- Ans: {{-4, -1, -7}, {}, {4, 1, 6, 9, 10}}
--   ? pivot( 5 ) 
--     -- Ans: {{}, {}, {5}}
--   </eucode>

export function pivot(object pData, object pPivot = 0)
	sequence lResult
	integer lPos
	
	lResult = {{}, {}, {}}
	
	if atom(pData) then
		pData = {pData}
	end if
	
	for i = 1 to length(pData) do
		lPos = compare(pData[i], pPivot) + 2
		lResult[lPos] = append(lResult[lPos], pData[i])
	end for

	return lResult
end function

--**
-- Filter a sequence based on a user comparator.
--
-- Parameters:
-- * ##source## - sequence to filter
-- * ##rid## - [[:routine_id]] of function to use as comparator
--
-- Returns:
--		A **sequence** made of the elements in ##source## which passed the test.
--
-- Comments:
-- The comparator routine must take one parameter and return an atom. The parameter type must be such that all elements of ##source## have this type. An element is retained if the comparator routine returns a nonzero value.
--
-- Example 1:
-- <eucode>
-- function gt_ten(integer a)
--     return a > 10
-- end function
--
-- s = filter({5,8,20,19,3,2}, routine_id("gt_ten"))
-- -- s is {20, 19}
-- </eucode>
--
-- See Also:
--   [[:apply]]

export function filter(sequence source, integer rid)
	sequence dest = {}

	for a = 1 to length(source) do
		if call_func(rid, {source[a]}) then
			dest &= {source[a]}
		end if
	end for

	return dest
end function

--**
-- Apply ##rid## to every element of a sequence returning a new sequence of the same size.
--
-- Parameters: 
-- * ##source## - sequence to map
-- * ##rid## - [[:routine_id]] of function to use as converter
--
-- Returns:
--		A **sequence** the length of ##source##. Each element there is the corresponding element in ##source## mapped using the routine referred to by ##rid##.
--
-- Comments:
-- The supplied routine must take one parameter. The type of this parameter must be compatible with all the elements in ##source##.
--
-- Example 1:
-- <eucode>
-- include text.e
-- s = apply({1, 2, 3, 4}, routine_id("sprint"))
-- -- s is {"1", "2", "3", "4"}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- function greeter(object o)
--     return o[1] & ", " & o[2] & "!"
-- end function
--
-- s = apply({{"Hello", "John"}, {"Goodbye", "John"}}, routine_id("greeter"))
-- -- s is {"Hello, John!", "Goodbye, John!"}
-- </eucode>
--
-- See Also:
--   [[:filter]]

export function apply(sequence source, integer rid)
	for a = 1 to length(source) do
		source[a] = call_func(rid, {source[a]})
	end for
	return source
end function

