--****
-- == Sequence Manipulation
--
-- <<LEVELTOC level=2 depth=4>>

namespace stdseq

include std/error.e
include std/types.e
include std/search.e
include std/sort.e

--****
-- === Constants

public enum
	ADD_PREPEND,
	ADD_APPEND,
	ADD_SORT_UP,
	ADD_SORT_DOWN

public constant
	ROTATE_LEFT  = 1,
	ROTATE_RIGHT = -1

--****
-- === Basic Routines
--

--**
-- checks whether two objects can perform a sequence operation together.
--
-- Parameters:
--		# ##a## : one of the objects to test for compatible shape
--		# ##b## : the other object
--
-- Returns:
--	An **integer**, 1 if a sequence operation is valid between ##a## and ##b##, else 0.
--
-- Example 1:
-- <eucode>
-- i = binop_ok({1,2,3},{4,5})
-- -- i is 0
--
-- i = binop_ok({1,2,3},4)
-- -- i is 1
--
-- i = binop_ok({1,2,3},{4,{5,6},7})
-- -- i is 1
-- </eucode>
--
-- See Also:
--     [[:series]]

public function binop_ok(object a, object b)
	if atom(a) or atom(b) then
		return 1
	end if
	
	if length(a) != length(b) then
		return 0
	end if
	
	for i = 1 to length(a) do
		if not binop_ok(a[i], b[i]) then
			return 0
		end if
	end for
	
	return 1
end function

--**
-- retrieves an element nested arbitrarily deep into a sequence.
--
-- Parameters:
--	# ##source## : the sequence from which to fetch
--	# ##indexes## : a sequence of integers, the path to follow to reach the
--   element to return.
--
-- Returns:
--		An **object**, which is ##source[indexes[1]][indexes[2]]...[indexes[$]]##
--
-- Errors:
--	If the path cannot be followed to its end, an error about reading a
--  nonexistent element, or subscripting an atom, will occur.
--
-- Comments:
-- The last element of ##indexes## may be a pair ##{lower,upper}##, in which case
-- a slice of the innermost referenced sequence is returned.
--
-- Example 1:
-- <eucode>
-- x = fetch({0,1,2,3,{"abc","def","ghi"},6},{5,2,3})
-- -- x is 'f', or 102.
-- </eucode>
--
-- See Also:
--   [[:store]], [[:Subscripting of Sequences]]

public function fetch(sequence source, sequence indexes)
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
-- stores something at a location nested arbitrarily deep into a sequence.
--
-- Parameters:
--		# ##target## : the sequence in which to store something
--		# ##indexes## : a sequence of integers, the path to follow to reach the
--                     place where to store
--		# ##x## : the object to store.
--
-- Returns:
--		A **sequence**, a **copy** of ##target## with the specified place
--      ##indexes## modified by storing ##x## into it.
--
-- Errors:
--	If the path to storage location cannot be followed to its end, or an
--  index is not what one would expect or is not valid, an error about illegal
--  sequence operations will occur.
--
-- Comments:
-- If the last element of ##indexes## is a pair of integers, ##x## will be
-- stored as a slice three, the bounding indexes being given in the pair as ##{lower,upper}##.
--
-- In Euphoria, you can never modify an object by passing it to a routine.
-- You have to get a modified copy and then assign it back to the original.
--
-- Example 1:
-- <eucode>
-- s = store({0,1,2,3,{"abc","def","ghi"},6},{5,2,3},108)
-- -- s is {0,1,2,3,{"abc","del","ghi"},6}
-- </eucode>
--
-- See Also:
--     [[:fetch]], [[:Subscripting of Sequences]]

public function store(sequence target, sequence indexes, object x)
	sequence partials,result,branch
	object last_idx

	if length(indexes) = 1 then
		target[indexes[1]] = x
		return target
	end if

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
-- checks whether an index exists on a sequence.
--
-- Parameters:
--		# ##s## : the sequence for which to check
--		# ##x## : an object, the index to check.
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
--     [[:Subscripting of Sequences]]

public function valid_index(sequence st, object x)
	if not atom(x) then
		return 0
	end if
	if x < 1 then
		return 0
	end if
	if floor(x) > length(st) then
		return 0
	end if
	return 1
end function

--**
-- rotates a slice of a sequence.
--
-- Parameters:
-- # ##source## : sequence to be rotated
-- # ##shift## : direction and count to be shifted (##ROTATE_LEFT## or ##ROTATE_RIGHT##)
-- # ##start## : starting position for shift, defaults o 1
-- # ##stop## : stopping position for shift, defaults to ##length(source)##
--
-- Comments:
--
-- Use ##amount * direction## to specify the shift. direction is either ##ROTATE_LEFT##
-- or ##ROTATE_RIGHT##. This enables to shift multiple places in a single call.
--  For instance, use ##{{{ROTATE_LEFT * 5}}}## to rotate left, ##5##
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

public function rotate(sequence source, integer shift, integer start=1, integer stop=length(source))
	sequence shifted
	integer len
	integer lSize

	if start >= stop or length(source)=0 or not shift then
		return source
	end if

	if not valid_index(source, start) then
		error:crash("sequence:rotate(): invalid 'start' parameter %d", start)
	end if

	if not valid_index(source, stop) then
		error:crash("sequence:rotate(): invalid 'stop' parameter %d", stop)
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
-- converts a set of sub sequences into a set of "columns."
--
-- Parameters:
-- # ##source## : sequence containing the sub-sequences
-- # ##cols## : either a specific column number or a set of column numbers.
--             Default is 0, which returns the maximum number of columns.
-- # ##defval## : an object. Used when a column value is not available. Default is 0
--
-- Comments:
-- Any atoms found in ##source## are treated as if they are a 1-element sequence.
--
-- Example 1:
-- <eucode>
-- s = columnize({{1, 2}, {3, 4}, {5, 6}})
-- -- s is { {1,3,5}, {2,4,6}}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = columnize({{1, 2}, {3, 4}, {5, 6, 7}})
-- -- s is { {1,3,5}, {2,4,6}, {0,0,7} }
-- s = columnize({{1, 2}, {3, 4}, {5, 6, 7},,-999}) 
--     --> Change the not-available value.
-- -- s is { {1,3,5}, {2,4,6}, {-999,-999,7} }
-- </eucode>
--
-- Example 3:
-- <eucode>
-- s = columnize({{1, 2}, {3, 4}, {5, 6, 7}}, 2)
-- -- s is { {2,4,6} } -- Column 2 only
-- </eucode>
--
-- Example 4:
-- <eucode>
-- s = columnize({{1, 2}, {3, 4}, {5, 6, 7}}, {2,1})
-- -- s is { {2,4,6}, {1,3,5} } -- Column 2 then column 1
-- </eucode>
--
-- Example 5:
-- <eucode>
-- s = columnize({"abc", "def", "ghi"})
-- -- s is {"adg", "beh", "cfi" }
-- </eucode>

public function columnize(sequence source, object cols = {}, object defval = 0)
	sequence result
	sequence collist

	if sequence(cols) then
		collist = cols
	else
		collist = {cols}
	end if

	if length(collist) = 0 then
		cols = 0
		for i = 1 to length(source) do
			if cols < length(source[i]) then
				cols = length(source[i])
			end if
		end for
		for i = 1 to cols do
			collist &= i
		end for
	end if

	result = repeat({}, length(collist))
	for i = 1 to length(collist) do
		integer col = collist[i]
		for j = 1 to length(source) do
			if sequence(source[j]) and length(source[j]) < col then
				result[i] = append(result[i], defval)
			else
				if atom(source[j]) then
					result[i] = append(result[i], source[j])
				else
					result[i] = append(result[i], source[j][col])
				end if
			end if
		end for
	end for

	return result
end function


--**
-- applies a function to every element of a sequence returning a new sequence of
-- the same size.
--
-- Parameters:
-- * ##source## : the sequence to map
-- * ##rid## : the [[:routine_id]] of function to use as converter
-- * ##userdata## : an object passed to each invocation of ##rid##. If omitted,
--                 ##{}## is used.
--
-- Returns:
--	A **sequence**, the length of ##source##. Each element there is the
-- corresponding element in ##source## mapped using the routine referred to by ##rid##.
--
-- Comments:
-- The supplied routine must take two arguments. The type of the first arguments must
-- be compatible with all the elements in ##source##. The second parameter is
-- an ##object## containing ##userdata##.
--
-- Example 1:
-- <eucode>
-- function greeter(object o, object d)
--     return o[1] & ", " & o[2] & d
-- end function
--
-- s = apply({{"Hello", "John"}, {"Goodbye", "John"}},routine_id("greeter"),"!")
-- -- s is {"Hello, John!", "Goodbye, John!"}
-- </eucode>
--
-- See Also:
--   [[:filter]]

public function apply(sequence source, integer rid, object userdata = {})
	for a = 1 to length(source) do
		source[a] = call_func(rid, {source[a], userdata})
	end for
	return source
end function

--**
-- changes each item from ##source_arg## found in ##from_set## into the
-- corresponding item in ##to_set##
--
-- Parameters:
--   # ##source_arg## : Any Euphoria object to be transformed.
--   # ##from_set## : A sequence of objects representing the only items from
--                   ##source_arg## that are actually transformed.
--   # ##to_set## : A sequence of objects representing the transformed equivalents
--                 of those found in ##from_set##.
--   # ##one_level## : An integer. ##0## (the default) means that mapping applies to
--                    every atom in every level of sub-sequences. ##1## means that
--                    mapping only applies to the items at the first level
--                    in ##source_arg##.
--
-- Returns:
--   An **object**, The transformed version of ##source_arg##.
--
-- Comments:
-- * When ##one_level## is zero or omitted, for each item in ##source_arg##,
--  ** if it is an atom then it may be transformed
--  ** if it is a sequence, then the mapping is performed recursively on the
--     sequence.
--  ** This option required ##from_set## to only contain atoms and contain no
--     sub-sequences.
--
-- * When ##one_level## is not zero, for each item in ##source_arg##,
--  ** regardless of whether it is an atom or sequence, if it is found in ##from_set##
--     then it is mapped to the corresponding object in ##to_set##.
-- * Mapping occurs when an item in ##source_arg## is found in ##from_set##,
--  then it is replaced by the corresponding object in ##to_set##.
--
-- Example 1:
--   <eucode>
--   res = mapping("The Cat in the Hat", "aeiou", "AEIOU")
--   -- res is now "ThE CAt In thE HAt"
--   </eucode>

public function mapping(object source_arg, sequence from_set, sequence to_set, integer one_level = 0)
	integer pos

	if atom(source_arg) then
		pos = find(source_arg, from_set)
		if pos >= 1  and pos <= length(to_set) then
			source_arg = to_set[pos]
		end if
	else
		for i = 1 to length(source_arg) do
			if atom(source_arg[i]) or one_level then
				pos = find(source_arg[i], from_set)
				if pos >= 1  and pos <= length(to_set) then
					source_arg[i] = to_set[pos]
				end if
			else
				source_arg[i] = mapping(source_arg[i], from_set, to_set)
			end if
		end for
	end if

	return source_arg
end function

--****
-- Signature:
-- <built-in> function length(object target)
--
-- Description:
-- returns the length of an object.
--
-- Parameters:
--		# ##target## : the object being queried
--
-- Returns:
--		An **integer**, the number of elements involved with ##target##.
--
-- Comments:
-- * An atom only ever has a length of 1.
-- * The length of a sequence is the number of elements in the sequence.
-- * The length of each sequence is stored internally by the
-- interpreter for fast access. In some other languages this
-- operation requires a search through memory for an end marker.
--
-- Example 1:
-- <eucode>
-- length({{1,2}, {3,4}, {5,6}})   -- 3
-- length("")	 -- 0
-- length({})	 -- 0
-- length( 7 )   -- 1
-- length( 3.14 ) -- 1
-- </eucode>
--
-- See Also:
--     [[:append]], [[:prepend]], [[:& -> amp_concat]]

--**
-- reverses the order of elements in a sequence.
--
-- Parameters:
--		# ##target## : the sequence to reverse.
--		# ##pFrom## : an integer, the starting point. Defaults to 1.
--		# ##pTo## : an integer, the end point. Defaults to 0.
--
-- Returns:
--	A **sequence**, if ##target## is a sequence, the same length as ##target##
-- and the same elements, but those with index between ##pFrom## and ##pTo##
-- appear in reverse order.
--
-- Comments:
-- In the result sequence, some or all top-level elements appear in reverse order compared
-- to the original sequence. This does not reverse any sub-sequences found in the original
-- sequence.
-- 
-- The ##pTo## parameter can be negative, which indicates an offset from the last element.
-- Thus ##-1## means the second-last element and ##0## means the last element.
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

public function reverse(object target, integer pFrom = 1, integer pTo = 0)
	integer uppr, n, lLimit
	sequence t

	n = length(target)
	if n < 2 then
		return target
	end if
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
-- shuffles the elements of a sequence.
--
-- Parameters:
--		# ##seq##: the sequence to shuffle.
--
-- Returns:
--		A **sequence**
--
-- Comments:
-- The input sequence does not have to be in any specific order and can
-- contain duplicates. The output will be in an unpredictable order, which
-- might even be the same as the input order.
--
-- Example 1:
-- <eucode>
-- shuffle({1,2,3,3}) -- {3,1,3,2}
-- shuffle({1,2,3,3}) -- {2,3,1,3}
-- shuffle({1,2,3,3}) -- {1,2,3,3}
-- </eucode>

public function shuffle(object seq)
-- 1963 shuffle algorithm written by L.E. Moses and R.V. Oakford

	for toIdx = length(seq) to 2 by -1 do
		-- Get a random spot in the remaining items
		integer fromIdx = rand(toIdx)

		-- Swap the newly picked item with whatever is at the receiving spot
		object swapValue = seq[fromIdx]

		seq[fromIdx] = seq[toIdx]
		seq[toIdx] = swapValue

	end for

	return seq
end function

--****
-- === Building Sequences
--

--**
-- returns a new sequence built as a series from a given object.
--
-- Parameters:
--		# ##start## : the initial value from which to start
--		# ##increment## : the value to recursively add to ##start## to get new elements
--		# ##count## :  an integer, the number of items in the returned sequence. The default is 2.
--		# ##operation## :  an integer, the type of operation used to build the series.
--                         Can be either '+' for a linear series or '*' for a geometric series.
--                         The default is '+'.
--
-- Returns:
--		An **object**, either 0 on failure or a sequence containing the series.
-- 
--
-- Comments:
-- * The first item in the returned series is always ##start##.
-- * A //linear// series is formed by **adding** ##increment## to ##start##.
-- * A //geometric// series is formed by **multiplying** ##increment## by ##start##.
-- * If ##count## is negative, or if ##start## **##op##** ##increment## is invalid,
-- then 0 is returned. Otherwise, a sequence, of length
-- ##count+1##, staring with ##start## and whose adjacent elements differ
-- by ##increment##, is returned.
--
-- Example 1:
-- <eucode>
-- s = series( 1, 4, 5)
-- -- s is {1, 5, 9, 13, 17}
-- s = series( 1, 2, 6, '*')
-- -- s is {1, 2, 4, 8, 16, 32}
-- s = series({1,2,3}, 4, 2)
-- -- s is {{1,2,3}, {5,6,7}}
-- s = series({1,2,3}, {4,-1,10}, 2)
-- -- s is {{1,2,3}, {5,1,13}}
-- </eucode>
--
-- See Also:
--     [[:repeat_pattern]]

public function series(object start, object increment, integer count = 2, integer op = '+')
	sequence result

	if count < 0 then
		return 0
	end if
	
	if not binop_ok(start, increment) then
		return 0
	end if
	
	if count = 0 then
		return {}
	end if
	
	result = repeat(0, count )
	result[1] = start
	switch op do
		case '+' then
			for i = 2 to count  do
				start += increment
				result[i] = start
			end for
			
		case '*' then
			for i = 2 to count do
				start *= increment
				result[i] = start
			end for
			
		case else
			return 0
	end switch
	return result
end function

--**
-- returns a periodic sequence, given a pattern and a count.
--
-- Parameters:
--		# ##pattern## : the sequence whose elements are to be repeated
--		# ##count## : an integer, the number of times the pattern is to be repeated.
--
-- Returns:
--	A **sequence**, empty on failure, and of length ##count*length(pattern)##
-- otherwise. The first elements of the returned sequence are those of
-- ##pattern##. So are those that follow, on to the end.
--
-- Example 1:
-- <eucode>
-- s = repeat_pattern({1,2,5},3)
-- -- s is {1,2,5,1,2,5,1,2,5}
-- </eucode>
--
-- See Also:
--   [[:repeat]], [[:series]]

public function repeat_pattern(object pattern, integer count)
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

--****
-- Signature:
-- <built-in> function repeat(object item, atom count)
--
-- Description:
-- creates a sequence whose all elements are identical, with given length.
--
-- Parameters:
--		# ##item## : an object, to which all elements of the result will be equal
--		# ##count## : an atom, the requested length of the result sequence. This must
--                   be a value from zero to ##0x3FFFFFFF##. Any floating point values
--                   are first floored.
--
-- Returns:
--		A **sequence**, of length ##count## each element of which is ##item##.
--
-- Errors:
--	##count## cannot be less than zero and cannot be greater than ##1_073_741_823##.
--
-- Comments:
-- When you ##repeat## a sequence or an atom the
-- interpreter does not actually make multiple copies in memory.
-- Rather, a single copy is "pointed to" a number of times.
--
-- Example 1:
-- <eucode>
-- repeat(0, 10)	  -- {0,0,0,0,0,0,0,0,0,0}
--
-- repeat("JOHN", 4)  -- {"JOHN", "JOHN", "JOHN", "JOHN"}
-- -- The interpreter will create only one copy of "JOHN"
-- -- in memory and create a sequence containing four references to it.
-- </eucode>
--
-- See Also:
--     [[:repeat_pattern]], [[:series]]

--****
-- === Adding to Sequences
--

--****
-- Signature:
-- <built-in> function append(sequence target, object x)
--
-- Description:
-- adds an object as the last element of a sequence.
--
-- Parameters:
--		# ##source## : the sequence to add to
--      # ##x## : the object to add
--
-- Returns:
--	A **sequence**, whose first elements are those of ##target## and whose
-- last element is ##x##.
--
-- Comments:
--
-- The length of the resulting sequence will be ##length(target) + 1##, no
-- matter what ##x## is.
--
-- If ##x## is an atom this is equivalent to ##result = target & x##. If ##x##
-- is a sequence it is not equivalent.
--
-- The extra storage is allocated automatically and very efficiently with
-- Euphoria's dynamic storage allocation. The case where ##target## itself is
-- appended to (as in Example 1 below) is highly optimized.
--
-- Example 1:
-- <eucode>
--   sequence x
--
--   x = {}
--   for i = 1 to 10 do
--	     x = append(x, i)
--   end for
--   -- x is now {1,2,3,4,5,6,7,8,9,10}
-- </eucode>
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
--     [[:prepend]], [[:& -> amp_concat]]

--****
-- Signature:
-- <built-in> function prepend(sequence target, object x)
--
-- Description:
-- adds an object as the first element of a sequence.
--
-- Parameters:
--		# ##source## : the sequence to add to
--      # ##x## : the object to add
--
-- Returns:
--	A **sequence**, whose last elements are those of ##target## and whose
-- first element is ##x##.
--
-- Comments:
-- The length of the returned sequence will be ##length(target) + 1## always.
--
-- If ##x## is an atom this is the same as ##result = x & target##. If ##x## is
-- a sequence it is not the same.
--
-- The case where ##target## itself is prepended to is handled very efficiently.
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
--     [[:append]], [[:& -> amp_concat]]


--****
-- Signature:
--   <built-in> function insert(sequence target, object what, integer index)
--
-- Description:
--   inserts an object into a sequence as a new element at a given location.
--
-- Parameters:
--		# ##target## : the sequence to insert into
--		# ##what## : the object to insert
--		# ##index## : an integer, the position in ##target## where ##what##
--                               should appear
--
-- Returns:
-- A **sequence**, which is ##target## with one more element at ##index##,
-- which is ##what##.
--
-- Comments:
-- ##target## can be a sequence of any shape, and ##what## any kind of object.
--
-- The length of the returned sequence is always ##length(target) + 1##.
--
-- Inserting a sequence into a string returns a sequence which is no longer a string.
--
-- Example 1:
-- <eucode>
-- s = insert("John Doe", " Middle", 5)
-- -- s is {'J','o','h','n'," Middle",' ','D','o','e'}
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

--****
-- Signature:
--   <built-in> function splice(sequence target, object what, integer index)
--
-- Description:
-- inserts an object as a new slice in a sequence at a given position.
--
-- Parameters:
--		# ##target## : the sequence to insert into
--		# ##what## : the object to insert
--		# ##index## : an integer, the position in ##target## where ##what## should appear
--
-- Returns:
--		A **sequence**, which is ##target## with one or more elements, those of ##what##,
-- inserted at locations starting at ##index##.
--
-- Comments:
-- ##target## can be a sequence of any shape, and ##what## any kind of object.
--
-- The length of this new sequence is the sum of the lengths of ##target## and ##what##.
-- ##splice## is equivalent to
-- [[:insert]] when ##what## is an atom, but not when it is a sequence.
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
--     [[:insert]], [[:remove]], [[:replace]], [[:& -> amp_concat]]

--**
-- pads the beginning of a sequence with an object so as to meet a minimum
-- length condition.
--
-- Parameters:
--   # ##target## : the sequence to pad.
--   # ##size## : an integer, the target minimum size for ##target##
--   # ##padding## : an object, usually the character to pad to (defaults to ' ').
--
-- Returns:
--	A **sequence**, either ##target## if it was long enough, or a sequence of
-- length ##size## whose last elements are those of ##target## and whose first
-- few head elements all equal ##padding##.
--
-- Comments:
-- ##pad_head## will not remove characters. If ##length(target)## is greater
-- than ##size##, this function simply returns ##target##. See [[:head]]
-- if you wish to truncate long sequences.
--
-- Example 1:
-- <eucode>
-- s = pad_head("ABC", 6)
-- -- s is "   ABC"
--
-- s = pad_head("ABC", 6, '-')
-- -- s is "---ABC"
-- </eucode>
--
-- See Also:
--   [[:trim_head]], [[:pad_tail]], [[:head]]

public function pad_head(object target, integer size, object ch=' ')
	if size <= length(target) then
		return target
	end if

	return repeat(ch, size - length(target)) & target
end function

--**
-- pads the end of a sequence with an object so as to meet a minimum length condition.
--
-- Parameters:
--   # ##target## : the sequence to pad.
--   # ##size## : an integer, the target minimum size for ##target##
--   # ##padding## : an object, usually the character to pad to (defaults to ' ').
--
-- Returns:
-- A **sequence**, either ##target## if it was long enough, or a sequence
-- of length ##size## whose first elements are those of ##target## and whose
-- last few head elements all equal ##padding##.
--
-- Comments:
-- ##pad_tail## will not remove characters. If ##length(target)## is greater
-- than ##size##, this function simply returns ##target##. See [[:tail]] if
-- you wish to truncate long sequences.
--
-- Comments:
--
--   ##pad_tail## will not remove characters. If ##length(str)## is greater than params, this
--   function simply returns ##str##. See ##tail## if you wish to truncate long sequences.
--
-- Example 1:
-- <eucode>
-- s = pad_tail("ABC", 6)
-- -- s is "ABC   "
--
-- s = pad_tail("ABC", 6, '-')
-- -- s is "ABC---"
-- </eucode>
--
-- See Also:
--   [[:trim_tail]], [[:pad_head]], [[:tail]]

public function pad_tail(object target, integer size, object ch=' ')
	if size <= length(target) then
		return target
	end if

	return target & repeat(ch, size - length(target))
end function

--**
-- adds an item to the sequence if its not already there. If it already exists
-- in the list, the list is returned unchanged.
--
-- Parameters:
-- # ##needle## :   object to add.
-- # ##haystack## : sequence to add it to.
-- # ##order## :    an integer; determines how the ##needle## affects the ##haystack##.
--                 It can be added to the front (prepended), to the back (appended),
--                 or sorted after adding. The default is to prepend it.
--
-- Returns:
--   A **sequence**, which is ##haystack## with ##needle## added to it.
--
-- Comments:
--
--   An error occurs if an invalid ##order## argument is supplied.
--
-- The following enum is provided for specifying ##order##:
-- * ##ADD_PREPEND## ~--  prepend ##needle## to ##haystack##. This is the default option.
-- * ##ADD_APPEND## ~--  append ##needle## to ##haystack##.
-- * ##ADD_SORT_UP## ~-- sort ##haystack## in ascending order after inserting ##needle##
-- * ##ADD_SORT_DOWN## ~-- sort ##haystack## in descending order after inserting ##needle##
--
-- Example 1:
-- <eucode>
-- s = add_item( 1, {3,4,2}, ADD_PREPEND ) -- prepend
-- -- s is {1,3,4,2}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = add_item( 1, {3,4,2}, ADD_APPEND ) -- append
-- -- s is {3,4,2,1}
-- </eucode>
--
-- Example 3:
-- <eucode>
-- s = add_item( 1, {3,4,2}, ADD_SORT_UP ) -- ascending
-- -- s is {1,2,3,4}
-- </eucode>
--
-- Example 4:
-- <eucode>
-- s = add_item( 1, {3,4,2}, ADD_SORT_DOWN ) -- descending
-- -- s is {4,3,2,1}
-- </eucode>
--
-- Example 5:
-- <eucode>
-- s = add_item( 1, {3,1,4,2} )
-- -- s is {3,1,4,2} -- Item was already in list so no change.
-- </eucode>

public function add_item(object needle, sequence haystack, integer pOrder = 1)
	if find(needle, haystack) then
		return haystack
	end if
	switch pOrder do
		case ADD_PREPEND then
			return prepend(haystack, needle)

		case ADD_APPEND then
			return append(haystack, needle)

		case ADD_SORT_UP then
			return stdsort:sort(append(haystack, needle))

		case ADD_SORT_DOWN then
			return stdsort:sort(append(haystack, needle), stdsort:DESCENDING)

		case else
			error:crash("sequence.e:add_item() invalid Order argument '%d'", pOrder)
	end switch

	return haystack
end function

--**
-- removes an item from the sequence.
--
-- Parameters:
-- # ##needle## :   object to remove.
-- # ##haystack## : sequence to remove it from.
--
-- Returns:
--   A **sequence**, which is ##haystack## with ##needle## removed from it.
--
-- Comments:
-- If ##needle## is not in ##haystack## then ##haystack## is returned unchanged.
--
-- Example 1:
-- <eucode>
-- s = remove_item( 1, {3,4,2,1} ) --> {3,4,2}
-- s = remove_item( 5, {3,4,2,1} ) --> {3,4,2,1}
-- </eucode>

public function remove_item(object needle, sequence haystack)
	integer lIdx
	
	lIdx = find(needle, haystack)
	if not lIdx then
		return haystack
	end if
	
	if lIdx = 1 then
		return haystack[2 .. $]
		
	elsif lIdx = length(haystack) then
		return haystack[1 .. $-1]
		
	else
		return haystack[1 .. lIdx - 1] & haystack[lIdx + 1 .. $]
	end if
end function

--****
-- === Extracting, Removing, Replacing 
--

--****
-- Signature:
-- <built-in> function head(sequence source, atom size=1)
--
-- Description:
-- returns the first ##size## item or items of a sequence.
--
-- Parameters:
--		# ##source## : the sequence from which elements will be returned
--		# ##size## : an integer; how many elements, at most, will be returned.
--                              Defaults to 1.
--
-- Returns:
-- A **sequence**, ##source## if its length is not greater than ##size##,
-- or the ##size## first elements of ##source## otherwise.
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

--****
-- Signature:
-- <built-in> function tail(sequence source, atom size=length(source) - 1)
--
-- Description:
-- returns the last ##size## item or items of a sequence.
--
-- Parameters:
--   # ##source## : the sequence to get the tail of.
--   # ##size## : an integer, the number of items to return.
--                           (defaults to length(source) - 1)
--
-- Returns:
-- A **sequence**, of length at most ##size##. If the length is less than
-- ##size##, then ##source## was returned. Otherwise, the ##size## last elements
-- of ##source## were returned.
--
-- Comments:
--   ##source## can be any type of sequence, including nested sequences.
--
-- Example 1:
-- <eucode>
-- s2 = tail("John Doe", 3)
-- -- s2 is "Doe"
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s2 = tail("John Doe", 50)
-- -- s2 is "John Doe"
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

--**
-- returns a slice of a sequence, given by a starting point and a length.
--
-- Parameters:
--		# ##source## : the sequence some elements of which will be returned
--		# ##start## : an integer, the lower index of the slice to return
--		# ##len## : an integer, the length of the slice to return
--
-- Returns:
-- A **sequence**, made of at most ##len## elements of ##source##. These
-- elements are at contiguous positions in ##source## starting at ##start##.
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
-- Example 4:
-- <eucode>
-- s2 = mid({1, 5.4, "John", 30}, 2, -1)
-- -- s2 is {5.4, "John", 30}
-- </eucode>
--
-- See Also:
--     [[:head]], [[:tail]], [[:slice]]

public function mid(sequence source, atom start, atom len)
	if len<0 then
		len += length(source)
		if len<0 then
			error:crash("mid(): len was %d and should be greater than %d.",
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
-- returns a portion of the supplied sequence.
--
-- Parameters:
--		# ##source## : the sequence from which to get a portion
--		# ##start## : an integer, the starting point of the portion. Default is 1.
--		# ##stop## : an integer, the ending point of the portion. Default is length(source).
--
-- Returns:
--		A **sequence**.
--
-- Comments:
-- * If the supplied ##start## is less than 1 then it set to 1.
-- * If the supplied ##stop## is less than 1 then ##length(source)## is added to it.
-- In this way, 0 represents the end of ##source##, -1 represents one element
-- in from the end of ##source## and so on.
-- * If the supplied ##stop## is greater than ##length(source)## then it is set to the end.
-- * After these adjustments, and if ##source[start..stop]## makes sense, it is
-- returned, otherwise, ##{}## is returned.
--
-- Example 1:
-- <eucode>
-- s2 = slice("John Doe", 6, 8)--> "Doe"
-- s2 = slice("John Doe", 6, 50) --> "Doe"
-- s2 = slice({1, 5.4, "John", 30}, 2, 3) --> {5.4, "John"}
-- s2 = slice({1,2,3,4,5}, 2, -1) --> {2,3,4}
-- s2 = slice({1,2,3,4,5}, 2) --> {2,3,4,5}
-- s2 = slice({1,2,3,4,5}, , 4) --> {1,2,3,4}
-- </eucode>
--
-- See Also:
--   [[:head]], [[:mid]], [[:tail]]

public function slice(sequence source, atom start = 1, atom stop = 0)
		
	if stop < 1 then 
		stop += length(source) 
		
	elsif stop > length(source) then 
		stop = length(source) 
		
	end if
		
	if start < 1 then 
		start = 1 
	end if
	
	if start > stop then
		return ""
	end if

	return source[start..stop]
end function

--**
-- performs a vertical slice on a nested sequence.
--
-- Parameters:
--	# ##source## : the sequence to take a vertical slice from
--	# ##colno## : an atom, the column number to extract (rounded down)
--	# ##error_control## : an object which says what to do if some element
--                       does not exist. Defaults to 0 (crash in such a circumstance).
--
-- Returns:
-- A **sequence**, usually of the same length as ##source##, made of all
-- the ##source[x][colno]##.
--
-- Errors:
-- If an element is not defined and ##error_control## is 0, an error occurs.
-- If ##colno## is less than 1, it cannot be any valid column, and an error occurs.
--
-- Comments:
-- If it is not possible to return the sequence of all ##source[x][colno]]##
-- for all available ##x##, the outcome is decided by ##error_control##:
-- * If 0 (the default), program is aborted.
-- * If a nonzero atom, the short vertical slice is returned.
-- * Otherwise, elements of ##error_control## will be taken to make for any
--   missing element. The elements are selected from the first to the last, 
--   as needed and this cycles again from the first.
--
-- Example 1:
-- <eucode>
-- s = vslice({{5,1}, {5,2}, {5,3}}, 2)
-- -- s is {1,2,3}
--
-- s = vslice({{5,1}, {5,2}, {5,3}}, 1)
-- -- s is {5,5,5}
-- </eucode>
--
-- See Also:
--   [[:slice]], [[:project]]

public function vslice(sequence source, atom colno, object error_control=0)
	integer substitutes, current_sub

	if colno < 1 then
		error:crash("sequence:vslice(): colno should be a valid index, but was %d",colno)
	end if

	if atom(error_control) then
		substitutes =-(not error_control)
	else
		substitutes = length(error_control)
		current_sub = 0
	end if

	for i = 1 to length(source) do
		if colno > length(source[i]) then
			if substitutes = -1 then
				error:crash("sequence:vslice(): colno should be a valid index on the %d-th element, but was %d", {i, colno})
			elsif substitutes = 0 then
				return source[1..i-1]
			else
				current_sub += 1
				if current_sub > length(error_control) then
					current_sub = 1
				end if
				source[i] = error_control[current_sub]
				
			end if
		else
			if sequence(source[i]) then
				source[i] = source[i][colno]
			end if
		end if
	end for

	return source
end function

--****
-- Signature:
-- <built-in> function remove(sequence target, atom start, atom stop=start)
--
-- Description:
-- removes an item, or a range of items from a sequence.
--
-- Parameters:
--   # ##target## : the sequence to remove from.
--   # ##start## : an atom, the (starting) index at which to remove
--   # ##stop## : an atom, the index at which to stop removing (defaults to ##start##)
--
-- Returns:
-- A **sequence**, obtained from ##target## by carving the ##start..stop## slice
-- out of it.
--
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


--**
-- changes a sequence slice, possibly with padding.
--
-- Parameters:
-- 		# ##target## : a sequence, a modified copy of which will be returned
--		# ##source## : a sequence, to be patched inside or outside ##target##
--		# ##start## : an integer, the position at which to patch
--		# ##filler## : an object, used for filling gaps. Defaults to ' '
--
-- Returns:
-- A **sequence**, which looks like ##target##, but a slice starting at ##start##
--                 equals ##source##.
--
-- Comments:
--
-- In some cases, this call will result in the same result as [[:replace]].
--
-- If ##source## does not fit into ##target## because of the lengths and the
-- supplied ##start## value, gaps will be created, and ##filler## is used to
-- fill them in.
--
-- Notionally, ##target## has an infinite amount of ##filler## on both sides,
-- and ##start## counts position relative to where ##target## actually starts.
-- Then, notionally, a [[:replace]] operation is performed.
--
-- Example 1:
-- <eucode>
-- sequence source = "abc", target = "John Doe"
-- sequence s = patch(target, source, 11,'0')
-- -- s is now "John Doe00abc"
-- </eucode>
--
-- Example 2:
-- <eucode>
-- sequence source = "abc", target = "John Doe"
-- sequence s = patch(target, source, -1)
-- -- s is now "abcohn Doe"
-- Note that there was no gap to fill.
-- Since -1 = 1 - 2, the patching started 2 positions before the initial 'J'.
-- </eucode>
--
-- Example 3:
-- <eucode>
-- sequence source = "abc", target = "John Doe"
-- sequence s = patch(target, source, 6)
-- -- s is now "John Dabc"
-- </eucode>
--
-- See Also:
-- [[:mid]], [[:replace]]

public function patch(sequence target, sequence source, integer start, object filler = ' ')
	if start + length(source) <= 0 then
		return source & repeat(filler, -start-length(source))+1 & target
	elsif start + length(source) <= length(target) then
		if start<=0 then
			return source & target[start+length(source)..$]
		else
        	return target[1..start-1] & source &  target[start+length(source)..$]
        end if
	elsif start <= 1 then
		return source
	elsif start <= length(target)+1 then
		return target[1..start-1] & source
	else
		return target & repeat(filler,start-length(target)-1) & source
	end if
end function

--**
-- removes all occurrences of some object from a sequence.
--
-- Parameters:
--   # ##needle## : the object to remove.
--   # ##haystack## : the sequence to remove from.
--
-- Returns:
-- A **sequence**, of length at most ##length(haystack)##, and which has
-- the same elements, without any copy of ##needle## left
--
-- Comments:
-- This function weeds elements out, not sub-sequences.
--
-- Example 1:
-- <eucode>
-- s = remove_all( 1, {1,2,4,1,3,2,4,1,2,3} )
-- -- s is {2,4,3,2,4,2,3}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = remove_all('x', "I'm toox secxksy for my shixrt.")
-- -- s is "I'm too secksy for my shirt."
-- </eucode>
--
-- See Also:
--   [[:remove]], [[:replace]]

public function remove_all(object needle, sequence haystack)
	integer found = 1
	while found entry do
		haystack = remove( haystack, found )
	entry
		found = find( needle, haystack, found )
	end while
	return haystack
end function

--**
-- keeps all occurrences of a set of objects from a sequence and removes all others.
--
-- Parameters:
--   # ##needles## : the set of objects to retain.
--   # ##haystack## : the sequence to remove items not in ##needles##.
--
-- Returns:
-- A **sequence** containing only those objects from ##haystack## that are also in ##needles##.
--
-- Example 1:
-- <eucode>
-- s = retain_all( {1,3,5}, {1,2,4,1,3,2,4,1,2,3} ) --> {1,1,3,1,3}
-- s = retain_all("0123456789", "+34 (04) 555-44392") -> "340455544392"
-- </eucode>
--
-- See Also:
--   [[:remove]], [[:replace]], [[:remove_all]]

public function retain_all(object needles, sequence haystack)
	integer lp
	integer np
	sequence result

	if atom(needles) then
		needles = {needles}
	end if
	if length(needles) = 0 then
		return {}
	end if
	if length(haystack) = 0 then
		return {}
	end if

	result = haystack
	lp = length(haystack)
	np = 1
	for i = 1 to length(haystack) do
		if find(haystack[i], needles) then
			if np < i then
				result[np .. lp] = haystack[i..$]
			end if
			np += 1
		else
			lp -= 1
		end if
	end for
	
	return result[1 .. lp]
	
end function

--**
-- filters a sequence based on a user supplied comparator function.
--
-- Parameters:
-- * ##source## : sequence to filter
-- * ##rid## : Either a [[:routine_id]] of function to use as comparator or one
-- of the predefined comparitors.
-- * ##userdata## : an object passed to each invocation of ##rid##. If omitted,
--                 ##{}## is used.
-- * ##rangetype##: A sequence. Only used when ##rid## is "in" or "out". This is
-- used to let the function know how to interpret ##userdata##. When ##rangetype##
-- is an empty string (which is the default), then ##userdata## is treated as a set of zero or more
-- discrete items such that "in" will only return items from ##source## that are
-- in the set of item in ##userdata## and "out" returns those not in ##userdata##.
-- The other values for ##rangetype## mean that ##userdata## must be a set of
-- exactly two items, that represent the lower and upper limits of a range of
-- values. 
--
-- Returns:
--		A **sequence**, made of the elements in ##source## which passed the 
-- comparitor test.
--
-- Comments:
-- * The only items from ##source## that are returned are those that pass the test.
-- * When ##rid## is a routine_id, that user defined routine must be a function.
-- Each item in ##source##, along with the ##userdata## is passed to the function.
-- The function must return a non-zero atom if the item is to be included in the
-- result sequence, otherwise it should return zero to exclude it from the result.
--
-- * The predefined comparitors are~:
--
-- |= Comparitor |  |= Return Items in ##source## that are... |
-- | "<"  |   "lt" | less than ##userdata## |
-- | "<=" |  "le" |  less than or equal to ##userdata## |
-- | "=" or "==" |  "eq" |  equal to ##userdata## |
-- | "!=" |  "ne" |  not equal to ##userdata## |
-- | ">"  |  "gt" |  greater than ##userdata## |
-- | ">=" | "ge" | greater than or equal to ##userdata## |
-- | | "in" | in ##userdata## |
-- | | "out" | not in ##userdata## |
--
-- * Range Type Usage
--
-- |= Range Type  |= Range |= Meaning |
-- | "[]"         | Inclusive range. | Lower and upper are in the range. |
-- | "[)"         | Low Inclusive range. | Lower is in the range but upper is not. |
-- | "(]"         | High Inclusive range.| Lower is not in the range but upper is. |
-- | "()"         | Exclusive range. | Lower and upper are not in the range. |
--
-- Example 1:
-- <eucode>
-- function mask_nums(atom a, object t)
--     if sequence(t) then
--         return 0
--     end if
--     return and_bits(a, t) != 0
-- end function
--
-- function even_nums(atom a, atom t)
--     return and_bits(a,1) = 0
-- end function
--
-- constant data = {5,8,20,19,3,2,10}
-- filter(data, routine_id("mask_nums"), 1) --> {5,19,3}
-- filter(data, routine_id("mask_nums"), 2) -->{19, 3, 2, 10}
-- filter(data, routine_id("even_nums")) -->{8, 20, 2, 10}
--
-- -- Using 'in' and 'out' with sets.
-- filter(data, "in", {3,4,5,6,7,8}) -->{5,8,3}
-- filter(data, "out", {3,4,5,6,7,8}) -->{20,19,2,10}
--
-- -- Using 'in' and 'out' with ranges.
-- filter(data, "in",  {3,8}, "[]") --> {5,8,3}
-- filter(data, "in",  {3,8}, "[)") --> {5,3}
-- filter(data, "in",  {3,8}, "(]") --> {5,8}
-- filter(data, "in",  {3,8}, "()") --> {5}
-- filter(data, "out", {3,8}, "[]") --> {20,19,2,10}
-- filter(data, "out", {3,8}, "[)") --> {8,20,19,2,10}
-- filter(data, "out", {3,8}, "(]") --> {20,19,3,2,10}
-- filter(data, "out", {3,8}, "()") --> {8,20,19,3,2,10}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- function quiksort(sequence s)
-- 	if length(s) < 2 then
-- 		return s
-- 	end if
-- 	return quiksort( filter(s[2..$], "<=", s[1]) ) & s[1] & quiksort(filter(s[2..$], ">", s[1]))
-- end function
-- ? quiksort( {5,4,7,2,4,9,1,0,4,32,7,54,2,5,8,445,67} )
-- --> {0,1,2,2,4,4,4,5,5,7,7,8,9,32,54,67,445}
-- </eucode>
--
-- See Also:
--   [[:apply]]

public function filter(sequence source, object rid, object userdata = {}, object rangetype = "")
	sequence dest
	integer idx

	if length(source) = 0 then
		return source
	end if
	dest = repeat(0, length(source))
	idx = 0
	switch rid do
		case "<", "lt" then
			for a = 1 to length(source) do
				if compare(source[a], userdata) < 0 then
					idx += 1
					dest[idx] = source[a]
				end if
			end for
		
		case "<=", "le" then
			for a = 1 to length(source) do
				if compare(source[a], userdata) <= 0 then
					idx += 1
					dest[idx] = source[a]
				end if
			end for
		
		case "=", "==", "eq" then
			for a = 1 to length(source) do
				if compare(source[a], userdata) = 0 then
					idx += 1
					dest[idx] = source[a]
				end if
			end for
		
		case "!=", "ne" then
			for a = 1 to length(source) do
				if compare(source[a], userdata) != 0 then
					idx += 1
					dest[idx] = source[a]
				end if
			end for
		
		case ">", "gt" then
			for a = 1 to length(source) do
				if compare(source[a], userdata) > 0 then
					idx += 1
					dest[idx] = source[a]
				end if
			end for
		
		case ">=", "ge" then
			for a = 1 to length(source) do
				if compare(source[a], userdata) >= 0 then
					idx += 1
					dest[idx] = source[a]
				end if
			end for
		
		case "in" then
			switch rangetype do
				case "" then
					for a = 1 to length(source) do
						if find(source[a], userdata)  then
							idx += 1
							dest[idx] = source[a]
						end if
					end for
					
				case "[]" then
					for a = 1 to length(source) do
						if compare(source[a], userdata[1]) >= 0 then
							if compare(source[a], userdata[2]) <= 0 then
								idx += 1
								dest[idx] = source[a]
							end if
						end if
					end for
					
				case "[)" then
					for a = 1 to length(source) do
						if compare(source[a], userdata[1]) >= 0 then
							if compare(source[a], userdata[2]) < 0 then
								idx += 1
								dest[idx] = source[a]
							end if
						end if
					end for
				case "(]" then
					for a = 1 to length(source) do
						if compare(source[a], userdata[1]) > 0 then
							if compare(source[a], userdata[2]) <= 0 then
								idx += 1
								dest[idx] = source[a]
							end if
						end if
					end for
				case "()" then
					for a = 1 to length(source) do
						if compare(source[a], userdata[1]) > 0 then
							if compare(source[a], userdata[2]) < 0 then
								idx += 1
								dest[idx] = source[a]
							end if
						end if
					end for

				case else
					-- ignore type
										
			end switch
		
		case "out" then
			switch rangetype do
				case "" then
					for a = 1 to length(source) do
						if not find(source[a], userdata)  then
							idx += 1
							dest[idx] = source[a]
						end if
					end for
					
				case "[]" then
					for a = 1 to length(source) do
						if compare(source[a], userdata[1]) < 0 then
							idx += 1
							dest[idx] = source[a]
						elsif compare(source[a], userdata[2]) > 0 then
							idx += 1
							dest[idx] = source[a]
						end if
					end for
					
				case "[)" then
					for a = 1 to length(source) do
						if compare(source[a], userdata[1]) < 0 then
							idx += 1
							dest[idx] = source[a]
						elsif compare(source[a], userdata[2]) >= 0 then
							idx += 1
							dest[idx] = source[a]
						end if
					end for
				case "(]" then
					for a = 1 to length(source) do
						if compare(source[a], userdata[1]) <= 0 then
							idx += 1
							dest[idx] = source[a]
						elsif compare(source[a], userdata[2]) > 0 then
							idx += 1
							dest[idx] = source[a]
						end if
					end for
				case "()" then
					for a = 1 to length(source) do
						if compare(source[a], userdata[1]) <= 0 then
							idx += 1
							dest[idx] = source[a]
						elsif compare(source[a], userdata[2]) >= 0 then
							idx += 1
							dest[idx] = source[a]
						end if
					end for
				case else
					-- ignore type
					
			end switch
		
		case else
			for a = 1 to length(source) do
				if call_func(rid, {source[a], userdata}) then
					idx += 1
					dest[idx] = source[a]
				end if
			end for
	end switch
	return dest[1..idx]
end function

without warning strict
function filter_alpha(object elem, object ud)
	return t_alpha(elem)
end function

--**
-- Signature:
-- <eucode>
-- public constant STDFLTR_ALPHA
-- </eucode>
--
-- Description:
-- Predefined routine_id for use with [[:filter]].
--
-- Comments:
-- Used to filter out non-alphabetic characters from a string.
--
-- Example 1:
-- <eucode>
-- -- Collect only the alphabetic characters from 'text'
--  result = filter(text, STDFLTR_ALPHA)
-- </eucode>
--

public constant STDFLTR_ALPHA = routine_id("filter_alpha")

--****
-- Signature:
-- <built-in> function replace(sequence target, object replacement, integer start, integer stop=start)
--
-- Description:
-- replaces a slice in a sequence by an object.
--
-- Parameters:
--   # ##target## : the sequence in which replacement will be done.
--   # ##replacement## : an object, the item to replace with.
--   # ##start## : an integer, the starting index of the slice to replace.
--   # ##stop## : an integer, the stopping index of the slice to replace.
--
-- Returns:
-- A **sequence**, which is made of ##target## with the ##start..stop## slice
-- removed and replaced by ##replacement##, which is spliced in.
--
-- Comments:
-- * A new sequence is created. ##target## can be a string or complex sequence
--   of any shape.
--
-- * To replace by just one element, enclose ##replacement## in curly braces,
--    which will be removed at replace time.
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

--**
-- picks out from a sequence a set of elements according to the supplied set of indexes.
--
-- Parameters:
--		# ##source## : the sequence from which to extract elements
--		# ##indexes## : a sequence of atoms, the indexes of the elements to be fetched in ##source##.
--
-- Returns:
--		A **sequence**, of the same length as ##indexes##. 
--
-- Example 1:
-- <eucode>
-- s = extract({11,13,15,17},{3,1,2,1,4})
-- -- s is {15,11,13,11,17}
-- </eucode>
--
-- See Also:
--     [[:slice]]

public function extract(sequence source, sequence indexes)
	object p

	for i = 1 to length(indexes) do
		p = indexes[i]
		if not valid_index(source,p) then
			error:crash("%d is not a valid index for the input sequence",p)
		end if
		indexes[i] = source[p]
	end for
	return indexes
end function

--**
-- creates a list of sequences based on selected elements from sequences in the source.
--
-- Parameters:
--	# ##source## : a list of sequences.
--	# ##coords## : a list of index lists.
--
-- Returns:
--	A **sequence**, with the same length as ##source##. Each of its elements is a sequence,
-- the length of ##coords##. Each innermost sequence is made of the
-- elements from the corresponding source sub-sequence.
--
-- Comments:
-- For each sequence in ##source##, a set of sub-sequences is created; one for
-- each index list in ##coords##. An index list is just a sequence containing
-- indexes for items in a sequence.
--
-- Example 1:
-- <eucode>
-- s = project({ "ABCD",  "789"},  {{1,2}, {3,1}, {2}})
-- -- s is {{"AB","CA","B"},{"78","97","8"}}
-- </eucode>
--
-- See Also:
--   [[:vslice]], [[:extract]]

public function project(sequence source, sequence coords)
	sequence result

	result = repeat( repeat(0, length(coords)), length(source) )
	for i = 1 to length(source) do
		for j = 1 to length(coords) do
			result[i][j] = extract(source[i], coords[j])
		end for
	end for
	return result
end function

--****
-- === Changing the Shape of a Sequence
--

--**
-- splits a sequence on separator delimiters into a number of sub-sequences.
--
-- Parameters:
--   # ##source## : the sequence to split.
--   # ##delim## : an object (default is ' '). The delimiter that separates items
--                in ##source##.
--   # ##no_empty## : an integer (default is 0). If not zero then all zero-length sub-sequences
--                   are removed from the returned sequence. Use this when leading,
--                   trailing and duplicated delimiters are not significant.
--   # ##limit## : an integer (default is 0). The maximum number of sub-sequences
--                to create. If zero, there is no limit.
--
-- Returns:
--		A **sequence**, of sub-sequences of ##source##. Delimiters are removed.
--
-- Comments:
-- This function may be applied to a string sequence or a complex sequence.
--
-- If ##limit## is ##> 0##, this is the maximum number of sub-sequences that will
-- created, otherwise there is no limit.
--
-- Example 1:
-- <eucode>
-- result = split("John Middle Doe")
-- -- result is {"John", "Middle", "Doe"}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- result = split("John,Middle,Doe", ",",, 2) -- Only want 2 sub-sequences.
-- -- result is {"John", "Middle,Doe"}
-- </eucode>
--
-- Example 3:
-- <eucode>
-- result = split("John||Middle||Doe|", '|') -- Each '|' is significant by default
-- -- result is {"John","","Middle","","Doe",""}
-- result = split("John||Middle||Doe|", '|', 1) -- Adjacent '|' are just a single delim,
--                                              -- and leading/trailing '|' ignored.
-- -- result is {"John","Middle","Doe"}
-- </eucode>
--
-- See Also:
--     [[:split_any]], [[:breakup]], [[:join]]

public function split( sequence st, object delim=' ', integer no_empty = 0, integer limit=0)
	sequence ret = {}
	integer start
	integer pos

	if length(st) = 0 then
		return ret
	end if


	if sequence(delim) then
		-- Handle the simple case of split("123", ""), opposite is join({"1","2","3"}, "") -- "123"
		if equal(delim, "") then
			for i = 1 to length(st) do
				st[i] = {st[i]}
				limit -= 1
				if limit = 0 then
					st = append(st[1 .. i],st[i+1 .. $])
					exit
				end if
			end for

			return st
		end if

		start = 1
		while start <= length(st) do
			pos = match(delim, st, start)

			if pos = 0 then
				exit
			end if

			ret = append(ret, st[start..pos-1])
			start = pos+length(delim)
			limit -= 1
			if limit = 0 then
				exit
			end if
		end while
	else
		start = 1
		while start <= length(st) do
			pos = find(delim, st, start)

			if pos = 0 then
				exit
			end if

			ret = append(ret, st[start..pos-1])
			start = pos + 1
			limit -= 1
			if limit = 0 then
				exit
			end if
		end while
	end if

	ret = append(ret, st[start..$])

	integer k = length(ret)
	if no_empty then
		k = 0
		for i = 1 to length(ret) do
			if length(ret[i]) != 0 then
				k += 1
				if k != i then
					ret[k] = ret[i]
				end if
			end if
		end for
	end if

	if k < length(ret) then
		return ret[1 .. k]
	else
		return ret
	end if
end function

--**
-- splits a sequence by any of the separators in the list of delimiters.
--
-- If ##limit## is ##> 0## then limit the number of tokens that will be split to limit.
--
-- Parameters:
-- # ##source## : the sequence to split.
-- # ##delim## : a list of delimiters to split by. The default set is comma, space, tab and bar.
-- # ##limit## : an integer (default is 0). The maximum number of sub-sequences
--              to create. If zero, there is no limit.
-- # ##no_empty## : an integer (default is 0). If not zero then all zero-length sub-sequences
--                   removed from the returned sequence. Use this when leading,
--                   trailing and duplicated delimiters are not significant.
--
-- Comments:
-- * This function may be applied to a string sequence or a complex sequence.
-- * It works like ##split##, but in this case ##delim## is a set of potential
-- delimiters rather than a single delimiter.
-- * If ##delim## is an empty set, the ##source## is returned in a sequence.
--
-- Example 1:
-- <eucode>
-- result = split_any("One,Two|Three Four") -- Default delims
-- -- result is {"One", "Two", "Three", "Four"}
-- result = split_any("192.168.1.103:8080", ".:") -- Using dot and colon
-- -- result is {"192","168","1","103","8080"}
-- result = split_any("One,Two|Three Four",, 2) -- limited to two splits
-- -- result is {"One", "Two", "Three Four"}
-- result = split_any(",One,,Two| Three|| Four,"  ) -- Allow Empty option
-- -- result is {"","One","","Two","","Three","","","Four",""}
-- result = split_any(",One,,Two| Three|| Four,",,,1) -- No Empty option
-- -- result is {"One", "Two", "Three", "Four"}
-- result = split_any(",One,,Two| Three|| Four,", "") -- Empty delimiters
-- -- result is {",One,,Two| Three|| Four,"}
-- </eucode>
--
-- See Also:
--   [[:split]], [[:breakup]], [[:join]]

public function split_any(sequence source, object delim=", \t|", integer limit=0, integer no_empty=0)
	sequence ret = {}
	integer start = 1, pos, next_pos

	if length(delim) = 0 then
		return {source}
	end if

	while 1 do
		pos = search:find_any(delim, source, start)
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

	integer k = length(ret)
	if no_empty then
		k = 0
		for i = 1 to length(ret) do
			if length(ret[i]) != 0 then
				k += 1
				if k != i then
					ret[k] = ret[i]
				end if
			end if
		end for
	end if

	if k < length(ret) then
		return ret[1 .. k]
	else
		return ret
	end if
end function

--**
-- joins sequences together using a delimiter.
--
-- Parameters:
--   # ##items## : the sequence of items to join.
--   # ##delim## : an object, the delimiter to join by. Defaults to " ".
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
--     [[:split]], [[:split_any]], [[:breakup]]

public function join(sequence items, object delim=" ")
	object ret

	if not length(items) then return {} end if

	ret = {}
	for i=1 to length(items)-1 do
		ret &= items[i] & delim
	end for

	ret &= items[$]

	return ret
end function

-- Style options for breakup()

public enum
	--** Indicates that ##size## parameter is maximum length of sub-sequence. See [[:breakup]]
	BK_LEN,
	--** Indicates that ##size## parameter is maximum number of sub-sequence. See [[:breakup]]
	BK_PIECES

--**
-- breaks up a sequence into multiple sequences of a given length.
--
-- Parameters:
-- 		# ##source## : the sequence to be broken up into sub-sequences.
--		# ##size## : an object, if an integer it is either the maximum length of
--                  each resulting sub-sequence or the maximum number of
--                  sub-sequences to break ##source## into. \\
--                  If ##size## is a sequence, it is a list of element counts
--                  for the sub-sequences it creates.
--		# ##style## : an integer, Either ##BK_LEN## if ##size## integer represents
--                   the sub-sequences' maximum length, or ##BK_PIECES## if
--                   the ##size## integer represents the maximum number of
--                   sub-sequences (pieces) to break ##source## into.
--
-- Returns:
--	A **sequence**, of sequences.
--
-- Comments:
-- **When ##size## is an integer and ##style## is BK_LEN...**\\
-- The sub-sequences have length ##size##, except possibly the last one,
-- which may be shorter. For example if ##source## has 11 items and ##size## is
-- 3, then the first three sub-sequences will get 3 items each and the remaining
-- 2 items will go into the last sub-sequence. If ##size## is less than 1 or
-- greater than the length of the ##source##, the ##source## is returned as the
-- only sub-sequence.
--
-- **When ##size## is an integer and ##style## is BK_PIECES...**\\
-- There is exactly ##size## sub-sequences created. If the ##source## is not
-- evenly divisible into that many pieces, then the lefthand sub-sequences will
-- contain one more element than the right-hand sub-sequences. For example, if
-- source contains 10 items and we break it into 3 pieces, piece #1 gets 4 elements,
-- piece #2 gets 3 items and piece #3 gets 3 items - a total of 10. If source had
-- 11 elements then the pieces will have 4,4, and 3 respectively.
--
-- **When ##size## is a sequence...**\\
-- The style parameter is ignored in this case. The source will be broken up
-- according to the counts contained in the size parameter. For example, if
-- ##size## was {3,4,0,1} then piece #1 gets 3 items, #2 gets 4 items, #3 gets
-- 0 items, and #4 gets 1 item. Note that if not all items from source are
-- placed into the sub-sequences defined by ##size##, and //extra// sub-sequence
-- is appended that contains the remaining items from ##source##.
--
-- In all cases, when concatenated these sub-sequences will be identical
-- to the original ##source##.
--
--
-- Example 1:
-- <eucode>
-- s = breakup("5545112133234454", 4)
-- -- s is {"5545", "1121", "3323", "4454"}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = breakup("12345", 2)
-- -- s is {"12", "34", "5"}
-- </eucode>
--
-- Example 3:
-- <eucode>
-- s = breakup({1,2,3,4,5,6}, 3)
-- -- s is {{1,2,3}, {4,5,6}}
-- </eucode>
--
-- Example 4:
-- <eucode>
-- s = breakup("ABCDEF", 0)
-- -- s is {"ABCDEF"}
-- </eucode>
--
-- See Also:
--   [[:split]] [[:flatten]]

public function breakup(sequence source, object size, integer style = BK_LEN)

	if atom(size) and not integer(size) then
		size = floor(size)
	end if

	-- Convert simple integer size into the 'customized' size format.
	if integer(size) then
		integer len
		integer rem
		if style = BK_LEN then
			if size < 1 or size >= length(source) then
				return {source}
			end if
			len = floor(length(source) / size)
			rem = remainder(length(source), size)
			size = repeat(size, len)
			if rem > 0 then
				size &= rem
			end if
		else
			if size > length(source) then
				size = length(source)
			end if
			if size < 1 then
				return {source}
			end if
			len = floor(length(source) / size)
			if len < 1 then
				len = 1
			end if
			rem = length(source) - (size * len)
			size = repeat(len, size)
			for i = 1 to length(size) do
				if rem = 0 then
					exit
				end if
				size[i] += 1
				rem -= 1
			end for
		end if
	end if


	-- Allocate the top level sequence.
	sequence ns = repeat(0, length(size))
	integer source_idx = 1

	-- Place each source element into its appropriate target sub-sequence.
	for i = 1 to length(size) do
		if source_idx <= length(source) then
			integer k = 1
			ns[i] = repeat(0, size[i])
			for j = 1 to size[i] do
				if source_idx > length(source) then
					ns[i] = ns[i][1 .. k-1]
					exit
				end if
				ns[i][k] = source[source_idx]
				k += 1
				source_idx += 1
			end for
		else
			ns[i] = {}
		end if
	end for

	--Handle any leftover data from source.
	if source_idx <= length(source) then
		ns = append(ns, source[source_idx .. $])
	end if

	return ns
end function

--**
-- removes all nesting from a sequence.
--
-- Parameters:
--		# ##s## : the sequence to flatten out.
--      # ##delim## : An optional delimiter to place after each flattened sub-sequence (except
--                 the last one).
--
-- Returns:
--		A **sequence**, of atoms, all the atoms in ##s## enumerated.
--
-- Comments:
-- * If you consider a sequence as a tree, then the enumeration is performed
-- by left-right reading of the tree. The elements are simply read left to
-- right, without any care for braces.
-- * Empty sub-sequences are stripped out entirely.
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
--
-- Example 3:
-- <eucode>
-- Using the delimiter argument.
-- s = flatten({"abc", "def", "ghi"}, ", ")
-- -- s is "abc, def, ghi"
-- </eucode>


public function flatten(sequence s, object delim = "")
	sequence ret
	object x
	integer len
	integer pos

	ret = s
	pos = 1
	len = length(ret)
	while pos <= len do
		x = ret[pos]
		if sequence(x) then
			if length(delim) = 0 then
				ret = ret[1..pos-1] & flatten(x) & ret[pos+1 .. $]
			else
				sequence temp = ret[1..pos-1] & flatten(x)
				if pos != length(ret) then
					ret = temp &  delim & ret[pos+1 .. $]
				else
					ret = temp & ret[pos+1 .. $]
				end if
			end if
			len = length(ret)
		else
			pos += 1
		end if
	end while

	return ret
end function

--**
-- returns a sequence of three sub-sequences. The sub-sequences contain
-- all the elements less than the supplied pivot value, equal to the pivot,
-- and greater than the pivot.
--
-- Parameters:
--   # ##data_p## : Either an atom or a list. An atom is treated as if it is one-element sequence.
--   # ##pivot_p## : An object. Default is zero.
--
-- Returns:
--   A **sequence**, { {less than pivot}, {equal to pivot}, {greater than pivot} }
--
-- Comments:
-- ##pivot## is used as a split up a sequence relative to a specific value.
--
-- Example 1:
-- <eucode>
-- pivot( {7, 2, 8.5, 6, 6, -4.8, 6, 6, 3.341, -8, "text"}, 6 )
-- -- Ans: {{2, -4.8, 3.341, -8}, {6, 6, 6, 6}, {7, 8.5, "text"}}
-- pivot( {4, 1, -4, 6, -1, -7, 9, 10} )
-- -- Ans: {{-4, -1, -7}, {}, {4, 1, 6, 9, 10}}
-- pivot( 5 )
-- -- Ans: {{}, {}, {5}}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- function quiksort(sequence s)
--     if length(s) < 2 then
--         return s
--     end if
--
--     sequence k = pivot(s, s[rand(length(s))])
-- 	
--     return quiksort(k[1]) & k[2] & quiksort(k[3])
-- end function
--
-- sequence t2 = {5,4,7,2,4,9,1,0,4,32,7,54,2,5,8,445,67}
-- ? quiksort(t2) --> {0,1,2,2,4,4,4,5,5,7,7,8,9,32,54,67,445}
-- </eucode>
--

public function pivot(object data_p, object pivot_p = 0)
	sequence result_
	integer pos_

	result_ = {{}, {}, {}}

	if atom(data_p) then
		data_p = {data_p}
	end if

	for i = 1 to length(data_p) do
		pos_ = eu:compare(data_p[i], pivot_p) + 2
		result_[pos_] = append(result_[pos_], data_p[i])
	end for

	return result_
end function


--**
-- implements "List Comprehension" or building a list based on the contents of another list.
--
-- Parameters:
--   # ##source## : A sequence. The list of items to base the new list upon.
--   # ##transformer## : One or more routine_ids. These are [[:routine_id | routine ids]]
--        of functions that must receive three parameters (object x, sequence i, object u)
--        where 'x' is an item in the ##source## list, 'i' contains the position that 'x' is
--        found in the ##source## list and the length of ##source##, and 'u'
--        is the ##user_data## value. Each transformer
--        must return a two-element sequence. If the first element is zero, then ##build_list## continues
--        on with the next transformer function for the same 'x'. If the first element is not
--        zero, the second element is added to the new list being built (other elements
--        are ignored) and build_list skips the rest of the transformers and processes
--        the next element in ##source##.
--   # ##singleton## : An integer. If zero then the transformer functions return multiple
--                   list elements. If not zero then the transformer functions return
--                   a single item (which might be a sequence).
--   # ##user_data## : Any object. This is passed unchanged to each transformer function.
--
-- Returns:
--   A **sequence**, The new list of items.
--
-- Comments:
-- * If the transformer is -1, then the source item is just copied.
--
-- Example 1:
-- <eucode>
-- function remitem(object x, sequence i, object q)
-- 	if (x < q) then
-- 		return {0} -- no output
-- 	else
-- 		return {1,x} -- copy 'x'
-- 	end if
-- end function
--
-- sequence s
-- -- Remove negative elements (x < 0)
-- s = build_list({-3, 0, 1.1, -2, 2, 3, -1.5}, routine_id("remitem"), , 0)
-- -- s is {0, 1.1, 2, 3}
-- </eucode>

public function build_list( sequence source, object transformer, integer singleton = 1, object user_data = {})
	sequence result = {}
	sequence x
	object new_x

	-- Special case where only one transformer is supplied.
	if atom(transformer) then
		transformer = {transformer}
	end if

	for i = 1 to length(source) do
		x = {source[i], {i, length(source)}, user_data}

		for j = 1 to length(transformer) do

			if transformer[j] >= 0 then
				new_x = call_func(transformer[j], x)
				if length(new_x) = 0 then
					-- This didn't return anything so go to the next transformer.
					continue
				end if
				if new_x[1] = 0 then
					-- This didn't return anything so go to the next transformer.
					continue
				end if
				if new_x[1] < 0 then
					-- This didn't return anything and skip other transformers.
					exit
				end if

				new_x = new_x[2]
			else
				-- Just copy the input.
				new_x = x[1]
			end if

			if singleton then
				result = append(result, new_x)
			else
				result &= new_x
			end if

			-- Stop calling any more transformers for this input item.
			exit

		end for


	end for

	return result
end function

--**
-- transforms the input sequence by using one or more user-supplied transformers.
--
-- Parameters:
-- # ##source_data## : A sequence to be transformed.
-- # ##transformer_rids## : An object. One or more routine_ids used to transform the input.
--
-- Returns:
-- The source **sequence**, that has been transformed.
--
-- Comments:
-- * This works by calling each transformer in order, passing to it the result
-- of the previous transformation. Of course, the first transformer gets the
-- original sequence as passed to this routine.
-- * Each transformer routine takes one or more parameters. The first is a source sequence
-- to be transformed and others are any user data that may have been supplied
-- to the ##transform## routine.
-- * Each transformer routine returns a transformed sequence.
-- * The ##transformer_rids## parameters is either a single routine_id or a sequence
-- of routine_ids. In this second case, the routine_id may actually be a
-- multi-element sequence containing the real routine_id and some user data to
-- pass to the transformer routine. If there is no user data then the transformer
-- is called with only one parameter.
--
-- Example 1:
-- <eucode>
-- res = transform(" hello    ", {
--     { routine_id("trim"), " ", 0 },
--     routine_id("upper")
-- })
-- --> "HELLO"
-- </eucode>

public function transform( sequence source_data, object transformer_rids)
	sequence lResult

	lResult = source_data
	if atom(transformer_rids) then
		transformer_rids = {transformer_rids}
	end if

	for i = 1 to length(transformer_rids) do
		if atom(transformer_rids[i]) then
			lResult = call_func(transformer_rids[i], {lResult})
		else
			lResult = call_func(transformer_rids[i][1], {lResult} & transformer_rids[i][2..$])
		end if
	end for
	return lResult

end function

--**
-- replaces all instances of any element from the ##current_items## sequence that occur in the
-- ##source_data## sequence with the corresponding item from the ##new_items## sequence.
--
-- Parameters:
--		# ##source_data## : a sequence, the data that might contain elements from ##current_items##
--		# ##current_items## : a sequence, the set of items to look for in ##source_data##. Matching
--                            data is replaced with the corresponding data from ##new_items##.
--		# ##new_items## : a sequence, the set of replacement data for any matches found.
--		# ##start## : an integer, the starting point of the search. Defaults to 1.
--		# ##limit## : an integer, the maximum number of replacements to be made. 
--                    Defaults to ##length(source_data)##.
--
-- Returns:
--		A **sequence**, an updated version of ##source_data##.
--
-- Comments:
--   By default, this routine operates on single elements from each of the arguments.
-- That is to say, it scans ##source_data## for elements that match any single element
-- in ##current_items## and when matched, replaces that with a single element from ##new_items##.
--
-- For example, you can find all occurrances of 'h', 's', and 't' in a string and replace
-- them with '1', '2', and '3' respectively. \\
--   ##transmute(SomeString, "hts", "123")## \\
-- However, the routine can also be used to scan for sub-sequences and/or replace
-- matches with sequences rather than single elements. This is done by making the first
-- element in ##current_items## and/or ##new_items## an empty sequence. 
--
-- For example, to find all occurrances of "sh","th", and "sch" you have the
-- ##current_items## as ##{{}, "sh", "th", "sch"}##. Note that for the purposes
-- of determine the corresponding replacement data, the leading empty sequence
-- is not counted, so in this example "th" is the second item. 
--
-- <eucode>
--   res = transmute("the school shoes", {{}, "sh", "th", "sch"}, "123")
--   -- res becomes "2e 3ool 1oes"
-- </eucode>
-- The similar syntax is used to indicates that replacements are sequences and
-- not single elements.
--
-- <eucode>
--   res = transmute("the school shoes", {{}, "sh", "th", "sch"}, {{}, "SH", "TH", "SCH"})
--   -- res becomes "THe SCHool SHoes"
-- </eucode>
--
-- Using this option also allows you to remove matching data.
-- <eucode>
--   res = transmute("the school shoes", {{}, "sh", "th", "sch"}, {{}, "", "", ""})
--   -- res becomes "e ool oes"
-- </eucode>
--
-- Another thing to note is that when using this syntax, you can still mix together
-- atoms and sequences.
--
-- <eucode>
--   res = transmute("the school shoes", {{}, "sh", 't', "sch"}, {{}, 'x', "TH", "SCH"})
--   -- res becomes "THhe SCHool xoes"
-- </eucode>
--
-- Example 1:
--   <eucode>
--   res = transmute("John Smith enjoys uncooked apples.", "aeiouy", "YUOIEA")
--   -- res is "JIhn SmOth UnjIAs EncIIkUd YpplUs."
--   </eucode>
-- See Also:
--		[[:find]], [[:match]], [[:replace]], [[:mapping]]

public function transmute(sequence source_data, sequence current_items, sequence new_items, integer start=1, integer limit = length(source_data))
	integer pos
	integer cs
	integer ns
	integer i
    integer elen

	-- Check 'current' for single or sub-sequence matching
	if equal(current_items[1], {}) then
		cs = 1
		current_items = current_items[2 .. $]
	else
		cs = 0
	end if
	
	-- Check 'new' for element or sequence replacements
	if equal(new_items[1], {}) then
		ns = 1
		new_items = new_items[2 .. $]
	else
		ns = 0
	end if
	
	-- Begin scanning
	i = start - 1
	if cs = 0 then
		-- Compare and replace single item in source.
		if ns = 0 then
			-- Treat 'new' as a single item to replace the match.
			while i < length(source_data) do
				if limit <= 0 then
					exit
				end if
				limit -= 1
				
				i += 1
				pos = find(source_data[i], current_items) 
				if pos then
					source_data[i] = new_items[pos]
				end if
			end while
		else
			-- Treat 'new' as a set of items to replace the match.
			while i < length(source_data) do
				if limit <= 0 then
					exit
				end if
				limit -= 1
				
				i += 1
				pos = find(source_data[i], current_items) 
				if pos then
					source_data = replace(source_data, new_items[pos], i, i)
					-- Skip over the replacement data 
					i += length(new_items[pos]) - 1
				end if
			end while
		end if
	else
		-- Compare and replace sub-sequences in source.
		if ns = 0 then
			-- Treat 'new' as a single item to replace the match.
			while i < length(source_data) do
				if limit <= 0 then
					exit
				end if
				limit -= 1
				
				i += 1
				pos = 0
				for j = 1 to length(current_items) do
					if search:begins(current_items[j], source_data[i .. $]) then
						pos = j
						exit
					end if
				end for
				if pos then
			    	elen = length(current_items[pos]) - 1
					source_data = replace(source_data, {new_items[pos]}, i, i + elen)
				end if
			end while
		else
			-- Treat 'new' as a set of items to replace the match.
			while i < length(source_data) do
				if limit <= 0 then
					exit
				end if
				limit -= 1
				
				i += 1
				pos = 0
				for j = 1 to length(current_items) do
					if search:begins(current_items[j], source_data[i .. $]) then
						pos = j
						exit
					end if
				end for
				if pos then
			    	elen = length(current_items[pos]) - 1
					source_data = replace(source_data, new_items[pos], i, i + elen)
					-- Skip over the replacement data 
					i += length(new_items[pos]) - 1
				end if
			end while
		end if
	end if
	return source_data

end function

--**
-- calculates the similarity between two sequences.
--
-- Parameters:
--   # ##A## : A sequence.
--   # ##B## : A sequence.
--
-- Returns:
--   An **atom**, the closer to zero, the more the two sequences are alike.
--
-- Comments:
-- The calculation is weighted to give mismatched elements towards the front
-- of the sequences larger scores. This means that sequences that differ near
-- the begining are considered more un-alike than mismatches towards the end of
-- the sequences. Also, unmatched elements from the first sequence are weighted more
-- than unmatched elements from the second sequence.
--
-- Two identical sequences return zero. A non-zero means that they are not the same
-- and larger values indicate a larger differences.
--
-- Example 1:
-- <eucode>
-- ? sim_index("sit",      "sin")      --> 0.08784
-- ? sim_index("sit",      "sat")      --> 0.32394
-- ? sim_index("sit",      "skit")     --> 0.34324
-- ? sim_index("sit",      "its")      --> 0.68293
-- ? sim_index("sit",      "kit")      --> 0.86603
--
-- ? sim_index("knitting", "knitting") --> 0.00000
-- ? sim_index("kitting",  "kitten")   --> 0.09068
-- ? sim_index("knitting", "knotting") --> 0.27717
-- ? sim_index("knitting", "kitten")   --> 0.35332
-- ? sim_index("abacus","zoological")  --> 0.76304
-- </eucode>

public function sim_index(sequence A, sequence B)
	atom accum_score
	atom pos_factor
	integer indx_a
	integer indx_b
	sequence used_A
	sequence used_B

	-- First pass scores only matching runs of elements.
	accum_score = 0
	indx_a = 1
	used_A = repeat(0, length(A))
	used_B = repeat(0, length(B))
	while indx_a <= length(A) label "DoA" do
		pos_factor = power((1 + length(A) - indx_a) / length(A),2)
		indx_b = 1
		while indx_b <= length(B) do
			if equal(A[indx_a],B[indx_b]) then
				accum_score += power((indx_b - indx_a) * pos_factor,2)
				while indx_a <= length(A) and indx_b <= length(B) with entry do
					if not equal(A[indx_a], B[indx_b]) then
						exit
					end if
				entry
					used_B[indx_b] = 1
					used_A[indx_a] = 1
					indx_a += 1
					indx_b += 1
				end while
				continue "DoA"
			end if
			indx_b += 1
		end while
		indx_a += 1
	end while

	-- Now score the unused elements from A.
 	for i = 1 to length(A) do
 		if used_A[i] = 0 then
			pos_factor = power((1 + length(A) - i) / length(A),2)
 			accum_score += power((length(A) - i + 1) * pos_factor,2)
 		end if
 	end for

	-- Now score the unused elements from B.
 	integer total_elems = length(A)
 	for i = 1 to length(B) do
 		if used_B[i] = 0 then
			pos_factor = power((1 + length(B) - i) / length(B),2)
 			accum_score += (length(B) - i + 1) * pos_factor
 			total_elems += 1
 		end if
 	end for

	return power(accum_score / power(total_elems,2), 0.5)
end function

--**
-- Indicates that [[:remove_subseq]] must not replace removed sub-sequences
-- with an alternative value.
public constant SEQ_NOALT = {{1.23456}}


--**
-- removes all sub-sequences from the supplied sequence, optionally
-- replacing them with a supplied alternative value. One common use
-- is to remove all strings from a mixed set of numbers and strings.
--
-- Parameters:
-- # ##source_list## : A sequence from which sub-sequences are removed.
-- # ##alt_value## : An object. The default is ##SEQ_NOALT##, which causes sub-sequences
--                  to be physically removed, otherwise any other value will be
--                  used to replace the sub-sequence.
--
-- Returns:
-- A **sequence**, which contains only the atoms from ##source_list## and optionally
-- the ##alt_value## where sub-sequences used to be.
--
-- Example 1:
-- <eucode>
-- sequence s = remove_subseq({4,6,"Apple",0.1, {1,2,3}, 4})
-- -- 's' is now {4, 6, 0.1, 4} -- length now 4
-- s = remove_subseq({4,6,"Apple",0.1, {1,2,3}, 4}, -1)
-- -- 's' is now {4, 6, -1, 0.1, -1, 4} -- length unchanged.
-- </eucode>
--

public function remove_subseq( sequence source_list, object alt_value = SEQ_NOALT)
	sequence lResult
	integer lCOW = 0

	for i = 1 to length(source_list) do
		if atom(source_list[i]) then
			if lCOW != 0 then
				if lCOW != i then
					lResult[lCOW] = source_list[i]
				end if
				lCOW += 1
			end if
			continue
		end if

		if lCOW = 0 then
			lResult = source_list
			lCOW = i
		end if
		if not equal(alt_value, SEQ_NOALT) then
			lResult[lCOW] = alt_value
			lCOW += 1
		end if

	end for

	if lCOW = 0 then
		return source_list
	end if
	return lResult[1.. lCOW - 1]
end function

public enum
	--**
	-- Remove items while preserving the original order of the unique items.
	--
	-- See Also:
	--   [[:remove_dups]]
	--
	
	RD_INPLACE,
	
	--**
	-- Assume that the elements in ##source_data## are already sorted. If they
	-- are not already sorted, this option merely removed adjacent duplicate elements.
	--
	-- See Also:
	--   [[:remove_dups]]
	--
	
	RD_PRESORTED,

	--**
	-- Will return the unique elements in ascending sorted order.
	--
	-- See Also:
	--   [[:remove_dups]]
	--
	
	RD_SORT

--**
-- removes duplicate elements.
--
-- Parameters:
-- # ##source_data## : A sequence that may contain duplicated elements
-- # ##proc_option## : One of ##RD_INPLACE##, ##RD_PRESORTED##, or ##RD_SORT##.
-- ** ##RD_INPLACE## removes items while preserving the original order of the unique items.
-- ** ##RD_PRESORTED## assumes that the elements in ##source_data## are already sorted. If they
-- are not already sorted, this option merely removed adjacent duplicate elements.
-- ** ##RD_SORT## will return the unique elements in ascending sorted order.
--
-- Returns:
-- A **sequence**, that contains only the unique elements from ##source_data##.
--
-- Example 1:
-- <eucode>
-- sequence s = { 4,7,9,7,2,5,5,9,0,4,4,5,6,5}
-- ? remove_dups(s, RD_INPLACE) --> {4,7,9,2,5,0,6}
-- ? remove_dups(s, RD_SORT) --> {0,2,4,5,6,7,9}
-- ? remove_dups(s, RD_PRESORTED) --> {4,7,9,7,2,5,9,0,4,5,6,5}
-- ? remove_dups(sort(s), RD_PRESORTED) --> {0,2,4,5,6,7,9}
-- </eucode>
--
public function remove_dups(sequence source_data, integer proc_option = RD_PRESORTED)
	integer lTo
	integer lFrom

	if length(source_data) < 2 then
		return source_data
	end if

	if proc_option = RD_SORT then
		source_data = stdsort:sort(source_data)
		proc_option = RD_PRESORTED
	end if
	if proc_option = RD_PRESORTED then
		lTo = 1
		lFrom = 2

		while lFrom <= length(source_data) do
			if not equal(source_data[lFrom], source_data[lTo]) then
				lTo += 1
				if lTo != lFrom then
					source_data[lTo] = source_data[lFrom]
				end if
			end if
			lFrom += 1
		end while
		return source_data[1 .. lTo]
	end if

	sequence lResult
	lResult = {}
	for i = 1 to length(source_data) do
		if not find(source_data[i], lResult) then
			lResult = append(lResult, source_data[i])
		end if
	end for
	return lResult

end function

public enum 
	COMBINE_UNSORTED = 0,
	COMBINE_SORTED,
	$
	
--**
-- combines all the sub-sequences into a single, optionally sorted, list.
--
-- Parameters:
-- # ##source_data## : A sequence that contains sub-sequences to be combined.
-- # ##proc_option## : An integer; ##COMBINE_UNSORTED## to return a non-sorted list and 
--                 ##COMBINE_SORTED## (the default) to return a sorted list.
--
-- Returns:
-- A **sequence**, that contains all the elements from all the first-level of
-- sub-sequences from ##source_data##.
--
-- Comments:
-- The elements in the sub-sequences do not have to be pre-sorted.
--
-- Only one level of sub-sequence is combined.
--
-- Example 1:
-- <eucode>
-- sequence s = { {4,7,9}, {7,2,5,9}, {0,4}, {5}, {6,5}}
-- combine(s, COMBINE_SORTED)   --> {0,2,4,4,5,5,5,6,7,7,9,9}
-- combine(s, COMBINE_UNSORTED) --> {4,7,9,7,2,5,9,0,4,5,6,5}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- sequence s = { {"cat", "dog"}, {"fish", "whale"}, {"wolf"}, {"snail", "worm"}}
-- combine(s)                   --> {"cat","dog","fish","snail","whale","wolf","worm"}
-- combine(s, COMBINE_UNSORTED) --> {"cat","dog","fish","whale","wolf","snail","worm"}
-- </eucode>
--
-- Example 3:
-- <eucode>
-- sequence s = { "cat", "dog","fish", "whale", "wolf", "snail", "worm"}
-- combine(s)                   --> "aaacdeffghhiilllmnooorsstwww"
-- combine(s, COMBINE_UNSORTED) --> "catdogfishwhalewolfsnailworm"
-- </eucode>
--

public function combine(sequence source_data, integer proc_option = COMBINE_SORTED)
	sequence lResult
	integer lTotalSize = 0
	integer lPos

	if length(source_data) = 0 then
		return {}
	end if

	if length(source_data) = 1 then
		return source_data[1]
	end if

	for i = 1 to length(source_data) do
		lTotalSize += length(source_data[i])
	end for

	lResult = repeat(0, lTotalSize)
	lPos = 1
	for i = 1 to length(source_data) do
		lResult[lPos .. length(source_data[i]) + lPos - 1] = source_data[i]
		lPos += length(source_data[i])
	end for
	
	if proc_option = COMBINE_SORTED then
		return stdsort:sort(lResult)
	else
		return lResult
	end if
end function

--**
-- ensures that the supplied sequence is at least the supplied minimum length.
--
-- Parameters:
-- # ##source_data## : An object that might need extending.
-- # ##min_size##: An integer. The minimum length that ##source_data## must be.
-- The default is to increase the length of ##source_data# by 50%.
-- # ##new_data##: An object. This used to when ##source_data## needs to be extended,
-- in which case it is appended as many times as required to make the length
-- equal to ##min_size##. The default is 0.
--
-- Returns:
-- A **sequence**. The padded sequence, unchanged if its size was not less
-- than ##min_size## on input.
--
-- Comments:
-- Pads ##source_data## to the right until its length reaches ##min_size## 
-- using ##new_data## as filler.
-- 
-- Example 1:
-- <eucode>
-- sequence s
-- s = minsize({4,3,6,2,7,1,2}, 10, -1) --> {4,3,6,2,7,1,2,-1,-1,-1}
-- s = minsize({4,3,6,2,7,1,2},  5, -1) --> {4,3,6,2,7,1,2}
-- </eucode>
--
public function minsize(object source_data, integer min_size = floor(length(source_data) * 1.5), object new_data = 0)

    if length(source_data) < min_size then
        source_data &= repeat(new_data, min_size - length(source_data))
    end if
    
    return source_data
end function
