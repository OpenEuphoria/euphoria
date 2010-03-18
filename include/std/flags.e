-- (c) Copyright - See License.txt

namespace flags
--****
-- == flags



include std/search.e
include std/pretty.e
include std/sequence.e

function count_bits( integer i )
	atom n
	integer cnt = 0
    while n < power(2,31) do
		if and_bits(i,n) then
		    cnt += 1
		end if
		n = 2 * n
    end while
	return cnt
end function
	
function only_one_bit( integer i )
    atom n
    n = 1
    while n < power(2,31) do
		if i = n then
		    return 1
		end if
	n = 2 * n
    end while
    return 0
end function

--**
-- creates a string representation of a sequence of flag numbers or a
-- single number that was derived from a set of or_bits() operations.
--
-- flag_names is a dictionary: a sequence of value name pairs
-- 
-- 
public function flags_to_string(object o, sequence flag_names )
	-- s is a sequence of strings
    sequence s = {}
	sequence zero_name = "0"
    if sequence(o) then
		for i = 1 to length(o) do
			if not integer(o[i]) then
				o[i] = pretty_sprint(o[i],{2})
			else
				o[i] = vlookup(o[i], flag_names, 1, 2, sprintf("%d(unknown flag)",{o[i]}) )
			end if
		end for
		s = o
    else
		for i = 1 to length(flag_names) do
			if flag_names[i][1] = 0 then
				zero_name = flag_names[i][2]
				continue
			end if
			if not only_one_bit(flag_names[i][1]) and
				and_bits( flag_names[i][1], o ) = flag_names[i][1] then
				s = append(s,flag_names[i][2])
			end if
		end for
		for i = 1 to length(flag_names) do
			if only_one_bit(flag_names) and
				and_bits( flag_names[i][1], o ) = flag_names[i][1] then
				s = append(s,flag_names[i][2])
			end if
		end for
    end if
    -- now convert s to a string
    if compare(s,{})=0 then
		s = zero_name
    else
		s = pretty_sprint(s,{2})
    end if
    return s
end function

