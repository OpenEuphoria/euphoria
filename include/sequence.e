-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.2
-- Sequence routines

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
