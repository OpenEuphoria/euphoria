include search.e
include machine.e
--****
-- Category: 
--   primes
--
-- Title:
--   Euphoria Standard Library List of prime numbers less than 10,000
--****


global sequence gPrimes 
gPrimes = {2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61}

-- TODO: document
global function calc_primes(integer pMax, atom pTimeLimit = 10)
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

-- TODO: document
-- Returns the next prime number on or after 'n'
global function next_prime(integer n, integer pDefault = 1)
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

