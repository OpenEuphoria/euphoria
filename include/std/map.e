-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--

--****
-- == Map (hash table)
--
-- <<LEVELTOC depth=2>>
--
-- A map is a special array, often called an associative array or dictionary,
-- in which the index to the data can be any Euphoria object and not just
-- an integer. These sort of indexes are also called keys.
-- For example we can code things like this...
-- <eucode>
--    custrec = new() -- Create a new map
--    put(custrec, "Name", "Joe Blow")
--    put(custrec, "Address", "555 High Street")
--    put(custrec, "Phone", 555675632)
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
-- Maps automatically grow to accommodate all the elements placed into it.
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

namespace map

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
include std/serialize.e
include std/datetime.e
include std/io.e

constant type_tag      = 1 -- ==> 'tag' for map type
constant element_count = 2 -- ==> elementCount
constant in_use        = 3 -- ==> count of non-empty buckets
constant map_type      = 4  -- ==> Either SMALLMAP or LARGEMAP
constant key_buckets   = 5 -- ==> bucket[] --> bucket = {key[], value[]}
constant value_buckets = 6 -- ==> bucket[] --> bucket = {key[], value[]}
constant key_list      = 5 -- ==> Small map keys
constant value_list    = 6 -- ==> Small map values
constant free_list     = 7 -- ==> Small map freespace

constant type_is_map   = "Eu:StdMap"

--****
-- Signature:
--   <built-in> function hash(object source, atom algo)
--
-- Description:
--     Calculates a hash value from //key// using the algorithm //algo//
--
-- Parameters:
--		# ##source##: Any Euphoria object
--		# ##algo##: A code indicating which algorithm to use.
-- ** -5 uses Hsieh. Fastest and good dispersion
-- ** -4 uses Fletcher. Very fast and good dispersion
-- ** -3 uses Adler. Very fast and reasonable dispersion, especially for small strings
-- ** -2 uses MD5 (not implemented yet) Slower but very good dispersion. 
-- Suitable for signatures.
-- ** -1 uses SHA256 (not implemented yet) Slow but excellent dispersion. 
-- Suitable for signatures. More secure than MD5.
-- ** 0 and above (integers and decimals) and non-integers less than zero use
--  the cyclic variant (hash = hash * algo + c).
-- This is a fast and good to excellent
-- dispersion depending on the value of //algo//. Decimals give better dispersion but are
-- slightly slower.
--
-- Returns:
--     An **integer**:
--        Except for the MD5 and SHA256 algorithms, this is a 32-bit integer.
--     A **sequence**:
--        MD5 returns a 4-element sequence of integers\\
--        SHA256 returns a 8-element sequence of integers.
--
-- Comments:
-- * For //algo// values from zero to less than 1, that actual value used is (algo + 69096). 
--
-- Example 1:
-- <eucode>
-- x = hash("The quick brown fox jumps over the lazy dog", 0)
-- -- x is 242399616
-- x = hash("The quick brown fox jumps over the lazy dog", 99.94)
-- -- x is 723158
-- x = hash("The quick brown fox jumps over the lazy dog", -99.94)
-- -- x is 4175585990
-- x = hash("The quick brown fox jumps over the lazy dog", -4)
-- -- x is 467406810
-- </eucode>

--****
-- === Hashing Algorithms

public enum
	HSIEH32 = -5,
	FLETCHER32,
	ADLER32,
	MD5,
	SHA256

--****
-- === Operation codes for put

public enum
	PUT,
	ADD,
	SUBTRACT,
	MULTIPLY,
	DIVIDE,
	APPEND,
	CONCAT,
	LEAVE


--****
-- === Types of Maps

public constant SMALLMAP = 's'
public constant LARGEMAP = 'L'

integer threshold_size = 50

-- This is a improbable value used to initialize a small map's keys list. 
constant init_small_map_key = -75960.358941

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

public type map(object obj_p)
-- Must be a valid EuMem pointer.
	if not valid(obj_p, "") then return 0 end if
	
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
	object m_
	
	m_ = ram_space[obj_p]
	if not sequence(m_) then return 0 end if
	if length(m_) < 6 then return 0 end if
	if length(m_) > 7 then return 0 end if
	if not equal(m_[type_tag], type_is_map) then return 0 end if
	if not integer(m_[element_count]) then return 0 end if
	if m_[element_count] < 0 		then return 0 end if
	if not integer(m_[in_use]) then return 0 end if
	if m_[in_use] < 0		then return 0 end if
	if equal(m_[map_type],SMALLMAP) then
		if atom(m_[key_list]) 		then return 0 end if
		if atom(m_[value_list]) 		then return 0 end if
		if atom(m_[free_list]) 		then return 0 end if
		if length(m_[key_list]) = 0  then return 0 end if
		if length(m_[key_list]) != length(m_[value_list]) then return 0 end if
		if length(m_[key_list]) != length(m_[free_list]) then return 0 end if
	elsif  equal(m_[map_type],LARGEMAP) then
		if atom(m_[key_buckets]) 		then return 0 end if
		if atom(m_[value_buckets]) 		then return 0 end if
		if length(m_[key_buckets]) != length(m_[value_buckets])	then return 0 end if
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
--   * max_hash_p = (default = 0) The returned value will be no larger than this value.
--     However, a value of 0 or lower means that it can grow as large as the maximum integer value.
--
-- Returns:
--		An **integer**, the value of which depends only on the supplied data.
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

public function calc_hash(object key_p, integer max_hash_p = 0)
	atom ret_

    ret_ = hash(key_p, -4) --HSIEH32)
	if max_hash_p <= 0 then
		return ret_
	end if

	return remainder(ret_, max_hash_p) + 1 -- 1-based

end function

--**
-- Gets or Sets the threshold value that determines at what point a small map
-- converts into a large map structure. Initially this has been set to 50,
-- meaning that maps up to 50 elements use the //small map// structure.
--
-- Parameters:
-- # new_value_p = If this is greater than zero then it **sets** the threshold
-- value.
--
-- Returns:
-- ##integer## The current value (when ##new_value_p## is less than 1) or the
-- old value prior to setting it to ##new_value_p##.
--
public function threshold(integer new_value_p = 0)

	if new_value_p < 1 then
		return threshold_size
	end if

	integer old_value_ = threshold_size
	threshold_size = new_value_p
	return old_value_
		
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
public function type_of(map the_map_p)
	return ram_space[the_map_p][map_type]
end function
	
--**
-- Changes the width, i.e. the number of buckets, of a map. Only effects
-- //large// maps.
--
-- Parameters:
--   # ##m##: the map to resize
--   # ##requested_bucket_size_p##: a lower limit for the new size.
--
-- Returns:
--		A **map** with the same data in, but more evenly dispatched and hence faster to use.
--
-- Comment:
-- If ##requested_bucket_size_p## is not greater than zero, a new width is automatically derived from the current one.
--
-- See Also:
--		[[:statistics]], [[:optimize]]


public procedure rehash(map the_map_p, integer requested_bucket_size_p = 0)
	integer size_
	integer index_2_
	sequence old_key_buckets_
	sequence old_val_buckets_
	sequence new_key_buckets_
	sequence new_val_buckets_
	object key_
	object value_
	atom new_size_
	sequence temp_map_

	if ram_space[the_map_p][map_type] = SMALLMAP then
		return -- small maps are not hashed.
	end if
	
	if requested_bucket_size_p <= 0 then
		-- grow bucket size_
		new_size_ = floor(length(ram_space[the_map_p][key_buckets]) * 3.5) + 1
		if new_size_ > maxInt then
				return  -- don't do anything. already too large
		end if
		size_ = new_size_
	else
		size_ = requested_bucket_size_p
	end if
	
	size_ = next_prime(size_, 2)	-- Allow up to 2 seconds to calc next prime.
	if size_ < 0 then
		size_ = -size_	-- Failed to just use given size_.
	end if
	old_key_buckets_ = ram_space[the_map_p][key_buckets]
	old_val_buckets_ = ram_space[the_map_p][value_buckets]
	new_key_buckets_ = repeat({}, size_)
	new_val_buckets_ = repeat({}, size_)
	temp_map_ = {type_is_map, 0, 0, LARGEMAP}

	for index = 1 to length(old_key_buckets_) do
		for entry_idx = 1 to length(old_key_buckets_[index]) do
			key_ = old_key_buckets_[index][entry_idx]
			value_ = old_val_buckets_[index][entry_idx]
			index_2_ = calc_hash(key_, size_)
			new_key_buckets_[index_2_] = append(new_key_buckets_[index_2_], key_)
			new_val_buckets_[index_2_] = append(new_val_buckets_[index_2_], value_)
			temp_map_[element_count] += 1
			if length(new_key_buckets_[index_2_]) = 1 then
				temp_map_[in_use] += 1
			end if
		end for
	end for

	temp_map_ = append(temp_map_, new_key_buckets_)
	temp_map_ = append(temp_map_, new_val_buckets_)

	ram_space[the_map_p] = temp_map_
end procedure

--**
-- Create a new map data structure
--
-- Parameters:
--		# ##initial_size_p##: An estimate of how many initial elements will be stored
--   in the map. If this value is less than the [[:threshold]] value, the map
--   will initially be a //small// map otherwise it will be a //large// map.
--
-- Returns:
--		An empty **map**.
--
-- Comments:
--   A new object of type map is created.  The resources allocated for the map will
--   be automatically cleaned up if the reference count of the returned value drops
--  to zero, or if passed in a call to [[:delete]].
--
-- Example 1:
--   <eucode>
--   map m = new()  -- m is now an empty map
--   map x = new(threshold()) -- Forces a small map to be initialized
--   x = new()    -- the resources for the map previously stored in x are released automatically
--   delete( m )  -- the resources for the map are released
--   </eucode>

public function new(integer initial_size_p = 690)
	integer buckets_
	sequence new_map_
	atom temp_map_

	if initial_size_p < 3 then
		initial_size_p = 3
	end if
	if initial_size_p > threshold_size then
		-- Return a large map
		buckets_ = floor(initial_size_p / 30)
		if buckets_ < 23 then
			buckets_ = 23
		else
			buckets_ = next_prime(buckets_)
		end if
		
		
		new_map_ = {type_is_map, 0, 0, LARGEMAP, repeat({}, buckets_), repeat({}, buckets_)}
	else
		-- Return a small map
		new_map_ =  {type_is_map, 0,0, SMALLMAP, repeat(init_small_map_key, initial_size_p), repeat(0, initial_size_p), repeat(0, initial_size_p)}
	end if
	temp_map_ = malloc()
	ram_space[temp_map_] = new_map_
	
	return temp_map_
end function

--**
-- Returns either the supplied map or a new map.
--
-- Parameters:
--      # ##the_map_p##: An object, that could be an existing map
--		# ##initial_size_p##: An estimate of how many initial elements will be stored
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

public function new_extra(object the_map_p, integer initial_size_p = 690)
	if map(the_map_p) then
		return the_map_p
	else
		return new(initial_size_p)
	end if
end function


--**
-- Compares two maps to test equality.
--
-- Parameters:
--		# ##map_1_p##: A map
--		# ##map_2_p##: A map
--      # ##scope_p##: An integer that specifies what to compare.
--        ** 'k' or 'K' to only compare keys.
--        ** 'v' or 'V' to only compare values.
--        ** 'd' or 'D' to compare both keys and values. This is the default.
--
-- Returns:
--   An integer...
--   * -1 if they are not equal.
--   * 0 if they are literally the same map.
--   * 1 if they contain the same keys and/or values.
--
-- Example 1:
--   <eucode>
--   map map_1_p = foo()
--   map map_2_p = bar()
--   if compare(map_1_p, map_2_p, 'k') >= 0 then
--        ... -- two maps have the same keys
--   </eucode>

public function compare(map map_1_p, map map_2_p, integer scope_p = 'd')
	sequence data_set_1_
	sequence data_set_2_

	if map_1_p = map_2_p then
		return 0
	end if
	
	switch scope_p with fallthru do
		case 'v' then
		case 'V' then
			data_set_1_ = sort(values(map_1_p))
			data_set_2_ = sort(values(map_2_p))
			break
			
		case 'k' then
		case 'K' then
			data_set_1_ = sort(keys(map_1_p))
			data_set_2_ = sort(keys(map_2_p))
			break
			
		case else
			data_set_1_ = sort(pairs(map_1_p))
			data_set_2_ = sort(pairs(map_2_p))

	end switch
				
	if equal(data_set_1_, data_set_2_) then
		return 1
	end if
	
	return -1
	
end function

--**
-- Check whether map has a given key.
--
-- Parameters:
-- 		# ##the_map_p##: the map to inspect
--		# ##the_key_p##: an object to be looked up
--
-- Returns:
--		An **integer**, 0 if not present, 1 if present.
--
-- Example 1:
--   <eucode>
--   map the_map_p
--   the_map_p = new()
--   put(the_map_p, "name", "John")
--   ? has(the_map_p, "name") -- 1
--   ? has(the_map_p, "age")  -- 0
--   </eucode>
--See Also:
-- 		[[:get]]
public function has(map the_map_p, object the_key_p)
	integer index_
	integer pos_
	
	if ram_space[the_map_p][map_type] = LARGEMAP then
		index_ = calc_hash(the_key_p, length(ram_space[the_map_p][key_buckets]))
		pos_ = find(the_key_p, ram_space[the_map_p][key_buckets][index_])
	else
		pos_ = find(the_key_p, ram_space[the_map_p][key_list])
	end if
	return (pos_  != 0)
	
end function

--**
-- Retrieves the value associated to a key in a map.
--
-- Parameters:
--		# ##the_map_p##: the map to inspect
--		# ##the_key_p##: an object, the the_key_p being looked tp
--		# ##default_value_p##: an object, a default value returned if ##the_key_p## not found.
--                         The default is 0.
--
-- Returns:
--		An **object**, the value that corresponds to ##the_key_p## in ##the_map_p##. 
--      If ##the_key_p## is not in ##the_map_p##, ##default_value_p## is returned instead.
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

public function get(map the_map_p, object the_key_p, object default_value_p = 0)
	integer bucket_
	integer pos_
	integer from_
	
	if ram_space[the_map_p][map_type] = LARGEMAP then
		bucket_ = calc_hash(the_key_p, length(ram_space[the_map_p][key_buckets]))
		pos_ = find(the_key_p, ram_space[the_map_p][key_buckets][bucket_])
		if pos_ > 0 then
			return ram_space[the_map_p][value_buckets][bucket_][pos_]
		end if
		return default_value_p
	else
		if equal(the_key_p, init_small_map_key) then
			from_ = 1
			while from_ > 0 do
				pos_ = find_from(the_key_p, ram_space[the_map_p][key_list], from_)
				if pos_ then
					if ram_space[the_map_p][free_list][pos_] = 1 then
						return ram_space[the_map_p][value_list][pos_]
					end if
				else
					return default_value_p
				end if
				from_ = pos_ + 1
			end while
		else
			pos_ = find(the_key_p, ram_space[the_map_p][key_list])
			if pos_  then
				return ram_space[the_map_p][value_list][pos_]
			end if
		end if
	end if
	return default_value_p
end function

--**
-- Returns the value that corresponds to the object ##the_keys_p## in the nested map the_map_p.  ##the_keys_p## is a
-- sequence of keys.  If any key is not in the map, the object default_value_p is returned instead.
public function nested_get( map the_map_p, sequence the_keys_p, object default_value_p = 0)
	for i = 1 to length( the_keys_p ) - 1 do
		object val_ = get( the_map_p, the_keys_p[1], 0 )

		if not map( val_ ) then
			-- not a map
			return default_value_p
		else
			the_map_p = val_
			the_keys_p = the_keys_p[2..$]
		end if
	end for
	return get( the_map_p, the_keys_p[1], default_value_p )
end function

--**
-- Adds or updates an entry on a map.
--
-- Parameters:
--		# ##the_map_p##: the map where an entry is being added or updated
--		# ##the_key_p##: an object, the the_key_p to look up
--		# ##the_value_p##: an object, the value to add, or to use for updating.
--		# ##operation##: an integer, indicating what is to be done with ##the_value_p##. Defaults to PUT.
--		# ##trigger_p##: an integer. Default is 100. See Comments for details.
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
-- ** ##LEAVE##: If it already exists, the current value is left unchanged
--               otherwise the new value is added to the map.
--
-- * The //trigger// parameter is used when you need to keep the average 
--     number of keys in a hash bucket to a specific maximum. The //trigger// 
--     value is the maximum allowed. Each time a //put// operation increases
--     the hash table's average bucket size to be more than the //trigger// value
--     the table is expanded by a factor 3.5 and the keys are rehashed into the
--     enlarged table. This can be a time intensive action so set the value
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

public procedure put(map the_map_p, object the_key_p, object the_value_p, integer operation_p = PUT, integer trigger_p = 100 )
	integer index_
	integer bucket_
	atom average_length_
	integer from_
	
	if ram_space[the_map_p][map_type] = LARGEMAP then
		bucket_ = calc_hash(the_key_p,  length(ram_space[the_map_p][key_buckets]))
		index_ = find(the_key_p, ram_space[the_map_p][key_buckets][bucket_])
		if index_ > 0 then
			-- The the_value_p already exists.
			switch operation_p do
				case PUT then
					ram_space[the_map_p][value_buckets][bucket_][index_] = the_value_p
					
				case ADD then
					ram_space[the_map_p][value_buckets][bucket_][index_] += the_value_p
					
				case SUBTRACT then
					ram_space[the_map_p][value_buckets][bucket_][index_] -= the_value_p
					
				case MULTIPLY then
					ram_space[the_map_p][value_buckets][bucket_][index_] *= the_value_p
					
				case DIVIDE then
					ram_space[the_map_p][value_buckets][bucket_][index_] /= the_value_p
					
				case APPEND then
					ram_space[the_map_p][value_buckets][bucket_][index_] = append( ram_space[the_map_p][value_buckets][bucket_][index_], the_value_p )
					
				case CONCAT then
					ram_space[the_map_p][value_buckets][bucket_][index_] &= the_value_p
					
				case LEAVE then
					-- Do nothing
					
				case else
					crash("Unknown operation given to map.e:put()")
					
			end switch
			return
		end if

		
		ram_space[the_map_p][in_use] += (length(ram_space[the_map_p][key_buckets][bucket_]) = 0)
		ram_space[the_map_p][element_count] += 1 -- elementCount
		
		
		-- write new entry
		if operation_p = APPEND then
			-- If appending, then the user wants the the_value_p to be an element, not the entire thing
			the_value_p = { the_value_p }
		end if


		ram_space[the_map_p][key_buckets][bucket_] = append(ram_space[the_map_p][key_buckets][bucket_], the_key_p)
		ram_space[the_map_p][value_buckets][bucket_] = append(ram_space[the_map_p][value_buckets][bucket_], the_value_p)
				
		if trigger_p > 0 then
			average_length_ = ram_space[the_map_p][element_count] / ram_space[the_map_p][in_use]
			if (average_length_ >= trigger_p) then
				rehash(the_map_p)
			end if
		end if
		
		return
	else -- Small Map
		if equal(the_key_p, init_small_map_key) then
			from_ = 1
			while index_ > 0 with entry do
				if ram_space[the_map_p][free_list][index_] = 0 then
					exit
				end if
				from_ = index_ + 1
			  entry
				index_ = find_from(the_key_p, ram_space[the_map_p][key_list], from_)
			end while
		else
			index_ = find(the_key_p, ram_space[the_map_p][key_list])
		end if
		
		-- Did we find it?
		if index_ = 0 then
			-- No, so add it.
			index_ = find(0, ram_space[the_map_p][free_list])
			if index_ = 0 then
				-- No room left, so now it becomes a large map.
				convert_to_large_map(the_map_p)
				put(the_map_p, the_key_p, the_value_p, operation_p, trigger_p)
				return
			else
				ram_space[the_map_p][key_list][index_] = the_key_p
				ram_space[the_map_p][value_list][index_] = the_value_p
				ram_space[the_map_p][free_list][index_] = 1
				ram_space[the_map_p][in_use] += 1
				ram_space[the_map_p][element_count] += 1
				return
			end if
		end if
		
		switch operation_p do
			case PUT then
				ram_space[the_map_p][value_list][index_] = the_value_p
				
			case ADD then
				ram_space[the_map_p][value_list][index_] += the_value_p
				
			case SUBTRACT then
				ram_space[the_map_p][value_list][index_] -= the_value_p
				
			case MULTIPLY then
				ram_space[the_map_p][value_list][index_] *= the_value_p
				
			case DIVIDE then
				ram_space[the_map_p][value_list][index_] /= the_value_p
				
			case APPEND then
				ram_space[the_map_p][value_list][index_] = append( ram_space[the_map_p][value_list][index_], the_value_p )
				
			case CONCAT then
				ram_space[the_map_p][value_list][index_] &= the_value_p
				
			case else
				crash("Unknown operation given to map.e:put()")
				
		end switch
		return
		
	end if
end procedure


--**
-- Adds or updates an entry on a map.
--
-- Parameters:
--		# ##the_map_p##: the map where an entry is being added or updated
--		# ##the_keys_p##: a sequence of keys for the nested maps
--		# ##the_value_p##: an object, the value to add, or to use for updating.
--		# ##operation_p##: an integer, indicating what is to be done with ##value##. Defaults to PUT.
--		# ##trigger_p##: an integer. Default is 51. See Comments for details.
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
--     enlarged table. This can be a time intensive action so set the value
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
--   nested_put(city_population, {"United States", "California", "Los Angeles"}, 3819951 )
--   nested_put(city_population, {"Canada",        "Ontario",    "Toronto"},     2503281 )
--   </eucode>
--
-- See also:  [[:put]]
public procedure nested_put( map the_map_p, sequence the_keys_p, object the_value_p, integer operation_p = PUT, integer trigger_p = 51 )
	atom temp_map_

	if length( the_keys_p ) = 1 then
		put( the_map_p, the_keys_p[1], the_value_p, operation_p, trigger_p )
		return
	else
		temp_map_ = new_extra( get( the_map_p, the_keys_p[1] ) )
		nested_put( temp_map_, the_keys_p[2..$], the_value_p, operation_p, trigger_p )
		put( the_map_p, the_keys_p[1], temp_map_, PUT, trigger_p )
		return
	end if
end procedure

--**
-- Remove an entry with given key from a map.
--
-- Parameters:
--		# ##the_map_p##: the map to operate on
--		# ##key##: an object, the key to remove.
--
-- Returns:
--		 The modified **map**.
--
-- Comments:
--   * If ##key## is not on ##the_map_p##, the ##the_map_p## is returned unchanged.
--   * If you need to remove all entries, see [[:clear]]
--
-- Example 1:
--   <eucode>
--   map the_map_p
--   the_map_p = new()
--   put(the_map_p, "Amy", 66.9)
--   remove(the_map_p, "Amy")
--   -- the_map_p is now an empty map again
--   </eucode>
--
-- See Also:
--		[[:clear]], [[:has]]

public procedure remove(map the_map_p, object the_key_p)
	integer index_
	integer bucket_
	sequence temp_map_
	integer from_
	

	temp_map_ = ram_space[the_map_p]
	if temp_map_[map_type] = LARGEMAP then
		bucket_ = calc_hash(the_key_p, length(temp_map_[key_buckets]))
	
		index_ = find(the_key_p, temp_map_[key_buckets][bucket_])
		if index_ != 0 then
			temp_map_[element_count] -= 1
			if length(temp_map_[key_buckets][bucket_]) = 1 then
				temp_map_[in_use] -= 1
				temp_map_[key_buckets][bucket_] = {}
				temp_map_[value_buckets][bucket_] = {}
			else
				temp_map_[value_buckets][bucket_] = temp_map_[value_buckets][bucket_][1 .. index_-1] & temp_map_[value_buckets][bucket_][index_+1 .. $]
				temp_map_[key_buckets][bucket_] = temp_map_[key_buckets][bucket_][1 .. index_-1] & temp_map_[key_buckets][bucket_][index_+1 .. $]
			end if
			
			if temp_map_[element_count] < floor(51 * threshold_size / 100) then
				ram_space[the_map_p] = temp_map_
				convert_to_small_map(the_map_p)
				return
			end if
		end if
	else
		from_ = 1
		while from_ > 0 do
			index_ = find_from(the_key_p, temp_map_[key_list], from_)
			if index_ then
				if temp_map_[free_list][index_] = 1 then
					temp_map_[free_list][index_] = 0
					temp_map_[key_list][index_] = init_small_map_key
					temp_map_[value_list][index_] = 0
					temp_map_[in_use] -= 1
					temp_map_[element_count] -= 1
				end if
			else
				exit
			end if
			from_ = index_ + 1
		end while
	end if
	ram_space[the_map_p] = temp_map_
	return
end procedure

--**
-- Remove all entries in a map.
--
-- Parameters:
--		# ##the_map_p##: the map to operate on
--
-- Comments:
--   * This is much faster than removing each entry individually.
--   * If you need to remove just one entry, see [[:remove]]
--
-- Example 1:
--   <eucode>
--   map the_map_p
--   the_map_p = new()
--   put(the_map_p, "Amy", 66.9)
--   put(the_map_p, "Betty", 67.8)
--   put(the_map_p, "Claire", 64.1)
--   ...
--   clear(the_map_p)
--   -- the_map_p is now an empty map again
--   </eucode>
--
-- See Also:
--		[[:remove]], [[:has]]

public procedure clear(map the_map_p)
	sequence temp_map_

	temp_map_ = ram_space[the_map_p]
	if temp_map_[map_type] = LARGEMAP then
		temp_map_[element_count] = 0
		temp_map_[in_use] = 0
		temp_map_[key_buckets] = repeat({}, length(temp_map_[key_buckets]))
		temp_map_[value_buckets] = repeat({}, length(temp_map_[value_buckets]))
	else
		temp_map_[element_count] = 0
		temp_map_[in_use] = 0
		temp_map_[key_list] = repeat(0, length(temp_map_[key_list]))
		temp_map_[value_list] = repeat(0, length(temp_map_[value_list]))
		temp_map_[free_list] = repeat(0, length(temp_map_[free_list]))
	end if
	ram_space[the_map_p] = temp_map_
	return
end procedure

--**
-- Return the number of entries in a map.
--
-- Parameters:
--		##the_map_p##: the map being queried
--
-- Returns:
--		An **integer**, the number of entries it has.
--
-- Comments:
--   For an empty map, size will be zero
--
-- Example 1:
--   <eucode>
--   map the_map_p
--   put(the_map_p, 1, "a")
--   put(the_map_p, 2, "b")
--   ? size(the_map_p) -- outputs 2
--   </eucode>
--
-- See Also:
--		[[:statistics]]
public function size(map the_map_p)
	return ram_space[the_map_p][element_count]
end function

--**
-- Retrieves characteristics of a map.
--
-- Parameters:
-- 		# ##the_map_p##: the map being queried
--
-- Returns:
--		A  **sequence** of 7 integers:
-- * NUM_ENTRIES: number of entries
-- * NUM_IN_USE: number of buckets in use
-- * NUM_BUCKETS: number of buckets
-- * LARGEST_BUCKET: size of largest bucket
-- * SMALLEST_BUCKET: size of smallest bucket
-- * AVERAGE_BUCKET: average size for a bucket
-- * STDEV_BUCKET: standard deviation for the bucket length series
--
-- Example 1:
--   <eucode>
--   sequence s = statistics(mymap)
--   printf(1, "The average size of the buckets is %d", s[AVERAGE_BUCKET])
--   </eucode>
--

public enum
	NUM_ENTRIES,
	NUM_IN_USE,
	NUM_BUCKETS,
	LARGEST_BUCKET,
	SMALLEST_BUCKET,
	AVERAGE_BUCKET,
	STDEV_BUCKET

public function statistics(map the_map_p)
	sequence statistic_set_
	sequence lengths_
	integer length_
	sequence temp_map_
	
	temp_map_ = ram_space[the_map_p]

	if temp_map_[map_type] = LARGEMAP then
		statistic_set_ = {temp_map_[element_count], temp_map_[in_use], length(temp_map_[key_buckets]), 0, maxInt, 0, 0}
		lengths_ = {}
		for i = 1 to length(temp_map_[key_buckets]) do
			length_ = length(temp_map_[key_buckets][i])
			if length_ > 0 then
				if length_ > statistic_set_[LARGEST_BUCKET] then
					statistic_set_[LARGEST_BUCKET] = length_
				end if
				if length_ < statistic_set_[SMALLEST_BUCKET] then
					statistic_set_[SMALLEST_BUCKET] = length_
				end if
				lengths_ &= length_
			end if
		end for
		statistic_set_[AVERAGE_BUCKET] = stats:average(lengths_)
		statistic_set_[STDEV_BUCKET] = stats:stdev(lengths_)
	else
		statistic_set_ = {temp_map_[element_count], temp_map_[in_use], length(temp_map_[key_list]), length(temp_map_[key_list]), length(temp_map_[key_list]), length(temp_map_[key_list]), 0}
	end if
	return statistic_set_
end function

--**
-- Return all keys in a map.
--
-- Parameters;
--		# ##the_map_p##: the map being queried
--
-- Returns:
-- 		A **sequence** made of all the keys in the map.
--
-- Comments:
--   The order of the keys returned may not be the same as the putting order.
--
-- Example 1:
--   <eucode>
--   map the_map_p
--   the_map_p = new()
--   put(the_map_p, 10, "ten")
--   put(the_map_p, 20, "twenty")
--   put(the_map_p, 30, "thirty")
--   put(the_map_p, 40, "forty")
--
--   sequence keys
--   keys = keys(the_map_p) -- keys might be {20,40,10,30} or some other order
--   </eucode>
-- See Also:
--		[[:has]], [[:values]], [[:pairs]]
public function keys(map the_map_p)
	sequence buckets_
	sequence current_bucket_
	sequence results_
	integer pos_
	sequence temp_map_
	
	temp_map_ = ram_space[the_map_p]

	results_ = repeat(0, temp_map_[element_count])
	pos_ = 1

	if temp_map_[map_type] = LARGEMAP then
		buckets_ = temp_map_[key_buckets]
		for index = 1 to length(buckets_) do
			current_bucket_ = buckets_[index]
			if length(current_bucket_) > 0 then
				results_[pos_ .. pos_ + length(current_bucket_) - 1] = current_bucket_
				pos_ += length(current_bucket_)
			end if
		end for
	else
		for index = 1 to length(temp_map_[free_list]) do
			if temp_map_[free_list][index] !=  0 then
				results_[pos_] = temp_map_[key_list][index]
				pos_ += 1
			end if
		end for
		
	end if
	return results_
end function

--**
-- Return all values in a map.
--
-- Parameters:
--   # ##the_map##: the map being queried
--   # ##keys##: optional key list of values to return
--   # ##default_values##: optional default values for keys list
--
-- Returns:
--   A **sequence** of all values stored in ##the_map##.
--
-- Comments:
--   The order of the values returned may not be the same as the putting order. 
--   Duplicate values are not removed.
--
--   If specifying keys, then the return order is that of the keys sequence. If
--   no default values are given and one is needed, 0 will be used.
--
-- Example 1:
--   <eucode>
--   map the_map_p
--   the_map_p = new()
--   put(the_map_p, 10, "ten")
--   put(the_map_p, 20, "twenty")
--   put(the_map_p, 30, "thirty")
--   put(the_map_p, 40, "forty")
--
--   sequence values
--   values = values(the_map_p)
--   -- values might be {"twenty","forty","ten","thirty"}
--   -- or some other order
--   </eucode>
--
-- Example 2:
--   <eucode>
--   map the_map_p
--   the_map_p = new()
--   put(the_map_p, 10, "ten")
--   put(the_map_p, 20, "twenty")
--   put(the_map_p, 30, "thirty")
--   put(the_map_p, 40, "forty")
--
--   sequence values
--   values = values(the_map_p, { 10, 30, 9000 })
--   -- values WILL be { "ten", "thirty", 0 }
--   </eucode>
--
-- See Also:
--   [[:get]], [[:keys]], [[:pairs]]

public function values(map the_map, object keys=0, object default_values=0)
	if sequence(keys) then
		if not sequence(default_values) then
			default_values = repeat(0, length(keys))
		end if

		for i = 1 to length(keys) do
			keys[i] = get(the_map, keys[i], default_values[i])
		end for

		return keys
	end if

	sequence buckets_
	sequence bucket_
	sequence results_
	integer pos_
	sequence temp_map_
	
	temp_map_ = ram_space[the_map]

	results_ = repeat(0, temp_map_[element_count])
	pos_ = 1

	if temp_map_[map_type] = LARGEMAP then
		buckets_ = temp_map_[value_buckets]
		for index = 1 to length(buckets_) do
			bucket_ = buckets_[index]
			if length(bucket_) > 0 then
				results_[pos_ .. pos_ + length(bucket_) - 1] = bucket_
				pos_ += length(bucket_)
			end if
		end for
	else
		for index = 1 to length(temp_map_[free_list]) do
			if temp_map_[free_list][index] !=  0 then
				results_[pos_] = temp_map_[value_list][index]
				pos_ += 1
			end if
		end for
		
	end if

	return results_
end function

--**
--
-- Return all key/value pairs in a map.
--
-- Parameters:
--		# ##the_map_p##: the map being queried
--
-- Returns:
--		A **sequence** of all key/value pairs stored in ##the_map_p##. Each pair is a 
-- sub-sequence in the form {key, value}
--
-- Comments:
--   The order of the values returned may not be the same as the putting order. 
--
-- Example 1:
--   <eucode>
--   map the_map_p
--   the_map_p = new()
--   put(the_map_p, 10, "ten")
--   put(the_map_p, 20, "twenty")
--   put(the_map_p, 30, "thirty")
--   put(the_map_p, 40, "forty")
--
--   sequence keyvals
--   keyvals = pairs(the_map_p) -- might be {{20,"twenty"},{40,"forty"},{10,"ten"},{30,"thirty"}}
--   </eucode>
 -- See Also:
 --		[[:get]], [[:keys]], [[:values]]
public function pairs(map the_map_p)
	sequence key_bucket_
	sequence value_bucket_
	sequence results_
	integer pos_
	sequence temp_map_
	
	temp_map_ = ram_space[the_map_p]

	results_ = repeat({0,0}, temp_map_[element_count])
	pos_ = 1

	if temp_map_[map_type] = LARGEMAP then
		for index = 1 to length(temp_map_[key_buckets]) do
			key_bucket_ = temp_map_[key_buckets][index]
			value_bucket_ = temp_map_[value_buckets][index]
			for j = 1 to length(key_bucket_) do
				results_[pos_][1] = key_bucket_[j]
				results_[pos_][2] = value_bucket_[j]
				pos_ += 1
			end for
		end for
	else
		for index = 1 to length(temp_map_[free_list]) do
			if temp_map_[free_list][index] !=  0 then
				results_[pos_][1] = temp_map_[key_list][index]
				results_[pos_][2] = temp_map_[value_list][index]
				pos_ += 1
			end if
		end for
		
	end if
	return results_
end function

--**
-- Widens a map to increase performance.
--
-- Parameters:
--		# ##the_map_p##: the map being optimized
--		# ##max_p##: an integer, the maximum desired size of a bucket. Default is 25.
--                  This must be 3 or higher.
--      # ##grow_p##: an atom, the factor to grow the number of buckets for each
--                   iteration of rehashing. Default is 1.333. This must be 
--                   greater than 1.
--
-- Returns:
--		The optimized **map**.
--
-- Comments:
--      This rehashes the map until either the maximum bucket size is less than
--      the desired maximum or the maximum bucket size is less than the largest
--      size statistically expected (mean + 3 standard deviations).
--
-- See Also:
--		[[:statistics]], [[:rehash]]
public procedure optimize(map the_map_p, integer max_p = 25, atom grow_p = 1.333)
	sequence stats_
	integer next_guess_
	
	if ram_space[the_map_p][map_type] = LARGEMAP then
		if grow_p < 1 then
			grow_p = 1.333
		end if
		if max_p < 3 then
			max_p = 3
		end if
		
		next_guess_ = max({1, floor(ram_space[the_map_p][element_count] / max_p)})
		while 1 with entry do
		
			if stats_[LARGEST_BUCKET] <= max_p then
				exit -- Largest is now smaller than the maximum I wanted.
			end if
			
			if stats_[LARGEST_BUCKET] <= (stats_[STDEV_BUCKET]*3 + stats_[AVERAGE_BUCKET]) then
				exit -- Largest is smaller than is statistically expected.
			end if
			
			next_guess_ = floor(stats_[NUM_BUCKETS] * grow_p)
			
		  entry
			rehash(the_map_p, next_guess_)
			stats_ = statistics(the_map_p)
		end while
	end if
	return
end procedure

--**
-- Loads a map from a file
--
-- Parameters:
--		# ##file_name_p##: The file to load from. This file may have been created
--                          by the [[:save_map]] function. This can either be a
--                          name of a file or an already opened file handle.
--
-- Returns:
--		Either a **map** with all the entries found in ##file_name_p##, or **-1**
--      if the file failed to open.
--
-- Comments:
-- If ##file_name_p## is an already opened file handle, this routine will write
-- to that file and not close it. Otherwise, the named file will be created and
-- closed by this routine.
--
-- The input file can be either one created by the [[:save_map]] function or
-- a manually created/edited text file. See [[:save_map]] for details about
-- the required layout of the text file.
--
--
-- Example 1:
-- <eucode>
--    object loaded
--    map AppOptions
--    sequence SavedMap = "c:\myapp\options.txt"
--    loaded = load_map(SavedMap)
--    if equal(loaded, -1) then
--       crash("Map '%s' failed to open", SavedMap)
--    end if
--    -- By now we know that it was loaded and a new map created,
--    -- so we can assign it to a 'map' variable.
--    AppOptions = loaded
--    if get(AppOptions, "verbose", 1) = 3 then
--        ShowIntructions()
--    end if
-- </eucode>
-- See Also:
--		[[:new]], [[:save_map]]
public function load_map(object file_name_p)
	integer file_handle_
	object line_
	integer comment_
	integer delim_
	object value_
	object key_
	sequence conv_res_
	atom new_map_

	if sequence(file_name_p) then
		file_handle_ = open(file_name_p, "rb")
	else
		file_handle_ = file_name_p
	end if
	if file_handle_ = -1 then
		return 0
	end if
	
	new_map_ = new(threshold_size) -- Assume a small map initially.

	-- Look for a non-printable byte in the first 10 bytes. If none are found then this is a text-formated
	-- file otherwise it is a 'raw' saved file.
	
	for i = 1 to 10 do
		delim_ = getc(file_handle_)
		if delim_ = -1 then 
			exit
		end if
	    if not t_print(delim_) then 
	    	exit
	    end if
	    delim_ = -1
	end for
	
	if delim_ = -1 then
	-- A text format file
		close(file_handle_)
		file_handle_ = open(file_name_p, "r")
		while sequence(line_) with entry do
			comment_ = rmatch("--", line_)
			if comment_ != 0 then
				line_ = trim(line_[1..comment_-1])
			end if
			delim_ = find('=', line_)
			if delim_ > 0 then
				key_ = trim(line_[1..delim_-1])
				if length(key_) > 0 then
					key_ = find_replace("\\-", key_, "-")
					if not t_alpha(key_[1]) then
						conv_res_ = value(key_,,GET_LONG_ANSWER)
						if conv_res_[1] = GET_SUCCESS then
							if conv_res_[3] = length(key_) then
								key_ = conv_res_[2]
							end if
						end if
					end if
									
					value_ = trim(line_[delim_+1..$])
					value_ = find_replace("\\-", value_, "-")
					conv_res_ = value(value_,,GET_LONG_ANSWER)
					if conv_res_[1] = GET_SUCCESS then
						if conv_res_[3] = length(value_) then
							value_ = conv_res_[2]
						end if
					end if
					put(new_map_, key_, value_)
				end if
			end if
		  entry
			line_ = gets(file_handle_)
		end while
	else
		object _ = seek(file_handle_, 0)
		line_  = deserialize(file_handle_)
		if line_[1] = 1 then
			-- Saved Map Format version 1
			key_   = deserialize(file_handle_)
			value_ =  deserialize(file_handle_)
			
			for i = 1 to length(key_) do
				put(new_map_, key_[i], value_[i])
			end for
		end if
	end if
	if sequence(file_name_p) then
		close(file_handle_)
	end if
	optimize(new_map_)
	return new_map_
end function

--**
-- Saves a map to a file.
--
-- Parameters:
--		# ##m##: a map.
--		# ##file_name_p##: Either a sequence, the name of the file to save to,
--                         or an open file handle as returned by [[:open]]().
--		# ##type##: an integer. SM_TEXT for a human-readable format (default),
--                SM_RAW for a smaller and faster format, but not human-readable.
--
-- Returns:
--		##integer## = The number of keys saved to the file, or -1 if the
--                    save failed.
--
-- Comments:
-- If ##file_name_p## is an already opened file handle, this routine will write
-- to that file and not close it. Otherwise, the named file will be created and
-- closed by this routine.
--
-- The SM_TEXT type saves the map keys and values in a text format which can
-- be read and edited by standard text editor. Each entry in the map is saved as
-- a KEY/VALUE pair in the form \\
-- {{{
-- key = value
-- }}}
-- Note that if the 'key' value is a normal string value, it can be enclosed in
-- double quotes. If it is not thus quoted, the first character of the key
-- determines its Euphoria value type. A dash or digit implies an atom, an left-brace
-- implies a sequence, an alphabetic character implies a text string that extends to the
-- next equal '=' symbol, and anything else is ignored. 
--
-- Note that if a line contains a double-dash, then all text from the double-dash
-- to the end of the line will be ignored. This is so you can optionally add
-- comments to the saved map. Also, any blank lines are ignored too.
--
-- All text after the '=' symbol is assumed to be the map item's value data.
--
-- The SM_RAW type saves the map in an efficient manner. It is generally smaller
-- than the text format and is faster to process, but it is not human readable and
-- standard text editors can not be used to edit it. In this format, the file will
-- contain three serialized sequences:
-- # Header sequence: {integer:format version, string: date and time of save (YYMMDDhhmmss),
--                     sequence: euphoria version {major, minor, revision, patch}}
-- # Keys. A list of all the keys
-- # Values. A list of the corresponding values for the keys.
--
-- Example 1:
-- <eucode>
--    map AppOptions
--    if save_map(AppOptions, "c:\myapp\options.txt") = -1
--        Error("Failed to save application options")
--    end if
--    if save_map(AppOptions, "c:\myapp\options.dat", SM_RAW) = -1
--        Error("Failed to save application options")
--    end if
-- </eucode>
-- See Also:
--		[[:load_map]]

public enum
	SM_TEXT,
	SM_RAW
	
public function save_map(map the_map_, object file_name_p, integer type_ = SM_TEXT)
	integer file_handle_ = -2
	sequence keys_
	sequence values_
	
	if sequence(file_name_p) then
		if type_ = SM_TEXT then
			file_handle_ = open(file_name_p, "w")
		else
			file_handle_ = open(file_name_p, "wb")
		end if
	else
		file_handle_ = file_name_p
	end if
	
	if file_handle_ < 0 then
		return -1
	end if
	
	keys_ = keys(the_map_)
	values_ = values(the_map_)
	
	if type_ = SM_RAW then
		puts(file_handle_, serialize(
				{1, -- saved map version
				format(now_gmt(), "%Y%m%d%H%M%S" ), -- date of this saved map
				{4,0,0,0}} -- Euphoria version
			 	))	
		puts(file_handle_, serialize(keys_))
		puts(file_handle_, serialize(values_))
	else
		for i = 1 to length(keys_) do
			keys_[i] = pretty_sprint(keys_[i], {2,0,1,0,"%d","%.15g",32,127,1,0})
			keys_[i] = find_replace("-", keys_[i], "\\-")
			values_[i] = pretty_sprint(values_[i], {2,0,1,0,"%d","%.15g",32,127,1,0})
			values_[i] = find_replace("-", values_[i], "\\-")
				
			printf(file_handle_, "%s = %s\n", {keys_[i], values_[i]})
			
		end for
	end if
	
	if sequence(file_name_p) then
		close(file_handle_)
	end if
	return length(keys_)
end function

--**
-- Duplicates a map.
--
-- Parameters:
--   # ##source_map##: map to duplicate
--   # ##dest_map##: optional map to duplicate to
--
-- Returns:
--   If ##dest_map## was not provided, a duplicate of ##source_map## otherwise
--   ##dest_map## is returned with the new values copied from ##source_map##.
--
-- Example 1:
--   <eucode>
--   map m1 = new()
--   put(m1, 1, "one")
--   put(m1, 2, "two")
--
--   map m2 = copy(m1)
--   printf(1, "%s, %s\n", { get(m2, 1), get(m2, 2) })
--   -- one, two
--
--   put(m1, 1, "one hundred")
--   printf(1, "%s, %s\n", { get(m1, 1), get(m1, 2) })
--   -- one hundred, two
--
--   printf(1, "%s, %s\n", { get(m2, 1), get(m2, 2) })
--   -- one, two
--   </eucode>
--
-- Example 2:
--   <eucode>
--   map m1 = new()
--   map m2 = new()
--
--   put(m1, 1, "one")
--   put(m1, 2, "two")
--
--   copy(m1, m2)
--   put(m2, 3, "three")
--
--   ? keys(m2)
--   -- { 1, 2, 3 }
--   </eucode>
--

public function copy(map source_map, object dest_map=0)
	atom temp_map = malloc()

	if map(dest_map) then
		-- TODO: a better (internal) way of doing this?
		sequence source_keys = keys(source_map)
		for i = 1 to length(source_keys) do
			put(dest_map, source_keys[i], get(source_map, source_keys[i]))
		end for

		return dest_map
	else
	 	ram_space[temp_map] = ram_space[source_map]
		return temp_map
	end if
end function

---- Local Functions ------------
procedure convert_to_large_map(map the_map_)
	sequence temp_map_
	atom map_handle_

	temp_map_ = ram_space[the_map_]
	if temp_map_[map_type] = LARGEMAP then
		return 
	end if
	
	map_handle_ = new()
	for index = 1 to length(temp_map_[free_list]) do
		if temp_map_[free_list][index] !=  0 then
			put(map_handle_, temp_map_[key_list][index], temp_map_[value_list][index])
		end if
	end for

	ram_space[the_map_] = ram_space[map_handle_]
	return
end procedure

procedure convert_to_small_map(map the_map_)
	sequence keys_
	sequence values_

	if ram_space[the_map_][map_type] = SMALLMAP then
		return
	end if
	keys_ = keys(the_map_)
	values_ = values(the_map_)
	
	ram_space[the_map_] = {type_is_map, 0,0, SMALLMAP, repeat(init_small_map_key, threshold_size), repeat(0, threshold_size), repeat(0, threshold_size)}
	
	for i = 1 to length(keys_) do
		put(the_map_, keys_[i], values_[i])
	end for

	return
end procedure

