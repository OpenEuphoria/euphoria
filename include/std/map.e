-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Map (hash table)
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>
--
-- A map is a special array, often called an associative array or dicionary,
-- in which the index to the data can be any Euphoria object and not just
-- an integer. These sort of indexes are also called keys.
-- For example we can code things like this...
-- <eucode>
--    custrec = new() -- Create a new map
--    custrec = put(custrec, "Name", "Joe Blow")
--    custrec = put(custrec, "Address", "555 High Street")
--    custrec = put(custrec, "Phone", 555675632)
-- </eucode>
-- This creates three elements in the map, and they are indexed by "Name", 
-- "Address" and "Phone", meaning that to get the data associated with those
-- keys we can code ...
-- <eucode>
--    object data = get(custrec, "Phone")
--    -- data now set to 555675632
-- </eucode>
-- **Note~:** Only one instance of a given key can exist in a given map, meaning
-- for example, we couldn't have two separate "Name" values in the above //custrec//
-- map.
--
-- Maps automatically grow to accomodate all the elements placed into it.
--
-- Associative arrays can be implemented in many different ways, depending
-- on what efficiency trade-offs have been made. This implementation allows
-- you to decide if you want a //small// map or a //large// map.\\
-- ;small map: Faster for small numbers of elements. Speed is usually proportional
-- to the number of elements.
-- ;large map: Faster for large number of elements. Speed is usually the same
-- regardless of how many elements are in the map. The speed is often slower than
-- a small map.\\
-- **Note~:** If the number of elements placed into a //small// map take it over
-- the initial size of the map, it is automatically converted to a //large// map.
--

namespace stdmap

include std/get.e
include std/primes.e
include std/convert.e
include std/math.e
include std/stats.e as stats
include std/text.e
include std/search.e
include std/types.e
include std/pretty.e
include std/eumem.e
include std/error.e
include std/sort.e

constant vTag = 1 -- ==> 'tag' for map type
constant vElemCnt = 2 -- ==> elementCount
constant vInUse = 3 -- ==> count of non-empty buckets
constant vType = 4  -- ==> Either SMALLMAP or LARGEMAP
constant vKeyBuckets = 5 -- ==> bucket[] --> bucket = {key[], value[]}
constant vValBuckets = 6 -- ==> bucket[] --> bucket = {key[], value[]}
constant vKeyList = 5 -- ==> Small map keys
constant vValList = 6 -- ==> Small map values
constant vFreeList = 7 -- ==> Small map freespace

constant vMAPTYPE = "Eu:StdMap"
--**
-- Signature:
--   global function hash(object source, atom algo)
--
-- Description:
--     Calculates a hash value from //key// using the algorithm //algo//
--
-- Parameters:
--		# ##source##: Any Euphoria object
--		# ##algo##: A code indicating which algorithm to use.
-- ** -4 uses Fletcher. Very fast and good dispersion
-- ** -3 uses Adler. Very fast and reasonable dispersion, especially for small strings
-- ** -2 uses MD5 (not implemented yet) Slower but very good dispersion. 
-- Suitable for signatures.
-- ** -1 uses SHA256 (not implemented yet) Slow but excellent dispersion. 
-- Suitable for signatures. More secure than MD5.
-- ** 0 and above (integers and decimals) use the cyclic variant (hash = hash * algo + c),
-- except that for values from zero to less than 1, use (algo + 69096). Fast and good to excellent
-- dispersion depending on the value of //algo//. Decimals give better dispersion but are
-- slightly slower.
--
-- Returns:
--     An **integer**:
--        Except for the MD5 and SHA256 algorithms, this is a 30-bit integer.
--     A **sequence**:
--        MD5 returns a 4-element sequence of integers\\
--        SHA256 returns a 8-element sequence of integers.
--
-- Example 1:
-- <eucode>
-- x = hash("The quick brown fox jumps over the lazy dog", 0)
-- -- x is 242399616
-- x = hash("The quick brown fox jumps over the lazy dog", 99.94)
-- -- x is 723158
-- x = hash("The quick brown fox jumps over the lazy dog", -4)
-- -- x is 467406810
-- </eucode>

--****
-- === Constants
--**
-- Operation codes for ##put##():
-- * PUT,
-- * ADD,
-- * SUBTRACT,
-- * MULTIPLY,
-- * DIVIDE,
-- * APPEND,
-- * CONCAT
--
-- Types of Maps
-- * SMALLMAP
-- * LARGEMAP
--
-- Hashing Algorithms
-- * FLETCHER32
-- * ADLER32
-- * SHA256
-- * MD5

public enum
     FLETCHER32 = -4,
     ADLER32,
     MD5,
     SHA256
     
public enum
	PUT,
	ADD,
	SUBTRACT,
	MULTIPLY,
	DIVIDE,
	APPEND,
	CONCAT

public constant SMALLMAP = 's'
public constant LARGEMAP = 'L'

integer vSizeThreshold = 50

-- This is a improbable value used to initialize a small map's keys list. 
constant vInitSmallKey = -75960.358941

--****
-- === Types
--

--**
-- Defines the datatype 'map'
--
-- Comments:
-- Used when declaring a map variable.
--
-- Example:
--   <eucode>
--   map SymbolTable = new() -- Create a new map to hold the symbol table.
--   </eucode>
--with s

public type map(object o)
-- Must be a valid EuMem pointer.
	if not valid(o, "") then return 0 end if
	
-- Large maps have five data elements:
--   (1) Count of elements 
--   (2) Number of slots being used
--   (3) The map type
--   (4) Key Buckets 
--   (5) Value Buckets
-- A bucket contains one or more lists of items.

-- Small maps have six data elements:
--   (1) Count of elements 
--   (2) Number of slots being used
--   (3) The map type
--   (4) Sequence of keys
--   (5) Sequence of values, in the same order as the keys.
--   (6) Sequence. A Free space map.
	object m
	
	m = gMem[o]
	if not sequence(m) then return 0 end if
	if length(m) < 6 then return 0 end if
	if length(m) > 7 then return 0 end if
	if not equal(m[vTag], vMAPTYPE) then return 0 end if
	if not integer(m[vElemCnt]) then return 0 end if
	if m[vElemCnt] < 0 		then return 0 end if
	if not integer(m[vInUse]) then return 0 end if
	if m[vInUse] < 0		then return 0 end if
	if equal(m[vType],SMALLMAP) then
		if atom(m[vKeyList]) 		then return 0 end if
		if atom(m[vValList]) 		then return 0 end if
		if atom(m[vFreeList]) 		then return 0 end if
		if length(m[vKeyList]) = 0  then return 0 end if
		if length(m[vKeyList]) != length(m[vValList]) then return 0 end if
		if length(m[vKeyList]) != length(m[vFreeList]) then return 0 end if
	elsif  equal(m[vType],LARGEMAP) then
		if atom(m[vKeyBuckets]) 		then return 0 end if
		if atom(m[vValBuckets]) 		then return 0 end if
		if length(m[vKeyBuckets]) != length(m[vValBuckets])	then return 0 end if
	else
		return 0
	end if
	return 1
end type

constant maxInt = #3FFFFFFF

--****
-- === Routines
--

--**
-- Calculate a Hashing value from the supplied data.
--
-- Parameters:
--   * pData = The data for which you want a hash value calculated.
--   * pMaxHash = (default = 0) The returned value will be no larger than this value.
--     However, a value of 0 or lower menas that it can grow as large as the maximum integer value.
--
-- Returns:
--		An **integer**, the value of which depends only on the supplied adata.
--
-- Comments:
-- This is used whenever you need a single number to represent the data you supply.
-- It can calculate the number based on all the data you give it, which can be
-- an atom or sequence of any value.
--
-- Example 1:
--   <eucode>
--   integer h1
--   h1 = calc_hash( symbol_name )
--   </eucode>

public function calc_hash(object key, integer pMaxHash = 0)
	atom ret

    ret = hash(key, FLETCHER32)
	if pMaxHash <= 0 then
		return ret
	end if

	return remainder(ret, pMaxHash) + 1 -- 1-based

end function

--**
-- Gets or Sets the threshold value that deterimes at what point a small map
-- converts into a large map structure. Initially this has been set to 50,
-- meaning that maps up to 50 elements use the 'small map' structure.
--
-- Parameters:
-- # pNewValue = If this is greater than zero then it **sets** the threshold
-- value.
--
-- Returns:
-- ##integer## The current value (when ##pNewValue## is less than 1) or the
-- old value prior to setting it to ##pNewValue##.
--
public function threshold(integer pNewValue = 0)

	if pNewValue < 1 then
		return vSizeThreshold
	end if

	integer lOldValue = vSizeThreshold
	vSizeThreshold = pNewValue
	return lOldValue
		
end function
	
--**
-- Determines the type of the map.
--
-- Parameters:
-- # m = A map
--
-- Returns:
-- ##integer## Either //SMALLMAP// or //LARGEMAP//
--
public function type_of(map m)

	return gMem[m][vType]
end function
	
--**
-- Changes the width, i.e. the number of buckets, of a map. Only effects
-- //large// maps.
--
-- Parameters:
--		# ##m##: the map to resize
--		# ##pRequestedSize##: a lower limit for the new size.
--
-- Returns:
--		A **map** with the same data in, but more evenly dispatched and hence faster to use.
--
-- Comment:
-- If ##pRequestedSize## is not greater than zero, a new width is automatically derived from the current one.
-- SEe Also:
--		[[:statistics]], [[:optimise]]


public procedure rehash(map m, integer pRequestedBucketSize = 0)
	integer size
	integer index2
	sequence oldKeyBuckets
	sequence oldValBuckets
	sequence newKeyBuckets
	sequence newValBuckets
	object key
	object value
	atom newsize
	sequence m0
	integer pos

	if gMem[m][vType] = SMALLMAP then
		return -- small maps are not hashed.
	end if
	
	if pRequestedBucketSize <= 0 then
		-- grow bucket size
		newsize = floor(length(gMem[m][vKeyBuckets]) * 3.5) + 1
		if newsize > maxInt then
				return  -- dont do anything. already too large
		end if
		size = newsize
	else
		size = pRequestedBucketSize
	end if
	
	size = next_prime(size, 2)	-- Allow up to 2 seconds to calc next prime.
	if size < 0 then
		size = -size	-- Failed to just use given size.
	end if
	oldKeyBuckets = gMem[m][vKeyBuckets]
	oldValBuckets = gMem[m][vValBuckets]
	newKeyBuckets = repeat({}, size)
	newValBuckets = repeat({}, size)
	m0 = {vMAPTYPE, 0, 0, LARGEMAP}

	for index = 1 to length(oldKeyBuckets) do
		for entry_idx = 1 to length(oldKeyBuckets[index]) do
			key = oldKeyBuckets[index][entry_idx]
			value = oldValBuckets[index][entry_idx]
			index2 = calc_hash(key, size)
			newKeyBuckets[index2] = append(newKeyBuckets[index2], key)
			newValBuckets[index2] = append(newValBuckets[index2], value)
			m0[vElemCnt] += 1
			if length(newKeyBuckets[index2]) = 1 then
				m0[vInUse] += 1
			end if
		end for
	end for

	m0 = append(m0, newKeyBuckets)
	m0 = append(m0, newValBuckets)

	gMem[m] = m0
end procedure

--**
-- Create a new map data structure
--
-- Parameters:
--		# ##initSize##: An estimate of how many initial elements will be stored
--   in the map. If this value is less than the [[:threshold]] value, the map
--   will initially be a //small// map otherwise it will be a //large// map.
--
-- Returns:
--		An empty **map**.
--
-- Comments:
--   A new object of type map is created.
--
-- Example 1:
--   <eucode>
--   map m = new()  -- m is now an empty map
--   map x = new(threshold()) -- Forces a small map to be initialized
--   </eucode>

public function new(integer initSize = 690)
	integer lBuckets
	sequence lNewMap
	integer m0

	if initSize < 3 then
		initSize = 3
	end if
	if initSize > vSizeThreshold then
		-- Return a large map
		lBuckets = floor(initSize / 30)
		if lBuckets < 23 then
			lBuckets = 23
		else
			lBuckets = next_prime(lBuckets)
		end if
		
		
		lNewMap = {vMAPTYPE, 0, 0, LARGEMAP, repeat({}, lBuckets), repeat({}, lBuckets)}
	else
		-- Return a small map
		lNewMap =  {vMAPTYPE, 0,0, SMALLMAP, repeat(vInitSmallKey, initSize), repeat(0, initSize), repeat(0, initSize)}
	end if
	m0 = malloc()
	gMem[m0] = lNewMap
	
	return m0
end function

--**
-- Returns either the supplied map or a new map.
--
-- Parameters:
--      # ##m##: An object, that could be an existing map
--		# ##initSize##: An estimate of how many initial elements will be stored
--   in a new map.
--
-- Returns:
--		If #m# is an existing map then it is returned otherwise this 
--      returns a new empty **map**.
--
-- Comments:
--   This is used to return a new map if the supplied variable isn't already
--   a map.
--
-- Example 1:
--   <eucode>
--   map m = new_extra( foo() ) -- If foo() returns a map it is used, otherwise
--                              --  a new map is created.
--   </eucode>

public function new_extra(object m, integer initSize = 690)
	if map(m) then
		return m
	else
		return new(initSize)
	end if
end function

--**
-- Delete an existing map data structure
--
-- Parameters:
--		# ##m##: The map to delete.
--      # ##embedded##: If not zero, this will also delete any maps contained
--      in this map's keys or values. The default is 0.
--
-- Comments:
--   * You use this routine when you have finished with a map and want to 
--   give back the memory to Euphoria. You don't normally have to do this
--   because all memory is reclaimed when the program ends, but it can be
--   useful if your program is not finished but it has finished using the map.
--   * If you have been using [[:nested_put]], you might want to use the
--   ##embedded## parameter to also delete sub-maps automatically created
--   by ##nested_put##.
--
-- Example 1:
--   <eucode>
--   map m = new()  -- m is a new map
--   . . .
--   delete(m) -- No longer needed, so give space back to Euphoria.
--   </eucode>

public procedure delete(map m, integer pEmbedded = 0)
	if pEmbedded != 0 then
		sequence lData
		lData = keys(m)
		for i = 1 to length(lData) do
			if map(lData[i]) then
				delete( lData[i], 1 )
			end if
		end for
		lData = values(m)
		for i = 1 to length(lData) do
			if map(lData[i]) then
				delete( lData[i], 1 )
			end if
		end for
	end if
	free(m)
end procedure

--**
-- Compares two maps to test equality.
--
-- Parameters:
--		# ##m1##: A map
--		# ##m2##: A map
--      # ##pScope##: An integer that specifies what to compare.
--        ** 'k' or 'K' to only compare keys.
--        ** 'v' or 'V' to only compare values.
--        ** 'd' or 'd' to compare both keys and values. This is the default.
--
-- Returns:
--   An integer...
--   * -1 if they are not equal.
--   * 0 if they are literally the same map.
--   * 1 if they contain the same keys and values.
--
-- Example 1:
--   <eucode>
--   map m1 = foo()
--   map m2 = bar()
--   if compare(m1, m2, 'k') >= 0 then
--        ... -- two maps have the same keys
--   </eucode>

public function compare(map m1, map m2, integer pScope = 'd')
	sequence p1
	sequence p2

	if m1 = m2 then
		return 0
	end if
	
	switch pScope do
		case 'v':
		case 'V':
			p1 = sort(values(m1))
			p2 = sort(values(m2))
			break
			
		case 'k':
		case 'K':
			p1 = sort(keys(m1))
			p2 = sort(keys(m2))
			break
			
		case else
			p1 = sort(pairs(m1))
			p2 = sort(pairs(m2))
			
	end switch
				
	if equal(p1, p2) then
		return 1
	end if
	
	return - 1
	
end function

--**
-- Check whether map has a given key.
--
-- Parameters:
-- 		# ##m##: the map to inspect
--		# ##key##: an object to be looked up
--
-- Returns:
--		An **integer**, 0 if not present, 1 if present.
--
-- Example 1:
--   <eucode>
--   map m
--   m = new()
--   m = put(m, "name", "John")
--   ? has(m, "name") -- 1
--   ? has(m, "age")  -- 0
--   </eucode>
--See Also:
-- 		[[:get]]
public function has(map m, object key)
	integer lIndex
	integer lPos
	
	if gMem[m][vType] = LARGEMAP then
		lIndex = calc_hash(key, length(gMem[m][vKeyBuckets]))
		lPos = find(key, gMem[m][vKeyBuckets][lIndex])
	else
		lPos = find(key, gMem[m][vKeyList])
	end if
	return (lPos  != 0)
	
end function

--**
-- Retrieves the value associated to a key in a map.
--
-- Parameters:
--		# ##m##: the map to inspect
--		# ##key##: an object, the key being looked tp
--		# ##defaultValue##: an object, a default value returned if ##key## not found.
--                         The default is 0.
--
-- Returns:
--		An **object**, the value that corresponds to ##key## in ##m##. 
--      If ##key## is not in ##m##, ##defaultValue## is returned instead.
--
-- Example 1:
--   <eucode>
--   map ages
--   ages = new()
--   put(ages, "Andy", 12)
--   put(ages, "Budi", 13)
--
--   integer age
--   age = get(ages, "Budi", -1)
--   if age = -1 then
--       puts(1, "Age unknown")
--   else
--       printf(1, "The age is %d", age)
--   end if
--   </eucode>
-- See Also:
--		[[:has]]

public function get(map m, object key, object defaultValue = 0)
	integer lBucket
	integer lPosn
	integer lFrom
	
	if gMem[m][vType] = LARGEMAP then
		lBucket = calc_hash(key, length(gMem[m][vKeyBuckets]))
		lPosn = find(key, gMem[m][vKeyBuckets][lBucket])
		if lPosn > 0 then
			return gMem[m][vValBuckets][lBucket][lPosn]
		end if
		return defaultValue
	else
		if equal(key, vInitSmallKey) then
			lFrom = 1
			while lFrom > 0 do
				lPosn = find_from(key, gMem[m][vKeyList], lFrom)
				if lPosn then
					if gMem[m][vFreeList][lPosn] = 1 then
						return gMem[m][vValList][lPosn]
					end if
				else
					return defaultValue
				end if
				lFrom = lPosn + 1
			end while
		else
			lPosn = find(key, gMem[m][vKeyList])
			if lPosn  then
				return gMem[m][vValList][lPosn]
			end if
		end if
	end if
	return defaultValue
end function

--**
-- Returns the value that corresponds to the object ##keys## in the nested map m.  ##keys## is a
-- sequence of keys.  If any key is not in the map, the object defaultValue is returned instead.
public function nested_get( map m, sequence keys, object defaultValue = 0)
	for i = 1 to length( keys ) - 1 do
		object val = get( m, keys[1], 0 )

		if not map( val ) then
			-- not a map
			return defaultValue
		else
			m = val
			keys = keys[2..$]
		end if
	end for
	return get( m, keys[1], defaultValue )
end function

--**
-- Adds or updates an entry on a map.
--
-- Parameters:
--		# ##m##: the map where an entry is being added or opdated
--		# ##key##: an object, the key to look up
--		# ##value##: an object, the value to add, or to use for updating.
--		# ##operation##: an integer, indicating what is to be done with ##value##. Defaults to PUT.
--		# ##pTrigger##: an integer. Default is 100. See Comments for details.
--
-- Returns:
--		The updated **map**.
--
-- Comments:
-- * The operation parameter can be used to modify the existing value.  Valid operations are: 
-- 
-- ** ##PUT##:  This is the default, and it replaces any value in there already
-- ** ##ADD##:  Equivalent to using the += operator 
-- ** ##SUBTRACT##:  Equivalent to using the -= operator 
-- ** ##MULTIPLY##:  Equivalent to using the *= operator
-- ** ##DIVIDE##: Equivalent to using the /= operator 
-- ** ##APPEND##: Appends the value to the existing data 
-- ** ##CONCAT##: Equivalent to using the &= operator
--
-- * The //trigger// parameter is used when you need to keep the average 
--     number of keys in a hash bucket to a specific maximum. The //trigger// 
--     value is the maximum allowed. Each time a //put// operation increases
--     the hash table's average bucket size to be more than the //trigger// value
--     the table is expanded by a factor 3.5 and the keys are rehashed into the
--     enlarged table. This can be a time intensitive action so set the value
--     to one that is appropriate to your application. 
--     ** By keeping the average bucket size to a certain maximum, it can
--        speed up lookup times. 
--     ** If you set the //trigger// to zero, it will not check to see if
--        the table needs reorganizing. You might do this if you created the original
--        bucket size to an optimal value. See [[:new]] on how to do this.
--
-- Example 1:
--   <eucode>
--   map ages
--   ages = new()
--   put(ages, "Andy", 12)
--   put(ages, "Budi", 13)
--   put(ages, "Budi", 14)
--
--   -- ages now contains 2 entries: "Andy" => 12, "Budi" => 14
--   </eucode>
--
-- See Also:
--		[[:remove]], [[:has]],  [[:nested_put]]

public procedure put(map m, object key, object value, integer operation = PUT, integer pTrigger = 100 )
	integer lIndex
	atom hashval
	integer lOffset
	object bucket
	atom lAvgLength
	integer bl
	integer lFrom
	sequence dbg

	if gMem[m][vType] = LARGEMAP then
		hashval = calc_hash(key, 0)
		lIndex = remainder(hashval,  length(gMem[m][vKeyBuckets])) + 1
		dbg = gMem[m][vKeyBuckets][lIndex]
		lOffset = find(key, gMem[m][vKeyBuckets][lIndex])
		if lOffset > 0 then
			-- The value already exists.
			switch operation do
				case PUT:
					gMem[m][vValBuckets][lIndex][lOffset] = value
					break
					
				case ADD:
					gMem[m][vValBuckets][lIndex][lOffset] += value
					break
					
				case SUBTRACT:
					gMem[m][vValBuckets][lIndex][lOffset] -= value
					break
					
				case MULTIPLY:
					gMem[m][vValBuckets][lIndex][lOffset] *= value
					break
					
				case DIVIDE:
					gMem[m][vValBuckets][lIndex][lOffset] /= value
					break
					
				case APPEND:
					gMem[m][vValBuckets][lIndex][lOffset] = append( gMem[m][vValBuckets][lIndex][lOffset], value )
					break
					
				case CONCAT:
					gMem[m][vValBuckets][lIndex][lOffset] &= value
					break					
			end switch
			return
		end if

		
		gMem[m][vInUse] += (length(gMem[m][vKeyBuckets][lIndex]) = 0)
		gMem[m][vElemCnt] += 1 -- elementCount
		
		
		-- write new entry
		if operation = APPEND then
			-- If appending, then the user wants the value to be an element, not the entire thing
			value = { value }
		end if


		gMem[m][vKeyBuckets][lIndex] = append(gMem[m][vKeyBuckets][lIndex], key)
		gMem[m][vValBuckets][lIndex] = append(gMem[m][vValBuckets][lIndex], value)
				
		if pTrigger > 0 then
			lAvgLength = gMem[m][vElemCnt] / gMem[m][vInUse]
			if (lAvgLength >= pTrigger) then
				rehash(m)
			end if
		end if
		
		return
	else -- Small Map
		if equal(key, vInitSmallKey) then
			lFrom = 1
			while lIndex > 0 entry do
				if gMem[m][vFreeList][lIndex] = 0 then
					exit
				end if
				lFrom = lIndex + 1
			  entry
				lIndex = find_from(key, gMem[m][vKeyList], lFrom)
			end while
		else
			lIndex = find(key, gMem[m][vKeyList])
		end if
		
		-- Did we find it?
		if lIndex = 0 then
			-- No, so add it.
			lIndex = find(0, gMem[m][vFreeList])
			if lIndex = 0 then
				-- No room left, so now it becomes a large map.
				ConvertToLarge(m)
				put(m, key, value, operation, pTrigger)
				return
			else
				gMem[m][vKeyList][lIndex] = key
				gMem[m][vValList][lIndex] = value
				gMem[m][vFreeList][lIndex] = 1
				gMem[m][vInUse] += 1
				gMem[m][vElemCnt] += 1
				return
			end if
		end if
		
		switch operation do
			case PUT:
				gMem[m][vValList][lIndex] = value
				break
				
			case ADD:
				gMem[m][vValList][lIndex] += value
				break
				
			case SUBTRACT:
				gMem[m][vValList][lIndex] -= value
				break
				
			case MULTIPLY:
				gMem[m][vValList][lIndex] *= value
				break
				
			case DIVIDE:
				gMem[m][vValList][lIndex] /= value
				break
				
			case APPEND:
				gMem[m][vValList][lIndex] = append( gMem[m][vValList][lIndex], value )
				break
				
			case CONCAT:
				gMem[m][vValList][lIndex] &= value
				break
				
		end switch
		return
		
	end if
end procedure


--**
-- Adds or updates an entry on a map.
--
-- Parameters:
--		# ##m##: the map where an entry is being added or opdated
--		# ##keys##: a sequence of keys for the nested maps
--		# ##value##: an object, the value to add, or to use for updating.
--		# ##operation##: an integer, indicating what is to be done with ##value##. Defaults to PUT.
--		# ##pTrigger##: an integer. Default is 51. See Comments for details.
--
-- Valid operations are: 
-- 
-- * ##PUT##:  This is the default, and it replaces any value in there already
-- * ##ADD##:  Equivalent to using the += operator 
-- * ##SUBTRACT##:  Equivalent to using the -= operator 
-- * ##MULTIPLY##:  Equivalent to using the *= operator 
-- * ##DIVIDE##: Equivalent to using the /= operator 
-- * ##APPEND##: Appends the value to the existing data 
-- * ##CONCAT##: Equivalent to using the &= operator
--
-- Returns:
--   The modified map.
--
-- Comments:
--   * If existing entry with the same key is already in the map, the value of the entry is updated.
--   * The //trigger// parameter is used when you need to keep the average 
--     number of keys in a hash bucket to a specific maximum. The //trigger// 
--     value is the maximum allowed. Each time a //put// operation increases
--     the hash table's average bucket size to be more than the //trigger// value
--     the table is expanded by a factor 3.5 and the keys are rehashed into the
--     enlarged table. This can be a time intensitive action so set the value
--     to one that is appropriate to your application. 
--     ** By keeping the average bucket size to a certain maximum, it can
--        speed up lookup times. 
--     ** If you set the //trigger// to zero, it will not check to see if
--        the table needs reorganizing. You might do this if you created the original
--        bucket size to an optimal value. See [[:new]] on how to do this.
--
-- Example 1:
--   <eucode>
--   map city_population
--   city_population = new()
--   city_population = nested_put(city_population, {"United States", "California", "Los Angeles"}, 3819951 )
--   city_population = nested_put(city_population, {"Canada",        "Ontario",    "Toronto"},     2503281 )
--   </eucode>
--
-- See also:  [[:put]]
public procedure nested_put( map m, sequence keys, object value, integer operation = PUT, integer pTrigger = 51 )
	integer m2

	if length( keys ) = 1 then
		put( m, keys[1], value, operation, pTrigger )
		return
	else
		m2 = get( m, keys[1] )
		if m2 = 0 then
			m2 = new()
		end if
		nested_put( m2, keys[2..$], value, operation, pTrigger )
		put( m, keys[1], m2, PUT, pTrigger )
		return
	end if
end procedure

--**
-- Remove an entry with given key from a map.
--
-- Parameters:
--		# ##m##: the map to operate on
--		# ##key##: an object, the key to remove.
--
-- Returns:
--		 The modified **map**.
--
-- Comments:
--   * If ##key## is not on ##m##, the ##m## is returned unchanged.
--   * If you need to remove all entries, see [[:clear]]
--
-- Example 1:
--   <eucode>
--   map m
--   m = new()
--   put(m, "Amy", 66.9)
--   remove(m, "Amy")
--   -- m is now an empty map again
--   </eucode>
--
-- See Also:
--		[[:clear]], [[:has]]

public procedure remove(map m, object key)
	integer hash, lIndex
	object bucket
	sequence m0
	integer lFrom
	

	m0 = gMem[m]
	if m0[vType] = LARGEMAP then
		lIndex = calc_hash(key, length(m0[vKeyBuckets]))
	
		-- find prev entry
		hash = find(key, m0[vKeyBuckets][lIndex])
		if hash != 0 then
			m0[vElemCnt] -= 1
			if length(m0[vKeyBuckets][lIndex]) = 1 then
				m0[vInUse] -= 1
				m0[vKeyBuckets][lIndex] = {}
				m0[vValBuckets][lIndex] = {}
			else
				m0[vValBuckets][lIndex] = m0[vValBuckets][lIndex][1 .. hash-1] & m0[vValBuckets][lIndex][hash+1 .. $]
				m0[vKeyBuckets][lIndex] = m0[vKeyBuckets][lIndex][1 .. hash-1] & m0[vKeyBuckets][lIndex][hash+1 .. $]
			end if
			
			if m0[vElemCnt] < floor(51 * vSizeThreshold / 100) then
				gMem[m] = m0
				ConvertToSmall(m)
				return
			end if
		end if
	else
		lFrom = 1
		while lFrom > 0 do
			lIndex = find_from(key, m0[vKeyList], lFrom)
			if lIndex then
				if m0[vFreeList][lIndex] = 1 then
					m0[vFreeList][lIndex] = 0
					m0[vKeyList][lIndex] = vInitSmallKey
					m0[vValList][lIndex] = 0
					m0[vInUse] -= 1
					m0[vElemCnt] -= 1
				end if
			else
				exit
			end if
			lFrom = lIndex + 1
		end while
	end if
	gMem[m] = m0
	return
end procedure

--**
-- Remove all entries in a map.
--
-- Parameters:
--		# ##m##: the map to operate on
--
-- Comments:
--   * This is much faster than removing each entry individually.
--   * If you need to remove just one entry, see [[:remove]]
--
-- Example 1:
--   <eucode>
--   map m
--   m = new()
--   put(m, "Amy", 66.9)
--   put(m, "Betty", 67.8)
--   put(m, "Claire", 64.1)
--   ...
--   clear(m)
--   -- m is now an empty map again
--   </eucode>
--
-- See Also:
--		[[:remove]], [[:has]]

public procedure clear(map m)
	sequence m0

	m0 = gMem[m]
	if m0[vType] = LARGEMAP then
		m0[vElemCnt] = 0
		m0[vInUse] = 0
		m0[vKeyBuckets] = repeat({}, length(m0[vKeyBuckets]))
		m0[vValBuckets] = repeat({}, length(m0[vValBuckets]))
	else
		m0[vElemCnt] = 0
		m0[vInUse] = 0
		m0[vKeyList] = repeat(0, length(m0[vKeyList]))
		m0[vValList] = repeat(0, length(m0[vValList]))
		m0[vFreeList] = repeat(0, length(m0[vFreeList]))
	end if
	gMem[m] = m0
	return
end procedure

--**
-- Return the number of entries in a map.
--
-- Parameters:
--		##m##: the map being queried
--
-- Returns:
--		An **integer**, the number of entries it has.
--
-- Comments:
--   For an empty map, size will be zero
--
-- Example 1:
--   <eucode>
--   map m
--   m = put(m, 1, "a")
--   m = put(m, 2, "b")
--   ? size(m) -- outputs 2
--   </eucode>
--
-- See Also:
--		[[:statistics]]
public function size(map m)
	return gMem[m][vElemCnt]
end function

--**
-- Retrieves characteristics of a map.
--
-- Parameters:
-- 		# ##m##: the map being queried
--
-- Returns:
--		A  **sequence** of 7 integers:
-- * number of entries
-- * number of buckets in use
-- * number of buckets
-- * size of largest bucket
-- * size of smallest bucket
-- * average size for a bucket
-- * * standard deviation for the bucket length series

public enum
	NUM_ENTRIES,
	NUM_IN_USE,
	NUM_BUCKETS,
	LARGEST_BUCKET,
	SMALLEST_BUCKET,
	AVERAGE_BUCKET,
	STDEV_BUCKET

public function statistics(map m)
	sequence lStats
	sequence lLengths
	integer lLength
	sequence m0
	
	m0 = gMem[m]

	if m0[vType] = LARGEMAP then
		lStats = {m0[vElemCnt], m0[vInUse], length(m0[vKeyBuckets]), 0, maxInt, 0, 0}
		lLengths = {}
		for i = 1 to length(m0[vKeyBuckets]) do
			lLength = length(m0[vKeyBuckets][i])
			if lLength > 0 then
				if lLength > lStats[LARGEST_BUCKET] then
					lStats[LARGEST_BUCKET] = lLength
				end if
				if lLength < lStats[SMALLEST_BUCKET] then
					lStats[SMALLEST_BUCKET] = lLength
				end if
				lLengths &= lLength
			end if
		end for
		lStats[AVERAGE_BUCKET] = stats:average(lLengths)
		lStats[STDEV_BUCKET] = stats:stdev(lLengths)
	else
		lStats = {m0[vElemCnt], m0[vInUse], length(m0[vKeyList]), length(m0[vKeyList]), length(m0[vKeyList]), length(m0[vKeyList]), 0}
	end if
	return lStats
end function

--**
-- Return all keys in a map.
--
-- Parameters;
--		# ##m##: the map being queried
--
-- Returns:
-- 		A **sequence** made of all the keys in the map.
--
-- Comments:
--   The order of the keys returned may not be the same as the putting order.
--
-- Example 1:
--   <eucode>
--   map m
--   m = new()
--   put(m, 10, "ten")
--   put(m, 20, "twenty")
--   put(m, 30, "thirty")
--   put(m, 40, "forty")
--
--   sequence keys
--   keys = keys(m) -- keys might be {20,40,10,30} or some other order
--   </eucode>
-- See Also:
--		[[:has]], [[:values]], [[:pairs]]
public function keys(map m)
	sequence buckets
	sequence bucket
	sequence ret
	integer pos
	sequence m0
	
	m0 = gMem[m]

	ret = repeat(0, m0[vElemCnt])
	pos = 1

	if m0[vType] = LARGEMAP then
		buckets = m0[vKeyBuckets]
		for index = 1 to length(buckets) do
			bucket = buckets[index]
			if length(bucket) > 0 then
				ret[pos .. pos + length(bucket) - 1] = bucket
				pos += length(bucket)
			end if
		end for
	else
		for index = 1 to length(m0[vFreeList]) do
			if m0[vFreeList][index] !=  0 then
				ret[pos] = m0[vKeyList][index]
				pos += 1
			end if
		end for
		
	end if
	return ret
end function

--**
--
-- Return all values in a map.
--
-- Parameters:
--		# ##m##: the map being queried
--
-- Returns:
--		A **sequence** of all values stored in ##m##.
--
-- Comments:
--   The order of the values returned may not be the same as the putting order. 
--   Duplicate values are not removed.
--
-- Example 1:
--   <eucode>
--   map m
--   m = new()
--   m = put(m, 10, "ten")
--   m = put(m, 20, "twenty")
--   m = put(m, 30, "thirty")
--   m = put(m, 40, "forty")
--
--   sequence values
--   values = values(m) -- values might be {"twenty","forty","ten","thirty"} 
--    or some other order
--   </eucode>
 -- See Also:
 --		[[:get]], [[:keys]], [[:pairs]]
public function values(map m)
	sequence buckets
	sequence bucket
	sequence ret
	integer pos
	sequence m0
	
	m0 = gMem[m]

	ret = repeat(0, m0[vElemCnt])
	pos = 1

	if m0[vType] = LARGEMAP then
		buckets = m0[vValBuckets]
		for index = 1 to length(buckets) do
			bucket = buckets[index]
			if length(bucket) > 0 then
				ret[pos .. pos + length(bucket) - 1] = bucket
				pos += length(bucket)
			end if
		end for
	else
		for index = 1 to length(m0[vFreeList]) do
			if m0[vFreeList][index] !=  0 then
				ret[pos] = m0[vValList][index]
				pos += 1
			end if
		end for
		
	end if
	return ret
end function

--**
--
-- Return all key/value pairs in a map.
--
-- Parameters:
--		# ##m##: the map being queried
--
-- Returns:
--		A **sequence** of all key/value pairs stored in ##m##. Each pair is a 
-- subsequence in the form {key, value}
--
-- Comments:
--   The order of the values returned may not be the same as the putting order. 
--
-- Example 1:
--   <eucode>
--   map m
--   m = new()
--   m = put(m, 10, "ten")
--   m = put(m, 20, "twenty")
--   m = put(m, 30, "thirty")
--   m = put(m, 40, "forty")
--
--   sequence keyvals
--   keyvals = pairs(m) -- might be {{20,"twenty"},{40,"forty"},{10,"ten"},{30,"thirty"}}
--   </eucode>
 -- See Also:
 --		[[:get]], [[:keys]], [[:values]]
public function pairs(map m)
	sequence keybucket
	sequence valbucket
	sequence ret
	integer pos
	sequence m0
	
	m0 = gMem[m]

	ret = repeat({0,0}, m0[vElemCnt])
	pos = 1

	if m0[vType] = LARGEMAP then
		for index = 1 to length(m0[vKeyBuckets]) do
			keybucket = m0[vKeyBuckets][index]
			valbucket = m0[vValBuckets][index]
			for j = 1 to length(keybucket) do
				ret[pos][1] = keybucket[j]
				ret[pos][2] = valbucket[j]
				pos += 1
			end for
		end for
	else
		for index = 1 to length(m0[vFreeList]) do
			if m0[vFreeList][index] !=  0 then
				ret[pos][1] = m0[vKeyList][index]
				ret[pos][2] = m0[vValList][index]
				pos += 1
			end if
		end for
		
	end if
	return ret
end function

--**
-- Widens a map to increase performance.
--
-- Parameters:
--		# ##m##: the map being optimised
--		# ##pMax##: an integer, the maximum desired size of a bucket. Default is 25.
--                  This must be 3 or higher.
--      # ##pGrow##: an atom, the factor to grow the number of buckets for each
--                   iteration of rehashing. Default is 1.333. This must be 
--                   greater than 1.
--
-- Returns:
--		The optimised **map**.
--
-- Comments:
--      This rehashes the map until either the maximum bucket size is less than
--      the desired maximum or the maximum bucket size is less than the largest
--      size statistically expected (mean + 3 standard deviations).
--
-- See Also:
--		[[:statistics]], [[:rehash]]
public procedure optimize(map m, integer pMax = 25, atom pGrow = 1.333)
	sequence op
	integer lNextGuess
	
	if gMem[m][vType] = LARGEMAP then
		if pGrow < 1 then
			pGrow = 1.333
		end if
		if pMax < 3 then
			pMax = 3
		end if
		
		lNextGuess = max({1, floor(gMem[m][vElemCnt] / pMax)})
		while 1 entry do
		
			if op[LARGEST_BUCKET] <= pMax then
				exit -- Largest is now smaller than the maximum I wanted.
			end if
			
			if op[LARGEST_BUCKET] <= (op[STDEV_BUCKET]*3 + op[AVERAGE_BUCKET]) then
				exit -- Largest is smaller than is statistically expected.
			end if
			
			lNextGuess = floor(op[NUM_BUCKETS] * pGrow)
			
		  entry
			rehash(m, lNextGuess)
			op = statistics(m)
		end while
	end if
	return
end procedure

--**
-- Loads a map from a file
--
-- Parameters:
--		# ##pFileName##: a sequence, the name of the file to load from.
--
-- Returns:
--		A **map** with all the entries found in ##pFileName##.
--
-- Comments:
-- The imported file format needs to be that it has one entry per line, each
-- line being of the form <key>=<value>.  Whitespace around the key and the
-- value is ignored. Comment lines start with {{{"--"}}} and are also ignored.
-- <values> that can be converted to atom will be, meaning that X=3 is stored
-- as a key of "X" and a value of 3, rather than "3"\\
-- Input file example:
-- :
-- {{{
--    -- Set the verbosity Level
--    verbose=3
--    -- Tell the app where to put the output files.
--    outdir = c:\temp
-- }}}
--
-- Example 1:
-- <eucode>
--    map AppOptions
--    AppOptions = load_map("c:\myapp\options.txt")
--    if get(AppOptions, "verbose", 1) = 3 then
--        ShowIntructions()
--    end if
-- </eucode>
-- See Also:
--		[[:new]], [[:save_map]]
public function load_map(sequence pFileName)
	integer fh
	object lLine
	integer lComment
	integer lDelim
	object lValue
	sequence lKey
	sequence lConvRes
	integer m

	fh = open(pFileName, "r")
	if fh = -1 then
		return 0
	end if

	m = new(vSizeThreshold) -- Assume a small map initially.
	while sequence(lLine) entry do
		lComment = rmatch("--", lLine)
		if lComment != 0 then
			lLine = trim(lLine[1..lComment-1])
		end if
		lDelim = find('=', lLine)
		if lDelim > 0 then
			lKey = trim(lLine[1..lDelim-1])
			if length(lKey) > 0 then
				lValue = trim(lLine[lDelim+1..$])
				lValue = find_replace("\\-", lValue, "-")
				lConvRes = value(lValue,,GET_LONG_ANSWER)
				if lConvRes[1] = GET_SUCCESS then
					if lConvRes[3] = length(lValue) then
						lValue = lConvRes[2]
					end if
				end if
				put(m, lKey, lValue)
			end if
		end if
	  entry
		lLine = gets(fh)
	end while

	close(fh)
	optimize(m)
	return m
end function

--**
-- Saves a map to a file.
--
-- Parameters:
--		# ##m##: a map.
--		# ##pFileName##: a sequence, the name of the file to save to.
--
-- Returns:
--		##integer## = The number of keys saved to the file.
--
-- Comments:
-- It only saves key/value pairs if the keys only  contain letters, digits and
-- underscore, and only if the value contains only printable characters. This
-- means that numeric keys or nested sequence keys are not saved, nor are 
-- nested sequence values. **Note~:** that numeric values are allowed and
-- will be saved.
--
-- Example 1:
-- <eucode>
--    map AppOptions
--    if save_map(AppOptions, "c:\myapp\options.txt") = 0
--        Error("Failed to save application options")
--    end if
-- </eucode>
-- See Also:
--		[[:load_map]]
public function save_map(map m, sequence pFileName)
	integer lFH = -2
	sequence lKeys
	sequence lValues
	integer lOutCount = 0
	
	
	lKeys = keys(m)
	lValues = values(m)
	for i = 1 to length(lKeys) do
		if char_test(lKeys[i], {{'a','z'},{'A', 'Z'}, {'_','_'}}) then
			lValues[i] = pretty_sprint(lValues[i], {2,0,1,0,"%d","%.15g",32,127,1,0})
			lValues[i] = find_replace("-", lValues[i], "\\-")
			
			if lFH < 0 then
				lFH = open(pFileName, "w")
				if lFH < 0 then
					return 0
				end if
			end if
			printf(lFH, "%s = %s\n", {lKeys[i], lValues[i]})
			lOutCount += 1
		end if
	end for
	close(lFH)
	return lOutCount
end function

public function copy(map m)
	integer m0
	
 	m0 = malloc()
 	gMem[m0] = gMem[m]
	return m0
end function

---- Local Functions ------------
procedure ConvertToLarge(map m)
	sequence m0
	integer m2

	m0 = gMem[m]
	if m0[vType] = LARGEMAP then
		return 
	end if
	
	m2 = new()
	for index = 1 to length(m0[vFreeList]) do
		if m0[vFreeList][index] !=  0 then
			put(m2, m0[vKeyList][index], m0[vValList][index])
		end if
	end for

	gMem[m] = gMem[m2]
	free(m2)
	return
end procedure

procedure ConvertToSmall(map m)
	integer m2
	sequence lKeys
	sequence lVals

	if gMem[m][vType] = SMALLMAP then
		return
	end if
	lKeys = keys(m)
	lVals = values(m)
	
	gMem[m] = {vMAPTYPE, 0,0, SMALLMAP, repeat(vInitSmallKey, vSizeThreshold), repeat(0, vSizeThreshold), repeat(0, vSizeThreshold)}
	
	for index = 1 to length(lKeys) do
		put(m, lKeys[index], lVals[index])
	end for

	return
end procedure

