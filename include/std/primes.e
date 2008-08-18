-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Prime Numbers
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>

include search.e

public sequence gPrimes = {2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61}

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
--		# ##pMax##: an integer, the value below which all returned prime numbers will be
--		# ##pTimeOut##: an atom, the number of seconds allotted to computation. Defaults to 10.0.
--
-- Returns:
--		A **sequence** made of prime numbers below ##pMax##, in increasing order.
--
-- Comments:
-- The returned sequence does not miss any prime number in less than its last and largest element. If the function times out, it may not hold all primes below ##pMax##, but only the largest ones will be absent.
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

public function calc_primes(integer pMax, atom pTimeLimit = 10)
	sequence lResult
	integer lCandidate
	integer lLo
	atom lTimeOut
	integer lPos
	integer lTop
	integer slot
	
	if pMax <= gPrimes[$] then
		lPos = binary_search(pMax, gPrimes)
		if lPos < 0 then
			lPos = (-lPos)
		end if
		return gPrimes[1..lPos]
	end if
	lResult = gPrimes & repeat(0, floor(pMax  / 3.5))

	--lTimeOut = time() + pTimeLimit
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
	task_schedule(task_create(rTime_out, {slot}), {pTimeLimit, pTimeLimit * 1.02})
-- 
	lPos = length(gPrimes)

	while lResult[lPos] < pMax do
		if timed_out[slot] then
-- 		if time() > lTimeOut then
			exit
		end if

		lTop = lResult[lPos]
		lCandidate = lTop * 2 - 1
		for i = 2 to lPos label "TL" do
			for j = i to lPos do
				lLo = lResult[i] * lResult[j]
				if lLo = lCandidate then
					lCandidate += 2
				elsif lLo > lTop and lLo < lCandidate and and_bits(lLo,1) = 1 then
					lCandidate = lLo
					exit "TL"
				end if
			end for
		end for
		
		lLo = 0
		while lLo = 0 do
			for i = lTop + 2 to lCandidate by 2 do
				lLo = i
				for j = 2 to lPos do
					if remainder(i, lResult[j]) = 0 then
						lLo = 0
						exit
					end if
				end for
				if lLo = i then
					lCandidate= lLo
					exit
				end if
			end for
			if lLo != 0 then
				lPos += 1
				if lPos > length(lResult) then
					lResult &= repeat(0, 1000)
				end if
				lResult[lPos] = lCandidate
			else
				lCandidate += 2
			end if
		end while
		task_yield()
	end while

	returned[slot] = 1
	return lResult[1..lPos]
end function

--**
-- Return the next prime number on or after some number
--
-- Paremeters:
-- 		# ##n##: an integer, the starting point for the search
--		# ##pDefault##: an integer, used to signal error. Defaults to -1.
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

public function next_prime(integer n, integer pDefault = -1, atom pTimeOut = 1)
	integer i


	if n < 0 then
		return pDefault
	end if
	if gPrimes[$] < n then
		gPrimes = calc_primes(n,pTimeOut)
	end if
	if n > gPrimes[$] then
		return n * pDefault
	end if
	-- Assumes that most searches will be less than about 1000
	if n < 1009 and 1009 <= gPrimes[$] then
		i = binary_search(n, gPrimes, ,169)
	else
		i = binary_search(n, gPrimes)
	end if
	if i < 0 then
		i = (-i)
	end if
	return gPrimes[i]

end function
