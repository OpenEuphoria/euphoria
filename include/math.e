-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.2
-- Math routines

-- trig formulas provided by Larry Gregg

--****
-- Category: 
--   math
--
-- Title:
--   Euphoria Standard Library Math Routines
--****

global constant
	PI = 3.141592653589793238,
	E  = 2.718281828459045235

constant
	PI_HALF  =  PI / 2.0,          -- PI / 2
	PINF     = 1E308 * 1000,       -- Plus infinity (used in several routines)
	MINF     = - PINF,             -- Minus infinity (used in several routines)
	INVLOG10 = 1 / log(10),        -- for log10() routine
	RADIANS_TO_DEGREES = 180.0/PI, -- for radians_to_degrees()
	DEGREES_TO_RADIANS = PI/180.0  -- for degrees_to_radians()

type trig_range(object x)
--  values passed to arccos and arcsin must be [-1,+1]
	if atom(x) then
		return x >= -1 and x <= 1
	else
		for i = 1 to length(x) do
			if not trig_range(x[i]) then
				return 0
			end if
		end for
		return 1
	end if
end type

--**
-- Signature:
--   global function arctan(object x1)
--
-- Description:
--   Return an angle with tangent equal to x1
--
-- Comments:
-- A value between -PI/2 and PI/2 (radians) will be returned.
--
-- This function may be applied to an atom or to all elements of a sequence.
--
-- arctan() is faster than arcsin() or arccos().
--
-- Example 1:
-- s = arctan({1,2,3})
-- s is {0.785398, 1.10715, 1.24905}
--**

--**
-- Signature:
-- global function tan(object x1)
--
-- Description:
-- Return the tangent of x1, where x1 is in radians
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence.
--
-- Example 1:
-- t = tan(1.0)
-- -- t is 1.55741
--**

--**
-- Signature:
--   global function rand(object x1)
--
-- Description:
-- Return a random integer from 1 to x1, where x1 may be from 1 to the largest positive value of type integer (1073741823)
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence.
--
-- Example 1:
-- s = rand({10, 20, 30})
-- -- s might be: {5, 17, 23} or {9, 3, 12} etc.
--**

--**
-- Signature:
-- global function set_rand(integer i1)
--
-- Description:
-- Set the random number generator to a certain state, i1, so that you will get a known 
-- series of random numbers on subsequent calls to rand().
--
-- Comments:
-- Normally the numbers returned by the rand() function are totally unpredictable, and 
-- will be different each time you run your program. Sometimes however you may wish to 
-- repeat the same series of numbers, perhaps because you are trying to debug your program, 
-- or maybe you want the ability to generate the same output (e.g. a random picture) for 
-- your user upon request.
--
-- Example 1:
-- sequence s, t
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
--**

--**
-- Signature:
--   global function remainder(object x1, object x2)
--
-- Description:
-- Compute the remainder after dividing x1 by x2. The result will have the same sign as x1, 
-- and the magnitude of the result will be less than the magnitude of x2.
--
-- Comments:
-- The arguments to this function may be atoms or sequences. The rules for 
-- <a href="refman_2.htm#26">operations on sequences</a> apply.
--
-- Example 1:
-- a = remainder(9, 4)
-- -- a is 1
--
-- Example 2:
-- s = remainder({81, -3.5, -9, 5.5}, {8, -1.7, 2, -4})
-- -- s is {1, -0.1, -1, 1.5}
--
-- Example 3:
-- s = remainder({17, 12, 34}, 16)
-- -- s is {1, 12, 2}
--
-- Example 4:
-- s = remainder(16, {2, 3, 5})
-- -- s is {0, 1, 1}
--**

--**
-- Signature:
--   global function cos(object x1)
--
-- Description:
-- Return the cosine of x1, where x1 is in radians
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence.
--
-- Example 1:
-- x = cos({.5, .6, .7})
-- -- x is {0.8775826, 0.8253356, 0.7648422}
--**

--**
-- Signature:
-- global constant E
--
-- Description:
-- base of the natural logarithm
--
-- Example 1:
-- x = E
-- -- x is 2.718281828459045235
--**

--**
-- Signature:
-- global constant PI
--
-- Description:
-- 3.141592653589793238
--
-- Comments:
-- Enough digits have been used to attain the maximum accuracy possible for a Euphoria atom.
--
-- Example 1:
-- x = PI 
-- -- x is 3.141592653589793238
--**

--**
-- Signature:
-- global function log(object x1)
--
-- Description:
-- Return the natural logarithm of x1
--
-- Comments:
-- This function may be applied to an atom or to all elements
-- of a sequence. Note that log is only defined for positive
-- numbers. Your program will abort with a message if you
-- try to take the log of a negative number or zero.
--
-- To compute the inverse, you can use power(E, x)
-- where E is 2.7182818284590452.
--
-- Example 1:
-- a = log(100)
-- -- a is 4.60517
--**

--**
-- Signature:
-- global function power(object x1, object x2)
--
-- Description:
-- Raise x1 to the power x2
--
-- Comments:
-- The arguments to this function may be atoms or sequences. The rules for 
-- <a href="refman_2.htm#26">operations on sequences</a> apply.
--
-- Powers of 2 are calculated very efficiently.
--
-- Example 1:
-- ? power(5, 2)
-- -- 25 is printed
--
-- Example 2:
-- ? power({5, 4, 3.5}, {2, 1, -0.5})
-- -- {25, 4, 0.534522} is printed
--
-- Example 3:
-- ? power(2, {1, 2, 3, 4})
-- -- {2, 4, 8, 16}
--
-- Example 4:
-- ? power({1, 2, 3, 4}, 2)
-- -- {1, 4, 9, 16}
--**

--**
-- Signature:
-- global function floor(object x1)
--
-- Description:
-- Return the greatest integer less than or equal to x1. (Round down to an integer.)
--
-- Example 1:
-- y = floor({0.5, -1.6, 9.99, 100})
-- -- y is {0, -2, 9, 100}
--**

--**
-- Signature:
-- global function sqrt(object x1)
--
-- Description:
-- Calculate the square root of x1
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence.
--
-- Taking the square root of a negative number will abort your program with a run-time error message."
--
-- Example 1:
-- r = sqrt(16)
-- -- r is 4
--**

--**
-- Signature:
-- global function sin(object x1)
--
-- Description:
-- Return the sine of x1, where x1 is in radians
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence.
--
-- Example 1:
-- sin_x = sin({.5, .9, .11})
-- -- sin_x is {.479, .783, .110}
--**

--**
-- Return an angle with cosine equal to x1.
--
-- Comments:
-- The argument, x1, must be in the range -1 to +1 inclusive.
--
-- A value between 0 and <a href="lib_math.htm#PI">PI</a> radians will be returned.
--
-- This function may be applied to an atom or to all elements of a sequence.
--
-- arccos() is not as fast as arctan().
--
-- Example 1:
-- s = arccos({-1,0,1})
-- -- s is {3.141592654, 1.570796327, 0}

global function arccos(trig_range x)
--  returns angle in radians
	return PI_HALF - 2 * arctan(x / (1.0 + sqrt(1.0 - x * x)))
end function
--**

--**
-- Return an angle with sine equal to x1
--
-- Comments:
-- The argument, x1, must be in the range -1 to +1 inclusive.
--
-- A value between -PI/2 and +PI/2 (radians) will be returned.
--
-- This function may be applied to an atom or to all elements of a sequence.
--
-- arcsin() is not as fast as arctan().
--
-- Example 1:
-- s = arcsin({-1,0,1})
-- s is {-1.570796327, 0, 1.570796327}

global function arcsin(trig_range x)
--  returns angle in radians
	return 2 * arctan(x / (1.0 + sqrt(1.0 - x * x)))
end function
--**

--**
-- Computes next higher argument's integers. Returns the integers that are greater or 
-- equal to each element in the argument.
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence
--
-- Example 1:
-- sequence nums
-- nums = {8, -5, 3.14, 4.89, -7.62, -4.3}
-- nums = ceil(nums) -- {8, -5, 4, 5, -7, -4}

global function ceil(object a)
	return -floor(-a)
end function
--**

--**
-- Return the argument's elements rounded to `precision` precision
--
-- Comments:
-- `precision` is optional and defaults to 1.
--
-- This function may be applied to an atom or to all elements of a sequence.
--
-- Example 1:
-- round(5.2) -- 5
-- round({4.12, 4.67, -5.8, -5.21}, 10) -- {4.1, 4.7, -5.8, -5.2}
-- round(12.2512, 100) -- 12.25

global function round(object a, object precision=1)
	integer len
	sequence s
	object t, u
	if atom(a) then
		if atom(precision) then
			return floor(a * precision + 0.5) / precision
		end if
		len = length(precision)
		s = repeat(0, len)
		for i = 1 to len do
			t = precision[i]
			if atom (t) then
				s[i] = floor(a * t + 0.5) / t
			else
				s[i] = round(a, t)
			end if
		end for
		return s
	elsif atom(precision) then
		len = length(a)
		s = repeat(0, len)
		for i = 1 to len do
			t = a[i]
			if atom(t) then
				s[i] = floor(t * precision + 0.5) / precision
			else
				s[i] = round(t, precision)
			end if
		end for
		return s
	end if
	len = length(a)
	if len != length(precision) then
			abort(1)
	end if
	s = repeat(0, len)
	for i = 1 to len do
		t = precision[i]
		if atom(t) then
			u = a[i]
			if atom(u) then
				s[i] = floor(u * t + 0.5) / t
			else
				s[i] = round(u, t)
			end if
		else
			s[i] = round(a[i], t)
		end if
	end for
	return s
end function
--**

--**
-- Return -1, 0 or 1 for each element according to it being negative, zero or positive
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence.
--
-- Example 1:
-- i = sign(5)
-- i is 1
--
-- i = sign(0)
-- -- i is 0
--
-- i = sign(-2)
-- -- i is -1

global function sign(object a)
	object t
	if atom(a) then
		if a > 0 then
				return 1
		elsif a < 0 then
				return - 1
		else
				return 0
		end if
	end if
	for i = 1 to length(a) do
			t = a[i]
		if atom(t) then
				if t > 0 then
					a[i] = 1
			elsif t < 0 then
						a[i] = - 1
			end if
			else
				a[i] = sign(t)
		end if
	end for
	return a
end function
--**

--**
-- Returns the absolute value of each element of x
--
-- Comments:
--   This function may be applied to an atom or to all elements of a sequence
--
-- Example 1:
-- x = abs({10.5, -12, 3})
-- -- x is {10.5, 12, 3}
--
-- i = abs(-4)
-- -- i is 4

global function abs(object a)
	object t
	if atom(a) then
		if a >= 0 then
				return a
		else
				return - a
			end if
	end if
	for i = 1 to length(a) do
		t = a[i]
			if atom(t) then
			if t < 0 then
						a[i] = - t
				end if
		else
				a[i] = abs(t)
		end if
	end for
	return a
end function
--**

--**
-- Compute the sum of all the argument's elements
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence
--
-- Example 1:
--   a = sum({10, 20, 30})
--   -- a is 60
--
--   a = sum({10.5, 11.2, 8.1})
--   -- a is 29.8

global function sum(object a)
	atom b
	if atom(a) then
			return a
	end if
	b = 0
	for i = length(a) to 1 by -1 do
			b += sum(a[i])
	end for
	return b
end function
--**

--**
-- Compute the average of all the argument's elements
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence
--
-- Example 1:
-- a = average({8.5, 7.25, 10, 18.75})
-- -- a is 11.125

global function average(object a)
	atom b
	integer len
	if atom(a) then
		return a
	end if

	len = length(a)
	b = 0

	for i = 1 to len do
		b += a[i]
	end for

	return b / len
end function
--**

--**
-- Computes the maximum value among all the argument's elements
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence
--
-- Example 1:
-- a = max({10,15.4,3})
-- -- a is 15.4

global function max(object a)
	atom b, c
	if atom(a) then
			return a
	end if
	b = MINF
	for i = 1 to length(a) do
			c = max(a[i])
		if c > b then
				b = c
		end if
	end for
	return b
end function
--**

--**
-- Computes the minimum value among all the argument's elements
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence
--
-- Example 1:
-- a = min({10,15.4,3})
-- -- a is 3

global function min(object a)
	atom b, c
	if atom(a) then
			return a
	end if
	b = PINF
	for i = 1 to length(a) do
		c = min(a[i])
			if c < b then
				b = c
		end if
	end for
	return b
end function
--**

--**
-- Convert an angle measured in radians to an angle measured in degrees
--
-- Comments:
-- This function may be applied to an atom or sequence
--
-- Example 1:
-- x = rad2deg(3.385938749)
-- -- x is 194

global function rad2deg (object x)
   return x * RADIANS_TO_DEGREES
end function
--**

--**
-- Convert an angle measured in degrees to an angle measured in radians
--
-- Comments:
-- This function may be applied to an atom or sequence.
--
-- Example 1:
-- x = deg2rad(194)
-- -- x is 3.385938749

global function deg2rad (object x)
   return x * DEGREES_TO_RADIANS
end function
--**

--**
-- Return the base 10 logarithm of x1
--
-- Comments:
-- This function may be applied to an atom or to all elements
-- of a sequence. Note that log10 is only defined for positive
-- numbers. Your program will abort with a message if you
-- try to take the log of a negative number or zero.
--
-- Example 1:
-- a = log10(12)
-- -- a is 2.48490665

global function log10(object x1)
	return log(x1) * INVLOG10
end function
--**

--**
-- calculate E to the n'th power
--
-- Example 1:
-- x = exp(5.4)
-- -- x is 221.4064162

global function exp(atom x)
	return power(E, x)
end function
--**

--**
-- calculate the arctangent of y/x
--
-- Example 1:
-- a = atan2(10.5, 3.1)
-- -- a is 1.283713958

global function atan2(atom y, atom x)
	if x > 0 then
		return arctan(y/x)
	elsif x < 0 then
		if y < 0 then
			return arctan(y/x) - PI
		else
			return arctan(y/x) + PI
		end if
	elsif y > 0 then
		return PI_HALF
	elsif y < 0 then
		return -(PI_HALF)
	else
		return 0
	end if
end function
--**

--**
-- Return a random integer from i1 to i2, where i1 may be from 1 to the largest 
-- positive value of type integer (1073741823).
--
-- Example 1:
-- s = rand_range(18, 24)
-- -- s might be: 18, 19, 20, 21, 22, 23 or 24

global function rand_range(integer lo, integer hi)
   lo -= 1
   hi -= lo

   return lo + rand(hi)
end function
--**

-- TODO: document
global function mod(atom x, atom y)
	return x - y * floor(x / y)
end function

