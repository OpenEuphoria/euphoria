include std/machine.e

atom ptr = allocate(8)
atom value = power(2,64)
poke8(ptr, value)
 
include std/unittest.e

test_fail("Should not be able to poke 2^64 with poke8")
test_report()
