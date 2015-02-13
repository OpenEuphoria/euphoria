include std/unittest.e
include std/error.e
-- the biggest double (scinot.e:391)
atom max_atom = 1.7976931348623157081e308
-- bigger than half the biggest double (in binary this is analogous to a base 10 number like
-- 9.999999 and will overflow the matissa when it rounds off.  And if the exponent is not incremented
-- it will get evaulated as 1.0 rather than 10.  Similiarly in binary, this number should evaluate
-- to about 9e307 but if the exponents are not adjusted in scinot.e, it will be evaluated as 4.5e307.
atom        b = 8.9884656743115795e307
-- bigger than the biggest double.
atom        a = 1.79769313486231582e308
test_pass("Huge floating point notation number")
test_report()
