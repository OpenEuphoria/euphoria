-- (c) Copyright - See License.txt
--
namespace unicode
--****
-- == Unicode
--
-- Unicode is not complete. This API will change, even in 4.1 release.
--
--
-- By default, Euphoria strings contain UCS-4 code points (characters).
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>

-- References: 
--   http://www.unicode.org/
--   http://en.wikipedia.org/wiki/Unicode

--**
-- Tests if a value is a valid code point.
--
-- Parameters:
-- # ##test_char## : an object, the value to test.
-- # ##is_strict##: an integer, if non-zero then non-character code points are
--                rejected. The default (zero) means that non-character code
--                points are accepted. 
--
-- Returns:
--   An integer. 1 means that ##test_char## is valid and 0 means that it is not.
--
-- Example:
-- <eucode>
-- for i = 1 to length(s) do
--    if not isUChar(s[i]) then
--       return 0 -- String is not a utf-32 string.
--    end if
-- end for
-- </eucode>
public function isUChar(object test_char, integer is_strict = 0)
-- Valid code points ranges are ...
--    U+0000 to U+D7FF
--    U+E000 to U+10FFFF
-- however there are 66 specific non-character codes that applicaitons are
-- allowed to use but these will never be officially encoded characters.
-- They are U+FDD0 to U+FDEF, and any value ending in either 0xFFFE or 0xFFFF.

	if not atom(test_char) then
		return 0
	end if
	
    if test_char < 0xD800 then
    	return 1
    end if
    
    if test_char < 0xE000 then
    	return 0
    end if
    
    if is_strict then
    	-- Disallow non-character code points.
    	if test_char < 0xFDD0 then
    		return 1
    	end if
    	if test_char < 0xFDEF then
    		return 0
    	end if 

    	if and_bits(test_char,0xFFFF) >= 0xFFFE then
    		return 0
    	end if
    end if
    
    if test_char < 0x11_0000 then
    	return 1
    end if
    
    return 0
end function

constant utf8_seqlen = x"
 1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1 
 1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1 
 1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1 
 1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1 
 1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1 
 1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1 
 1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1 
 1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1 
FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF 
FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF 
FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF 
FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF 
 2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2 
 2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2 
 3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3 
 4  4  4  4  4  4  4  4  5  5  5  5  6  6 FF FF 
"

public enum
	utf_8,
	utf_16,
	utf_32

public constant BOM_8 = x"efbbbf",
				BOM = {#feff}
	
--**
-- Returns the length of an encoded UTF sequence.
--
-- Parameters:
-- # ##input_string## : a sequence. Contains a UTF encoded string.
-- # ##from_index##: an integer. The index of a code sequence starting point in ##input_string##.
-- # ##encoding_format##: One of ##utf_8##, ##utf_16##, or ##utf_32##. The default is ##utf_8##.
--
-- Returns:
--   An integer. The number of elements in ##input_string##, starting from ##from_index## that
-- form the code sequence. If 255 (0xFF) is returned, it means that either ##from_index## was
-- not at the start of a code sequence, or an invalid ##encoding_format## parameter was
-- supplied.
--
-- Example:
-- <eucode>
-- ? get_seqlen("abc", 2) --> 1
-- </eucode>
public function get_seqlen(sequence input_string, integer from_index, integer encoding_format=utf_8)
	object lChar = input_string[from_index]
	
	if not integer(lChar) or
	   lChar < 0 then
		return 0xFF
	end if
	
	switch encoding_format do
    	case utf_8 then
    		if lChar > 255 then
    			return 0xFF
    		end if
    		return utf8_seqlen[lChar + 1]
    		
    	case utf_16 then
			if lChar < 0xD800 then return 1 end if
			if lChar < 0xDC00 then return 2 end if
			if lChar < 0xE000 then return 0xFF end if
			if lChar < 0x1_0000 then return 1 end if
    		return 0xFF 
    	
    	case utf_32 then
    		if isUChar(lChar) then return 1 end if
    		return 0xFF
    		
    	case else
    		return 0xFF
    end switch
end function

--**
-- Returns the length of an encoded UTF sequence.
--
-- Parameters:
-- # ##input_string## : a sequence. Contains a UTF encoded string.
-- # ##from_index##: an integer. The index of a code sequence starting point in ##pString##.
-- # ##encoding_format##: One of ##utf_8##, ##utf_16##, or ##utf_32##. The default is ##utf_8##.
--
-- Returns:
--   An integer. The number of UCS characters in ##input_string## that occur before
-- ##from_index##. However, if ##from_index## is invalid it returns -1, and if an invalid
-- UTF sequence is found, it returns -2.
--
-- Example:
-- <eucode>
-- ? chars_before(x"7a C2A9 E6B0B4 F09d849e", 4) --> 2
-- </eucode>
public function chars_before(sequence input_string, integer from_index, integer encoding_format = utf_8)
	if from_index < 1 or from_index > length(input_string) then
		return -1
	end if
	
	integer cnt = 0
	integer i = 1
	while i < from_index do
		atom nxt
		cnt += 1
		nxt = get_seqlen(input_string, i, encoding_format)
		if nxt = 0xFF then
			return -2
		end if
		i += nxt
	end while
	
	return cnt
	
end function

--**
-- Returns the number of UCS characters in a UTF string.
--
-- Parameters:
-- # ##input_string## : a sequence. Contains a UTF encoded string.
-- # ##encoding_format##: One of ##utf_8##, ##utf_16##, or ##utf_32##. The default is ##utf_8##.
--
-- Returns:
--   An integer. The number of UCS characters in ##input_string##. However, if an 
-- invalid UTF sequence is found it returns -2.
--
-- Example:
-- <eucode>
-- ? char_count(x"7a C2A9 E6B0B4 F09d849e") --> 4
-- </eucode>

public function char_count(sequence input_string, integer encoding_format = utf_8)
	integer cnt = 0
	integer i = 1
	while i <= length(input_string) do
		atom nxt
		cnt += 1
		nxt = get_seqlen(input_string, i, encoding_format)
		if nxt = 0xFF then
			return -2
		end if
		i += nxt
	end while
	
	return cnt
	
end function

--**
-- Returns the UCS character from a specific location in a UTF string
--
-- Parameters:
-- # ##input_string## : a sequence. Contains a UTF encoded string.
-- # ##from_index##: an integer. The index of a code sequence starting point in ##input_string##.
-- # ##encoding_format##: One of ##utf_8##, ##utf_16##, or ##utf_32##. The default is ##utf_8##.
-- # ##is_strict##:an integer. If non-zero, then non-character code points are deemed
-- to be invalid characters. The default is zero, which allows non-character code points.
--
-- Returns:
-- * If ##from_index## points to a valid character then a sequence is returned. The first
-- element is the code point value of the encoded USC character in ##input_string##
-- at ##from_index##, and the second element is the index of the next character in ##input_string##. 
-- * If ##from_index## does not point to a valid character then an integer is returned.
-- ** 1 An element in the coded character is invalid.
-- ** 2 In utf_8 encodings, the leading encoded byte is not valid.
-- ** 3 The value of ##from_index## is invalid or the length of ##input_string## is too short.
-- ** 4 In utf_8 encodings, the non-leading byte is not valid
-- ** 5 The UCS character is not a valid one.
-- ** 6 The ##encoding_format## parameter is not valid
-- ** 7 For utf_16 encodings, the leading surrogate is invalid
-- ** 8 For utf_16 encodings, the trailing surrogate is invalid
--
-- Example:
-- <eucode>
-- ? get_char(u"d834 dd1e", 1, utf_16) --> 0x1D11E
-- </eucode>
public function get_char(sequence input_string, integer from_index, integer encoding_format = utf_8, integer is_strict = 0)
	atom lUCS_char
    integer lNextIdx
    object lCodePart
	integer lCodeLen
    
	if from_index < 1 or from_index > length(input_string) then
		return 3
	end if

	lCodePart = input_string[from_index]
	
	switch encoding_format do
		case utf_8 then
		    if not integer(lCodePart) or lCodePart > 255 or lCodePart < 0 then
		    	return 1
		    end if
		    
		    -- The first part of a valid UTF-8 sequence must be a bit pattern
		    -- matching one of ...
		    --  0b0xxxxxxx
		    --  0b110xxxxx
		    --  0b1110xxxx
		    --  0b11110xxx
		    --  0b111110xx
		    --  0b1111110x
			if    and_bits(lCodePart, 0b1000_0000) = 0b0000_0000 then
				lUCS_char = and_bits(lCodePart, 0b0111_1111)
				lCodeLen = 1
				
			elsif and_bits(lCodePart, 0b1110_0000) = 0b1100_0000 then
				lUCS_char = and_bits(lCodePart, 0b0001_1111)
				lCodeLen = 2
				
			elsif and_bits(lCodePart, 0b1111_0000) = 0b1110_0000 then
				lUCS_char = and_bits(lCodePart, 0b0000_1111)
				lCodeLen = 3
				
			elsif and_bits(lCodePart, 0b1111_1000) = 0b1111_0000 then
				lUCS_char = and_bits(lCodePart, 0b0000_0111)
				lCodeLen = 4
				
			-- The 5 and 6 bytes encodings are not supported yet.
-- 			elsif and_bits(lCodePart, 0b1111_1100) = 0b1111_1000 then
-- 				lUCS_char = and_bits(lCodePart, 0b0000_0011)
-- 				lCodeLen = 5
-- 				
-- 			elsif and_bits(lCodePart, 0b1111_1110) = 0b1111_1100 then
-- 				lUCS_char = and_bits(lCodePart, 0b0000_0001)
-- 				lCodeLen = 6
				
			else
		    	return 2
			end if
			
			lNextIdx = from_index + lCodeLen
			
			while lCodeLen > 1 do
				-- Subsequent parts of a utf_8 sequence must be a bit pattern
				-- matching 0b10xxxxxx
				lCodeLen -= 1
				from_index += 1
				if from_index > length(input_string) then
					return 3
				end if
				lCodePart = input_string[from_index]
		    	if not integer(lCodePart) or lCodePart > 255 or lCodePart < 0 then
					return 1
				end if
				
				if and_bits(lCodePart, 0b1100_0000) != 0b1000_0000 then
					return 4
				end if
				
				lUCS_char *= 0b0100_0000 
				lCodePart = and_bits(lCodePart, 0b0011_1111)
				lUCS_char += lCodePart
			end while
			
		case utf_16 then
			
		    if not integer(lCodePart) or lCodePart > 0xFFFF or lCodePart < 0 then
		    	return 1
		    end if
		    
		    if lCodePart < 0xD800 then
		    	return {lCodePart, from_index + 1}
		    end if
		    
		    if lCodePart > 0xDFFF then
		    	lNextIdx = from_index + 1
		    	lUCS_char = lCodePart
			else		    
			    lNextIdx = from_index + 2
			    if lCodePart > 0xDBFF then
			    	return 7 -- Invalid surrogate leader.
			    end if
			    
			    lUCS_char = and_bits(lCodePart, 0x03FF) * 0x0400
			    
			    from_index += 1
			    if from_index > length(input_string) then
			    	return 3
			    end if
			    
			    lCodePart = input_string[from_index]
			    if not integer(lCodePart) or lCodePart > 0xFFFF or lCodePart < 0 then
			    	return 1
			    end if
			    
			    if lCodePart < 0xDC00 then
			    	return 8 -- Invalid surrogate trailer.
			    end if
			  
			    lUCS_char += and_bits(lCodePart, 0x03FF)
			    
			    lUCS_char += 0x10000
		    end if
		    
		case utf_32 then
		    if not integer(lCodePart) or lCodePart < 0 then
		    	return 1
		    end if
		    
	    	lNextIdx = from_index + 1
	    	lUCS_char = lCodePart
		    
			
		case else
			return 6
	end switch
	    
	if not isUChar(lUCS_char, is_strict) then
		return 5
	end if
    return {lUCS_char, lNextIdx}
end function



--**
-- Returns the UTF string representation of a UCS character (code point)
--
-- Parameters:
-- # ##ucs_char## : An atom. The UCS character, also known as a code point, to encode.
-- # ##encoding_format##: The format at return. One of ##utf_8##, ##utf_16##, or ##utf_32##.
--  The default is ##utf_8##.
--
-- Returns:
-- A sequence. The UTF encoding form of the ##ucs_char##. Note that if the UCS
-- value supplied if not a valid character, or ##encoding_format## is invalid, an empty
-- sequence is returned.
--
-- Example:
-- <eucode>
-- atom G_Clef = 0x1d11e
-- ? encode(G_Clef, utf_8)) --> x"f09d849e"
-- </eucode>
public function encode(atom ucs_char, integer encoding_format = utf_8)
	if not isUChar(ucs_char) then
		return ""
	end if

	if encoding_format = utf_8 then
		if ucs_char <= 0x7F then
			return {ucs_char}
		end if
		
		if ucs_char <= 0x7FF then
			return {
				(0xC0 + floor(ucs_char / 0b100_0000)),
				(0x80 + and_bits(ucs_char, 0b0011_1111))
			}
		end if
		
		if (ucs_char <= 0xFFFF) then
			return {
				(0xE0 + floor(ucs_char / 0b1_0000_0000_0000)),
				(0x80 + and_bits(ucs_char / 0b100_0000, 0b0011_1111)),
				(0x80 + and_bits(ucs_char, 0b0011_1111))
			}
		end if
		
		return {
			(0xF0 + floor(ucs_char / 0b100_0000_0000_0000_0000)),
			(0x80 + and_bits(ucs_char / 0b1_0000_0000_0000, 0b0011_1111)),
			(0x80 + and_bits(ucs_char / 0b100_0000, 0b0011_1111)),
			(0x80 + and_bits(ucs_char, 0b0011_1111))
		}
	end if

	if encoding_format = utf_16 then
		if ucs_char <= 0xFFFF then
			return {ucs_char}
		end if
		return {
			and_bits(((ucs_char - 0x10000) / 0b100_0000_0000),0x3FF) + 0xD800,
			and_bits((ucs_char - 0x10000), 0x3FF) + 0xDC00
		}
	end if
			
	
	if encoding_format = utf_32 then
		return {ucs_char}
	end if
	
	return ""
			
end function

--**
-- Returns the length of the UTF string representation of a UCS character (code point)
--
-- Parameters:
-- # ##ucs_char## : An atom. The UCS character, also known as a code point.
-- # ##encoding_format##: The format at return. One of ##utf_8##, ##utf_16##, or ##utf_32##.
--  The default is ##utf_8##.
--
-- Returns:
-- An integer. The number of elements to make up the UTF encoded form of 
-- ##ucs_char##. Note that if the UCS value supplied if not a valid character, 
-- or ##encoding_format## is invalid, zero is returned.
--
-- Example:
-- <eucode>
-- atom G_Clef = 0x1d11e
-- ? encode(G_Clef, utf_8)) --> 4
-- </eucode>
public function code_length(atom ucs_char, integer encoding_format = utf_8)
	if not isUChar(ucs_char) then
		return 0
	end if

	if encoding_format = utf_8 then
		if ucs_char <= 0x7F then
			return 1
		end if
		
		if ucs_char <= 0x7FF then
			return 2
		end if
		
		if (ucs_char <= 0xFFFF) then
			return 3
		end if
		
		return 4
	end if

	if encoding_format = utf_16 then
		if ucs_char <= 0xFFFF then
			return 1
		end if
		return 2
	end if
			
	
	if encoding_format = utf_32 then
		return 1
	end if
	
	return 0
			
end function

--**
-- Returns the UTF string representation of a UCS character (code point)
--
-- Parameters:
-- # ##input_string## : A sequence. The UTF encoded text to validate.
-- # ##encoding_format##: The format of ##input_string##. One of ##utf_8##, ##utf_16##, or ##utf_32##.
--  The default is ##utf_8##.
-- # ##is_strict##:an integer. If non-zero, then non-character code points are deemed
-- to be invalid characters. The default is zero, which allows non-character code points.
--
-- Returns:
--   An integer. 
-- * 0 means that the text is valid for the given format. 
-- * n>0 is the index into ##input_string## where the first invalid element was found.
--
-- Example:
-- <eucode>
-- ? validate(x"7aE289", utf_8) --> 2
-- </eucode>
public function validate(object input_string, integer encoding_format = utf_8, integer is_strict = 0)
	object lPos
	integer lIdx
	
	if not sequence(input_string) then
		return -1
	end if
	lPos = {0,1}
	lIdx = 1
	while sequence(lPos) do
		if lPos[2] > length(input_string) then
			return 0
		end if
		lIdx = lPos[2]
		lPos = get_char(input_string, lIdx, encoding_format, is_strict)
	end while
	
	return lIdx
end function

--**
-- Converts the UTF encoding of the given text to another UTF encoding format.
--
-- Parameters:
-- # ##input_string## : A sequence. The UTF encoded text to convert.
-- # ##source_encoding##: The format of ##input_string##. One of ##utf_8##, ##utf_16##, or ##utf_32##.
--  The default is ##utf_32##.
-- # ##result_encoding##: The format of returned result. One of ##utf_8##, ##utf_16##, or ##utf_32##.
--  The default is ##utf_8##.
--
-- Returns:
-- * If ##input_string## is not a valid UTF string, this returns the index into it
-- where the first invalid element was found.
-- * Otherwise it returns a sequence, which is the converted form of ##input_string##.
--
-- Example:
-- <eucode>
-- ? toUTF(x"7a C2A9 E6B0B4 F09d849e", utf_8, utf_16)) --> u"7a A9 6c34 d834 dd1e"
-- </eucode>
public function toUTF( sequence input_string, integer source_encoding = utf_32, integer result_encoding = utf_8)

	sequence lResult
	integer lIdx
	sequence lChar
	sequence lInChar
	
	lIdx = validate(input_string, source_encoding)
	if lIdx != 0 then
		return lIdx
	end if
	
	if source_encoding = result_encoding then
		return input_string
	end if
	
	lResult = repeat(0, length(input_string) * 4)
	lIdx = 1

	lInChar = {0,1}
	while lInChar[2] <= length(input_string) do
		lInChar = get_char(input_string, lInChar[2], source_encoding)
		lChar = encode(lInChar[1], result_encoding)
		lResult[lIdx .. lIdx + length(lChar) - 1] = lChar
		lIdx += length(lChar)
	end while
			
	return lResult[1 .. lIdx-1]
	
end function

