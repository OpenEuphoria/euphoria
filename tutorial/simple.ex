	--------------------------------
	-- A very simple sort program --
	--------------------------------
with trace -- make everything traceable
trace(1)   -- turn on tracing

function simple_sort(sequence x)
object temp 
    for i = 1 to length(x) - 1 do
	for j = i + 1 to length(x) do
	    if compare(x[j],x[i]) < 0 then
		-- swap x[j], x[i]
		temp = x[j]    
		x[j] = x[i]
		x[i] = temp
	    end if
	end for
    end for
    return x
end function

-- Hold down the Enter key and 
-- watch x get sorted before your eyes! 
? simple_sort( {9, 10, 3, 1, 4, 5, 8, 7, 6, 2} )
