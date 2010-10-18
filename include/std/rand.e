-- (c) Copyright - See License.txt
--

namespace random

--****
-- == Random Numbers
--
-- <<LEVELTOC level=2 depth=4>>
--

--****
-- Signature:
-- <built-in> function rand(object maximum)
--
-- Description:
--   Return a random integral value.
--
-- Parameters:
-- 		# ##maximum## : an atom, a cap on the value to return.
--
-- Returns:
--		An **atom**, from 1 to ##maximum##.
--
-- Comments:
--	* The minimum value of ##maximum## is 1.
--  * The maximum value that can possibly be returned is #FFFFFFFF (4_294_967_295)
--  * This function may be applied to an atom or to all elements of a sequence.
--	* In order to get reproducible results from this function, you should call 
--   [[:set_rand]]() with a reproducible value prior.
--
-- Example 1:
--   <eucode>
--   s = rand({10, 20, 30})
--   -- s might be: {5, 17, 23} or {9, 3, 12} etc.
--   </eucode>
--
-- See Also:
-- 		[[:set_rand]], [[:ceil]]


--**
-- Return a random integer from a specified inclusive integer range.
--
-- Parameters:
--		# ##lo## : an atom, the lower bound of the range
--		# ##hi## : an atom, the upper bound of the range.
--
-- Returns:
--		An **atom**, randomly drawn between ##lo## and ##hi## inclusive.
--
-- Comments:
--   This function may be applied to an atom or to all elements of a sequence.
--	 In order to get reproducible results from this function, you should 
--   call ##set_rand##() with a reproducible value prior.
--
-- Example 1:
-- <eucode>
-- s = rand_range(18, 24)
-- -- s could be any of: 18, 19, 20, 21, 22, 23 or 24
-- </eucode>
--
-- See Also:
--	[[:rand]], [[:set_rand]], [[:rnd]]

public function rand_range(atom lo, atom hi)

	if lo > hi then
		integer temp = hi
		hi = lo
		lo = temp
	end if
	
	if not integer(lo) or not integer(hi) then
   		hi = rnd() * (hi - lo)
   	else
		lo -= 1
   		hi = rand(hi - lo)
   	end if
   	
   	return lo + hi
end function

constant M_SET_RAND = 35,
         M_GET_RAND = 98

--**
-- Return a random floating point number in the range 0 to 1.
--
-- Parameters:
--		None.
--
-- Returns:
--		An **atom**, randomly drawn between 0.0 and 1.0 inclusive.
--
-- Comments:
--	 In order to get reproducible results from this function, you should
-- call ##set_rand##() with a reproducible value prior to calling this.
--
-- Example 1:
-- <eucode>
-- set_rand(1001)
-- s = rnd()
--   -- s is 0.6277338201
-- </eucode>
--
-- See Also:
--	[[:rand]], [[:set_rand]], [[:rand_range]]

public function rnd()
	atom a,b,r

	 a = rand(#FFFFFFFF)
	 if a = 1 then return 0 end if
	 b = rand(#FFFFFFFF)
	 if b = 1 then return 0 end if

	 if a > b then
	 	r = b / a
	 else
	 	r = a / b
	 end if
	 
	 return r
end function

--**
-- Return a random floating point number in the range 0 to less than 1.
--
-- Parameters:
--		None.
--
-- Returns:
--		An **atom**, randomly drawn between 0.0 and a number less than 1.0 
--
-- Comments:
--	 In order to get reproducible results from this function, you should
-- call ##set_rand##() with a reproducible value prior to calling this.
--
-- Example 1:
-- <eucode>
-- set_rand(1001)
-- s = rnd_1()
--   -- s is 0.6277338201
-- </eucode>
--
-- See Also:
--	[[:rand]], [[:set_rand]], [[:rand_range]]

public function rnd_1()
	atom r
	
	while r >= 1.0 with entry do
	entry
		r = rnd()
	end while	 
	return r
end function

--**
-- Reset the random number generator.
--
-- Parameters:
-- 		# ##seed## : an object. The generator uses this initialize itself for the next
--                    random number generated. This can be a single integer or atom,
--                    or a sequence of two integers, or an empty sequence or any
--                    other sort of sequence.
--
-- Comments:
-- * Starting from a ##seed##, the values returned by ##rand##() are
-- reproducible. This is useful for demos and stress tests based on random
-- data. Normally the numbers returned by the ##rand##() function are totally
-- unpredictable, and will be different each time you run your program.
-- Sometimes however you may wish to repeat the same series of numbers,
-- perhaps because you are trying to debug your program, or maybe you want
-- the ability to generate the same output (e.g. a random picture) for your
-- user upon request.  
-- * Internally there are actually two seed values. 
-- ** When ##set_rand()## is called with a single integer or atom, the two 
--   internal seeds are derived from the parameter. 
-- ** When ##set_rand()## is called with a sequence of exactly two integers/atoms
--    the internal seeds are set to the parameter values.
-- ** When ##set_rand()## is called with an empty sequence, the internal seeds are
--   set to random values and are unpredictable. This is how to reset the generator.
-- ** When ##set_rand()## is called with any other sequence, the internal seeds are
-- set based on the length of the sequence and the hashed value of the sequence.
-- * Aside from an empty ##seed## parameter, this sets the generator to a known state
-- and the random numbers generated after come in a predicable order, though they still
-- appear to be random.
--
-- Example 1:
-- <eucode>
--  sequence s, t
-- s = repeat(0, 3)
-- t = s
-- 
-- set_rand(12345)
-- s[1] = rand(10)
-- s[2] = rand(100)
-- s[3] = rand(1000)
-- 
-- set_rand(12345)  -- same value for set_rand()
-- t[1] = rand(10)  -- same arguments to rand() as before
-- t[2] = rand(100)
-- t[3] = rand(1000)
-- -- at this point s and t will be identical
-- set_rand("") -- Reset the generator to an unknown seed.
-- t[1] = rand(10)  -- Could be anything now, no way to predict it.
--  </eucode>
-- 
-- See Also:
--		[[:rand]]

public procedure set_rand(object seed)
-- A given value of seed will cause the same series of
-- random numbers to be generated from the rand() function
	machine_proc(M_SET_RAND, seed)
end procedure

--**
-- Retrieves the current values of the random generator's seeds.
--
-- Returns:
--    a sequence. A 2-element sequence containing the values of the two internal seeds.
--
-- Comments:
-- You can use this to save the current seed values so that you can later reset them
-- back to a known state.
--
-- Example 1:
-- <eucode>
--  sequence seeds
--  seeds = get_rand()
--  some_func() -- Which might set the seeds to anything.
--- set_rand(seeds) -- reset them back to whatever they were
--                  -- before calling 'some_func()'.
--  </eucode>
-- 
-- See Also:
--		[[:set_rand]]

public function get_rand()
-- Get the generator's current seed values.
	return machine_func(M_GET_RAND, {})
end function

--**
-- Simulates the probability of a desired outcome.
--
-- Parameters:
-- # ##my_limit## : an atom. The desired chance of something happening.
-- # ##top_limit##: an atom. The maximum chance of something happening. The
--                   default is 100.
--
-- Returns:
--    an integer. 1 if the desired chance happened otherwise 0.
--
-- Comments:
-- This simulates the chance of something happening. For example, if you
-- wnat something to happen with a probablity of 25 times out of 100 times then you code ##chance(25)##
-- and if you want something to (most likely) occur 345 times out of 999 times, you code
-- ##chance(345, 999)###.
--
-- Example 1:
-- <eucode>
--  -- 65% of the days are sunny, so ...
--  if chance(65) then
--      puts(1, "Today will be a sunny day")
--  elsif chance(40) then
--      -- And 40% of non-sunny days it will rain.
--      puts(1, "It will rain today")
--  else
--      puts(1, "Today will be a overcast day")
--  end if
-- </eucode>
-- 
-- See Also:
--		[[:rnd]], [[:roll]]
public function chance(atom my_limit, atom top_limit = 100)
	return (rnd_1() * top_limit) <= my_limit
end function


--**
-- Simulates the probability of a dice throw.
--
-- Parameters:
-- # ##desired## : an object. One or more desired outcomes.
-- # ##sides##: an integer. The number of sides on the dice. Default is 6.
--
-- Returns:
--    an integer. 0 if none of the desired outcomes occured, otherwise
--    the face number that was rolled.
--
-- Comments:
-- The minimum number of sides is 2 and there is no maximum.
--
-- Example 1:
-- <eucode>
-- res = roll(1, 2) 
--       --> Simulate a coin toss.
-- res = roll({1,6}) 
--       --> Try for a 1 or a 6 from a standard die toss.
-- res = roll({1,2,3,4}, 20) 
--       --> Looking for any number under 5 from a 20-sided die.
-- </eucode>
-- 
-- See Also:
--		[[:rnd]], [[:chance]]
public function roll(object desired, integer sides = 6)
	integer rolled
	
	if sides < 2 then
		return 0
	end if
	if atom(desired) then
		desired = {desired}
	end if
	
	rolled =  rand(sides)
	if find(rolled, desired) then
		return rolled
	else
		return 0
	end if
end function

--**
-- Selects a random sample sub-set of items from a population set.
--
-- Parameters:
-- # ##full_set## : a sequence. The set of items from which to take a sample.
-- # ##sample_size##: an integer. The number of samples to take.
-- # ##return_remaining##: an integer. If non-zero, the sub-set not selected is also returned.
-- If zero, the default, only the sampled set is returned.
--
-- Returns:
--    a sequence. When ##return_remaining## = 0 then this is the set of samples, otherwise
--   it returns a two-element sequence; the first is the samples, and the second
--   is the remainder of the population (in the original order).
--
-- Comments:
-- * If ##sample_size## is less than 1, an empty set is returned.
-- * If ##sample_size## is greater than or equal to the population count, 
--   the entire population set is returned, but in a random order.
--
-- Example 1:
-- <eucode>
-- set_rand("example")
-- printf(1, "%s\n", { sample("abcdefghijklmnopqrstuvwxyz", 1)})  
--      --> "t"
-- printf(1, "%s\n", { sample("abcdefghijklmnopqrstuvwxyz", 5)})  
--      --> "flukq"
-- printf(1, "%s\n", { sample("abcdefghijklmnopqrstuvwxyz", -1)}) 
--      --> ""
-- printf(1, "%s\n", { sample("abcdefghijklmnopqrstuvwxyz", 26)}) 
--      --> "kghrsxmjoeubaywlzftcpivqnd"
-- printf(1, "%s\n", { sample("abcdefghijklmnopqrstuvwxyz", 25)}) 
--     --> "omntrqsbjguaikzywvxflpedc"
-- </eucode>
--
-- Example 2:
-- <eucode>
-- -- Deal 4 hands of 5 cards from a standard deck of cards.
-- sequence theDeck
-- sequence hands = {}
-- sequence rt
-- function new_deck()
-- 	sequence nd = {}
-- 	for i = 1 to 4 do
-- 		for j = 1 to 13 do
-- 			nd = append(nd, {i,j})
-- 		end for
-- 	end for
-- 	return nd
-- end function
-- theDeck = new_deck()
-- for i = 1 to 4 do
-- 	rt = sample(theDeck, 5, 1)
-- 	theDeck = rt[2]
-- 	hands = append(hands, rt[1])
-- end for
--
-- </eucode>
public function sample(sequence full_set, integer sample_size, integer return_remaining = 0)
	sequence lResult
	integer lIdx
	integer lChoice
	integer lLen
	
	if sample_size < 1 then
		if return_remaining then
			return {{}, full_set}	
		else
			return {}
		end if
	end if
	
	if sample_size >= length(full_set) then
		sample_size = length(full_set)
	end if
	
	lResult = repeat(0, sample_size)
	lIdx = 0
	lLen = length(full_set)
	while lIdx < sample_size do
		lChoice = rand(lLen)
		lIdx += 1
		lResult[lIdx] = full_set[lChoice]
		lLen -= 1
		full_set[lChoice .. $-1] = full_set[lChoice+1 .. $]
	end while

	if return_remaining then
		return {lResult, full_set[1 .. $ - sample_size]}	
	else
		return lResult
	end if
end function
