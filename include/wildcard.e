-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.1
-- wild card matching for strings and file names

include misc.e

constant TO_LOWER = 'a' - 'A' 

global function lower(object x)
-- convert atom or sequence to lower case
    return x + (x >= 'A' and x <= 'Z') * TO_LOWER
end function

global function upper(object x)
-- convert atom or sequence to upper case
    return x - (x >= 'a' and x <= 'z') * TO_LOWER
end function

function qmatch(sequence p, sequence s)
-- find pattern p in string s
-- p may have '?' wild cards (but not '*')
    integer k
    
    if not find('?', p) then
	return match(p, s) -- fast
    end if
    -- must allow for '?' wildcard
    for i = 1 to length(s) - length(p) + 1 do
	k = i
	for j = 1 to length(p) do
	    if p[j] != s[k] and p[j] != '?' then
		k = 0
		exit
	    end if
	    k += 1
	end for
	if k != 0 then
	    return i
	end if
    end for
    return 0
end function

constant END_MARKER = -1

global function wildcard_match(sequence pattern, sequence string)
-- returns TRUE if string matches pattern
-- pattern can include '*' and '?' "wildcard" characters
    integer p, f, t 
    sequence match_string
    
    pattern = pattern & END_MARKER
    string = string & END_MARKER
    p = 1
    f = 1
    while f <= length(string) do
	if not find(pattern[p], {string[f], '?'}) then
	    if pattern[p] = '*' then
		while pattern[p] = '*' do
		    p += 1
		end while
		if pattern[p] = END_MARKER then
		    return 1
		end if
		match_string = ""
		while pattern[p] != '*' do
		    match_string = match_string & pattern[p]
		    if pattern[p] = END_MARKER then
			exit
		    end if
		    p += 1
		end while
		if pattern[p] = '*' then
		    p -= 1
		end if
		t = qmatch(match_string, string[f..$])
		if t = 0 then
		    return 0
		else
		    f += t + length(match_string) - 2
		end if
	    else
		return 0
	    end if
	end if
	p += 1
	f += 1
	if p > length(pattern) then
	    return f > length(string) 
	end if
    end while
    return 0
end function

global function wildcard_file(sequence pattern, sequence filename)
-- Return 1 (TRUE) if filename matches the wild card pattern.
-- Similar to DOS wild card matching but better. For example, 
-- "*ABC.*" in DOS will match *all* files, where this function will 
-- only match when the file name part has "ABC" at the end.
    
    if platform() != LINUX then
	pattern = upper(pattern)
	filename = upper(filename)
    end if
    if not find('.', pattern) then
	pattern = pattern & '.'
    end if
    if not find('.', filename) then
	filename = filename & '.'
    end if
    return wildcard_match(pattern, filename)
end function


