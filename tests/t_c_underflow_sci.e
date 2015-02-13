include std/unittest.e

-- the smallest double is about 4.9e-324
-- this should be read without an error
atom c = 4.940_656_458_412_465_4e-324 
-- the following line should error out with an error.  It is exactly half of the smallest number.
-- It is small enough to get rounded to 0 by the Euphoria scanner.
atom a = 2.470_328_229_206_232_7e-324
-- the following number is even smaller.
atom b = 2e-30000 

test_pass("Tiny standard decimal notation number")
test_report()
test_pass("Tiny floating point notation atom")
test_report()
