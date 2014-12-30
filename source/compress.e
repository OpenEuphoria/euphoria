-- (c) Copyright - See License.txt
--
-- compression / decompression

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef
include std/convert.e
include std/machine.e

export constant IL_MAGIC = 79 -- indicates an IL file

-- IL Versioning
--
-- 10 -- (2.5 alpha) IL version number
-- 11 -- (2.5 beta)
-- 12 -- 3.0.0 Open Source, no encryption
-- 13 -- 4.0 Added file_include, blocks, include_matrix, removed pixel, get_pixel

export constant IL_VERSION = 13

export constant IL_START = "YTREWQ\n"

-- Compressed / Decompress Euphoria objects

-- tags for various values:
export constant
		 I2B  = 247,   -- 2-byte signed integer follows
		 I3B  = 248,   -- 3-byte signed integer follows
		 I4B  = 249,   -- 4-byte signed integer follows
		 I8B  = 250,   -- 8-byte signed integer follows
		 F4B  = 251,   -- 4-byte f.p. number follows
		 F8B  = 252,   -- 8-byte f.p. number follows
		 F10B = 253,   -- 10-byte fp number follows
		 S1B  = 254,   -- sequence, 1-byte length follows, then elements
		 S4B  = 255    -- sequence, 4-byte length follows, then elements

-- ranges for various sizes:
export constant
		 MIN1B = -2,  -- minimum integer value stored in one byte
		 MAX1B = 244, -- maximum integer value (if no cache)
		 MIN2B = -power(2, 15),
		 MAX2B =  power(2, 15)-1,
		 MIN3B = -power(2, 23),
		 MAX3B =  power(2, 23)-1,
		 MIN4B = -power(2, 31),
		 MAX4B =  power(2, 31)-1,
		 MIN8B = -power(2, 63),
		 MAX8B =  power(2, 63)-1

export function compress(object x)
-- Return the compressed representation of a Euphoria object
-- as a sequence of bytes (in memory).
-- The compression cache is not used. Decompression occurs in be_execute.c
	sequence x4, s

	if integer(x) then
		if x >= MIN1B and x <= MAX1B then
			return {x - MIN1B}

		elsif x >= MIN2B and x <= MAX2B then
			x -= MIN2B
			return {I2B, and_bits(x, #FF), floor(x / #100)}

		elsif x >= MIN3B and x <= MAX3B then
			x -= MIN3B
			return {I3B, and_bits(x, #FF), and_bits(floor(x / #100), #FF), floor(x / #10000)}

		elsif x >= MIN4B and x <= MAX4B then
			return I4B & int_to_bytes(x)
		
		else
			ifdef EU4_0 then
				-- Euphoria 4.0 int_to_bytes doesn't take a size argument
				return I8B & int_to_bytes(remainder(x,#1_0000_0000)) & int_to_bytes(floor(x/#1_0000_0000))
			elsedef
				return I8B & int_to_bytes(x, 8)
			end ifdef
		end if

	elsif atom(x) then
		-- floating point
		x4 = atom_to_float32(x)
		if x = float32_to_atom(x4) then
			-- can represent as 4-byte float
			return F4B & x4
		else
			x4 = atom_to_float64( x )
			if x = float64_to_atom( x4 ) then
				return F8B & x4
			else
				return F10B & atom_to_float80( x )
			end if
		end if

	else
		-- sequence
		if length(x) <= 255 then
			s = {S1B, length(x)}
		else
			s = S4B & int_to_bytes(length(x))
		end if
		for i = 1 to length(x) do
			s &= compress(x[i])
		end for
		return s
	end if
end function

-- Compression Cache: To save space on disk, we allocate a series of
-- dynamic one-byte codes to represent recently-seen (large) integer values,
-- rather than reserving those codes for specific small integer values.
-- We use the lower bits of the integer value to provide fast access to the
-- cache slot that it would occupy if it were present in the cache,
-- i.e. if it is the most recently-seen value for that particular cache slot.
-- Both the compressor and decompressor update the cache as they go through
-- the IL stream. This often allows us to issue a one-byte code rather than a
-- 3, 4 or 5-byte code to indicate a large integer. Experiments show that
-- this reduces the size of the IL by a significant amount (maybe 30%),
-- as we often see the same large integers (such as symbol table indexes)
-- repeated several times within a short segment of the IL.

constant COMP_CACHE_SIZE = 64  -- power of 2: number of large integers to cache

constant CACHE0 = 255-9-COMP_CACHE_SIZE -- just before cache

export integer max1b  -- maximum integer value to store in one byte
max1b = CACHE0 + MIN1B

sequence comp_cache  -- stores recent large (hopefully over one byte) values

export procedure init_compress()
-- do this before a series of calls to fcompress() or fdecompress()
	comp_cache = repeat({}, COMP_CACHE_SIZE)
end procedure

export procedure fcompress(integer f, object x)
-- Write the compressed representation of a Euphoria object
-- to disk as a sequence of bytes. A compression cache is used.
	sequence x4, s
	integer p

	if integer(x) then
		if x >= MIN1B and x <= max1b then
			puts(f, x - MIN1B) -- normal, quite small integer

		else
			-- check the appropriate slot in the compression cache
			p = 1 + and_bits(x, COMP_CACHE_SIZE-1)
			if equal(comp_cache[p], x) then
				-- a cache hit
				puts(f, CACHE0 + p) -- output the cache slot number

			else
				-- cache miss
				comp_cache[p] = x -- store it in cache slot p

				-- write out the full value this time (but hopefully next time
				-- we can just write the one-byte cache slot number
				-- representing this number)
				if x >= MIN2B and x <= MAX2B then
					x -= MIN2B
					puts(f, {I2B, and_bits(x, #FF), floor(x / #100)})

				elsif x >= MIN3B and x <= MAX3B then
					x -= MIN3B
					puts(f, {I3B, and_bits(x, #FF), and_bits(floor(x / #100), #FF), floor(x / #10000)})

				elsif x >= MIN4B and x <= MAX4B then
					puts(f, I4B & int_to_bytes(x))
					
				else
					ifdef not EU4_0 then
						puts(f, I8B & int_to_bytes(x, 8))
					elsedef
						-- Euphoria 4.0 int_to_bytes doesn't take a size argument
						puts(f, I8B & int_to_bytes(remainder(x,#1_0000_0000)) & int_to_bytes(floor(x/#1_0000_0000)) )
					end ifdef					
				end if
			end if
		end if

	elsif atom(x) then
		-- floating point
		x4 = atom_to_float32(x)
		if x = float32_to_atom(x4) then
			-- can represent as 4-byte float
			puts(f, F4B & x4)
		else
			x4 = atom_to_float64(x)
			if x = float64_to_atom( x4 ) then
				puts(f, F8B & x4)
			else
				puts(f, F10B & atom_to_float80( x ) )
			end if
		end if

	else
		-- sequence
		if length(x) <= 255 then
			s = {S1B, length(x)}
		else
			s = S4B & int_to_bytes(length(x))
		end if
		puts(f, s)
		for i = 1 to length(x) do
			fcompress(f, x[i])
		end for
	end if
end procedure

constant M_ALLOC = 16
atom
	mem0 = machine_func(M_ALLOC,8),
	mem1 = mem0 + 1,
	mem2 = mem0 + 2,
	mem3 = mem0 + 3,
	mem4 = mem0 + 4,
	mem5 = mem0 + 5,
	mem6 = mem0 + 6,
	mem7 = mem0 + 7,
	$

export integer current_db

function get4()
-- read 4-byte value at current position in database file
	poke(mem0, getc(current_db))
	poke(mem1, getc(current_db))
	poke(mem2, getc(current_db))
	poke(mem3, getc(current_db))
	return peek4s(mem0)
end function

function get8()
-- read 8-byte value at current position in database file
	poke(mem0, getc(current_db))
	poke(mem1, getc(current_db))
	poke(mem2, getc(current_db))
	poke(mem3, getc(current_db))
	poke(mem4, getc(current_db))
	poke(mem5, getc(current_db))
	poke(mem6, getc(current_db))
	poke(mem7, getc(current_db))
	return peek8s(mem0)
end function

export function fdecompress(integer c)
-- read a compressed Euphoria object from disk.
-- A compression cache is used.
-- if c is set, then c is not in byte range.
	sequence s
	integer len
	integer ival

	if c = 0 then
		c = getc(current_db)
		if c <= CACHE0 then
			return c + MIN1B  -- a normal, quite small integer

		elsif c <= CACHE0 + COMP_CACHE_SIZE then
			-- a cache slot number - use the value currently stored in
			-- the compression cache at this slot
			return comp_cache[c-CACHE0]

		end if
	end if

	if c = I2B then
		ival = getc(current_db) +
			   #100 * getc(current_db) +
			   MIN2B
		-- update the appropriate compression cache slot
		comp_cache[1 + and_bits(ival, COMP_CACHE_SIZE-1)] = ival
		return ival

	elsif c = I3B then
		ival = getc(current_db) +
			   #100 * getc(current_db) +
			   #10000 * getc(current_db) +
			   MIN3B
		-- update the appropriate compression cache slot
		comp_cache[1 + and_bits(ival, COMP_CACHE_SIZE-1)] = ival
		return ival

	elsif c = I4B  then
		ival = get4()
		-- update the appropriate compression cache slot
		comp_cache[1 + and_bits(ival, COMP_CACHE_SIZE-1)] = ival
		return ival
		
	elsif c = I8B then
		ival = get8()
		-- update the appropriate compression cache slot
		comp_cache[1 + and_bits(ival, COMP_CACHE_SIZE-1)] = ival
		return ival
		
	elsif c = F4B then
		return float32_to_atom({getc(current_db), getc(current_db),
								getc(current_db), getc(current_db)})
	elsif c = F8B then
		return float64_to_atom({getc(current_db), getc(current_db),
								getc(current_db), getc(current_db),
								getc(current_db), getc(current_db),
								getc(current_db), getc(current_db)})
	elsif c = F10B then
		return float80_to_atom({getc(current_db), getc(current_db),
								getc(current_db), getc(current_db),
								getc(current_db), getc(current_db),
								getc(current_db), getc(current_db),
								getc(current_db), getc(current_db)})
	else
		-- sequence
		if c = S1B then
			len = getc(current_db)
		else
			len = get4()
		end if
		s = repeat(0, len)
		for i = 1 to len do
			-- inline the small integer case for greater speed on strings
			c = getc(current_db)
			if c < I2B then
				if c <= CACHE0 then
					s[i] = c + MIN1B

				elsif c <= CACHE0 + COMP_CACHE_SIZE then
					-- a value from cache
					s[i] = comp_cache[c - CACHE0]
				end if
			else
				s[i] = fdecompress(c)
			end if
		end for
		return s
	end if
end function

