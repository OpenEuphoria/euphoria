-- t_literals.e

include std/unittest.e

-- Hexadecimal literals
test_equal("Hex Lit 1", -4275878552, -#FEDC_BA98)
test_equal("Hex Lit 2", 1985229328, #7654_3210)
test_equal("Hex Lit 3", 11259375, #aB_cDeF)


test_equal("Integer Lit 1", 11259375, 11_259_375)

test_equal("Float Lit 1", 11259.3756, 11_259.375_6)

/*-------------------------------------------------------
   Extended string literals.
   Make sure each allowable syntax form is permitted.
-------------------------------------------------------- */
test_equal("Extended string literal 1", "\"one\" \"two\"", ##"one" "two"#)
test_equal("Extended string literal 2", "\"one\" \"two\"", #'"one" "two"')
test_equal("Extended string literal 3", "\"one\" \"two\"", #`"one" "two"`)
test_equal("Extended string literal 4", "\"one\" \"two\"", #~"one" "two"~)
test_equal("Extended string literal 5", "\"one\" \"two\"", #$"one" "two"$)
test_equal("Extended string literal 6", "\"one\" \"two\"", #^"one" "two"^)
test_equal("Extended string literal 7", "\"one\" \"two\"", #/"one" "two"/)
test_equal("Extended string literal 8", "\"one\" \"two\"", #\"one" "two"\)
test_equal("Extended string literal 9", "\"one\" \"two\"", #|"one" "two"|)


/* Test for string which extend over multiple lines. */
sequence _s
_s = ##

"three'
'four"

#
test_equal("Extended string literal A", "\n\"three'\n'four\"\n", _s)

_s = ##
"three'
'four"
#
test_equal("Extended string literal B", "\"three'\n'four\"", _s)


_s = ##"three'
'four"
#
test_equal("Extended string literal C", "\"three'\n'four\"\n", _s)


_s = #/
________
        Dear Mr. John Doe, 
        
            I am very happy for your support 
            with respect to the offer of
            help.
        
     Mr. Jeff Doe 
/     
sequence t = ##
Dear Mr. John Doe, 

    I am very happy for your support 
    with respect to the offer of
    help.

Mr. Jeff Doe 
#

test_equal("Extended string literal D", t, _s)
     

_s = ##
__________________if ( strcmp( "foo", "bar" ) == 1 ) {
                       printf("strcmp works correctly.");
                  }
#

t = ##if ( strcmp( "foo", "bar" ) == 1 ) {
     printf("strcmp works correctly.");
}
#
test_equal("Extended string literal E", t, _s)

test_report()
