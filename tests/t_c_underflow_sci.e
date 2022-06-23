include std/unittest.e

-- A very small unparsible positive value.  Too small for this notation.
-- Should throw an error here, warning the user the number is so small it is interpreted as zero.
atom epsilon = 3e-4932

-- test below for numbers really close to zero works better than test_not_equal()
test_false("Number is not zero", epsilon + epsilon = epsilon)
? 1/epsilon
test_pass("Tiny standard decimal notation number")
test_report()
test_pass("Tiny floating point notation atom")
test_report()
