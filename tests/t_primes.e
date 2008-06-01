include unittest.e
include primes.e as m


set_test_module_name("primes.e")

test_equal("primes found #1" , 541, next_prime(540))
test_equal("primes found #2" , 541, next_prime(541))
test_equal("primes found #3" , 547, next_prime(542))

test_equal("primes missing #1" , 0, next_prime(100000000, 0))
test_equal("primes missing #2" , 100000000, next_prime(100000000))
test_equal("primes missing #3" , 2, next_prime(-1))
