include std/unittest.e
include std/convert.e

-- Test double limits

-- Min and max subnormal positive double, min normal positive double, max double
atom mnspd, mxspd, mnnpd, mxdb

mnspd = 4.9406564584124654e-324
mxspd = 2.2250738585072009e-308
mnnpd = 2.2250738585072014e-308
mxdb  = 1.7976931348623157e308

test_equal("1. Minimum subnormal positive double:", 
    float64_to_atom({0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}), mnspd)
test_equal("2. Maximum subnormal positive double:", 
    float64_to_atom({0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x0f, 0x00}), mxspd)
test_equal("3. Minimum normal positive double   :",
    float64_to_atom({0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00}), mnnpd)
test_equal("4. Max double                       :",
    float64_to_atom({0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xef, 0x7f}), mxdb)

-- Min and max subnormal negative double, min normal negative double, max (negative) double
atom mnsnd, mxsnd, mnnnd, mxndb

mnsnd = -4.9406564584124654e-324
mxsnd = -2.2250738585072009e-308
mnnnd = -2.2250738585072014e-308
mxndb  = -1.7976931348623157e308

test_equal("5. Minimum subnormal negative double:",
    float64_to_atom({0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80}), mnsnd)
test_equal("6. Maximum subnormal negative double:",
    float64_to_atom({0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x0f, 0x80}), mxsnd)
test_equal("7. Minimum normal negative double   :",
    float64_to_atom({0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x80}), mnnnd)
test_equal("8. Max negative double              :",
    float64_to_atom({0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xef, 0xff}), mxndb)

-- Test correct scanning of zeroes in scientific notation.
sequence dectest = {1E2, 0.000000000000000000000000000001E30, 0e0, 0e1, 0.0e2, .1e1,
                    1.0e0, 1.00e1, 1.000e2, 1.0000e3, 1.00000e4, 1.000000e5, 
                    1.0000000e6, 1.00000000e7, 1.000000000e8, 1.0000000000e9, 
                    1.00000000000e10, 1.000000000000e11, 1.0000000000000e12, 
                    1.00000000000000e13, 1.000000000000000e14, 1.0000000000000000e15,
                    1.00000000000000000e16, 1.000000000000000000e17}

test_equal("9. Correct scanning of zeroes in scientific notation:", 
                   {100, 1, 0, 0, 0, 1,
                    1, 10, 100, 1000, 10000, 100000, 
                    1000000, 10000000, 100000000, 1000000000, 
                    10000000000, 100000000000, 1000000000000, 
                    10000000000000, 100000000000000, 1000000000000000, 
                    10000000000000000, 100000000000000000}, dectest
          )
test_report()

