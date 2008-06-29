-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Extended Types
--
-- === Constants
--

--** 
-- Boolean FALSE value

export constant FALSE = 0

--**
-- Boolean TRUE value

export constant TRUE = 1

--****
-- === Support Functions
--

--** 
-- Returns TRUE if pVal is a character or sequence of characters in 
-- the character set defined by pCharSet.
--
-- pCharset is either a simple sequence of characters eg. "qwertyuiop[]\\"
-- or a sequence of character pairs, which represent allowable ranges
-- of characters. eg. Alphabetic is defined as {{'a','z'}, {'A', 'Z'}}
--
-- Example 1:
-- <eucode>
-- char_test("ABCD", {{'A', 'D'}})    
-- -- TRUE, every char is in the range 'A' to 'D'
--
-- char_test("ABCD", {{'A', 'C'}})
-- -- FALSE, not every char is in the range 'A' to 'C'
--
-- char_test("Harry", {{'a', 'z'}, {'D', 'J'}}) 
-- -- TRUE, every char is either in the range 'a' to 'z', or in the range 'D' to 'J'
-- 
-- char_test("Potter", "novel") 
-- -- FALSE, not every character is in the set 'n', 'o', 'v', 'e', 'l'
-- </eucode>

export function char_test(object pVal, sequence pCharSet)
	integer lChr
	
	if integer(pVal) then
		if sequence(pCharSet[1]) then
			for j = 1 to length(pCharSet) do
				if pVal >= pCharSet[j][1] and pVal <= pCharSet[j][2] then return TRUE end if 
			end for
			return FALSE
		else
			return find(pVal, pCharSet) > 0
		end if
	elsif sequence(pVal) then
		if length(pVal) = 0 then return FALSE end if
		for i = 1 to length(pVal) label "NXTCHR" do
			if sequence(pVal[i]) then return FALSE end if
			if not integer(pVal[i]) then return FALSE end if
			lChr = pVal[i]
			if sequence(pCharSet[1]) then
				for j = 1 to length(pCharSet) do
					if lChr >= pCharSet[j][1] and lChr <= pCharSet[j][2] then continue "NXTCHR" end if 
				end for
			else
				if find(lChr, pCharSet) > 0 then continue "NXTCHR" end if
			end if
			return FALSE
		end for	
		return TRUE
	else
		return FALSE
	end if
end function

sequence Defined_Sets

export enum
	CS_FIRST = 0,
	CS_Consonant,
	CS_Vowel,
	CS_Hexadecimal,
	CS_Whitespace,
	CS_Punctuation,
	CS_Printable,
	CS_Lowercase,
	CS_Uppercase,
	CS_Alphanumeric ,
	CS_Alphabetic ,
	CS_ASCII,
	CS_Control,
	CS_Digit,
	CS_Graphic,
	CS_Bytes,
	CS_LAST


--** 
-- Sets all the defined character sets to their default definitions.
--
-- Example 1:
-- <eucode>
-- set_default_charsets()
-- </eucode>

export procedure set_default_charsets()
	Defined_Sets = repeat(0, CS_LAST - CS_FIRST - 1)
	Defined_Sets[CS_Alphabetic	] = {{'a', 'z'}, {'A', 'Z'}}
	Defined_Sets[CS_Alphanumeric] = {{'0', '9'}, {'a', 'z'}, {'A', 'Z'}}
	Defined_Sets[CS_Uppercase 	] = {{'A', 'Z'}}
	Defined_Sets[CS_Lowercase 	] = {{'a', 'z'}}
	Defined_Sets[CS_Printable 	] = {{' ', '~'}}
	Defined_Sets[CS_Whitespace 	] = " \t\n\r" & 11 & 160
	Defined_Sets[CS_Consonant 	] = "bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ"
	Defined_Sets[CS_Vowel 		] = "aeiouAEIOU"
	Defined_Sets[CS_Hexadecimal ] = {{'0', '9'}, {'A', 'F'},{'a', 'f'}}
	Defined_Sets[CS_Punctuation ] = {{' ', '/'}, {':', '?'}, {'[', '`'}, {'{', '~'}}
	Defined_Sets[CS_Control 	] = {{0, 31}, {127, 127}}
	Defined_Sets[CS_ASCII 		] = {{0, 127}}
	Defined_Sets[CS_Digit 		] = {{'0', '9'}}
	Defined_Sets[CS_Graphic 	] = {{'!', '~'}}
	Defined_Sets[CS_Bytes	 	] = {{0, 255}}
end procedure

--** 
-- Gets the definition for each of the defined character sets.
--
-- The returned value is a sequence of pairs. The first element of each pair
-- is the character set id , eg. CS_Whitespace, and the second is the definition
-- of that character set.
--
-- This is the same format required for the set_charsets() routine.
--
-- Example 1:
-- <eucode>
-- sequence sets
-- sets = get_charsets()
-- </eucode>

export function get_charsets()
	sequence lResult
	
	lResult = {}
	for i = CS_FIRST + 1 to CS_LAST - 1 do
		lResult = append(lResult, {i, Defined_Sets[i]} )
	end for
	
	return lResult
end function

--** 
-- Sets the definition for one or more defined character sets.
--
-- The argument must be a sequence of pairs. The first element of each pair
-- is the character set id , eg. CS_Whitespace, and the second is the definition
-- of that character set.
--
-- This is the same format returned by the get_charsets() routine.
--
-- Example 1:
-- <eucode>
-- set_charsets({{CS_Whitespace, " \t"}})
-- t_space('\n') --> FALSE
-- </eucode>

export procedure set_charsets(sequence pSets)	
	for i = 1 to length(pSets) do
		if sequence(pSets[i]) and length(pSets[i]) = 2 then
			if integer(pSets[i][1]) and pSets[i][1] > CS_FIRST and pSets[i][1] < CS_LAST then
				Defined_Sets[pSets[i][1]] = pSets[i][2]
			end if
		end if
	end for
end procedure

--***
-- === Types
--

--** 
-- Returns TRUE if argument is an atom or if every element of the argument
-- is an atom.
--
-- Returns FALSE if the argument is an empty sequence or contains sequences.
--
-- Example 1:
-- <eucode>
-- boolean(-1)            -- TRUE
-- boolean(0)             -- TRUE 
-- boolean(1)             -- TRUE
-- boolean(1.234)         -- TRUE
-- boolean('A')           -- TRUE
-- boolean('9')           -- TRUE
-- boolean('?')           -- TRUE
-- boolean("abc")         -- TRUE (every element is an atom)
-- boolean("ab3")         -- TRUE
-- boolean({1,2,"abc"})   -- FALSE (contains a sequence)
-- boolean({1, 2, 9.7)    -- TRUE
-- boolean({})            -- FALSE (empty sequence)
-- </eucode>
	
export type boolean(object pVal)
	-- A boolean is a value that is either zero or not zero.
	if atom(pVal) then
		return TRUE
	end if
	for i = 1 to length(pVal) do
		if sequence(pVal[i]) then
			return FALSE
		end if
	end for
	return length(pVal) > 0
	
end type

--** 
-- Returns TRUE if argument is an alphanumic character or if every element of 
-- the argument is an alphanumic character.
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains non-alphanumeric elements
--
-- Example 1:
-- <eucode>
-- t_alnum(-1)            -- FALSE
-- t_alnum(0)             -- FALSE 
-- t_alnum(1)             -- FALSE
-- t_alnum(1.234)         -- FALSE
-- t_alnum('A')           -- TRUE
-- t_alnum('9')           -- TRUE
-- t_alnum('?')           -- FALSE
-- t_alnum("abc")         -- TRUE (every element is alphabetic or a digit)
-- t_alnum("ab3")         -- TRUE
-- t_alnum({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_alnum({1, 2, 9.7)    -- FALSE (contains a non-integer)
-- t_alnum({})            -- FALSE (empty sequence)
-- </eucode>

export type t_alnum(object pVal)
	return char_test(pVal, Defined_Sets[CS_Alphanumeric])
end type

--** 
-- Returns TRUE if argument is an alphabetic character or if every element of 
-- the argument is an alphabetic character.
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains non-alphabetic elements
--
-- Example 1:
-- <eucode>
-- t_alnum(-1)            -- FALSE
-- t_alpha(0)             -- FALSE 
-- t_alpha(1)             -- FALSE
-- t_alpha(1.234)         -- FALSE
-- t_alpha('A')           -- TRUE
-- t_alpha('9')           -- FALSE
-- t_alpha('?')           -- FALSE
-- t_alpha("abc")         -- TRUE (every element is alphabetic)
-- t_alpha("ab3")         -- FALSE
-- t_alpha({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_alpha({1, 2, 9.7)    -- FALSE (contains a non-integer)
-- t_alpha({})            -- FALSE (empty sequence)
-- </eucode>

export type t_alpha(object pVal)
	return char_test(pVal, Defined_Sets[CS_Alphabetic])
end type

--** 
-- Returns TRUE if argument is an ASCII character or if every element of 
-- the argument is an ASCII character.
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains non-ASCII elements
--
-- Example 1:
-- <eucode>
-- t_ascii(-1)            -- FALSE
-- t_ascii(0)             -- TRUE 
-- t_ascii(1)             -- TRUE
-- t_ascii(1.234)         -- FALSE
-- t_ascii('A')           -- TRUE
-- t_ascii('9')           -- TRUE
-- t_ascii('?')           -- TRUE
-- t_ascii("abc")         -- TRUE (every element is ascii)
-- t_ascii("ab3")         -- TRUE
-- t_ascii({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_ascii({1, 2, 9.7)    -- FALSE (contains a non-integer)
-- t_ascii({})            -- FALSE (empty sequence)
-- </eucode>

export type t_ascii(object pVal)
	return char_test(pVal, Defined_Sets[CS_ASCII])
end type

--** 
-- Returns TRUE if argument is an Control character or if every element of 
-- the argument is an Control character.
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains non-Control elements
--
-- Example 1:
-- <eucode>
-- t_cntrl(-1)            -- FALSE
-- t_cntrl(0)             -- TRUE 
-- t_cntrl(1)             -- TRUE
-- t_cntrl(1.234)         -- FALSE
-- t_cntrl('A')           -- FALSE
-- t_cntrl('9')           -- FALSE
-- t_cntrl('?')           -- FALSE
-- t_cntrl("abc")         -- FALSE (every element is ascii)
-- t_cntrl("ab3")         -- FALSE
-- t_cntrl({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_cntrl({1, 2, 9.7)    -- FALSE (contains a non-integer)
-- t_cntrl({1, 2, 'a')    -- FALSE (contains a non-control)
-- t_cntrl({})            -- FALSE (empty sequence)
-- </eucode>

export type t_cntrl(object pVal)
	return char_test(pVal, Defined_Sets[CS_Control])
end type

--** 
-- Returns TRUE if argument is an digit character or if every element of 
-- the argument is an digit character.
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains non-digits
--
-- Example 1:
-- <eucode>
-- t_digit(-1)            -- FALSE
-- t_digit(0)             -- FALSE 
-- t_digit(1)             -- FALSE
-- t_digit(1.234)         -- FALSE
-- t_digit('A')           -- FALSE
-- t_digit('9')           -- TRUE
-- t_digit('?')           -- FALSE
-- t_digit("abc")         -- FALSE 
-- t_digit("ab3")         -- FALSE
-- t_digit("123")         -- TRUE
-- t_digit({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_digit({1, 2, 9.7)    -- FALSE (contains a non-integer)
-- t_digit({1, 2, 'a')    -- FALSE (contains a non-digit)
-- t_digit({})            -- FALSE (empty sequence)
-- </eucode>

export type t_digit(object pVal)
	return char_test(pVal, Defined_Sets[CS_Digit])
end type

--** 
-- Returns TRUE if argument is a glyph character or if every element of 
-- the argument is a gylph character. (One that is visible when displayed)
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains non-gylph
--
-- Example 1:
-- <eucode>
-- t_graph(-1)            -- FALSE
-- t_graph(0)             -- FALSE 
-- t_graph(1)             -- FALSE
-- t_graph(1.234)         -- FALSE
-- t_graph('A')           -- TRUE
-- t_graph('9')           -- TRUE
-- t_graph('?')           -- TRUE
-- t_graph(' ')           -- FALSE
-- t_graph("abc")         -- TRUE 
-- t_graph("ab3")         -- TRUE
-- t_graph("123")         -- TRUE
-- t_graph({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_graph({1, 2, 9.7)    -- FALSE (contains a non-integer)
-- t_graph({1, 2, 'a')    -- FALSE (control chars (1,2) don't have glyphs)
-- t_graph({})            -- FALSE (empty sequence)
-- </eucode>

export type t_graph(object pVal)
	return char_test(pVal, Defined_Sets[CS_Graphic])
end type

--** 
-- Returns TRUE if argument is a byte or if every element of 
-- the argument is a byte. (Integers from 0 to 255)
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains non-byte
--
-- Example 1:
-- <eucode>
-- t_bytearray(-1)            -- FALSE (contains value less than zero)
-- t_bytearray(0)             -- TRUE
-- t_bytearray(1)             -- TRUE
-- t_bytearray(10)            -- TRUE
-- t_bytearray(100)           -- TRUE
-- t_bytearray(1000)          -- FALSE (greater than 255)
-- t_bytearray(1.234)         -- FALSE (contains a floating number)
-- t_bytearray('A')           -- TRUE
-- t_bytearray('9')           -- TRUE
-- t_bytearray('?')           -- TRUE
-- t_bytearray(' ')           -- TRUE
-- t_bytearray("abc")         -- TRUE 
-- t_bytearray("ab3")         -- TRUE
-- t_bytearray("123")         -- TRUE
-- t_bytearray({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_bytearray({1, 2, 9.7)    -- FALSE (contains a non-integer)
-- t_bytearray({1, 2, 'a')    -- TRUE
-- t_bytearray({})            -- FALSE (empty sequence)
-- </eucode>

export type t_bytearray(object pVal)
	return char_test(pVal, Defined_Sets[CS_Bytes])
end type

--** 
-- Returns TRUE if argument is a lowercase character or if every element of 
-- the argument is an lowercase character.
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains non-lowercase
--
-- Example 1:
-- <eucode>
-- t_lower(-1)            -- FALSE
-- t_lower(0)             -- FALSE 
-- t_lower(1)             -- FALSE
-- t_lower(1.234)         -- FALSE
-- t_lower('A')           -- FALSE
-- t_lower('9')           -- FALSE
-- t_lower('?')           -- FALSE
-- t_lower("abc")         -- TRUE 
-- t_lower("ab3")         -- FALSE
-- t_lower("123")         -- TRUE
-- t_lower({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_lower({1, 2, 9.7)    -- FALSE (contains a non-integer)
-- t_lower({1, 2, 'a')    -- FALSE (contains a non-digit)
-- t_lower({})            -- FALSE (empty sequence)
-- </eucode>

export type t_lower(object pVal)
	return char_test(pVal, Defined_Sets[CS_Lowercase])
end type

--** 
-- Returns TRUE if argument is an displayable character or if every element of 
-- the argument is an displayable character.
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains non-displayable characters.
--
-- Example 1:
-- <eucode>
-- t_print(-1)            -- FALSE
-- t_print(0)             -- FALSE 
-- t_print(1)             -- FALSE
-- t_print(1.234)         -- FALSE
-- t_print('A')           -- TRUE
-- t_print('9')           -- TRUE
-- t_print('?')           -- TRUE
-- t_print("abc")         -- TRUE 
-- t_print("ab3")         -- TRUE
-- t_print("123")         -- TRUE
-- t_print({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_print({1, 2, 9.7)    -- FALSE (contains a non-integer)
-- t_print({1, 2, 'a')    -- FALSE
-- t_print({})            -- FALSE (empty sequence)
-- </eucode>

export type t_print(object pVal)
	return char_test(pVal, Defined_Sets[CS_Printable])
end type

--** 
-- Returns TRUE if argument is an punctuation character or if every element of 
-- the argument is an punctuation character.
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains non-punctuation symbols.
--
-- Example 1:
-- <eucode>
-- t_punct(-1)            -- FALSE
-- t_punct(0)             -- FALSE 
-- t_punct(1)             -- FALSE
-- t_punct(1.234)         -- FALSE
-- t_punct('A')           -- FALSE
-- t_punct('9')           -- FALSE
-- t_punct('?')           -- TRUE
-- t_punct("abc")         -- FALSE 
-- t_punct("(-)")         -- TRUE
-- t_punct("123")         -- TRUE
-- t_punct({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_punct({1, 2, 9.7)    -- FALSE (contains a non-integer)
-- t_punct({1, 2, 'a')    -- FALSE (contains a non-digit)
-- t_punct({})            -- FALSE (empty sequence)
-- </eucode>

export type t_punct(object pVal)
	return char_test(pVal, Defined_Sets[CS_Punctuation])
end type

--** 
-- Returns TRUE if argument is a whitespace character or if every element of 
-- the argument is an whitespace character.
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains non-whitespace character.
--
-- Example 1:
-- <eucode>
-- t_space(-1)            -- FALSE
-- t_space(0)             -- FALSE 
-- t_space(1)             -- FALSE
-- t_space(1.234)         -- FALSE
-- t_space('A')           -- FALSE
-- t_space('9')           -- FALSE
-- t_space('\t')          -- TRUE
-- t_space("abc")         -- FALSE 
-- t_space("123")         -- FALSE
-- t_space({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_space({1, 2, 9.7)    -- FALSE (contains a non-integer)
-- t_space({1, 2, 'a')    -- FALSE (contains a non-digit)
-- t_space({})            -- FALSE (empty sequence)
-- </eucode>

export type t_space(object pVal)
	return char_test(pVal, Defined_Sets[CS_Whitespace])
end type

--** 
-- Returns TRUE if argument is an uppercase character or if every element of 
-- the argument is an uppercase character.
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains non-uppercase characters.
--
-- Example 1:
-- <eucode>
-- t_upper(-1)            -- FALSE
-- t_upper(0)             -- FALSE 
-- t_upper(1)             -- FALSE
-- t_upper(1.234)         -- FALSE
-- t_upper('A')           -- TRUE
-- t_upper('9')           -- FALSE
-- t_upper('?')           -- FALSE
-- t_upper("abc")         -- FALSE 
-- t_upper("ABC")         -- TRUE
-- t_upper("123")         -- FALSE
-- t_upper({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_upper({1, 2, 9.7)    -- FALSE (contains a non-integer)
-- t_upper({1, 2, 'a')    -- FALSE (contains a non-digit)
-- t_upper({})            -- FALSE (empty sequence)
-- </eucode>

export type t_upper(object pVal)
	return char_test(pVal, Defined_Sets[CS_Uppercase])
end type

--** 
-- Returns TRUE if argument is an hexadecimal digit character or if every element of 
-- the argument is an hexadecimal digit character.
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains non-hexadecimal character.
--
-- Example 1:
-- <eucode>
-- t_xdigit(-1)            -- FALSE
-- t_xdigit(0)             -- FALSE 
-- t_xdigit(1)             -- FALSE
-- t_xdigit(1.234)         -- FALSE
-- t_xdigit('A')           -- TRUE
-- t_xdigit('9')           -- TRUE
-- t_xdigit('?')           -- FALSE
-- t_xdigit("abc")         -- TRUE 
-- t_xdigit("fgh")         -- FALSE
-- t_xdigit("123")         -- TRUE
-- t_xdigit({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_xdigit({1, 2, 9.7)    -- FALSE (contains a non-integer)
-- t_xdigit({1, 2, 'a')    -- FALSE (contains a non-digit)
-- t_xdigit({})            -- FALSE (empty sequence)
-- </eucode>

export type t_xdigit(object pVal)
	return char_test(pVal, Defined_Sets[CS_Hexadecimal])
end type

--** 
-- Returns TRUE if argument is a vowel or if every element of 
-- the argument is a vowel character.
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains non-vowels
--
-- Example 1:
-- <eucode>
-- t_vowel(-1)            -- FALSE
-- t_vowel(0)             -- FALSE 
-- t_vowel(1)             -- FALSE
-- t_vowel(1.234)         -- FALSE
-- t_vowel('A')           -- TRUE
-- t_vowel('9')           -- FALSE
-- t_vowel('?')           -- FALSE
-- t_vowel("abc")         -- FALSE 
-- t_vowel("aiu")         -- TRUE
-- t_vowel("123")         -- FALSE
-- t_vowel({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_vowel({1, 2, 9.7)    -- FALSE (contains a non-integer)
-- t_vowel({1, 2, 'a')    -- FALSE (contains a non-digit)
-- t_vowel({})            -- FALSE (empty sequence)
-- </eucode>

export type t_vowel(object pVal)
	return char_test(pVal, Defined_Sets[CS_Vowel])
end type

--** 
-- Returns TRUE if argument is a consonant character or if every element of 
-- the argument is an consonant character.
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains non-consonant character.
--
-- Example 1:
-- <eucode>
-- t_consonant(-1)            -- FALSE
-- t_consonant(0)             -- FALSE 
-- t_consonant(1)             -- FALSE
-- t_consonant(1.234)         -- FALSE
-- t_consonant('A')           -- FALSE
-- t_consonant('9')           -- FALSE
-- t_consonant('?')           -- FALSE
-- t_consonant("abc")         -- FALSE 
-- t_consonant("rTfM")        -- TRUE
-- t_consonant("123")         -- FALSE
-- t_consonant({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_consonant({1, 2, 9.7)    -- FALSE (contains a non-integer)
-- t_consonant({1, 2, 'a')    -- FALSE (contains a non-digit)
-- t_consonant({})            -- FALSE (empty sequence)
-- </eucode>

export type t_consonant(object pVal)
	return char_test(pVal, Defined_Sets[CS_Consonant])
end type

set_default_charsets()
