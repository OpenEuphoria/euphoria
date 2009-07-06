-- (c) Copyright Rapid Deployment Software - See License.txt
--

--****
-- == Sorting
--
-- <<LEVELTOC depth=2>>
--

--****
-- === Constants
--

public constant
	--**
	-- ascending sort order, always the default.
	--
	-- When a sequence is sorted in ##ASCENDING## order, its first element
	-- is the smallest as per the sort order and its last element is the
	-- largest
	ASCENDING = 1,
	
	--** The normal sort order used by the custom comparison routine.
	NORMAL_ORDER = ASCENDING,
	
	--**
	-- descending sort order, which is the reverse of ##ASCENDING##.
	DESCENDING = -1,
	
	--** Reverses the sense of the order returned by a custom comparison routine.
	REVERSE_ORDER = DESCENDING

include std/text.e -- upper/lower

--****
-- === Routines
--

--**
-- Sort the elements of a sequence into ascending order.
--
-- Parameters:
--	 # ##x##: The sequence to be sorted.
--   # ##order##: the sort order. Default is ##ASCENDING##.
--
-- Returns:
--	 A **sequence**, a copy of the original sequence in ascending order
--
-- Comments:
--
-- The elements can be atoms or sequences. 
--
--	 The standard compare()
-- routine is used to compare elements. This means that "##y## is greater than ##x##" is defined by ##compare(y, x)=1##.
--
-- This function uses the "Shell" sort algorithm. This sort is not "stable", i.e. elements that are considered equal might
-- change position relative to each other.
--
-- Example 1:
--   <eucode>
--   constant student_ages = {18,21,16,23,17,16,20,20,19}
--   sequence sorted_ages
--   sorted_ages = sort( student_ages )
--   -- result is {16,16,17,18,19,20,20,21,23}
--   </eucode>
--
-- See Also:
--     [[:compare]], [[:custom_sort]]

public function sort(sequence x, integer order = ASCENDING)
	integer gap, j, first, last
	object tempi, tempj

	if order >= 0 then
		order = -1
	else
		order = 1
	end if
	
	
	last = length(x)
	gap = floor(last / 10) + 1
	while 1 do
		first = gap + 1
		for i = first to last do
			tempi = x[i]
			j = i - gap
			while 1 do
				tempj = x[j]
				if eu:compare(tempi, tempj) != order then
					j += gap
					exit
				end if
				x[j+gap] = tempj
				if j <= gap then
					exit
				end if
				j -= gap
			end while
			x[j] = tempi
		end for
		if gap = 1 then
			return x
		else
			gap = floor(gap / 7) + 1
		end if
	end while
end function

--**
-- Sort the elements of a sequence according to a user-defined order.
--
-- Parameters:
--		# ##custom_compare##: an integer, the routine-id of the user defined routine that compares two items which appear in the sequence to sort.
--		# ##x##: the sequence of items to be sorted.
--		# ##data##: an object, either {} (no custom data, the default), an atom or a non-empty sequence.
--		# ##order##: an integer, either ##NORMAL_ORDER## (the default) or ##REVERSE_ORDER##.
--
-- Returns:
--     A **sequence**, a copy of the original sequence in sorted order
--
-- Errors:
-- If the user defined routine does not return according to the specifications in the 
-- //Comments// section below, an error will occur.
--
-- Comments:
-- * If some user data is being provided, that data must be either an atom or 
-- a sequence with at least one element. **NOTE** only the first element is passed
-- to the user defined comparison routine, any other elements are just ignored. 
-- The user data is not used or inspected it in any way other than passing it
-- to the user defined routine.
--
-- * The user defined routine must return an integer //comparison result//
-- ** a **negative** value if object A must appear before object B
-- ** a **positive** value if object B must appear before object A
-- ** 0 if the order does not matter
-- >
-- **NOTE:** The meaning of the value returned by the user-defined routine is reversed 
-- when ##order = REVERSE_ORDER##.
-- The default is ##order = NORMAL_ORDER##, which sorts in order returned by the 
-- custom comparison routine.
--<
-- * When no user data is provided, the user defined routine must accept two
--  objects (A, B) and return just the //comparison result//.
--
-- * When some user data is provided, the user defined routine must take three
-- objects (A, B , data). It must return either...
-- ** an integer, which is a //comparison result//
-- ** a two-element sequence, in which the first element is a //comparison result//
-- and the second element is the updated user data that is to be used for the next call 
-- to the user defined routine.
--
-- * The elements of ##x## can be atoms or sequences. Each time that the
-- sort needs to compare two items in the sequence, it calls
-- the user-defined function to determine the order.
--
-- * This function uses the "Shell" sort algorithm. This sort is not "stable", 
--  i.e. elements that are considered equal might change position relative to
--  each other.
--
-- Example 1:
-- <eucode>
-- constant students = {{"Anne",18},   {"Bob",21},
--                      {"Chris",16},  {"Diane",23},
--                      {"Eddy",17},   {"Freya",16},
--                      {"George",20}, {"Heidi",20},
--                      {"Ian",19}}
-- sequence sorted_byage
-- function byage(object a, object b)
--  ----- If the ages are the same, compare the names otherwise just compare ages.
--     if equal(a[2], b[2]) then
--         return compare(upper(a[1]), upper(b[1]))
--     end if
--     return compare(a[2], b[2])
-- end function
--
-- sorted_byage = custom_sort( routine_id("byage"), students )
-- -- result is {{"Chris",16}, {"Freya",16},
-- --            {"Eddy",17},  {"Anne",18},
-- --            {"Ian",19},   {"George",20},
-- --            {"Heidi",20}, {"Bob",21},
-- --            {"Diane",23}}
--
-- sorted_byage = custom_sort( routine_id("byage"), students,, REVERSE_ORDER )
-- -- result is {{"Diane",23}, {"Bob",21},
-- --            {"Heidi",20}, {"George",20},
-- --            {"Ian",19},   {"Anne",18},
-- --            {"Eddy",17},  {"Freya",16},
-- --            {"Chris",16}}
-- --
-- </eucode>
--
-- Example 2:
-- <eucode>
-- constant students = {{"Anne","Baxter",18}, {"Bob","Palmer",21},
--                      {"Chris","du Pont",16},{"Diane","Fry",23},
--                      {"Eddy","Ammon",17},{"Freya","Brash",16},
--                      {"George","Gungle",20},{"Heidi","Smith",20},
--                      {"Ian","Sidebottom",19}}
-- sequence sorted
-- function colsort(object a, object b, sequence cols)
--     integer sign
--     for i = 1 to length(cols) do
--         if cols[i] < 0 then
--             sign = -1
--             cols[i] = -cols[i]
--         else
--             sign = 1
--         end if
--         if not equal(a[cols[i]], b[cols[i]]) then
--             return sign * compare(upper(a[cols[i]]), upper(b[cols[i]]))
--         end if
--     end for
--
--     return 0
-- end function
--
-- -- Order is age:descending, Surname, Given Name
-- sequence column_order = {-3,2,1}
-- sorted = custom_sort( routine_id("colsort"), students, {column_order} )
-- -- result is 
-- {
--     {"Diane","Fry",23},
--     {"Bob","Palmer",21},
--     {"George","Gungle",20},
--     {"Heidi","Smith",20},
--     {"Ian","Sidebottom",19},
--     {"Anne", "Baxter", 18 },
--     {"Eddy","Ammon",17},
--     {"Freya","Brash",16},
--     {"Chris","du Pont",16}
-- }
--
-- sorted = custom_sort( routine_id("colsort"), students, {column_order}, REVERSE_ORDER )
-- -- result is 
-- {
--     {"Chris","du Pont",16},
--     {"Freya","Brash",16},
--     {"Eddy","Ammon",17},
--     {"Anne", "Baxter", 18 },
--     {"Ian","Sidebottom",19},
--     {"Heidi","Smith",20},
--     {"George","Gungle",20},
--     {"Bob","Palmer",21},
--     {"Diane","Fry",23}
-- }
-- </eucode>
-- See Also:
--   [[:compare]], [[:sort]]

public function custom_sort(integer custom_compare, sequence x, object data = {}, integer order = NORMAL_ORDER)
	integer gap, j, first, last
	object tempi, tempj, result
	sequence args = {0, 0}

	if order >= 0 then
		order = -1
	else
		order = 1
	end if
	
	if atom(data) then
		args &= data
	elsif length(data) then
		args = append(args, data[1])
	end if

	last = length(x)
	gap = floor(last / 10) + 1
	while 1 do
		first = gap + 1
		for i = first to last do
			tempi = x[i]
			args[1] = tempi
			j = i - gap
			while 1 do
				tempj = x[j]
				args[2] = tempj
				result = call_func(custom_compare, args)
				if sequence(result) then
					args[3] = result[2]
					result = result[1]
				end if
				if eu:compare(result, 0) != order then
					j += gap
					exit
				end if
				x[j+gap] = tempj
				if j <= gap then
					exit
				end if
				j -= gap
			end while
			x[j] = tempi
		end for
		if gap = 1 then
			return x
		else
			gap = floor(gap / 7) + 1
		end if
	end while
end function


function column_compare(object a, object b, object cols)
-- Local function used by sort_columns()
	integer sign
	integer column
	
	for i = 1 to length(cols) do
		if cols[i] < 0 then
			sign = -1
			column = -cols[i]
		else
			sign = 1
			column = cols[i]
		end if
		if column <= length(a) then
			if column <= length(b) then
				if not equal(a[column], b[column]) then
					return sign * eu:compare(upper(a[column]), upper(b[column]))
				end if
			else
				return sign * -1
			end if
		else
			if column <= length(b) then
				return sign * 1
			else
				return 0
			end if
		end if
	end for
	return 0
end function

--**
-- Sort the rows in a sequence according to a user-defined
-- column order.
--
-- Parameters:
-- # ##x##: a sequence, holding the sequences to be sorted.
-- # ##column_list##: a list of columns indexes ##x## is to be sorted by.
--
-- Returns:
--	 A **sequence**, a copy of the original sequence in sorted order.
--
-- Comments:
--
-- ##x## must be a sequence of sequences.
--
-- A non-existent column is treated as coming before an existing column. This
-- allows sorting of records that are shorter than the columns in the
-- column list.
--
-- By default,
-- columns are sorted in ascending order. To sort in descending
-- order, make the column number negative.
--
--	This function uses the "Shell" sort algorithm.
-- This sort is not "stable", i.e. elements that are considered equal might
-- change position relative to each other.
--
-- Example 1:
--   <eucode>
--   sequence dirlist
--   dirlist = dir("c:\\temp")
--   sequence sorted
--   -- Order is Size:descending, Name
--   sorted = sort_columns( dirlist, {-D_SIZE, D_NAME} )
--   </eucode>
--
-- See Also:
--	 [[:compare]], [[:sort]]

public function sort_columns(sequence x, sequence column_list)
	return custom_sort(routine_id("column_compare"), x, {column_list})
end function

