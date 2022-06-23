include std/unittest.e
include std/error.e
-- bigger than the biggest double.
atom        a = -1.18973e+4933
test_pass("Huge floating point notation number")
test_report()
