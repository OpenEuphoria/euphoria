include unittest.e
include primes.e

integer s

gPrimes = {2,3,5,7,11,13}
s = length(gPrimes)
test_equal("primes found #1" , 541, next_prime(540))
test_true("primes growth #1", s < length(gPrimes))
s = length(gPrimes)
test_equal("primes found #2" , 541, next_prime(541))
test_equal("primes found #3" , 547, next_prime(542))
test_true("primes growth #2", s < length(gPrimes))
s = length(gPrimes)

test_equal("primes missing #1" , 0, next_prime(200000, 0))
test_true("primes growth #3", s < length(gPrimes))
s = length(gPrimes)
test_equal("primes missing #2" , 2, next_prime(-1))
test_true("primes growth #4", s = length(gPrimes))

test_embedded_report()

