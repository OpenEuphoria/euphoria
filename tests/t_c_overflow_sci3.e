include std/unittest.e
include std/error.e
-- bigger than the biggest long double.
atom        a = -1.18974e+4932
test_pass("Huge floating point notation number")
test_report()
