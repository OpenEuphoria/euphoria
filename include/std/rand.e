-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Random Numbers
--
-- <<LEVELTOC depth=2>>
--
public include std/mathcons.e

--**
-- Return a random integer from a specified integer range.
--
-- Parameters:
--		# ##lo##: an integer, the lower bound of the range
--		# ##hi##: an integer, the upper bound of the range.
--
-- Returns:
--		An **integer** randomly drawn between ##lo## and ##hi## inclusive.
--
-- Errors:
--		If ##lo## is not less than ##hi##, an error will occur.
--
-- Comments:
--   This function may be applied to an atom or to all elements of a sequence.
--	 In order to get reproducible results from this function, you should call ##set_rand##() with a reproducible value prior.
--
-- Example 1:
-- <eucode>
-- s = rand_range(18, 24)
-- -- s might be: 18, 19, 20, 21, 22, 23 or 24
-- </eucode>
-- See Also:
--	[[:rand]], [[:set_rand]], [[:rnd]]

public function rand_range(integer lo, integer hi)
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
--		An **atom** randomly drawn between 0.0 and 1.0 inclusive.
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
--		An **atom** randomly drawn between 0.0 and a number less than 1.0 
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
-- 		# ##seed##, an integer, which the generator uses to initialize itself
--
-- Comments:
-- 		Starting from a ##seed##, the values returned by rand() are
-- reproducible. This is useful for demos and stress tests based on random
-- data. Normally the numbers returned by the rand() function are totally
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

-- /*************************************
-- Normal distribution.
-- mu is the mean, and sigma is the standard deviation. Not thread safe.
-- */
-- double normal(double mu=0.0, double sigma=1.0) {
--     // When x and y are two variables from [0, 1), uniformly
--     // distributed, then
--     //
--     //    cos(2*pi*x)*sqrt(-2*log(1-y))
--     //    sin(2*pi*x)*sqrt(-2*log(1-y))
--     //
--     // are two *independent* variables with normal distribution
--     // (mu = 0, sigma = 1).
--     // (Lambert Meertens)
--     static double gauss_next; // nan
--     auto z = gauss_next;
--     gauss_next = double.init; // nan
--     if (isnan(z)) {
--         double x2pi = random() * PI * 2;
--         double g2rad = sqrt(-2.0 * log(1.0 - random()));
--         z = cos(x2pi) * g2rad;
--         gauss_next = sin(x2pi) * g2rad;
--     }
--     return mu + z * sigma;
-- }

atom r2
integer use_r2 = 0
--**
-- Get a random number from with a Normal Distribution
--
-- Parameters:
--	# ##mu##, an atom, The Normal Distribution's mean. Defaults to 0.0
--	# ##sigma##, an atom, The Normal Distribution's standard deviation. Defaults to 1.0
--	# ##set##, an integer. The number of random numbers to return. If this is
--             zero or omitted, a single atom is returned. For numbers greater than zero
--             it returns a sequence containing the requested count of random
--             numbers.
--
-- Returns:
--      An atom. 
-- Example 1:
-- <eucode>
-- set_rand(12345)
-- s[1] = rand_normal()
-- s[2] = rand_normal(4.5, 0.05)
-- s[3] = rand_normal(4.5, 0.50)
-- ? s
--  </eucode>
-- Should return {0.8381062659,4.563054761,4.987177067}
-- 
-- Example 1:
-- <eucode>
-- -- Returns a sequence of 100 numbers in a Normal Distribution around 90 with
-- -- a standard deviation of 10
-- sample_weights = rand_normal(90, 10, 100)
--  </eucode>
--
-- See Also:
--		[[:rand]], [[:rnd]], [[:rnd_1]]
public function rand_normal(atom mu = 0.0, atom sigma = 1.0, integer set = 0)
	atom x2pi
	atom g2rad
	atom r1
	sequence rr
	
	if set > 0 then
		rr = repeat(0, set)
		for i = 1 to set do
			rr[i] = rand_normal(mu, sigma, 0)
		end for
		return rr
	end if
	
	if use_r2 then
		use_r2 = 0
		return mu + r2 * sigma
	end if
	
	x2pi = rnd_1() * PI
	x2pi += x2pi
	g2rad = log(1.0 - rnd_1())
	g2rad = -(g2rad + g2rad)
	g2rad = sqrt(g2rad)
	r1 = cos(x2pi) * g2rad
    r2 = sin(x2pi) * g2rad
    use_r2 = 1
	return mu + r1 * sigma
end function

--****
-- Signature:
-- <built-in> function rand(object maximum)
--
-- Description:
--   Return a random positive integer.
--
-- Parameters:
-- 		# ##maximum##: an atom, a cap on the value to return.
--
-- Returns:
--		An **integer** from 1 to ##maximum##.
--
-- Errors:
--		If [[:ceil]](##maximum##) is not a positive integer <= 1073741823, an error will occur. It must also be at least 1.
--
-- Comments:
--   This function may be applied to an atom or to all elements of a sequence.
--	 In order to get reproducible results from this function, you should call [[:set_rand]]() with a reproducible value prior.
--
-- Example 1:
--   <eucode>
--   s = rand({10, 20, 30})
--   -- s might be: {5, 17, 23} or {9, 3, 12} etc.
--   </eucode>
--
-- See Also:
-- 		[[:set_rand]], [[:ceil]]
