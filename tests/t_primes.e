include std/unittest.e
include std/primes.e

sequence list_of_primes = prime_list( 10 )
test_equal( "prime list (11)", 11, list_of_primes[$] )

test_equal( "calc_primes up to 5 (already calc'd)", {2,3,5}, calc_primes(5) )

test_equal( "calc_primes up to 5 (already calc'd)", {2,3,5}, calc_primes(5) )
test_equal( "calc_primes up to 11", {2,3,5,7,11}, calc_primes(8))

integer s
test_equal("primes found #0" , 37, next_prime(32))

list_of_primes = calc_primes(100, -1)
test_equal("No time limit", 101, list_of_primes[$])
test_equal("Sanity check #1", 26, length(list_of_primes))
for i = 2 to length(list_of_primes) do
	integer N = list_of_primes[i]
	for j = 1 to i - 1 do
		test_false("Sanity check #2", 0 = remainder(N, list_of_primes[j]))
	end for
end for

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

test_equal("fast search", 997, next_prime(996))


test_report()

