--****
-- == Searching
--
-- <<LEVELTOC level=2 depth=4>>

namespace search

include std/types.e

--****
-- === Equality
--

--****
-- Signature:
--   <built-in> function compare(object compared, object reference)
--
-- Description:
--     compares two items returning less than, equal or greater than.
--
-- Parameters:
--		# ##compared## : the compared object
--		# ##reference## : the reference object
--
-- Returns:
--     An **integer**,
--	*  0 ~-- if objects are identical
--	*  1 ~-- if ##compared## is greater than ##reference##
--	* -1 ~-- if ##compared## is less than ##reference##
--
-- Comments:
--     Atoms are considered to be less than sequences. Sequences are compared alphabetically 
--     starting with the first element until a difference is found or one of the sequences is exhausted. Atoms are compared as ordinary reals.
--
-- Example 1:
-- <eucode>
-- x = compare({1,2,{3,{4}},5}, {2-1,1+1,{3,{4}},6-1})
-- -- identical, x is 0
-- </eucode>
-- 
-- Example 2:
-- <eucode>
-- if compare("ABC", "ABCD") < 0 then   -- -1
--     -- will be true: ABC is "less" because it is shorter
-- end if
-- </eucode>
--
-- Example 3:
-- <eucode>
-- x = compare('a', "a")
-- -- x will be -1 because 'a' is an atom
-- -- while "a" is a sequence
-- </eucode>
--
-- See Also:
--     [[:equal]], [[:relational operators]], [[:operations on sequences]], [[:sort]]

--****
-- Signature:
--     <built-in> function equal(object left, object right)
--
-- Description:
--     compares two Euphoria objects to see if they are the same. 
--
-- Parameters:
--			# ##left## : one of the objects to test
--			# ##right## : the other object
--
-- Returns:
--   An **integer**, 1 if the two objects are identical, else 0.
--
-- Comments:
--     This is equivalent to the expression: ##compare(left, right) = 0##.
--
--     This routine, like most other built-in routines, is very fast. It does not have any
--     subroutine call overhead.
--
-- Example 1:
-- <eucode>
-- if equal(PI, 3.14) then
--     puts(1, "give me a better value for PI!\n")
-- end if
-- </eucode>
--
-- Example 2:
-- <eucode>
-- if equal(name, "George") or equal(name, "GEORGE") then
--    puts(1, "name is George\n")
-- end if
-- </eucode>
--
-- See Also:
--     [[:compare]]

--****
-- === Finding
--

--****
-- Signature:
--     <built-in> function find(object needle, sequence haystack, integer start)
--
-- Description:
--     finds the first occurrence of a "needle" as an element of a "haystack", starting from position "start".
--
-- Parameters:
--		# ##needle## : an object whose presence is being queried
--		# ##haystack## : a sequence, which is being looked up for ##needle##
--		# ##start## : an integer, the position at which to start searching. Defaults to 1.
--
-- Returns:
--     An **integer**, 0 if ##needle## is not on ##haystack##, else the smallest index of an 
-- element of ##haystack## that equals ##needle##.
--
-- Example 1:
-- <eucode>
-- location = find(11, {5, 8, 11, 2, 3})
-- -- location is set to 3
-- </eucode>
--
-- Example 2:
-- <eucode>
-- names = {"fred", "rob", "george", "mary", ""}
-- location = find("mary", names)
-- -- location is set to 4
-- </eucode>
--
-- See Also:
--     [[:find]], [[:match]], [[:compare]]

--****
-- Signature:
--     <built-in> function find_from(object needle, object haystack, integer start)
--
-- Deprecated:
--  Deprecated since version 4.0.0
--
--  In Euphoria 4.0.0 we have the ability to default parameters to procedures and functions.
--  The built-in [[:find]] therefore now has a ##start## parameter that is defaulted to the
--  beginning of the sequence. Thus, [[:find]] can perform the identical functionality
--  provided by ##find_from##. In an undetermined future release of Euphoria, ##find_from##
--  will be removed.
--

--**
-- finds any element from a list inside a sequence. Returns the location of the first hit.
--
-- Parameters:
--		# ##needles## : a sequence, the list of items to look for
--		# ##haystack## : a sequence, in which "needles" are looked for
--		# ##start## : an integer, the starting point of the search. Defaults to 1.
--
-- Returns:
--		An **integer**, the smallest index in ##haystack## of an element of ##needles##, or 0 if no needle is found.
--
-- Comments:
--   This function may be applied to a string sequence or a complex
--   sequence.
--
-- Example 1:
--   <eucode>
--   location = find_any("aeiou", "John Smith", 3)
--   -- location is 8
--   </eucode>
--
-- Example 2:
--   <eucode>
--   location = find_any("aeiou", "John Doe")
--   -- location is 2
--   </eucode>
--
-- See Also:
--		[[:find]]

public function find_any(object needles, sequence haystack, integer start=1)
	if atom(needles) then
		needles = {needles}
	end if
	for i = start to length(haystack) do
		if find(haystack[i],needles) then
			return i
		end if
	end for

	return 0
end function

--**
-- determines if any element from ##needles## is in ##haystack##.
--
-- Parameters:
--		# ##needles## : a sequence, the list of items to look for
--		# ##haystack## : a sequence, in which "needles" are looked for
--		# ##start## : an integer, the starting point of the search. Defaults to 1.
--
-- Returns:
--		An **integer**, 0 if no matches, 1 if any matches.
--
-- Comments:
--   This function may be applied to a string sequence or a complex
--   sequence.
--   An empty needles sequence will always result in 0.
--
-- Example 1:
--   <eucode>
--   ok = match_any("aeiou", "John Smith")
--   -- okay is 1
--   ok = match_any("xyz", "John Smith" )
--   -- okay is 0
--   </eucode>
--
-- See Also:
--		[[:find_any]]

public function match_any(sequence needles, sequence haystack, integer start=1)
	for i = start to length(haystack) do
		if find(haystack[i],needles) then
			return 1
		end if
	end for

	return 0
end function

--**
-- finds all instances of any element from the needle sequence that occur in the
-- haystack sequence. Returns a list of indexes.
--
-- Parameters:
--		# ##needles## : a sequence, the list of items to look for
--		# ##haystack## : a sequence, in which "needles" are looked for
--		# ##start## : an integer, the starting point of the search. Defaults to 1.
--
-- Returns:
--		A **sequence**, the list of indexes into ##haystack## that point to an
-- element that is also in ##needles##.
--
-- Comments:
--   This function may be applied to a string sequence or a complex
--   sequence.
--
-- Example 1:
--   <eucode>
--   location = find_each("aeiou", "John Smith", 3)
--   -- location is {8}
--   </eucode>
--
-- Example 2:
--   <eucode>
--   location = find_each("aeiou", "John Doe")
--   -- location is {2,7,8}
--   </eucode>
--
-- See Also:
--		[[:find]], [[:find_any]]

public function find_each(sequence needles, sequence haystack, integer start=1)
	integer kx = 0
		
	for i = start to length(haystack) do
		if find(haystack[i],needles) then
			kx += 1
			haystack[kx] = i
		end if
	end for
	
	haystack = remove( haystack, kx+1, length( haystack ) )
	return haystack
end function

--**
-- finds all occurrences of an object inside a sequence, starting at some specified point.
--
-- Parameters:
--     # ##needle## : an object, what to look for
--     # ##haystack## : a sequence to search in
--     # ##start## : an integer, the starting index position (defaults to 1)
--
-- Returns:
--		A **sequence**, the list of all indexes no less than ##start## of elements of ##haystack## that equal ##needle##. This sequence is empty if no match found.
--
-- Example 1:
-- <eucode>
-- s = find_all('A', "ABCABAB")
-- -- s is {1,4,6}
-- </eucode>
--
-- See Also:
--     [[:find]], [[:match]], [[:match_all]]

public function find_all(object needle, sequence haystack, integer start=1)
	integer kx = 0
	while start with entry do
		kx += 1
		haystack[kx] = start
		start += 1
	entry
		start = find(needle, haystack, start)
	end while

	haystack = remove( haystack, kx+1, length( haystack ) )
	return haystack
end function

--**
-- finds all non-occurrences of an object inside a sequence, starting at some specified point.
--
-- Parameters:
--     # ##needle## : an object, what to look for
--     # ##haystack## : a sequence to search in
--     # ##start## : an integer, the starting index position (defaults to 1)
--
-- Returns:
--	A **sequence**, the list of all indexes no less than ##start## of elements
--  of ##haystack## that not equal to ##needle##. This sequence is empty if 
--  ##haystack## only consists of ##needle##.
--
-- Example 1:
-- <eucode>
-- s = find_all_but('A', "ABCABAB")
-- -- s is {2,3,5,7}
-- </eucode>
--
-- See Also:
--     [[:find_all]], [[:match]], [[:match_all]]

public function find_all_but( object needle, sequence haystack, integer start = 1 ) 
	integer ix = start 
	integer jx 
	integer kx = 0 
	
	while jx with entry do
		-- Collect all the indexes up to the next needle
		for i = ix to jx - 1 do 
			kx += 1 
			haystack[kx] = i 
		end for 
		-- Reset the next scan point.
		ix = jx + 1 
	entry 
		-- Scan for a needle.
		jx = find( needle, haystack, ix ) 
	end while 
	
	-- Collect any trailing non-needles.
	for i = ix to length(haystack) do 
		kx += 1 
		haystack[kx] = i 
	end for 
	
	-- send back what we collected.
	haystack = remove( haystack, kx+1, length( haystack ) )
	return haystack
end function 
 

public constant
    NESTED_ANY=1,
    NESTED_ALL=2,
    NESTED_INDEX=4,
    NESTED_BACKWARD=8


--**
-- finds any object (among a list) in a sequence of arbitrary shape at arbitrary nesting.
--
-- Parameters:
--		# ##needle## : an object, either what to look up, or a list of items to look up
--		# ##haystack## : a sequence, where to look up
--		# ##flags## : options to the function, see Comments section.  Defaults to 0.
--		# ##routine## : an integer, the routine_id of an user supplied equal/find function. Defaults to  [[:types:NO_ROUTINE_ID]].
--
-- Returns:
-- A possibly empty **sequence**, of results, one for each hit.
--
-- Comments:
-- Each item in the returned sequence is either a sequence of indexes, or a pair {sequence of indexes, index in ##needle##}.
--
-- The following flags are available to fine tune the search~:
-- * ##NESTED_BACKWARD## ~--  if on ##flags##, search is performed backward. Default is forward.
-- * ##NESTED_ALL## ~-- if on ##flags##, all occurrences are looked for. Default is one hit only.
-- * ##NESTED_ANY## ~-- if present on ##flags##, ##needle## is a list of items to look for. Not the default.
-- * ##NESTED_INDEXES## ~-- if present on ##flags##, an individual result is a pair {position, index 
--   in ##needle##}. Default is just return the position.
--
-- If ##s## is a single index list, or position, from the returned sequence, then ##fetch(haystack, s) = needle##.
--
-- If a routine id is supplied, the routine must behave like [[:equal]] if the ##NESTED_ANY##
-- flag is not supplied, and like [[:find]] if it is. The routine is being passed the current
-- ##haystack## item and ##needle##. The returned integer is interpreted as if returned by
-- [[:equal]] or [[:find]].
--
-- If the ##NESTED_ANY## flag is specified, and ##needle## is an atom, then the flag is removed.
--
-- Example 1:
-- <eucode>
-- sequence s = find_nested(3, {5, {4, {3, {2}}}})
-- -- s is {2 ,2 ,1}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- sequence s = find_nested({3, 2}, {1, 3, {2,3}}, 
--                                    NESTED_ANY + NESTED_BACKWARD + NESTED_ALL)
-- -- s is {{3,2}, {3,1}, {2}}
-- </eucode>
--
-- Example 3:
-- <eucode>
-- sequence s = find_nested({3, 2}, {1, 3, {2,3}}, 
--                                     NESTED_ANY + NESTED_INDEXES + NESTED_ALL)
-- -- s is {{{2}, 1}, {{3, 1}, 2}, {{3, 2}, 1}}
-- </eucode>
--
-- See Also:
-- [[:find]], [[:rfind]], [[:find_any]], [[:fetch]]

public function find_nested(object needle, sequence haystack, integer flags=0, integer rtn_id=types:NO_ROUTINE_ID)
	sequence occurrences = {} -- accumulated results
	integer depth = 0
	sequence branches = {}, indexes = {}, last_indexes = {} -- saved states
	integer last_idx = length(haystack), current_idx = 1, direction = 1 -- assume forward searches more frequent
	object x
	integer rc, any = and_bits(flags, NESTED_ANY)
	
	if and_bits(flags,NESTED_BACKWARD) then
	    current_idx = last_idx
	    last_idx = 1
	    direction = -1
	end if
	any = any and sequence(needle)

	while 1 do -- traverse the whole haystack tree
		while eu:compare(current_idx, last_idx) != direction do
	        x = haystack[current_idx]
	        
	        -- is x what we want?
			if rtn_id = NO_ROUTINE_ID then
	         	if any then
	         		rc = find(x, needle)
	         	else
					rc = equal(x, needle)
	         	end if
	        else
		        rc = call_func(rtn_id, {x, needle})
	        end if
	        
	        if rc then
	        -- yes, it is
	            sequence info

				-- inline head() from sequence.e
				if depth < length(indexes) then
					info = indexes[1..depth] & current_idx
				else
					info = indexes & current_idx
				end if
				
	            if and_bits(flags, NESTED_INDEX) then
	               info = {info, rc}
	            end if
	            if and_bits(flags, NESTED_ALL) then
	                occurrences = append(occurrences, info)
	            else
	                return info
	            end if
	        end if
	        
	        -- either it wasn't, or we keep going
	        if eu:compare(x, {})=1 then
	        -- this is a subtree, search inside
	            -- save state
				depth += 1
	            if length(indexes) < depth then
	                indexes &= current_idx
	                branches = append(branches, haystack)
	                last_indexes &= last_idx
	            else
	                indexes[depth] = current_idx
	                branches[depth] = haystack
	                last_indexes[depth] = last_idx
	            end if
	            
	            -- set new state
	            haystack = x
	            if direction = 1 then
	                current_idx = 1
	                last_idx = length(haystack)
	            else
	                last_idx = 1
	                current_idx = length(haystack)
	            end if
	        else
	            -- next item
				current_idx += direction
	        end if
	    end while
	
	    -- return or backtrack
	    if depth=0 then
	        return occurrences -- either accumulated results, or {} if none -> ok
	    end if
	
	    -- restore state
	    haystack = branches[depth]
	    last_idx = last_indexes[depth]
	    current_idx = indexes[depth] + direction
	    depth -= 1
	end while
end function

--**
-- finds a needle in a haystack in reverse order.
--
-- Parameters:
--   # ##needle## : an object to search for
--   # ##haystack## : a sequence to search in
--   # ##start## : an integer, the starting index position (defaults to length(##haystack##))
--     
-- Returns:
--   An **integer**, 0 if no instance of ##needle## can be found on ##haystack## before
--   index ##start##, or the highest such index otherwise.
--
-- Comments: 
--
--   If ##start## is less than 1, it will be added once to length(##haystack##)
--   to designate a position counted backwards. Thus, if ##start## is -1, the
--   first element to be queried in ##haystack## will be ##haystack[$-1]##,
--   then ##haystack[$-2]## and so on.
--
-- Example 1:
-- <eucode>
-- location = rfind(11, {5, 8, 11, 2, 11, 3})
-- -- location is set to 5
-- </eucode>
--
-- Example 2:
-- <eucode>
-- names = {"fred", "rob", "rob", "george", "mary"}
-- location = rfind("rob", names)
-- -- location is set to 3
-- location = rfind("rob", names, -4)
-- -- location is set to 2
-- </eucode>
--
-- See Also:
--   [[:find]], [[:rmatch]]

public function rfind(object needle, sequence haystack, integer start=length(haystack))
	integer len = length(haystack)

	if start = 0 then start = len end if
	if (start > len) or (len + start < 1) then
		return 0
	end if

	if start < 1 then
		start = len + start
	end if

	for i = start to 1 by -1 do
		if equal(haystack[i], needle) then
			return i
		end if
	end for

	return 0
end function

--**
-- finds a ##needle## in the ##haystack##, and replaces all or upto ##max## 
-- occurrences with ##replacement##.
--
-- Parameters:
--
--		# ##needle## : an object to search and perhaps replace
--		# ##haystack## : a sequence to be inspected
--		# ##replacement## : an object to substitute for any (first) instance of ##needle##
--		# ##max## : an integer, 0 to replace all occurrences
--
-- Returns:
--		A **sequence**, the modified ##haystack##.
--
-- Comments:
-- Replacements will not be made recursively on the part of ##haystack## that was already changed.
--
-- If ##max## is 0 or less, any occurrence of ##needle## in ##haystack## will be replaced by ##replacement##. Otherwise, only the first ##max## occurrences are.
--
-- Example 1:
-- <eucode>
-- s = find_replace('b', "The batty book was all but in Canada.", 'c', 0)
-- -- s is "The catty cook was all cut in Canada."
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = find_replace('/', "/euphoria/demo/unix", '\\', 2)
-- -- s is "\\euphoria\\demo/unix"
-- </eucode>
--
-- Example 3:
-- <eucode>
-- s = find_replace("theater", { "the", "theater", "theif" }, "theatre")
-- -- s is { "the", "theatre", "theif" }
-- </eucode>
--
-- See Also:
--		[[:find]], [[:replace]], [[:match_replace]]

public function find_replace(object needle, sequence haystack, object replacement, 
			integer max=0)
	integer posn = 0

	while posn != 0 entry do 
		haystack[posn] = replacement
		max -= 1
		if max = 0 then
			exit
		end if
	entry
		posn = find(needle, haystack, posn + 1)
	end while

	return haystack
end function

--**
-- finds a "needle" in a "haystack", and replace any, or only the first few, occurrences with a replacement.
--
-- Parameters:
--
--		# ##needle## : an non-empty sequence or atom to search and perhaps replace
--		# ##haystack## : a sequence to be inspected
--		# ##replacement## : an object to substitute for any (first) instance of ##needle##
--		# ##max## : an integer, 0 to replace all occurrences
--
-- Returns:
--		A **sequence**, the modified ##haystack##.
--
-- Comments:
-- Replacements will not be made recursively on the part of ##haystack## that was already changed.
--
-- If ##max## is 0 or less, any occurrence of ##needle## in ##haystack## will be replaced by ##replacement##. Otherwise, only the first ##max## occurrences are.
--
-- If either ##needle## or ##replacement## are atoms they will be treated as if you had passed in a 
-- length-1 sequence containing the said atom. 
--
-- If ##needle## is an empty sequence, an error will be raised and your program will exit. 
--
-- Example 1:
-- <eucode>
-- s = match_replace("the", "the cat ate the food under the table", "THE", 0)
-- -- s is "THE cat ate THE food under THE table"
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = match_replace("the", "the cat ate the food under the table", "THE", 2)
-- -- s is "THE cat ate THE food under the table"
-- </eucode>
--
-- Example 3:
-- <eucode>
-- s = match_replace('/', "/euphoria/demo/unix", '\\', 2)
-- -- s is "\\euphoria\\demo/unix"
-- </eucode>
--
-- Example 4:
-- <eucode>
-- s = match_replace('a', "abracadabra", 'X')
-- -- s is now "XbrXcXdXbrX"
-- s = match_replace("ra", "abracadabra", 'X')
-- -- s is now "abXcadabX"
-- s = match_replace("a", "abracadabra", "aa")
-- -- s is now "aabraacaadaabraa"
-- s = match_replace("a", "abracadabra", "")
-- -- s is now "brcdbr"
-- </eucode>
--
-- See Also:
--		[[:find]], [[:replace]], [[:regex:find_replace]], [[:find_replace]]

public function match_replace(object needle, sequence haystack, object replacement, 
			integer max=0)
	integer posn
	integer needle_len
	integer replacement_len
	integer scan_from
	integer cnt
	
	
	if max < 0 then
		return haystack
	end if
	
	cnt = length(haystack)
	if max != 0 then
		cnt = max
	end if
	
	if atom(needle) then
		needle = {needle}
	end if
	if atom(replacement) then
		replacement = {replacement}
	end if

	needle_len = length(needle) - 1
	replacement_len = length(replacement)

	scan_from = 1
	while posn with entry do
		haystack = replace(haystack, replacement, posn, posn + needle_len)

		cnt -= 1
		if cnt = 0 then
			exit
		end if
		scan_from = posn + replacement_len
	entry
		posn = match(needle, haystack, scan_from)
	end while

	return haystack
end function

--**
-- finds a "needle" in an ordered "haystack". Start and end point can be given for the search.
--
-- Parameters:
--		# ##needle## : an object to look for
--		# ##haystack## : a sequence to search in
--		# ##start_point## : an integer, the index at which to start searching. Defaults to 1.
--		# ##end_point## : an integer, the end point of the search. Defaults to 0, ie search to end.
--
-- Returns:
--		An **integer**, either:
-- # a positive integer ##i##, which means ##haystack[i]## equals ##needle##.
-- # a negative integer, ##-i##, with ##i## between adjusted start and end
--    points. This means that ##needle## is not in the searched slice of 
--    ##haystack##, but would be at index ##i## if it were there.
-- # a negative integer ##-i## with ##i## out of the searched range. This
--   means than ##needle##might be either below the start point if ##i## 
--   is below the start point, or above the end point if ##i## is.
--
-- Comments:
-- * If ##end_point## is not greater than zero, it is added to 
--   ##length(haystack)## once only. Then, the end point of the search is
--   adjusted to ##length(haystack)## if out of bounds.
-- * The start point is adjusted to 1 if below 1.
-- * The way this function returns is very similar to what [[:db_find_key]]
--   does. They use variants of the same algorithm. The latter is all the
--   more efficient as ##haystack## is long.
-- * ##haystack## is assumed to be in ascending order. Results are undefined
--   if it is not. 
-- * If duplicate copies of ##needle## exist in the range searched on
--   ##haystack##, any of the possible contiguous indexes may be returned.
--
-- See Also:
-- [[:find]], [[:db_find_key]]

public function binary_search(object needle, sequence haystack, integer start_point = 1, 
		integer end_point = 0)
	integer lo, hi, mid, c  -- works up to 1.07 billion records
	
	lo = start_point
	if end_point <= 0 then
		hi = length(haystack) + end_point
	else
		hi = end_point
	end if
	if lo<1 then
		lo=1
	end if
	if lo > hi and length(haystack) > 0 then
		hi = length(haystack)
	end if
	mid = start_point
	c = 0
	while lo <= hi do
		mid = floor((lo + hi) / 2)
		c = eu:compare(needle, haystack[mid])
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

--****
-- === Matching
--

--****
-- Signature: 
--     <built-in> function match(sequence needle, sequence haystack, integer start)
--
-- Description:
--     tries to match a "needle" against some slice of a "haystack", starting at position "start".
--
-- Parameters:
--		# ##needle## : a sequence whose presence as a "substring" is being queried
--		# ##haystack## : a sequence, which is being looked up for ##needle## as a sub-sequence
--		# ##start## : an integer, the point from which matching is attempted. Defaults to 1.
--
-- Returns:
--     An **integer**, 0 if no slice of ##haystack## is ##needle##, else the smallest index at which such a slice starts.
--
-- Comments:
--  If ##needle## is an empty sequence, an error is raised and your program 
--  will exit.
--
-- Example 1:
-- <eucode>
-- location = match("pho", "Euphoria")
-- -- location is set to 3
-- </eucode>
--
-- See Also:
--     [[:find]], [[:compare]], [[:wildcard:is_match]]

--****
-- Signature:
--     <built-in> function match_from(sequence needle, sequence haystack, integer start)
--
-- Deprecated:
--  Deprecated since version 4.0.0
--
--  In Euphoria 4.0.0 we have the ability to default parameters to procedures and functions.
--  The built-in [[:match]] therefore now has a ##start## parameter that is defaulted to the
--  beginning of the sequence. Thus, [[:match]] can perform the identical functionality
--  provided by ##match_from##. In an undetermined future release of Euphoria, ##match_from##
--  will be removed.
--
-- Comments:
--  If ##needle## is an empty sequence, an error is raised and your program 
--  will exit.
--

--**
-- matches all items of haystack in needle.
--
-- Parameters:
--     # ##needle## : a non-empty sequence, what to look for
--     # ##haystack## : a sequence to search in
--     # ##start## : an integer, the starting index position (defaults to 1)
--
-- Returns:
--   A **sequence**, of integers, the list of all lower indexes, not less than ##start##, of all slices in ##haystack## that equal ##needle##. The list may be empty.
--
-- Comments:
--   If ##needle## is an empty sequence, an error will be raised and your program will exit.
--
-- Example 1:
-- <eucode>
-- s = match_all("the", "the dog chased the cat under the table.")
-- -- s is {1,16,30}
-- </eucode>
--
-- See Also:
--     [[:match]], [[:regex:find_all]] [[:find]], [[:find_all]]

public function match_all(sequence needle, sequence haystack, integer start=1)
	integer kx = 0

	while start > 0 with entry do
		kx += 1
		haystack[kx] = start
		start += length(needle)
	entry
		start = match(needle, haystack, start)
	end while

	haystack = remove( haystack, kx+1, length( haystack ) )
	return haystack
end function

--**
-- tries to match a needle against some slice of a haystack in reverse order.
--
-- Parameters:
--   # ##needle## : a sequence to search for
--   # ##haystack## : a sequence to search in
--   # ##start## : an integer, the starting index position (defaults to length(##haystack##))
--
-- Returns:
--   An **integer**, either 0 if no slice of ##haystack## starting before 
--   ##start## equals ##needle##, else the highest lower index of such a slice.
--
-- Comments:
--   If ##start## is less than 1, it will be added once to ##length(haystack)##
--   to designate a position counted backwards. Thus, if ##start## is -1, the
--   first element to be queried in ##haystack## will be ##haystack[$-1]##,
--   then ##haystack[$-2]## and so on.
--
--   If a ##needle## is an empty sequence this will return 0.
--
-- Example 1:
-- <eucode>
-- location = rmatch("the", "the dog ate the steak from the table.")
-- -- location is set to 28 (3rd 'the')
-- location = rmatch("the", "the dog ate the steak from the table.", -11)
-- -- location is set to 13 (2nd 'the')
-- </eucode>
--
-- See Also:
--     [[:rfind]], [[:match]]

public function rmatch(sequence needle, sequence haystack, integer start=length(haystack))
	integer len, lenX

	len = length(haystack)
	lenX = length(needle)

	if lenX = 0 then
		return 0
	elsif (start > len) or  (len + start < 1) then
		return 0
	end if

	if start < 1 then
		start = len + start
	end if

	if start + lenX - 1 > len then
		start = len - lenX + 1
	end if

	lenX -= 1

	for i=start to 1 by -1 do
		if equal(needle, haystack[i..i + lenX]) then
			return i
		end if
	end for

	return 0
end function


--**
-- tests whether a sequence is the head of another one.
-- 
-- Parameters:
--	# ##sub_text## : an object to be looked for
--  # ##full_text## : a sequence, the head of which is being inspected.
--
-- Returns:
--		An **integer**, 1 if ##sub_text## begins ##full_text##, else 0.
--
-- Comments:
--  If ##sub_text## is an empty sequence, this returns 1 unless ##full_text## 
--  is also an empty sequence.  When they are both empty sequences this returns 
--  0.
--
-- Example 1:
-- <eucode>
-- s = begins("abc", "abcdef")
-- -- s is 1
-- s = begins("bcd", "abcdef")
-- -- s is 0
-- </eucode>
--
-- See Also:
--     [[:ends]], [[:head]]

public function begins(object sub_text, sequence full_text)
	if length(full_text) = 0 then
		return 0
	end if
	
	if atom(sub_text) then
		if equal(sub_text, full_text[1]) then
			return 1
		else
			return 0
		end if
	end if
	
	if length(sub_text) > length(full_text) then
		return 0
	end if
	
	if equal(sub_text, full_text[1.. length(sub_text)]) then
		return 1
	else
		return 0
	end if
end function

--**
-- tests whether a sequence ends another one.
--
-- Parameters:
--	# ##sub_text## : an object to be looked for
--  # ##full_text## : a sequence, the tail of which is being inspected.
--
-- Returns:
--		An **integer**, 1 if ##sub_text## ends ##full_text##, else 0.
--
-- Comments:
--  If ##sub_text## is an empty sequence, this returns 1 unless ##full_text## 
--  is also an empty sequence.  When they are both empty sequences this returns 
--  0.
--
-- Example 1:
-- <eucode>
-- s = ends("def", "abcdef")
-- -- s is 1
-- s = begins("bcd", "abcdef")
-- -- s is 0
-- </eucode>
--
-- See Also:
--     [[:begins]], [[:tail]]

public function ends(object sub_text, sequence full_text)
	if length(full_text) = 0 then
		return 0
	end if
	
	if atom(sub_text) then
		if equal(sub_text, full_text[$]) then
			return 1
		else
			return 0
		end if
	end if
	
	if length(sub_text) > length(full_text) then
		return 0
	end if
	
	if equal(sub_text, full_text[$ - length(sub_text) + 1 .. $]) then
		return 1
	else
		return 0
	end if
end function

--**
-- tests to see if the ##item## is in a range of values supplied by ##range_limits##.
--
-- Parameters:
--   # ##item## : The object to test for.
--   # ##range_limits## : A sequence of two or more elements. The first is assumed
--    to be the smallest value and the last is assumed to be the highest value.
--   # ##boundries##: a sequence. This determines if the range limits are inclusive
--                    or not. Must be one of ##"[]"## (the default), ##"[)"##, ##"(]"##, or
--                    ##"()"##.
--
-- Returns:
--   An **integer**, 0 if ##item## is not in the ##range_limits## otherwise it returns 1.
--
-- Comments:
-- * In ##boundries##, square brackets mean //inclusive// and round brackets
--   mean //exclusive//. Thus ##"[]"## includes both limits in the range, while
--   ##"()"## excludes both limits. And, ##"[)"## includes the lower limit and excludes
--   the upper limits while ##"(]"## does the reverse.
--
-- Example 1:
--   <eucode>
--   if is_in_range(2, {2, 75}) then
--       procA(user_data) -- Gets run (both limits included)
--   end if
--   if is_in_range(2, {2, 75}, "(]") then
--       procA(user_data) -- Does not get run
--   end if
--   </eucode>

public function is_in_range(object item, sequence range_limits, sequence boundries = "[]")
	if length(range_limits) < 2 then
		return 0
	end if
	
	switch boundries do
		case "()" then
			if eu:compare(item, range_limits[1]) <= 0 then
				return 0
			end if
			if eu:compare(item, range_limits[$]) >= 0 then
				return 0
			end if
		
		case "[)" then
			if eu:compare(item, range_limits[1]) < 0 then
				return 0
			end if
			if eu:compare(item, range_limits[$]) >= 0 then
				return 0
			end if
		
		case "(]" then
			if eu:compare(item, range_limits[1]) <= 0 then
				return 0
			end if
			if eu:compare(item, range_limits[$]) > 0 then
				return 0
			end if
		
		case else
			if eu:compare(item, range_limits[1]) < 0 then
				return 0
			end if
			if eu:compare(item, range_limits[$]) > 0 then
				return 0
			end if
	end switch
	
	return 1
end function

--**
-- tests to see if the ##item## is in a list of values supplied by ##list##.
--
-- Parameters:
--   # ##item## : The object to test for.
--   # ##list## : A sequence of elements that ##item## could be a member of.
--
-- Returns:
--   An **integer**,  0 if ##item## is not in the ##list##, otherwise
--                  it returns 1.
--
-- Example 1:
--   <eucode>
--   if is_in_list(user_data, {100, 45, 2, 75, 121}) then
--       procA(user_data)
--   end if
--   </eucode>

public function is_in_list(object item, sequence list)
	return (find(item, list) != 0)
end function

--**
-- returns the corresponding element from the target list if
-- the supplied item is in the source list.
--
-- Parameters:
-- # ##find_item##: an object that might exist in ##source_list##.
-- # ##source_list##: a sequence that might contain ##pITem##.
-- # ##target_list##: a sequence from which the corresponding item will be returned.
-- # ##def_value##: an object (defaults to zero). This is returned when ##find_item## 
-- is not in ##source_list## **and** ##target_list## is not longer than ##source_list##.
--
-- Returns:
-- An **object**
-- * If ##find_item## is found in ##source_list## then this is the corresponding element
-- from ##target_list##
-- * If ##find_item## is not in ##source_list## then if ##target_list## is longer than ##source_list##
-- then the last item in ##target_list## is returned otherwise ##def_value## is returned.
--
-- Example 1:
-- <eucode>
-- lookup('a', "cat", "dog") --> 'o'
-- lookup('d', "cat", "dogx") --> 'x'
-- lookup('d', "cat", "dog") --> 0
-- lookup('d', "cat", "dog", -1) --> -1
-- lookup("ant", {"ant","bear","cat"}, {"spider","seal","dog","unknown"}) 
--             --> "spider"
-- lookup("dog", {"ant","bear","cat"}, {"spider","seal","dog","unknown"})     
--             --> "unknown"
-- </eucode>
--
public function lookup(object find_item, sequence source_list, sequence target_list, object def_value = 0)
    integer lPosn

    lPosn = find(find_item, source_list)
    if lPosn then
        if lPosn <= length(target_list) then
            return target_list[lPosn]
        else
        	return def_value
        end if
        
    elsif length(target_list) > length(source_list) then
    	-- Return the default built into the target list
        return target_list[$]
        
    else
    	-- Return the supplied default
    	return def_value
    end if

end function

--**
-- returns the corresponding element from the target column
-- if the supplied item is in a source grid column.
--
-- Parameters:
-- # ##find_item##: an object that might exist in ##source_col##.
-- # ##grid_data##: a 2D grid sequence that might contain ##pITem##.
-- # ##source_col##: an integer. The column number to look for ##find_item##.
-- # ##target_col##: an integer. The column number from which the corresponding
-- item will be returned.
-- # ##def_value##: an object (defaults to zero). This is returned when ##find_item## 
-- is not found in the ##source_col## column, or if found but the target column
-- does not exist.
--
-- Comments:
-- * If a row in the grid is actually a single atom, the row is ignored.
-- * If a row's length is less than the ##source_col##, the row is ignored.
--
-- Returns:
-- An **object**,
-- * If ##find_item## is found in the ##source_col## column then this is the corresponding element
-- from the ##target_col## column.
--
-- Example 1:
-- <eucode>
-- sequence grid
-- grid = {
--        {"ant", "spider", "mortein"},
--        {"bear", "seal", "gun"},
--        {"cat", "dog", "ranger"},
--        $
--  }
-- vlookup("ant", grid, 1, 2, "?") --> "spider"
-- vlookup("ant", grid, 1, 3, "?") --> "mortein"
-- vlookup("seal", grid, 2, 3, "?") --> "gun"
-- vlookup("seal", grid, 2, 1, "?") --> "bear"
-- vlookup("mouse", grid, 2, 3, "?") --> "?"
-- </eucode>
--
public function vlookup(object find_item, sequence grid_data, integer source_col, integer target_col, object def_value = 0)

    for i = 1 to length(grid_data) do
    	if atom(grid_data[i]) then
    		continue
    	end if
    	if length(grid_data[i]) < source_col then
    		continue
    	end if
    	
    	if equal(find_item, grid_data[i][source_col]) then
	    	if length(grid_data[i]) < target_col then
    			return def_value
    		end if
    		return grid_data[i][target_col]
    	end if
    end for
    
    return def_value

end function
