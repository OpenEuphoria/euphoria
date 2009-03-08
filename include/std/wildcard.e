-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
-- wildcard.e
--****
-- == Wildcard Matching
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>
--

--****
-- === Routines

include std/text.e as txt -- upper/lower

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

--**
-- Determine whether a string matches a pattern. The pattern may contain * and ? wildcards.
--
-- Parameters:
--		# ##pattern##: a string, the pattern to match
--		# ##string##: the string to be matched against
--
-- Returns 
--		An **integer**, TRUE if ##string## matches ##pattern##, else FALSE.
--
-- Comments:
--
-- Character comparisons are case sensitive.
-- If you want case insensitive comparisons, pass both ##pattern## and ##string## through [[:upper]](), or both through [[:lower]](), before calling ##wildcard_match##().
--
-- If you want to detect a pattern anywhere within a string, add * to each end of the pattern: 
--  {{{
--  i = wildcard_match('*' & pattern & '*', string)
--  }}}
--  
--  There is currently no way to treat * or ? literally in a pattern.
--
-- Example 1: 
-- <eucode> 
--  i = wildcard_match("A?B*", "AQBXXYY")
-- -- i is 1 (TRUE)
-- </eucode>
--
-- Example 2:  
-- <eucode> 
--  i = wildcard_match("*xyz*", "AAAbbbxyz")
-- -- i is 1 (TRUE)
-- </eucode>
--
-- Example 3:
-- <eucode> 
--  i = wildcard_match("A*B*C", "a111b222c")
-- -- i is 0 (FALSE) because upper/lower case doesn't match
-- </eucode>
--
-- Example 4: 
-- ##bin/search.ex##
--
-- See Also: 
-- [[:wildcard_file]], [[:upper]], [[:lower]], [[:Regular expressions]]

public function wildcard_match(sequence pattern, sequence string)
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

--**
-- Determine whether a file name matches a wildcard pattern.
--
-- Parameters:
--		# ##pattern##: a string, the pattern to match
--		# ##filename##: the string to be matched against
--
-- Returns 
--		An **integer**, TRUE if ##filename## matches ##pattern##, else FALSE.
--
-- Comments:
--
--   Similar to DOS wild card matching but better. For example, 
--   "*ABC.*" in DOS will match *all* files, where this function will 
--   only match when the file name part has "ABC" at the end.
--  
-- * matches any 0 or more characters, ? matches any single character. On //Unix// the character comparisons are case sensitive. On DOS and Windows they are not.
--
-- You might use this function to check the output of the [[:dir]]() routine for file names that match a pattern supplied by the user of your program.
--
-- In //DOS// "*ABC.*" will match all files. ##wildcard_file("*ABC.*", s)## will only match when the file name part has "ABC" at the end (as you would expect).
--  
-- Example 1: 
-- <eucode> 
--  i = wildcard_file("AB*CD.?", "aB123cD.e")
-- -- i is set to 1 on DOS or Windows, 0 on Linux or FreeBSD
-- </eucode>
--
-- Example 2:  
-- <eucode> 
--  i = wildcard_file("AB*CD.?", "abcd.ex")
-- -- i is set to 0 on all systems, 
-- -- because the file type has 2 letters not 1
-- </eucode>
--
-- Example 3: 
-- ##bin/search.ex##
--
-- See Also: 
-- [[:wildcard_match]], [[:dir]]

public function wildcard_file(sequence pattern, sequence filename)
	ifdef !UNIX then
		pattern = txt:upper(pattern)
		filename = txt:upper(filename)
	end ifdef
	
	if not find('.', pattern) then
		pattern = pattern & '.'
	end if
	
	if not find('.', filename) then
		filename = filename & '.'
	end if
	
	return wildcard_match(pattern, filename)
end function
