-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Map (hash table)
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

include std/get.e
include std/primes.e
include std/convert.e
include stats.e as stats
include std/text.e
include std/search.e
include std/types.e
include std/pretty.e

constant iElemCnt = 1 -- ==> elementCount
constant iInUse = 2 -- ==> count of non-empty buckets
constant iBuckets = 3 -- ==> bucket[] --> bucket = {key[], value[]}
constant iKeyList = 3 -- ==> Small map keys
constant iValList = 4 -- ==> Small map values
constant iFreeSpace = 5 -- ==> Small map freespace
constant iKeys = 1
constant iVals = 2
constant iSmallMap = 5
constant iLargeMap = 3

integer ri_ConvertToLarge
integer ri_ConvertToSmall

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
-- Convenience empty map:
-- * BLANK_MAP
--
-- Types of Maps
-- * SMALLMAP
-- * LARGEMAP

public enum
	PUT,
	ADD,
	SUBTRACT,
	MULTIPLY,
	DIVIDE,
	APPEND,
	CONCAT,
	SMALLMAP,
	LARGEMAP

integer vSizeThreshold = 50

-- Used to initialize a small map's keys list. 
constant vInitSmallKey = -960.35894374 

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

public type map(object o)
-- Large maps have three elements:
--   (1) 
--   (2) 
--   (3) Sequence containing two subsequences: Key-Buckets and Value-Buckets

-- Small maps have five elements:
--   (1)
--   (2)
--   (3) Sequence of keys
--   (4) Sequence of values, in the same order as the keys.
--   (5) Sequence. A Free space map.
		if atom(o) 				then return 0 end if
		if length(o) < 3 		then return 0 end if
		if length(o) > 5 		then return 0 end if
		if length(o) = 4 		then return 0 end if
		if not integer(o[iElemCnt]) then return 0 end if
		if o[iElemCnt] < 0 		then return 0 end if
		if not integer(o[iInUse]) then return 0 end if
		if o[iInUse] < 0		then return 0 end if
		if atom(o[iKeyList])	then return 0 end if
		if length(o) = iSmallMap then
			if atom(o[iValList]) 		then return 0 end if
			if atom(o[iFreeSpace]) 		then return 0 end if
			if length(o[iKeyList]) = 0 then return 0 end if
			if length(o[iKeyList]) != length(o[iValList]) then return 0 end if
			if length(o[iKeyList]) != length(o[iFreeSpace]) then return 0 end if
		end if
		return 1
end type

constant maxInt = #3FFFFFFF

--****
-- === Support outines
--

--**
-- Signature:
--   global function hash(object source, object algo)
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
-- ** Anything else except negative integers: uses the cyclic variant (hash = hash * algo + c)
--   Fast and good to excellent dispersion depending on the value of //algo//.
--  Decimals give better dispersion but are slightly slower. The value zero is 
--  also slightly slower but gives a secure hash value.
--
-- Returns:
--     An **atom**:
--        Except for the MD5 and SHA256 algorithms, this is a 32-bit value.
--     A **sequence**:
--        MD5 returns a 4-element sequence of integers\\
--        SHA256 returns a 8-element sequence of integers.
--
-- Example 1:
-- <eucode>
-- x = hash("The quick brown fox jumps over the lazy dog", 0)
-- -- x is 3071488335
-- x = hash("The quick brown fox jumps over the lazy dog", 99.94)
-- -- x is 2065442629
-- x = hash("The quick brown fox jumps over the lazy dog", -4)
-- -- x is 1541148634
-- x = hash("The quick brown fox jumps over the lazy dog", "secret word")
-- -- x is 1300119431
-- </eucode>
--
-- See Also:
-- [[:calc_hash]]

--**
-- Calculate a Hashing value from the supplied data.
--
-- Parameters:
--   # ##pData##: the data for which you want a hash value calculated.
--   # ##pMaxHash##: an integer, which is a cap on the returned value. Defaults to 0 (no cap).
--
-- Returns:
--		An **integer**, the value of which depends only on the supplied adata.
--
-- Comments:
--
-- This is used whenever you need a single number to represent the data you supply.
-- It can calculate the number based on all the data you give it, which can be
-- an atom or sequence of any value.
--
-- If ##pMaxHash## is less than one, the returned value can grow as large as the maximum Euphoria integer.
--
-- Example 1:
--   <eucode>
--   integer h1
--   h1 = calc_hash( symbol_name )
--   </eucode>

public function calc_hash(object key, integer pMaxHash = 0)
	atom ret

	ret = hash(key, 0)	
	if pMaxHash <= 0 then
		return ret
	end if

	return remainder(ret, pMaxHash) + 1 -- 1-based

end function

--**
-- Gets or Sets the threshhold value that determines at what point a small map
-- converts into a large map structure.
--
-- Parameters:
-- # ##pNewValue##: an integer, 0 or less to get the threshhold, greater than zero to set.
--
-- Returns:
-- An ##integer##:
-- * when ##pNewValue## is less than 1, the current threshhold value; or
-- * when ##pNewValue## is 1 or more, the prevous value of the threshhold.
--
-- Comments:
--
-- Initially this has been set to 50,
-- meaning that maps up to 50 elements use the 'small map' structure.
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
-- # ##m##: the map being queried.
--
-- Returns:
-- An ##integer##, either ##SMALLMAP## or ##LARGEMAP##.
--
public function is_type(map m)

	if length(m) = iSmallMap then
		return SMALLMAP
	else
		return LARGEMAP
	end if		
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
--
-- See Also:
--		[[:statistics]], [[:optimize]]
public function rehash(map m, integer pRequestedSize = 0)
	integer size
	atom index2
	sequence oldBuckets, newBuckets
	object key, value
	atom newsize
	sequence m0

	if length(m) = iSmallMap then
		return m
	end if
	
	m0 = m

	if pRequestedSize <= 0 then
		-- grow bucket size
		newsize = floor(length(m[iBuckets]) * 3.5) + 1
		if newsize > maxInt then
				return m -- dont do anything. already too large
		end if
		size = newsize
	else
		size = pRequestedSize
	end if
	size = next_prime(size)
	oldBuckets = m[iBuckets]
	newBuckets = repeat({{},{}}, size)
	m0[iInUse] = 0
	for index = 1 to length(oldBuckets) do
		for entry_idx = 1 to length(oldBuckets[index][iKeys]) do
			key = oldBuckets[index][iKeys][entry_idx]
			value = oldBuckets[index][iVals][entry_idx]
			index2 = calc_hash(key, size)
			newBuckets[index2][iKeys] = append(newBuckets[index2][iKeys],key)
			newBuckets[index2][iVals] = append(newBuckets[index2][iVals],value)
			if length(newBuckets[index2][iVals]) = 1 then
				m0[iInUse] += 1
			end if
		end for
	end for

	m0[iBuckets] = newBuckets

	return m0
end function

--****
-- === Map management
--

--**
-- Create a new map data structure
--
-- Parameters:
--		# ##initSize##: An initial estimate of how many elements will be stored
--   in the map.
--
-- Returns:
--		An empty **map**.
--
-- Comments:
--   A new object of type map is created. If ##initSize## is less than the [[:threshold]] value, the map
--   will initially be a //small// map otherwise it will be a //large// map.
--
-- Example 1:
--   <eucode>
--   map m = new()  -- m is now an empty map
--   map x = new(threshold()) -- Forces a small map to be initialized
--   </eucode>

public function new(integer initSize = 66)
	integer lBuckets

	if initSize < 3 then
		initSize = 3
	end if
	if initSize > vSizeThreshold then
		-- Return a large map
		lBuckets = next_prime(floor((initSize + 1) / 4))
		return {0, 0, repeat({{},{}}, lBuckets ) }
	end if
	-- Return a small map
	return {0,0, repeat(vInitSmallKey, initSize), repeat(0, initSize), repeat(0, initSize)}
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
	atom lIndex
	integer lFrom

	if length(m) = iLargeMap then
		lIndex = calc_hash(key, length(m[iBuckets]))
		return (find(key, m[iBuckets][lIndex][iKeys]) != 0)
	else
		lFrom = 1
		while lFrom > 0 do
			lIndex = find_from(key, m[iKeyList], lFrom)
			if lIndex then
				if m[iFreeSpace][lIndex] = 1 then
					return 1
				end if
			else
				return 0
			end if
			lFrom = lIndex + 1
		end while
	end if
	
end function

--**
-- Retrieves the value associated to a key in a map.
--
-- Parameters:
--		# ##m##: the map to inspect
--		# ##key##: an object, the key being looked tp
--		# ##defaultValue##: an object, a default value returned if ##key## not found
--
-- Returns:
--		An **object**, the value that corresponds to ##key## in ##m##. If ##key## is not in ##m##, ##defaultValue## is returned instead.
--
-- Example 1:
--   <eucode>
--   map ages
--   ages = new()
--   ages = put(ages, "Andy", 12)
--   ages = put(ages, "Budi", 13)
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
--		[[:has]], [[:nested_get]]
public function get(map m, object key, object defaultValue)
	atom lIndex
	integer lOffset
	integer lFrom
	
	if length(m) = iLargeMap then
		lIndex = calc_hash(key, length(m[iBuckets]))
		lOffset = find(key, m[iBuckets][lIndex][iKeys])
		if lOffset != 0 then
			return m[iBuckets][lIndex][iVals][lOffset]
		else
			return defaultValue
		end if
	else
		lFrom = 1
		while lFrom > 0 do
			lIndex = find_from(key, m[iKeyList], lFrom)
			if lIndex then
				if m[iFreeSpace][lIndex] = 1 then
					return m[iValList][lIndex]
				end if
			else
				return defaultValue
			end if
			lFrom = lIndex + 1
		end while
	end if
end function

--**
-- Returns the value that corresponds to a key in a nested map.
--
-- Parameters:
--		# ##m##: the master map in which to search.
--		# ##keys##: a non empty sequence, each element of which is a key in the previous one, which is a map.
--		# ##defaultValue##: an object, to be return on an unsuccesful lookup.
--
-- Returns:
-- An **object**, either the value associated to ##keys[$]## in its home map, or ##defaultValue## on failure.
--
-- Comments:
--
-- If any of the ##keys[i]## but the last is not a map, the search fails.
--
-- ##keys[1]## is looked up in ##m##. On success, ##keys[2]## is looked up in ##keys[1]##, and so on.
-- The last step is an ordinary [[:get]]().
--
-- See Also:
-- [[:get]]

public function nested_get( map m, sequence keys, object defaultValue )
	for i = 1 to length( keys ) - 1 do
		object val = get( m, keys[1], 0 )
		if atom( val ) then
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
--
-- The operation parameter can be used to modify the existing value.  Valid operations are: 
-- 
-- * ##PUT##:  This is the default, and it replaces any value in there already
-- * ##ADD##:  Equivalent to using the += operator 
-- * ##SUBTRACT##:  Equivalent to using the -= operator 
-- * ##MULTIPLY##:  Equivalent to using the *= operator
-- * ##DIVIDE##: Equivalent to using the /= operator 
-- * ##APPEND##: Appends the value to the existing data 
-- * ##CONCAT##: Equivalent to using the &= operator
--
--   If existing entry with the same key is already in the map, the value of the entry is updated.
--
-- ##pTrigger## sets the sensitivity of ##m## to additions. The lower the value, the more often an addition will cause a [[:rehash]](). A value of 0 or less disables the check, ensuring no rehash takes place on this particular call.. 
--
-- Example 1:
--   <eucode>
--   map ages
--   ages = new()
--   ages = put(ages, "Andy", 12)
--   ages = put(ages, "Budi", 13)
--   ages = put(ages, "Budi", 14)
--
--   -- ages now contains 2 entries: "Andy" => 12, "Budi" => 14
--   </eucode>
--
-- See Also:
--		[[:remove]], [[:has]],  [[:nested_put]]

public function put(map m, object key, object value, integer operation = PUT, integer pTrigger = 100 )
	integer lIndex
	atom hashval
	integer lOffset
	object bucket
	atom lAvgLength
	sequence m0
	integer bl
	integer lFrom

	m0 = m
	if length(m) = iLargeMap then
		hashval = calc_hash(key, 0)
		lIndex = remainder(hashval, length(m[iBuckets])) + 1
		bucket = m[iBuckets][lIndex]
		bl = length(bucket[iVals])
		lOffset = find(key, bucket[iKeys])
	
		if lOffset != 0 then
			switch operation do
				case PUT:
					bucket[iVals][lOffset] = value
					break
					
				case ADD:
					bucket[iVals][lOffset] += value
					break
					
				case SUBTRACT:
					bucket[iVals][lOffset] -= value
					break
					
				case MULTIPLY:
					bucket[iVals][lOffset] *= value
					break
					
				case DIVIDE:
					bucket[iVals][lOffset] /= value
					break
					
				case APPEND:
					bucket[iVals][lOffset] = append( bucket[iVals][lOffset], value )
					break
					
				case CONCAT:
					bucket[iVals][lOffset] &= value
					break
					
			end switch

			m0[iBuckets][lIndex] = bucket
			return m0
		end if
		if bl = 0 then
			m0[iInUse] += 1
		end if
	
		m0[iElemCnt] += 1 -- elementCount
		if pTrigger > 0 then
			lAvgLength = m0[iElemCnt] / m0[iInUse]
			if (lAvgLength >= pTrigger) then
				m0 = rehash(m0)
				lIndex = remainder(hashval, length(m0[iBuckets])) + 1
			end if
		end if
		-- write new entry
		m0[iBuckets][lIndex][iKeys] = append(m0[iBuckets][lIndex][iKeys], key)
		if operation = APPEND then
			-- If appending, then the user wants the value to be an element, not the entire thing
			value = { value }
		end if
		m0[iBuckets][lIndex][iVals] = append(m0[iBuckets][lIndex][iVals], value)
		
		return m0
	else
		lFrom = 1
		while lFrom > 0 do
			lIndex = find_from(key, m0[iKeyList], lFrom)
			if lIndex then
				if m0[iFreeSpace][lIndex] = 1 then
					exit
				end if
			else
				exit
			end if
			lFrom = lIndex + 1
		end while
		
		-- Did we find it?
		if lIndex = 0 then
			-- No, so add it.
			lIndex = find(0, m0[iFreeSpace])
			if lIndex = 0 then
				-- No room left, so now it becomes a large map.
				return put(call_func(ri_ConvertToLarge,{m0}), key, value, operation, pTrigger)
			else
				m0[iKeyList][lIndex] = key
				m0[iValList][lIndex] = value
				m0[iFreeSpace][lIndex] = 1
				m0[iInUse] += 1
				m0[iElemCnt] += 1
				return m0
			end if
		end if
		
		switch operation do
			case PUT:
				m0[iValList][lIndex] = value
				break
				
			case ADD:
				m0[iValList][lIndex] += value
				break
				
			case SUBTRACT:
				m0[iValList][lIndex] -= value
				break
				
			case MULTIPLY:
				m0[iValList][lIndex] *= value
				break
				
			case DIVIDE:
				m0[iValList][lIndex] /= value
				break
				
			case APPEND:
				m0[iValList][lIndex] = append( m0[iValList][lIndex], value )
				break
				
			case CONCAT:
				m0[iValList][lIndex] &= value
				break
				
		end switch
		return m0
		
	end if
end function

--**
-- Convenience new map.
--
-- See Also:
-- [[:new]]

public constant BLANK_MAP = new()

--**
-- Adds or updates an entry on a map.
--
-- Parameters:
--		# ##m##: the map where an entry is being added or opdated
--		# ##keys##: a sequence of keys for the nested maps
--		# ##value##: an object, the value to add, or to use for updating.
--		# ##operation##: an integer, indicating what is to be done with ##value##. Defaults to PUT.
--		# ##pTrigger##: an integer. Default is 100. See Comments for details.
--
-- Returns:
--   The modified map.
--
-- Comments:
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
--   If existing entry with the same key is already in the map, the value of the entry is updated.
--
-- Example 1:
--   <eucode>
--   map city_population
--   city_population = new()
--   city_population = nested_put(city_population, {"United States", "California", "Los Angeles", 3819951 )
--   city_population = nested_put(city_population, {"Canada",        "Ontario",    "Toronto",     2503281 )
--   </eucode>
--
-- See also:
--  [[:put]]

public function nested_put( map m, sequence keys, object value, integer operation = PUT, integer pTrigger = 100 )
	if length( keys ) = 1 then
		return put( m, keys[1], value, operation, pTrigger )
	else
		return put( m, keys[1], nested_put( get( m, keys[1], BLANK_MAP ), keys[2..$], value, operation, pTrigger ), PUT, pTrigger )
	end if
end function

--**
-- Remove an entry with given key from a map.
--
-- Parameters:
--		# ##m##: the map to operate on
--		# ##key##: an object, the key to remove.
--
-- Returns:
-- The modified **map**.
--
-- Comments:
--   If ##key## is not on ##m##, the ##m## is returned unchanged.
--
-- Example 1:
--   <eucode>
--   map m = new()
--   m = put(m, "Amy", 66.9)
--   m = remove(m, "Amy")
--   -- m is now an empty map again
--   </eucode>
--
-- See Also:
--		[[:put]], [[:has]]
--
public function remove(map m, object key)
	integer hash
	atom lIndex
	object bucket
	sequence m0
	integer lFrom
	

	m0 = m
	if length(m0) = iLargeMap then
		lIndex = calc_hash(key, length(m[iBuckets]))
	
		-- find prev entry
		bucket = m[iBuckets][lIndex]
		hash = find(key, bucket[iKeys])
		if hash != 0 then
			m0[iElemCnt] -= 1
			if length(bucket[iVals]) = 1 then
				m0[iInUse] -= 1
				bucket = {{},{}}
			else
				bucket[iVals] = bucket[iVals][1 .. hash-1] & bucket[iVals][hash+1 .. $]
				bucket[iKeys] = bucket[iKeys][1 .. hash-1] & bucket[iKeys][hash+1 .. $]
			end if
			m0[iBuckets][lIndex] = bucket
			
			if m0[iElemCnt] < floor(51 * vSizeThreshold / 100) then
				m0 = call_func(ri_ConvertToSmall,{m0})
			end if
		end if
	else
		lFrom = 1
		while lFrom > 0 do
			lIndex = find_from(key, m0[iKeyList], lFrom)
			if lIndex then
				if m0[iFreeSpace][lIndex] = 1 then
					m0[iFreeSpace][lIndex] = 0
					m0[iKeyList][lIndex] = vInitSmallKey
					m0[iValList][lIndex] = 0
					m0[iInUse] -= 1
					m0[iElemCnt] -= 1
				end if
			else
				exit
			end if
			lFrom = lIndex + 1
		end while
	end if
	return m0
end function

--****
-- === Retrieving information from a map
--

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
	return m[iElemCnt]
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

public function statistics(map m)
	sequence lStats
	sequence lLengths
	integer lLength

	if length(m) = iLargeMap then
		lStats = {m[iElemCnt], m[iInUse], length(m[iBuckets]), 0, maxInt, 0, 0}
		lLengths = {}
		for i = 1 to length(m[iBuckets]) do
			lLength = length(m[iBuckets][i][iVals])
			if lLength > 0 then
				if lLength > lStats[4] then
					lStats[4] = lLength
				end if
				if lLength < lStats[5] then
					lStats[5] = lLength
				end if
				lLengths &= lLength
			end if
		end for
		lStats[6] = stats:average(lLengths)
		lStats[7] = stdev(lLengths)
	else
		lStats = {m[iElemCnt], m[iInUse], length(m[iBuckets]), length(m[iKeyList]), length(m[iKeyList]), length(m[iKeyList]), 0}
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
--   m = put(m, 10, "ten")
--   m = put(m, 20, "twenty")
--   m = put(m, 30, "thirty")
--   m = put(m, 40, "forty")
--
--   sequence keys
--   keys = keys(m) -- keys might be {20,40,10,30} or some other order
--   </eucode>
-- See Also:
--		[[:has]]
public function keys(map m)
	sequence buckets, bucket
	sequence ret
	integer pos

	ret = repeat(0, m[iElemCnt])
	pos = 1

	if length(m) = iLargeMap then
		buckets = m[iBuckets]
		for index = 1 to length(buckets) do
			bucket = buckets[index]
			if length(bucket[iKeys]) > 0 then
				ret[pos .. pos + length(bucket[iKeys]) - 1] = bucket[iKeys]
				pos += length(bucket[iKeys])
			end if
		end for
	else
		ret = repeat(0, m[iElemCnt])
		pos = 1
		for index = 1 to length(m[iFreeSpace]) do
			if m[iFreeSpace][index] !=  0 then
				ret[pos] = m[iKeyList][index]
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
 --		[[:get]]
public function values(map m)
	sequence buckets, bucket
	sequence ret
	integer pos

	ret = repeat(0, m[iElemCnt])
	pos = 1

	if length(m) = iLargeMap then
		buckets = m[iBuckets]
		for index = 1 to length(buckets) do
			bucket = buckets[index]
			if length(bucket[iVals]) > 0 then
				ret[pos .. pos + length(bucket[iVals]) - 1] = bucket[iVals]
				pos += length(bucket[iVals])
			end if
		end for

	else
		for index = 1 to length(m[iFreeSpace]) do
			if m[iFreeSpace][index] !=  0 then
				ret[pos] = m[iValList][index]
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
	sequence buckets, bucket
	sequence ret
	integer pos

	ret = repeat(0, m[iElemCnt])
	pos = 1
	if length(m) = iLargeMap then
		buckets = m[iBuckets]
		for index = 1 to length(buckets) do
			bucket = buckets[index]
			for j = 1 to length(bucket[iVals]) do
				ret[pos] = {bucket[iKeys][j], bucket[iVals][j]}
				pos += 1
			end for
		end for

	else
		for index = 1 to length(m[iFreeSpace]) do
			if m[iFreeSpace][index] !=  0 then
				ret[pos] = {m[iKeyList][index], m[iValList][index]}
				pos += 1
			end if
		end for
		
	end if
	return ret
end function

--****
-- === Optimisation
--

--**
-- Widens a map to increase performance.
--
-- Parameters:
--		# ##m##: the map being optimised
--		# ##pAvg##: an atom, an estimate of the desired count of nonempty buckets. Default is 10.
--
-- Returns:
--		The optimised **map**.
--
-- See Also:
--		[[:statistics]]
public function optimize(map m, atom pAvg = 10)
	sequence op
	sequence m0

	m0 = m
	if length(m) = iLargeMap then
		op = statistics(m0)
		m0 = rehash(m0, floor(op[1] / pAvg))
		op = statistics(m0)
	
		while op[4] > pAvg * 1.5 and (op[7]*3 + op[6]) <= op[4] do
			m0 = rehash(m, floor(op[3] * 1.333))
			op = statistics(m0)
		end while
	end if
	return m0
end function

--****
-- === Map serialization
--

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
--
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
	sequence m

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
				m = put(m, lKey, lValue)
			end if
		end if
	  entry
		lLine = gets(fh)
	end while

	close(fh)
	return optimize(m)
end function

--**
-- Saves a map to a file.
--
-- Parameters:
--		# ##m##: a map.
--		# ##pFileName##: a sequence, the name of the file to save to.
--
-- Returns:
--		An ##integer##, the number of keys saved to the file.
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

---- Local Functions ------------
function ConvertToLarge(map m)
	sequence m0
	
	if length(m) = iLargeMap then
		return m
	end if
	
	m0 = new()
	for index = 1 to length(m[iFreeSpace]) do
		if m[iFreeSpace][index] !=  0 then
			m0 = put(m0, m[iKeyList][index], m[iValList][index])
		end if
	end for

	return m0
end function
ri_ConvertToLarge = routine_id("ConvertToLarge")

function ConvertToSmall(map m)
	sequence m0
	sequence lKeys
	sequence lVals

	if length(m) = iSmallMap then
		return m
	end if
	
	m0 = new(vSizeThreshold)
	lKeys = keys(m)
	lVals = values(m)
	
	for index = 1 to length(lKeys) do
		m0 = put(m0, lKeys[index], lVals[index])
	end for

	return m0
end function
ri_ConvertToSmall = routine_id("ConvertToSmall")

