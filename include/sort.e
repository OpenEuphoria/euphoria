-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Sorting
--
-- === Routines
--

include sequence.e -- upper/lower

--**
-- Sort the elements of a sequence into ascending order.
--
-- The elements can be atoms or sequences. The standard compare()
-- routine is used to compare elements.
--
-- Parameters:
--	 * x = The sequence to be sorted.
--
-- Returns:
--	 sequence - The original sequence in ascending order
--
-- Comments:
--	 This uses the "Shell" sort algorithm.
--
-- This sort is not "stable", i.e. elements that are considered equal might
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
--     search:compare, sort_reverse, sort_user, custom_sort

global function sort(sequence x)
	integer gap, j, first, last
	object tempi, tempj

	last = length(x)
	gap = floor(last / 10) + 1
	while 1 do
		first = gap + 1
		for i = first to last do
			tempi = x[i]
			j = i - gap
			while 1 do
				tempj = x[j]
				if compare(tempi, tempj) >= 0 then
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
-- Sort the elements of a sequence according to a user-defined 
-- order.
--
-- The elements can be atoms or sequences. Each time that the
-- sort needs to compare two items in the sequence, it calls
-- the user-defined function to determine the order. 
--
-- Parameters:
--     **custom_compare** = A routine-id of the user defined routine that compares
--     two items in x.
--
--	   The user defined routine must accept two objects (A and B) and return
--	   an integer. It returns -1 if object A must appear before object B,
--	   1 if object B must appear before object A, and 0 if the order
--	   doesn't matter.
--
--	   **x** = The sequence of items to be sorted.
--
-- Returns:
--     sequence - The original sequence in sorted order
--
-- Comments:
--     This uses the "Shell" sort algorithm.
--
--     This sort is not "stable", i.e. elements that are considered equal might
--     change position relative to each other.
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
-- </eucode>
--
-- See Also:
--   search:compare, sort, sort_reverse, sort_user

global function custom_sort(integer custom_compare, sequence x)
	integer gap, j, first, last
	object tempi, tempj

	last = length(x)
	gap = floor(last / 10) + 1
	while 1 do
		first = gap + 1
		for i = first to last do
			tempi = x[i]
			j = i - gap
			while 1 do
				tempj = x[j]
				if call_func(custom_compare, {tempi, tempj}) >= 0 then
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

-- Local function used by sort_reverse()
function reverse_comp(object a, object b)
	return -(compare(a,b))
end function

--**
-- Sort the elements of a sequence into descending order.
--
-- The elements can be atoms or sequences. The standard compare()
-- routine is used to compare elements.
--
-- Parameters:
--	 * x = The sequence to be sorted.
--
-- Returns:
--	 sequence - The original sequence in descending order
--
-- Comments:
--	 This uses the "Shell" sort algorithm.
--
-- This sort is not "stable", i.e. elements that are considered equal might
-- change position relative to each other.
--
-- Example 1:
--   <eucode>
--   constant student_ages = {18,21,16,23,17,16,20,20,19}
--   sequence sorted_ages
--   sorted_ages = sort( student_ages )
--   -- result is {23,21,20,20,19,18,17,16,16}
--   </eucode>
--
-- See Also:
--	 search:compare, sort, sort_user, custom_sort

global function sort_reverse(sequence x)
	return custom_sort(routine_id("reverse_comp"), x)
end function

--**
-- Sort the elements of a sequence according to a user-defined order.
--
-- The elements can be atoms or sequences. Each time that the sort needs to compare two 
-- items in the sequence, it calls the user-defined function to determine the order. 
--
-- Parameters:
--   **custom_compare** = A routine-id of the user defined routine that compares
--     two items in x.
--
--   The user defined routine must accept two objects (A and B) and return
--   an integer. It returns -1 if object A must appear before object B,
--   1 if object B must appear before object A, and 0 if the order
--   doesn't matter.
--
--   **x** = The sequence of items to be sorted.
--
--   **user_data** = Anything that is needed by the user defined routine. (defaults to 0)
--
-- Returns:
--   sequence - The original sequence in sorted order
--
-- Comments:
--   This uses the "Shell" sort algorithm.
--
--   This sort is not "stable", i.e. elements that are considered equal might
--   change position relative to each other.
--
-- Example 1:
-- <eucode>
-- constant students = {{"Anne","Baxter",18}, {"Bob","Palmer",21},
--                      {"Chris","du Pont",16},{"Diane","Fry",23},
--                      {"Eddy","Ammon",17},{"Freya","Brash",16},
--                      {"George","Gungle",20},{"Heidi","Smith",20},
--                      {"Ian","Sidebottom",19}}
-- sequence sorted
-- function colsort(object a, object b, object cols)
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
-- -- sorted = sort_user( routine_id("colsort"), students, {-3,2,1} )
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
-- </eucode>
--
-- See Also:
--	 search:compare, sort, sort_reverse, sort_user

export function sort_user(integer custom_compare, sequence x, object user_data=0)
	integer gap, j, first, last
	object tempi, tempj

	last = length(x)
	gap = floor(last / 10) + 1
	while 1 do
		first = gap + 1
		for i = first to last do
			tempi = x[i]
			j = i - gap
			while 1 do
				tempj = x[j]
				if call_func(custom_compare, {tempi, tempj, user_data}) >= 0 then
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
					return sign * compare(upper(a[column]), upper(b[column]))
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
-- The elements must be sequences.
--
-- Parameters:
-- **x** = The set of sequences to be sorted.
--
-- **column_list** = A list of columns to be sorted. By default,
-- columns are sorted in ascending order. To sort in descending
-- order, make the column number negative.
--
-- A non-existant column is treated as coming before an existing column. This
-- allows sorting of records that are shorter than the columns in the
-- column list.
--
-- Returns:
--	 sequence - The original sequence in sorted order
--
-- Comments:
--	This uses the "Shell" sort algorithm.
--
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
--	 search:compare, sort, sort_reverse, sort_user

export function sort_columns(sequence x, sequence column_list)
	return sort_user(routine_id("column_compare"), x, column_list)
end function

