--****
-- == Wildcard Matching
--
-- <<LEVELTOC level=2 depth=4>>
--

namespace wildcard

ifdef not UNIX then
	include std/text.e
end ifdef

--****
-- === Routines

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
-- determines whether a string matches a pattern. The pattern may contain ##*## and ##?## wildcards.
--
-- Parameters:
--		# ##pattern## : a string, the pattern to match
--		# ##string## : the string to be matched against
--
-- Returns: 
--		An **integer**, TRUE if ##string## matches ##pattern##, else FALSE.
--
-- Comments:
--
-- Character comparisons are case sensitive.
-- If you want case insensitive comparisons, pass both ##pattern## and ##string## through [[:upper]], or both through [[:lower]], before calling ##is_match##.
--
-- If you want to detect a pattern anywhere within a string, add ##*## to each end of the pattern: 
--  
-- <eucode>
--  i = is_match('*' & pattern & '*', string)
--  </eucode>
--  
--  There is currently no way to treat ##*## or ##?## literally in a pattern.
--
-- Example 1: 
-- <eucode> 
--  i = is_match("A?B*", "AQBXXYY")
-- -- i is 1 (TRUE)
-- </eucode>
--
-- Example 2:  
-- <eucode> 
--  i = is_match("*xyz*", "AAAbbbxyz")
-- -- i is 1 (TRUE)
-- </eucode>
--
-- Example 3:
-- <eucode> 
--  i = is_match("A*B*C", "a111b222c")
-- -- i is 0 (FALSE) because upper/lower case doesn't match
-- </eucode>
--
-- Example 4: 
-- ##.../euphoria/demo/search.ex##
--
-- See Also: 
-- [[:upper]], [[:lower]], [[:Regular Expressions]]
--

public function is_match(sequence pattern, sequence string)
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
