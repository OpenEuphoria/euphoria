-- map.e
-- Euphoria hash map
-- 
-- yuku 2008

include machine.e

-- [1] = bucket[]
-- bucket = {key, value}[]
-- [2] = elementCount
global type map(object o)
		return sequence(o) and length(o) = 2 and sequence(o[1]) and integer(o[2])
end type

-- return 0 to #00FFFFFF (prevent conversion to atom)
function hashCode(object key)
	integer ret

		if integer(key) then
				if key > #00FFFFFF then
						return and_bits(key, #00FFFFFF)
				else 
						return key
				end if
		elsif atom(key) then
				ret = 0
				key = atom_to_float64(key)
				for i = 1 to 8 do
						ret *= 15
						ret += key[i]
						if ret > #00FFFFFF then
								ret = and_bits(ret, #00FFFFFF)
						end if
				end for
		else
				ret = length(key)
				for i = 1 to length(key) do
						ret *= 15
						ret += hashCode(key[i])
						if ret > #00FFFFFF then
								ret = and_bits(ret, #00FFFFFF)
						end if
				end for
		end if

		return ret
end function

function rehash(map m)
	integer size, index2
	sequence oldBuckets, newBuckets
	object key, value

		-- make bucket size 4 times original. max #1000000)
		size = length(m[1])
		size *= 4
		if size > #1000000 then
				return m -- dont do anything. already too large
		end if
		
		oldBuckets = m[1]
		newBuckets = repeat({}, size)
		
		for index = 1 to length(oldBuckets) do
				for entry_idx = 1 to length(oldBuckets[index]) do
						key = oldBuckets[index][entry_idx][1]
						value = oldBuckets[index][entry_idx][2]
						index2 = and_bits(hashCode(key), size-1) + 1
						newBuckets[index2] &= {{key, value}}
				end for
		end for
		
		m[1] = newBuckets

		return m
end function

global function new()
		return {repeat({}, 16), 0}
end function

global function get(map m, object key, object defaultValue)
	integer hash, index
	object bucket

		hash = hashCode(key)
		index = and_bits(hash, length(m[1])-1) + 1 -- 1-based
		
		-- find prev entry
		bucket = m[1][index]
		for i = 1 to length(bucket) do
				if equal(bucket[i][1], key) then
						return m[1][index][i][2]
				end if
		end for
		
		return defaultValue
end function

global function has(map m, object key)
	integer hash, index
	object bucket

		hash = hashCode(key)
		index = and_bits(hash, length(m[1])-1) + 1 -- 1-based
		
		-- find prev entry
		bucket = m[1][index]
		for i = 1 to length(bucket) do
				if equal(bucket[i][1], key) then
						return 1
				end if
		end for

	return 0
end function

global function put(map m, object key, object value) 
	integer hash, index
	integer found
	object bucket

		hash = hashCode(key)
		index = and_bits(hash, length(m[1])-1) + 1 -- 1-based
		found = 0
		
		-- find prev entry
		bucket = m[1][index]
		for i = 1 to length(bucket) do
				if equal(bucket[i][1], key) then
						-- write updated value
						m[1][index][i][2] = value
						found = 1
						exit
				end if
		end for
		
		if not found then
				m[2] += 1 -- elementCount
				if m[2] > length(m[1]) * 4 then
						m = rehash(m)
						index = and_bits(hash, length(m[1])-1) + 1 -- 1-based
				end if
				
				-- write new entry
				m[1][index] &= {{key, value}}
		end if
				
		return m
end function

global function remove(map m, object key)
	integer hash, index
	object bucket

		hash = hashCode(key)
		index = and_bits(hash, length(m[1])-1) + 1 -- 1-based
		
		-- find prev entry
		bucket = m[1][index]
		for i = 1 to length(bucket) do
				if equal(bucket[i][1], key) then
						m[1][index] = m[1][index][1..i-1] & m[1][index][i+1..$]
						m[2] -= 1
						exit
				end if
		end for
		
		return m
end function

global function size(map m)
		return m[2]
end function

global function keys(map m)
	sequence buckets, bucket
	sequence ret
	integer pos

		ret = repeat(0, m[2])
		pos = 1
		
		buckets = m[1]
		for index = 1 to length(buckets) do
				bucket = buckets[index]
				for entry_idx = 1 to length(bucket) do
						ret[pos] = bucket[entry_idx][1]
						pos += 1
				end for
		end for
		
		return ret
end function

global function values(map m)
	sequence buckets, bucket
	sequence ret
	integer pos

		ret = repeat(0, m[2])
		pos = 1
		
		buckets = m[1]
		for index = 1 to length(buckets) do
				bucket = buckets[index]
				for entry_idx = 1 to length(bucket) do
						ret[pos] = bucket[entry_idx][2]
						pos += 1
				end for
		end for
		
		return ret
end function

