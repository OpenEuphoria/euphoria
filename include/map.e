-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Map (hash table)

include get.e
include primes.e
include machine.e
include math.e
include stats.e as stats
include sequence.e
include search.e

constant iCnt = 1 -- ==> elementCount
constant iInUse = 2 -- ==> count of non-empty buckets
constant iBuckets = 3 -- ==> bucket[] --> bucket = {key[], value[]}
constant iKeys = 1
constant iVals = 2

global enum
	PUT,
	ADD,
	SUBTRACT,
	MULTIPLY,
	DIVIDE,
	APPEND,
	CONCAT

--**
-- Defines the datatype 'map'
--
-- Comments:
-- Used when declaring a map variable.
--
-- Example:
--   <eucode>
--   map SymbolTable
--   SymbolTable = new() -- Create a new map to hold the symbol table.
--   </eucode>

global type map(object o)
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

--**
-- Calculate a Hashing value from the supplied data.
--
-- This is used whenever you need to a single number to represent the data you supply.
-- It can calculate the number based on all the data you give it, which can be
-- an atom or sequence of any value.
--
-- Parameters:
--   * pData = The data for which you want a hash value calculated.
--   * pMaxHash = (default = 0) The returned value will be no larger than this value.
--     However, a value of 0 or lower menas that it can as large as the maximum integer value.
--
-- Example 1:
--   <eucode>
--   integer h1
--   h1 = calc_hash( symbol_name )
--   </eucode>

global function calc_hash(object key, integer pMaxHash = 0)
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
global function rehash(map m1, integer pRequestedSize = 0)
	integer size, index2
	sequence oldBuckets, newBuckets
	object key, value
	atom newsize
	sequence m

	m = m1

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
	m[iInUse] = 0
	for index = 1 to length(oldBuckets) do
		for entry_idx = 1 to length(oldBuckets[index][iKeys]) do
			key = oldBuckets[index][iKeys][entry_idx]
			value = oldBuckets[index][iVals][entry_idx]
			index2 = calc_hash(key, size)
			newBuckets[index2][iKeys] = append(newBuckets[index2][iKeys],key)
			newBuckets[index2][iVals] = append(newBuckets[index2][iVals],value)
			if length(newBuckets[index2][iVals]) = 1 then
				m[iInUse] += 1
			end if
		end for
	end for

	m[iBuckets] = newBuckets

	return m
end function

--**
-- Create a new map data structure
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

global function new(integer initSize = 66)
	integer lBuckets
	lBuckets = next_prime(floor((max({1,initSize - 2}) + 3) / 4))

	return {0, 0, repeat({{},{}}, lBuckets ) }
end function

--**
-- Check if map has a given key.
--
-- Example 1:
--   <eucode>
--   map m
--   m = new()
--   m = put(m, "name", "John")
--   ? has(m, "name") -- 1
--   ? has(m, "age")  -- 0
--   </eucode>

global function has(map m, object key)
	integer lIndex

	lIndex = calc_hash(key, length(m[iBuckets]))
	return (find(key, m[iBuckets][lIndex][iKeys]) != 0)
end function

--**
-- Return the value that corresponds to the object key in the map m. If the key is not in the map, 
-- the object defaultValue is returned instead.
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

global function get(map m, object key, object defaultValue)
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
-- Put an entry on the map m1 with key x1 and value x2. 
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
-- Returns:
--   The modified map.
--
-- Comments:
--   If existing entry with the same key is already in the map, the value of the entry is updated.
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

global function put(map m1, object key, object value, integer pTrigger = 100, integer operation = PUT )
	integer index
	integer hashval
	integer lOffset
	object bucket
	atom lAvgLength
	sequence m
	integer bl
	object old_value
	
	m = m1
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
		m[iBuckets][index] = bucket
		return m
	end if
	if bl = 0 then
		m[iInUse] += 1
	end if

	m[iCnt] += 1 -- elementCount
	if pTrigger > 0 then
		lAvgLength = m[iCnt] / m[iInUse]
		if (lAvgLength >= pTrigger) then
			m = rehash(m)
			index = remainder(hashval, length(m[iBuckets])) + 1
		end if
	end if
	-- write new entry
	m[iBuckets][index][iKeys] = append(m[iBuckets][index][iKeys], key)
	m[iBuckets][index][iVals] = append(m[iBuckets][index][iVals], value)

	return m
end function

--**
-- Remove an entry with given key from the map m1. The modified map is returned.
--
-- Comments:
--   If the map has no entry with the specified key, the original map is returned.
--
-- Example 1:
--   <eucode>
--   map m
--   m = new()
--   m = put(m, "Amy", 66.9)
--   m = remove(m, "Amy")
--   -- m is now an empty map again
--   </eucode>

global function remove(map m1, object key)
	integer hash, index
	object bucket
	sequence m

	m = m1
		index = calc_hash(key, length(m[iBuckets]))

		-- find prev entry
		bucket = m[iBuckets][index]
		hash = find(key, bucket[iKeys])
		if hash != 0 then
			m[iCnt] -= 1
			if length(bucket[iVals]) = 1 then
				m[iInUse] -= 1
				bucket = {{},{}}
			else
				bucket[iVals] = bucket[iVals][1 .. hash-1] & bucket[iVals][hash+1 .. $]
				bucket[iKeys] = bucket[iKeys][1 .. hash-1] & bucket[iKeys][hash+1 .. $]
			end if
			m[iBuckets][index] = bucket
		end if

		return m
end function

--**
-- Return the number of entries in the map m.
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

global function size(map m)
	return m[iCnt]
end function

--**
global function statistics(map m)
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
-- Return all keys in map m as a sequence.
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

global function keys(map m)
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
-- Return all values in map m as a sequence.
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

global function values(map m)
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
global function optimize(map m1, atom pAvg = 10)
	sequence op
	sequence m

	m = m1
	op = statistics(m)
	m = rehash(m, floor(op[1] / pAvg))
	op = statistics(m)

	while op[4] > pAvg * 1.5 and (op[7]*3 + op[6]) <= op[4] do
		m = rehash(m, floor(op[3] * 1.333))
		op = statistics(m)
	end while
	return m
end function

--**
global function load_map(sequence pFileName)
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
				lConvRes = value_from(lValue)
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
