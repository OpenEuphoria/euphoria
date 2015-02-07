include std/unittest.e
include std/error.e
-- the biggest double (scinot.e:391)
atom max_atom = 1.7976931348623157081e308
-- bigger than the biggest double.
atom        a = -1.79769313486231582e308
test_pass("Huge floating point notation number")
test_report()
