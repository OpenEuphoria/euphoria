-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Statistics
-- === Routines

include unittest.e
include math.e
include sort.e

with trace

--**
-- Returns the k-th smallest value from the supplied set of numbers. 
--
-- Returns:
-- atom 
--
-- Comments: small() is used to reurn a value based on its relative size.
-- The set of numbers does not have to be in any order.
--
-- Example 1:
--   <eucode>
--   ? small( {4,5,6,8,5,4,3,"text"}, 3 ) -- Ans: 4 (The 3rd smallest number)
--   ? small( {4,5,6,8,5,4,3,"text"}, 1 ) -- Ans: 3 (The 1st smallest number)
--   ? small( {4,5,6,8,5,4,3,"text"}, 7 ) -- Ans: 8 (The 7th smallest number)
--   </eucode>
--
-- Parameters:
--   * pData = A list of 1 or more numbers.
--   * pIndex = Which smallest number you want. 1 returns the smallest and length(pData)
--     returns the highest. If pIndex is less than one or greater then length of pData,
--     and empty sequence is returned.
--

export function small(sequence pData, integer pIndex)
	sequence lSortedData
	
	if pIndex < 1 or pIndex > length(pData) then
		return {}
	end if
	
	lSortedData = sort(pData)
	
	return lSortedData[pIndex]
end function

--**
-- Returns the standard deviation based on a random sample of the population. 
-- The equation for average deviation is: 
--
-- {{{
-- stdev(X) ==> SQRT(SUM(SQ(X{1..N} - MEAN)) / (N-1))
-- }}}
--
-- Parameters:
-- * pData = A list of 1 or more numbers for which you want the estimated standard deviation.
--           These numbers are assumed to represent a random sample, a subset, of 
--           a larger set of numbers.
--           Note that only atom elements are included, any sequences elements are ignored.
-- Returns:
--   atom 
-- 
-- Comments: 
-- stdev() is a measure of how values are different from the average.
-- This function differs from stdeva() in that this ignores all elements that are
-- sequences.
--
--
-- Example 1:
--   <eucode>
--   ? stdev( {4,5,6,7,5,4,3,"text"} ) -- Ans: 
--   </eucode>
--
-- See also:
--   average, avedev, var, stdeva
--

export function stdev(sequence pData)
	atom lSum
	atom lMean
	integer lCnt
	
	lSum = 0
	lCnt = 0
	for i = 1 to length(pData) do
		if atom(pData[i]) then
			lSum += pData[i]
			lCnt += 1
		end if
	end for
	if lCnt = 0 then
		return {}
	end if
	if lCnt = 1 then
		return 0
	end if
	
	lMean = lSum / lCnt
	lSum = 0
	for i = 1 to length(pData) do
		if atom(pData[i]) then
			lSum += power(pData[i] - lMean, 2)
		end if
	end for
	
	return power(lSum / (lCnt - 1), 0.5)
end function

--**
-- Returns the estimated standard deviation based on a random sample of the population. 
-- The equation for average deviation is: 
--
-- {{{
-- stdeva(X) ==> SQRT(SUM(SQ(X{1..N} - MEAN)) / (N-1))
--}}}
--
-- Parameters:
-- * pData = A list of 1 or more numbers for which you want the estimated standard deviation.
--           These numbers are assumed to represent a random sample, a subset, of 
--           a larger set of numbers.
--           Note that any sequences elements are assumed to have a value of zero.
--
-- Returns:
--   atom 
--
-- Comments: 
-- stdeva() is a measure of how values are different from the average.
-- This function differs from stdev() in that this treats all elements that are
-- sequences as having a value of zero.
--
-- Example 1:
--   <eucode>
--   ? stdeva( {4,5,6,7,5,4,3,"text"} ) -- Ans:
--   </eucode>
--
-- See also:
--   average, avedev, var, stdev
--

export function stdeva(sequence pData)
	atom lSum
	atom lMean
	integer lCnt
	
	lCnt = length(pData)
	if lCnt = 0 then
		return {}
	end if
	if lCnt = 1 then
		return 0
	end if
	
	lSum = 0
	for i = 1 to length(pData) do
		if atom(pData[i]) then
			lSum += pData[i]
		end if
	end for
	
	lMean = lSum / lCnt
	lSum = 0
	for i = 1 to length(pData) do
		if atom(pData[i]) then
			lSum += power(pData[i] - lMean, 2)
		else
			lSum += power(lMean, 2)
		end if
	end for
	
	return power(lSum / (lCnt - 1), 0.5)
end function

-- TODO: remove tests
test_equal("stdeva list", 2.121320344, stdeva( {4,5,6,7,5,4,3,"text"} ))
test_equal("stdeva 1", 0, stdeva( {100} ))
test_equal("stdeva text", 0, stdeva( {"text"} ))
test_equal("stdeva empty", {}, stdeva( {} ))


--**
-- Returns the estimated standard deviation based of the population. 
-- The equation for average deviation is: 
--
-- {{{
-- stdev(X) ==> SQRT(SUM(SQ(X{1..N} - MEAN)) / N)
-- }}}
--
-- Parameters:
--   * pData = A list of 1 or more numbers for which you want the standard deviation.
--             These numbers are assumed to represent the entire population to test.
--             Note that only atom elements are included, any sequences elements are ignored.
--
-- Returns:
--   atom 
--
-- Comments: 
-- stdevp() is a measure of how values are different from the average.
-- This function differs from stdevpa() in that this ignores all elements that are
-- sequences.
--
-- Example 1:
--   <eucode>
--   ? stdevp( {4,5,6,7,5,4,3,"text"} ) -- Ans: 
--   </eucode>
--
-- See also:
--   average, avedev, var, stdevpa, stdev
--

export function stdevp(sequence pData)
	atom lSum
	atom lMean
	integer lCnt
	
	lSum = 0
	lCnt = 0
	for i = 1 to length(pData) do
		if atom(pData[i]) then
			lSum += pData[i]
			lCnt += 1
		end if
	end for
	if lCnt = 0 then
		return {}
	end if
	if lCnt = 1 then
		return 0
	end if
	
	lMean = lSum / lCnt
	lSum = 0
	for i = 1 to length(pData) do
		if atom(pData[i]) then
			lSum += power(pData[i] - lMean, 2)
		end if
	end for
	
	return power(lSum / lCnt, 0.5)
end function

--**
-- Returns the standard deviation based of the population. 
-- The equation for average deviation is: 
--
-- {{{
-- stdevpa(X) ==> SQRT(SUM(SQ(X{1..N} - MEAN)) / N)
-- }}}
--
-- Parameters:
--   * pData = A list of 1 or more numbers for which you want the estimated standard deviation.
--             These numbers are assumed to represent the entire population to test.
--             Note that any sequences elements are assumed to have a value of zero.
--
-- Returns:
--   atom 
--
-- Comments: stdevpa() is a measure of how values are different from the average.
-- This function differs from stdevp() in that this treats all elements that are
-- sequences as having a value of zero.
--
-- Example 1:
--   ? stdevpa( {4,5,6,7,5,4,3,"text"} ) -- Ans: 
--
-- See also:
--   average, avedev, var, stdevp, stdev
--

export function stdevpa(sequence pData)
	atom lSum
	atom lMean
	integer lCnt
	
	lCnt = length(pData)
	if lCnt = 0 then
		return {}
	end if
	if lCnt = 1 then
		return 0
	end if
	
	lSum = 0
	for i = 1 to length(pData) do
		if atom(pData[i]) then
			lSum += pData[i]
		end if
	end for
	
	lMean = lSum / lCnt
	lSum = 0
	for i = 1 to length(pData) do
		if atom(pData[i]) then
			lSum += power(pData[i] - lMean, 2)
		else
			lSum += power(lMean, 2)
		end if
	end for
	
	return power(lSum / lCnt , 0.5)
end function

--**
-- Returns the average of the absolute deviations of data points from their mean. 
-- The equation for average deviation is: 
--
-- {{{
-- avedev(X) ==> SUM( ABS(X{1..N} - MEAN(X)) ) / N
-- }}}
--
-- Parameters:
--   * pData = A list of 1 or more numbers for which you want the mean of the absolute deviations.
--             Note that only atom elements are included, any sequences elements are ignored.
--
-- Returns:
--   atom 
--
-- Comments: 
--   avedev() is a measure of the variability in a data set.
--
-- Example 1:
--   <eucode>
--   ? avedev( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"} ) -- Ans: 1.85777777777778
--   </eucode>
--
-- See also:
--   average, stdev, var
--

export function avedev(sequence pData)
	atom lSum
	atom lMean
	integer lCnt
	
	lSum = 0
	lCnt = 0
	for i = 1 to length(pData) do
		if atom(pData[i]) then
			lSum += pData[i]
			lCnt += 1
		end if
	end for
	if lCnt = 0 then
		return {}
	end if
	
	lMean = lSum / lCnt
	lSum = 0
	for i = 1 to length(pData) do
		if atom(pData[i]) then
			if pData[i] > lMean then
				lSum += pData[i] - lMean
			else
				lSum += lMean - pData[i]
			end if
		end if
	end for
	
	return lSum / lCnt
end function

--**
export function sum(object pData)
	atom pResult
	if atom(pData) then
		pResult = pData
	else
		pResult = 0
		for i = 1 to length(pData) do
			if atom(pData[i]) then
				pResult += pData[i]
			end if
		end for
	end if
	return pResult
end function

--**
export function count(object pData)
	atom pResult
	if atom(pData) then
		pResult = 1
	else
		pResult = 0
		for i = 1 to length(pData) do
			if atom(pData[i]) then
				pResult += 1
			end if
		end for
	end if
	return pResult
end function

--**
export function counta(object pData)
	atom pResult
	if atom(pData) then
		pResult = 1
	else
		pResult = length(pData)
	end if
	return pResult
end function

--**
export function average(object pData)
	integer lCount
	if atom(pData) then
		return pData
	end if
	lCount = count(pData)
	if lCount = 0 then
		return {}
	end if
	return sum(pData) / lCount
end function

--**
export function averagea(object pData)
	if atom(pData) or length(pData) = 0 then
		return pData
	end if
	return sum(pData) / length(pData)
end function

--**
export function largest(object pData)
	atom pResult, pTemp
	integer pStarted
	if atom(pData) then
			return pData
	end if
	pStarted = 0
	for i = 1 to length(pData) do
		if atom(pData[i]) then
			pTemp = max(pData[i])
			if pStarted then
				if pTemp > pResult then
					pResult = pTemp
				end if
			else
				pResult = pTemp
				pStarted = 1
			end if
		end if
	end for
	if pStarted = 0 then
		return {}
	end if
	return pResult
end function

--**
export function smallest(object pData)
	atom pResult, pTemp
	integer pStarted
	if atom(pData) then
			return pData
	end if
	pStarted = 0
	for i = 1 to length(pData) do
		if atom(pData[i]) then
			pTemp = max(pData[i])
			if pStarted then
				if pTemp < pResult then
					pResult = pTemp
				end if
			else
				pResult = pTemp
				pStarted = 1
			end if
		end if
	end for
	if pStarted = 0 then
		return {}
	end if
	return pResult
end function
