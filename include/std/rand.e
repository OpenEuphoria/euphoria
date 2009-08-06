-- (c) Copyright - See License.txt
--

namespace random

--****
-- == Random Numbers
--
-- <<LEVELTOC depth=2>>
--

--****
-- Signature:
-- <built-in> function rand(object maximum)
--
-- Description:
--   Return a random positive integer.
--
-- Parameters:
-- 		# ##maximum## : an atom, a cap on the value to return.
--
-- Returns:
--		An **integer**, from 1 to ##maximum##.
--
-- Errors:
--		If [[:ceil]](##maximum##) is not a positive integer <= 1073741823,
--      an error will occur. It must also be at least 1.
--
-- Comments:
--   This function may be applied to an atom or to all elements of a sequence.
--	 In order to get reproducible results from this function, you should call 
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
--		# ##lo## : an integer, the lower bound of the range
--		# ##hi## : an integer, the upper bound of the range.
--
-- Returns:
--		An **integer**, randomly drawn between ##lo## and ##hi## inclusive.
--
-- Errors:
--		If ##lo## is not less than ##hi##, an error will occur.
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

public function rand_range(integer lo, integer hi)

	if lo > hi then
		integer temp = hi
		hi = lo
		lo = temp
	end if
	
	lo -= 1
	hi -= lo

   return lo + rand(hi)
end function

constant M_SET_RAND = 35

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
--   -- s is 0.2634879318
-- </eucode>
--
-- See Also:
--	[[:rand]], [[:set_rand]], [[:rand_range]]

public function rnd()
	atom a,b,r

	 a = rand(#3FFFFFFF)
	 if a = 1 then return 0 end if
	 b = rand(#3FFFFFFF)
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
--   -- s is 0.2634879318
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
-- 		# ##seed## : an integer, which the generator uses to initialize itself
--
-- Comments:
-- 		Starting from a ##seed##, the values returned by ##rand##() are
-- reproducible. This is useful for demos and stress tests based on random
-- data. Normally the numbers returned by the ##rand##() function are totally
-- unpredictable, and will be different each time you run your program.
-- Sometimes however you may wish to repeat the same series of numbers,
-- perhaps because you are trying to debug your program, or maybe you want
-- the ability to generate the same output (e.g. a random picture) for your
-- user upon request.  
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
--  </eucode>
-- 
-- See Also:
--		[[:rand]]

public procedure set_rand(integer seed)
-- A given value of seed will cause the same series of
-- random numbers to be generated from the rand() function
	machine_proc(M_SET_RAND, seed)
end procedure


