-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.2
-- Sequence routines

-- TODO: benchmark, would using find() be quicker? We would have to find each
--       needle and then take the minimum number

global function findany_from(sequence needles, sequence haystack, integer start)
    if start > length(haystack) then
        return 0
    end if

    for i = start to length(haystack) do
        for j = 1 to length(needles) do
            if equal(haystack[i], needles[j]) then
                return i
            end if
        end for
    end for
    return 0
end function

global function findany(sequence needles, sequence haystack)
    return findany_from(needles, haystack, 1)
end function

global function left(sequence st, atom n)
	if n >= length(st) then
		return st
	else
		return st[1..n]
	end if
end function

global function mid(sequence st, atom start, atom len)
	if start > length(st) then
		return ""
	elsif len = 0 or len <= -2 then
		return ""
	elsif start+len-1 > length(st) then
		return st[start..$]
	elsif len = -1 then
		return st[start..$]
	elsif len+start-1 < 0 then
		return ""
	elsif start < 1 then
		return st[1..len+start-1]
	else
		return st[start..len+start-1]
	end if
end function

global function slice(sequence st, atom start, atom stop)
    if stop < 0 then stop = length(st) + stop end if
	if stop = 0 then stop = length(st) end if
	if start < 1 then start = 1 end if
	if stop > length(st) then stop = length(st) end if
	if start > stop then return "" end if
	return st[start..stop]
end function

global function right(sequence st, atom n)
	if n >= length(st) then
		return st
	else
		return st[$-n+1..$]
	end if
end function

global function remove(sequence st, integer index)
    if index > length(st) or index < 1 then
        return st
    end if

    return st[1..index-1] & st[index+1..$]
end function

global function remove_range(sequence st, integer start, integer stop)
    if start > length(st) then
        return st
    elsif stop >= length(st) then
        return st[1..start-1]
    end if

    return st[1..start-1] & st[stop+1..$]
end function

global function insert(sequence st, object what, integer index)
    if index > length(st) then
        return st & what
    elsif index = 1 then
        return what & st
    end if

    return st[1..index-1] & what & st[index..$]
end function

global function replace_range(sequence st, object what, integer start, integer stop)
    st = remove_range(st, start, stop)
    return insert(st, what, start)
end function

-- TODO: instead of reassigning st all the time, use the new _from variants of
--       findany and match.

global function split_adv(sequence st, object delim, integer limit, integer any)
	sequence ret
	object pos
	ret={}

    if atom(delim) then
        delim = {delim}
    end if

	while 1 do
        if any then
            pos = findany(delim, st)
        else
    		pos = match(delim, st)
        end if

		if pos then
			ret = append(ret, st[1..pos-1])
			st = st[pos+1..length(st)]
            limit -= 1
            if limit = 1 then
                exit
            end if
		else
			exit
		end if
	end while

	ret = append(ret, st)
	
	return ret
end function

global function split(sequence st, object delim)
    return split_adv(st, delim, 0, 0)
end function

global function join(sequence s, object delim)
    object ret

	if not length(s) then return {} end if

	ret = {}
	for i=1 to length(s)-1 do
		ret &= s[i] & delim
	end for

	ret &= s[length(s)]

	return ret
end function
