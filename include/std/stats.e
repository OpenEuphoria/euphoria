--****
-- == Statistics
--
-- <<LEVELTOC level=2 depth=4>>
--
-- === Routines

namespace stats

include std/sequence.e
include std/sort.e


--**
-- determines the k-th smallest value from the supplied set of numbers. 
--
-- Parameters:
-- # ##data_set## : The list of values from which the smallest value is chosen.
-- # ##ordinal_idx## : The relative index of the desired smallest value.
--
-- Returns:
-- A **sequence**, ##{The k-th smallest value, its index in the set}##.
--
-- Comments: 
-- ##small## is used to return a value based on its size relative to
-- all the other elements in the sequence. When ##index## is 1, the smallest index is returned. Use ##index = length(data_set)## to return the highest. 
--
-- If ##ordinal_idx## is less than one, or greater then length of ##data_set##,
--     an empty sequence is returned.
--
-- The set of values does not have to be in any particular order. The values may be any Euphoria object.
--
-- Example 1:
--   <eucode>
--   small( {4,5,6,8,5,4,3,"text"}, 3 ) 
--   --> Ans: {4,1} (The 3rd smallest value)
--   small( {4,5,6,8,5,4,3,"text"}, 1 ) 
--   --> Ans: {3,7} (The 1st smallest value)
--   small( {4,5,6,8,5,4,3,"text"}, 7 ) 
--   --> Ans: {8,4} (The 7th smallest value)
--   small( {"def", "qwe", "abc", "try"}, 2 ) 
--   --> Ans: {"def", 1} (The 2nd smallest value)
--   small( {1,2,3,4}, -1) 
--   --> Ans: {} -- no-value
--   small( {1,2,3,4}, 10) 
--   --> Ans: {} -- no-value
--   </eucode>
--

public function small(sequence data_set, integer ordinal_idx)
	sequence lSortedData

	if ordinal_idx < 1 or ordinal_idx > length(data_set) then
		return {}
	end if
	
	lSortedData = stdsort:sort(data_set)
	
	return {lSortedData[ordinal_idx], find(lSortedData[ordinal_idx], data_set)}
end function

--**
-- returns the largest of the data points that are atoms.
--
-- Parameters:
--   # ##data_set## : a list of 1 or more numbers among which you want the largest.
--
-- Returns:
--   An **object**, either of:
-- * an atom (the largest value) if there is at least one atom item in the set\\
-- * ##{} ##if there //is// no largest value.
--
-- Comments:
-- Any ##data_set## element which is not an atom is ignored.
--
-- Example 1:
--   <eucode>
--   largest( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"} ) -- Ans: 8
--   largest( {"just","text"} ) -- Ans: {}
--   </eucode>
--
-- See Also:
--   [[:range]]
--
public function largest(object data_set)
	atom result_, temp_
	integer lFoundAny
	if atom(data_set) then
		return data_set
	end if
	lFoundAny = 0
	for i = 1 to length(data_set) do
		if atom(data_set[i]) then
			temp_ = data_set[i]
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
-- returns the smallest of the data points. 
--
-- Parameters:
--   # ##data_set## : A list of 1 or more numbers for which you want the smallest.
--             **Note:** only atom elements are included and any sub-sequences
--             elements are ignored.
--
-- Returns:
--   An **object**, either of~:
-- * an atom (the smallest value) if there is at least one atom item in the set\\
-- * ##{} ##if there //is// no largest value.
--
-- Comments:
-- Any ##data_set## element which is not an atom is ignored.
--
-- Example 1:
--   <eucode>
--   ? smallest( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"} ) -- Ans: 1
--   ? smallest( {"just","text"} ) -- Ans: {}
--   </eucode>
--
-- See Also:
--   [[:range]]
public function smallest(object data_set)
	atom result_, temp_
	integer lFoundAny
	if atom(data_set) then
			return data_set
	end if
	lFoundAny = 0
	for i = 1 to length(data_set) do
		if atom(data_set[i]) then
			temp_ = data_set[i]
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
-- determines a number of //range// statistics for the data set. 
--
-- Parameters:
--   # ##data_set## : a list of 1 or more numbers for which you want the range data.
--
-- Returns:
--  A **sequence**, empty if no atoms were found, else like ##{Lowest, Highest, Range, Mid-range}## ,
--
-- Comments:
-- Any sequence element in ##data_set## is ignored.
--
-- Example 1:
--   <eucode>
--   ? range( {7,2,8,5,6,6,4,8,6,16,3,3,4,1,8,"text"} ) -- Ans: {1, 16, 15, 8.5}
--   </eucode>
--
-- See Also:
--   [[:smallest]] [[:largest]]
--
public function range(object data_set)
	sequence result_
	atom temp_
	integer lFoundAny = 0
	
	if atom(data_set) then
		data_set = {data_set}
	end if
	
	for i = 1 to length(data_set) do
		if atom(data_set[i]) then
			temp_ = data_set[i]
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

--****
-- Enums used to influence the results of some of these functions.

public enum
   --** 
   -- The supplied data is the entire population.
   ST_FULLPOP,
   
   --**
   -- The supplied data is only a random sample of the population.
   ST_SAMPLE

public enum 
   --** 
   -- The supplied data consists of only atoms.
	ST_ALLNUM,
	
   --** 
   -- Any sub-sequences (such as strings) in the supplied data are ignored.
	ST_IGNSTR,
	
   --** 
   -- Any sub-sequences (such as strings) in the supplied data are assumed to
   -- have the value zero.
	ST_ZEROSTR,
	
	$
   
function massage(sequence data_set, object subseq_opt)
	switch subseq_opt do
		case ST_IGNSTR then
			return stdseq:remove_subseq(data_set, stdseq:SEQ_NOALT)
			
		case ST_ZEROSTR then
			return stdseq:remove_subseq(data_set, 0)
			
		case else
			return data_set
	end switch
end function

--**
-- returns the standard deviation based on the population. 
--
-- Parameters:
-- # ##data_set## : a list of 1 or more numbers for which you want the estimated standard deviation.
-- # ##subseq_opt## : an object. When this is ##ST_ALLNUM## (the default) it 
--  means that ##data_set## is assumed to contain no sub-sequences otherwise this
--  gives instructions about how to treat sub-sequences. See comments for details.
-- # ##population_type## : an integer. ##ST_SAMPLE## (the default) assumes that ##data_set## is a random
-- sample of the total population. ##ST_FULLPOP## means that ##data_set## is the
-- entire population.
--
-- Returns:
--    An **atom**, the estimated standard deviation.
--    An empty **sequence** means that there is no meaningful data to calculate from.
--
-- Comments:
-- ##stdev## is a measure of how values are different from the average. 
--
-- The numbers in ##data_set## can either be the entire population of values or
-- just a random subset. You indicate which in the ##population_type## parameter. By default
-- ##data_set## represents a sample and not the entire population. When using this
-- function with sample data, the result is an //estimated// standard deviation.
--
-- If the data can contain sub-sequences, such as strings, you need to let the
-- the function know about this otherwise it assumes every value in ##data_set## is
-- an number. If that is not the case then the function will crash. So it is
-- important that if it can possibly contain sub-sequences that you tell this
-- function what to do with them. Your choices are to ignore them or assume they
-- have the value zero. To ignore them, use ##ST_IGNSTR## as the ##subseq_opt## parameter
-- value otherwise use ##ST_ZEROSTR##. However, if you know that ##data_set## only
-- contains numbers use the default ##subseq_opt## value, ##ST_ALLNUM##. 
--
-- **Note** It is faster if the data only contains numbers.
--
-- The equation for standard deviation is~:
-- {{{
-- stdev(X) ==> SQRT(SUM(SQ(X{1..N} - MEAN)) / (N))
-- }}}
--
-- Example 1:
-- <eucode>
-- ? stdev( {4,5,6,7,5,4,3,7} )                             -- Ans: 1.457737974
-- ? stdev( {4,5,6,7,5,4,3,7} ,, ST_FULLPOP)                -- Ans: 1.363589014
-- ? stdev( {4,5,6,7,5,4,3,"text"} , ST_IGNSTR)             -- Ans: 1.345185418
-- ? stdev( {4,5,6,7,5,4,3,"text"}, ST_IGNSTR, ST_FULLPOP ) -- Ans: 1.245399698
-- ? stdev( {4,5,6,7,5,4,3,"text"} , 0)                     -- Ans: 2.121320344
-- ? stdev( {4,5,6,7,5,4,3,"text"}, 0, ST_FULLPOP )         -- Ans: 1.984313483
-- </eucode>
--
-- See Also:
--   [[:average]], [[:avedev]]
--

public function stdev(sequence data_set, object subseq_opt = ST_ALLNUM, integer population_type = ST_SAMPLE)
	atom lSum
	atom lMean
	integer lCnt
	
	data_set = massage(data_set, subseq_opt)
	
	lCnt = length(data_set)
	
	if lCnt = 0 then
		return {}
	end if
	if lCnt = 1 then
		return 0
	end if
	
	lSum = 0
	for i = 1 to length(data_set) do
		lSum += data_set[i]
	end for
	
	lMean = lSum / lCnt
	lSum = 0
	for i = 1 to length(data_set) do
		lSum += power(data_set[i] - lMean, 2)
	end for
	
	if population_type = ST_SAMPLE then
		lCnt -= 1
	end if
	
	return power(lSum / lCnt, 0.5)
end function

--**
-- returns the average of the absolute deviations of data points from their mean.
--
-- Parameters:
-- # ##data_set## : a list of 1 or more numbers for which you want the mean of the absolute deviations.
-- # ##subseq_opt## : an object. When this is ##ST_ALLNUM## (the default) it 
--  means that ##data_set## is assumed to contain no sub-sequences otherwise this
--  gives instructions about how to treat sub-sequences. See comments for details.
-- # ##population_type## : an integer. ##ST_SAMPLE## (the default) assumes that ##data_set## is a random
-- sample of the total population. ##ST_FULLPOP## means that ##data_set## is the
-- entire population.
--
-- Returns:
--    An **atom** , the deviation from the mean.\\
--    An empty **sequence**, means that there is no meaningful data to calculate from.
--
-- Comments:
-- ##avedev## is a measure of the variability in a data set. Its statistical
-- properties are less well behaved than those of the standard deviation, which is
-- why it is used less. 
--
-- The numbers in ##data_set## can either be the entire population of values or
-- just a random subset. You indicate which in the ##population_type## parameter. By default
-- ##data_set## represents a sample and not the entire population. When using this
-- function with sample data, the result is an //estimated// deviation.
--
-- If the data can contain sub-sequences, such as strings, you need to let the
-- the function know about this otherwise it assumes every value in ##data_set## is
-- an number. If that is not the case then the function will crash. So it is
-- important that if it can possibly contain sub-sequences that you tell this
-- function what to do with them. Your choices are to ignore them or assume they
-- have the value zero. To ignore them, use ##ST_IGNSTR## as the ##subseq_opt## parameter
-- value otherwise use ##ST_ZEROSTR##. However, if you know that ##data_set## only
-- contains numbers use the default ##subseq_opt## value, ##ST_ALLNUM##.
-- 
-- **Note** It is faster if the data only contains numbers.
--
-- The equation for absolute average deviation is~:
-- {{{
-- avedev(X) ==> SUM( ABS(X{1..N} - MEAN(X)) ) / N
-- }}}
--
-- Example 1:
-- <eucode>
-- ? avedev( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,7} ) 
--    --> Ans: 1.966666667
-- ? avedev( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,7},, ST_FULLPOP ) 
--    --> Ans: 1.84375
-- ? avedev( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"}, ST_IGNSTR  ) 
--    --> Ans: 1.99047619
-- ? avedev( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"}, ST_IGNSTR,ST_FULLPOP ) 
--    --> Ans: 1.857777778
-- ? avedev( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"}, 0 ) 
--     --> Ans: 2.225
-- ? avedev( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"}, 0, ST_FULLPOP ) 
--    --> Ans: 2.0859375
-- </eucode>
--
-- See Also:
--   [[:average]], [[:stdev]]
--

public function avedev(sequence data_set, object subseq_opt = ST_ALLNUM, integer population_type = ST_SAMPLE)
	atom lSum
	atom lMean
	integer lCnt
	
	data_set = massage(data_set, subseq_opt)
	
	lCnt = length(data_set)
	
	if lCnt = 0 then
		return {}
	end if
	if lCnt = 1 then
		return 0
	end if
	lSum = 0

	for i = 1 to length(data_set) do
		lSum += data_set[i]
	end for
	
	lMean = lSum / lCnt
	lSum = 0
	for i = 1 to length(data_set) do
		if data_set[i] > lMean then
			lSum += data_set[i] - lMean
		else
			lSum += lMean - data_set[i]
		end if
	end for
	
	if population_type = ST_SAMPLE then
		lCnt -= 1
	end if
	return lSum / lCnt
end function

--**
-- returns the sum of all the atoms in an object.
--
-- Parameters:
-- # ##data_set## : Either an atom or a list of numbers to sum.
-- # ##subseq_opt## : an object. When this is ##ST_ALLNUM## (the default) it 
--  means that ##data_set## is assumed to contain no sub-sequences otherwise this
--  gives instructions about how to treat sub-sequences. See comments for details.
--
-- Returns:
--   An **atom**,  the sum of the set.
--
-- Comments: 
--   ##sum## is used as a measure of the magnitude of a sequence of positive values.
--
-- If the data can contain sub-sequences, such as strings, you need to let the
-- the function know about this otherwise it assumes every value in ##data_set## is
-- an number. If that is not the case then the function will crash. So it is
-- important that if it can possibly contain sub-sequences that you tell this
-- function what to do with them. Your choices are to ignore them or assume they
-- have the value zero. To ignore them, use ##ST_IGNSTR## as the ##subseq_opt## parameter
-- value otherwise use ##ST_ZEROSTR##. However, if you know that ##data_set## only
-- contains numbers use the default ##subseq_opt## value, ##ST_ALLNUM##.
-- 
-- **Note** It is faster if the data only contains numbers.
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
-- See Also:
--   [[:average]]

public function sum(object data_set, object subseq_opt = ST_ALLNUM)
	atom result_
	if atom(data_set) then
		return data_set
	end if
	
	data_set = massage(data_set, subseq_opt)
	result_ = 0
	for i = 1 to length(data_set) do
		result_ += data_set[i]
	end for

	return result_
end function

--**
-- returns the count of all the atoms in an object.
--
-- Parameters:
--   # ##data_set## : either an atom or a list.
-- # ##subseq_opt## : an object. When this is ##ST_ALLNUM## (the default) it 
--  means that ##data_set## is assumed to contain no sub-sequences otherwise this
--  gives instructions about how to treat sub-sequences. See comments for details.
--
-- Comments: 
-- This returns the number of numbers in ##data_set##
--
-- If the data can contain sub-sequences, such as strings, you need to let the
-- the function know about this otherwise it assumes every value in ##data_set## is
-- an number. If that is not the case then the function will crash. So it is
-- important that if it can possibly contain sub-sequences that you tell this
-- function what to do with them. Your choices are to ignore them or assume they
-- have the value zero. To ignore them, use ##ST_IGNSTR## as the ##subseq_opt## parameter
-- value otherwise use ##ST_ZEROSTR##. However, if you know that ##data_set## only
-- contains numbers use the default ##subseq_opt## value, ##ST_ALLNUM##.
-- 
-- **Note** It is faster if the data only contains numbers.
--
-- Returns:
--
--  An **integer**, the number of atoms in the set. When ##data_set## is an atom, 1 is returned.
--
-- Example 1:
--   <eucode>
--   ? count( {7,2,8.5,6,6,-4.8,6,6,3.341,-8,"text"} ) -- Ans: 10
--   ? count( {"cat", "dog", "lamb", "cow", "rabbit"} ) -- Ans: 0 (no atoms)
--   ? count( 5 ) -- Ans: 1
--   </eucode>
--
-- See Also:
--   [[:average]], [[:sum]]

public function count(object data_set, object subseq_opt = ST_ALLNUM)
	if atom(data_set) then
		return 1
	end if
	
	return length(massage(data_set, subseq_opt))

end function


--**
-- returns the average (mean) of the data points.
--
-- Parameters:
--   # ##data_set## : A list of 1 or more numbers for which you want the mean.
-- # ##subseq_opt## : an object. When this is ##ST_ALLNUM## (the default) it 
--  means that ##data_set## is assumed to contain no sub-sequences otherwise this
--  gives instructions about how to treat sub-sequences. See comments for details.
--
--
-- Returns:
--	An **object**,
-- * ##{}## (the empty sequence) if there are no atoms in the set.
-- * an atom (the mean) if there are one or more atoms in the set.
--
-- Comments: 
--
--   ##average## is the theoretical probable value of a randomly selected item from the set.
--
-- The equation for average is~:
--
-- {{{
-- average(X) ==> SUM( X{1..N} ) / N
-- }}}
--
-- If the data can contain sub-sequences, such as strings, you need to let the
-- the function know about this otherwise it assumes every value in ##data_set## is
-- an number. If that is not the case then the function will crash. So it is
-- important that if it can possibly contain sub-sequences that you tell this
-- function what to do with them. Your choices are to ignore them or assume they
-- have the value zero. To ignore them, use ##ST_IGNSTR## as the ##subseq_opt## parameter
-- value otherwise use ##ST_ZEROSTR##. However, if you know that ##data_set## only
-- contains numbers use the default ##subseq_opt## value, ##ST_ALLNUM##. 
--
-- **Note** It is faster if the data only contains numbers.
--
-- Example 1:
--   <eucode>
--   ? average( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,"text"}, ST_IGNSTR ) -- Ans: 5.13333333
--   </eucode>
--
-- See Also:
--   [[:geomean]], [[:harmean]], [[:movavg]], [[:emovavg]]
--
public function average(object data_set, object subseq_opt = ST_ALLNUM)
	
	if atom(data_set) then
		return data_set
	end if
	
	data_set = massage(data_set, subseq_opt)
	
	if length(data_set) = 0 then
		return {}
	end if
	return sum(data_set) / length(data_set)
end function

--**
-- returns the geometric mean of the atoms in a sequence.
--
-- Parameters:
-- # ##data_set## : the values to take the geometric mean of.
-- # ##subseq_opt## : an object. When this is ##ST_ALLNUM## (the default) it 
--  means that ##data_set## is assumed to contain no sub-sequences otherwise this
--  gives instructions about how to treat sub-sequences. See comments for details.
--
-- Returns:
--
-- An **atom**, the geometric mean of the atoms in ##data_set##.
-- If there is no atom to take the mean of, 1 is returned.
--
-- Comments:
--
-- The geometric mean of ##N## atoms is the n-th root of their product. Signs are ignored.
--
-- This is useful to compute average growth rates.
--
-- If the data can contain sub-sequences, such as strings, you need to let the
-- the function know about this otherwise it assumes every value in ##data_set## is
-- an number. If that is not the case then the function will crash. So it is
-- important that if it can possibly contain sub-sequences that you tell this
-- function what to do with them. Your choices are to ignore them or assume they
-- have the value zero. To ignore them, use ##ST_IGNSTR## as the ##subseq_opt## parameter
-- value otherwise use ##ST_ZEROSTR##. However, if you know that ##data_set## only
-- contains numbers use the default ##subseq_opt## value, ##ST_ALLNUM##.
-- 
-- **Note** It is faster if the data only contains numbers.
--
-- Example 1:
-- <eucode>
-- ? geomean({3, "abc", -2, 6}, ST_IGNSTR) -- prints out power(36,1/3) = 3,30192724889462669
-- ? geomean({1,2,3,4,5,6,7,8,9,10}) -- = 4.528728688
-- </eucode>
--
-- See Also:
-- [[:average]]

public function geomean(object data_set, object subseq_opt = ST_ALLNUM)
	atom prod_ = 1.0
	integer count_

	if atom(data_set) then
		return data_set
	end if
	
	data_set = massage(data_set, subseq_opt)
	
	count_ = length(data_set)
	if count_ = 0 then
		return 1
	end if
	if count_ = 1 then
		return data_set[1]
	end if
	
	for i = 1 to length(data_set) do
		atom x = data_set[i]
		
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
-- returns the harmonic mean of the atoms in a sequence.
--
-- Parameters:
-- # ##data_set## : the values to take the harmonic mean of.
-- # ##subseq_opt## : an object. When this is ##ST_ALLNUM## (the default) it 
--  means that ##data_set## is assumed to contain no sub-sequences otherwise this
--  gives instructions about how to treat sub-sequences. See comments for details.
--
-- Returns:
--
-- An **atom**, the harmonic mean of the atoms in ##data_set##.
--
-- Comments:
-- The harmonic mean is the inverse of the average of their inverses.
--
-- This is useful in engineering to compute equivalent capacities and resistances.
--
-- If the data can contain sub-sequences, such as strings, you need to let the
-- the function know about this otherwise it assumes every value in ##data_set## is
-- an number. If that is not the case then the function will crash. So it is
-- important that if it can possibly contain sub-sequences that you tell this
-- function what to do with them. Your choices are to ignore them or assume they
-- have the value zero. To ignore them, use ##ST_IGNSTR## as the ##subseq_opt## parameter
-- value otherwise use ##ST_ZEROSTR##. However, if you know that ##data_set## only
-- contains numbers use the default ##subseq_opt## value, ##ST_ALLNUM##.
-- 
-- **Note** It is faster if the data only contains numbers.
--
-- Example 1:
-- <eucode>
-- ? harmean({3, "abc", -2, 6}, ST_IGNSTR) -- =  0.
-- ? harmean({{2, 3, 4}) -- 3 / (1/2 + 1/3 + 1/4) = 2.769230769
-- </eucode>
--
-- See Also:
-- [[:average]]

public function harmean(sequence data_set, object subseq_opt = ST_ALLNUM)
	integer count_
	
	data_set = massage(data_set, subseq_opt)
	
	count_ = length(data_set)
	if count_ = 1 then
		return data_set[1]
	end if

	atom y = 0
	atom z = 1
	for i = 1 to count_ do
		atom x = 1
		z *= data_set[i]
		for j = 1 to count_ do
			if j != i then
				x *= data_set[j]
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
-- returns the average (mean) of the data points for overlaping periods. This
-- can be either a simple or weighted moving average.
--
-- Parameters:
--   # ##data_set## : a list of 1 or more numbers for which you want a moving average.
--   # ##period_delta## : an object, either 
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
--   of the first five data points ##[1..5]##, 
-- # the second returned element is
--   the average of the second five data points ##[2..6]##, \\and so on \\until
--   the last returned value is the average of the last 5 data points
--   ##[$-4 .. $]##.
--
-- When ##period_delta## is an atom, it is rounded down to the width of the average. When it is a 
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
-- See Also:
--   [[:average]]
--
public function movavg(object data_set, object period_delta)
	sequence result_ 
	integer lLow
	integer lHigh
	integer j
	integer n

	if atom(data_set) then
		data_set = {data_set}
		
	elsif count(data_set) = 0 then
		return data_set
	end if
	
	if atom(period_delta) then
		if floor(period_delta) < 1 then
			return {}
		end if
		period_delta = repeat(1, floor(period_delta))
	end if
	
	if length(data_set) < length(period_delta) then
		data_set = repeat(0, length(period_delta) - length(data_set)) & data_set
	end if
	lLow = 1
	lHigh = length(period_delta)
	result_ = repeat(0, length(data_set) - length(period_delta) + 1)
	while lHigh <= length(data_set) do
		j = 1
		n = 0
		for i = lLow to lHigh do
			if atom(data_set[i]) then
				result_[lLow] += data_set[i] * period_delta[j]
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
-- returns the exponential moving average of a set of data points.
--
-- Parameters:
--   # ##data_set## : a list of 1 or more numbers for which you want a moving average.
--   # ##smoothing_factor## : an atom, the smoothing factor, typically between 0 and 1.
--
-- Returns:
--   A **sequence**, made of the requested averages, or ##{}## if ##data_set## is empty or
-- the supplied period is less than one.
--
-- Comments: 
--
--   A moving average is used to smooth out a set of data points over a period.
--
-- The formula used is~:\\
-- : ##Y,,i,, = Y,,i-1,, + F * (X,,i,, - Y,,i-1,,)##
--
-- Note that only atom elements are included and any sub-sequences elements are ignored.
--
-- The smoothing factor controls how data is smoothed. 0 smooths everything to 0, and 1 means no smoothing at all.
--
-- Any value for ##smoothing_factor## outside the ##0.0..1.0## range causes ##smoothing_factor## 
-- to be set to the periodic factor ##(2/(N+1))##.
--
-- Example 1:
--   <eucode>
--   ? emovavg( {7,2,8,5,6}, 0.75 ) 
--    -- Ans: {6.65,3.1625,6.790625,5.44765625,5.861914063}
--   ? emovavg( {7,2,8,5,6}, 0.25 ) 
--    -- Ans: {5.95,4.9625,5.721875,5.54140625,5.656054687}
--   ? emovavg( {7,2,8,5,6}, -1 ) 
--    -- Ans: {6.066666667,4.711111111,5.807407407,5.538271605,5.69218107}
--   </eucode>
--
-- See Also:
--   [[:average]]

public function emovavg(object data_set, atom smoothing_factor)
	atom lPrev
	if atom(data_set) then
		data_set = {data_set}
		
	elsif count(data_set) = 0 then
		return data_set
	end if
	
	if smoothing_factor < 0 or smoothing_factor > 1 then
		smoothing_factor = (2 / (count(data_set) + 1))
	end if
	
	lPrev = average(data_set)
	for i = 1 to length(data_set) do
		if atom(data_set[i]) then
			data_set[i] = (data_set[i] - lPrev) * smoothing_factor + lPrev
			lPrev = data_set[i]
		end if
	end for
	return data_set
end function

--**
-- returns the mid point of the data points.
--
-- Parameters:
-- # ##data_set## : a list of 1 or more numbers for which you want the mean.
-- # ##subseq_opt## : an object. When this is ##ST_ALLNUM## (the default) it 
--  means that ##data_set## is assumed to contain no sub-sequences otherwise this
--  gives instructions about how to treat sub-sequences. See comments for details.
--
-- Returns:
--    An **object**, either ##{}## if there are no items in the set, or an **atom** (the median) otherwise.
--
-- Comments:
--
--   ##median## is the item for which half the items are below it and half
--   are above it.
--
-- All elements are included; any sequence elements are assumed to have the value zero.
--
-- The equation for average  is~:
--
-- {{{
-- median(X) ==> sort(X)[N/2]
-- }}}
--
-- If the data can contain sub-sequences, such as strings, you need to let the
-- the function know about this otherwise it assumes every value in ##data_set## is
-- an number. If that is not the case then the function will crash. So it is
-- important that if it can possibly contain sub-sequences that you tell this
-- function what to do with them. Your choices are to ignore them or assume they
-- have the value zero. To ignore them, use ##ST_IGNSTR## as the ##subseq_opt## parameter
-- value otherwise use ##ST_ZEROSTR##. However, if you know that ##data_set## only
-- contains numbers use the default ##subseq_opt## value, ##ST_ALLNUM##.
-- 
-- **Note** It is faster if the data only contains numbers.
--
-- Example 1:
--   <eucode>
--   ? median( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,4} ) -- Ans: 5
--   </eucode>
--
-- See Also:
--   [[:average]], [[:geomean]], [[:harmean]], [[:movavg]], [[:emovavg]]
--

public function median(object data_set, object subseq_opt = ST_ALLNUM)

	if atom(data_set) then
		return data_set
	end if
	
	data_set = massage(data_set, subseq_opt)
	
	if length(data_set) = 0 then
		return data_set
	end if
	
	if length(data_set) < 3 then
		return data_set[1]
	end if
	data_set = stdsort:sort(data_set)
	return data_set[ floor((length(data_set) + 1) / 2) ]
	
end function

--**
-- returns the frequency of each unique item in the data set.
--
-- Parameters:
-- # ##data_set## : a list of 1 or more numbers for which you want the frequencies.
-- # ##subseq_opt## : an object. When this is ##ST_ALLNUM## (the default) it 
--  means that ##data_set## is assumed to contain no sub-sequences otherwise this
--  gives instructions about how to treat sub-sequences. See comments for details.
--
-- Returns:
--    A **sequence**. This will contain zero or more 2-element sub-sequences. The
--    first element is the frequency count and the second element is the data item
--    that was counted. The returned values are in descending order, meaning that
--    the highest frequencies are at the beginning of the returned list.
--
-- Comments:
-- If the data can contain sub-sequences, such as strings, you need to let the
-- the function know about this otherwise it assumes every value in ##data_set## is
-- an number. If that is not the case then the function will crash. So it is
-- important that if it can possibly contain sub-sequences that you tell this
-- function what to do with them. Your choices are to ignore them or assume they
-- have the value zero. To ignore them, use ##ST_IGNSTR## as the ##subseq_opt## parameter
-- value otherwise use ##ST_ZEROSTR##. However, if you know that ##data_set## only
-- contains numbers use the default ##subseq_opt## value, ##ST_ALLNUM##.
-- 
-- **Note** It is faster if the data only contains numbers.
--
-- Example 1:
--   <eucode>
--   ? raw_frequency("the cat is the hatter") 
--   </eucode>
-- This returns 
-- {{{
-- {
--   {5,116},
--   {4,32},
--   {3,104},
--   {3,101},
--   {2,97},
--   {1,115},
--   {1,114},
--   {1,105},
--   {1,99}
-- }
-- }}}
--

public function raw_frequency(object data_set, object subseq_opt = ST_ALLNUM)
	
	sequence lCounts
	sequence lKeys
	integer lNew = 0
	integer lPos
	integer lMax = -1
	
	if atom(data_set) then
		return {{1,data_set}}
	end if
	
	data_set = massage(data_set, subseq_opt)
	
	if length(data_set) = 0 then
		return {{1,data_set}}
	end if
	lCounts = repeat({0,0}, length(data_set))
	lKeys   = repeat(0, length(data_set))
	for i = 1 to length(data_set) do
		lPos = find(data_set[i], lKeys)
		if lPos = 0 then
			lNew += 1
			lPos = lNew
			lCounts[lPos][2] = data_set[i]
			lKeys[lPos] = data_set[i]
			if lPos > lMax then
				lMax = lPos
			end if
		end if
		lCounts[lPos][1] += 1
	end for
	return stdsort:sort(lCounts[1..lMax], stdsort:DESCENDING)
	
end function

--**
-- returns the most frequent point(s) of the data set.
--
-- Parameters:
-- # ##data_set## : a list of 1 or more numbers for which you want the mode.
-- # ##subseq_opt## : an object. When this is ##ST_ALLNUM## (the default) it 
--  means that ##data_set## is assumed to contain no sub-sequences otherwise this
--  gives instructions about how to treat sub-sequences. See comments for details.
--
-- Returns:
--   A **sequence**. The list of modal items in the data set.
--
-- Comments:
--
-- It is possible for the ##mode## to return more than one item when more than
-- one item in the set has the same highest frequency count.
--
-- If the data can contain sub-sequences, such as strings, you need to let the
-- the function know about this otherwise it assumes every value in ##data_set## is
-- an number. If that is not the case then the function will crash. So it is
-- important that if it can possibly contain sub-sequences that you tell this
-- function what to do with them. Your choices are to ignore them or assume they
-- have the value zero. To ignore them, use ##ST_IGNSTR## as the ##subseq_opt## parameter
-- value otherwise use ##ST_ZEROSTR##. However, if you know that ##data_set## only
-- contains numbers use the default ##subseq_opt## value, ##ST_ALLNUM##.
-- 
-- **Note** It is faster if the data only contains numbers.
--
-- Example 1:
--   <eucode>
-- ? mode( {7,2,8,5,6,6,4,8,6,6,3,3,4,1,8,4} ) -- Ans: {6}
-- ? mode( {8,2,8,5,6,6,4,8,6,6,3,3,4,1,8,4} ) -- Ans: {8,6}
--   </eucode>
--
-- See Also:
--   [[:average]], [[:geomean]], [[:harmean]], [[:movavg]], [[:emovavg]]
--

public function mode(sequence data_set, object subseq_opt = ST_ALLNUM)
	
	sequence lCounts
	sequence lRes
	
	data_set = massage(data_set, subseq_opt)
	
	if not length( data_set ) then
		return {}
	end if

	lCounts = raw_frequency(data_set, subseq_opt)
	
	lRes = {lCounts[1][2]}
	for i = 2 to length(lCounts) do
		if lCounts[i][1] < lCounts[1][1] then
			exit
		end if
		lRes = append(lRes, lCounts[i][2])
	end for
	
	return lRes
	
end function

--**
-- returns the distance between a supplied value and the mean, to some supplied
-- order of magnitude. This is used to get a measure of the //shape// of a 
-- data set.
--
-- Parameters:
-- # ##data_set## : a list of 1 or more numbers whose mean is used.
-- # ##datum##: either a single value or a list of values for which you require
-- the central moments.
-- # ##order_mag##: An integer. This is the order of magnitude required. Usually
-- a number from 1 to 4, but can be anything.
-- # ##subseq_opt## : an object. When this is ##ST_ALLNUM## (the default) it 
--  means that ##data_set## is assumed to contain no sub-sequences otherwise this
--  gives instructions about how to treat sub-sequences. See comments for details.
--
-- Returns:
--   An **object**. The same data type as ##datum##. This is the set of calculated
--  central moments.
--
-- Comments:
--
-- For each of the items in ##datum##, its central moment is calculated as~:
-- {{{
--     CM = power( ITEM - AVG, MAGNITUDE)
-- }}}
--
-- If the data can contain sub-sequences, such as strings, you need to let the
-- the function know about this otherwise it assumes every value in ##data_set## is
-- an number. If that is not the case then the function will crash. So it is
-- important that if it can possibly contain sub-sequences that you tell this
-- function what to do with them. Your choices are to ignore them or assume they
-- have the value zero. To ignore them, use ##ST_IGNSTR## as the ##subseq_opt## parameter
-- value otherwise use ##ST_ZEROSTR##. However, if you know that ##data_set## only
-- contains numbers use the default ##subseq_opt## value, ##ST_ALLNUM##.
-- 
-- **Note** It is faster if the data only contains numbers.
--
-- Example 1:
--   <eucode>
-- ? central_moment("the cat is the hatter", "the",1) --> {23.14285714, 11.14285714, 8.142857143}
-- ? central_moment("the cat is the hatter", 't',2) -->   535.5918367                          
-- ? central_moment("the cat is the hatter", 't',3) -->   12395.12536                          
--   </eucode>
--
-- See Also:
--   [[:average]]
--
public function central_moment(sequence data_set, object datum, integer order_mag = 1, object subseq_opt = ST_ALLNUM)

	atom lMean
	
	data_set = massage(data_set, subseq_opt)

	if length(data_set) = 0 then
		return 0
	end if
	
	lMean = average(data_set)
	
	return power( datum - lMean, order_mag)

end function
 
--**
-- returns sum of the central moments of each item in a data set.
--
-- Parameters:
-- # ##data_set## : a list of 1 or more numbers whose mean is used.
-- # ##order_mag##: An integer. This is the order of magnitude required. Usually
-- a number from 1 to 4, but can be anything.
-- # ##subseq_opt## : an object. When this is ##ST_ALLNUM## (the default) it 
--  means that ##data_set## is assumed to contain no sub-sequences otherwise this
--  gives instructions about how to treat sub-sequences. See comments for details.
--
-- Returns:
--   An **atom**. The total of the central moments calculated for each of the
-- items in ##data_set##.
--
-- Comments:
-- If the data can contain sub-sequences, such as strings, you need to let the
-- the function know about this otherwise it assumes every value in ##data_set## is
-- an number. If that is not the case then the function will crash. So it is
-- important that if it can possibly contain sub-sequences that you tell this
-- function what to do with them. Your choices are to ignore them or assume they
-- have the value zero. To ignore them, use ##ST_IGNSTR## as the ##subseq_opt## parameter
-- value otherwise use ##ST_ZEROSTR##. However, if you know that ##data_set## only
-- contains numbers use the default ##subseq_opt## value, ##ST_ALLNUM##.
-- 
-- **Note** It is faster if the data only contains numbers.
--
-- Example 1:
--   <eucode>
-- ? sum_central_moments("the cat is the hatter", 1) --> -8.526512829e-14
-- ? sum_central_moments("the cat is the hatter", 2) --> 19220.57143     
-- ? sum_central_moments("the cat is the hatter", 3) --> -811341.551     
-- ? sum_central_moments("the cat is the hatter", 4) --> 56824083.71
--   </eucode>
--
-- See Also:
--   [[:central_moment]], [[:average]]
--
public function sum_central_moments(object data_set, integer order_mag = 1, object subseq_opt = ST_ALLNUM)
	return sum( central_moment(data_set, data_set, order_mag, subseq_opt) )
end function

--**
-- returns a measure of the asymmetry of a data set. Usually the data_set is a
-- probablity distribution but it can be anything. This value is used to assess
-- how suitable the data set is in representing the required analysis. It can
-- help detect if there are too many extreme values in the data set.
--
-- Parameters:
-- # ##data_set## : a list of 1 or more numbers whose mean is used.
-- # ##subseq_opt## : an object. When this is ##ST_ALLNUM## (the default) it 
--  means that ##data_set## is assumed to contain no sub-sequences otherwise this
--  gives instructions about how to treat sub-sequences. See comments for details.
--
-- Returns:
--   An **atom**. The skewness measure of the data set.
--
-- Comments:
-- Generally speaking, a negative return indicates that most of the values are
-- lower than the mean, while positive values indicate that most values are
-- greater than the mean. However this might not be the case when there are a few
-- extreme values on one side of the mean.
--
-- The larger the magnitude of the returned value, the more the data is skewed
-- in that direction.
--
-- A returned value of zero indicates that the mean and median values are identical
-- and that the data is symmetrical.
--
--
-- If the data can contain sub-sequences, such as strings, you need to let the
-- the function know about this otherwise it assumes every value in ##data_set## is
-- an number. If that is not the case then the function will crash. So it is
-- important that if it can possibly contain sub-sequences that you tell this
-- function what to do with them. Your choices are to ignore them or assume they
-- have the value zero. To ignore them, use ##ST_IGNSTR## as the ##subseq_opt## parameter
-- value otherwise use ##ST_ZEROSTR##. However, if you know that ##data_set## only
-- contains numbers use the default ##subseq_opt## value, ##ST_ALLNUM##.
-- 
-- **Note** It is faster if the data only contains numbers.
--
-- Example 1:
--   <eucode>
-- ? skewness("the cat is the hatter") --> -1.36166186
-- ? skewness("thecatisthehatter")     --> 0.1093730315
--   </eucode>
--
-- See Also:
--   [[:kurtosis]]
--
public function skewness(object data_set, object subseq_opt = ST_ALLNUM)

	if atom(data_set) then
		return data_set
	end if
	
	data_set = massage(data_set, subseq_opt)
	
	if length(data_set) = 0 then
		return data_set
	end if
	return sum_central_moments(data_set, 3) / ((length(data_set) - 1) * power(stdev(data_set), 3))
	
end function

--**
-- returns a measure of the spread of values in a dataset when compared to a 
-- //normal// probability curve. 
--
-- Parameters:
-- # ##data_set## : a list of 1 or more numbers whose kurtosis is required.
-- # ##subseq_opt## : an object. When this is ##ST_ALLNUM## (the default) it 
--  means that ##data_set## is assumed to contain no sub-sequences otherwise this
--  gives instructions about how to treat sub-sequences. See comments for details.
--
-- Returns:
--   An **object**. If this is an atom it is the kurtosis measure of the data set.
--   Othewise it is a sequence containing an error integer. The return value ##{0}##
--   indicates that an empty dataset was passed, ##{1}## indicates that the standard
--   deviation is zero (all values are the same).
--
-- Comments:
-- Generally speaking, a negative return indicates that most of the values are
-- further from the mean, while positive values indicate that most values are
-- nearer to the mean.
--
-- The larger the magnitude of the returned value, the more the data is 'peaked'
-- or 'flatter' in that direction.
--
-- If the data can contain sub-sequences, such as strings, you need to let the
-- the function know about this otherwise it assumes every value in ##data_set## is
-- an number. If that is not the case then the function will crash. So it is
-- important that if it can possibly contain sub-sequences that you tell this
-- function what to do with them. Your choices are to ignore them or assume they
-- have the value zero. To ignore them, use ##ST_IGNSTR## as the ##subseq_opt## parameter
-- value otherwise use ##ST_ZEROSTR##. However, if you know that ##data_set## only
-- contains numbers use the default ##subseq_opt## value, ##ST_ALLNUM##.
-- 
-- **Note** It is faster if the data only contains numbers.
--
-- Example 1:
--   <eucode>
-- ? kurtosis("thecatisthehatter")     --> -1.737889192
--   </eucode>
--
-- See Also:
--   [[:skewness]]
--
public function kurtosis(object data_set, object subseq_opt = ST_ALLNUM)
	atom sd
	
	if atom(data_set) then
		return data_set
	end if
	data_set = massage(data_set, subseq_opt)
	if length(data_set) = 0 then
		return {0}
	end if
	sd = stdev(data_set)
	if sd = 0 then
		return {1}
	end if
	
	return (sum_central_moments(data_set, 4) / ((length(data_set) - 1) * power(stdev(data_set), 4))) - 3

end function
