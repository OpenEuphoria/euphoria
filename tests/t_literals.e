-- t_literals.e

include std/unittest.e

-- Hexadecimal literals
test_equal("Hex Lit 1", 4275878552, #FEDCBA98)
test_equal("Hex Lit 2", 1985229328, #76543210)
test_equal("Hex Lit 3", 11259375, #aBcDeF)

-- Extended string literals.
-- Make sure each allowable syntax form is permitted.
test_equal("Extended string literal 1", "\"one\" \"two\"", ##"one" "two"#)
test_equal("Extended string literal 2", "\"one\" \"two\"", #'"one" "two"')
test_equal("Extended string literal 3", "\"one\" \"two\"", #`"one" "two"`)
test_equal("Extended string literal 4", "\"one\" \"two\"", #~"one" "two"~)
test_equal("Extended string literal 5", "\"one\" \"two\"", #$"one" "two"$)
test_equal("Extended string literal 6", "\"one\" \"two\"", #^"one" "two"^)
test_equal("Extended string literal 7", "\"one\" \"two\"", #/"one" "two"/)
test_equal("Extended string literal 8", "\"one\" \"two\"", #\"one" "two"\)
test_equal("Extended string literal 9", "\"one\" \"two\"", #|"one" "two"|)

-- Test for string which extend over multiple lines.
sequence s
s = ##

"three'
'four"

#
test_equal("Extended string literal A", "\n\"three'\n'four\"\n", s)

s = ##
"three'
'four"
#
test_equal("Extended string literal B", "\"three'\n'four\"", s)


s = ##"three'
'four"
#
test_equal("Extended string literal C", "\"three'\n'four\"\n", s)


s = #/
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

test_equal("Extended string literal D", t, s)
     

s = ##
__________________if ( strcmp( "foo", "bar" ) == 1 ) {
                       printf("strcmp works correctly.");
                  }
#

t = ##if ( strcmp( "foo", "bar" ) == 1 ) {
     printf("strcmp works correctly.");
}
#
test_equal("Extended string literal E", t, s)

test_report()
