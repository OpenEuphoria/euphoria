-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.1
-- Sorting

-- Sort the elements of a sequence into ascending order, using "Shell" sort.

global function sort(sequence x)
-- Sort a sequence into ascending order. The elements can be atoms or 
-- sequences. The standard compare() routine is used to compare elements.
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
	    gap = floor(gap / 3.5) + 1
	end if
    end while
end function

global function custom_sort(integer custom_compare, sequence x)
-- Sort a sequence. A user-supplied comparison function is used 
-- to compare elements. Note that this sort is not "stable", i.e.
-- elements that are considered equal might change position relative
-- to each other.
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
	    gap = floor(gap / 3.5) + 1
	end if
    end while
end function


