-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
-- map.e
-- Euphoria hash map
--
-- yuku 2008
--
-- Euphoria 4.0
-- File System Operations --

--****
-- Category:
--	 map
--
-- File:
--	 lib_map
--
-- Title:
--	 Euphoria Standard Library Map (hash table) Routines
--****


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

--**
-- Signature:
-- global type map
--
-- Description:
-- Defines the datatype 'map'
--
-- Comments:
-- Used when declaring a map variable.
--
-- Example:
-- map SymbolTable
-- SymbolTable = new() -- Create a new map to hold the symbol table.
--**
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
sequence lPrimes
lPrimes = calc_primes(1000)

--**
-- Calculate a Hashing value from the supplied data.
--
-- This is used whenever you need to a single number to represent the data you supply.
-- It can calculate the number based on all the data you give it, which can be
-- an atom or sequence of any value.
--
-- Parameters:
--	 pData = The data for which you want a hash value calculated.
--	 pMaxHash = (default = 0) The returned value will be no larger than this value.
--				However, a value of 0 or lower menas that it can as large as the maximum integer value.
--
-- Example 1:
--	  integer h1
--	  h1 = calc_hash( symbol_name )

global function calc_hash(object pData, integer pMaxHash = 0)
	integer lResult
	integer j
	atom lTemp

	if integer(pData) then
		pData = {pData}
	elsif atom(pData) then
		pData = atom_to_float64(pData)
	end if

	j = 1
	lResult = (length(pData) + 1) * (length(pData) + 1) + pMaxHash
	for i = 1 to length(pData) do
		j -= 1
		if j < 1 then 
			j = length(lPrimes)
		end if

		if sequence(pData[i]) then
			lTemp = lResult + calc_hash(pData[i])

		elsif not integer(pData[i]) then
			lTemp = lResult + calc_hash(atom_to_float64(pData[i]))

		else
			lTemp = lResult +  pData[i] - lPrimes[j]
		end if

		if lTemp > maxInt then
			lResult = remainder(floor(lTemp), maxInt)
		else
			lResult = floor(lTemp)
		end if

	end for
	lResult = and_bits(maxInt, lResult)

	if pMaxHash <= 0 then
		return lResult
	else
		return remainder(lResult, pMaxHash) + 1 -- 1-based
	end if
end function
--**

global function rehash(map m, integer pRequestedSize = 0)
	integer size, index2
	sequence oldBuckets, newBuckets
	object key, value
	atom newsize

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

global function new(integer initSize = 66)
	integer lBuckets
	lBuckets = next_prime(floor((max({1,initSize - 2}) + 3) / 4))

	return {0, 0, repeat({{},{}}, lBuckets ) }
end function

global function has(map m, object key, integer pSimple = 1)
	integer index
	integer lOffset

		index = calc_hash(key, length(m[iBuckets]))

		lOffset = find(key, m[iBuckets][index][iKeys])
		if pSimple != 0 then
			if lOffset != 0 then
				return 1
			else
				return 0
			end if
		else
			return {index, lOffset}
		end if
end function

global function get(map m, object key, object defaultValue, integer pSimple = 1)
	sequence lLocn

	if pSimple != 0 then
		lLocn = has(m, key, 0)
	else
		lLocn = key
	end if
	if lLocn[2] != 0 then
		return m[iBuckets][lLocn[1]][iVals][lLocn[2]]
	else
		return defaultValue
	end if

end function


global function put(map m, object key, object value, integer pTrigger = 100, integer pSimple = 1)
	integer index
	integer lOffset
	object bucket
	atom lAvgLength
	sequence lLocn

	if pSimple != 0 then
		lLocn = has(m, key, 0)
		index = lLocn[1]
		lOffset = lLocn[2]
	else
		index = key[1]
		lOffset = key[2]
	end if

	bucket = m[iBuckets][index]
	if lOffset != 0 then
		bucket[iVals][lOffset] = value
		m[iBuckets][index] = bucket
	else
		m[iCnt] += 1 -- elementCount
		if pTrigger > 0 then
			if m[iCnt] >= length(m[iBuckets]) * pTrigger then
				m = rehash(m)
				index = calc_hash(key, length(m[iBuckets]))
			else
				lAvgLength = (m[iCnt] / max({1,  m[iInUse]}))
				if (lAvgLength >= pTrigger) and (length(bucket[iVals]) >= (lAvgLength * 2)) then
					m = rehash(m)
					index = calc_hash(key, length(m[iBuckets]))
				end if
			end if
		end if
		-- write new entry
		m[iBuckets][index][iKeys] = append(m[iBuckets][index][iKeys], key)
		m[iBuckets][index][iVals] = append(m[iBuckets][index][iVals], value)
		if length(m[iBuckets][index][iVals]) = 1 then
			m[iInUse] += 1
		end if
	end if

	return m
end function

global function remove(map m, object key)
	integer hash, index
	object bucket


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

global function size(map m)
	return m[iCnt]
end function

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


global function optimize(map m, atom pAvg = 10)
	sequence op

	op = statistics(m)
	m = rehash(m, floor(op[1] / pAvg))
	op = statistics(m)

	while op[4] > pAvg * 1.5 and (op[7]*3 + op[6]) <= op[4] do
		m = rehash(m, floor(op[3] * 1.333))
		op = statistics(m)
	end while
	return m
end function

global function load_map(sequence pFileName)
	integer fh
	object lLine
	integer lComment
	integer lDelim
	object lValue
	sequence lKey
	sequence lConvRes
	map m

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

