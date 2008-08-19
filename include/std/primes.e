-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Prime Numbers
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>
namespace primes

include search.e

sequence list_of_primes = {2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61}

--****
-- === Routines
--

sequence timed_out = {}, returned = {}

procedure time_out(integer slot)
	if returned[slot]=0 then
		timed_out[slot] = 1
	end if
	returned[slot] = -1
end procedure
constant rTime_out = routine_id("time_out")

--**
-- Returns all the prime numbers below some threshhold, with a cap on computation time.
--
-- Parameters:
--		# ##max_p##: an integer, the value below which all returned prime numbers will be
--		# ##time_out_p##: an atom, the number of seconds allotted to computation. Defaults to 10.0.
--
-- Returns:
--		A **sequence** made of prime numbers below ##max_p##, in increasing order.
--
-- Comments:
-- The returned sequence does not miss any prime number in less than its last and largest element. If the function times out, it may not hold all primes below ##max_p##, but only the largest ones will be absent.
--
-- There is no provision to disable the timeout. Simply give it a large enough value.
--
-- Example 1:
-- <eucode>
-- ?calc_primes(1000,5)
-- -- On a very slow computer, you may only get all primes up to say 719. On a faster computer, the last element printed out will be 997. The function always returns within 5 seconds.
-- </eucode>
--
-- See Also:
--		[[:next_prime]]

public function calc_primes(integer max_p, atom time_limit_p = 10)
	sequence result_
	integer candidate_
	integer low_
	atom time_out_
	integer pos_
	integer top_
	integer slot
	
	if max_p <= list_of_primes[$] then
		pos_ = binary_search(max_p, list_of_primes)
		if pos_ < 0 then
			pos_ = (-pos_)
		end if
		return list_of_primes[1..pos_]
	end if
	result_ = list_of_primes & repeat(0, floor(max_p  / 3.5))

	--lTimeOut = time() + time_limit_p
	slot = find(-1, returned)
	-- there s no task_killl(). If the function returns before time out, the slot must not be
	-- recycled. 0 means active, 1 means return done, -1 means can recycle
	if slot=0 then
	    timed_out &= 0
	    returned &= 0
	    slot = length(returned)
	else
		timed_out[slot] = 0
		returned[slot] = 0
	end if
	task_schedule(task_create(rTime_out, {slot}), {time_limit_p, time_limit_p * 1.02})
-- 
	pos_ = length(list_of_primes)

	while result_[pos_] < max_p do
		if timed_out[slot] then
-- 		if time() > time_out_ then
			exit
		end if

		top_ = result_[pos_]
		candidate_ = top_ * 2 - 1
		for i = 2 to pos_ label "TL" do
			for j = i to pos_ do
				low_ = result_[i] * result_[j]
				if low_ = candidate_ then
					candidate_ += 2
				elsif low_ > top_ and low_ < candidate_ and and_bits(low_,1) = 1 then
					candidate_ = low_
					exit "TL"
				end if
			end for
		end for
		
		low_ = 0
		while low_ = 0 do
			for i = top_ + 2 to candidate_ by 2 do
				low_ = i
				for j = 2 to pos_ do
					if remainder(i, result_[j]) = 0 then
						low_ = 0
						exit
					end if
				end for
				if low_ = i then
					candidate_= low_
					exit
				end if
			end for
			if low_ != 0 then
				pos_ += 1
				if pos_ > length(result_) then
					result_ &= repeat(0, 1000)
				end if
				result_[pos_] = candidate_
			else
				candidate_ += 2
			end if
		end while
		task_yield()
	end while

	returned[slot] = 1
	return result_[1..pos_]
end function

--**
-- Return the next prime number on or after some number
--
-- Paremeters:
-- 		# ##n##: an integer, the starting point for the search
--		# ##default_value_p##: an integer, used to signal error. Defaults to -1.
--
-- Returns:
--		An **integer**, which is prime only if it took less than 1 second 
--      to determine the next prime greater or equal to ##n##.
--
-- Comments:
-- The default value of -1 will alert you about an invalid returned value,
-- since a prime not less than ##n## is expected. However, you can pass
-- another value for this parameter.
--
-- Example 1:
-- <eucode>
-- ?next_prime(997)
-- -- On a very slow computer, you might get -997, but 1003 is expected.
-- </eucode>
--
-- See Also:
-- [[:calc_primes]]

public function next_prime(integer n, integer default_value_p = -1, atom time_out_p = 1)
	integer i


	if n < 0 then
		return default_value_p
	end if
	if list_of_primes[$] < n then
		list_of_primes = calc_primes(n,time_out_p)
	end if
	if n > list_of_primes[$] then
		return n * default_value_p
	end if
	-- Assumes that most searches will be less than about 1000
	if n < 1009 and 1009 <= list_of_primes[$] then
		i = binary_search(n, list_of_primes, ,169)
	else
		i = binary_search(n, list_of_primes)
	end if
	if i < 0 then
		i = (-i)
	end if
	return list_of_primes[i]

end function

--**
-- Returns a list of prime numbers.
--
-- Paremeters:
-- 		# ##top_prime_p##: The list will end with the prime less than or equal
--        to this value. If this is zero, the current list calculated primes
--        is returned.
--
-- Returns:
--		An **sequence**, a list of prime numbers from 2 to ##top_prime_p##
--
-- Example 1:
-- <eucode>
-- sequence pl = prime_list(1000)
-- -- pl will now contain all the primes from 2 up to the largest less than or
-- --    equal to 1000.
-- </eucode>
--
-- See Also:
-- [[:calc_primes]], [[:next_prime]]
public function prime_list(integer top_prime_p = 0)
	integer index_
	
	if top_prime_p <= 0 then
		return list_of_primes
	end if
	
	if list_of_primes[$] < top_prime_p then
		list_of_primes = calc_primes(top_prime_p, 5)
	end if
	
	index_ = binary_search(top_prime_p, list_of_primes)
	if index_ < 0 then
		index_ = - index_
	end if
	
	return list_of_primes[1 .. index_]
end function	