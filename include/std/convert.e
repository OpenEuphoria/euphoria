--# This file uses ISO-8859-1 encoding
--****
-- == Data Type Conversion
--
-- <<LEVELTOC level=2 depth=4>>
--

namespace convert

include std/types.e
include std/search.e
include std/text.e
include std/machine.e

constant
	M_A_TO_F64 = 46,
	M_F64_TO_A = 47,
	M_A_TO_F32 = 48,
	M_F32_TO_A = 49,
	M_F80_TO_A = 101,
	M_A_TO_F80 = 105


constant M_ALLOC = 16
atom mem  = machine_func(M_ALLOC,8)

--****
-- === Routines

--**
-- converts an atom that represents an integer to a sequence of 4 bytes.
--
-- Parameters:
--		# ##x## : an atom, the value to convert.
--
-- Returns:
--		A **sequence**, of 4 bytes, lowest significant byte first.
--
-- Comments:
-- If the atom does not fit into a 32-bit integer, things may still work right:
-- * If there is a fractional part, the first element in the returned value
--   will carry it. If you poke the sequence to RAM, that fraction will be discarded anyway.
-- * If ##x## is simply too big, the first three bytes will still be correct, and the 4th
--   element will be  ##floor(x/power(2,24))##. If this is not a byte sized integer, some
--   truncation may occur, but usually no error.
--
-- The integer can be negative. Negative byte-values will be returned, but
-- after poking them into memory you will have the correct (two's complement)
-- representation for the 386+.
--
-- Example 1:
-- <eucode>
-- s = int_to_bytes(999)
-- -- s is {231, 3, 0, 0}
-- </eucode>
--
-- Example 2:
--
-- <eucode>
-- s = int_to_bytes(-999)
-- -- s is {-231, -4, -1, -1}
-- </eucode>
--
-- See Also:
--		[[:bytes_to_int]], [[:int_to_bits]], [[:atom_to_float64]], [[:poke4]]

public function int_to_bytes(atom x, integer size = 4 )
	switch size do
		case 1 then
			poke( mem, x )
		case 2 then
			poke2( mem, x )
		case 4 then
			poke4( mem, x )
		case 8 then
			poke8( mem, x )
		case else
			return {}
	end switch
	return peek( mem & size )
end function

type sequence_8(sequence s)
-- an 8-element sequence
	return length(s) = 8
end type

type sequence_4(sequence s)
-- a 4-element sequence
	return length(s) = 4
end type

--**
-- converts a sequence of at most 4 bytes into an atom.
--
-- Parameters:
--		# ##s## : the sequence to convert
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
-- atom int32
--
-- int32 = bytes_to_int({37,1,0,0})
-- -- int32 is 37 + 256*1 = 293
-- </eucode>
--
-- See Also:
--   [[:bits_to_int]], [[:float64_to_atom]], [[:int_to_bytes]], [[:peek]],
--   [[:peek4s]], [[:peek4u]], [[:poke4]]

public function bytes_to_int(sequence s)
	if length(s) = 4 then
		poke(mem, s)
	elsif length(s) < 4 then
		poke(mem, s & repeat(0, 4 - length(s))) -- avoid breaking old code
	else
		poke(mem, s[1..4]) -- avoid breaking old code
	end if
	return peek4u(mem)
end function

--**
-- extracts the lower bits from an integer.
--
-- Parameters:
--		# ##x## : the atom to convert
-- 		# ##nbits## : the number of bits requested. The default is 32.
--
-- Returns:
--		A **sequence**, of length ##nbits##, made of 1's and 0's.
--
-- Comments:
-- ##x## should have no fractional part. If it does, then the first "bit"
-- will be an atom between 0 and 2.
--
-- The bits are returned lowest first.
--
-- For negative numbers the two's complement bit pattern is returned.
--
-- You can use operators like subscripting/slicing/and/or/xor/not on entire sequences
-- to manipulate sequences of bits. Shifting of bits and rotating of bits are
-- easy to perform.
--
-- Example 1:
-- <eucode>
-- s = int_to_bits(177, 8)
-- -- s is {1,0,0,0,1,1,0,1} -- "reverse" order
-- </eucode>
--
-- See Also:
--	[[:bits_to_int]], [[:int_to_bytes]], [[:Relational operators]],
--  [[:operations on sequences]]

public function int_to_bits(atom x, integer nbits = 32)
	sequence bits
	atom mask

	if nbits < 1 then
		return {}
	end if
	bits = repeat(0, nbits)
	if nbits <= 32 then
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
-- converts a sequence of bits to an atom that has no fractional part.
--
-- Parameters:
-- 		# ##bits## : the sequence to convert.
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
--
-- If you print s the bits will appear in "reverse" order, but it is
-- convenient to have increasing subscripts access bits of increasing
-- significance.
--
-- Example 1:
-- <eucode>
-- a = bits_to_int({1,1,1,0,1})
-- -- a is 23 (binary 10111)
-- </eucode>
--
-- See Also:
--		[[:bytes_to_int]], [[:int_to_bits]], [[:operations on sequences]]

public function bits_to_int(sequence bits)
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
-- converts an atom to a sequence of 8 bytes in IEEE 64-bit format.
--
-- Parameters:
-- 		# ##a## : the atom to convert:
--
-- Returns:
--		A **sequence**, of 8 bytes, which can be poked in memory to represent ##a##.
--
-- Comments:
-- All Euphoria atoms have values which can be represented as 64-bit IEEE
-- floating-point numbers, so you can convert any atom to 64-bit format
-- without losing any precision.
--
-- Integer values will also be converted to 64-bit floating-point format.
--
-- Example 1:
-- <eucode>
-- fn = open("numbers.dat", "wb")
-- puts(fn, atom_to_float64(157.82)) -- write 8 bytes to a file
-- </eucode>
--
-- See Also:
--     [[:float64_to_atom]], [[:int_to_bytes]], [[:atom_to_float32]]

public function atom_to_float64(atom a)
	return machine_func(M_A_TO_F64, a)
end function

--**
-- 
public function atom_to_float80(atom a)
	return machine_func(M_A_TO_F80, a)
end function

--**
--
public function float80_to_atom( sequence bytes )
	return machine_func(M_F80_TO_A, bytes )
end function

--**
-- converts an atom to a sequence of 4 bytes in IEEE 32-bit format.
--
-- Parameters:
-- 		# ##a## : the atom to convert:
--
-- Returns:
--		A **sequence**, of 4 bytes, which can be poked in memory to represent ##a##.
--
-- Comments:
--
-- Euphoria atoms can have values which are 64-bit IEEE floating-point
-- numbers, so you may lose precision when you convert to 32-bits
-- (16 significant digits versus 7). The range of exponents is much larger
-- in 64-bit format (10 to the 308, versus 10 to the 38), so some atoms may
-- be too large or too small to represent in 32-bit format. In this case you
-- will get one of the special 32-bit values: ##inf## or ##-inf## (infinity or
-- -infinity). To avoid this, you can use [[:atom_to_float64]].
--
-- Integer values will also be converted to 32-bit floating-point format.
--
-- On modern computers, computations on 64 bit floats are no slower than
-- on 32 bit floats. Internally, the PC stores them in 80 bit registers
-- anyway. Euphoria does not support these so called long doubles. Not all C compilers do.
--
-- Example 1:
-- <eucode>
-- fn = open("numbers.dat", "wb")
-- puts(fn, atom_to_float32(157.82)) -- write 4 bytes to a file
-- </eucode>
--
-- See Also:
--		[[:float32_to_atom]], [[:int_to_bytes]], [[:atom_to_float64]]

public function atom_to_float32(atom a)
	return machine_func(M_A_TO_F32, a)
end function

--**
-- converts a sequence of 8 bytes in IEEE 64-bit format to an atom.
--
-- Parameters:
-- 		# ##ieee64## : the sequence to convert.
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
-- f = repeat(0, 8)
-- fn = open("numbers.dat", "rb")  -- read binary
-- for i = 1 to 8 do
--     f[i] = getc(fn)
-- end for
-- a = float64_to_atom(f)
-- </eucode>
--
-- See Also:
--		[[:float32_to_atom]], [[:bytes_to_int]], [[:atom_to_float64]]

public function float64_to_atom(sequence_8 ieee64)
-- Convert a sequence of 8 bytes in IEEE 64-bit format to an atom
	return machine_func(M_F64_TO_A, ieee64)
end function

--**
-- converts a sequence of 4 bytes in IEEE 32-bit format to an atom.
--
-- Parameters:
-- 		# ##ieee32## : the sequence to convert.
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
-- f = repeat(0, 4)
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

public function float32_to_atom(sequence_4 ieee32)
	return machine_func(M_F32_TO_A, ieee32)
end function

--**
-- converts a text representation of a hexadecimal number to an atom.
--
-- Parameters:
-- 		# ##text## : the text to convert.
--
-- Returns:
--		An **atom**, the numeric equivalent to ##text##
--
-- Comments:
-- * The text can optionally begin with ##'#'## which is ignored.
-- * The text can have any number of underscores, all of which are ignored.
-- * The text can have one leading ##'-'##, indicating a negative number.
-- * The text can have any number of underscores, all of which are ignored.
-- * Any other characters in the text stops the parsing and returns the value thus far.
--
-- Example 1:
-- <eucode>
--  atom h = hex_text("-#3_4FA.00E_1BD")
--  -- h is now -13562.003444492816925
--  atom h = hex_text("DEADBEEF")
--  -- h is now 3735928559
-- </eucode>
--
-- See Also:
--		[[:value]]

public function hex_text(sequence text)
	atom res
	atom fp
	integer div
	integer pos
	integer sign
	integer n

	res = 0
	fp = 0
	div = 0
	sign = 0
	n = 0

	for i = 1 to length(text) do
		if text[i] = '_' then
			continue
		end if

		if text[i] = '#' then
			if n = 0 then
				continue
			else
				exit
			end if
		end if

		if text[i] = '.' then
			if div = 0 then
				div = 1
				continue
			else
				exit
			end if
		end if

		if text[i] = '-' then
			if sign = 0 and n = 0 then
				sign = -1
				continue
			else
				exit
			end if
		end if

		pos = eu:find(text[i], "0123456789abcdefABCDEF")
		if pos = 0 then
			exit
		end if

		if pos > 16 then
			pos -= 6
		end if
		pos -= 1
		if div = 0 then
			res = res * 16 + pos
		else
		    fp = fp * 16 + pos
		    div += 1
		end if
		n += 1

	end for

	while div > 1 do
		fp /= 16
		div -= 1
	end while
	res += fp
	if sign != 0 then
		res = -res
	end if

	return res

end function


constant vDigits = "0123456789ABCDEFabcdef"
integer decimal_mark = '.'

--**
-- gets, and possibly sets, the decimal mark that [[:to_number]] uses.
--
-- Parameters:
-- # ##new_mark## : An integer: Either a comma (,), a period (.) or any other integer.
--
-- Returns:
-- An **integer**, The current value, before ##new_mark## changes it.
--
-- Comments:
-- * When ##new_mark## is a //period// it will cause ##to_number## to interpret a dot ##(.)##
-- as the decimal point symbol. The pre-changed value is returned.
-- * When ##new_mark## is a //comma// it will cause ##to_number## to interpret a comma ##(,)##
-- as the decimal point symbol. The pre-changed value is returned.
-- * Any other value does not change the current setting. Instead it just returns the current value.
-- * The initial value of the decimal marker is a period.

public function set_decimal_mark(integer new_mark)
	integer old_mark

	old_mark = decimal_mark
	switch new_mark do
		case ',', '.' then
			decimal_mark = new_mark

		case else
			-- do nothing.
	end switch
	return old_mark
end function

--**
-- converts the text into a number.
--
-- Parameters:
-- # ##text_in## : A string containing the text representation of a number.
-- # ##return_bad_pos## : An integer. 
--     ** If 0 (the default) then this will return
--     a number based on the supplied text and it will **not** return
--     any position in ##text_in## that caused an incomplete conversion. 
--     ** If ##return_bad_pos## is -1 then if the conversion of ##text_in## was
--        complete the resulting number is returned otherwise a single-element
--        sequence containing the position within ##text_in## where the conversion
--        stopped. 
--     ** If not 0 then this returns both the converted value up to the point of failure (if any) and the
--     position in ##text_in## that caused the failure. If that position is 0 then
--     there was no failure. 
--
-- Returns:
-- * an **atom**, If ##return_bad_pos## is zero, the number represented by ##text_in##.
--  If ##text_in## contains invalid characters, zero is returned.\\
-- * a **sequence**, If ##return_bad_pos## is non-zero. If ##return_bad_pos## is -1
-- it returns a 1-element sequence containing the spot inside ##text_in## where
-- conversion stopped. Otherwise it returns a 2-element sequence
-- containing the number represented by ##text_in## and either 0 or the position in
-- ##text_in## where conversion stopped.
--
-- Comments:
-- # You can supply **Hexadecimal** values if the value is preceded by
-- a '#' character, **Octal** values if the value is preceded by a '@' character,
-- and **Binary** values if the value is preceded by a '!' character. With
-- hexadecimal values, the case of the digits 'A' - 'F' is not important. Also,
-- any decimal marker embedded in the number is used with the correct base.
-- # Any underscore characters or thousands separators, that are embedded in the text
-- number are ignored. These can be used to help visual clarity for long numbers. The thousands
-- separator is a ',' when the decimal mark is '.' (the default), or '.' if the
-- decimal mark is ','. You inspect and set it using [[:set_decimal_mark]]().
-- # You can supply a single leading or trailing sign. Either a minus (-) or plus (+).
-- # You can supply one or more trailing adjacent percentage signs. The first one
-- causes the resulting value to be divided by 100, and each subsequent one divides
-- the result by a further 10. Thus ##3845%## gives a value of ##(3845 / 100) ==> 38.45##,
-- and ##3845%%## gives a value of ##(3845 / 1000) ==> 3.845##.
-- # You can have single currency symbol before the first digit or after the last
-- digit. A currency symbol is any character of the string: "$£¤¥€".
-- # You can have any number of whitespace characters before the first digit and
-- after the last digit.
-- # The currency, sign and base symbols can appear in any order. Thus ##"$ -21.10"## is
-- the same as ##" -$21.10 "##, which is also the same as ##"21.10$-"##, and so on.
-- # This function can optionally return information about invalid numbers. If ##return_bad_pos##
-- is not zero, a two-element sequence is returned. The first element is the converted
-- number value , and the second is the position in the text where conversion stopped.
-- If no errors were found then the second element is zero.
-- # When converting floating point text numbers to atoms, you need to be aware that
-- many numbers cannot be accurately converted to the exact value expected due to the
-- limitations of the 64-bit IEEEE Floating point format.
--
-- Example 1:
-- <eucode>
-- object val
-- val = to_number("12.34")      ---> 12.34 -- No errors and no error return needed.
-- val = to_number("12.34", 1)   ---> {12.34, 0} -- No errors.
-- val = to_number("12.34", -1)  ---> 12.34 -- No errors.
-- val = to_number("12.34a", 1)  ---> {12.34, 6} -- Error at position 6
-- val = to_number("12.34a", -1) ---> {6} -- Error at position 6
-- val = to_number("12.34a")     ---> 0 because its not a valid number
--
-- val = to_number("#f80c")        --> 63500
-- val = to_number("#f80c.7aa")    --> 63500.47900390625
-- val = to_number("@1703")        --> 963
-- val = to_number("!101101")      --> 45
-- val = to_number("12_583_891")   --> 12583891
-- val = to_number("12_583_891%")  --> 125838.91
-- val = to_number("12,583,891%%") --> 12583.891
-- </eucode>


public function to_number( sequence text_in, integer return_bad_pos = 0)
	-- get the numeric result of text_in
	integer lDotFound = 0
	integer lSignFound = 2
	integer lCharValue
	integer lBadPos = 0
	atom    lLeftSize = 0
	atom    lRightSize = 1
	atom    lLeftValue = 0
	atom    lRightValue = 0
	integer lBase = 10
	integer lPercent = 1
	atom    lResult
	integer lDigitCount = 0
	integer lCurrencyFound = 0
	integer lLastDigit = 0
	integer lChar

	for i = 1 to length(text_in) do
		if not integer(text_in[i]) then
			exit
		end if

		lChar = text_in[i]
		switch lChar do
			case '-' then
				if lSignFound = 2 then
					lSignFound = -1
					lLastDigit = lDigitCount
				else
					lBadPos = i
				end if

			case '+' then
				if lSignFound = 2 then
					lSignFound = 1
					lLastDigit = lDigitCount
				else
					lBadPos = i
				end if

			case '#' then
				if lDigitCount = 0 and lBase = 10 then
					lBase = 16
				else
					lBadPos = i
				end if

			case '@' then
				if lDigitCount = 0  and lBase = 10 then
					lBase = 8
				else
					lBadPos = i
				end if

			case '!' then
				if lDigitCount = 0  and lBase = 10 then
					lBase = 2
				else
					lBadPos = i
				end if

			case '$', '£', '¤', '¥', '€' then
				if lCurrencyFound = 0 then
					lCurrencyFound = 1
					lLastDigit = lDigitCount
				else
					lBadPos = i
				end if

			case '_' then -- grouping character
				if lDigitCount = 0 or lLastDigit != 0 then
					lBadPos = i
				end if

			case '.', ',' then
				if lLastDigit = 0 then
					if decimal_mark = lChar then
						if lDotFound = 0 then
							lDotFound = 1
						else
							lBadPos = i
						end if
					else
						-- Ignore it
					end if
				else
					lBadPos = i
				end if

			case '%' then
				lLastDigit = lDigitCount
				if lPercent = 1 then
					lPercent = 100
				else
					if text_in[i-1] = '%' then
						lPercent *= 10 -- Yes ten not one hundred.
					else
						lBadPos = i
					end if
				end if
				
			case '\t', ' ', #A0 then
				if lDigitCount = 0 then
					-- skip it
				else
					lLastDigit = i
				end if

			case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
			      'A', 'B', 'C', 'D', 'E', 'F',
			      'a', 'b', 'c', 'd', 'e', 'f' then
	            lCharValue = find(lChar, vDigits) - 1
	            if lCharValue > 15 then
	            	lCharValue -= 6
	            end if

	            if lCharValue >= lBase then
	                lBadPos = i

	            elsif lLastDigit != 0 then  -- shouldn't be any more digits
					lBadPos = i

				elsif lDotFound = 1 then
					lRightSize *= lBase
					lRightValue = (lRightValue * lBase) + lCharValue
					lDigitCount += 1
				else
					lLeftSize += 1
					lLeftValue = (lLeftValue * lBase) + lCharValue
					lDigitCount += 1
				end if

			case else
				lBadPos = i

		end switch

		if lBadPos != 0 then
			exit
		end if
	end for


	-- Error if no actual digits where converted.
	if lBadPos = 0 and lDigitCount = 0 then
		lBadPos = 1
	end if

	if return_bad_pos = 0 and lBadPos != 0 then
		return 0
	end if

	if lRightValue = 0 then
		-- Common situation optimised for speed.
	    if lPercent != 1 then
			lResult = (lLeftValue / lPercent)
		else
	        lResult = lLeftValue
		end if
	else
	    if lPercent != 1 then
	        lResult = (lLeftValue  + (lRightValue / (lRightSize))) / lPercent
	    else
	        lResult = lLeftValue + (lRightValue / lRightSize)
	    end if
	end if

	if lSignFound < 0 then
		lResult = -lResult
	end if

	if return_bad_pos = 0 then
		return lResult
	end if

	if return_bad_pos = -1 then
		if lBadPos = 0 then
			return lResult
		else
			return {lBadPos}	
		end if
	end if
	
	return {lResult, lBadPos}

end function

--**
-- converts an object into a integer.
--
-- Parameters:
-- # ##data_in## : Any Euphoria object.
-- # ##def_value## : An integer. This is returned if ##data_in## cannot be converted
--                into an integer. If omitted, zero is returned.
--
-- Returns:
-- An **integer**, either the integer rendition of ##data_in## or ##def_value## if it has
-- no integer value.
--
-- Comments:
-- The returned value is guaranteed to be a valid Euphoria integer.
--
-- Example 1:
-- <eucode>
-- ? to_integer(12)            --> 12
-- ? to_integer(12.4)          --> 12
-- ? to_integer("12")          --> 12
-- ? to_integer("12.9")        --> 12
--
-- ? to_integer("a12")         --> 0 (not a valid number)
-- ? to_integer("a12",-1)      --> -1 (not a valid number)
-- ? to_integer({"12"})        --> 0 (sub-sequence found)
-- ? to_integer(#3FFFFFFF)     --> 1073741823
-- ? to_integer(#3FFFFFFF + 1) --> 0 (too big for a Euphoria integer)
-- </eucode>

public function to_integer(object data_in, integer def_value = 0)
	if integer(data_in) then
		return data_in
	end if

	if atom(data_in) then
		data_in = floor(data_in)
		if not integer(data_in) then
			return def_value
		end if
		return data_in
	end if

	sequence lResult = to_number(data_in, 1)
	if lResult[2] != 0 then
		return def_value
	else
		return floor(lResult[1])
	end if

end function

--**
-- converts an object into a text string.
--
-- Parameters:
-- # ##data_in## : Any Euphoria object.
-- # ##string_quote## : An integer. If not zero (the default) this will be used to
--   enclose ##data_in##, if it is already a string. 
-- # ##embed_string_quote## : An integer. This will be used to
--   enclose any strings embedded inside ##data_in##. The default is '"'
--
-- Returns:
-- A **sequence**. This is the string repesentation of ##data_in##.
--
-- Comments:
-- * The returned value is guaranteed to be a displayable text string.
-- * ##string_quote## is only used if ##data_in## is already a string. In this case,
--   all occurances of ##string_quote## already in ##data_in## are prefixed with
--   the '\' escape character, as are any preexisting escape characters. Then 
--   ##string_quote## is added to both ends of ##data_in##, resulting in a quoted
--   string.
-- * ##embed_string_quote## is only used if ##data_in## is a sequence that contains
--   strings. In this case, it is used as the enclosing quote for embedded strings.
--
-- Example 1:
-- <eucode>
-- include std/console.e
-- display(to_string(12))           --> 12
-- display(to_string("abc"))        --> abc
-- display(to_string("abc",'"'))    --> "abc"
-- display(to_string(`abc\"`,'"'))  --> "abc\\\""
-- display(to_string({12,"abc",{4.5, -99}}))    --> {12, "abc", {4.5, -99}}
-- display(to_string({12,"abc",{4.5, -99}},,0)) --> {12, abc, {4.5, -99}}
-- </eucode>

public function to_string(object data_in, integer string_quote = 0, integer embed_string_quote = '"')
	sequence data_out
	
	if types:string(data_in) then
		if string_quote = 0 then
			return data_in
		end if
		data_in = search:match_replace(`\`, data_in, `\\`)
		data_in = search:match_replace({string_quote}, data_in, `\` & string_quote)
		return string_quote & data_in & string_quote
	end if
	
	if atom(data_in) then
		if integer(data_in) then
			return sprintf("%d", data_in)
		end if
		data_in = text:trim_tail(sprintf("%.15f", data_in), '0')
		if data_in[$] = '.' then
			data_in = remove(data_in, length(data_in))
		end if
		return data_in
	end if
	
	data_out = "{"
	for i = 1 to length(data_in) do
		data_out &= to_string(data_in[i], embed_string_quote)
		if i != length(data_in) then
			data_out &= ", "
		end if
	end for
	data_out &= '}'
	
	return data_out
end function

