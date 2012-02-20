include std/unittest.e
include std/unicode.e
include std/machine.e

sequence s1, s2, s3
s1 = "abcd"
s2 = ""
s3 = {#FFFF, #0001, #1000, #8080}

test_equal("peek_wstring and allocate_wstring#1", s1, peek_wstring(allocate_wstring(s1,1)))
test_equal("peek_wstring and allocate_wstring#2", s2, peek_wstring(allocate_wstring(s2,1)))
test_equal("peek_wstring and allocate_wstring#3", s3, peek_wstring(allocate_wstring(s3,1)))
-- 
-- atom adr
-- adr = allocate(length(s3) * 2 + 2,1)
-- poke_wstring(adr, (length(s3) + 1)*2, s3)
-- test_equal("peek_wstring and poke_wstring#3", s3, peek_wstring(adr))
-- 
-- free(adr)

-- type tests
object a = {
	"this is ascii string \t \n \r " & #FF & #00,
	123,
	{{"not", "string", 999}},
	"this is unicode string " & #100,
	"this is unicode string " & #FFFF,
	"this is not unicode string " & #10000,
	"this is not unicode string " & #FFFFFFFF,
	$
	}

for i = 1 to length(a) do
	a[i] = validate(a[i], utf_16, 0)
end for
test_equal("validate utfs", {0,-1,1,0,0,28, 28}, a)

test_equal("UTF8 literal #1",  {101,102,103,174}, x"656667AE")
test_equal("UTF8 literal #2",  {101,102,103,174}, x"6566 67AE")
test_equal("UTF8 literal #3",  {101,102,103,174}, x"65 66 67 AE")

test_equal("UTF16 literal #1",  {25958, 26542}, u"656667AE")
test_equal("UTF16 literal #2",  {25958, 26542}, u"6566 67AE")
test_equal("UTF16 literal #3",  {101,102,103,174}, u"65 66 67 AE")

test_equal("UTF32 literal #1",  {1701210030}, U"656667AE")
test_equal("UTF32 literal #2",  {25958, 26542}, U"6566 67AE")
test_equal("UTF32 literal #3",  {101,102,103,174}, U"65 66 67 AE")


-- utf8 tests -- taken from rfc 2279

sequence e1, e2, e3
sequence f1, f2, f3
sequence g1, g2, g3

e1 = u"0041 2262 0391 002E" -- "A<NOT IDENTICAL TO><ALPHA>."
e2 = u"D55C AD6D C5B4" -- "hangugo" in Hangul
e3 = u"65E5 672C 8A9E" -- "nihongo" in Kanji

f1 = utf_to_utf(e1, utf_16, utf_8)
f2 = utf_to_utf(e2, utf_16, utf_8)
f3 = utf_to_utf(e3, utf_16, utf_8)

test_equal("utf8_encode#1", x"41E289A2CE912E", f1)
test_equal("utf8_encode#2", x"ED959CEAB5ADEC96B4", f2)
test_equal("utf8_encode#3", x"E697A5E69CACE8AA9E", f3)

g1 = utf_to_utf(f1, utf_8, utf_16)
g2 = utf_to_utf(f2, utf_8, utf_16)
g3 = utf_to_utf(f3, utf_8, utf_16)

test_equal("utf8_decode#1", e1, g1)
test_equal("utf8_decode#2", e2, g2)
test_equal("utf8_decode#3", e3, g3)


test_true(`is_code_point('a')`, is_code_point('a'))
test_false(`is_code_point(0x1FFFFF)`, is_code_point(0x1FFFFF))
test_true(`is_code_point(0xFFFF)`, is_code_point(0xFFFF))
test_false(`is_code_point(0xFFFF, strict)`, is_code_point(0xFFFF, 1))
test_true(`is_code_point(0x1FFFF)`, is_code_point(0x1FFFF))
test_false(`is_code_point(0x1FFFF, strict)`, is_code_point(0x1FFFF, 1))

test_equal( "chars_before utf8",  3, chars_before(x"7a C2A9 E6B0B4 F09d849e 0 F09d849e E6B0B4 C2A9 7a", 7, utf_8))
test_equal( "chars_before utf16", 4, chars_before(u"7a A9 6c34 d834dd1e 0 d834dd1e 6c34 a9 7a", 6, utf_16))
test_equal( "chars_before utf32", 5, chars_before(U"7a A9 6c34 1d11e 0 1d11e 6c34 a9 7A", 6, utf_32))

test_equal( "char_count utf8",  9, char_count(x"7a C2A9 E6B0B4 F09d849e 0 F09d849e E6B0B4 C2A9 7a", utf_8))
test_equal( "char_count utf16", 9, char_count(u"7a A9 6c34 d834dd1e 0 d834dd1e 6c34 a9 7a", utf_16))
test_equal( "char_count utf32", 9, char_count(U"7a A9 6c34 1d11e 0 1d11e 6c34 a9 7A", utf_32))

procedure ut1()
	object c
	
	sequence s = x"7a C2A9 E6B0B4 F09d849e"
	c = get_char(s, 1, utf_8)
	test_equal("get_char utf_8 z", {'z', 2}, c)
	
	c = get_char(s, 2, utf_8)
	test_equal("get_char utf_8 copyright", {0xa9, 4}, c)

	c = get_char(s, 4, utf_8)
	test_equal("get_char utf_8 water", {0x6c34, 7}, c)

	c = get_char(s, 7, utf_8)
	test_equal("get_char utf_8 G-Clef", {0x1d11e, 11}, c)
	
	sequence s4 = {
	x"DFFF", -- Subsequent parts invalid
	x"E289", -- Sequence is missing
	x"EDBFBF", -- Not a valid UCS char (0xDFFF)
	x"F88080808A", -- 5 byte sequence
	x"FC808080808A", -- 6 byte sequence
	$
	}
	
	for j = 1 to length(s4) do
	    s4[j] = get_char(s4[j], 1)
	end for
	test_equal("get_char utf_8 5", {4, 3, 5, 2, 2}, s4)
end procedure
ut1()	

procedure ut2()
	object c
	sequence s
	
	s = u"7a 6c34 d834 dd1e"
	c = get_char(s, 1, utf_16)
	test_equal("get_char utf_16 z", {'z', 2}, c)
	
	c = get_char(s, 2, utf_16)
	test_equal("get_char utf_16 water", {0x6c34, 3}, c)

	c = get_char(s, 3, utf_16)
	test_equal("get_char utf_16 G-Clef", {0x1d11e, 5}, c)
	
	sequence s4 = {
	u"DFFF", -- Bad leader
	u"D828 D828", -- Bad trailer
	u"D828 ", -- Missing trailer
	u"D8FF DFFF", -- Not a valid UCS char (0x4FFFF)
	$
	}

	for j = 1 to length(s4) do
	    s4[j] = get_char(s4[j], 1, utf_16, 1) -- Use 'strict' option
	end for
	test_equal("get_char utf_16 5", {7,8,3,5}, s4)
	
end procedure
ut2()

procedure ut3()
	object c
	sequence s
	
	s = U"7a 6c34 1d11e"
	c = get_char(s, 1, utf_32)
	test_equal("get_char utf_32 z", {'z', 2}, c)
	
	c = get_char(s, 2, utf_32)
	test_equal("get_char utf_32 water", {0x6c34, 3}, c)

	c = get_char(s, 3, utf_32)
	test_equal("get_char utf_32 G-Clef", {0x1d11e, 4}, c)
	
	sequence s4 = {
	{-1}, -- Bad data item
	U"D8FF", -- Not a valid UCS char 
	U"4FFFF", -- Not a valid UCS char
	$
	}

	for j = 1 to length(s4) do
	    s4[j] = get_char(s4[j], 1, utf_32, 1) -- Use 'strict' option
	end for
	test_equal("get_char utf_16 5", {1,5,5}, s4)
	
end procedure
ut3()

test_equal("to_utf utf_8 z", x"7a", to_utf(0x7a, utf_8))
test_equal("to_utf utf_8 copyright", x"c2a9", to_utf(0xa9, utf_8))
test_equal("to_utf utf_8 water", x"e6b0b4", to_utf(0x6c34, utf_8))
test_equal("to_utf utf_8 G-Clef", x"f09d849e", to_utf(0x1d11e, utf_8))

test_equal("to_utf utf_16 z", u"7a", to_utf(0x7a, utf_16))
test_equal("to_utf utf_16 copyright", u"a9", to_utf(0xa9, utf_16))
test_equal("to_utf utf_16 water", u"6c34", to_utf(0x6c34, utf_16))
test_equal("to_utf utf_16 G-Clef", u"d834 dd1e", to_utf(0x1d11e, utf_16))

test_equal("to_utf utf_32 z", U"7a", to_utf(0x7a, utf_32))
test_equal("to_utf utf_32 copyright", U"a9", to_utf(0xa9, utf_32))
test_equal("to_utf utf_32 water", U"6c34", to_utf(0x6c34, utf_32))
test_equal("to_utf utf_32 G-Clef", U"1d11e", to_utf(0x1d11e, utf_32))

test_equal("code_length utf_8 z", 1, code_length(0x7a, utf_8))
test_equal("code_length utf_8 copyright", 2, code_length(0xa9, utf_8))
test_equal("code_length utf_8 water", 3, code_length(0x6c34, utf_8))
test_equal("code_length utf_8 G-Clef", 4, code_length(0x1d11e, utf_8))

test_equal("code_length utf_16 z", 1, code_length(0x7a, utf_16))
test_equal("code_length utf_16 copyright", 1, code_length(0xa9, utf_16))
test_equal("code_length utf_16 water", 1, code_length(0x6c34, utf_16))
test_equal("code_length utf_16 G-Clef", 2, code_length(0x1d11e, utf_16))

test_equal("code_length utf_32 z", 1, code_length(0x7a, utf_32))
test_equal("code_length utf_32 copyright", 1, code_length(0xa9, utf_32))
test_equal("code_length utf_32 water", 1, code_length(0x6c34, utf_32))
test_equal("code_length utf_32 G-Clef", 1, code_length(0x1d11e, utf_32))
	
test_equal("validate utf_8 1", 0, validate(x"7a C2A9 E6B0B4 F09d849e", utf_8))
test_equal("validate utf_8 2", 1, validate(x"dfff", utf_8))
test_equal("validate utf_8 3", 2, validate(x"7a E289", utf_8))
test_equal("validate utf_8 4", 3, validate(x"7a 7a EDBFBF", utf_8))
test_equal("validate utf_8 5", 4, validate(x"7a 7a 7a F88080808A", utf_8))
test_equal("validate utf_8 6", 5, validate(x"7a 7a 7a 7a FC808080808A", utf_8))

test_equal("validate utf_16 1", 0, validate(u"7a 6c34 d834 dd1e", utf_16))
test_equal("validate utf_16 2", 1, validate(u"dfff", utf_16))
test_equal("validate utf_16 3", 2, validate(u"7a d828 d828", utf_16))
test_equal("validate utf_16 4", 3, validate(u"7a 7a d828", utf_16))
test_equal("validate utf_16 5", 0, validate(u"7a 7a 7a d8ff dfff", utf_16, 0))
test_equal("validate utf_16 5", 4, validate(u"7a 7a 7a d8ff dfff", utf_16, 1))

test_equal("validate utf_32 1", 0, validate(U"7a A9 6c34 1d11e", utf_32))
test_equal("validate utf_32 2", 1, validate({-1}, utf_32))
test_equal("validate utf_32 3", 2, validate(U"7a D8FF", utf_32))
test_equal("validate utf_32 4", 0, validate(U"7a 7a 4FFFF", utf_32, 0))
test_equal("validate utf_32 4", 3, validate(U"7a 7a 4FFFF", utf_32, 1))

test_equal("utf8 to utf8",   x"7a C2A9 E6B0B4 F09d849e", utf_to_utf(x"7a C2A9 E6B0B4 F09d849e", utf_8, utf_8))
test_equal("utf8 to utf16",  u"7a A9 6c34 d834 dd1e",    utf_to_utf(x"7a C2A9 E6B0B4 F09d849e", utf_8, utf_16))
test_equal("utf8 to utf32",  U"7a A9 6c34 1d11e",        utf_to_utf(x"7a C2A9 E6B0B4 F09d849e", utf_8, utf_32))

test_equal("utf16 to utf8",  x"7a C2A9 E6B0B4 F09d849e", utf_to_utf(u"7a A9 6c34 d834 dd1e", utf_16, utf_8))
test_equal("utf16 to utf16", u"7a A9 6c34 d834 dd1e",    utf_to_utf(u"7a A9 6c34 d834 dd1e", utf_16, utf_16))
test_equal("utf16 to utf32", U"7a A9 6c34 1d11e",        utf_to_utf(u"7a A9 6c34 d834 dd1e", utf_16, utf_32))

test_equal("utf32 to utf8",  x"7a C2A9 E6B0B4 F09d849e", utf_to_utf(U"7a A9 6c34 1d11e", utf_32, utf_8))
test_equal("utf32 to utf16", u"7a A9 6c34 d834 dd1e",    utf_to_utf(U"7a A9 6c34 1d11e", utf_32, utf_16))
test_equal("utf32 to utf32", U"7a A9 6c34 1d11e",        utf_to_utf(U"7a A9 6c34 1d11e", utf_32, utf_32))

sequence sc = x"7a C2A9 E6B0B4 F09d849e"
sequence sr 
sr = utf_to_utf(sc, utf_8, utf_16)
sr = utf_to_utf(sr, utf_16, utf_32)
sr = utf_to_utf(sr, utf_32, utf_8)
test_equal("utf_to_utf round trip", sc, sr)


test_report()

