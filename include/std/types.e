--****
-- == Types - Extended
--
-- <<LEVELTOC level=2 depth=4>>

namespace types

--**
-- Object not assigned
public constant OBJ_UNASSIGNED = 0

--**
-- Object is integer
public constant OBJ_INTEGER = 1

--**
-- Object is atom
public constant OBJ_ATOM = 2

--**
-- Object is sequence
public constant OBJ_SEQUENCE = 3

--****
-- Signature:
-- <built-in> type object(object x)
--
-- Description:
-- returns information about the object type of the supplied argument ##x##.
--
-- Returns:
-- # An **integer**, 
-- ** ##OBJ_UNASSIGNED## if ##x## has not been assigned anything yet.
-- ** ##OBJ_INTEGER## if ##x## holds an integer value.
-- ** ##OBJ_ATOM## if ##x## holds a number that is not an integer.
-- ** ##OBJ_SEQUENCE## if ##x## holds a sequence value.
--
-- Example 1:
-- <eucode>
-- ? object(1) --> OBJ_INTEGER
-- ? object(1.1) --> OBJ_ATOM
-- ? object("1") --> OBJ_SEQUENCE
-- object x
-- ? object(x) --> OBJ_UNASSIGNED
-- </eucode>
--
-- See Also:
-- [[:sequence]], [[:integer]], [[:atom]]

--****
-- Signature:
-- <built-in> type integer(object x)
--
-- Description:
-- tests the supplied argument ##x## to see if it is an integer or not.
--
-- Returns:
-- # An **integer**. 
-- ** 1 if ##x## is an integer.
-- ** 0 if ##x## is not an integer.
--
-- Example 1:
-- <eucode>
-- ? integer(1) --> 1
-- ? integer(1.1) --> 0
-- ? integer("1") --> 0
-- </eucode>
--
-- See Also:
-- [[:sequence]], [[:object]], [[:atom]]

--****
-- Signature:
-- <built-in> type atom(object x)
--
-- Description:
-- tests the supplied argument ##x## to see if it is an atom or not.
--
-- Returns:
-- # An **integer**, 
-- ** 1 if ##x## is an atom.
-- ** 0 if ##x## is not an atom.
--
-- Example 1:
-- <eucode>
-- ? atom(1) --> 1
-- ? atom(1.1) --> 1
-- ? atom("1") --> 0
-- </eucode>
--
-- See Also:
-- [[:sequence]], [[:object]], [[:integer]]

--****
-- Signature:
-- <built-in> type sequence( object x)
--
-- Description:
-- tests the supplied argument ##x## to see if it is a sequence or not.
--
-- Returns:
-- # An **integer*, 
-- ** 1 if ##x## is a sequence.
-- ** 0 if ##x## is not an sequence.
--
-- Example 1:
-- <eucode>
-- ? sequence(1) --> 0
-- ? sequence({1}) --> 1
-- ? sequence("1") --> 1
-- </eucode>
--
-- See Also:
-- [[:integer]], [[:object]], [[:atom]]

--**
-- Boolean FALSE value

public constant FALSE = (1=0)

--**
-- Boolean TRUE value

public constant TRUE = (1=1)

--****
-- === Predefined Character Sets


public enum
	CS_FIRST = 0,	
	CS_Consonant,
	CS_Vowel,
	CS_Hexadecimal,
	CS_Whitespace,
	CS_Punctuation,
	CS_Printable,
	CS_Displayable,
	CS_Lowercase,
	CS_Uppercase,
	CS_Alphanumeric,
	CS_Identifier,
	CS_Alphabetic,
	CS_ASCII,
	CS_Control,
	CS_Digit,
	CS_Graphic,
	CS_Bytes,
	CS_SpecWord,
	CS_Boolean,
	CS_LAST

--****
-- === Support Functions
--

--**
-- determines whether one or more characters are in a given character set.
--
-- Parameters:
-- 		# ##test_data## : an object to test, either a character or a string
--		# ##char_set## : a sequence, either a list of allowable characters, or a list of pairs representing allowable ranges.
--
-- Returns:
--		An **integer**, 1 if all characters are allowed, else 0.
--
-- Comments:
--
-- ##pCharset## is either a simple sequence of characters (such as ##"qwertyuiop[]\"##)
-- or a sequence of character pairs, which represent allowable ranges
-- of characters. For example  Alphabetic is defined as ##{{'a','z'}, {'A', 'Z'}}##.
--
-- To add an isolated character to a character set which is defined using ranges, present it as a range of length 1, like in ##{%,%}##.
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
-- -- TRUE, every char is either in the range 'a' to 'z', 
-- --       or in the range 'D' to 'J'
--
-- char_test("Potter", "novel")
-- -- FALSE, not every character is in the set 'n', 'o', 'v', 'e', 'l'
-- </eucode>

public function char_test(object test_data, sequence char_set)
	integer lChr

	if integer(test_data) then
		if sequence(char_set[1]) then
			for j = 1 to length(char_set) do
				if test_data >= char_set[j][1] and test_data <= char_set[j][2] then 
					return TRUE 
				end if
			end for
			return FALSE
		else
			return find(test_data, char_set) > 0
		end if
	elsif sequence(test_data) then
		if length(test_data) = 0 then 
			return FALSE 
		end if
		for i = 1 to length(test_data) label "NXTCHR" do
			if sequence(test_data[i]) then 
				return FALSE
			end if
			if not integer(test_data[i]) then 
				return FALSE
			end if
			lChr = test_data[i]
			if sequence(char_set[1]) then
				for j = 1 to length(char_set) do
					if lChr >= char_set[j][1] and lChr <= char_set[j][2] then
						continue "NXTCHR" 
					end if
				end for
			else
				if find(lChr, char_set) > 0 then
					continue "NXTCHR"
				end if
			end if
			return FALSE
		end for
		return TRUE
	else
		return FALSE
	end if
end function

sequence Defined_Sets

--**
-- sets all the defined character sets to their default definitions.
--
-- Example 1:
-- <eucode>
-- set_default_charsets()
-- </eucode>

public procedure set_default_charsets()
	Defined_Sets = repeat(0, CS_LAST - CS_FIRST - 1)
	Defined_Sets[CS_Alphabetic	] = {{'a', 'z'}, {'A', 'Z'}}
	Defined_Sets[CS_Alphanumeric] = {{'0', '9'}, {'a', 'z'}, {'A', 'Z'}}
	Defined_Sets[CS_Identifier]   = {{'0', '9'}, {'a', 'z'}, {'A', 'Z'}, {'_', '_'}}
	Defined_Sets[CS_Uppercase 	] = {{'A', 'Z'}}
	Defined_Sets[CS_Lowercase 	] = {{'a', 'z'}}
	Defined_Sets[CS_Printable 	] = {{' ', '~'}}
	Defined_Sets[CS_Displayable ] = {{' ', '~'}, "  ", "\t\t", "\n\n", "\r\r", {8,8}, {7,7} }
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
	Defined_Sets[CS_SpecWord 	] = "_"
	Defined_Sets[CS_Boolean     ] = {TRUE,FALSE}
end procedure

--**
-- gets the definition for each of the defined character sets.
--
-- Returns:
-- A **sequence**, of pairs. The first element of each pair
-- is the character set id ( such as ##CS_Whitespace## ) and the second is the definition
-- of that character set.
--
-- Comments:
-- This is the same format required for the [[:set_charsets]] routine.
--
-- Example 1:
-- <eucode>
-- sequence sets
-- sets = get_charsets()
-- </eucode>
--
-- See Also:
-- [[:set_charsets]], [[:set_default_charsets]]

public function get_charsets()
	sequence result_

	result_ = {}
	for i = CS_FIRST + 1 to CS_LAST - 1 do
		result_ = append(result_, {i, Defined_Sets[i]} )
	end for

	return result_
end function

--**
-- sets the definition for one or more defined character sets.
--
-- Parameters:
--		# ##charset_list## : a sequence of zero or more character set definitions.
--
-- Comments:
-- ##charset_list## must be a sequence of pairs. The first element of each pair
-- is the character set id (such as ##CS_Whitespace##) and the second is the definition
-- of that character set.
--
-- This is the same format returned by the [[:get_charsets]] routine.
--
-- You cannot create new character sets using this routine.
--
-- Example 1:
-- <eucode>
-- set_charsets({{CS_Whitespace, " \t"}})
-- t_space('\n') --> FALSE
--
-- t_specword('$') --> FALSE
-- set_charsets({{CS_SpecWord, "_-#$%"}})
-- t_specword('$') --> TRUE
-- </eucode>
--
-- See Also:
-- [[:get_charsets]]

public procedure set_charsets(sequence charset_list)
	for i = 1 to length(charset_list) do
		if sequence(charset_list[i]) and length(charset_list[i]) = 2 then
			if integer(charset_list[i][1]) and charset_list[i][1] > CS_FIRST and charset_list[i][1] < CS_LAST then
				Defined_Sets[charset_list[i][1]] = charset_list[i][2]
			end if
		end if
	end for
end procedure

--****
-- === Types
--

--**
-- test for an integer boolean.
--
-- Returns:
-- Returns TRUE if argument is 1 or 0
--
-- Returns FALSE if the argument is anything else other than 1 or 0.
--
-- Example 1:
-- <eucode>
-- boolean(-1)            -- FALSE
-- boolean(0)             -- TRUE
-- boolean(1)             -- TRUE
-- boolean(1.234)         -- FALSE
-- boolean('A')           -- FALSE
-- boolean('9')           -- FALSE
-- boolean('?')           -- FALSE
-- boolean("abc")         -- FALSE
-- boolean("ab3")         -- FALSE
-- boolean({1,2,"abc"})   -- FALSE
-- boolean({1, 2, 9.7)    -- FALSE
-- boolean({})            -- FALSE (empty sequence)
-- </eucode>

public type boolean(object test_data)
	-- A boolean is a value that is either zero or one.

	return find(test_data,{1,0}) != 0

end type

--**
-- tests elements for boolean.
--
-- Returns:
-- Returns TRUE if argument is boolean (1 or 0) or if every element of
-- the argument is boolean.
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains non-boolean elements
--
-- Example 1:
-- <eucode>
-- t_boolean(-1)            -- FALSE
-- t_boolean(0)             -- TRUE
-- t_boolean(1)             -- TRUE
-- t_boolean({1, 1, 0})     -- TRUE
-- t_boolean({1, 1, 9.7})    -- FALSE
-- t_boolean({})            -- FALSE (empty sequence)
-- </eucode>
public type t_boolean(object test_data)
	return char_test(test_data, Defined_Sets[CS_Boolean])
end type

--**
-- tests for  alphanumeric character.
--
-- Returns:
-- Returns TRUE if argument is an alphanumeric character or if every element of
-- the argument is an alphanumeric character.
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
-- t_alnum({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- t_alnum({})            -- FALSE (empty sequence)
-- </eucode>

public type t_alnum(object test_data)
	return char_test(test_data, Defined_Sets[CS_Alphanumeric])
end type

--**
-- tests string if it is an valid identifier.
--
-- Returns:
-- Returns TRUE if argument is an alphanumeric character or if every element of
-- the argument is an alphanumeric character and that the first character is not
-- numeric and the whole group of characters are not all numeric.
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains non-alphanumeric elements
--
-- Example 1:
-- <eucode>
-- t_identifier(-1)            -- FALSE
-- t_identifier(0)             -- FALSE
-- t_identifier(1)             -- FALSE
-- t_identifier(1.234)         -- FALSE
-- t_identifier('A')           -- TRUE
-- t_identifier('9')           -- FALSE
-- t_identifier('?')           -- FALSE
-- t_identifier("abc")         -- TRUE (every element is alphabetic or a digit)
-- t_identifier("ab3")         -- TRUE
-- t_identifier("ab_3")        -- TRUE (underscore is allowed)
-- t_identifier("1abc")        -- FALSE (identifier cannot start with a number)
-- t_identifier("102")         -- FALSE (identifier cannot be all numeric)
-- t_identifier({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_identifier({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- t_identifier({})            -- FALSE (empty sequence)
-- </eucode>

public type t_identifier(object test_data)
	-- Test to make sure the first character is not a number
	if t_digit(test_data) then
		return 0
	elsif sequence(test_data) and length(test_data) > 0 and t_digit(test_data[1]) then
		return 0
	end if

	return char_test(test_data, Defined_Sets[CS_Identifier])
end type

--**
-- tests for alphabetic characters.
--
-- Returns:
-- Returns TRUE if argument is an alphabetic character or if every element of
-- the argument is an alphabetic character.
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains non-alphabetic elements
--
-- Example 1:
-- <eucode>
-- t_alpha(-1)            -- FALSE
-- t_alpha(0)             -- FALSE
-- t_alpha(1)             -- FALSE
-- t_alpha(1.234)         -- FALSE
-- t_alpha('A')           -- TRUE
-- t_alpha('9')           -- FALSE
-- t_alpha('?')           -- FALSE
-- t_alpha("abc")         -- TRUE (every element is alphabetic)
-- t_alpha("ab3")         -- FALSE
-- t_alpha({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_alpha({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- t_alpha({})            -- FALSE (empty sequence)
-- </eucode>

public type t_alpha(object test_data)
	return char_test(test_data, Defined_Sets[CS_Alphabetic])
end type

--**
-- tests for ASCII characters.
--
-- Returns:
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
-- t_ascii({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- t_ascii({})            -- FALSE (empty sequence)
-- </eucode>

public type t_ascii(object test_data)
	return char_test(test_data, Defined_Sets[CS_ASCII])
end type

--**
-- tests for control characters.
--
-- Returns:
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
-- t_cntrl({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- t_cntrl({1, 2, 'a'})    -- FALSE (contains a non-control)
-- t_cntrl({})            -- FALSE (empty sequence)
-- </eucode>

public type t_cntrl(object test_data)
	return char_test(test_data, Defined_Sets[CS_Control])
end type

--**
-- tests for digits.
--
-- Returns:
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
-- t_digit({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- t_digit({1, 2, 'a'})    -- FALSE (contains a non-digit)
-- t_digit({})            -- FALSE (empty sequence)
-- </eucode>

public type t_digit(object test_data)
	return char_test(test_data, Defined_Sets[CS_Digit])
end type

--**
-- test for glyphs (printable) characters.
--
-- Returns:
-- Returns TRUE if argument is a glyph character or if every element of
-- the argument is a glyph character. (One that is visible when displayed)
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains non-glyph
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
-- t_graph({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- t_graph({1, 2, 'a'})    -- FALSE (control chars (1,2) don't have glyphs)
-- t_graph({})            -- FALSE (empty sequence)
-- </eucode>

public type t_graph(object test_data)
	return char_test(test_data, Defined_Sets[CS_Graphic])
end type

--**
-- tests for a special word character.
--
-- Returns:
-- Returns TRUE if argument is a special word character or if every element of
-- the argument is a special word character.
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains non-special-word characters.
--
-- Comments:
-- A //special word character// is any character that is not normally part of
-- a word but in certain cases may be considered. This is most commonly used
-- when looking for words in programming source code which allows an underscore
-- as a word character.
--
-- Example 1:
-- <eucode>
-- t_specword(-1)            -- FALSE
-- t_specword(0)             -- FALSE
-- t_specword(1)             -- FALSE
-- t_specword(1.234)         -- FALSE
-- t_specword('A')           -- FALSE
-- t_specword('9')           -- FALSE
-- t_specword('?')           -- FALSE
-- t_specword('_')           -- TRUE
-- t_specword("abc")         -- FALSE
-- t_specword("ab3")         -- FALSE
-- t_specword("123")         -- FALSE
-- t_specword({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_specword({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- t_specword({1, 2, 'a'})    -- FALSE (control chars (1,2) don't have glyphs)
-- t_specword({})            -- FALSE (empty sequence)
-- </eucode>

public type t_specword(object test_data)
	return char_test(test_data, Defined_Sets[CS_SpecWord])
end type

--**
-- tests for bytes.
--
-- Returns:
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
-- t_bytearray({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- t_bytearray({1, 2, 'a'})    -- TRUE
-- t_bytearray({})            -- FALSE (empty sequence)
-- </eucode>

public type t_bytearray(object test_data)
	return char_test(test_data, Defined_Sets[CS_Bytes])
end type

--**
-- tests for lowercase characters.
--
-- Returns:
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
-- t_lower({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- t_lower({1, 2, 'a'})    -- FALSE (contains a non-digit)
-- t_lower({})            -- FALSE (empty sequence)
-- </eucode>

public type t_lower(object test_data)
	return char_test(test_data, Defined_Sets[CS_Lowercase])
end type

--**
-- tests for ASCII glyph characters.
--
-- Returns:
-- Returns TRUE if argument is a character that has an ASCII glyph or if every element of
-- the argument is a character that has an ASCII glyph.
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains characters that do not have an ASCII glyph.
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
-- t_print("123 ")        -- FALSE (contains a space)
-- t_print("123\n")       -- FALSE (contains a new-line)
-- t_print({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_print({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- t_print({1, 2, 'a'})    -- FALSE
-- t_print({})            -- FALSE (empty sequence)
-- </eucode>

public type t_print(object test_data)
	return char_test(test_data, Defined_Sets[CS_Printable])
end type

--**
-- tests for printable characters.
--
-- Returns:
-- Returns TRUE if argument is a character that can be displayed or if every element of
-- the argument is a character that can be displayed.
--
-- Returns FALSE if the argument is an empty sequence, or contains sequences,
-- or contains characters that cannot be displayed.
--
-- Example 1:
-- <eucode>
-- t_display(-1)            -- FALSE
-- t_display(0)             -- FALSE
-- t_display(1)             -- FALSE
-- t_display(1.234)         -- FALSE
-- t_display('A')           -- TRUE
-- t_display('9')           -- TRUE
-- t_display('?')           -- TRUE
-- t_display("abc")         -- TRUE
-- t_display("ab3")         -- TRUE
-- t_display("123")         -- TRUE
-- t_display("123 ")        -- TRUE
-- t_display("123\n")       -- TRUE
-- t_display({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_display({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- t_display({1, 2, 'a'})    -- FALSE
-- t_display({})            -- FALSE (empty sequence)
-- </eucode>

public type t_display(object test_data)
	return char_test(test_data, Defined_Sets[CS_Displayable])
end type

--**
-- tests for punctuation characters.
--
-- Returns:
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
-- t_punct({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- t_punct({1, 2, 'a'})    -- FALSE (contains a non-digit)
-- t_punct({})            -- FALSE (empty sequence)
-- </eucode>

public type t_punct(object test_data)
	return char_test(test_data, Defined_Sets[CS_Punctuation])
end type

--**
-- tests for whitespace characters.
--
-- Returns:
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
-- t_space({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- t_space({1, 2, 'a'})    -- FALSE (contains a non-digit)
-- t_space({})            -- FALSE (empty sequence)
-- </eucode>

public type t_space(object test_data)
	return char_test(test_data, Defined_Sets[CS_Whitespace])
end type

--**
-- tests for uppercase characters.
--
-- Returns:
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
-- t_upper({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- t_upper({1, 2, 'a'})    -- FALSE (contains a non-digit)
-- t_upper({})            -- FALSE (empty sequence)
-- </eucode>

public type t_upper(object test_data)
	return char_test(test_data, Defined_Sets[CS_Uppercase])
end type

--**
-- tests for hexadecimal characters.
--
-- Returns:
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
-- t_xdigit({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- t_xdigit({1, 2, 'a'})    -- FALSE (contains a non-digit)
-- t_xdigit({})            -- FALSE (empty sequence)
-- </eucode>

public type t_xdigit(object test_data)
	return char_test(test_data, Defined_Sets[CS_Hexadecimal])
end type

--**
-- tests for vowel characters.
--
-- Returns:
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
-- t_vowel({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- t_vowel({1, 2, 'a'})    -- FALSE (contains a non-digit)
-- t_vowel({})            -- FALSE (empty sequence)
-- </eucode>

public type t_vowel(object test_data)
	return char_test(test_data, Defined_Sets[CS_Vowel])
end type

--**
-- tests for consonant characters.
--
-- Returns:
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
-- t_consonant({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- t_consonant({1, 2, 'a'})    -- FALSE (contains a non-digit)
-- t_consonant({})            -- FALSE (empty sequence)
-- </eucode>

public type t_consonant(object test_data)
	return char_test(test_data, Defined_Sets[CS_Consonant])
end type

set_default_charsets()

--**
-- tests for integer elements.
--
-- Returns:
--  TRUE if argument is a sequence that only contains zero or more integers.
--
-- Example 1:
-- <eucode>
-- integer_array(-1)            -- FALSE (not a sequence)
-- integer_array("abc")         -- TRUE (all single characters)
-- integer_array({1, 2, "abc"}) -- FALSE (contains a sequence)
-- integer_array({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- integer_array({1, 2, 'a'})    -- TRUE
-- integer_array({})            -- TRUE
-- </eucode>
public type integer_array( object x )
	if not sequence(x) then
		return 0
	end if

	for i = 1 to length(x) do
		if not integer(x[i]) then
			return 0
		end if
	end for
	return 1
end type

--**
-- tests for text characters.
--
-- Returns:
--  TRUE if argument is a sequence that only contains zero or more characters.
--
-- Comments:
-- A **character** is defined as a positive integer or zero. This is a broad
-- definition that may be refined once proper UNICODE support is implemented.
--
-- Example 1:
-- <eucode>
-- t_text(-1)            -- FALSE (not a sequence)
-- t_text("abc")         -- TRUE (all single characters)
-- t_text({1, 2, "abc"}) -- FALSE (contains a sequence)
-- t_text({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- t_text({1, 2, 'a'})    -- TRUE
-- t_text({1, -2, 'a'})   -- FALSE (contains a negative integer)
-- t_text({})            -- TRUE
-- </eucode>
public type t_text( object x )
	if not sequence(x) then
		return 0
	end if

	for i = 1 to length(x) do
		if not integer(x[i]) then
			return 0
		end if
		if x[i] < 0 then
			return 0
		end if
	end for
	return 1
end type

--**
-- tests for atom elements.
--
-- Returns:
--  TRUE if argument is a sequence that only contains zero or more numbers.
--
-- Example 1:
-- <eucode>
-- number_array(-1)            -- FALSE (not a sequence)
-- number_array("abc")         -- TRUE (all single characters)
-- number_array({1, 2, "abc"}) -- FALSE (contains a sequence)
-- number_array(1, 2, 9.7})    -- TRUE
-- number_array(1, 2, 'a'})    -- TRUE
-- number_array({})            -- TRUE
-- </eucode>
public type number_array( object x )
	if not sequence(x) then
		return 0
	end if

	for i = 1 to length(x) do
		if not atom(x[i]) then
			return 0
		end if
	end for
	return 1
end type

--**
-- tests for sequence with possible nested sequences.
-- 
-- Returns:
--  TRUE if argument is a sequence that only contains zero or more sequences.
--
-- Example 1:
-- <eucode>
-- sequence_array(-1)            -- FALSE (not a sequence)
-- sequence_array("abc")         -- FALSE (all single characters)
-- sequence_array({1, 2, "abc"}) -- FALSE (contains some atoms)
-- sequence_array({1, 2, 9.7})   -- FALSE
-- sequence_array({1, 2, 'a'})   -- FALSE
-- sequence_array({"abc", {3.4, 99182.78737}}) -- TRUE
-- sequence_array({})            -- TRUE
-- </eucode>
public type sequence_array( object x )
	if not sequence(x) then
		return 0
	end if

	for i = 1 to length(x) do
		if not sequence(x[i]) then
			return 0
		end if
	end for
	return 1
end type

--**
-- tests for ASCII elements.
--
-- Returns:
--  TRUE if argument is a sequence that only contains zero or more ASCII characters.
--
-- Comments:
-- An ASCII 'character' is defined as a integer in the range [0 to 127].
--
-- Example 1:
-- <eucode>
-- ascii_string(-1)            -- FALSE (not a sequence)
-- ascii_string("abc")         -- TRUE (all single ASCII characters)
-- ascii_string({1, 2, "abc"}) -- FALSE (contains a sequence)
-- ascii_string({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- ascii_string({1, 2, 'a'})    -- TRUE
-- ascii_string({1, -2, 'a'})   -- FALSE (contains a negative integer)
-- ascii_string({})            -- TRUE
-- </eucode>
public type ascii_string( object x )
	if not sequence(x) then
		return 0
	end if

	for i = 1 to length(x) do
		if not integer(x[i]) then
			return 0
		end if
		if x[i] < 0 then
			return 0
		end if
		if x[i] > 127 then
			return 0
		end if
	end for
	return 1
end type

--**
-- tests for a string sequence.
--
-- Returns:
--  TRUE if argument is a sequence that only contains zero or more byte characters.
--
-- Comments:
-- A byte 'character' is defined as a integer in the range [0 to 255].
--
-- Example 1:
-- <eucode>
-- string(-1)            -- FALSE (not a sequence)
-- string("abc'6")       -- TRUE (all single byte characters)
-- string({1, 2, "abc'6"}) -- FALSE (contains a sequence)
-- string({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- string({1, 2, 'a'})    -- TRUE
-- string({1, 2, 'a', 0}) -- TRUE (even though it contains a null byte)
-- string({1, -2, 'a'})   -- FALSE (contains a negative integer)
-- string({})            -- TRUE
-- </eucode>
public type string( object x )
	if not sequence(x) then
		return 0
	end if

	for i = 1 to length(x) do
		if not integer(x[i]) then
			return 0
		end if
		if x[i] < 0 then
			return 0
		end if
		if x[i] > 255 then
			return 0
		end if
	end for
	return 1
end type

--**
-- tests for a string sequence (that has no null character).
--
-- Returns:
--  TRUE if argument is a sequence that only contains zero or more non-null byte characters.
--
-- Comments:
-- A non-null byte 'character' is defined as a integer in the range [1 to 255].
--
-- Example 1:
-- <eucode>
-- cstring(-1)            -- FALSE (not a sequence)
-- cstring("abc'6")       -- TRUE (all single byte characters)
-- cstring({1, 2, "abc'6"}) -- FALSE (contains a sequence)
-- cstring({1, 2, 9.7})    -- FALSE (contains a non-integer)
-- cstring({1, 2, 'a'})    -- TRUE
-- cstring({1, 2, 'a', 0}) -- FALSE (contains a null byte)
-- cstring({1, -2, 'a'})   -- FALSE (contains a negative integer)
-- cstring({})            -- TRUE
-- </eucode>
public type cstring( object x )
	if not sequence(x) then
		return 0
	end if

	for i = 1 to length(x) do
		if not integer(x[i]) then
			return 0
		end if
		if x[i] <= 0 then
			return 0
		end if
		if x[i] > 255 then
			return 0
		end if
	end for
	return 1
end type

--**
-- Value returned from [[:routine_id]]
-- when the routine does not exist or is out of scope.
-- This is typically seen as -1 in legacy code.
public constant INVALID_ROUTINE_ID = routine_id("#")

--**
-- To be used as a flag for no [[:routine_id]] supplied.
public constant NO_ROUTINE_ID = -99999

-- Maximum and minimum values for Euphoria 31-bit integers (as implemented by 32-bit Euphoria)
constant
	MAXSINT31 = power(2,30)-1,
	MINSINT31 = -power(2,30)

--** 
-- tests for Euphoria integer.
--
-- Returns:
-- TRUE if the argument is a valid 31-bit Euphoria integer.
--
-- Comments:
-- This function is the same as ##integer(o)## on 32-bit Euphoria,
-- but is portable to 64-bit architectures.

public type t_integer32( object o )
	ifdef EU32 then
		return integer( o )
	elsedef
		if integer( o ) and o <= MAXSINT31 and o >= MINSINT31 then
			return 1
		else
			return 0
		end if
	end ifdef
end type

