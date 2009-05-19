-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Statistics
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>
--
-- === Routines

include std/math.e
include std/sort.e
include std/sequence.e


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
-- Enums used for to influence the results of some of these functions.

public enum
   --** 
   -- The supplied data is the entire population.
   ST_FULLPOP,
   
   --**
   -- The supplied data is only a random sample of the population.
   ST_SAMPLE

public constant ST_NOALT = SEQ_NOALT
   
function massage(sequence pData, object pMassage)
   	if atom(pMassage) or equal(pMassage, ST_NOALT) then
		return remove_subseq(pData, pMassage)
	end if
	
	if length(pMassage) > 0 then
		return remove_subseq(pData, 0)
	end if
	
	return pData
end function

--**
-- Returns the standard deviation based of the population. 
--
-- Parameters:
-- # ##pData##: a list of 1 or more numbers for which you want the estimated standard deviation.
-- # ##pMassage##: an object. When this is an empty sequence (the default) it 
--  means that ##pData## is assumed to contain no sub-sequences otherwise this
--  gives intructions about how to treat sub-sequences.
-- # ##pPop##: an integer. ST_SAMPLE (the default) assumes that ##pData## is a random
-- sample of the total population. ST_FULLPOP means that ##pData## is the
-- entire population.
--
-- Returns:
--    An **atom**, the estimated standard deviation.
--    An empty **sequence** means that there is no meaningful data to calculate from.
--
-- Comments:
-- ##stdev##() is a measure of how values are different from the average. 
--
-- The numbers in ##pData## can either be the entire population of values or
-- just a random subset. You indicate which in the ##pPop## parameter. By default
-- ##pData## represents a sample and not the entire population. When using this
-- function with sample data, the result is an //estimated// standard deviation.
--
-- If the data can contain sub-sequences, such as strings, you need to let the
-- the function know about this otherwise it assumes every value in ##pData## is
-- an number. If that is not the case then the function will crash. So it is
-- important that if it can possibly contain subsequences that you tell this
-- function what to do with them. Your choices are to ignore them or replace them
-- with some number. To ignore them, use ST_NOALT as the ##pMassage## parameter
-- value otherwise use the replacement value in ##pMassage##. However, if you
-- know that ##pData## only contains numbers use the default ##pMassage## value,
-- which is an empty sequence. **Note** It is faster if the data only contains
-- numbers.
--
-- The equation for standard deviation is:
-- {{{
-- stdev(X) ==> SQRT(SUM(SQ(X{1..N} - MEAN)) / (N))
-- }}}
--
-- Example 1:
--   <eucode>
--   ? stdev( {4,5,6,7,5,4,3,7} )                             -- Ans: 1.457737974
--   ? stdev( {4,5,6,7,5,4,3,7} ,, ST_FULLPOP)                -- Ans: 1.363589014
--   ? stdev( {4,5,6,7,5,4,3,"text"} , ST_NOALT)             -- Ans: 1.345185418
--   ? stdev( {4,5,6,7,5,4,3,"text"}, ST_NOALT, ST_FULLPOP ) -- Ans: 1.245399698
--   ? stdev( {4,5,6,7,5,4,3,"text"} , 0)                     -- Ans: 2.121320344
--   ? stdev( {4,5,6,7,5,4,3,"text"}, 0, ST_FULLPOP )         -- Ans: 1.984313483
--   </eucode>
--
-- See also:
--   [[:average]], [[:avedev]]
--

public function stdev(sequence pData, object pMassage = "", integer pPop = ST_SAMPLE)
	atom lSum
	atom lMean
	integer lCnt
	
	pData = massage(pData, pMassage)
	
	lCnt = length(pData)
	
	if lCnt = 0 then
		return {}
	end if
	if lCnt = 1 then
		return 0
	end if
	
	lSum = 0
	for i = 1 to length(pData) do
		lSum += pData[i]
	end for
	
	lMean = lSum / lCnt
	lSum = 0
	for i = 1 to length(pData) do
		lSum += power(pData[i] - lMean, 2)
	end for
	
	if pPop = ST_SAMPLE then
		lCnt -= 1
	end if
	
	return power(lSum / lCnt, 0.5)
end function

--**
-- Returns the average of the absolute deviations of data points from their mean.
--
-- Parameters:
-- # ##pData##: a list of 1 or more numbers for which you want the mean of the absolute deviations.
-- # ##pMassage##: an object. When this is an empty sequence (the default) it 
--  means that ##pData## is assumed to contain no sub-sequences otherwise this
--  gives intructions about how to treat sub-sequences.
-- # ##pPop##: an integer. ST_SAMPLE (the default) assumes that ##pData## is a random
-- sample of the total population. ST_FULLPOP means that ##pData## is the
-- entire population.
--
-- Returns:
--    An **atom**, the deviation from the mean.
--    An empty **sequence** means that there is no meaningful data to calculate from.
--
-- Comments:
-- ##avedev##() is a measure of the variability in a data set. Its statistical
-- properties are less well behaved than those of the standard deviation, which is
-- why it is used less. 
--
-- The numbers in ##pData## can either be the entire population of values or
-- just a random subset. You indicate which in the ##pPop## parameter. By default
-- ##pData## represents a sample and not the entire population. When using this
-- function with sample data, the result is an //estimated// deviation.
--
-- If the data can contain sub-sequences, such as strings, you need to let the
-- the function know about this otherwise it assumes every value in ##pData## is
-- an number. If that is not the case then the function will crash. So it is
-- important that if it can possibly contain subsequences that you tell this
-- function what to do with them. Your choices are to ignore them or replace them
-- with some number. To ignore them, use ST_NOALT as the ##pMassage## parameter
-- value otherwise use the replacement value in ##pMassage##. However, if you
-- know that ##pData## only contains numbers use the default ##pMassage## value,
-- which is an empty sequence. **Note** It is faster if the data only contains
-- numbers.
--
-- The equation for absolute average deviation is~:
-- {{{
-- avedev(X) ==> SUM( ABS(X{1..N} - MEAN(X)) ) / N
-- }}}
--
-- Example 1:
--<eucode>
-- ? avedev( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,7} ) -- Ans: 1.966666667
-- ? avedev( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,7},, ST_FULLPOP ) -- Ans: 1.84375
-- ? avedev( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"}, ST_NOALT  ) -- Ans: 1.99047619
-- ? avedev( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"}, ST_NOALT,ST_FULLPOP ) -- Ans: 1.857777778
-- ? avedev( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"}, 0 ) -- Ans: 2.225
-- ? avedev( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"}, 0, ST_FULLPOP ) -- Ans: 2.0859375
--</eucode>
--
-- See also:
--   [[:average]], [[:stdev]]
--

public function avedev(sequence pData, object pMassage = "", integer pPop = ST_SAMPLE)
	atom lSum
	atom lMean
	integer lCnt
	
	pData = massage(pData, pMassage)
	
	lCnt = length(pData)
	
	if lCnt = 0 then
		return {}
	end if
	if lCnt = 1 then
		return 0
	end if
	lSum = 0

	for i = 1 to length(pData) do
		lSum += pData[i]
	end for
	
	lMean = lSum / lCnt
	lSum = 0
	for i = 1 to length(pData) do
		if pData[i] > lMean then
			lSum += pData[i] - lMean
		else
			lSum += lMean - pData[i]
		end if
	end for
	
	if pPop = ST_SAMPLE then
		lCnt -= 1
	end if
	return lSum / lCnt
end function

--**
-- Returns the sum of all the atoms in an object.
--
-- Parameters:
-- # ##pData##: Either an atom or a list of numbers to sum.
-- # ##pMassage##: an object. When this is an empty sequence (the default) it 
--  means that ##pData## is assumed to contain no sub-sequences otherwise this
--  gives intructions about how to treat sub-sequences.
--
-- Returns:
--   An **atom**,  the sum of the set.
--
-- Comments: 
--   ##sum##() is used as a measure of the magnitude of a sequence of positive values.
--
-- If the data can contain sub-sequences, such as strings, you need to let the
-- the function know about this otherwise it assumes every value in ##pData## is
-- an number. If that is not the case then the function will crash. So it is
-- important that if it can possibly contain subsequences that you tell this
-- function what to do with them. Your choices are to ignore them or replace them
-- with some number. To ignore them, use ST_NOALT as the ##pMassage## parameter
-- value otherwise use the replacement value in ##pMassage##. However, if you
-- know that ##pData## only contains numbers use the default ##pMassage## value,
-- which is an empty sequence. **Note** It is faster if the data only contains
-- numbers.
--
-- The equation is~:
--
-- {{{
-- sum(X) ==> SUM( X{1..N} )
-- }}}
--
-- Example 1:
--   <eucode>
--   ? sum( {7,2,8.5,6,6,-4.8,6,6,3.341,-8,"text"}, 0 ) -- Ans: 32.041
--   </eucode>
--
-- See also:
--   [[:average]]

public function sum(object pData, object pMassage = "")
	atom result_
	if atom(pData) then
		return pData
	end if
	
	pData = massage(pData, pMassage)
	result_ = 0
	for i = 1 to length(pData) do
		result_ += pData[i]
	end for

	return result_
end function

--**
-- Returns the count of all the atoms in an object.
--
-- Parameters:
--   # ##pData##: either an atom or a list.
-- # ##pMassage##: an object. When this is an empty sequence (the default) it 
--  means that ##pData## is assumed to contain no sub-sequences otherwise this
--  gives intructions about how to treat sub-sequences.
--
-- Comments: 
-- This returns the number of numbers in ##pData##
--
-- If the data can contain sub-sequences, such as strings, you need to let the
-- the function know about this otherwise it assumes every value in ##pData## is
-- an number. If that is not the case then the function will crash. So it is
-- important that if it can possibly contain subsequences that you tell this
-- function what to do with them. Your choices are to ignore them or replace them
-- with some number. To ignore them, use ST_NOALT as the ##pMassage## parameter
-- value otherwise use the replacement value in ##pMassage##. However, if you
-- know that ##pData## only contains numbers use the default ##pMassage## value,
-- which is an empty sequence. **Note** It is faster if the data only contains
-- numbers.
--
-- Returns:
--
--  An **integer**, the number of atoms in the set. When ##pData## is an atom, 1 is returned.
--
-- Example 1:
--   <eucode>
--   ? count( {7,2,8.5,6,6,-4.8,6,6,3.341,-8,"text"} ) -- Ans: 10
--   ? count( {"cat", "dog", "lamb", "cow", "rabbit"} ) -- Ans: 0 (no atoms)
--   ? count( 5 ) -- Ans: 1
--   </eucode>
--
-- See also:
--   [[:average]], [[:sum]]

public function count(object pData, object pMassage = "")
	atom result_
	if atom(pData) then
		return 1
	end if
	
	return length(massage(pData, pMassage))

end function


--**
-- Returns the average (mean) of the data points.
--
-- Parameters:
--   # pData = A list of 1 or more numbers for which you want the mean.
-- # ##pMassage##: an object. When this is an empty sequence (the default) it 
--  means that ##pData## is assumed to contain no sub-sequences otherwise this
--  gives intructions about how to treat sub-sequences.
--
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
--   ? average( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"}, ST_NOALT ) -- Ans: 5.13333333
--   </eucode>
--
-- See also:
--   [[:geomean]], [[:harmean]], [[:movavg]], [[:emovavg]]
--
public function average(object pData, object pMassage = "")
	integer lCount
	if atom(pData) then
		return pData
	end if
	
	pData = massage(pData, pMassage)
	
	if length(pData) = 0 then
		return {}
	end if
	return sum(pData) / length(pData)
end function

--**
-- Returns the geometric mean of the atoms in a sequence.
--
-- Parameters:
-- # ##pData##: the values to take the geometric mean of.
-- # ##pMassage##: an object. When this is an empty sequence (the default) it 
--  means that ##pData## is assumed to contain no sub-sequences otherwise this
--  gives intructions about how to treat sub-sequences.
--
-- Returns:
--
-- An **atom**; the geometric mean of the atoms in ##pData##.
-- If there is no atom to take the mean of, 1 is returned.
--
-- Comments:
--
-- The geometric mean of ##N## atoms is the N-th root of their product. Signs are ignored.
--
-- This is useful to compute average growth rates.
--
-- Example 1:
-- <eucode>
-- ? geomean({3, "abc", -2, 6}, ST_NOALT) -- prints out power(36,1/3) = 3,30192724889462669
-- ? geomean({1,2,3,4,5,6,7,8,9,10}) -- = 4.528728688
-- </eucode>
--
-- See Also:
-- [[:average]]

public function geomean(object pData, object pMassage = "")
	atom prod_ = 1.0
	integer count_

	if atom(pData) then
		return pData
	end if
	
	pData = massage(pData, pMassage)
	
	count_ = length(pData)
	if count_ = 0 then
		return 1
	end if
	if count_ = 1 then
		return pData[1]
	end if
	
	for i = 1 to length(pData) do
		atom x = pData[i]
		
	    if x = 0 then
	        return 0
		else
		    prod_ *= x
	    end if

	end for

	if prod_ < 0 then
		return power(-prod_, 1/count_)
	else	
		return power(prod_, 1/count_)
	end if

end function

--**
-- Returns the harmonic mean of the atoms in a sequence.
--
-- Parameters:
-- # ##pData##: the values to take the harmonic mean of.
-- # ##pMassage##: an object. When this is an empty sequence (the default) it 
--  means that ##pData## is assumed to contain no sub-sequences otherwise this
--  gives intructions about how to treat sub-sequences.
--
-- Returns:
--
-- An **atom**; the harmonic mean of the atoms in ##pData##.
--
-- Comments:
-- The harmonic mean is the inverse of the average of their inverses.
--
-- This is useful in engineering to compute equivalent capacities and resistances.
--
-- Example 1:
-- <eucode>
-- ?harmean({3, "abc", -2, 6}, ST_NOALT) -- =  0.
-- ?harmean({{2, 3, 4}) -- 3 / (1/2 + 1/3 + 1/4) = 2.769230769
-- </eucode>
--
-- See Also:
-- [[:average]]

public function harmean(sequence pData, object pMassage = "")
	integer count_

	if atom(pData) then
		return pData
	end if
	
	pData = massage(pData, pMassage)
	
	count_ = length(pData)
	if count_ = 1 then
		return pData[1]
	end if

	atom y = 0
	atom z = 1
	for i = 1 to count_ do
		atom x = 1
		z *= pData[i]
		for j = 1 to count_ do
			if j != i then
				x *= pData[j]
			end if
		end for
		y += x
	end for
			
 	if y = 0 then
 		return 0
 	end if

 	return count_ * z / y
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


--**
-- Returns the mid point of the data points.
--
-- Parameters:
-- # ##pData##: a list of 1 or more numbers for which you want the mean.
-- # ##pMassage##: an object. When this is an empty sequence (the default) it 
--  means that ##pData## is assumed to contain no sub-sequences otherwise this
--  gives intructions about how to treat sub-sequences.
--
-- Returns:
--    An **object**, either ##{}## if there are no items in the set, or an **atom** (the median) otherwise.
--
-- Comments:
--
--   ##median##() is the item for which half the items are below it and half
--   are above it.
--
-- All elements are included; any sequence elements are assumed to have the value zero.
--
-- The equation for average  is:
--
-- {{{
-- median(X) ==> sort(X)[N/2]
-- }}}
--
-- Example 1:
--   <eucode>
--   ? median( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,4} ) -- Ans: 5
--   </eucode>
--
-- See also:
--   [[:average]], [[:geomean]], [[:harmean]], [[:movavg]], [[:emovavg]]
--

public function median(object pData, object pMassage = "")

	if atom(pData) then
		return pData
	end if
	
	pData = massage(pData, pMassage)
	
	if length(pData) = 0 then
		return pData[1]
	end if
	
	if length(pData) < 3 then
		return pData[1]
	end if
	pData = sort(pData)
	return pData[ floor((length(pData) + 1) / 2) ]
	
end function


public function raw_frequency(object pData, object pMassage = "")
	
	sequence lCounts
	sequence lKeys
	integer lNew = 0
	integer lPos
	integer lMax = -1
	
	if atom(pData) then
		return {{1,pData}}
	end if
	
	pData = massage(pData, pMassage)
	
	if length(pData) = 0 then
		return {{1,pData}}
	end if
	lCounts = repeat({0,0}, length(pData))
	lKeys   = repeat(0, length(pData))
	for i = 1 to length(pData) do
		lPos = find(pData[i], lKeys)
		if lPos = 0 then
			lNew += 1
			lPos = lNew
			lCounts[lPos][2] = pData[i]
			lKeys[lPos] = pData[i]
			if lPos > lMax then
				lMax = lPos
			end if
		end if
		lCounts[lPos][1] += 1
	end for
	return lCounts[1..lMax]
	
end function

public function mode(object pData, object pMassage = "")
	
	sequence lCounts
	integer lTop
	integer lTopFreq
	
	pData = massage(pData, pMassage)

	lCounts = sort(raw_frequency(pData))
	lTop = length(lCounts)-1
	lTopFreq = lCounts[$][1]
	while lTop > 0 do
		if lCounts[lTop][1] != lTopFreq then
			exit
		end if
		lTop -= 1
	end while
	if lTop = length(lCounts) - 1 then
		return lCounts[$][2]
	else
		sequence lItems
		integer lPos
		
		lItems = repeat(0, length(lCounts) - lTop)

		lPos = 0		
		while lTop <= length(lCounts) with entry do
			lPos += 1
			lItems[lPos] = lCounts[lTop][2]
		entry
			lTop += 1
		end while
	
		return lItems
	end if
end function

public function central_moment(object pData, atom datum, integer which = 1)

	atom lMean
	atom lTop
	atom lRes
	
	if atom(pData) or length(pData) = 0 then
		return 0
	end if
	
	lMean = average(pData)
	
	return power( datum - lMean, which)

end function
 
public function sum_central_moments(object pData, integer which = 1)

	atom lMean
	atom lTop
	atom lRes
	
	if atom(pData) or length(pData) = 0 then
		return 0
	end if
	
	lMean = average(pData)
	
	lTop = 0
	for i = 1 to length(pData) do
		lTop += power( pData[i] - lMean, which)
	end for
	
	return lTop
end function
 
public function kurtosis(object pData, integer norm = 3, object pMassage = "")

	if atom(pData) then
		return pData
	end if
	pData = massage(pData, pMassage)
	if length(pData) = 0 then
		return pData
	end if
	
	return (sum_central_moments(pData, 4) / ((length(pData) - 1) * power(stdev(pData), 4))) - norm

end function
 
public function skewness(object pData, object pMassage = "")

	if atom(pData) then
		return pData
	end if
	
	pData = massage(pData, pMassage)
	
	if length(pData) = 0 then
		return pData
	end if
	return sum_central_moments(pData, 3) / ((length(pData) - 1) * power(stdev(pData), 3))
	
end function
 
