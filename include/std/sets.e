-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Sets
--
-- <<LEVELTOC depth=2>>
--
-- The sets.e module defines a type for sets and provides basic tools for handling them.
--
-- Other modules may be built upon them, for instance graph handling or simplicial topology, finite groups etc.
--
-- Notes:
--   * A set is an ordered sequence in ascending order, not more, not less
--   * A map from s1 to s2 is a sequence the length of s1 whose elements are indexes into s2,
--     followed by {length(s1),length(s2)}.
--   * An operation of ExF to G is a two dimensional sequence of elements of G, indexed ny
--     ExF, and the triple {card(E),card(F),card(G)}.
--

include std/error.e
include std/sequence.e

procedure report_error(sequence s)
-- Description: Prints an error message on stderr and abort(1)s.
-- Takes: {routine name,error message}; both are strings.
    crash("Error in routine %s in module %s: %s",{s[1],"sets.e",s[2]})
end procedure

--****
-- === Types
--

--**
-- A set is a sequence in which each item is greater than the previous item.
--
-- See Also:
-- [[:compare]]

public type set(object s)
    object x,y

    if atom(s) then
        return 1
    end if
    
    if length(s) < 2 then
        return 1
    end if
    
    x = s[1]
    for i = 2 to length(s) do
        y = s[i]
        if eu:compare(y, x) < 1 then
            return 0
        end if
        
        x = y
    end for
    
    return 1
end type

function bounded_integer(object x,integer lbound,integer ubound)
-- Description: Returns 0 for a non integer or an out of bounds integer, else 1.
-- Takes: object to test; lower allowable bound; upper allowable bound.
-- Returns: 1 if x is an integer between lbound and ubound both included, else 0.
-- See also: map, is_left_unit, is_right_unit
    if not integer(x) then
        return 0
    end if
    if x < lbound then
    	return 0
    end if
    
    if x > ubound then
    	return 0
    end if
    
    return 1
    
end function

--**
-- Returns 1 if a sequence of integers is a valid map descriptor, else 0.
--
-- Comments:
-- A map is a sequence of indexes. Each index is between 1 and the maximum allowed for the particular map.
--
-- Actually, what is being called a ##map## is a class of maps, as the elements of the input
-- sequence, except for the last two, are ordinals rather than set elements. A map 
-- contains the information required to map as expected the elements of a set, given by index,
-- to another set, where the images are indexes again.  Technically, those are maps of the 
-- category of finite sets quotiented by equality of cardinal.
--
-- The objects that map.e handle are completely unrelated to these.
--
-- Example 1:
-- <eucode>
-- sequence s0 = {2, 3, 4, 1, 4, 2, 6, 4}
-- ? map(s0)   -- prints out 1.
-- </eucode>
--
-- See also: 
--   [[:define_map]], [[:fiber_over]], [[:restrict]], [[:direct_map]], [[:reverse_map],
--   [[:is_injective]], [[:is_surjective]], [[:is_bijective]]

public type map(sequence s)
    object p,q

	if length(s) <= 2 then
		return 0
	end if
	
	-- The 2nd last element contains the number of items in the map.
    q = s[$-1]
    if not integer(q) then
    	return 0    -- Sanity check failed.
    end if
	if q != length(s)-2 then
		return 0    -- Sanity check failed.
	end if
	
    -- The last element contains the upper boundary for element values.
    p = s[$]
    
    if not integer(p) then
    	return 0    -- Sanity check failed.
    end if
    
    if p < 0 then
    	return 0    -- Sanity check failed.
    end if
    
    -- Check that each element is within the boundaries.
    for i = 1 to q do
        if not bounded_integer(s[i], 1, p) then
            return 0
        end if
    end for

    return 1
end type

--**
-- Returns 1 if the data represents a map from the product of two sets to a third one.
--
-- Comments:
--
--   An operation from FxG to H is defined as a sequence of mappings from G to H, plus the
--   cardinals of the sets F, G and H. If the input data is consistent with this description,
--   1 is returned, else 0.
--
-- Example 1:
-- <eucode>
-- sequence s = {{{2, 3}, {3, 1}, {1, 2}, {2, 3}, {3, 1}}, {5,2,3}}
-- -- s represents the addition modulo 3 from {0, 1, 2, 3, 4} x {1, 2} to {0, 1, 2}
-- ? operation(s)   -- prints out 1.
-- </eucode>

public type operation(object s)
    sequence u

    if atom(s) or length(s)!=2 or length(s[2])!=3 or length(s[1])!=s[2][1] then
        return 0
    end if

    u=s[2][2..3]
    for i=1 to length(s[1]) do
        if not map(s[1][i]&u) then
            return 0
        end if
    end for
    return 1
end type

--****
-- === Inclusion and belonging.
--

function bfind(object x,sequence s,integer startpoint,integer endpoint)
    integer r,c

    if endpoint>length(s) then
        endpoint=length(s)
    end if
    if startpoint<1 then
        startpoint=1	
    end if
	
    c=eu:compare(x,s[startpoint])
    if c=1 then
        c=eu:compare(x,s[endpoint])
        if c=-1 then
            while endpoint - startpoint>1 do
                r=floor((endpoint+startpoint)/2)
                c=eu:compare(x,s[r])
                if c=-1 then
                    endpoint=r
                elsif c=0 then
                    return r
                else
                    startpoint=r
                end if
            end while
            return -endpoint
        elsif c=0 then
            return endpoint
        else
            return -1-endpoint
        end if
    elsif c=0 then
        return startpoint
    else
        return -startpoint
    end if
end function

include std/sort.e
include std/sequence.e

--**
-- Makes a set out of a sequence by sorting it and removing duplicate elements.
--
-- Parameters: 
-- 		# ##s##: the sequence to transform.
--
-- Returns:
--
-- 		A **set** which is the ordered list of distinct elements in ##s##.
--
-- Example 1:
-- <eucode>
--   sequence s0 s0={1,3,7,5,7,4,1}
--   set s1 s1=sequence_to_set(s0)   -- s1 is now {1,3,4,5,7}
-- </eucode>
--
-- See also: 
-- [[:set]]

public function sequence_to_set(sequence s)
    return remove_dups(s, RD_SORT)
end function

--**
-- Return the cardinal of a set
--
-- Parameters:
--		# ##S##: the set being queried.
--
-- Returns:
--
--		An **integer**, the count of elements in S.
--
-- See Also:
-- [[:set]]

public function cardinal(set S)
    return length(S)
end function

--**
-- Decide whether an object is on a set.
--
-- Parameters:
--		# ##x##: the object inquired about
--		# ##S##: the set being queried
--
-- Returns:
--
--		An **integer**, 1 if ##x## is in ##S##, else 0.
--
-- Example 1:
-- <eucode>
--   set s0 s0={1,3,5,7}
--   ?belongs_to(2,s)   -- prints out 0
-- </eucode>
--
-- See Also: 
-- [[:is_inside]] , [[:intersection]], [[:difference]]

public function belongs_to(object x,set s)
	if length( s ) then
		return bfind(x,s,1,length(s))>0
	else
		return 0
	end if
end function

function add_to_(object x,sequence s)
    integer p

    if not length(s) then
        return {x}
    end if
    p=bfind(x,s,1,length(s))
    if p<0 then
        return insert(s,x,-p)
    end if
    return s
end function

--**
-- Add an object to a set.
--
-- Parameters:
--	# ##x##: the object to add
--		# ##S##: the set to augment
--
-- Returns:
--
-- A **set** which is a **copy** of ##S##, with the addition of ##x## if it was not there already.
--
-- Example 1:
-- <eucode>
--   set s0 s0={1,3,5,7}
--   s0=add_to(2,s)   -- s0 is now {1,2,3,5,7}
-- </eucode>
--
-- See Also: 
-- [[:remove_from]], [[:belongs_to]], [[:union]]

public function add_to(object x,set S)
    return add_to_(x,S)
end function

function remove_from_(object x,sequence s)
    integer p

    p=bfind(x,s,1,length(s))
    if p>0 then
        return remove(s,p)
    else
        return s
    end if
end function

--**
-- Remove an object from a set.
--
-- Parameters:
--		# ##x##: the object to add
--		# ##S##: the set to remove from
--
-- Returns:
--
--A **set** which is a **copy** of ##S##, with ##x## removed if it was there.
--
-- Example 1:
-- <eucode>
--   set s0 s0={1,3,5,7}
--   s0=add_to(2,s)   -- s0 is now {1,2,3,5,7}
-- </eucode>
--
-- See Also: 
-- [[:remove_from]], [[:belongs_to]], [[:union]]

public function remove_from(object x,set s)
    return remove_from_(x,s)
end function

function iota(integer count)
-- Returns: {1,2,...,count}, or "" if count is not greater than 0.
    sequence result
    if count<=0 then
        return ""
    end if
    result=repeat(1,count)
    for i=2 to count do
        result[i]=i
    end for
    return result
end function

function is_inside_(sequence s1,sequence s2,integer mode)
    integer p,q,ls1
    sequence result

    q=length(s2)
    ls1=length(s1)
    if q>ls1 then
        if ls1>1 then
            result=repeat(0,ls1)
            p=1
            for i=1 to ls1/2 do
                p=bfind(s1[i],s2,p,q)
                if p<0 then
                    return 0
                end if
                result[i]=p
                p+=1
                q=bfind(s1[$+1-i],s2,p,q)
                if q<0 then
                    return 0
                end if
                result[$+1-i]=q
                q-=1
            end for
            if and_bits(ls1,1) then
                p=bfind(s1[(ls1+1)/2],s2,p,q)
                if p<=0 then
                    return 0
                end if
                result[(ls1+1)/2]=p
            end if
            if mode then
                return result
            else
                return 1
            end if
        elsif ls1=1 then
            p=find(s1[1],s2)
            if p=0 then
                return 0
            elsif mode then
                return {p}
            else
                return 1
            end if
        else
            if mode then
                return {}
            else
                return 1
            end if
        end if
    elsif q<ls1 then
        return 0
    else
        if mode then
            return iota(ls1)
        else
            return not eu:compare(s1,s2)
        end if
    end if
end function

--**
-- Checks whether a set is a subset of another.
--
-- Parameters: 
-- 		# ##small##: the set to test
--		# ##large##:  the supposedly larger set.
--
-- Returns: 
--
--		An **integer**, 1 if ##small## is a subset of ##large##, else 0.
--
-- Example 1:
-- <eucode>
--   set s0 s0={1,3,5,7}
--   ?is_inside({3,5},s0)   -- prints out 1
-- </eucode>
--
-- See Also: 
-- [[:subsets]], [[:belongs_to]], [[:difference]], [[:embedding]], [[:embed_union]]
public function is_inside(set small,set large)
    return is_inside_(small,large,0)
end function

--** 
--   Returns the set of indexes of the elements of a set in a larger set, or 0 if not applicable
--
-- Parameters: 
--		# ##small##: the set to embed
--		# ##large##: the supposedly larger set
--
-- Returns:
--
--		 A **set** of indexes if ##small## [[:is_inside]]() ##large##, else 0. Each element 
-- is the index in ##large## of the corresponding element of ##small##. Its length is ##
-- length(small)## and the values range from 1 to ##length(large)##.
--
-- Example 1:
-- <eucode>
--   set s0 s0={1,3,5,7}
--   set s s=embedding({3,5},s0)   -- s is now {2,3}
-- </eucode>
--
-- See Also: 
-- [[:subsets]], [[:belongs_to]], [[:difference]], [[:is_inside]]
public function embedding(set small,set large)
    return is_inside_(small,large,1)
end function

function abs(integer p)
-- Description: Returns the absolute value of p.
    if p>0 then
        return p
    else
        return -p
    end if
end function

function embed_union_(sequence s1,sequence s2)
-- Description: Wrapped by embed_union so as to avoid some type checks.
    integer p,q,q_1,ls1
    sequence result,temp

    q=length(s2)
    if q>1 then
        ls1=length(s1)
        if ls1>1 then
            if eu:compare(s1[$],s2[1])=-1 then
                return iota(length(s1))
            elsif eu:compare(s2[$],s1[1])=-1 then
                return iota(length(s1))+q
            end if
            temp=s1
            p=1
            for i=1 to length(s1)/2 do
                p=bfind(s1[i],s2,p,q)
                temp[i]=p
                if p>0 then
                    p+=1
                else
                    p=-p-1
                end if
                q=bfind(s1[$+1-i],s2,p,q)
                temp[$+1-i]=q
                if q>0 then
                    q-=1
                else
                    q=-q
                end if
            end for
            if and_bits(ls1,1) then
                temp[(ls1/2)+1]=bfind(s1[(ls1/2)+1],s2,p,q)
            end if
            result=temp
            if result[1]<0 then
                result[1]*=-1
            end if
            q_1=temp[1]
            for i=2 to length(result) do
                q=temp[i]
                result[i]=abs(q)-abs(q_1)+result[i-1]+(q_1<0)
                q_1=q
            end for
            return result
        elsif length(s1)=1 then
            q=find(s1[1],s2)
            if q>0 then
                return {q}
            else
                return {-q}
            end if
        else
            return ""
        end if
    elsif q=0 then
        return iota(length(s1))
    else
        q=find(s2[1],s1)
        if q>0 then
            return iota(length(s1))
        else
            result=iota(length(s1))
            result[-q..$]+=1
            return result
        end if
    end if
end function

--**
--   Returns the embedding of a set into its union with another.
--
-- Parameters: 
-- 		# ##S1##: the set to embed
--		# ##S2##: the other set
--
-- Returns:
--
--		A **set** of indexes representing S1 inside ##union(S1,S2)##. Its length is ##length(S1)##, and the values range from 1 to ##length(S1) + length(S2)##.
--
-- Example 1:
-- <eucode>
-- set s1 = {2, 5, 7}, s2 = {1, 3, 4}
-- sequence s = embed_union(s1,s2) -- s is now {2, 5, 6}
-- </eucode>
-- See Also:
--		[[:embedding]], [[:union]]

public function embed_union(set s1,set s2)
    return embed_union_(s1,s2)
end function

--**
-- Returns the list of all subsets of the input set.
--
-- Parameters: 
-- 		# ##s##: the set to enumerate the subsets of.
--
-- Returns: 
--		A **sequence** containing all the subsets of the input set.
--
-- Comments:
--
--   ##s## must not have more than 29 elements, as the length of the output sequence is
--    ##power(2,length(s))##, which rapidly grows out of integer range.
--   The order in which the subsets are output is implementation dependent.
--
-- Example 1:
-- <eucode>
--   set s0 s0={1,3,5,7}
--   s0=subsets(s0)   -- s0 is now:
--   {{},{1},{3},{5},{7},{1,3},{1,5},{1,7},{3,5},{3,7},{5,7},{1,3,5},{1,3,7},{1,5,7},{3,5,7},{1,3,5,7}}
-- </eucode>
--
-- See Also: 
--  [[:is_inside]]

public function subsets(set s)
    integer p,k,L
    sequence result,s1,s2,x

    L=length(s)
    if L<=3 then
        if L=0 then
            return {{}}
        elsif L=1 then
            return {{},s}
        elsif L=2 then
            return {{},{s[1]},{s[2]},s}
        else
            return {{},{s[1]},{s[2]},{s[3]},s[1..2],{s[1],s[3]},s[2..3],s}
        end if
    else
        result=repeat(0,power(2,L))
        p=floor(L/2)
        s1=subsets(s[1..p])
        s2=subsets(s[p+1..$])
        k=1
        for i=1 to length(s1) do
            x=s1[i]
            for j=1 to length(s2) do
                result[k]=x&s2[j]
                k+=1
            end for
        end for
        return result
    end if
end function

--****
-- === Basic set-theoretic operations.
--

function intersection_(sequence s1,sequence s2)
-- Description: Wrapped by intersection() so as to avoid some type checks.
    integer k1,k2,k,c,ls1,ls2
    sequence result

    ls2=length(s2)
    result=s1
    if ls2=0 then
        return ""
    elsif ls2=1 then
        if belongs_to(s2[1],s1) then
            return s2
        else
            return ""
        end if
    end if
    ls1=length(s1)
    k1=1
    k2=1
    k=1
    c=eu:compare(s1[1],s2[1])
    while k1<=ls1 and k2<=ls2 do
        if c=0 then
            result[k]=s1[k1]
            k+=1
            k1+=1
            k2+=1
            if k1>ls1 or k2>ls2 then
                return result[1..k-1]
            else
                c=eu:compare(s1[k1],s2[k2])
            end if
        elsif c=1 then
            k2=bfind(s1[k1],s2,k2,length(s2))
            if k2>=0 then
                c=0
            else
                k2=-k2
                c=-1
            end if
        else
            k1=bfind(s2[k2],s1,k1,length(s1))
            if k1>=0 then
                c=0
            else
                k1=-k1
                c=1
            end if
        end if
    end while
    return result[1..k-1]
end function

--**
-- Returns the set of elements belonging to both s1 and s2.
--
-- Parameters: 
--		# ##S1##: One of the sets to intersect
--		# ##S2##: the other set.
--
-- Returns: 
--
--		A **set** made of all elements belonging to both ##S1## and ##S2##.
--
-- Example 1:
-- <eucode>
-- set s0,s1,s2
-- s1={1,3,5,7} s2={-1,2,3,7,11}
-- s0=intersection(s1,s2)   -- s0 is now {3,7}.
-- </eucode>
--
-- See Also: 
-- [[:is_inside]], [[:subsets]], [[:belongs_to]]

public function intersection(set S1,set S2)
    return intersection_(S1,S2)
end function

function union_(sequence s1,sequence s2,integer ls1,integer ls2,integer mode)
-- Description: Wrapped by union() and delta() to avoid type checking.
-- mode=1 for union and 0 for delta (union=intersection+delta)
    integer k1,k2,k,c,k0
    sequence result

    result=s1&s2
    k1=1
    k2=1
    k=1
    c=eu:compare(s1[1],s2[1])
    while k1<=ls1 and k2<=ls2 do
        if c=0 then
            if mode then
                result[k]=s1[k1]
                k+=1
            end if
            k1+=1
            k2+=1
            if k1>ls1 or k2>ls2 then
                exit
            else
                c=eu:compare(s1[k1],s2[k2])
            end if
        elsif c=1 then
            k0=bfind(s1[k1],s2,k2,length(s2))
            if k0>=0 then
                c=0
            else
                k0=-k0
                c=-1
            end if
            result[k..k-k2+k0-1]=s2[k2..k0-1]
            k+=(k0-k2)
            k2=k0
        else
            k0=bfind(s2[k2],s1,k1,length(s1))
            if k0>=0 then
                c=0
            else
                k0=-k0
                c=1
            end if
            result[k..k-k1+k0-1]=s1[k1..k0-1]
            k+=(k0-k1)
            k1=k0
        end if
    end while
    result=result[1..k-1]
    if k1<=ls1 then
        return result & s1[k1..$]
    elsif k2<=ls2 then
        return result & s2[k2..$]
    else
        return result
    end if
end function

function union1(sequence s1,sequence s2)
    integer ls1,ls2

    ls1=length(s1)
    ls2=length(s2)
    if ls2=0 then
        return s1
    elsif ls1=0 then
        return s2
    elsif ls1=1 then
        return add_to_(s1[1],s2)
    elsif ls2=1 then
        return add_to_(s2[1],s1)
    end if
    return union_(s1,s2,ls1,ls2,1)
end function

--**
-- Returns the set of elements belonging to any of two sets.
--
-- Parameters: 
--		# ##S1##: one of the sets to merge
--		# ##S2##: the other set.
--
-- Returns:
--
--		The **set** of all elements belonging to ##S1## or ##S2##, and possibly to both.
--
-- Example 1:
-- <eucode>
--   set s0,s1,s2
--   s1={1,3,5,7} s2={-1,2,3,7,11}
--   s0=union(s1,s2)   -- s0 is now {-1,1,2,3,5,7,11}.
-- </eucode>
--
-- See Also: 
-- [[:is_inside]], [[:subsets]], [[:belongs_to]]
public function union(set S1,set S2)
    return union1(S1,S2)
end function

--**
-- Returns the set of elements belonging to either of two sets.
--
-- Parameters: 
--		# ##s1##: One of the sets to take a symmetrical difference with
--		# ##s2##: the other set.
--
-- Returns: 
--
--		The **set** of all elements belonging to either ##s1## or ##s2##.
--
-- Example 1:
-- <eucode>
--   set s0,s1,s2
--   s1={1,3,5,7} s2={-1,2,3,7,11}
--   s0=delta(s1,s2)   -- s0 is now {-1,1,2,5,11}.
-- </eucode>
--
-- See Also: 
--		[[:intersection]], [[:union]], [[:difference]]
public function delta(set s1,set s2)
    integer ls1,ls2

    ls1=length(s1)
    ls2=length(s2)
    if ls2=0 then
        return s1
    elsif ls1=0 then
        return s2
    elsif ls1=1 then
        return remove_from_(s1[1],s2)
    elsif ls2=1 then
        return remove_from_(s2[1],s1)
    end if
    return union_(s1,s2,ls1,ls2,0)
end function

--**
-- Returns the set of elements belonging to some set and not to another.
--
-- Parameters: 
-- 		# ##base##: the set from which a difference is to be taken
--		# ##removed##: the set of elements to remove from ##base##.
--
-- Returns:
--
--		The **set** of elements belonging to ##base## but not to ##removed##.
--
-- Example 1:
-- <eucode>
--   set s0,s1,s2
--   s1={1,3,5,7} s2={-1,2,3,7,11}
--   s0=difference(s1,s2)   -- s0 is now {1,5}.
-- </eucode>
--
-- See Also:
-- [::remove_from,]] [[:is_inside]], [[:delta]]
public function difference(set base,set removed)
    integer k1,k2,k,c,ls1,ls2,k0
    sequence result
    ls1=length(base)
    ls2=length(removed)
    if ls2=0 then
        return base
    elsif ls1=0 then
        return ""
    elsif ls2=1 then
        return remove_from_(removed[1],base)
    elsif ls1=1 then
        if bfind(base[1],removed,1,length(removed))>0 then
            return ""
        else
            return base
        end if
    end if
    result=base&removed
    k1=1
    k2=1
    k=1
    c=eu:compare(base[1],removed[1])
    while k1<=ls1 and k2<=ls2 do
        if c=0 then
            k1+=1
            k2+=1
            if k1>ls1 or k2>ls2 then
                exit
            else
                c=eu:compare(base[k1],removed[k2])
            end if
        elsif c=1 then
            k2=bfind(base[k1],removed,k2,length(removed))
            if k2>=0 then
                c=0
            else
                k2=-k2
                c=-1
            end if
        else
            k0=bfind(removed[k2],base,k1,length(base))
            if k0>=0 then
                c=0
            else
                k0=-k0
                c=1
            end if
            result[k..k-k1+k0-1]=base[k1..k0-1]
            k+=(k0-k1)
            k1=k0
        end if
    end while
    result=result[1..k-1]
    if k1<=ls1 then
        return result & base[k1..$]
    else
        return result
    end if
end function

function product_(sequence s1,sequence s2)
-- Description: Wrapped by product() to skip type checking
    sequence result
    integer ls1,ls2,k
    object x

    ls1=length(s1)
    ls2=length(s2)
    if not (ls1 and ls2) then
        return ""
    end if
    k=1
    result=repeat(0,ls1*ls2)
    for i=1 to ls1 do
        x={s1[i],0}
        for j=1 to ls2 do
            x[2]=s2[j]
            result[k]=x
            k+=1
        end for
    end for
    return result
end function

--**
-- Returns the set of all pairs made of an element of a set and an element of another set.
--
-- Parameters: 
--		# ##S1##: The set where the first coordinate lives
--		# ##S2##: The set where the second coordinate lives
--
-- Returns:
--
--		The **set** of all pairs made of an element of ##S1## and an element of ##S2##.
--
-- Example 1:
-- <eucode>
-- set s0,s1,s2
-- s1 = {1, 3, 5, 7} s2 = {-1, 3}
-- s0 = product(s1, s2)   -- s0 is now {{1, -1}, {1, 3}, {3, -1}, {3, 3}, {5, -1}, {5, 3}, {7, -1}, {7, 3}}
-- </eucode>
--
-- See Also:
-- [[:product_map]], [[:amalgamated_sum]], [[:fiber_product]]

public function product(set S1, set S2)
    return product_(S1, S2)
end function

--****
-- === Maps between sets.

--**
--   Returns a map which sends each element of its source set to the corresponding 
--    one in a list.
--
-- Parameters: 
--		# ##mapping##: the sequence mapped to
--		# ##target##: the target set that contains the elements ##mapping## refers to by index
--
-- Returns:
--
--   	The requested **map** descriptor.
--
-- Example 1:
-- <eucode>
-- sequence s0 = {2, 3, 4, 1, 4, 2}
-- set s1 = {-1, 1, 2, 3, 4}
-- map f = define_map(s0,s1)
-- --  As a sequence, f is {3, 4, 5, 2, 5, 3, 6, 5}
-- </eucode>
--
-- See Also:
--   [[:map]], [[:sequences_to_map]], [[:direct_map]]

public function define_map(sequence mapping, set target)
    sequence result
    integer lt

    lt = length(target)
    result = mapping & length(mapping) & lt
    for i = 1 to length(mapping) do
        result[i] = bfind(mapping[i], target, 1, lt)
    end for

    return result
end function

--**
--   Returns a map which sends each element of some sequence to the corresponding one in another sequence.
--
-- Parameters:
--		# ##mapped##: the source sequence
--		# ##mapped_to##:  the sequence it must map to.
--		# ##mode##: an integer, nonzero to also return the minimal sets the result map maps.
--
-- Returns:
--		A **sequence**:
-- * If ##mode## is 0, a map which maps ##mapped## to ##mapped_to##, between the smallest possible sets.
-- * If mode is not zero, the sequence has length 3. The first element is the map above. The other two elements are the sets derived from the input sequences.
--
-- Comments:
--
--   Elements in excess in ##mapped_to## are discarded.
--
--   If an element is repeated in ##mapped##, only the mapping of the last occurrence is retained.
--
-- Example 1:
-- <eucode>
-- sequence s0, s1
-- s0 = {2, 3, 4, 1, 4} 
-- s1 = {"aba", "aac", 3, "def"}
--
-- map f f=sequences_to_map(s0,s1)
-- --  As a sequence, f is {3,2,1,4,4,4}
-- </eucode>
--
-- See Also:
-- [[:map]], [[:define_map]]

public function sequences_to_map(sequence mapped,sequence mapped_to,integer mode)
    sequence result
    set sorted,sorted_to
    integer ls,lm_to,lm

    lm=length(mapped)
    lm_to=length(mapped_to)

    if lm>lm_to then
        mapped=mapped[1..lm_to]
    end if

    sorted=sequence_to_set(mapped)
    sorted_to=sequence_to_set(mapped_to)
    ls=length(sorted)
    result=repeat(0,ls)&ls&length(sorted_to)

    for i=1 to lm do
        result[find(mapped[i],sorted)]=find(mapped_to[i],sorted_to)
    end for

    if mode then
        return {result,sorted,sorted_to}
    else
        return result
    end if
end function

--**
-- If an object is in some input set, returns how it is mapped to a set.
--
-- Parameters: 
--		# ##f##: the map to apply
--		# ##x##: the object to apply ##f## to
--		# ##input##: the source set
--		# ##output##: the target set.
--
-- Returns: 
--		An **object**, f(x) if it can be reckoned.
--
-- Errors:
--
-- ##x## must belong to ##input## for ##f(x) ##to be computed.
-- ##f## must not map to sets larger than ##output##; otherwise, it cannot be defined from ##input## to ##output##.
--
-- Example 1:
-- <eucode>
-- map f={3,1,2,2,4,3}
-- set s1,s2
-- s1={"Albert","Beatrix","Conrad","Doris"} s2={13,17,19}
-- object x x=image(f,"Conrad",s1,s2}
-- -- x is now 17.
-- </eucode>
--
-- See Also:
--   [[:direct_map]]

public function image(map f,object x,set input,set output)
    integer p

    if f[$]>length(output) then
        report_error({"image","The map range would not fit into the supplied target set."})
    end if

    p=bfind(x,input,1,length(input))

    if p<0 or p>f[$-1] then
        report_error({"image","The map is not defined for the supplied argument."})
    else
        return output[f[p]]
    end if
end function

--**
-- Returns the set of all values taken by a map in some output set.
--
-- Parameters:
--		# ##f##: the map to inspect
--		# ##the output set
--
-- Returns:
--
--		The **set** of all ##f(x)##.
--
-- Example 1:
-- <eucode>
-- map f = {3, 2, 5, 2, 4, 6}
-- set s = {"Albert", "Beatrix", "Conrad", "Doris", "Eugene", "Fabiola"}
-- set s1 = range(f, s)
-- -- s1 is now {"Beatrix",  "Conrad", "Eugene"}
-- </eucode>
--
-- See Also:
-- [[:direct_map]], [[:image]]

public function range(map f,set s)
    sequence result

    result=sequence_to_set(f[1..$-2])
    for i=1 to length(result) do
        result[i]=s[result[i]]
    end for

    return result
end function

--**
--   Returns the image of a list by a map, given the input and output sets.
--
-- Parameters: 
--		# ##f##: the map to apply
--		# ##input##: the source set
--		# ##elements##:  the sequence to map
--		# ##output##:  the target set.
--
-- Returns: 
--   A **sequence** of elements of ##output## obtained by applying ##f## to the corresponding
--    element of ##input##.
--
-- Errors:
-- This function errors out if ##f## cannot map ##input## to ##output##.
--
-- Comments:
--
--If ##elements## has items which are not on ##input##, they are ignored. Items may appear in any order any number of times.
--
-- Example:
-- <eucode>
--   sequence s0 s0={2,3,4,1,4}
--   set t1,t2
--   t1={1,2,2.5,3,4} t2={11,13,17,19,23,29}
--   map f f={3,1,4,5,3,5,5}
--   sequence s2 s2=direct_map(f,t1,s0,t2)
--   -- s2 is now {11,29,17,17,17}.
-- </eucode>
--
-- See Also: 
-- [[:reverse_map]]

public function direct_map(map f,set s1,sequence s0,set s2)
    sequence result
    integer k,p,ls1

    ls1=length(s1)
    if f[$-1]>ls1 or f[$]>length(s2) then
        report_error({"direct_map","The supplied map cannot map the source set into the target set."})
    end if

    k=1
    result=s0

    for i=1 to length(s0) do
        p=bfind(s0[i],s1,1,ls1)
        if p>0 then
            result[k]=s2[f[p]]
            k+=1
        end if
    end for

    return result[1..k-1]
end function

--**
-- Restricts f to the intersection of an input set and another set
--
-- Parameters: 
--		# ##f##: the map to restrict
--		# ##source##: the initial source set for ##f##
--		# ##restriction##: the set which will help forming a restricted source set.
--
-- Returns:
--
--		A **map** defined on ##difference(source,restriction)## which agrees with ##f##.
--
-- Example 1:
-- <eucode>
--   set s1 s1={1,3,5,7,9,11,13,17,19,23}}
--   map f f=[3,7,1,4,5,2,7,1,6,2,10,7}
--   set s0 s0={3,11,13,19,29}
--   map f0 f0=restrict(f,s1,s0)
--   f0 is now: {7,2,7,6,4,7}
-- </eucode>
--
-- See Also:
-- [[:is_inside]], [[:direct_map]], [[:difference]]
 public function restrict(map f,set source,set restriction)
    sequence result = restriction
    integer p = 1, k = 0

    for i=1 to length(restriction) do
        p=bfind(restriction[i],source,p,length(source))
        if p>0 then
            k+=1
            result[k]=f[p]
        end if
    end for

    return result[1..k]&k&f[$]
end function

function change_target_(sequence f,sequence s1,sequence s2)
-- Description: Wrapped by change_target() to avoid some type checks.
    sequence result,done
    integer p,fi

    result=f
    done=repeat(0,f[$])

    for i=1 to f[$-1] do
        fi=f[i]
        p=done[fi]
        if p then
            result[i]=p
        else
            p=bfind(s1[fi],s2,1,length(s2))
            if p<0 then
                report_error({"change_target","map range not included in new target set."})
            else
                result[i]=p
                done[fi]=p
            end if
        end if
    end for
    result[$]=length(s2)

    return result
end function

--**
-- Converts a map by changing its output set.
--
-- Parameters: 
--		# ##f##: the map to retarget
--		# ##old_target## the initial target set for ##f##
--		# ##new_target##: the new target set.
--
-- Returns:
--
--   A **map** which agrees with ##f## and has values in ##new_target## instead of ##
-- old_target##, or "" if ##f## hits something outside ##new_target##.
--
-- Example 1:
-- <eucode>
--   set s1,s2
--   s1={1,3,5,7,9,11} s2={1,3,7,11,17,19,23}
--   map f f={2,1,4,6,2,6,6,6}
--   map f0 f0=change_target(f,s1,s2)
--   f0 is now: {2,1,3,4,2,4,6,7}
-- </eucode>
--
-- See Also: 
-- [[:restrict]], [[:direct_map]]

public function change_target(map f,set old_target,set new_target)
    return change_target_(f,old_target,new_target)
end function

--**
--   Combines two maps into one defined from the union of source sets to the union 
--    of target sets.
--
-- Parameters:
--		# ##f1##: the first map
--		# ##source1##: its source set
--		# ##target1##: its target set
--		# ##f2##: the second map
--		# ##source2##: its source set
--		# ##target2##: its target set
--
-- Returns:
--   A **map** from ##union(source1,source2)## to ##union(target1,target2) which agrees with ##f1## and ##f2##, or "" if ##f1##
--    and ##f2## disagree at any point of ##intersection(s11,s21)##.
--
-- Errors:
--
--   If f1 and f2 are both defined for some point, they must have the same value at this point..
--
-- Example 1:
--
-- <eucode>
--   set s11,s12,s21,s22
--   s11={2,3,5,7,11,13,17,19} s21={7,13,19,23,29}
--   s12={-1,0,1,4} s22={-2,0,1,2,6}
--   map f1,f2
--   f1={2,1,3,3,2,3,1,2,8,4} f2={3,3,2,4,5,5,5}
--   map f f=combine_maps(f1,s11,s12,f2,s21,s22)
--   -- f is now: {3,2,4,4,3,4,2,3,5,7,10,7}.
-- </eucode>
--
-- See Also:
-- [[:restrict]], [[:direct_map]]

public function combine_maps(map f1,set source1,set target1,map f2,set source2,set target2)
    integer len_result,p
    set s
    sequence result

    s=union1(target1,target2)
    f1=change_target_(f1,target1,s)
    f2=change_target_(f2,target2,s)
    s=embed_union_(source1,source2)
    len_result=length(source1)+length(source2)
    result=repeat(0,len_result)
    for i=1 to length(s) do
        result[s[i]]=f1[i]
    end for
    s=embed_union_(source2,source1)
    for i=1 to length(s) do
        p=s[i]
        if result[p] then
            if result[p]!=f2[i] then
                report_error({"combine_maps",
                  "Maps disagree at some point where they are both defined."})
            else
                len_result-=1
            end if
        else
            result[p]=f2[i]
        end if
    end for
    return result[1..len_result]&len_result&f1[$]
end function

function compose_map_(sequence f2,sequence f1)
-- Description: Wrapped by compose_map(), so as to avoid some type checks.
    sequence result
    if find(0,f1[1..$-2]<=f2[$]) then
        report_error({"compose_maps","Range of initial map exceeds definition set of final map."})
    end if
    result=f1
    for i=1 to f1[$-1] do
        result[i]=f2[f1[i]]
    end for
    result[$]=f2[$]
    return result
end function

--**
-- Computes the compound map f2 o f1.
--
-- Parameters: 
-- 		# ##f2##: the map to apply second, or left
--		# ##f1##: the map to apply first, or right.
--
-- Returns: 
--		A **map** ##f## defined by ##f(x)=f2(f1(x))## for all ##x##
--.
-- Errors:
--
-- ##f2## must be defined on the whole range of ##f1##.
--
-- Example 1:
-- <eucode>
--   map f1,f2,f
--   f1={2,3,1,1,2,5,3}
--   f2={4,8,1,2,6,7,6,9}
--   f=compose_ùa^(f2,f1)
--   -- f is now: {8,1,4,4,8,5,9}
-- </eucode>
--
-- See Also:
-- [[:diagram_commutes]]
public function compose_map(map f2,map f1)
    return compose_map_(f1,f2)
end function

--**
-- Decide whether taking two different paths along a square map diagrams results in the same map.
--
-- Parameters: 
--		# ##from_base_path_1##: the outgoing map along path 1
--		# ##from_base_path_2##: the outgoing map along path 2
--		# ##to_target_path_1##: the incoming map along path 1
--		# ##to_target_path_2##: the incoming map along path 2
--
-- Returns: 
--
--		An **integer**, either 1 if to_target_path_1 o from_base_path_1 = to_target_path_2 o from_base_path_2.
--
-- Example 1:
-- <eucode>
--   map f12a,f12b,f2a3,f2b3
--   f12a={2,3,1,1,2,5,3}
--   f2a3={4,8,1,2,6,7,6,9}
--   f12b={2,4,2,3,1,5,4}
--   f2b3={8,8,4,1,3,5,8}
--   ?diagram_commutes(f12a,f12b,f2a3,f2b3)   -- prints out 0
-- </eucode>
--
-- See Also:
-- [[:compose_map]]
public function diagram_commutes(sequence f12a,sequence f12b,sequence f2a3,sequence f2b3)
    return not eu:compare(compose_map_(f2a3,f12a),compose_map_(f2b3,f12b))
end function

--**
-- Determines whether there is a point in an output set hit twice or more by a map.
--
-- Parameters: 
--		# ##f##: the map being queried.
--
-- Returns:
--
--		An **integer**, 0 if f ever maps two points to the same element, else 1.
--
-- Example 1:
-- <eucode>
--   map f f={2,3,1,1,2,5,3}
--   ?is_injective(f)  -- prints out 0
-- </eucode>
--
-- See Also: 
-- [[:is_surjective]], [[:is_bijective]], [[:reverse_map]], [[:fiber_over]]
public function is_injective(map f)
    sequence s
    integer p
    object x,y

    if f[$-1]>f[$] then
        return 0
    end if

    p=length(f)-2
    s=sort(f[1..p])
    x=s[1]

    for i=2 to p do
        y=s[i]
        if y=x then
            return 0
        end if
        x=y
    end for

    return 1
end function

function is_surjective_(sequence f)
    if f[$-1]<f[$] then
        return 0
    else
        return equal(sequence_to_set(f[1..$-2]),iota(f[$]))
    end if
end function

--**
-- Determine whether all points in the output set are hit by a map.
--
-- Parameters: 
--		# ##f##: the map to test.
--
-- Returns:
--
--		An **integer**, 0 if ##f## ever misses some point in the target set, else 1.
--
-- Example 1:
-- <eucode>
--   map f f={2,3,1,1,2,5,3}
--   ?is_surjective(f)  -- prints out 1
-- </eucode>
--
-- See Also: 
-- [[:is_surjective]], [[:is_bijective]], [[:direct_map]], [[:section]]
public function is_surjective(map f)
    return is_surjective_(f)
end function

--**
-- Determine whether a map is one-to-one.
--
-- Parameters:
--		# ##f##: the map to test.
--
-- Returns:
--
--		An **integer**, 1 if f is one-to-one, else 0.
--
-- Example 1:
-- <eucode>
--   map f f={2,3,1,1,2,5,3}
--   ?is_surjective(f)  -- prints out 0
-- </eucode>
--
-- See Also: 
-- [[:is_surjective]], [[:is_bijective]], [[:direct_map]], [[:has_inverse]]
public function is_bijective(map f)
    if f[$]!=f[$-1] then
        return 0
    else
        return is_surjective_(f)
    end if
end function

function fiber_over_(sequence f,sequence s1,sequence s2)
    sequence fibers,result
    integer p
    if f[$-1]!=length(s1) or f[$]!=length(s2) then
        return ""
    end if
    fibers=sequence_to_set(f[1..$-2])
    result=repeat({},length(fibers))
    for i=1 to length(s1) do
        p=find(f[i],fibers)
        result[p]=append(result[p],s1[i])
    end for
    return {result,fibers}
end function

--****
-- === Reverse mappings
--

--**
-- Given a map between two sets, returns {list of antecedents of elements in target, effective target}.
--
-- Parameters: 
--		# ##f##: the inspected map
--		# ##source##: the source set
--		# ##target##: the target set.
--
-- Returns:
--
--   A **sequence** which is empty on failure. On success, it has two elements:
-- * A sequence of sets; each of these sets is included in ##source## and is mapped to a single point by ##f##.
-- * A set, the points in ##target## hit by ##f##.
--
-- Comments:
--
-- The listed sets, which are reverse images of points in ##target##,
--   are called //fibers// of ##f## over points, specially if they are isomorphic to one 
-- another for some extra algebraic or topological structure.
--
-- The fibers are enumerated in the same order as the points in the effective target, i.e. 
-- the points in ##target## ##f## hits.
--
-- Example 1:
-- <eucode>
--   set s1,s2
--   s1={5,7,9,11} s2={13,17,19,23,29}
--   map f f={2,1,4,1,4,5}
--   sequence s s=fiber_over(f,s1,s2)
--   -- s is now {{{7,11},{5},{9}},{13,17,23}}.
-- </eucode>
--
-- See Also: 
-- [[:reverse_map]], [[:fiber_product]]
public function fiber_over(map f,set source,set target)
    return fiber_over_(f,source,target)
end function

--**
--   Given a map between two sets, returns the smallest subset whose image contains the set of elements in a list.
--
-- Parameters: 
--		# ##f##: the map relative to which reverse images are to be taken
--		# ##source##: the source set
--		# ##elements##: the list of elements in ##target## to lift to ##source##
--		# ##target##: the target set
--
-- Returns: 
--		A **set** which is included in ##source## and contains all antecedents of elements in ##elements## by ##f##.
--
--Comments:
--
-- Elements which ##f## does not hit are ignored.
--
-- Example 1:
-- <eucode>
--   set s1,s2
--   s1={5,7,9,11} s2={13,17,19,23,29}
--   sequence s0 s0={23,13,17,23}
--   map f f={5,3,1,3,4,5}
--   set s s=reverse_map(f,s1,s0,s2)
--   s is now {9}.
-- </eucode>
--
-- See Also: 
-- [[:direct_map]], [[:fiber_over]]

public function reverse_map(map f,set s1,sequence s0,set s2)
    sequence x,done,result
    integer p

    x=fiber_over_(f,s1,s2)
    result=""
    done=repeat(0,length(x[2]))

    for i=1 to length(s0) do
        p=find(bfind(s0[i],s1,1,length(s1)),x[2])
        if p and not done[p] then
            done[p]=1
            result=union1(result,x[1][p])
        end if
    end for
    return result
end function

--**
-- Return a right, and left is possible, inverse of a map over its [[:range]].
--
-- Parameters:
--		# ##f##: the map to invert.
--
-- Returns:
--   A **map** ##g## such that ##f(g(y)) = y## whenever ##y## is hit by ##f##. and  If f is 
-- injective, it also holds that ##g(f(x))=x##.
--
-- Example 1:
-- <eucode>
-- map f = {2, 3, 1, 1, 2, 5, 3}, g = section(f)
-- -- g is now {3,1,2,3,5}.
-- </eucode>
--
-- See Also: 
-- [[:reverse_map]], [[:is_injective]]

public function section(map f)
    sequence result = f
    integer k = 0, p = f[$-1]

    for i=1 to p do
        result[f[i]]=i
    end for

    for i=1 to p do
        if result[i] and k then
           result[k]=result[i]
           k+=1
        elsif result[i]=0 and k=0 then
           k=i
        end if
    end for

    if k then
        result[k]=k-1
        result=result[1..k]&p
    else
        result[$]=p
        result[$-1]=f[$]
    end if

    return result
end function


--****
-- === Products
--

--**
-- Builds a map to a product from a map to each of its components.
--
-- Parameters: 
--		# ##f1##: the map going to the first component
--		# ##f2##: the map going to the second component
--
-- Returns: 
--
--   A **map** ##f=f1 x f2## defined by ##f(x,y)={f1(x),f2(y)}## wherever this makes sense.
--
-- Example 1:
-- <eucode>
--   set s s={1,3,5,7}
--   map f f={3,1,4,1,4,4}
--   map f1 f1=product(f,f)
--   -- f1 is {11,9,12,9,3,1,4,1,15,13,16,13,3,1,4,1,16,16}.
-- </eucode>
--
-- See Also: 
-- [[:product]], [[:amalgamated_sum]], [[:fiber_product]]
public function product_map(map f1,map f2)
    sequence result,s
    integer k ,p
    k=1
    p=f2[$-1]
    result=repeat(0,f1[$-1]*p)&f1[$-1]*p&f1[$]*f2[$]
    s=f2[1..$-2]-p
    for i=1 to f1[$-1] do
        result[k..k+p-1]=s+p*f1[i]
        k+=p
    end for
    return result
end function

--**
-- Returns all pairs in a product that come from applying two maps to the same element in a base set.
--
-- Parameters:
--		# ##first##: one of the sets to involved in the sum
--		# ##second##: the other set
--		# ##base##: the base set
--		# ##base_to_1##: the map from ##base## to ##first##
--		# ##base_to_2##: the map from ##base## to ##second##
--
-- Returns:
--
--   A set of pairs obtained by applying f01Xf02 to s0.
--
-- Example 1:
-- <eucode>
--   set s0,s1,s2
--   s0={1,2,3} s1={5,7,9,11} s2={13,17,19}
--   map f01,f02
--   f01={2,4,1,3,4} f02={2,2,1,3,3}
--   set s s=amalgamated_product(s1,s2,s0,f01,f02)
--   -- s is now {{7,17},{11,17},{5,13}}.
-- </eucode>
--
-- See Also:
--
-- [[:product]], [[:product_map]], [[:fiber_product]]

public function amalgamated_sum(set first,set second,set base,map base_to_1,map base_to_2)
    sequence result

    result=base
    for i=1 to length(base) do
        result[i]={first[base_to_1[i]],second[base_to_2[i]]}
    end for
    return sequence_to_set(result)
end function

--**
-- Returns the set of all pairs in a product on which two given componentwise maps agree.
--
-- Parameters:
--		# ##first##: the first product component
--		# ##second##: the second product component
--		# ##base##: the base set the fiber product is built on
--		# ##from_1_to_base##: the map from ##first## to ##base##.
--		# ##from_2_to_base##: the map from ##second## to ##base##.
--
-- Returns: 
--
--		The **set** of pairs whose coordinates are mapped consistently to ##base## by ##
-- from_1_to_base## and ##from_2_to_base## respectively.
--
-- Example 1:
-- <eucode>
--   set s0,s1,s2
--   s0={1,2,3} s1={5,7,9,11} s2={13,17,19,23,29}
--   map f10,f20
--   f10={2,1,2,1,4,3} f20={1,3,3,2,3,5,3}
--   set s s=fiber_product(s1,s2,s0,f10,f20)
--   -- s is now {{5,23},{7,13},{9,23},{11,13}}.
-- </eucode>
--
-- See Also: 
-- [[:reverse_map]], {{:amalgamated_sum]], [[:fiber_over]]
public function fiber_product(set first,set second,set base,map from_1_to_base,map from_2_to_base)
    sequence result,x1,x2,x0

    x1=fiber_over_(from_1_to_base,first,base)
    x2=fiber_over_(from_2_to_base,second,base)
    x0=intersection_(x1[2],x2[2])
    result={}

    for i=1 to length(x0) do
        result&=product_(x1[1][find(x0[i],x1[2])],x2[1][find(x0[i],x2[2])])
    end for

    return result
end function

--****
-- === Constants
--

--**
-- The following constants denote orientation of distributivity or unitarity~:
-- * SIDE_NONE: no units, or no distributivity
-- * SIDE_LEFT: property is requested or verified on the left side
-- * SIDE_RIGHT: property is requested or verified on the right side
-- * SIDE_BOTH:  property is requested or verified on both sides.


public enum SIDE_NONE = 0, SIDE_LEFT, SIDE_RIGHT, SIDE_BOTH

--****
-- === Operations on sets
--

--**
-- Returns an operation that splits by left action into the supplied mappings.
--
-- Parameters: 
--		# ##left_actions##: a sequence of maps, the left actions of each element in the left hand set.
--
-- Returns:
--   An operation ##F## realizing the conditions above, with minimal cardinal values, or "" if
--   the maps are not defined on the same set.
--
-- Errors: 
-- ##left_actions## must be a rectangular matrix.
--
-- Comments:
--
-- If ##F## is the result, and is defined from ##E1 x E2## to ##E##, then each left action is 
-- a map from ##E2## to ##E##, the "left multiplication" by an element of ##E1##.
--
-- Example 1:
-- <eucode>
-- sequence s = {{2, 3, 2, 3}, {3, 1, 2, 5}, {1, 2, 2, 2}, {2, 3, 2, 4}, {3, 1, 2, 3}}
-- operation F = define_operation(s)
-- -- F is now {{{2,3},{3,1},{1,2},{2,3},{3,1}},{5,2,3}
-- ? operation(s)   -- prints out 1.
-- </eucode>
--
-- See Also:
-- [[:operation]]

public function define_operation(sequence left_actions)
    integer size_left,size_right
    map f

    f=left_actions[1]
    size_left=f[$-1]
    size_right=f[$]
    left_actions[1]=f[1..$-2]
    for i=2 to length(left_actions) do
        f=left_actions[i]
        if f[$-1]!=size_left then
            report_error({"define_operation","All specified actions do not map to the same result set."})
        end if
        if f[$]>size_right then
            size_right=f[$]
        end if
        left_actions[i]=f[1..$-2]
    end for
    return {left_actions,{size_left,length(left_actions),size_right}}
end function

--**
-- Determine whether f(x,y) always equals f(y,x).
--
-- Parameters: 
--		# ##f##: the operation to test.
--
-- Returns: 
--
-- 		An **integer**, 1 if exchanging operands makes sense and has no effect, else 0.
--
-- Example 1:
-- <eucode>
-- operation f f={{{1,2,3},{2,3,4},{3,4,5}},{3,3,5}}
-- -- f is the addition from {0,1,2}x{0,1,2} to {0,1,2,3,4}.
-- ? is_symmetric(f)   -- prints out 1.
-- </eucode>
--
-- See Also: 
--   [[:operation]], [[:has_unit]]

public function is_symmetric(operation f)
    sequence s
    integer n
    n=f[2][1]
    if n!=f[2][2] then
        return 0
    end if
    s=f[1]
    for i=1 to n-1 do
        for j=i+1 to n do
            if s[i][j]!=s[j][i] then
                return 0
            end if
        end for
    end for
    return 1
end function

--**
-- Determine whether the identity f(f(x,y),z)=f(x,f(y,z)) always makes sense and holds.
--
-- Parameters: 
--		# ##f##: the operation to test.
--
-- Returns:
-- An **integer**, 1 if ##f## is an internal operation on a set and is associative, else 0.
--
-- Comments:
--
-- Being associative is equivalent to not depending on parentheses for
--   defining iterated execution.
--
-- Example 1:
-- <eucode>
-- operation f f={{{1, 2, 3}, {2, 3, 1}, {3, 1, 2}}, {3, 3, 3}}
-- -- f is the addition modulo 3 from {0, 1, 2} x {0, 1, 2} to {0, 1, 2}.
-- ? is_symmetric(f)   -- prints out 1.
-- </eucode>
--
-- See Also:
--    [[:operation]], [[:has_unit]]

public function is_associative(operation f)
    sequence s
    integer n
    
    s=f[2]
    n=s[1]
    if s[2]!=n or s[3]!=n then
        return 0
    end if 
    s=f[1]
    for i=1 to n do
        for j=1 to n do
            for k=1 to n do
                if s[s[i][j]][k]!=s[i][s[j][k]] then
                    return 0
                end if
            end for
        end for
    end for
    return 1
end function

function has_left_unit(operation f)
    if f[2][2]!=f[2][3] then
        return 0
    else
        return find(iota(f[2][2]),f[1])
    end if
end function

function all_left_units_(sequence f)
    sequence result,s
    if f[2][2]!=f[2][3] then
        return ""
    else
        result=""
        s=iota(f[2][2])
        for i=1 to f[2][1] do
            if equal(f[1][i],s) then
                result&=i
            end if
        end for
        return result
    end if
end function

--**
-- Finds all left units for an operation.
--
-- Parameters: 
--		# ##f##: the operation to test.
--
-- Returns: 
--
--		A possibly empty **sequence**, listing all ##x## such that ##f(x,.)## is the identity map.
--
-- Example 1:
-- <eucode>
--   operation f f={{{1,2,3},{1,2,3},{3,1,2}},{3,3,3}}
--   sequence s s=all_left_units(f)
--   s is now {1,2}.
-- </eucode>
--
-- See Also: 
-- [[:all_right_units]], [[:is_unit]], [[:has_unit]]

public function all_left_units(operation f)
    return all_left_units_(f)
end function

function is_left_unit(integer x,operation f)
    if f[2][2]!=f[2][3] or not bounded_integer(x,1,f[2][1]) then
        return 0
    else
        return equal(f[1][x],iota(f[2][2]))
    end if
end function

function has_right_unit(operation f)
    integer p
    if f[2][3]!=f[2][1] then
        return ""
    else
        for i=1 to f[2][1] do
            p=0
            for j=1 to f[2][2] do
                if f[1][j][i]!=j then
                    p=j
                    exit
                end if
            end for
            if p=0 then
                return i
            end if
        end for
        return 0
    end if
end function

--**
-- Finds all right units for an operation.
--
-- Parameters: 
--		# ##f##: the operation to test.
--
-- Returns: 
--
--		 A possibly empty **sequence** of all ##y## such that ##f(.,y)## is the identity map..
--
-- Example 1:
-- <eucode>
--   operation f f={{{1,2,3},{1,2,3},{3,1,2}},{3,3,3}}
--   sequence s s=all_right_units(f)
--   s is now empty.
-- </eucode>
--
-- See Also: 
-- [[:all_left_units]], [[:is_unit]], [[:has_unit]]

public function all_right_units(operation f)
    integer p
    sequence result

    result=""
    if f[2][3]!=f[2][1] then
        return result
    else
        for i=1 to f[2][2] do
            p=0
            for j=1 to f[2][1] do
                if f[1][j][i]!=j then
                    p=j
                    exit
                end if
            end for
            if p=0 then
                result&=i
            end if
        end for
        return result
    end if
end function

function is_right_unit_(integer x,sequence f)
-- Description: Wrapped by is_right_unit() so as to avoid some type checks.
    if f[2][3]!=f[2][1] or not bounded_integer(x,1,f[2][2]) then
        return 0
    else
        for i=1 to f[2][1] do
            if f[1][i][x]!=i then
                return 0
            end if
        end for
        return 1
    end if
end function

function has_unit_(sequence f)
    sequence s
    s=all_left_units_(f)
    if length(s)!=1 then
        return 0
    elsif is_right_unit_(s[1],f) then
        return s[1]
    else
        return 0
    end if
end function

--**
-- Returns an unit of a given kind for an operation if there is any, else 0.
--
-- Parameters: 
--		# ##f##: the operation to test.
--		# ##flags##: an integer, which says whether one or two sided units are looked for. Defaults to ##SIDE_BOTH##.
--
-- Returns: 
--		An **integer**. If ##f## has a unit of the requested type, it is returned. Otherwise, 0 is returned..
--
-- Comments:
--
-- If there is a two sided inverse, it is unique.
--
-- Only the two lower bits of ##flags## matter. They must be ##SIDE_LEFT## to check for left
-- units, ##SIDE_RIGHT## for right units. Otherwise, two sided units are determined.
--
-- Example 1:
-- <eucode>
--   operation f f={{{1,2,3},{2,3,1},{3,1,2}},{3,3,3}}
--   ?has_unit(f)  -- prints out 1.
-- </eucode>
--
-- See Also: 
-- [[:all_left_units]], [[:all_right_units]],[[:is_unit]]

public function has_unit(operation f, integer flags = SIDE_BOTH)
	flags = and_bits(flags, SIDE_BOTH)
    switch flags do
    	case SIDE_LEFT then
    		return has_left_unit(f)
    		
    	case SIDE_RIGHT then
    		return has_right_unit(f)
    		
    	case else
			return has_unit_(f)
    end switch
end function

--**
-- Determines if an element is a (one sided) unit for an operation.
--
-- Parameters:
--		# ##x##: an integer, the element to test
--		# ##f##: the operation involved
--
-- Returns:
--
--	An **integer**, either ##SIDE_NONE##, ##SIDE_LEFT##, ##SIDE_RIGHT## or ##SIDE_BOTH##.
--
-- Example 1:
-- <eucode>
-- operation f f={{{1, 2, 3}, {1, 2, 3}, {3, 1, 2}}, {3, 3,3 }}
-- ? is_left_unit(3, f)   -- prints out 0.
-- </eucode>
--
-- See Also:
-- [[:all_left_units]], [[:has_unit]]

public function is_unit(integer x, operation f)
	return is_left_unit(x, f) + SIDE_RIGHT * is_right_unit_(x, f)
end function
--**
-- Returns the bilateral inverse of an element by a operation if it exists and the operation has a unit.
--
-- Parameters: 
--		# ##x##: the element to test
--		# ##f##:  the operation involved.
--
-- Returns:
--
--   If ##f## has a bilateral unit ##e## and there is a (necessarily unique) ##y## such that ##f(x,y)=e##,
--   ##y## is returned. Otherwise, 0 is returned..
--
-- Example 1:
-- <eucode>
-- operation f f={{{1, 2, 3}, {2, 3, 1}, {3, 1, 2}}, {3, 3, 3}}
--  ? has_inverse(3, f)  -- prints out 2.
-- </eucode>
--
-- See Also: 
-- [[:has_unit]]

public function has_inverse(integer x,operation f)
    return find(has_unit_(f),f[1][x])
end function

function distributes_left_(sequence product,sequence sum,integer transpose)
-- Description: Wrapped by distributes_left(), so as to avoid some type checks.
    integer p,q,p1
    sequence f1,g1
    p=product[2][2]
    if transpose then
        q=3
    else
        q=1
    end if
    p1=product[2][q]
    if p=product[2][4-q] and not find(0,sum[2]=p) then
        f1=product[1]
        g1=sum[1]
        if transpose then
            for i=1 to p1 do
                for j=1 to p do
                    for k=1 to p do
                        if f1[i][g1[k][j]]!=g1[f1[i][k]][f1[i][j]] then
                            return 0
                        end if
                    end for
                end for
            end for
        else
            for i=1 to p do
                for j=1 to p1 do
                    for k=1 to p1 do
                        if f1[i][g1[j][k]]!=g1[f1[i][j]][f1[i][k]] then
                            return 0
                        end if
                    end for
                end for
            end for
        end if
        return 1
    else
        return 0
    end if
end function

function distributes_right_(sequence product,sequence sum,integer transpose)
    integer p,q,p1
    sequence f1,g1
    p=product[2][2]
    if transpose then
        q=1
    else
        q=3
    end if
    p1=product[2][q]
    if p=product[2][4-q] and not find(0,sum[2]=p) then
        f1=product[1]
        g1=sum[1]
        if transpose then
            for i=1 to p1 do
                for j=1 to p do
                    for k=1 to p do
                        if f1[i][g1[j][k]]!=g1[f1[i][j]][f1[i][k]] then
                            return 0
                        end if
                    end for
                end for
            end for
        else
            for i=1 to p do
                for j=1 to p1 do
                    for k=1 to p1 do
                        if f1[i][g1[k][j]]!=g1[f1[i][k]][f1[i][j]] then
                            return 0
                        end if
                    end for
                end for
            end for
        end if
        return 1
    else
        return 0
    end if
end function

--**
-- Determine whether a product map distributes over a sum
--
-- Parameters:
--		# ##product##: the operation that may be distributive over ##sum##
--		# ##sum##: : the operations over which ##product## might distribute
--		# ##transpose##: an integer, nonzero if ##product## is a right operation. Defaults to 0.
--
-- Returns:
--
--		An **integer**, either of
-- * SIDE_NONE    : ##product## does not distribute either way over ##sum##
-- * SIDE_LEFT    : ##product## distributes over ##sum## on the left only
-- * SIDE_RIGHT   : ##product## distributes over ##sum## on the right only
-- * SIDE_BOTH    : ##product## distributes over ##sum## o(both ways)
--
-- Example 1:
-- <eucode>
--   operation sum 	sum={{{1,2,3},{2,3,1},{3,1,2}},{3,3,3}}		
--   operation product product={{{1,1,1},{1,2,3},{1,3,2}},{3,3,3}}
--   ?distributes_right(product,sum,0)  -- prints out 1.
-- </eucode>
--

public function distributes_over(operation product,operation sum,integer transpose=0)
    return distributes_left_(product,sum,transpose)+2*distributes_right_(product,sum,not transpose)
end function

