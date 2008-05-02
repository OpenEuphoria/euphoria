-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.2
-- Sequence routines

include machine.e

global function find_any_from(sequence needles, sequence haystack, integer start)
    for i = start to length(haystack) do
    	if find(haystack[i],needles) then
    	    return i
    	end if
    end for
    return 0
end function

global function find_any(sequence needles, sequence haystack)
    return find_any_from(needles, haystack, 1)
end function

global function find_all(object x, sequence source, integer from)
    sequence ret

    ret = {}

    while 1 do
        from = find_from(x, source, from)
        if from = 0 then
            exit
        end if

        ret &= from

        from += 1
    end while

    return ret
end function

global function match_all(object x, sequence source, integer from)
    sequence ret

    ret = {}

    while 1 do
        from = match_from(x, source, from)
        if from = 0 then
            exit
        end if

        ret &= from

        from += length(x)
    end while

    return ret
end function

--Find x as an element of s starting from index start going down to 1
--If start<1 then it is an offset from the end of s
global function rfind_from(object x, sequence s, integer start)
    integer len

	len=length(s)

	if (start > len) or (len + start < 1) then
        crash("third argument of rfind_from() is out of bounds (%d)", {start})
	end if

	if start < 1 then
		start = len + start
	end if

	for i = start to 1 by -1 do
		if equal(s[i], x) then
			return i
		end if
	end for

	return 0
end function

global function rfind(object x, sequence s)
	return rfind_from(x, s, length(s))
end function

--Try to match x against some slice of s, starting from index start and going down to 1
--if start<0 then it is an offset from the end of s
global function rmatch_from(sequence x, sequence s, integer start)
    integer len,lenx

	len = length(s)
	lenx = length(x)

	if lenx = 0 then
        crash("first argument of rmatch_from() must be a non-empty sequence", {})
	elsif (start > len) or  (len + start < 1) then
        crash("third argument of rmatch_from is out of bounds (%d)", {start})
	end if

	if start < 1 then
		start = len + start
	end if

	if start + lenx - 1 > len then
		start = len - lenx + 1
	end if

	lenx-= 1

	for i=start to 1 by -1 do
		if equal(x, s[i..i + lenx]) then
			return i
		end if
	end for

	return 0
end function

global function rmatch(sequence x, sequence s)
	if length(x)=0 then
        crash("first argument of rmatch_from() must be a non-empty string", {})
	end if

	return rmatch_from(x, s, length(s))
end function

global function find_replace(sequence what, sequence repl_with, sequence source, integer max)
    integer posn
    
    if length(what) then
        posn = match(what, source)
        while posn do
            source = source[1..posn-1] & repl_with & source[posn+length(what)..length(source)]
            posn = match_from(what, source, posn+length(repl_with))
            max -= 1
            if max = 0 then
                exit
            end if
        end while
    end if

    return source
end function
