-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Statistics
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>
--
-- === Routines

include math.e
include sort.e

--**
-- Determines the k-th smallest value from the supplied set of numbers. 
--
-- Parameters:
-- # ##pData## - The list of values from which the smallest value is chosen.
-- # ##pIndex## - The relative index of the desired smallest value.
--
-- Returns:
-- ##sequence##: {The k-th smallest value, its index in the set}
--
-- Comments: 
-- ##small##() is used to return a value based on its size relative to
-- all the other elements in the sequence. When ##index## is 1, the smallest index is returned. Use ##index = length(pData)## to return the highest. 
--
-- If ##pIndex## is less than one, or greater then length of ##pData##,
--     an empty sequence is returned.
--
-- The set of values does not have to be in any particular order. The values may be any Euphoria object.
--
-- Example 1:
--   <eucode>
--   ? small( {4,5,6,8,5,4,3,"text"}, 3 ) -- Ans: {4,1} (The 3rd smallest value)
--   ? small( {4,5,6,8,5,4,3,"text"}, 1 ) -- Ans: {3,7} (The 1st smallest value)
--   ? small( {4,5,6,8,5,4,3,"text"}, 7 ) -- Ans: {8,4} (The 7th smallest value)
--   ? small( {"def", "qwe", "abc", "try"}, 2 ) -- Ans: {"def", 1} (The 2nd smallest value)
--   ? small( {1,2,3,4}, -1) -- Ans: {} -- no-value
--   ? small( {1,2,3,4}, 10) -- Ans: {} -- no-value
--   </eucode>
--

public function small(sequence pData, integer pIndex)
	sequence lSortedData

	if pIndex < 1 or pIndex > length(pData) then
		return {}
	end if
	
	lSortedData = sort(pData)
	
	return {lSortedData[pIndex], find(lSortedData[pIndex], pData)}
end function

--**
-- Returns the largest of the data points that are atoms.
--
-- Parameters:
--   # ##pData##: a list of 1 or more numbers among which you want the largest.
--
-- Returns:
--   An **object**, either of:
-- * an atom (the largest value) if there is at least one atom item in the set\\
-- * ##{} ##if there //is// no largest value.
--
-- Comments:
-- Any ##pData## element which is not an atom is ignored.
--
-- Example 1:
--   <eucode>
--   ? largest( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"} ) -- Ans: 8
--   ? largest( {"just","text"} ) -- Ans: {}
--   </eucode>
--
-- See also:
--   [[:range]]
--
public function largest(object pData)
	atom result_, temp_
	integer lFoundAny
	if atom(pData) then
		return pData
	end if
	lFoundAny = 0
	for i = 1 to length(pData) do
		if atom(pData[i]) then
			temp_ = pData[i]
			if lFoundAny then
				if temp_ > result_ then
					result_ = temp_
				end if
			else
				result_ = temp_
				lFoundAny = 1
			end if
		end if
	end for
	if lFoundAny = 0 then
		return {}
	end if
	return result_
end function

--**
-- Returns the smallest of the data points. 
--
-- Parameters:
--   # pData = A list of 1 or more numbers for which you want the smallest.
--             **Note:** only atom elements are included and any sub-sequences
--             elements are ignored.
--
-- Returns:
--   An **object**, either of:
-- * an atom (the smallest value) if there is at least one atom item in the set\\
-- * ##{} ##if there //is// no largest value.
--
-- Comments:
-- Any ##pData## element which is not an atom is ignored.
--
-- Example 1:
--   <eucode>
--   ? smallest( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"} ) -- Ans: 1
--   ? smallest( {"just","text"} ) -- Ans: {}
--   </eucode>
--
-- See also:
--   [[:range]]
public function smallest(object pData)
	atom result_, temp_
	integer lFoundAny
	if atom(pData) then
			return pData
	end if
	lFoundAny = 0
	for i = 1 to length(pData) do
		if atom(pData[i]) then
			temp_ = pData[i]
			if lFoundAny then
				if temp_ < result_ then
					result_ = temp_
				end if
			else
				result_ = temp_
				lFoundAny = 1
			end if
		end if
	end for
	if lFoundAny = 0 then
		return {}
	end if
	return result_
end function

--**
-- Determines a number of //range// statistics for the data set. 
--
-- Parameters:
--   # ##pData##: a list of 1 or more numbers for which you want the range data.
--
-- Returns:
--  A **sequence**, empty if no atoms were found, else like {Lowest, Highest, Range, Mid-range}
--
-- Comments:
-- Any sequence element in ##pData## is ignored.
--
-- Example 1:
--   <eucode>
--   ? range( {7,2,8,5,6,6,4,8,6,16,3,3,4,1,8,"text"} ) -- Ans: {1, 16, 15, 8.5}
--   </eucode>
--
-- See also:
--   [[:smallest]] [[:largest]]
--
public function range(object pData)
	sequence result_
	atom temp_
	integer lFoundAny = 0
	
	if atom(pData) then
		pData = {pData}
	end if
	
	for i = 1 to length(pData) do
		if atom(pData[i]) then
			temp_ = pData[i]
			if lFoundAny then
				if temp_ < result_[1] then
					result_[1] = temp_
				elsif temp_ > result_[2] then
					result_[2] = temp_
				end if
			else
				result_ = {temp_, temp_, 0, 0}
				lFoundAny = 1
			end if
		end if
	end for
	if lFoundAny = 0 then
		return {}
	end if
	result_[3] = result_[2] - result_[1]
	result_[4] = (result_[1] + result_[2]) / 2
	return result_
end function

--**
-- Returns the //estimated// standard deviation based on a random sample of the population. 
--
-- Parameters:
-- # ##pData##: a list of 1 or more numbers for which you want the estimated standard deviation.
--
-- Returns:
--    An **atom**, the estimated standard deviation.
--
-- Comments:
--
-- ##stdev##() is a measure of how values are different from the average. These numbers are
-- assumed to represent a random sample, a subset, of a larger set of numbers.
--
-- This function differs from [[:stdeva]]() in that this ##stdev##() ignores all elements that are
-- sequences. It differs from [[:stdevp]]() because it assumes that the mean of the sample depends on the sample, so there are only (number of observations)-1 independent data points to compute the deviation amidst.
--
-- The equation for //estimated// average deviation is:
--
-- {{{
-- stdev(X) ==> SQRT(SUM(SQ(X{1..N} - MEAN)) / (N-1))
-- }}}
--
-- Example 1:
--   <eucode>
--   ? stdev( {4,5,6,7,5,4,3,"text"} ) -- Ans: 1.345185418
--   </eucode>
--
-- See also:
--   [[:average]], [[:avedev]], [[:stdevp]], [[:stdeva]]
--

public function stdev(sequence pData)
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
--
-- Parameters:
-- # pData = A list of 1 or more numbers for which you want the estimated standard deviation.
--
-- Returns:
--    An **atom**, the estimated standard deviation.
--
-- Comments: 
--
-- ##stdeva##() is a measure of how values are different from the average.
-- This function differs from stdev() in that stdeva() treats all elements that are
-- sequences as having a value of zero.
--
-- The equation for average deviation is:
--
-- {{{
-- stdeva(X) ==> SQRT(SUM(SQ(X{1..N} - MEAN)) / (N-1))
-- }}}
--
-- Note that any sub-sequences elements are assumed to have a value of zero. From that point on,
-- these numbers are assumed to represent a random sample, a subset, of a larger set of numbers.
--
-- Example 1:
--   <eucode>
--   ? stdeva( {4,5,6,7,5,4,3,"text"} ) -- Ans: 2.121320344
--   </eucode>
--
-- See also:
--   [[:average]], [[:avedev]], [[:stdevp]], [[:stdev]]
--

public function stdeva(sequence pData)
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

--**
-- Returns the standard deviation based of the population. 
--
-- Parameters:
--   # pData = A list of 1 or more numbers for which you want the standard deviation.
--
-- Returns:
--   An **atom**, the standard deviation of the population.
--
-- Comments: 
--
-- ##stdevp##() is a measure of how values are different from the average.
-- This function differs from [[:stdevpa]]() in that ##stdevp##() ignores all elements that are
-- sequences.
--
-- The numbers are assumed to represent the entire population to test. This is how ##stdevp##()
-- differs from [[:stdev]](), as the mean does not depend on anything, and all observations are independent.
--
-- The equation for average deviation is: 
--
-- {{{
-- stdevp(X) ==> SQRT(SUM(SQ(X{1..N} - MEAN)) / N)
-- }}}
--
-- Example 1:
--   <eucode>
--   ? stdevp( {4,5,6,7,5,4,3,"text"} ) -- Ans: 1.245399698
--   </eucode>
--
-- See also:
--   [[:average]], [[:avedev]], [[:stdeva]], [[:stdevpa]], [[:stdev]]
--

public function stdevp(sequence pData)
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
--
-- Parameters:
--   # pData = A list of 1 or more numbers for which you want the estimated standard deviation.
--
-- Returns:
--   An **atom**, the standard deviation of the population.
--
-- Comments:
--
-- ##stdevpa##() is a measure of how values are different from the average.
-- This function differs from [[:stdevp]]() in that stdevpa() treats all elements that are
-- sequences as having a value of zero. The numbers are assumed to represent the entire population to test.
--
-- The equation for average deviation is:
--
-- {{{
-- stdevpa(X) ==> SQRT(SUM(SQ(X{1..N} - MEAN)) / N)
-- }}}
--
-- Example 1:
-- <eucode>
--   ? stdevpa( {4,5,6,7,5,4,3,"text"} ) -- Ans: 1.984313483
-- </eucode>
--
-- See also:
--   [[:average]], [[:avedev]], [[:stdeva]], [[:stdevp]], [[:stdev]]
--

public function stdevpa(sequence pData)
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
--
-- Parameters:
--   # ##pData##: a list of 1 or more numbers for which you want the mean of the absolute deviations.
--
-- Returns:
--   An **atom**, the average deviation from the mean.
--
-- Comments: 
--
--   ##avedev##() is a measure of the variability in a data set. Its statistical properties are well behaved than those of the standard deviation, which is why it is used less.
--
-- Note that only atom elements are included, any sub-sequences elements are ignored.
--
-- The equation for absolute average deviation is~:
--
-- {{{
-- avedev(X) ==> SUM( ABS(X{1..N} - MEAN(X)) ) / N
-- }}}
--
-- Example 1:
--   <eucode>
--   ? avedev( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"} ) -- Ans: 1.85777777777778
--   </eucode>
--
-- See also:
--   [[:average]], [[:stdev]]
--

public function avedev(sequence pData)
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
-- Returns the sum of all the atoms in an object.
--
-- Parameters:
--   # ##pData##: Either an atom or a list.
--
-- Returns:
--   An **atom**,  the sum of the atoms in the set.
--
-- Comments: 
--
--   ##sum##() is used as a measure of the magnitude of a sequence of positive values.
--
-- If ##pData## is an atom, then it is returned. Otherwise, atomic elements of a sequence are added up. If there are no atoms on ##pData##, the function returns 0.
--
-- The equation is~:
--
-- {{{
-- sum(X) ==> SUM( X{1..N} )
-- }}}
--
-- Example 1:
--   <eucode>
--   ? sum( {7,2,8.5,6,6,-4.8,6,6,3.341,-8,"text"} ) -- Ans: 32.041
--   </eucode>
--
-- See also:
--   [[:average]]

public function sum(object pData)
	atom result_
	if atom(pData) then
		result_ = pData
	else
		result_ = 0
		for i = 1 to length(pData) do
			if atom(pData[i]) then
				result_ += pData[i]
			end if
		end for
	end if
	return result_
end function

--**
-- Returns the count of all the atoms in an object.
--
-- Parameters:
--   # ##pData##: either an atom or a list.
--
-- Returns:
--
--    An **integer**, the number of atoms in the set. When ##pData## is an atom, 1 is returned.
--
-- Example 1:
--   <eucode>
--   ? count( {7,2,8.5,6,6,-4.8,6,6,3.341,-8,"text"} ) -- Ans: 10
--   ? count( {"cat", "dog", "lamb", "cow", "rabbit"} ) -- Ans: 0 (no atoms)
--   ? count( 5 ) -- Ans: 1
--   </eucode>
--
-- See also:
--   [[:average]], [[:sum]], [[:counta]]

public function count(object pData)
	atom result_
	if atom(pData) then
		result_ = 1
	else
		result_ = 0
		for i = 1 to length(pData) do
			if atom(pData[i]) then
				result_ += 1
			end if
		end for
	end if
	return result_
end function

--**
-- Returns the count of all the elements in an object.
--
-- Parameters:
--   # ##pData##: either an atom or a list.
--
-- Returns:
--   An **integer**, the number of elements in the set. When ##pData## is an atom, 1 is returned.
--
-- Comments:
--
-- This routine extends [[:length]]() to atoms by returning 1 on atoms.
--
-- Example 1:
--   <eucode>
--   ? count( {7,2,8.5,6,6,-4.8,6,6,3.341,-8,"text"} ) -- Ans: 11
--   ? count( {"cat", "dog", "lamb", "cow", "rabbit"} ) -- Ans: 5
--   ? count( 5 ) -- Ans: 1
--   </eucode>
--
-- See also:
--   [[:average]], [[:sum]], [[:count]], [[:length]]

public function counta(object pData)
	atom result_
	if atom(pData) then
		result_ = 1
	else
		result_ = length(pData)
	end if
	return result_
end function

--**
-- Returns the average (mean) of the data points.
--
-- Parameters:
--   # pData = A list of 1 or more numbers for which you want the mean.
--             **Note:** that only atom elements are included, any
--             sub-sequences elements are ignored.
--
-- Returns:
--	An **object**:
-- * ##{}## (the empty sequence) if there are no atoms in the set.
-- * an atom (the mean) if there are one or more atoms in the set.
--
-- Comments: 
--
--   ##average##() is the theoretical probable value of a randomly selected item from the set.
--
-- The equation for average  is:
--
-- {{{
-- average(X) ==> SUM( X{1..N} ) / N
-- }}}
--
-- Example 1:
--   <eucode>
--   ? average( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"} ) -- Ans: 5.13333333
--   </eucode>
--
-- See also:
--   [[:averagea]], [[:geomean]], [[:harmean]], [[:movavg]], [[:emovavg]]
--
public function average(object pData)
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
-- Returns the geometric mean of the atoms in a sequence.
--
-- Parameters:
--		# ##data##: the values to take the geometric mean of.
--
-- Returns:
--
-- An **atom** not less than zero, representing the geometric mean of the atoms in ##data##.
-- Sequences are ignored.
-- If there is no atom to take the mean of, 1 is returned.
--
-- Comments:
--
-- The geometric mean of ##n## atoms is the n-th root of their product. Signs are ignored.
--
-- This is useful to compute average growth rates.
--
-- Example 1:
-- <eucode>
-- ?geomean({3, {}, -2, 6}) -- prints out power(36,1/3) = 3,30192724889462669
-- </eucode>
--
-- See Also:
-- [[:average]]

public function geomean(sequence data)
	atom prod = 1.0
	integer count = length(data)

	for i=1 to length(data) do
		object x = data[i]
		
		if sequence(x) then
			count -= 1
		else
		    x *= compare(x,0)
		    if x=0 then
		        return 0.0
			else
			    prod *= x
		    end if
		end if
	end for
	if count > 2 then
		return power(prod, 1/count)
	elsif count = 2 then
		return sqrt(prod)
	else
		return prod
	end if
end function

--**
-- Returns the harmonic mean of the atoms in a sequence.
--
-- Parameters:
--		# ##data##: the values to take the geometric mean of.
--
-- Returns:
--
-- An **atom** representing the harmonic mean of the atoms in ##data##.
-- Sequences are ignored.
-- If there is no atom to take the mean of, or if 0 is on ##data##, 0 is returned.
--
-- Comments:
--
-- The harmonic mean of some atoms is the invers of the average of their inverses.
--
-- This is useful in engineering to compute equivalent capacities and resistances.
--
-- Example 1:
-- <eucode>
-- ?harmean({3, {}, -2, 6}) -- errors out, as the sum of inverses is 0.
-- ?harmean({{2, 3, 4}) -- prints out 36/11 = 3,27272727272727
-- </eucode>
--
-- See Also:
-- [[:average]]

public function harmean(sequence data)
	atom sum_inv = 0.0, last_x = 0.0
	integer count = length(data)

	for i=1 to length(data) do
		object x = data[i]
		
		if sequence(x) then
			count -= 1
		elsif x=0 then
	        return 0.0
		else
		    sum_inv += 1/x
		    last_x = x
		end if
	end for
	if count > 1 then
		return count / sum_inv
	else
		return last_x -- avoids double reciprocal
	end if
end function

--**
-- Returns the average (mean) of the data points.
--
-- Parameters:
--   # ##pData##: a list of 1 or more numbers for which you want the mean.
--
-- Returns:
--    An **object**, either ##{}## if there are no items in the set, or an **atom** (the mean) otherwise.
--
-- Comments:
--
--   ##averagea##() is the theoretical probable value of a randomly selected item from the 
-- set, at least when they follow a unimodal distribution.
--
-- All elements are included; any sequence elements are assumed to have the value zero.
--
-- The equation for average  is:
--
-- {{{
-- average(X) ==> SUM( X{1..N} ) / N
-- }}}
--
-- Example 1:
--   <eucode>
--   ? averagea( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"} ) -- Ans: 4.8125
--   </eucode>
--
-- See also:
--   [[:average]], [[:geomean]], [[:harmean]], [[:movavg]], [[:emovavg]]
--
public function averagea(object pData)
	if atom(pData) or length(pData) = 0 then
		return pData
	end if
	return sum(pData) / length(pData)
end function
 
--**
-- Returns the average (mean) of the data points for overlaping periods. This
-- can be either a simple or weighted moving average.
--
-- Parameters:
--   # ##pData##: a list of 1 or more numbers for which you want a moving average.
--   # ##pPeriod##: an object, either 
-- * an integer representing the size of the period, or
-- * a list of weightings to apply to the respective period positions.
--
-- Returns:
--   A **sequence**, either the requested averages or ##{}## if the Data sequence is empty or
--             the supplied period is less than one.
--
-- If a list of weights was supplied, the result is a weighted average; otherwise, it is a simple average.
--
-- Comments: 
--
--   A moving average is used to smooth out a set of data points over a period.\\
--   For example, given a period of 5:
-- # the first returned element is the average
--   of the first five data points [1..5], 
-- # the second returned element is
--   the average of the second five data points [2..6], \\and so on \\until
--   the last returned value is the average of the last 5 data points
--   [$-4 .. $].
--
-- When ##pPeriod## is an atom, it is rounded down to the width of the average. When it is a 
-- sequence, the width is its length. If there are not enough data points, zeroes are inserted.
--
--  Note that only atom elements are included and any sub-sequence elements are ignored.
--
-- Example 1:
--   <eucode>
--   ? movavg( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8}, 10 ) 
--    -- Ans: {5.8, 5.4, 5.5, 5.1, 4.7, 4.9}
--   ? movavg( {7,2,8,5,6}, 2 ) 
--    -- Ans: {4.5, 5, 6.5, 5.5}
--   ? movavg( {7,2,8,5,6}, {0.5, 1.5} ) 
--    -- Ans: {3.25, 6.5, 5.75, 5.75}
--   </eucode>
--
-- See also:
--   [[:average]]
--
public function movavg(object pData, object pPeriod)
	sequence result_ 
	integer lLow
	integer lHigh
	integer j
	integer n

	if atom(pData) then
		pData = {pData}
		
	elsif count(pData) = 0 then
		return pData
	end if
	
	if atom(pPeriod) then
		if floor(pPeriod) < 1 then
			return {}
		end if
		pPeriod = repeat(1, floor(pPeriod))
	end if
	
	if length(pData) < length(pPeriod) then
		pData = repeat(0, length(pPeriod) - length(pData)) & pData
	end if
	lLow = 1
	lHigh = length(pPeriod)
	result_ = repeat(0, length(pData) - length(pPeriod) + 1)
	while lHigh <= length(pData) do
		j = 1
		n = 0
		for i = lLow to lHigh do
			if atom(pData[i]) then
				result_[lLow] += pData[i] * pPeriod[j]
				n += 1
			end if
			j += 1
		end for
		if n > 0 then
			result_[lLow] /= n
		else
			result_[lLow] = 0
		end if

		lLow += 1
		lHigh += 1
	end while
		
	return result_
end function

--**
-- Returns the exponential moving average of a set of data points.
--
-- Parameters:
--   # ##pData##: a list of 1 or more numbers for which you want a moving average.
--   # ##pFactor##: an atom, the smoothing factor, typically between 0 and 1.
--
-- Returns:
--   A **sequence** made of the requested averages, or ##{}## if ##pData## is empty or
-- the supplied period is less than one.
--
-- Comments: 
--
--   A moving average is used to smooth out a set of data points over a period.
--
-- The formula used is:\\
-- : ##Y,,i,, = Y,,i-1,, + F * (X,,i,, - Y,,i-1,,)##
--
-- Note that only atom elements are included and any sub-sequences elements are ignored.
--
-- The smoothing factor controls how data is smoothed. 0 smoothes everything to 0, and 1 means no smoothing at all.
--
-- Any value for ##pFactor## outside the 0.0..1.0 range causes ##pFactor## 
-- to be set to the periodic factor ##(2/(N+1))##.
--
-- Example 1:
--   <eucode>
--   ? emovavg( {7,2,8,5,6}, 0.75 ) 
--    -- Ans: {5.25,2.8125,6.703125,5.42578125,5.856445313}
--   ? emovavg( {7,2,8,5,6}, 0.25 ) 
--    -- Ans: {1.75,1.8125,3.359375,3.76953125,4.327148438}
--   ? emovavg( {7,2,8,5,6}, -1 ) 
--    -- Ans: {2.333333333,2.222222222,4.148148148,4.432098765,4.95473251}
--   </eucode>
--
-- See also:
--   [[:average]]

public function emovavg(object pData, atom pFactor)
	atom lPrev
	
	if atom(pData) then
		pData = {pData}
		
	elsif count(pData) = 0 then
		return pData
	end if
	
	if pFactor < 0 or pFactor > 1 then
		pFactor = (2 / (count(pData) + 1))
	end if
	
	lPrev = average(pData)
	for i = 1 to length(pData) do
		if atom(pData[i]) then
			pData[i] = (pData[i] - lPrev) * pFactor + lPrev
			lPrev = pData[i]
		end if
	end for
	return pData
end function

