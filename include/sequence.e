-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.2
-- Sequence routines

-- moved from misc.e
global function reverse(sequence s)
-- reverse the top-level elements of a sequence.
-- Thanks to Hawke' for helping to make this run faster.
    integer lower, n, n2
    sequence t
    
    n = length(s)
    n2 = floor(n/2)+1
    t = repeat(0, n)
    lower = 1
    for upper = n to n2 by -1 do
	    t[upper] = s[lower]
	    t[lower] = s[upper]
	    lower += 1
    end for
    return t
end function

global function findany_from(sequence needles, sequence haystack, integer start)
    for i = start to length(haystack) do
    	if find(haystack[i],needles) then
    	    return i
    	end if
    end for
    return 0
end function

global function findany(sequence needles, sequence haystack)
    return findany_from(needles, haystack, 1)
end function

global function head(sequence st, atom n)
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

global function tail(sequence st, atom n)
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

-- TODO: document
global function trim_head(sequence str, object what)
    integer cut
    cut = 1

    if integer(what) then
        if what = 0 then
            what = " \t\r\n"
        else
            what = {what}
        end if
    end if

    for i = 1 to length(str) do
        if find(str[i], what) = 0 then
            cut = i
            exit
        end if
    end for

    return str[cut..$]
end function

-- TODO: document
global function trim_tail(sequence str, object what)
    integer cut
    cut = length(str)

    if integer(what) then
        if what = 0 then
            what = " \t\r\n"
        else
            what = {what}
        end if
    end if

    for i = length(str) to 1 by -1 do
        if find(str[i], what) = 0 then
            cut = i
            exit
        end if
    end for

    return str[1..cut]
end function

-- TODO: document
global function trim(sequence str, object what)
    return trim_tail(trim_head(str, what), what)
end function

-- TODO: document
global function truncate(sequence s, integer size)
    if size < length(s) then
        return s[1..size]
    end if
    return s
end function

-- TODO: document
global function pad_head(sequence str, integer size)
    if size <= length(str) then
        return str
    end if
    return repeat(' ', size - length(str)) & str
end function

-- TODO: document
global function pad_tail(sequence str, integer size)
    if size <= length(str) then
        return str
    end if
    return str & repeat(' ', size - length(str))
end function

-- TODO: document
global function chunk(sequence s, integer size)
    sequence ns
    integer stop

    ns = {}

    for i = 1 to length(s) by size do
        stop = i + size - 1
        if stop > length(s) then
            stop = length(s)
        end if

        ns = append(ns, s[i..stop])
    end for

    return ns
end function

-- TODO: document
global function flatten(sequence s)
   sequence ret
   object x

   ret = {}
   for i = 1 to length(s) do
      x = s[i]
      if atom(x) then
         ret &= x
      else
         ret &= flatten(x)
      end if
   end for

   return ret
end function

-- TODO: document
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

-- TODO: document
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

-- TODO: document
global function find_replace(sequence source, sequence what, sequence repl_with, integer max)
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
