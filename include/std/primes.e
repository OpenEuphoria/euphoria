--****
-- == Prime Numbers
--
-- <<LEVELTOC level=2 depth=4>>

namespace primes

include std/search.e

sequence list_of_primes  = {2,3} -- Initial seedings.

--****
-- === Routines
--

--**
-- returns all the prime numbers below a threshold, with a cap on computation time.
--
-- Parameters:
--		# ##approx_limit## : an integer, This is not the upper limit but the last prime
--        returned is the //next// prime after or on this value.
--		# ##time_out_p## : an atom, the maximum number of seconds that this function can run for.
--                        The default is 10 (ten) seconds.
--
-- Returns:
--		A **sequence**, made of prime numbers in increasing order. The last value is 
--      the next prime number that falls on or //after// the value of ##approx_limit##.
--
-- Comments:
-- * The ##approx_limit## argument //does not// represent the largest value to return. 
--   The largest value returned will be the next prime number on or after ##approx_limit#.
--   The [[:prime_list]] function will allow to specify a upper limit.
-- * The returned sequence contains all the prime numbers less than its last element.
--
-- * If the function times out, it may not hold all primes below ##approx_limit##,
-- but only the largest ones will be absent. If the last element returned is 
-- less than ##approx_limit## then the function timed out.
--
-- * To disable the timeout, simply give it a negative value.
--
-- Example 1:
-- <eucode>
-- ? calc_primes(1000, 5)
-- -- On a very slow computer, you may only get all primes up to say 719. 
-- -- On a faster computer, the last element printed out will be 1009. 
-- -- This call will never take longer than 5 seconds.
-- </eucode>
--
-- See Also:
--		[[:next_prime]] [[:prime_list]]

public function calc_primes(integer approx_limit, atom time_limit_p = 10)
	sequence result_
	integer candidate_
	integer pos_
	atom time_out_
	integer maxp_
	integer maxf_
	integer maxf_idx
	integer next_trigger
	integer growth

	-- First we check to see if we have already got the requested value.	
	if approx_limit <= list_of_primes[$] then
		pos_ = search:binary_search(approx_limit, list_of_primes)
		if pos_ < 0 then
			pos_ = (-pos_)
		end if
		-- Already got it.
		return list_of_primes[1..pos_]
	end if
	
	-- Record the largest known prime (so far) and its index.
	pos_ = length(list_of_primes)
	candidate_ = list_of_primes[$]
	
	-- Calculate the largest possible factor for the largest known prime, and its index.
	maxf_ = floor(power(candidate_, 0.5))
	maxf_idx = search:binary_search(maxf_, list_of_primes)
	if maxf_idx < 0 then
		maxf_idx = (-maxf_idx)
		maxf_ = list_of_primes[maxf_idx]
	end if
	-- Calculate what the trigger is for when we need to go to the next maximum factor value.
	next_trigger = list_of_primes[maxf_idx+1]
	next_trigger *= next_trigger
	
	-- Pre-allocate space for the new values. This allocates more than we will
	-- need so the return value takes a slice up to the last stored prime.
	growth = floor(approx_limit  / 3.5) - length(list_of_primes)
	if growth <= 0 then
		growth = length(list_of_primes)
	end if
	result_ = list_of_primes & repeat(0, growth)

	-- Calculate when we must stop running. A negative value is really equivalent
	-- to a little over three years from now.
	if time_limit_p < 0 then
		time_out_ = time() + 100_000_000
	else
		time_out_ = time() + time_limit_p
	end if
	
	while time_out_ >= time()  label "MW" do
		-- As this could run for a significant amount of time,
		-- yield to any other tasks that might be ready.
		task_yield()

		-- Get the next candidate value to examine.		
		candidate_ += 2
		
		-- If this is at or past the factor trigger point
		-- pluck out the next maximum factor and calculate
		-- the next trigger.
		if candidate_ >= next_trigger then
			maxf_idx += 1
			maxf_ = result_[maxf_idx]
			next_trigger = result_[maxf_idx+1]
			next_trigger *= next_trigger
		end if
		
		-- Examine the candidate.
		for i = 2 to pos_ do
			-- If this potential factor is larger than the 'maximum' factor
			-- then we don't need to examine any more. The candidate is a prime.
			maxp_ = result_[i]
			if maxp_ > maxf_ then
				exit
			end if
			
			-- If it is divisible by any known prime then
			-- we go get another candidate value.
			if remainder(candidate_, maxp_) = 0 then
				continue "MW"
			end if
		end for
		
		-- Store it in the result, making sure that the result sequence is larger enough.
		pos_ += 1
		if pos_ >= length(result_) then
			result_ &= repeat(0, 1000)
		end if
		result_[pos_] = candidate_
		
		-- If the value just stored is larger or equal to the requested value
		-- then we can stop running.
		if candidate_ >= approx_limit then
			exit
		end if
	end while

	return result_[1..pos_]
end function


--**
-- returns the next prime number on or after the supplied number.
--
-- Parameters:
-- 		# ##n## : an integer, the starting point for the search
--		# ##fail_signal_p## : an integer, used to signal error. Defaults to -1.
--
-- Returns:
--		An **integer**, which is prime only if it took less than one second 
--      to determine the next prime greater or equal to ##n##.
--
-- Comments:
-- The default value of -1 will alert you about an invalid returned value,
-- since a prime not less than ##n## is expected. However, you can pass
-- another value for this parameter.
--
-- Example 1:
-- <eucode>
-- ? next_prime(997)
-- -- On a very slow computer, you might get -997, but 1009 is expected.
-- </eucode>
--
-- See Also:
-- [[:calc_primes]]

public function next_prime(integer n, object fail_signal_p = -1, atom time_out_p = 1)
	integer i

	if n < 0 then
		return fail_signal_p
	end if
	if list_of_primes[$] < n then
		list_of_primes = calc_primes(n,time_out_p)
	end if
	if n > list_of_primes[$] then
		return fail_signal_p
	end if
	-- Assumes that most searches will be less than about 1000
	if n < 1009 and 1009 <= list_of_primes[$] then
		i = search:binary_search(n, list_of_primes, ,169)
	else
		i = search:binary_search(n, list_of_primes)
	end if
	if i < 0 then
		i = (-i)
	end if
	return list_of_primes[i]

end function

--**
-- returns a list of prime numbers.
--
-- Parameters:
-- 		# ##top_prime_p## : The list will end with the prime less than or equal
--        to this value. If ##top_prime_p## is zero, the current list of calculated primes
--        is returned.
--
-- Returns:
--		An **sequence**, a list of prime numbers from ##2## to ##<=## ##top_prime_p##
--
-- Example 1:
-- <eucode>
-- sequence pList = prime_list(1000)
-- -- pList will now contain all the primes from 2 up to the largest less than or
-- --    equal to 1000, which is 997.
-- </eucode>
--
-- See Also:
-- [[:calc_primes]], [[:next_prime]]
--
public function prime_list(integer top_prime_p = 0)
	integer index_
	
	if top_prime_p <= 0 then
		return list_of_primes
	end if
	
	if list_of_primes[$] < top_prime_p then
		list_of_primes = calc_primes(top_prime_p, 5)
	end if
	
	index_ = search:binary_search(top_prime_p, list_of_primes)
	if index_ < 0 then
		index_ = - index_
	end if
	if list_of_primes[index_] > top_prime_p then
		index_ -= 1
	end if
	
	return list_of_primes[1 .. index_]
end function	
