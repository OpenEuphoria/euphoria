--****
-- == Serialization of Euphoria Objects
--
-- <<LEVELTOC level=2 depth=4>>

namespace serialize

include std/convert.e
include std/dll.e
include std/error.e
include std/machine.e

-- Serialized format of Euphoria objects
--
-- First byte:
--          0..248    -- immediate small integer, -9 to 239
					  -- since small negative integers -9..-1 might be common
constant I2B = 249,   -- 2-byte signed integer follows
		 I3B = 250,   -- 3-byte signed integer follows
		 I4B = 251,   -- 4-byte signed integer follows
		 F4B = 252,   -- 4-byte f.p. number follows
		 F8B = 253,   -- 8-byte f.p. number follows
		 S1B = 254,   -- sequence, 1-byte length follows, then elements
		 S4B = 255,   -- sequence, 4-byte length follows, then elements
		 I8B = 0,     -- 8-byte integer, for 4.1 compatibility
		 F10B= 1      -- 10-byte floating point, for 4.1 compatibility

constant MIN1B = -9,
		 MAX1B = 237,
		 MIN2B = -power(2, 15),
		 MAX2B =  power(2, 15)-1,
		 MIN3B = -power(2, 23),
		 MAX3B =  power(2, 23)-1,
		 MIN4B = -power(2, 31),
		 MAX4B =  power(2, 31)-1,
		 MIN8B = -power(2, 63),
		 MAX8B =  power(2, 63)-1

atom mem0, mem1, mem2, mem3, mem4, mem5, mem6, mem7
mem0 = machine:allocate(8)
mem1 = mem0 + 1
mem2 = mem0 + 2
mem3 = mem0 + 3
mem4 = mem0 + 4
mem5 = mem0 + 5
mem6 = mem0 + 6
mem7 = mem0 + 7

function get4(integer fh)
-- read 4-byte value at current position in file
	poke(mem0, getc(fh))
	poke(mem1, getc(fh))
	poke(mem2, getc(fh))
	poke(mem3, getc(fh))
	return peek4u(mem0)
end function

function get8( integer fh )
-- read 4-byte value at current position in file
	poke(mem0, getc(fh))
	poke(mem1, getc(fh))
	poke(mem2, getc(fh))
	poke(mem3, getc(fh))
	poke(mem4, getc(fh))
	poke(mem5, getc(fh))
	poke(mem6, getc(fh))
	poke(mem7, getc(fh))
	return peek8s( mem0 )
end function

function deserialize_file(integer fh, integer c)
-- read a serialized Euphoria object from disk

	sequence s
	atom len

	if c = 0 then
		c = getc(fh)
		if c < I2B then
			return c + MIN1B
		end if
	end if
	
	switch c with fallthru do
		case I2B then
			return getc(fh) +
				#100 * getc(fh) +
				MIN2B

		case I3B then
			return getc(fh) +
				#100 * getc(fh) +
				#10000 * getc(fh) +
				MIN3B

		case I4B then
			return get4(fh) + MIN4B

		case F4B then
			return convert:float32_to_atom({getc(fh), getc(fh),
				getc(fh), getc(fh)})

		case F8B then
			return convert:float64_to_atom({getc(fh), getc(fh),
				getc(fh), getc(fh),
				getc(fh), getc(fh),
				getc(fh), getc(fh)})

		case else
			-- sequence
			if c = S1B then
				len = getc(fh)
			else
				len = get4(fh)
			end if
			if len < 0  or not integer(len) or len > MAX4B then
				return 0
			end if
			if c = S4B and len < 256 then
				if len = I8B then
					return get8(fh)

				elsif len = F10B then
					return convert:float80_to_atom({getc(fh), getc(fh),
						getc(fh), getc(fh),
						getc(fh), getc(fh),
						getc(fh), getc(fh),
						getc(fh), getc(fh)})
				else
					error:crash( "Invalid sequence serialization" )
				end if
			else
				s = repeat(0, len)
				for i = 1 to len do
					-- in-line small integer for greater speed on strings
					c = getc(fh)
					if c < I2B then
						s[i] = c + MIN1B
					else
						s[i] = deserialize_file(fh, c)
					end if
				end for
				return s
			end if
	end switch
end function

function getp4(sequence sdata, integer pos)
	poke(mem0, sdata[pos+0])
	poke(mem1, sdata[pos+1])
	poke(mem2, sdata[pos+2])
	poke(mem3, sdata[pos+3])
	return peek4u(mem0)
end function

function getp8( sequence sdata, integer pos)
	poke(mem0, sdata[pos..pos+7])
	return peek8s(mem0)
end function

function deserialize_object(sequence sdata, integer pos, integer c)
-- read a serialized Euphoria object from a sequence

	sequence s
	integer len

	if c = 0 then
		c = sdata[pos]
		pos += 1
		if c < I2B then
			return {c + MIN1B, pos}
		end if
	end if
	
	switch c with fallthru do
		case I2B then
			return {sdata[pos] +
				#100 * sdata[pos+1] +
				MIN2B, pos + 2}

		case I3B then
			return {sdata[pos] +
				#100 * sdata[pos+1] +
				#10000 * sdata[pos+2] +
				MIN3B, pos + 3}

		case I4B then
			return {getp4(sdata, pos) + MIN4B, pos + 4}
		
		case F4B then
			return {convert:float32_to_atom({sdata[pos], sdata[pos+1],
				sdata[pos+2], sdata[pos+3]}), pos + 4}

		case F8B then
			return {convert:float64_to_atom({sdata[pos], sdata[pos+1],
				sdata[pos+2], sdata[pos+3],
				sdata[pos+4], sdata[pos+5],
				sdata[pos+6], sdata[pos+7]}), pos + 8}
		
		case else
			-- sequence
			if c = S1B then
				len = sdata[pos]
				pos += 1
			else
				len = getp4(sdata, pos)
				pos += 4
			end if
			if c = S4B and len < 256 then
				if len = I8B then
					return { getp8(sdata, pos), pos + 8 }
				elsif len = F10B then
					return {convert:float80_to_atom({sdata[pos], sdata[pos+1],
							sdata[pos+2], sdata[pos+3],
							sdata[pos+4], sdata[pos+5],
							sdata[pos+6], sdata[pos+7],
							sdata[pos+8], sdata[pos+9]}), pos + 10}
				else
					error:crash( "Invalid sequence serialization" )
				end if
			else
				s = repeat(0, len)
				for i = 1 to len do
					-- in-line small integer for greater speed on strings
					c = sdata[pos]
					pos += 1
					if c < I2B then
						s[i] = c + MIN1B
					else
						sequence temp = deserialize_object(sdata, pos, c)
						s[i] = temp[1]
						pos = temp[2]
					end if
				end for
				return {s, pos}
			end if
	end switch
end function

--****
-- === Routines

--**
-- converts a serialized object in to a standard Euphoria object.
--
-- Parameters:
-- # ##sdata## : either a sequence containing one or more concatenated serialized objects or
-- an open file handle. If this is a file handle, the current position in the
-- file is assumed to be at a serialized object in the file.
-- # ##pos## : optional index into ##sdata##. If omitted 1 is assumed. The index must
-- point to the start of a serialized object.
--
-- Returns:
-- The return **value**, depends on the input type. 
-- * If ##sdata## is a file handle then
-- this function returns a Euphoria object that had been stored in the file, and
-- moves the current file to the first byte after the stored object.
-- * If ##sdata## is a sequence then this returns a two-element sequence.
-- The //first// element is the Euphoria object that corresponds to the serialized
-- object that begins at index ##pos##, and the //second// element is the index
-- position in the input parameter just after the serialized object.
-- 
-- 
-- Comments:
-- A serialized object is one that has been returned from the [[:serialize]] function.
--
-- Example 1:
-- <eucode>
--  sequence objcache
--  objcache = serialize(FirstName) &
--             serialize(LastName) &
--             serialize(PhoneNumber) &
--             serialize(Address)
--
--  sequence res
--  integer pos = 1
--  res = deserialize( objcache , pos)
--  FirstName = res[1] pos = res[2]
--  res = deserialize( objcache , pos)
--  LastName = res[1] pos = res[2]
--  res = deserialize( objcache , pos)
--  PhoneNumber = res[1] pos = res[2]
--  res = deserialize( objcache , pos)
--  Address = res[1] pos = res[2]
-- </eucode>
--
-- Example 2:
-- <eucode>
--  sequence objcache
--  objcache = serialize({FirstName,
--                       LastName,
--                       PhoneNumber,
--                       Address})
--
--  sequence res
--  res = deserialize( objcache )
--  FirstName = res[1][1]
--  LastName = res[1][2]
--  PhoneNumber = res[1][3]
--  Address = res[1][4]
-- </eucode>
--
-- Example 3:
-- <eucode>
--  integer fh
--  fh = open("cust.dat", "wb")
--  puts(fh, serialize(FirstName))
--  puts(fh, serialize(LastName))
--  puts(fh, serialize(PhoneNumber))
--  puts(fh, serialize(Address))
--  close(fh)
--
--  fh = open("cust.dat", "rb")
--  FirstName = deserialize(fh)
--  LastName = deserialize(fh)
--  PhoneNumber = deserialize(fh)
--  Address = deserialize(fh)
--  close(fh)
-- </eucode>
--
-- Example 4:
-- <eucode>
--  integer fh
--  fh = open("cust.dat", "wb")
--  puts(fh, serialize({FirstName,
--                      LastName,
--                      PhoneNumber,
--                      Address}))
--  close(fh)
--
--  sequence res
--  fh = open("cust.dat", "rb")
--  res = deserialize(fh)
--  close(fh)
--  FirstName = res[1]
--  LastName = res[2]
--  PhoneNumber = res[3]
--  Address = res[4]
-- </eucode>
--

public function deserialize(object sdata, integer pos = 1)
-- read a serialized Euphoria object
	
	if integer(sdata) then
		return deserialize_file(sdata, 0)
	end if
	
	if atom(sdata) then
		return 0
	end if
	
	return deserialize_object(sdata, pos, 0)
	
end function

--**
-- converts a standard Euphoria object in to a serialized version of it.
--
-- Parameters:
-- # ##euobj## : any Euphoria object.
--
-- Returns:
-- A **sequence**, this is the serialized version of the input object.
-- 
-- Comments:
-- A serialized object is one that has been converted to a set of byte values. This
-- can then by written directly out to a file for storage.
--
-- You can use the [[:deserialize]] function to convert it back into a standard 
-- Euphoria object.
--
-- Example 1:
-- <eucode>
--  integer fh
--  fh = open("cust.dat", "wb")
--  puts(fh, serialize(FirstName))
--  puts(fh, serialize(LastName))
--  puts(fh, serialize(PhoneNumber))
--  puts(fh, serialize(Address))
--  close(fh)
--
--  fh = open("cust.dat", "rb")
--  FirstName = deserialize(fh)
--  LastName = deserialize(fh)
--  PhoneNumber = deserialize(fh)
--  Address = deserialize(fh)
--  close(fh)
-- </eucode>
--
-- Example 2:
-- <eucode>
--  integer fh
--  fh = open("cust.dat", "wb")
--  puts(fh, serialize({FirstName,
--                      LastName,
--                      PhoneNumber,
--                      Address}))
--  close(fh)
--
--  sequence res
--  fh = open("cust.dat", "rb")
--  res = deserialize(fh)
--  close(fh)
--  FirstName = res[1]
--  LastName = res[2]
--  PhoneNumber = res[3]
--  Address = res[4]
-- </eucode>
--
public function serialize(object x)
-- return the serialized representation of a Euphoria object
-- as a sequence of bytes
	sequence x4, s

	if integer(x) then -- and x >= MIN4B and x <= MAX4B then
		if x >= MIN1B and x <= MAX1B then
			return {x - MIN1B}

		elsif x >= MIN2B and x <= MAX2B then
			x -= MIN2B
			return {I2B, and_bits(x, #FF), floor(x / #100)}

		elsif x >= MIN3B and x <= MAX3B then
			x -= MIN3B
			return {I3B, and_bits(x, #FF), and_bits(floor(x / #100), #FF), floor(x / #10000)}

		elsif x >= MIN4B and x <= MAX4B then
			return I4B & convert:int_to_bytes(x-MIN4B)
		
		else
			return S4B & I8B & repeat( 0, 3 ) & int_to_bytes(x, 8)
		end if

	elsif atom(x) then
		-- floating point
		x4 = convert:atom_to_float32(x)
		if x = convert:float32_to_atom(x4) then
			-- can represent as 4-byte float
			return F4B & x4
		else
			x4 = convert:atom_to_float64( x )
			if x = convert:float64_to_atom( x4 ) then
				return F8B & convert:atom_to_float64(x)
			else
				return S4B & F10B & repeat( 0, 3 ) & convert:atom_to_float80( x )
			end if
		end if

	else
		-- sequence
		if length(x) <= 255 then
			s = {S1B, length(x)}
		else
			s = S4B & convert:int_to_bytes(length(x))
		end if
		for i = 1 to length(x) do
			s &= serialize(x[i])
		end for
		return s
	end if
end function

--**
-- saves a Euphoria object to disk in a binary format.
--
-- Parameters:
-- # ##data## : any Euphoria object.
-- # ##filename## : the name of the file to save it to.
--
-- Returns:
-- An **integer**, 0 if the function fails, otherwise the number of bytes in the
-- created file.
-- 
-- Comments:
-- If the named file does not exist it is created, otherwise it is overwritten.
--
-- You can use the [[:load]] function to recover the data from the file.
--
-- Example 1:
-- <eucode>
-- include std/serialize.e
-- integer size = dump(myData, theFileName) 
-- if size = 0 then
--     puts(1, "Failed to save data to file\n")
-- else
--     printf(1, "Saved file is %d bytes long\n", size)
-- end if
-- </eucode>
--
public function dump(sequence data, sequence filename)
	integer fh
	sequence sdata
	
	fh = open(filename, "wb")
	if fh < 0 then
		return 0
	end if
	
	sdata = serialize(data)
	puts(fh, sdata)
	
	close(fh)
	
	return length(sdata) -- Length is always > 0
end function

--**
-- restores a Euphoria object that has been saved to disk by [[:dump]].
--
-- Parameters:
-- # ##filename## : the name of the file to restore it from.
--
-- Returns:
-- A **sequence**, the first element is the result code. If the result code is 0
-- then it means that the function failed, otherwise the restored data is in the 
-- second element.
-- 
-- Comments:
-- This is used to load back data from a file created by the [[:dump]]
-- function.
--
-- Example 1:
-- <eucode>
-- include std/serialize.e
-- sequence mydata = load(theFileName) 
-- if mydata[1] = 0 then
--     puts(1, "Failed to load data from file\n")
-- else
--     mydata = mydata[2] -- Restored data is in second element.
-- end if
-- </eucode>
--
public function load(sequence filename)
	integer fh
	sequence sdata

	fh = open(filename, "rb")
	if fh < 0 then
		return {0}
	end if
	
	sdata = deserialize(fh)
	
	close(fh)
	return {1, sdata}
end function
