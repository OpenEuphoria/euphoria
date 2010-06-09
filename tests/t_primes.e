include std/unittest.e
include std/primes.e

sequence list_of_primes = prime_list( 11 )
test_equal( "prime list (11)", 11, list_of_primes[$] )

test_equal( "calc_primes up to 5 (already calc'd)", {2,3,5}, calc_primes(5) )

integer s
test_equal("primes found #0" , 37, next_prime(32))

list_of_primes = prime_list()


s = length(list_of_primes)
test_equal("primes found #1" , 541, next_prime(540))
test_true("primes growth #1", s < length(prime_list()))
s = length(prime_list())
test_equal("primes found #2" , 541, next_prime(541))
test_equal("primes found #3" , 547, next_prime(542))
test_true("primes growth #2", s < length(prime_list()))
s = length(prime_list())

integer n = next_prime(200000, 0, 0) -- use timeout of zero to force error
test_equal("primes missing #1" , 0, n)

test_true("primes growth #3", s < length(prime_list()))
s = length(prime_list())
test_equal("primes missing #2" , -1, next_prime(-1))
test_true("primes growth #4", s = length(prime_list()))


test_true("primes time out", next_prime(100_000_000, -1, 0.1) = -1)



test_report()

