include std/unittest.e

-- highest atom is 
-- 1.7E +/- 308 ( 17Fs an 8 and 242 0s )
atom max_double = #FFFFFFFFFFFFF800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- this should fail.
atom a = #FFFFFFFFFFFFF900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
test_pass("Huge standard hexadecimal notation number")
test_report()
