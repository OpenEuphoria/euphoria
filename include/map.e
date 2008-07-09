-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Map (hash table)
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>

include get.e
include primes.e
include machine.e
include math.e
include stats.e as stats
include text.e
include search.e

constant iCnt = 1 -- ==> elementCount
constant iInUse = 2 -- ==> count of non-empty buckets
constant iBuckets = 3 -- ==> bucket[] --> bucket = {key[], value[]}
constant iKeys = 1
constant iVals = 2

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


export enum
	PUT,
	ADD,
	SUBTRACT,
	MULTIPLY,
	DIVIDE,
	APPEND,
	CONCAT

--****
-- === Types
--

--**
-- Defines the datatype 'map'
--
-- Comments:
-- Used when declaring a map variable. A map is also known as a dictionnary. It organises pair {key, value} so as to make lookup faster. The keys and values may be any Euphoria objects. Only one pair with a given key may exist in a given map.
--
-- Example:
--   <eucode>
--   map SymbolTable
--   SymbolTable = new() -- Create a new map to hold the symbol table.
--   </eucode>

export type map(object o)
		if not sequence(o) then
			return 0
		end if
		if length(o) != 3 then
			return 0
		end if
		if not integer(o[1]) then
			return 0
		end if
		if o[1] < 0 then
			return 0
		end if
		if not integer(o[2]) then
			return 0
		end if
		if o[2] < 0 then
			return 0
		end if
		if not sequence(o[3]) then
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

export function calc_hash(object key, integer pMaxHash = 0)
	integer ret
	integer temp

	if integer(key) then	
		ret = key
	else
		if atom(key) then
			key = atom_to_float64(key)
		end if
		ret = length(key)
		for i = length(key) to 1 by -1 do
			temp = ret * 2
			temp *= 2
			temp *= 2
			temp *= 2
			ret = temp - ret			
			if integer(key[i]) then
				ret += key[i]
			elsif atom(key[i]) then
				ret += calc_hash(atom_to_float64(key[i]))
			else
				ret += calc_hash(key[i])
			end if
			ret = and_bits(ret, #03FFFFFF)
		end for
	end if
	
	if ret < 0 then
		ret = -ret
	end if
	
	if pMaxHash <= 0 then
		return ret
	end if

	return remainder(ret, pMaxHash) + 1 -- 1-based

end function

--**
-- Changes the width, i.e. the number of buckets, of a hmap.
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
export function rehash(map m, integer pRequestedSize = 0)
	integer size, index2
	sequence oldBuckets, newBuckets
	object key, value
	atom newsize
	sequence m0

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

--**
-- Create a new map data structure
--
-- Parameters:
--		# ##initSize##: an initial number of buckets for the map.
--
-- Returns:
--		An empty **map**.
--
-- Comments:
--   A new object of type map is created. type_check should be turned off for better performance.
--
-- Example 1:
--   <eucode>
--   map m
--   m = new()
--   -- m is now an empty map (size = 0)
--   </eucode>

export function new(integer initSize = 66)
	integer lBuckets
	lBuckets = next_prime(floor((max({1,initSize - 2}) + 3) / 4))

	return {0, 0, repeat({{},{}}, lBuckets ) }
end function

--**
-- Check whether map has a given key.
--
-- Parameters:
-- 		# ##m##: the map to inspect
--		# ##key##: an object to be looked up
--
-- Returns:
--		An **intger**, 0 if not present, 1 if present.
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
export function has(map m, object key)
	integer lIndex

	lIndex = calc_hash(key, length(m[iBuckets]))
	return (find(key, m[iBuckets][lIndex][iKeys]) != 0)
end function

--**
-- Retrieves the value associated to a key in a map.
--
-- Parameters:
--		# ##m##: the map to inspect
--		# ##key##: an object, the key being looked tp
--		# ##defaultValue##: an object, a default value returned if ##key## not found
--
-- Returnz:
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
--		[[:has]]
export function get(map m, object key, object defaultValue)
	integer lIndex
	integer lOffset

	lIndex = calc_hash(key, length(m[iBuckets]))
	lOffset = find(key, m[iBuckets][lIndex][iKeys])
	if lOffset != 0 then
		return m[iBuckets][lIndex][iVals][lOffset]
	else
		return defaultValue
	end if

end function

--**
-- Returns the value that corresponds to the object ##keys## in the nested map m.  ##keys## is a
-- sequence of keys.  If any key is not in the map, the object defaultValue is returned instead.

export function nested_get( map m, sequence keys, object defaultValue )
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

export function put(map m, object key, object value, integer operation = PUT, integer pTrigger = 100 )
	integer index
	integer hashval
	integer lOffset
	object bucket
	atom lAvgLength
	sequence m0
	integer bl
	object old_value

	m0 = m
	hashval = calc_hash(key, 0)
	index = remainder(hashval, length(m[iBuckets])) + 1
	bucket = m[iBuckets][index]
	bl = length(bucket[iVals])
	lOffset = find(key, bucket[iKeys])

	if lOffset != 0 then
		if operation = PUT then
			bucket[iVals][lOffset] = value
		else
			old_value = bucket[iVals][lOffset]
			switch operation do
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
			end switch
		end if
		m0[iBuckets][index] = bucket
		return m0
	end if
	if bl = 0 then
		m0[iInUse] += 1
	end if

	m0[iCnt] += 1 -- elementCount
	if pTrigger > 0 then
		lAvgLength = m0[iCnt] / m0[iInUse]
		if (lAvgLength >= pTrigger) then
			m0 = rehash(m0)
			index = remainder(hashval, length(m0[iBuckets])) + 1
		end if
	end if
	-- write new entry
	m0[iBuckets][index][iKeys] = append(m0[iBuckets][index][iKeys], key)
	if operation = APPEND then
		-- If appending, then the user wants the value to be an element, not the entire thing
		value = { value }
	end if
	m0[iBuckets][index][iVals] = append(m0[iBuckets][index][iVals], value)
	
	return m0
end function

constant BLANK_MAP = new()
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
-- See also:  [[:put]]
export function nested_put( map m, sequence keys, object value, integer operation = PUT, integer pTrigger = 100 )
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
--		 The modified **map**.
--
-- Comments:
--   If ##key## is not on ##m##, the ##m## is returned unchanged.
--
-- Example 1:
--   <eucode>
--   map m
--   m = new()
--   m = put(m, "Amy", 66.9)
--   m = remove(m, "Amy")
--   -- m is now an empty map again
--   </eucode>
--
-- See Also:
--		[[:put]], [[:has]]
export function remove(map m, object key)
	integer hash, index
	object bucket
	sequence m0

	m0 = m
		index = calc_hash(key, length(m[iBuckets]))

		-- find prev entry
		bucket = m[iBuckets][index]
		hash = find(key, bucket[iKeys])
		if hash != 0 then
			m0[iCnt] -= 1
			if length(bucket[iVals]) = 1 then
				m0[iInUse] -= 1
				bucket = {{},{}}
			else
				bucket[iVals] = bucket[iVals][1 .. hash-1] & bucket[iVals][hash+1 .. $]
				bucket[iKeys] = bucket[iKeys][1 .. hash-1] & bucket[iKeys][hash+1 .. $]
			end if
			m0[iBuckets][index] = bucket
		end if

		return m0
end function

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
export function size(map m)
	return m[iCnt]
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

export function statistics(map m)
	sequence lStats
	sequence lLengths
	integer lLength

	lStats = {m[iCnt], m[iInUse], length(m[iBuckets]), 0, maxInt, 0, 0}
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
--   keys = keys(m) -- keys might be {20,40,10,30} or some other orders
--   </eucode>
-- See Also:
--		[[:has]]
export function keys(map m)
	sequence buckets, bucket
	sequence ret
	integer pos

		ret = repeat(0, m[iCnt])
		pos = 1

		buckets = m[iBuckets]
		for index = 1 to length(buckets) do
			bucket = buckets[index]
			if length(bucket[iKeys]) > 0 then
				ret[pos .. pos + length(bucket[iKeys]) - 1] = bucket[iKeys]
				pos += length(bucket[iKeys])
			end if
		end for

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
--   values = values(m) -- values might be {"twenty","forty","ten","thirty"} or some other orders
--   </eucode>
 -- See Also:
 --		[[:get]]
export function values(map m)
	sequence buckets, bucket
	sequence ret
	integer pos

		ret = repeat(0, m[iCnt])
		pos = 1

		buckets = m[iBuckets]
		for index = 1 to length(buckets) do
			bucket = buckets[index]
			if length(bucket[iVals]) > 0 then
				ret[pos .. pos + length(bucket[iVals]) - 1] = bucket[iVals]
				pos += length(bucket[iVals])
			end if
		end for

		return ret
end function

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
--		{{:statistics]]
export function optimize(map m, atom pAvg = 10)
	sequence op
	sequence m0

	m0 = m
	op = statistics(m0)
	m0 = rehash(m0, floor(op[1] / pAvg))
	op = statistics(m0)

	while op[4] > pAvg * 1.5 and (op[7]*3 + op[6]) <= op[4] do
		m0 = rehash(m, floor(op[3] * 1.333))
		op = statistics(m0)
	end while
	return m0
end function

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
--	Rhe file has one entry per line, each line being of the form <key>=<value>. Whitespace around the key and the value do not count. Comment lines start with "--" and are ignored.
-- See Also:
--		[[:new]]
export function load_map(sequence pFileName)
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

	m = new()
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
				lValue = find_replace("\\-", "-", lValue)
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
