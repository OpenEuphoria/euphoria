--**
--== Data type conversion.

-- **Page Contents**
--
-- <<LEVELTOC depth=2>>
--
constant
		 M_A_TO_F64 = 46,
		 M_F64_TO_A = 47,
		 M_A_TO_F32 = 48,
		 M_F32_TO_A = 49
--**
-- Converts an atom that represents an integer to a sequence of 4 bytes.
--
-- Parameters:
--		# ##x##, an atom, the value to convert.
--
-- Returns:
--		A **sequence** of 4 bytes, lowest significant byte first.
-- Comments:
-- If the atom does not fit into a 32-bit integer, things may still work right:
-- * If there is a fractional part, the first element in the returned value
-- will carry it. If you poke the value to RAM, that fraction will be discarded anyway.
-- * If ##x## is simply too big, the first three bytes will still be correct, and the 4th 
-- element will be  floor(##x##/power(2,24)). If this is not a byte sized integer, some
-- truncation may occur, but usually o error.
--
-- The integer can be negative. Negative byte-values will be returned, but
-- after poking them into memory you will have the correct (two's complement)
-- representation for the 386+.
--
-- Example 1:
-- <eucode>
--  s = int_to_bytes(999)
-- -- s is {231, 3, 0, 0}
-- </eucode>
--  
-- Example 2:  
-- <eucode>
--  s = int_to_bytes(-999)
-- -- s is {-231, -4, -1, -1}
-- <8eucode>
-- 
-- See Also:
--		[[:bytes_to_int]], [[:int_to_bits]], [[:atom_to_float64]], [[:poke4]], [[:poke8]]

global function int_to_bytes(atom x)
-- returns value of x as a sequence of 4 bytes 
-- that you can poke into memory 
--      {bits 0-7,  (least significant)
--       bits 8-15,
--       bits 16-23,
--       bits 24-31} (most significant)
-- This is the order of bytes in memory on 386+ machines.
	integer a,b,c,d
	
	a = remainder(x, #100)
	x = floor(x / #100)
	b = remainder(x, #100)
	x = floor(x / #100)
	c = remainder(x, #100)
	x = floor(x / #100)
	d = remainder(x, #100)
	return {a,b,c,d}
end function

constant M_ALLOC = 16
atom mem
mem = machine_func(M_ALLOC,4)

type sequence_8(sequence s)
-- an 8-element sequence
	return length(s) = 8
end type

type sequence_4(sequence s)
-- a 4-element sequence
	return length(s) = 4
end type

--**
-- Converts a sequence of at most 4 bytes into an atom.
--
-- Parameters:
--		# ##s##, the sequence to convert
-- Returns:
--		An **atom**, the value of the concatenated bytes of ##s##.
--
-- Comments:
--
--	This performs the reverse operation from [[:int_to_bytes]]
--
--  An atom is being returned, because the converted value may be bigger
-- than what can fit in an Euphoria integer.
--
-- Example 1:
-- <eucode>
--  atom int32
--
-- int32 = bytes_to_int({37,1,0,0})
-- -- int32 is 37 + 256*1 = 293
-- </eucode>
-- 
-- See Also:
-- [[:bits_to_int]], [[:float64_to_atom]], [[:int_to_bytes]], [[:peek]],
-- [[:peek4s]], [[:pee4ku]], [[:poke4]]

global function bytes_to_int(sequence s)
-- converts 4-byte peek() sequence into an integer value
	if length(s) = 4 then
		poke(mem, s)
	else    
		poke(mem, s[1..4]) -- avoid breaking old code
	end if
	return peek4u(mem)
end function

--**
-- Extracts the lower bits from an integer.
--
-- Parameters:
--		# ##x##, the atom to convert
-- 		# ##nbits##, the number of bits requested.
--
-- Returns:
--		A **sequence of length ##nbits##, made of 1's and 0's.
--
-- Comments:
-- ##x## should have no fractional part. If it does, then the first "bit"
-- will be an atom between 0 and 2.
--
-- The bits are returned lowest first.
--
-- For negative numbers the two's complement bit pattern is returned.
--
-- You can use subscripting, slicing, and/or/xor/not of entire sequences etc.
-- to manipulate sequences of bits. Shifting of bits and rotating of bits are
-- easy to perform.
--
-- Example 1:
-- <eucode>
--  s = int_to_bits(177, 8)
-- -- s is {1,0,0,0,1,1,0,1} -- "reverse" order
-- </eucode>
--  
-- See Also:
--	[[:bits_to_int]], [[:int_to_bytes]], [[:bitwise operations]],
--  [[:operations on sequences]]

global function int_to_bits(atom x, integer nbits)
-- Returns the low-order nbits bits of x as a sequence of 1's and 0's. 
-- Note that the least significant bits come first. You can use Euphoria's
-- and/or/not operators on sequences of bits. You can also subscript, 
-- slice, concatenate etc. to manipulate bits.
	sequence bits
	integer mask
	
	bits = repeat(0, nbits)
	if integer(x) and nbits < 30 then
		-- faster method
		mask = 1
		for i = 1 to nbits do
			bits[i] = and_bits(x, mask) and 1
			mask *= 2
		end for
	else
		-- slower, but works for large x and large nbits
		if x < 0 then
			x += power(2, nbits) -- for 2's complement bit pattern
		end if
		for i = 1 to nbits do
			bits[i] = remainder(x, 2) 
			x = floor(x / 2)
		end for
	end if
	return bits
end function

--**
-- Converts a sequence of bits to an atom that has no fractional part.
--
-- Parameters:
-- 		# ##bits##, the sequence to convert.
--
-- Returns:
--		A positive **atom**, whose machine representation was given by ##bits##.
--
-- Comments:
-- An element in ##bits## can be any atom. If nonzero, it counts for 1, else
-- for 0.
--
-- The first elements in ##bits## represent the bits with the least weight in
-- the returned value. Only the 52 last bits will matter, as the PC hardware
-- cannot hold an integer with more digits than this.
--  If you print s the bits will appear in "reverse" order, but it is
-- convenient to have increasing subscripts access bits of increasing
-- significance.
--
-- Example 1:
-- <eucode>
--  a = bits_to_int({1,1,1,0,1})
-- -- a is 23 (binary 10111)
-- </eucode>
--  
-- See Also:
--		[[:bytes_to_int]], [[:int_to_bits]], [[:operations on sequences]]

global function bits_to_int(sequence bits)
-- get the (positive) value of a sequence of "bits"
	atom value, p
	
	value = 0
	p = 1
	for i = 1 to length(bits) do
		if bits[i] then
			value += p
		end if
		p += p
	end for
	return value
end function

--**
-- Convert an atom to a sequence of 8 bytes in IEEE 64-bit format
-- Parameters:
-- 		# ##a##, the atom to convert:
--
-- Returns:
--		A **sequence** of 8 bytes, which can be poked in memory to represent ##a##.
--
-- Comments:
-- All Euphoria atoms have values which can be represented as 64-bit IEEE
-- floating-point numbers, so you can convert any atom to 64-bit format
-- without losing any precision.
--
-- Integer values will also be converted to 64-bit floating-point format.
--
-- Example:
--  <eucode>
--  fn = open("numbers.dat", "wb")
-- puts(fn, atom_to_float64(157.82)) -- write 8 bytes to a file
--  </eucode>
-- 
-- See Also:
--		[[:float64_to_atom]], [[:int_to_bytes]], [[:atom_to_float32]]

global function atom_to_float64(atom a)
	return machine_func(M_A_TO_F64, a)
end function

--**
-- Convert an atom to a sequence of 4 bytes in IEEE 32-bit format
-- Parameters:
-- 		# ##a##, the atom to convert:
--
-- Returns:
--		A **sequence** of 4 bytes, which can be poked in memory to represent ##a##.
--
-- Comments: 
-- Euphoria atoms can have values which are 64-bit IEEE floating-point
-- numbers, so you may lose precision when you convert to 32-bits
-- (16 significant digits versus 7). The range of exponents is much larger
-- in 64-bit format (10 to the 308, versus 10 to the 38), so some atoms may
-- be too large or too small to represent in 32-bit format. In this case you
-- will get one of the special 32-bit values: inf or -inf (infinity or
-- -infinity). To avoid this, you can use atom_to_float64().
--
-- Integer values will also be converted to 32-bit floating-point format.
--
-- On modern computers, computations on 64 bit floats are no faster than
-- on 32 bit floats. Internally, the PC stores them in 80 bit registers
-- anyway. Euphoria does not support these so called long doubles.
--
-- Example 1:
-- <eucode>
--  fn = open("numbers.dat", "wb")
-- puts(fn, atom_to_float32(157.82)) -- write 4 bytes to a file
-- </eucode>
-- 
-- See Also:
--		[[:float32_to_atom]], [[:int_to_bytes]], [[:atom_to_float64]]

global function atom_to_float32(atom a)
-- Convert an atom to a sequence of 4 bytes in IEEE 32-bit format
	return machine_func(M_A_TO_F32, a)
end function

--**
-- Convert a sequence of 8 bytes in IEEE 64-bit format to an atom
-- Parameters:
-- 		# ##ieee64##, the sequence to convert:
--
-- Returns:
--		An **atom**, the same value as the FPU would see by peeking
-- ##ieee64## from RAM.
--
-- Comments:
-- Any 64-bit IEEE floating-point number can be converted to an atom.
--
-- Example 1:
-- <eucode>
--  f = repeat(0, 8)
-- fn = open("numbers.dat", "rb")  -- read binary
-- for i = 1 to 8 do
--     f[i] = getc(fn)
-- end for
-- a = float64_to_atom(f)
-- </eucode>
--
-- See Also:
--		[[:float32_to_atom]], [[:bytes_to_int]], [[:atom_to_float64]]

global function float64_to_atom(sequence_8 ieee64)
-- Convert a sequence of 8 bytes in IEEE 64-bit format to an atom
	return machine_func(M_F64_TO_A, ieee64)
end function

--**
-- Convert a sequence of 4 bytes in IEEE 32-bit format to an atom
-- Parameters:
-- 		# ##ieee32##, the sequence to convert:
--
-- Returns:
--		An **atom**, the same value as the FPU would see by peeking
-- ##ieee64## from RAM.
--
-- Comments:
-- Any 32-bit IEEE floating-point number can be converted to an atom.
--
-- Example 1:
-- <eucode>
--  f = repeat(0, 4)
-- fn = open("numbers.dat", "rb") -- read binary
-- f[1] = getc(fn)
-- f[2] = getc(fn)
-- f[3] = getc(fn)
-- f[4] = getc(fn)
-- a = float32_to_atom(f)
-- </eucode>
--
-- See Also:
--		[[:float64_to_atom]], [[:bytes_to_int]], [[:atom_to_float32]]

global function float32_to_atom(sequence_4 ieee32)
-- Convert a sequence of 4 bytes in IEEE 32-bit format to an atom
	return machine_func(M_F32_TO_A, ieee32)
end function

