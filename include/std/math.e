-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Math
--
-- <<LEVELTOC depth=2>>
--

--****
-- === Constants
--

--**
-- Base of the natural logarithm
--
-- Example 1:
-- <eucode>
-- x = E
-- -- x is 2.718281828459045235
-- </eucode>

public constant
	E         = 2.7182818284590452353602874

--**
-- * PI     : 3.141592653589793238 and usual multiples
-- * HALFPI : its half
-- * QUARTPI: its quarter
-- * TWOPI  : its double
--
-- Comments:
-- Enough digits have been used to attain the maximum accuracy possible for a Euphoria atom.
--
-- Example 1:
-- <eucode>
-- x = PI 
-- -- x is 3.141592653589793238
-- </eucode>

public constant
	PI        = 3.141592653589793238462643,
	QUARTPI   = 0.78539816339744830962,
	HALFPI    = 1.57079632679489661923,
	TWOPI     = 6.28318530717958647692

public constant
	LN2       = 0.69314718055994530941,
	INVLN2    = 1 / LN2,
	LN10      = 2.30258509299404568401,
	INVLN10   = 1 / LN10,        -- for log10() routine
	SQRT2     = 1.41421356237309504880,
	HALFSQRT2 = 0.70710678118654752440,
	DEGREES_TO_RADIANS  = 0.01745329251994329576,
	RADIANS_TO_DEGREES   = 1/DEGREES_TO_RADIANS,
	EULER_GAMMA  = machine_func(47,{25,182,111,252,140,120,226,63}),
	EULER_NORMAL = machine_func(47,{81,54,212,51,69,136,217,63})


constant
	PINF     = 1E308 * 1000,       -- Plus infinity (used in several routines)
	MINF     = - PINF             -- Minus infinity (used in several routines)

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

include error.e

--**
-- Miscellaneous constants:
-- * LN2      : natural logarithm of 2
-- * INVLN2   : the inverse of LN2
-- * LN10     : natural logarithm of 10
-- * INVLN10  : the inverse of LN10
-- * SQRT2    : the square root of 2
-- * HALFSQRT2 : the half, and also the inverse, of SQRT2
-- * RADIANS_TO_DEGREE  : 180 / PI, how many degrees a radian is worth
-- * DEGREES_TO_RADIANS : PI / 180, how many radians a degree is worth
-- * EULER_GAMMA : the Euler-Mascheroni-Soldner gamma constant: 0.57721566490153286606065121
-- * EULER_NORMAL: 1/sqrt(2*PI), or 0.3989422804014326779399461

--****
-- === Sign and comparisons
--

--**
-- Returns the absolute value of numbers.
--
-- Parameters:
--		# ##value##: an object, each atom is processed, no matter how deeply nested.
--
-- Returns:
--		An **object** the same shape as ##value##. When ##value## is an atom,
-- the result is the same if not less than zero, and the opposite value otherwise.
--
-- Comments:
--
--   This function may be applied to an atom or to all elements of a sequence
--
-- Example 1:
-- <eucode>
-- x = abs({10.5, -12, 3})
-- -- x is {10.5, 12, 3}
--
-- i = abs(-4)
-- -- i is 4
-- </eucode>
--
-- See Also:
--		[[:sign]]

public function abs(object a)
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
-- Return -1, 0 or 1 for each element according to it being negative, zero or positive
--
-- Parameters:
--		# ##value##: an object, each atom of which will be acted upon, no matter how deeply nested.
--
-- Returns:
--		An **object** the same shape as ##value##. When ##value## is an atom, the result is -1 if ##value## is less than zero, 1 if greater and 0 if equal.
--
-- Comments:
--
-- This function may be applied to an atom or to all elements of a sequence.
--
-- For an atom, ##sign##(x) is the same as [[:compare]](x,0).
-- Example 1:
-- <eucode>
-- i = sign(5)
-- i is 1
--
-- i = sign(0)
-- -- i is 0
--
-- i = sign(-2)
-- -- i is -1
-- </eucode>
--
-- See Also:
--		[[:compare]]

public function sign(object a)
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
-- Computes the maximum value among all the argument's elements
--
-- Parameters:
--		# ##values##: an object, all atoms of which will be inspected, no matter how deeply nested.
--
-- Returns:
--		An **atom**, the maximum of all atoms in [[:flatten]](##values##).
--
-- Comments:
-- This function may be applied to an atom or to a sequence of any shape.
--
-- Example 1:
-- <eucode>
-- a = max({10,15.4,3})
-- -- a is 15.4
-- </eucode>
-- See Also:
--		[[:min]], [[:compare]], [[:flatten]]

public function max(object a)
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
-- Computes the minimum value among all the argument's elements
--
-- Parameters:
--		# ##values##: an object, all atoms of which will be inspected, no matter how deeply nested.
--
-- Returns:
--		An **atom**, the minimum of all atoms in [[:flatten]](##values##).
--
-- Comments:
-- This function may be applied to an atom or to a sequence of any shape.
--
-- Example 1:
-- <eucode>
-- a = min({10,15.4,3})
-- -- a is 3
-- </eucode>

public function min(object a)
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

--****
-- === Roundings and remainders
--

--**
-- Signature:
--   global function remainder(object dividend, object divisor)
--
-- Description:
-- Compute the remainder of the division of two atoms. The result has the same sign as the dividend.
--
-- Parameters:
--		# ##dividend##: an object, each atom of which is the dividend of an Euclidian division
--		# ##divisor##: an object, each atom of which is the divisor in an Euclidian division.
--
-- Returns:
--		An **object**, the shape of which depends on ##dividend##'s and ##divisor##'s. For two atoms, this is the remainder of dividing ##dividend## by  ##divisor##, with ##dividend##'s sign.
--
-- Errors:
--	If any atom in ##divisor## is 0, this is an error condition as it amounts to an attempt to divide by zero.
--
-- Comments:
-- There is a mathematical integer n such that ##dividend## = n * ##divisor## + result. The result has the sign of ##dividend## and lesser magnitude than ##divisor##. n needs not fit in an Euphoria integer.
--
-- The arguments to this function may be atoms or sequences. The rules for
-- <a href="refman_2.htm#26">operations on sequences</a> apply, and determine the shape of the returned object.
--
-- Example 1:
-- <eucode>
-- a = remainder(9, 4)
-- -- a is 1
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = remainder({81, -3.5, -9, 5.5}, {8, -1.7, 2, -4})
-- -- s is {1, -0.1, -1, 1.5}
-- </eucode>
--
-- Example 3:
-- <eucode>
-- s = remainder({17, 12, 34}, 16)
-- -- s is {1, 12, 2}
-- </eucode>
--
-- Example 4:
-- <eucode>
-- s = remainder(16, {2, 3, 5})
-- -- s is {0, 1, 1}
-- </eucode>
-- See Also:
-- 		[[:mod]], [[:Relational operators]], [[:Operations on sequences]]

--**
-- Compute the remainder of the division of two atoms. The result is not less than zero
--
-- Parameters:
--		# ##dividend##: an object, each atom of which is the dividend of an Euclidian division
--		# ##divisor##: an object, each atom of which is the divisor in an Euclidian division.
--
-- Returns:
--		An **object**, the shape of which depends on ##dividend##'s and ##divisor##'s. For two atoms, this is the remainder of dividing ##dividend## by ##divisor##, with ##divisor##'s sign.
--
-- Comments:
-- There is a mathematical integer n such that ##dividend## = n * ##divisor## + result. The result is nonnegative and has lesser magnitude than ##divisor##. n needs not fit in an Euphoria integer.
--
-- The arguments to this function may be atoms or sequences. The rules for
-- <a href="refman_2.htm#26">operations on sequences</a> apply, and determine the shape of the returned object.
--
-- When both arguments are positive numbers, [[:mod]]() and ##remainder##() are the same. They differ by either the ##divisor## or its opposite, when they do.
--
-- Example 1:
-- <eucode>
-- a = mod(9, 4)
-- -- a is 1
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = mod({81, -3.5, -9, 5.5}, {8, -1.7, 2, -4})
-- -- s is {1, 1.6, 1, 1.5}
-- </eucode>
--
-- Example 3:
-- <eucode>
-- s = mod({17, 12, 34}, 16)
-- -- s is {1, 12, 2}
-- </eucode>
--
-- Example 4:
-- <eucode>
-- s = mod(16, {2, 3, 5})
-- -- s is {0, 1, 1}
-- </eucode>
-- See Also:
-- 		[[:mod]], [[:Relational operators]], [[:Operations on sequences]]

public function mod(object x, object y)
	return x - y * floor(x / y)
end function

--**
-- Signature:
-- global function floor(object value)
--
-- Description:
-- Return the greatest integer less than or equal to some value. This amount to rounding down to an integer.
--
-- Parameters:
--		# ##value##: an object, each atom in which will be acted upon.
--
-- Returns:
--		An **object** the same shape as ##value##. When ##value## is an atom, the result is the atom with no fractional part equal or immediately below ##value##.
--
-- Example 1:
-- <eucode>
-- y = floor({0.5, -1.6, 9.99, 100})
-- -- y is {0, -2, 9, 100}
-- </eucode>
--
-- See Also:
--		[[:ceil]], [[:round]]

--**
-- Computes the next integer equal or greater than the argument. 
--
-- Parameters:
--		# ##value##: an object, each atom of which processed, no matter how deeply nested.
--
-- Returns:
--		An **object**, the same shape as ##value##. Each atom in ##value## 
-- is returned as an integer that is the smallest integer equal to or greater
-- than the corresponding atom in ##value##.
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence.
--
--	##ceil(X)## is 1 more than ##floor(X)## for non-integers. For integers, ##X = floor(X) = ceil(X)##.
--
-- Example 1:
-- <eucode>
-- sequence nums
-- nums = {8, -5, 3.14, 4.89, -7.62, -4.3}
-- nums = ceil(nums) -- {8, -5, 4, 5, -7, -4}
-- </eucode>
--
-- See Also:
--		[[:floor]], [[:round]]

public function ceil(object a)
	return -floor(-a)
end function

--**
-- Return the argument's elements rounded to some precision
--
-- Parameters:
--		# ##value##: an object, each atom of which will be acted upon, no matter how deeply nested.
--		# ##precision##: an object, the rounding precision(s). If not passed, this defaults to 1.
--
-- Returns:
--		An **object** the same shape as ##value##. When ##value## is an atom, the result is that atom rounded to the nearest integer multiple of 1/##precision##.
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence.
--
-- Example 1:
-- <eucode>
-- round(5.2) -- 5
-- round({4.12, 4.67, -5.8, -5.21}, 10) -- {4.1, 4.7, -5.8, -5.2}
-- round(12.2512, 100) -- 12.25
-- </eucode>
--
-- See Also:
--	[[:floor]], [[:ceil]]

public function round(object a, object precision=1)
	integer len
	sequence s
	object t, u

	precision = abs(precision)
	if atom(a) then
		if atom(precision) then
			return floor(0.5 + (a * precision )) / precision
		end if
		len = length(precision)
		s = repeat(0, len)
		for i = 1 to len do
			t = precision[i]
			if atom (t) then
				s[i] = floor( 0.5 + (a * t)) / t
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
				s[i] = floor(0.5 + (t * precision)) / precision
			else
				s[i] = round(t, precision)
			end if
		end for
		return s
	end if
	len = length(a)
	if len != length(precision) then
		crash("The lengths of the two supplied sequences do not match.")
	end if
	s = repeat(0, len)
	for i = 1 to len do
		t = precision[i]
		if atom(t) then
			u = a[i]
			if atom(u) then
				s[i] = floor(0.5 + (u * t)) / t
			else
				s[i] = round(u, t)
			end if
		else
			s[i] = round(a[i], t)
		end if
	end for
	return s
end function

--****
-- === Trigonometry

--**
-- Signature:
-- global function arctan(object tangent)
--
-- Description:
--   Return an angle with given tangent.
--
-- Parameters:
--		# ##tangent##: an object, each atom of which will be converted, no matter how deeply nested.
--
-- Returns:
--		An **object** of the same shape as ##tangent##. For each atom in ##flatten(tangent)##, the angle with smallest magnitude that has this atom as tangent is computed.
--
-- Comments:
--   All atoms in the returned value lie between -PI/2 and PI/2, exclusive.
--
--   This function may be applied to an atom or to all elements of a sequence (of sequence (...)).
--
--   ##arctan()## is faster than ##arcsin()## or ##arccos()##.
--
-- Example 1:
--   <eucode>
--   s = arctan({1,2,3})
--   -- s is {0.785398, 1.10715, 1.24905}
--   </eucode>
-- See Also:
--		[[:arcsin]], [[arccos]], [[:tan]], [[:flatten]]

--**
-- Signature:
-- global function tan(object angle)
--
-- Description:
--   Return the tangent of an angle, or a sequence of angles.
--
-- Parameters:
--		# ##angle##: an object, each atom of which will be converted, no matter how deeply nested.
--
-- Returns:
--		An **object** of the same shape as ##angle##. Each atom in the flattened ##angle## is replaced by its tangent.
--
-- Errors:
--		If any atom in ##angle## is an odd multiple of PI/2, an error occurs, as its tangent would be infinite.
--
-- Comments:
--   This function may be applied to an atom or to all elements of a sequence of arbitrary shape, recursively.
--
-- Example 1:
--   <eucode>
--   t = tan(1.0)
--   -- t is 1.55741
--   </eucode>
-- See Also:
--		[[:sin]], [[:cos]], [[:arctan]]

--**
-- Signature:
--   global function cos(object angle)
--
-- Description:
-- Return the cosine of an angle expressed in radians
--
-- Parameters:
--		# ##angle##: an object, each atom of which will be converted, no matter how deeply nested.
--
-- Returns:
--		An **object**, the same shape as ##angle##. Each atom in ##angle## is turned into its cosine.
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence.
--
-- The cosine of an angle is an atom between -1 and 1 inclusive. 0.0 is hit by odd multiples of PI/2 only.
--
-- Example 1:
-- <eucode>
-- x = cos({.5, .6, .7})
-- -- x is {0.8775826, 0.8253356, 0.7648422}
-- </eucode>
--
-- See Also:
--		[[:sin]], [[tan]], [[arccos]], [[:PI]], [[:deg2rad]]

--**
-- Signature:
-- global function sin(object angle)
--
-- Description:
-- Return the sine of an angle expressed in radians
--
-- Parameters:
--		# ##angle##: an object, each atom in which will be acted upon.
--
-- Returns:
--		An **object** the same shape as ##angle##. When ##angle## is an atom, the result is the sine of ##angle##.
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence.
--
-- The sine of an angle is an atom between -1 and 1 inclusive. 0.0 is hit by integer multiples of PI only.
--
-- Example 1:
-- <eucode>
-- sin_x = sin({.5, .9, .11})
-- -- sin_x is {.479, .783, .110}
-- </eucode>
--
-- See Also:
--		[[:cos]], [[:arcsin]], [[:PI]], [[:deg2rad]]

--**
-- Return an angle given its cosine.
--
-- Parameters:
--		# ##value##: an object, each atom in which will be acted upon.
--
-- Returns:
--		An **object** the same shape as ##value##. When ##value## is an atom, the result is an atom, an angle whose cosine is ##value##.
--
-- Errors:
--		If any atom in ##value## is not in the -1..1 range, it cannot be the cosine of a real number, and an error occurs.
--
-- Comments:
--
-- A value between 0 and <a href="lib_math.htm#PI">PI</a> radians will be returned.
--
-- This function may be applied to an atom or to all elements of a sequence.
--
-- ##arccos##() is not as fast as [[:arctan]]().
--
-- Example 1:
-- <eucode>
-- s = arccos({-1,0,1})
-- -- s is {3.141592654, 1.570796327, 0}
-- </eucode>
--
-- See Also:
--		[[:cos]], [[:PI]], [[:arctan]]

public function arccos(trig_range x)
--  returns angle in radians
	return HALFPI - 2 * arctan(x / (1.0 + sqrt(1.0 - x * x)))
end function

--**
-- Return an angle given its sine.
--
-- Parameters:
--		# ##value##: an object, each atom in which will be acted upon.
--
-- Returns:
--		An **object** the same shape as ##value##. When ##value## is an atom, the result is an atom, an angle whose sine is ##value##.
--
-- Errors:
--		If any atom in ##value## is not in the -1..1 range, it cannot be the sine of a real number, and an error occurs.
--
-- Comments:
-- A value between -PI/2 and +PI/2 (radians) inclusive will be returned.
--
-- This function may be applied to an atom or to all elements of a sequence.
--
-- ##arcsin##() is not as fast as [[:arctan]]().
--
-- Example 1:
-- <eucode>
-- s = arcsin({-1,0,1})
-- s is {-1.570796327, 0, 1.570796327}
-- </eucode>
--
-- See Also:
--		[[:arccos]], [[:arccos]], [[:sin]]

public function arcsin(trig_range x)
--  returns angle in radians
	return 2 * arctan(x / (1.0 + sqrt(1.0 - x * x)))
end function
--**
-- Calculate the arctangent of a ratio.
--
-- Parameters:
--		# ##y##: an atom, the numerator of the ratio
--		# ##x##: an atom, the denominator of the ratio
--
-- Returns:
--		An **atom**, which is equal to [[:arctan]](##y##/##x##), except that it can handle zero denominator and is more accurate.
--
-- Example 1:
-- <eucode>
-- a = atan2(10.5, 3.1)
-- -- a is 1.283713958
-- </eucode>
--
-- See Also:
--		[[:arctan]]

public function atan2(atom y, atom x)
	if x > 0 then
		return arctan(y/x)
	elsif x < 0 then
		if y < 0 then
			return arctan(y/x) - PI
		else
			return arctan(y/x) + PI
		end if
	elsif y > 0 then
		return HALFPI
	elsif y < 0 then
		return -(HALFPI)
	else
		return 0
	end if
end function

--**
-- Convert an angle measured in radians to an angle measured in degrees
--
-- Parameters:
--		# ##angle##: an object, all atoms of which will be converted, no matter how deeply nested.
--
-- Returns:
--		An **object** the same shape as ##angle##, all atoms of which were multiplied by 180/PI.
--
-- Comments:
-- This function may be applied to an atom or sequence. A flat angle is PI radians and 180 degrees.
--
-- [[:arcsin]](), [[:arccos]]() and [[:arctan]]() return angles in radians.
--
-- Example 1:
-- <eucode>
-- x = rad2deg(3.385938749)
-- -- x is 194
-- </eucode>
--
-- See Also:
--		{{:deg2rad]]

public function rad2deg (object x)
   return x * RADIANS_TO_DEGREES
end function

--**
-- Convert an angle measured in degrees to an angle measured in radians
--
-- Parameters:
--		# ##angle##: an object, all atoms of which will be converted, no matter how deeply nested.
--
-- Returns:
--		An **object** the same shape as ##angle##, all atoms of which were multiplied by PI/180.
--
-- Comments:
-- This function may be applied to an atom or sequence. A flat angle is PI radians and 180 degrees.
-- [[:sin]](), [[:cos]]() and [[:tan]]() expect angles in radians.
--
-- Example 1:
-- <eucode>
-- x = deg2rad(194)
-- -- x is 3.385938749
-- </eucode>
-- See Also:
-- [[:rad2deg]]

public function deg2rad (object x)
   return x * DEGREES_TO_RADIANS
end function

--****
-- === Logarithms and powers.
--
--**
-- Signature:
-- global function log(object value)
--
-- Description:
-- Return the natural logarithm of a positive number.
--
-- Parameters:
--		# ##value##: an object, any atom of which ##log##() acts upon.
--
-- Returns:
--		An **object**, the same shape as ##value##. For an atom, the returned atom is its logarithm of base E.
--
-- Errors:
--		If any atom in ##value## is not greater than zero, an error occurs as its logarithm is not defined.
--
-- Comments:
-- This function may be applied to an atom or to all elements
-- of a sequence.
--
-- To compute the inverse, you can use power(E, x)
-- where E is 2.7182818284590452, or equivalently [[:exp]](x). Beware that the logarithm grows very slowly with x, so that [[:exp]]() grows very fast.
--
-- Example 1:
-- <eucode>
-- a = log(100)
-- -- a is 4.60517
-- </eucode>
-- See Also:
--		[[:E]], [[:exp]], [[:log10]]
--

--**
-- Return the base 10 logarithm of a number.
--
-- Parameters:
--		# ##value##: an object, each atom of which will be converted, no matter how deeply nested.
--
-- Returns:
--		An **object**, the same shape as ##value##. When ##value## is an atom, raising 10 to the returned atom yields ##value## back.
--
-- Errors:
--		If any atom in ##value## is not greater than zero, its logarithm is not a real number and an error occurs.
--
-- Comments:
-- This function may be applied to an atom or to all elements
-- of a sequence. 
--
-- log10() is proportional to log() by a factor of 1/log(10), which is about .435 .
--
-- Example 1:
-- <eucode>
-- a = log10(12)
-- -- a is 2.48490665
-- </eucode>
--
-- See Also:
--		[[:log]]

public function log10(object x1)
	return log(x1) * INVLN10
end function

--**
-- Computes some power of E.
--
-- Parameters:
--		# ##value##: an object, all atoms of which will be acted upon, no matter how deeply nested.
--
--Returns:
--		An **object** the same shape as ##value##. When ##value## is an atom, its exponential is being returned.
--
--	Comments:
--	This function can be applied to a single atom or to a sequence of any shape.
--
--	Due to its rapid growth, the returned values start losing accuracy as soon as values are greater than 10.  Values above 710 will cause an overflow in hardware.
--
-- Example 1:
-- <eucode>
-- x = exp(5.4)
-- -- x is 221.4064162
-- </eucode>
-- See Also:
--		[[:log]]

public function exp(atom x)
	return power(E, x)
end function

--**
-- Signature:
-- global function power(object base, object exponent)
--
-- Description:
-- Raise a base value to some power.
--
-- Parameters:
--		# ##base##: an object, the value(s) to raise to some power.
--		# ##exponent##: an object, the exponent(s) to apply to ##base##.
--
-- Returns:
--		An **object**, the shape of which depends on ##base##'s and ##exponent##'s. For two atoms, this will be ##base## raised to the power ##exponent##.
--
-- Errors:
--		If some atom in ##base## is negative and is raised to a non integer exponent, an error will occur, as the result is undefined.
--
--		If 0 is raised to any negative power, this is the same as a zero divide and causes an error.
--
-- 		power(0,0) is illegal, because there is not an unique value that can be assigned to that quantity.
--
-- Comments:
--
-- The arguments to this function may be atoms or sequences. The rules for 
-- <a href="refman_2.htm#26">operations on sequences</a> apply.
--
-- Powers of 2 are calculated very efficiently.
--
-- Other languages have a ~** or ^ operator to perform the same action. But they don't have  sequences.
--
-- Example 1:
-- <eucode>
-- ? power(5, 2)
-- -- 25 is printed
-- </eucode>
--
-- Example 2:
-- <eucode>
-- ? power({5, 4, 3.5}, {2, 1, -0.5})
-- -- {25, 4, 0.534522} is printed
-- </eucode>
--
-- Example 3:
-- <eucode>
-- ? power(2, {1, 2, 3, 4})
-- -- {2, 4, 8, 16}
-- </eucode>
--
-- Example 4:
-- <eucode>
-- ? power({1, 2, 3, 4}, 2)
-- -- {1, 4, 9, 16}
-- </eucode>
--
-- See Also:
--		[[:log]], [[:Operations on sequences]]
--
--**
-- Signature:
-- global function sqrt(object value)
--
-- Description:
-- Calculate the square root of a number.
--
-- Parameters:
--		# ##value##: an object, each atom in which will be acted upon.
--
-- Returns:
--		An **object** the same shape as ##value##. When ##value## is an atom, the result is the positive atom whose square is ##value##.
--
-- Errors:
--		If any atom in ##value## is less than zero, an error will occur, as no squared real can be less than zero.
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence.
--
-- Example 1:
-- <eucode>
-- r = sqrt(16)
-- -- r is 4
-- </eucode>
--
-- Se Also:
--		[[:power]], [[:Operations on sequences]]
--

--****
-- === Hyperbolic trigonometry
--

--**
-- Computes the hyperbolic cosine of an object.
--
-- Parameters:
--		# ##x##: the object to process.
--
-- Returns:
-- An **object**, the same shape as ##x##, each atom of which was acted upon.
--
-- Comments:
--
-- The hyperbolic cosine grows like the exponential function.
--
-- For all reals, ##poweer(cosh(x), 2) - power(sinh(x), 2) = 1. Compare with ordinary trigonometry.
--
-- Example 1:
-- <eucode>
-- ?cosh(LN2) -- prints out 1.25
-- </eucode>
-- See Also:
-- [[:cos]], [[:sinh]], [[:arccosh]]

public function cosh(object a)
    return (exp(a)+exp(-a))/2
end function

--**
-- Computes the hyperbolic sine of an object.
--
-- Parameters:
--		# ##x##: the object to process.
--
-- Returns:
-- An **object**, the same shape as ##x##, each atom of which was acted upon.
--
-- Comments:
--
-- The hyperbolic sine grows like the exponential function.
--
-- For all reals, ##poweer(cosh(x), 2) - power(sinh(x), 2) = 1. Compare with ordinary trigonometry.
--
-- Example 1:
-- <eucode>
-- ?sinh(LN2) -- prints out 0.75
-- </eucode>
-- See Also:
-- [[:cosh]], [[:sin]], [[:arcsinh]]

public function sinh(object a)
    return (exp(a)-exp(-a))/2
end function

--**
-- Computes the hyperbolic tangent of an object.
--
-- Parameters:
--		# ##x##: the object to process.
--
-- Returns:
-- An **object**, the same shape as ##x##, each atom of which was acted upon.
--
-- Comments:
--
-- The hyperbolic tangent takes values from -1 to +1.
--
-- ##tanh##() is he ratio ##sinh() / cosh()##. Compare with ordinary trigonometry.
--
-- Example 1:
-- <eucode>
-- ?tanh(LN2) -- prints out 0.6
-- </eucode>
--
-- See Also:
-- [[:cosh]], [[:sinh]], [[:tan]], [[:arctanh]]

public function tanh(object a)
    return sinh(a)/cosh(a)
end function

--**
-- Computes the reverse hyperbolic sine of an object.
--
-- Parameters:
--		# ##x##: the object to process.
--
-- Returns:
-- An **object**, the same shape as ##x##, each atom of which was acted upon.
--
-- Comments:
--
-- The hyperbolic sine grows like the logarithm function.
--
-- Example 1:
-- <eucode>
-- ?arcsinh(1) -- prints out 0,4812118250596034
-- </eucode>
--
-- See Also:
-- [[:arccosh]], [[:arcsin]], [[:sinh]]

public function arcsinh(object a)
    return log(a+sqrt(1+a*a))
end function

type not_below_1(object x)
    if atom(x) then
        return x>=1.0
    end if
    for i=1 to length(x) do
        if not not_below_1(x[i]) then
            return 0
        end if
    end for
    return 1
end type

--**
-- Computes the reverse hyperbolic cosine of an object.
--
-- Parameters:
--		# ##x##: the object to process.
--
-- Returns:
-- An **object**, the same shape as ##x##, each atom of which was acted upon.
--
-- Errors:
-- Since [[:cosh]] only takes values not below 1, an argument below 1 causes an error.
--
-- Comments:
--
-- The hyperbolic cosine grows like the logarithm function.
--
-- Example 1:
-- <eucode>
-- ?arccosh(1) -- prints out 0
-- </eucode>
--
-- See Also:
-- [[:arccos]], [[:arcsinh]], [[:cosh]]

public function arccosh(not_below_1 a)
    return log(a+sqrt(a*a-1))
end function

type abs_below_1(object x)
    if atom(x) then
        return x>-1.0 and x<1.0
    end if
    for i=1 to length(x) do
        if not abs_below_1(x[i]) then
            return 0
        end if
    end for
    return 1
end type

--**
-- Computes the reverse hyperbolic tangent of an object.
--
-- Parameters:
--		# ##x##: the object to process.
--
-- Returns:
-- An **object**, the same shape as ##x##, each atom of which was acted upon.
--
-- Errors:
-- Since [[:tanh]] only takes values between -1 and +1 excluded, an out of range argument causes an error.
--
-- Comments:
--
-- The hyperbolic cosine grows like the logarithm function.
--
-- Example 1:
-- <eucode>
-- ?arctanh(1/2) -- prints out 0,5493061443340548456976
-- </eucode>
--
-- See Also:
-- [[:arccos]], [[:arcsinh]], [[:cosh]]

public function arctanh(abs_below_1 a)
    return log((1+a)/(1-a))/2
end function

--****
-- === Accumulation
--

--**
-- Compute the sum of all atoms in the argument, no matter how deeply nested
--
-- Parameters:
--		# ##values##: an object, all atoms of which will be added up, no matter how nested.
--
-- Returns:
--		An **atom**, the sum of all atoms in [[:flatten]](##values##).
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence
--
-- Example 1:
--   <eucode>
--   a = sum({10, 20, 30})
--   -- a is 60
--
--   a = sum({10.5, {11.2} , 8.1})
--   -- a is 29.8
--   </eucode>
-- See Also:
--		[[:can_add]], [[:product]], [[:or_all]]

public function sum(object a)
	atom b
	if atom(a) then
		return a
	end if
	b = 0
	for i = 1 to length(a) do
		if atom(a[i]) then
			b += a[i]
		else
			b += sum(a[i])
		end if
	end for
	return b
end function

--**
-- Compute the product of all the atom in the argument, no matter how deeply nested.
--
-- Parameters:
--		# ##values##: an object, all atoms of which will be multimlied up, no matter how nested.
--
-- Returns:
--		An **atom**, the product of all atoms in [[:flatten]](##values##).
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence
--
-- Example 1:
--   <eucode>
--   a = product({10, 20, 30})
--   -- a is 6000
--
--   a = product({10.5, {11.2} , 8.1})
--   -- a is 952.56
--   </eucode>
--
-- See Also:
--		[[:can_add]], [[:sum]], [[:or_all]]

public function product(object a)
	atom b
	if atom(a) then
		return a
	end if
	b = 0
	for i = 1 to length(a) do
		if atom(a[i]) then
			b *= a[i]
		else
			b *= sum(a[i])
		end if
	end for
	return b
end function


--**
-- Or's together all atoms in the argument, no matter how deeply nested.
--
-- Parameters:
--		# ##values##: an object, all atoms of which will be added up, no matter how nested.
--
-- Returns:
--		An **atom**, the result of or'ing all atoms in [[:flatten]](##values##).
--
-- Comments:
--
-- This function may be applied to an atom or to all elements of a sequence. It performs [[:or_bits]]() operations repeatedly.
--
-- Example 1:
--   <eucode>
--   a = sum({10, 7, 35})
--   -- a is 47
--   </eucode>
--
-- See Also:
--		[[:can_add]], [[:sum]], [[:product]], [[:or_bits]

public function or_all	(object a)
	atom b
	if atom(a) then
		return a
	end if
	b = 0
	for i = 1 to length(a) do
		if atom(a[i]) then
			b = or_bits(b, a[i])
		else
			b = or_bits(b, or_all(a[i]))
		end if
	end for
	return b
end function
--****
-- === Bitwise opreations
--
--**
-- Signature:
-- global function and_bits(object a, object b)
--
-- Description:
-- Perform the logical AND operation on corresponding bits in two objects. A bit in the
-- result will be 1 only if the corresponding bits in both arguments are 1.
--
-- Parameters:
-- 		# ##a##: one of the objects involved
-- 		# ##b##: the second object
--
-- Returns:
-- An **object** whose shape depends on the shape of both arguments. Each atom in this object 
-- is obtained by logical AND between atoms on both objects.
--
-- Comments: 
--
-- The arguments to this function may be atoms or sequences. The rules for operations on sequences apply.
-- The atoms in the arguments must be representable as 32-bit numbers, either signed or unsigned.
-- 
-- If you intend to manipulate full 32-bit values, you should declare your variables as atom, rather than integer. Euphoria's integer type is limited to 31-bits. 
-- 
-- Results are treated as signed numbers. They will be negative when the highest-order bit is 1. 
--
-- To understand the binary representation of a number you should display it in hexadecimal notation. 
-- Use the %x format of [[:printf]](). Using [[:int_to_bits]]() is an even more direct approach.
--  
-- Example 1:  
-- <eucode>
--  a = and_bits(#0F0F0000, #12345678)
-- -- a is #02040000
-- </eucode>
--  
-- Example 2:  
-- <eucode>
--  a = and_bits(#FF, {#123456, #876543, #2211})
-- -- a is {#56, #43, #11}
-- </eucode>
-- 
-- Example 3:
-- <eucode>
--  a = and_bits(#FFFFFFFF, #FFFFFFFF)
-- -- a is -1
-- -- Note that #FFFFFFFF is a positive number,
-- -- but the result of a bitwise logical operation is interpreted
-- -- as a signed 32-bit number, so it's negative.
-- </eucode>
--
-- See Also:
--  [[:or_bits]], [[:xor_bits]], [[:not_bits]], [[:int_to_bits]]
--
--**
-- Signature:
-- global function xor_bits(object a, object b)
--
-- Description:
-- Perform the logical XOR operation on corresponding bits in two objects. A bit in the
-- result will be 1 only if the corresponding bits in both arguments are different.
--
-- Parameters:
-- 		# ##a##: one of the objects involved
-- 		# ##b##: the second object
--
-- Returns:
-- An **object** whose shape depends on the shape of both arguments. Each atom in this object 
-- is obtained by logical XOR between atoms on both objects.
--
-- Comments:
-- The arguments must be representable as 32-bit numbers, either signed or unsigned.
-- 
-- If you intend to manipulate full 32-bit values, you should declare your variables as atom, rather than integer. Euphoria's integer type is limited to 31-bits. 
-- 
-- Results are treated as signed numbers. They will be negative when the highest-order bit is 1. 
-- 
-- Example 1:  
-- <eucode>
--  a = xor_bits(#0110, #1010)
-- -- a is #1100
-- </eucode>
-- 
-- See Also: 
--     [[:and_bits]], [[:or_bits]], [[:not_bits]], [[:int_to_bits]]
--**
-- Signature:
-- global function or_bits(object a, object b)
--
-- Description:
-- Perform the logical OR operation on corresponding bits in two objects. A bit in the
-- result will be 1 only if the corresponding bits in both arguments are bot both 0.
--
-- Parameters:
-- 		# ##a##: one of the objects involved
-- 		# ##b##: the second object
--
-- Returns:
-- An **object** whose shape depends on the shape of both arguments. Each atom in this object 
-- is obtained by logical XOR between atoms on both objects.
--
-- Comments:
-- The arguments must be representable as 32-bit numbers, either signed or unsigned.
-- 
-- If you intend to manipulate full 32-bit values, you should declare your variables as atom, rather than integer. Euphoria's integer type is limited to 31-bits. 
-- 
-- Results are treated as signed numbers. They will be negative when the highest-order bit is 1.
--
-- Example 1:  
-- <eucode>
--  a = or_bits(#0F0F0000, #12345678)
-- -- a is #1F3F5678
-- </eucode>
--  
-- Example 2:
-- <eucode>
--  a = or_bits(#FF, {#123456, #876543, #2211})
-- -- a is {#1234FF, #8765FF, #22FF}
-- </eucode>
-- 
-- See Also: 
--    [[:and_bits]], [[:xor_bits]], [[:not_bits]], [[:int_to_bits]]

--**
-- Signature:
-- global function not_bits(object a)
--
-- Description:
-- Perform the logical NOT operation on each bit in an object. A bit in the result will be 1
-- when the corresponding bit in x1 is 0, and will be 0 when the corresponding bit in x1 is 1.
--
-- Parameters:
-- 		# ##a##: the object to invert the bits of.
--
-- Returns:
-- An **object**, the same shape as ##a##. Each bit in an atom of the result is the reverse of the corresponding bit inside ##a##.
--
-- Comments: 
-- The argument to this function may be an atom or a sequence. 
--
-- The argument must be representable as a 32-bit number, either signed or unsigned. 
-- 
-- If you intend to manipulate full 32-bit values, you should declare your variables as atom, rather than integer. Euphoria's integer type is limited to 31-bits. 
-- 
-- Results are treated as signed numbers. They will be negative when the highest-order bit is 1. 
-- 
-- A simple equality holds for an atom ##a##: ##a + not_bits(a) = -1##.
--
-- Example 1:
-- <eucode>
--  a = not_bits(#000000F7)
-- -- a is -248 (i.e. FFFFFF08 interpreted as a negative number)
-- </eucode>
--
-- See Also: 
--   [[:and_bits]], [[:or_bits]], [[:xor_bits]], [[:int_to_bits]]

--**
-- Left shift moves a left by b bits
--
-- Parameters
--   # ##a## - value to be moved
--   # ##b## - number of bits to be moved left by
--
-- Example 1:
-- <eucode>
-- ? left_shift(2, 2) -- 8
-- ? left_shift(4, 2) -- 16
-- ? left_shift(4, 4) -- 64
-- </eucode>
--
-- See Also:
--   [[:right_shift]]

public function left_shift(integer a, integer b)
	return round(a * power(2, b))
end function

--**
-- Right shift moves a right by b bits
--
-- Parameters:
--   # ##a## - value to be moved
--   # ##b## - number of bits to be moved right by
--
-- Example 1:
-- <eucode>
-- ? right_shift(2, 2) -- 0
-- ? right_shift(4, 2) -- 1
-- ? right_shift(40, 2) -- 10
-- </eucode>
--
-- See Also:
--   [[:left_shift]]

public function right_shift(integer a, integer b)
	return round(a / power(2, b))
end function

--****
-- === Random numbers
--

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

--**
-- Signature:
-- global function rand(object maximum)
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
-- See Als:
-- 		[[:set_rand]], [[:ceil]]

--****
-- Arithmetics
--

--**
-- Returns the greater common divisor of to atoms
--
-- Parameters:
--		# ##p##: one of the atoms to consider
--		# ##q##: the other atom.
--
-- Returns:
-- A positive **atom** without a fractional part, evenly dividing both parameters, and is the 
-- greatest value with those properties.
--
-- Comments:
--
-- Signs are ignored. Atoms are rounded down to integers.
--
-- Any zero parameter causes 0 to be returned.
--
-- Parameters and return value are atoms so as to take mathematical integers up to ##power(2,53)##.
--
-- Example 1:
-- <eucode>
-- ?gcd(76.3, -114) -- prints out gcd(76,114), which is 38
-- </eucode>
--

public function gcd(atom p, atom q)
	atom r
	
	if p<0 then
		p=floor(-p)
	else
		p=floor(p)
	end if
	if q<0 then
		q=floor(-q)
	else
		q=floor(q)
	end if
	if p<q then
		r=p
		p=q
		q=r
	end if
	if q<=1 then
		return q
	end if

    while 1 do
		r=remainder(p,q)
		if r=1 then
			return r
		elsif r=0 then
			return q
		else
			p=q
			q=r
		end if
    end while
end function
