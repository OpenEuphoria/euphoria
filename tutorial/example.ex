include std/console.e
sequence original_list

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
-- generate sorted_list from original_list
    sequence sorted_list
    
    original_list = {19, 10, 23, 41, 84, 55, 98, 67, 76, 32}
    sorted_list = merge_sort(original_list)
    for i = 1 to length(sorted_list) do
    	display("Number [] was at position [:2], now at [:2]", 
    	        {sorted_list[i], find(sorted_list[i], original_list), i}
    	    )
    end for
end procedure

print_sorted_list()     -- this command starts the program
