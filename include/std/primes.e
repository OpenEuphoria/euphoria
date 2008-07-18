-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Prime Numbers
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>

include search.e
include machine.e

--****
-- === Variables
--

--**

export sequence gPrimes = {2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61}

--****
-- === Routines
--

--**
-- Returns all the prime numbers below some threshold assessed in a possibly limited time.
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

export function calc_primes(integer pMax, atom pTimeLimit = 10)
	sequence lResult
	integer lCandidate
	integer lLo
	atom lTimeOut
	integer lPos
	integer lTop
	
	lTimeOut = time() + pTimeLimit
	if pMax <= gPrimes[$] then
		lPos = binary_search(pMax, gPrimes)
		if lPos < 0 then
			lPos = (-lPos)
		end if
		return gPrimes[1..lPos]
	end if
	lResult = gPrimes & repeat(0, floor(pMax  / 3.5))

	lPos = length(gPrimes)

	while lResult[lPos] < pMax and lTimeOut > time() do
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
	end while
	return lResult[1..lPos]
end function

--**
-- Return the next prime number on or after some number
--
-- Paremeters:
-- 		# ##n##: an integer, the starting point for the search
--		# ##pDefault##: an integer, used to signal a timed out search. Defaults to -1.
--
-- Returns:
--		An **integer**, which is prime only if it took less than 1 second to determine the next prime greater or equal to ##n##.
--
-- Comments:
-- The default value of -1 will alert you about an invalid returned value, since a prime not less than ##n## is expected. However, you can pass another value for this parameter.
--
-- Example 1:
-- <eucode>
-- ?next_prime(997)
-- -- On a very slow computer, you might get -997, but 1003 is expected.
-- </eucode>
--
-- See Also:
-- [[:calc_primes]]

export function next_prime(integer n, integer pDefault = -1)
	integer i


	if gPrimes[$] < n then
		gPrimes = calc_primes(n,1)
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
