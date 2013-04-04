-- t_literals.e

include std/unittest.e

-- Hexadecimal literals
test_equal("Hex Lit 1", -4275878552, -#FEDC_BA98)
test_equal("Hex Lit 2", 1985229328, #7654_3210)
test_equal("Hex Lit 3", 11259375, #aB_cDeF)

test_equal("Integer Lit 1", 11259375, 11_259_375)

test_equal("Float Lit 1", 11259.3756, 11_259.375_6)

test_equal("Binary Lit 1", 15, 0b1111)
test_equal("Octal Lit 1", 585, 0t1111)
test_equal("Dec Lit 1", 1111, 0d1111)
test_equal("Hex Lit 4", 4369, 0x1111)

test_equal("Binary Lit 2", 11, 0B1011)
test_equal("Octal Lit 2", 521, 0T1011)
test_equal("Dec Lit 2", 1011, 0D1011)
test_equal("Hex Lit 5", 4113, 0X1011)

test_equal("Hex Lit 6", -1073741824, -0x4000_0000)

/*-------------------------------------------------------
   Extended string literals.
   Make sure each /* allowable */ syntax form is permitted.
-------------------------------------------------------- */
test_equal("Extended string literal 1", "`one` `two`", """`one` `two`""")
test_equal("Extended string literal 2", "\"one\" \"two\"", `"one" "two"`)


/* Test for string which extend over multiple lines. */
integer c1 = 0
integer c2 = 0

/* C1 */ c1 = 1 /* C2 */ c2 = 1 /* eoc */
test_equal("Dual comments", {1,1}, {c1, c2})

sequence _s
_s = `

"three'
'four"

`
test_equal("Extended string literal A", "\n\"three'\n'four\"\n", _s)

_s = `
"three'
'four"
`
test_equal("Extended string literal B", "\"three'\n'four\"", _s)


_s = `"three'
'four"
`
test_equal("Extended string literal C", "\"three'\n'four\"\n", _s)


_s = `
________
        Dear Mr. John Doe, 
        
            I am very happy for your support 
            with respect to the offer of
            help.
        
     Mr. Jeff Doe 
`
sequence t = """
Dear Mr. John Doe, 

    I am very happy for your support 
    with respect to the offer of
    help.

Mr. Jeff Doe 
"""

test_equal("Extended string literal D", t, _s)
     

_s = """
__________________if ( strcmp( "foo", "bar" ) == 1 ) {
                       printf("strcmp works correctly.");
                  }
"""

t = `if ( strcmp( "foo", "bar" ) == 1 ) {
     printf("strcmp works correctly.");
}
`
test_equal("Extended string literal E", t, _s)

test_equal("Escaped strings - newline",         {10}, "\n")
test_equal("Escaped strings - tab",             {09}, "\t")
test_equal("Escaped strings - carriage return", {13}, "\r")
test_equal("Escaped strings - back slash",      {92}, "\\")  
test_equal("Escaped strings - dbl quote",       {34}, "\"")
test_equal("Escaped strings - sgl quote",       {39}, "\'")
test_equal("Escaped strings - null",            {00}, "\0")

test_equal("Escaped strings - hex", {0xAB, 0xDF, 0x01, 0x2E}, "\xab\xDF\x01\x2E")
test_equal("Escaped strings - u16", {0xABDF, 0x012E}, "\uabDF\u012E")
test_equal("Escaped strings - U32", {0xABDF012E}, "\UabDF012E")

test_equal("Escaped characters - newline",         10, '\n')
test_equal("Escaped characters - tab",             09, '\t')
test_equal("Escaped characters - carriage return", 13, '\r')
test_equal("Escaped characters - back slash",      92, '\\')  
test_equal("Escaped characters - dbl quote",       34, '\"')
test_equal("Escaped characters - sgl quote",       39, '\'')
test_equal("Escaped characters - null",            00, '\0')
test_equal("Escaped characters - escape #1",       27, '\e')
test_equal("Escaped characters - escape #2",       27, '\E')

test_equal("Escaped characters - binary", {0xA, 0xDF, 0x01, 0x12E}, {'\b1010','\b11011111','\b0000_0001','\b1_0010_1110'})

test_equal("Escaped characters - hex", {0xAB, 0xDF, 0x01, 0x2E}, {'\xab','\xDF','\x01','\x2E'})
test_equal("Escaped characters - u16", {0xABDF, 0x012E}, {'\uabDF','\u012E'})
test_equal("Escaped characters - U32", {0xABDF012E}, {'\UabDF012E'})

test_equal("Binary strings - no punc", {0x1,0xDF,0x012E}, b"1 11011111 100101110")
test_equal("Binary strings - with punc", {0x1,0xDF,0x012E}, b"1 11_01_11_11 1_0010_1110")
test_equal("Binary strings - multiline", {0x1,0xDF,0x012E}, b"1 
                                                              11_01_11_11 
                                                              1_0010_1110")

test_equal("Hex strings - no punc", {0xAB,0xDF,0x01,0x2E}, x"abDF012E")
test_equal("Hex strings - with punc", {0xAB,0x0D,0xF0,0x12,0xEF,0x03}, x"ab D F0__12Ef3")
test_equal("Hex strings - multiline", {0xAB,0x0D,0xF0,0x12,0xEF,0x03}, x"ab
                                                                         D 
                                                                         F0__12Ef3
                                                                         ")

test_equal("utf16 strings - no punc", {0xABDF,0x012E}, u"abDF012E")
test_equal("utf16 strings - with punc", {0xAB,0x0D,0xF012, 0x0EF3}, u"ab D F0__12Ef3")
test_equal("utf16 strings - no punc 2", {0xABDF, 0x012E, 0x1234, 0x5678, 0xFEDC, 0xBA98}, u"abDF012E12345678FEDCBA98")
test_equal("utf16 strings - multiline", {0xABDF, 0x012E, 0x1234, 0x5678, 0xFEDC, 0xBA98}, 
														u"abDF
														  012E
														  12345678
														  FEDC
														  
														  
														  BA98")
 
test_equal("utf32 strings - no punc", {0xABDF012E, 0x12345678, 0xFEDCBA98}, U"abDF012E 12345678 FEDCBA98 ")
test_equal("utf32 strings - with punc", {0xAB,0x0D,0x0F012EF3}, U"  ab D F0__12Ef3  ")
test_equal("utf32 strings - multiline", {0xAB,0x0D,0x0F012EF3}, U"  
                                                                   ab 
                                                                   D 
                                                                   F0__12Ef3
                                                                     ")
                                                                     

enum type colors by * 2.3 BLUE, BLACK, WHITE=13, RED, GREEN, CYAN=94.3 end type
constant colors_name = {"blue", "black", "white", "red", "green"}

test_equal("enum values", {1, 2.3, 13, 29.9, 68.77, 94.3}, {BLUE, BLACK, WHITE, RED, GREEN, CYAN})
test_equal("enum type func", "green", colors_name[colors(GREEN)])

constant MINVAL_1 = 2.0  
atom     MINVAL_2 = 2.0  
  
function doit()  
  
   atom amt1 = 0  
   atom amt2 = 0  
   atom amt3 = 0  
   atom amt4 = 0  
  
   amt1 += MINVAL_1  
   amt2 -= MINVAL_1  
  
   amt3 += MINVAL_2  
   amt4 -= MINVAL_2  
  
   return 0  
  
end function  
test_equal( "Constant floating point with zero fraction", 0, doit() )

test_report()
