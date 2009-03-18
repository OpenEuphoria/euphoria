		-------------------------------------
		-- Example Program from the Manual --
		-------------------------------------

function merge_sort(sequence x)
-- put x into ascending order using a recursive merge sort
    integer n, mid
    sequence merged, a, b

    n = length(x)
    if n = 0 or n = 1 then
	return x  -- trivial case
    end if

    mid = floor(n/2)
    a = merge_sort(x[1..mid])       -- sort first half of x 
    b = merge_sort(x[mid+1..n])     -- sort second half of x

    -- merge the two sorted halves into one
    merged = {}
    while length(a) > 0 and length(b) > 0 do
	if compare(a[1], b[1]) < 0 then
	    merged = append(merged, a[1])
	    a = a[2..length(a)]
	else
	    merged = append(merged, b[1])
	    b = b[2..length(b)]
	end if
    end while
    return merged & a & b  -- merged data plus leftovers
end function

procedure print_sorted_list()
-- generate sorted_list from list 
    ? merge_sort( {9, 10, 3, 1, 4, 5, 8, 7, 6, 2} )
    ? merge_sort( {1.5, -9, 1e6, 100} )
    printf(1, "%s, %s, %s\n", merge_sort({"oranges", "apples", "bananas"}))  
end procedure

print_sorted_list()     -- this command starts the program 
 
