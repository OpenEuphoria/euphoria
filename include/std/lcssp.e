-- Copyright (C) 2008 James Jonathan Cook
-- This program is distributed under the terms of the GNU Lesser General Public License.
--
-- This program was written by James Jonathan Cook (jmsck55@gmail.com)
--
--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU Lesser General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU Lesser General Public License for more details.
--
--    You should have received a copy of the GNU Lesser General Public License
--    along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

-- Longest Common Substring Problem
--
-- Author:
-- Translated into Euphoria code by James Cook
-- Adapted from Wikipedia article
--
-- Created:
--     September 1, 2008
--
-- Updated:
--     September 5, 2008
--
-- Copyright:
--     This file is in the public domain
--
-- See Also:
-- http://en.wikipedia.org/wiki/Longest_common_substring_problem

global function LCSubstr_fast(sequence S,sequence T)
-- returns {len1,end1 in S,end1 in T [len2,end2 in S,end2 in T] ...}
    sequence L, C, ret
    integer m, n, z
    m = length(S)
    n = length(T)
    C = repeat(0,n) -- current row, added to save memory
    -- old:
    --L = repeat(repeat(0,n),m)
    --pair = repeat(0,2)
    z = 0
    ret = {}
    for i = 1 to m do
	for j = 1 to n do
	    if equal(S[i],T[j]) then -- updated so any sequence can be used
		if i = 1 or j = 1 then
		    C[j] = 1 -- updated
		    -- old:
		    --L[i][j] = 1
		else
		    C[j] = L[j-1] + 1 -- updated
		    -- old:
		    --L[i][j] = L[i-1][j-1] + 1
		end if
		if C[j] > z then -- updated:
		    z = C[j]
		    ret = {}
		-- old:
		--if L[i][j] > z then
		    --z = L[i][j]
		    --ret = {}
		end if
		if C[j] = z then -- updated
		--if L[i][j] = z then -- old
		    -- store info in ret:
		    ret = append(ret, z)
		    ret = append(ret, i)
		    ret = append(ret, j)
		    -- old:
		    --pair[1] = i
		    --pair[2] = j
		    --pair = pair - z + 1
		    --ret = append(ret, {S[pair[1]..i],pair})
		    -- old:
		    --ret = ret & {{i-z+1,j-z+1,z}}--{S[i-z+1..i]}
		end if
	    end if
	end for
	L = C -- last row, added
	C[1..$] = 0 -- set all elements to 0, added
    end for
    return ret
end function

global function LCSubstr(sequence S,sequence T)
-- Longest Common Substring function
-- dynamic programming approach
-- costs Omega(min(n,m)) time
-- returns:
--  sequence of results, string followed by ordered pairs:
--  {string, {pos in S, pos in T}, [{pos in S, pos in T} [...]]}
-- returns: {} if only the empty set is found
-- Uses a sequence of length(T) to calculate results
-- calls LCSubstr_fast(S,T)
    sequence L, ret, pair, st, lookup
    integer p, z
    
    L = LCSubstr_fast(S,T)
    
    if length(L) = 0 then
	return {}
    end if
    
    -- sort results, grouping duplicates, Note: all are the same length.
    z = L[1]
    p = L[2]
    pair = L[2..3] - z + 1
    st = S[pair[1]..p]
    lookup = {st}
    ret = {{st,pair}}
    for i=4 to length(L) by 3 do
	z = L[i]
	p = L[i+1]
	pair = L[i+1..i+2] - z + 1
	st = S[pair[1]..p]
	p = find(st,lookup)
	if p != 0 then
	    ret[p] = append(ret[p], pair)
	else
	    lookup = append(lookup,st)
	    ret = append(ret, {st,pair})
	end if
    end for
    
    return ret -- grouped ret
end function


-- TEST:
-- 
-- include misc.e
-- 
-- pretty_print(1, LCSubstr(
--  "aa bb aaddcc",
--  "bbaabbccdd"
--  ), {2})
-- 
-- constant vars = {"Jog","Dog","Jim","Jan","Dog","Cat","Sunday","Saturday"}
-- 
-- for i=1 to length(vars) by 2 do
--  pretty_print(1, LCSubstr(
--      vars[i],
--      vars[i+1]
--      ), {2})
-- end for
-- 
-- if getc(0) then
-- end if

--eof
