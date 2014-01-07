--****
-- == Math
--
-- <<LEVELTOC level=2 depth=4>>
--
namespace math

public include std/rand.e
public include std/mathcons.e
include std/error.e

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


--****
-- === Sign and Comparisons
--

--**
-- returns the absolute value of numbers.
--
-- Parameters:
--		# ##value## : an object, each atom is processed, no matter how deeply nested.
--
-- Returns:
--		An **object**, the same shape as ##value##. When ##value## is an atom,
-- the result is the same if not less than zero, and the opposite value otherwise.
--
-- Comments:
--   This function may be applied to an atom or to all elements of a sequence.
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
-- returns -1, 0 or 1 for each element according to it being negative, zero or positive.
--
-- Parameters:
--		# ##value## : an object, each atom of which will be acted upon, no matter how deeply nested.
--
-- Returns:
--		An **object**, the same shape as ##value##. When ##value## is an atom, the result is -1 if ##value## is less than zero, 1 if greater and 0 if equal.
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence.
--
-- For an atom, ##sign(x)## is the same as [[:compare]](x,0).
--
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
	-- small so normally it will be inlined 
	return (a > 0) - (a < 0)
end function

--**
-- returns the larger of two objects.
--
-- Parameters:
--		# ##objA## : an object.
--		# ##objB## : an object.
-- Returns:
--		Whichever of ##objA## and ##objB## is the larger one.
--
-- Comments:
-- Introduced in v4.0.3
--
-- Example 1:
-- <eucode>
-- ? larger_of(10, 15.4) -- returns 15.4
-- ? larger_of("cat", "dog") -- returns "dog"
-- ? larger_of("apple", "apes") -- returns "apple"
-- ? larger_of(10, 10) -- returns 10
-- </eucode>
--
-- See Also:
--		[[:max]], [[:compare]], [[:smaller_of]]

public function larger_of(object objA, object objB)

	if compare(objA, objB) > 0 then
		return objA
	else
		return objB
	end if
end function

--**
-- returns the smaller of two objects.
--
-- Parameters:
--		# ##objA## : an object.
--		# ##objB## : an object.
--
-- Returns:
--		Whichever of ##objA## and ##objB## is the smaller one.
--
-- Comments:
-- Introduced in v4.0.3
--
-- Example 1:
-- <eucode>
-- ? smaller_of(10, 15.4) -- returns 10
-- ? smaller_of("cat", "dog") -- returns "cat"
-- ? smaller_of("apple", "apes") -- returns "apes"
-- ? smaller_of(10, 10) -- returns 10
-- </eucode>
--
-- See Also:
--		[[:min]], [[:compare]], [[:larger_of]]

public function smaller_of(object objA, object objB)
	if compare(objA, objB) < 0 then
		return objA
	else
		return objB
	end if
end function

--**
-- computes the maximum value among all the argument's elements.
--
-- Parameters:
--		# ##values## : an object, all atoms of which will be inspected, no matter how deeply nested.
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
--
-- See Also:
--		[[:min]], [[:compare]], [[:flatten]]

public function max(object a)
	atom b, c
	if atom(a) then
		return a
	end if
	b = mathcons:MINF
	for i = 1 to length(a) do
		c = max(a[i])
		if c > b then
			b = c
		end if
	end for
	return b
end function

--**
-- computes the minimum value among all the argument's elements.
--
-- Parameters:
--		# ##values## : an object, all atoms of which will be inspected, no matter how deeply nested.
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
	b = mathcons:PINF
	for i = 1 to length(a) do
		c = min(a[i])
			if c < b then
				b = c
		end if
	end for
	return b
end function

--**
-- ensures that the ##item## is in a range of values supplied by inclusive ##range_limits##.
--
-- Parameters:
--   # ##item## : The object to test for.
--   # ##range_limits## : A sequence of two or more elements. The first is assumed
--    to be the smallest value and the last is assumed to be the highest value.
--
-- Returns:
--   A **object**, If ##item## is lower than the first item in the ##range_limits##
--                 it returns the first item. 
--                 If  ##item## is higher than the last element in the ##range_limits##
--                 it returns the last item.
--                 Otherwise it returns ##item##.
--
-- Example 1:
--   <eucode>
--   object valid_data = ensure_in_range(user_data, {2, 75})
--   if not equal(valid_data, user_data) then
--       errmsg("Invalid input supplied. Using %d instead.", valid_data)
--   end if
--   procA(valid_data)
--   </eucode>

public function ensure_in_range(object item, sequence range_limits)
	if length(range_limits) < 2 then
		return item
	end if
	
	if eu:compare(item, range_limits[1]) < 0 then
		return range_limits[1]
	end if
	if eu:compare(item, range_limits[$]) > 0 then
		return range_limits[$]
	end if
	return item
end function

--**
-- ensures that the ##item## is in a list of values supplied by ##list##.
--
-- Parameters:
--   # ##item## : The object to test for.
--   # ##list## : A sequence of elements that ##item## should be a member of.
--	# ##default## : an integer, the index of the list item to return if ##item## is not found. Defaults to 1.
--
-- Returns:
--   An **object**, if ##item## is not in the list, it returns the list item of index ##default##,
--                 otherwise it returns ##item##.
--
-- Comments:
--
-- If ##default## is set to an invalid index, the first item on the list is returned instead
-- when ##item## is not on the list.
--
-- Example 1:
--   <eucode>
--   object valid_data = ensure_in_list(user_data, {100, 45, 2, 75, 121})
--   if not equal(valid_data, user_data) then
--       errmsg("Invalid input supplied. Using %d instead.", valid_data)
--   end if
--   procA(valid_data)
--   </eucode>

public function ensure_in_list(object item, sequence list, integer default=1)
	if length(list) = 0 then
		return item
	end if
	if find(item, list) = 0 then
		if default>=1 and default<=length(list) then
		    return list[default]
		else
			return list[1]
		end if
	end if
	return item
end function

--****
-- === Roundings and Remainders
--

--****
-- Signature:
--   <built-in> function remainder(object dividend, object divisor)
--
-- Description:
-- computes the remainder of the division of two objects using truncated division.
--
-- Parameters:
--		# ##dividend## : any Euphoria object.
--		# ##divisor## : any Euphoria object.
--
-- Returns:
--		An **object**, the shape of which depends on ##dividend##'s and 
--      ##divisor##'s. For two atoms, this is the remainder of dividing 
--      ##dividend## by  ##divisor##, with ##dividend##'s sign.
--
-- Errors:
-- # If any atom in ##divisor## is 0, this is an error condition as it 
--  amounts to an attempt to divide by zero.
-- # If both ##dividend## and ##divisor## are sequences, they must be the
--   same length as each other.
--
-- Comments:
-- * There is a integer ##N## such that ##dividend## = ##N## * ##divisor## + result. 
-- * The result has the sign of ##dividend## and lesser magnitude than ##divisor##.
-- *  The result has the same sign as the dividend.
-- * This differs from [[:mod]] in that when the operands' signs are different
-- this function rounds ##dividend/divisior## towards zero whereas ##mod## rounds
-- away from zero.
--
-- The arguments to this function may be atoms or sequences. The rules for
-- [[:operations on sequences]] apply, and determine the shape of the returned object.
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
-- computes the remainder of the division of two objects using floored division.
--
-- Parameters:
--		# ##dividend## : any Euphoria object.
--		# ##divisor## : any Euphoria object.
--
-- Returns:
--	An **object**, the shape of which depends on ##dividend##'s and
-- ##divisor##'s. For two atoms, this is the remainder of dividing ##dividend##
-- by ##divisor##, with ##divisor##'s sign.
--
-- Comments:
-- * There is a integer ##N## such that ##dividend## = N * ##divisor## + result.
-- * The result is non-negative and has lesser magnitude than ##divisor##.
-- n needs not fit in an Euphoria integer.
-- *  The result has the same sign as the dividend.
-- * The arguments to this function may be atoms or sequences. The rules for
-- [[:operations on sequences]] apply, and determine the shape of the returned object.
-- * When both arguments have the same sign, mod() and [[:remainder]]
-- return the same result. 
-- * This differs from [[:remainder]] in that when the operands' signs are different
-- this function rounds ##dividend/divisior## away from zero whereas ##remainder## rounds
-- towards zero.
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
-- -- s is {1,-0.1,1,-2.5}
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
-- 		[[:remainder]], [[:Relational operators]], [[:Operations on sequences]]

public function mod(object x, object y)
	if equal(sign(x), sign(y)) then
		return remainder(x,y)
	end if
	return x - y * floor(x / y)
end function

--**
-- returns the integer portion of a number.
--
-- Parameters:
--		# ##value## : any Euphoria object.
--
-- Returns:
--	An **object**, the shape of which depends on ##values##'s. Each item in the 
-- returned object will be an integer. These are the same corresponding items
-- in ##value## except with any fractional portion removed.
--
-- Comments:
-- * This is essentially done by always rounding towards zero. The [[:floor]] function
-- rounds towards negative infinity, which means it rounds towards zero for positive
-- values and away from zero for negative values.
-- * Note that ##trunc(x) + frac(x) = x##
--
-- Example 1:
-- <eucode>
-- a = trunc(9.4)
-- -- a is 9
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = trunc({81, -3.5, -9.999, 5.5})
-- -- s is {81,-3, -9, 5}
-- </eucode>
-- See Also:
-- 		[[:floor]] [[:frac]]
public function trunc(object x)
	return sign(x) * floor(abs(x))
end function


--**
-- returns the fractional portion of a number.
--
-- Parameters:
--		# ##value## : any Euphoria object.
--
-- Returns:
--	An **object**, the shape of which depends on ##values##'s. Each item in the 
-- returned object will be the same corresponding items
-- in ##value## except with the integer portion removed.
--
-- Comments:
-- Note that ##trunc(x) + frac(x) = x##
--
-- Example 1:
-- <eucode>
-- a = frac(9.4)
-- -- a is 0.4
-- </eucode>
--
-- Example 2:
-- <eucode>
-- s = frac({81, -3.5, -9.999, 5.5})
-- -- s is {0, -0.5, -0.999, 0.5}
-- </eucode>
--
-- See Also:
-- 		[[:trunc]]

public function frac(object x)
	object temp = abs(x)
	return sign(x) * (temp - floor(temp))
end function


--**
-- returns an integral division of two objects.
--
-- Parameters:
--		# ##divided## : any Euphoria object.
--		# ##divisor## : any Euphoria object.
--
-- Returns:
--	An **object**, which will be a sequence if either ##dividend## or ##divisor##
-- is a sequence. 
--
-- Comments:
-- * This calculates how many non-empty sets when ##dividend## is divided by ##divisor##.
-- * The result's sign is the same as the ##dividend##'s sign.
--
-- Example 1:
-- <eucode>
-- object Tokens = 101
-- object MaxPerEnvelope = 5
-- integer Envelopes = intdiv( Tokens, MaxPerEnvelope) --> 21
-- </eucode>
--

public function intdiv(object a, object b)	
	return sign(a)*ceil(abs(a)/abs(b))
end function

--****
-- Signature:
-- <built-in> function floor(object value)
--
-- Description:
-- Rounds ##value## down to the next integer less than or equal to ##value##. 
--
-- Parameters:
--		# ##value## : any Euphoria object; each atom in ##value## will be acted upon.
-- 
-- Comments:
-- It does not simply truncate the fractional part, but actually rounds towards
-- negative infinity.
--
-- Returns:
-- An **object**, the same shape as ##value## but with each item guarenteed to be
-- an integer less than or equal to the corresponding item in ##value##.
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
-- computes the next integer equal or greater than the argument. 
--
-- Parameters:
--		# ##value## : an object, each atom of which processed, no matter how deeply nested.
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
-- returns the argument's elements rounded to some precision.
--
-- Parameters:
--		# ##value## : an object, each atom of which will be acted upon, no matter how deeply nested.
--		# ##precision## : an object, the rounding precision(s). If not passed, this defaults to 1.
--
-- Returns:
--		An **object**, the same shape as ##value##. When ##value## is an atom, the result is that atom rounded to the nearest integer multiple of 1/##precision##.
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
		error:crash("The lengths of the two supplied sequences do not match.")
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

--****
-- Signature:
-- <built-in> function arctan(object tangent)
--
-- Description:
--   returns an angle with given tangent.
--
-- Parameters:
--   # ##tangent## : an object, each atom of which will be converted, no matter how deeply nested.
--
-- Returns:
--   An **object**, of the same shape as ##tangent##. For each atom in ##flatten(tangent)##,
--   the angle with smallest magnitude that has this atom as tangent is computed.
--
-- Comments:
--   All atoms in the returned value lie between ##-PI/2## and ##PI/2##, exclusive.
--
--   This function may be applied to an atom or to all elements of a sequence (of sequence (...)).
--
--   ##arctan## is faster than ##[[:arcsin]]## or ##[[:arccos]]##.
--
-- Example 1:
--   <eucode>
--   s = arctan({1,2,3})
--   -- s is {0.785398, 1.10715, 1.24905}
--   </eucode>
-- See Also:
--		[[:arcsin]], [[:arccos]], [[:tan]], [[:flatten]]

--****
-- Signature:
-- <built-in> function tan(object angle)
--
-- Description:
--   returns the tangent of an angle, or a sequence of angles.
--
-- Parameters:
--   # ##angle## : an object, each atom of which will be converted, no matter how deeply nested.
--
-- Returns:
--   An **object**, of the same shape as ##angle##. Each atom in the flattened ##angle## is
--   replaced by its tangent.
--
-- Errors:
--   If any atom in ##angle## is an odd multiple of PI/2, an error occurs, as its tangent
--   would be infinite.
--
-- Comments:
--   This function may be applied to an atom or to all elements of a sequence of arbitrary
--   shape, recursively.
--
-- Example 1:
--   <eucode>
--   t = tan(1.0)
--   -- t is 1.55741
--   </eucode>
-- See Also:
--		[[:sin]], [[:cos]], [[:arctan]]

--****
-- Signature:
--   <built-in> function cos(object angle)
--
-- Description:
-- returns the cosine of an angle expressed in radians.
--
-- Parameters:
--		# ##angle## : an object, each atom of which will be converted, no matter how deeply nested.
--
-- Returns:
--		An **object**, the same shape as ##angle##. Each atom in ##angle## is turned into its cosine.
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence.
--
-- The cosine of an angle is an atom between -1 and 1 inclusive. 0.0 is hit by odd multiples of ##PI/2## only.
--
-- Example 1:
-- <eucode>
-- x = cos({.5, .6, .7})
-- -- x is {0.8775826, 0.8253356, 0.7648422}
-- </eucode>
--
-- See Also:
--		[[:sin]], [[:tan]], [[:arccos]], [[:PI]], [[:deg2rad]]

--****
-- Signature:
-- <built-in> function sin(object angle)
--
-- Description:
-- returns the sine of an angle expressed in radians.
--
-- Parameters:
--   # ##angle## : an object, each atom in which will be acted upon.
--
-- Returns:
--   An **object**, the same shape as ##angle##. When ##angle## is an atom, the
--   result is the sine of ##angle##.
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence.
--
-- The sine of an angle is an atom between -1 and 1 inclusive. 0.0 is hit by integer
-- multiples of ##PI## only.
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
-- returns an angle given its cosine.
--
-- Parameters:
--   # ##value## : an object, each atom in which will be acted upon.
--
-- Returns:
--   An **object**, the same shape as ##value##. When ##value## is an atom, the result is
--   an atom, an angle whose cosine is ##value##.
--
-- Errors:
--   If any atom in ##value## is not in the -1..1 range, it cannot be the cosine of a real
--   number, and an error occurs.
--
-- Comments:
--
-- A value between 0 and [[:PI]] radians will be returned.
--
-- This function may be applied to an atom or to all elements of a sequence.
--
-- ##arccos## is not as fast as [[:arctan]].
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
	return mathcons:HALFPI - 2 * arctan(x / (1.0 + sqrt(1.0 - x * x)))
end function

--**
-- returns an angle given its sine.
--
-- Parameters:
--		# ##value## : an object, each atom in which will be acted upon.
--
-- Returns:
--		An **object**, the same shape as ##value##. When ##value## is an atom, the result is an atom, an angle whose sine is ##value##.
--
-- Errors:
--		If any atom in ##value## is not in the -1..1 range, it cannot be the sine of a real number, and an error occurs.
--
-- Comments:
-- A value between ##-PI/2## and ##+PI/2## (radians) inclusive will be returned.
--
-- This function may be applied to an atom or to all elements of a sequence.
--
-- ##arcsin## is not as fast as [[:arctan]].
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
-- calculate the arctangent of a ratio.
--
-- Parameters:
--		# ##y## : an atom, the numerator of the ratio
--		# ##x## : an atom, the denominator of the ratio
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
			return arctan(y/x) - mathcons:PI
		else
			return arctan(y/x) + mathcons:PI
		end if
	elsif y > 0 then
		return mathcons:HALFPI
	elsif y < 0 then
		return -(mathcons:HALFPI)
	else
		return 0
	end if
end function

--**
-- converts an angle measured in radians to an angle measured in degrees.
--
-- Parameters:
--		# ##angle## : an object, all atoms of which will be converted, no matter how deeply nested.
--
-- Returns:
--		An **object**, the same shape as ##angle##, all atoms of which were multiplied by ##180/PI##.
--
-- Comments:
-- This function may be applied to an atom or sequence. A flat angle is ##PI## radians and 180 degrees.
--
-- [[:arcsin]], [[:arccos]] and [[:arctan]] return angles in radians.
--
-- Example 1:
-- <eucode>
-- x = rad2deg(3.385938749)
-- -- x is 194
-- </eucode>
--
-- See Also:
--		[[:deg2rad]]

public function rad2deg (object x)
   return x * mathcons:RADIANS_TO_DEGREES
end function

--**
-- converts an angle measured in degrees to an angle measured in radians.
--
-- Parameters:
--		# ##angle## : an object, all atoms of which will be converted, no matter how deeply nested.
--
-- Returns:
--		An **object**, the same shape as ##angle##, all atoms of which were multiplied by ##PI/180##.
--
-- Comments:
-- This function may be applied to an atom or sequence. A flat angle is ##PI## radians and 180 degrees.
-- [[:sin]], [[:cos]] and [[:tan]] expect angles in radians.
--
-- Example 1:
-- <eucode>
-- x = deg2rad(194)
-- -- x is 3.385938749
-- </eucode>
-- See Also:
-- [[:rad2deg]]

public function deg2rad (object x)
   return x * mathcons:DEGREES_TO_RADIANS
end function

--****
-- === Logarithms and Powers
--

--****
-- Signature:
-- <built-in> function log(object value)
--
-- Description:
-- returns the natural logarithm of a positive number.
--
-- Parameters:
--		# ##value## : an object, any atom of which ##log## acts upon.
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
-- To compute the inverse, you can use ##power(E, x)##
-- where E is 2.7182818284590452, or equivalently [[:exp]](x). Beware that the logarithm grows very slowly with x, so that [[:exp]] grows very fast.
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
-- returns the base 10 logarithm of a number.
--
-- Parameters:
--		# ##value## : an object, each atom of which will be converted, no matter how deeply nested.
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
-- ##log10## is proportional to ##log## by a factor of ##1/log(10)##, 
-- which is about ##0.435## .
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
	return log(x1) * mathcons:INVLN10
end function

--**
-- computes some power of E.
--
-- Parameters:
--		# ##value## : an object, all atoms of which will be acted upon, no matter how deeply nested.
--
--Returns:
--		An **object**, the same shape as ##value##. When ##value## is an atom, its exponential is being returned.
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
	return power( mathcons:E, x)
end function

--****
-- Signature:
-- <built-in> function power(object base, object exponent)
--
-- Description:
-- raises a base value to some power.
--
-- Parameters:
--		# ##base## : an object, the value or values to raise to some power.
--		# ##exponent## : an object, the exponent or exponents to apply to ##base##.
--
-- Returns:
--		An **object**, the shape of which depends on ##base##'s and ##exponent##'s. For two atoms, this will be ##base## raised to the power ##exponent##.
--
-- Errors:
--		If some atom in ##base## is negative and is raised to a non integer exponent, an error will occur, as the result is undefined.
--
--		If 0 is raised to any negative power, this is the same as a zero divide and causes an error.
--
-- 		##power(0,0)## is illegal, because there is not an unique value that can be assigned to that quantity.
--
-- Comments:
--
-- The arguments to this function may be atoms or sequences. The rules for 
-- [[:operations on sequences]] apply.
--
-- Powers of 2 are calculated very efficiently.
--
-- Other languages have a ##~**## or ##^## operator to perform the same action. But they do not have  sequences.
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

--****
-- Signature:
-- <built-in> function sqrt(object value)
--
-- Description:
-- calculates the square root of a number.
--
-- Parameters:
--		# ##value## : an object, each atom in which will be acted upon.
--
-- Returns:
--		An **object**, the same shape as ##value##. When ##value## is an atom, the result is the positive atom whose square is ##value##.
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
-- See Also:
--		[[:power]], [[:Operations on sequences]]
--

--**
-- computes the nth Fibonacci Number.
--
-- Parameters:
--		# ##value## : an integer. The starting value to compute a Fibonacci Number from.
--
-- Returns:
-- An **atom**,
-- * The Fibonacci Number specified by value.
--
-- Comments:
-- * Note that due to the limitations of the floating point implementation,
-- only 'i' values less than 76 are accurate on //Windows// platforms, and 
-- 69 on other platforms (due to rounding differences in the native C
-- runtime libraries).
--
-- Example 1:
-- <eucode>
--   ? fib(6)
-- -- output ... 
-- -- 8
-- </eucode>
--
public function fib(integer i)
	return floor((power( mathcons:PHI, i) / mathcons:SQRT5) + 0.5)
end function

--****
-- === Hyperbolic Trigonometry
--

--**
-- computes the hyperbolic cosine of an object.
--
-- Parameters:
--		# ##x## : the object to process.
--
-- Returns:
-- An **object**, the same shape as ##x##, each atom of which was acted upon.
--
-- Comments:
--
-- The hyperbolic cosine grows like the exponential function.
--
-- For all reals, ##power(cosh(x), 2) - power(sinh(x), 2) = 1##. Compare 
-- with ordinary trigonometry.
--
-- Example 1:
-- <eucode>
-- ? cosh(LN2) -- prints out 1.25
-- </eucode>
--
-- See Also:
-- [[:cos]], [[:sinh]], [[:arccosh]]

public function cosh(object a)
    return (exp(a)+exp(-a))/2
end function

--**
-- computes the hyperbolic sine of an object.
--
-- Parameters:
--		# ##x## : the object to process.
--
-- Returns:
-- An **object**, the same shape as ##x##, each atom of which was acted upon.
--
-- Comments:
--
-- The hyperbolic sine grows like the exponential function.
--
-- For all reals, ##power(cosh(x), 2) - power(sinh(x), 2) = 1##. Compare 
-- with ordinary trigonometry.
--
-- Example 1:
-- <eucode>
-- ? sinh(LN2) -- prints out 0.75
-- </eucode>
--
-- See Also:
-- [[:cosh]], [[:sin]], [[:arcsinh]]

public function sinh(object a)
    return (exp(a)-exp(-a))/2
end function

--**
-- computes the hyperbolic tangent of an object.
--
-- Parameters:
--		# ##x## : the object to process.
--
-- Returns:
-- An **object**, the same shape as ##x##, each atom of which was acted upon.
--
-- Comments:
--
-- The hyperbolic tangent takes values from -1 to +1.
--
-- ##tanh## is the ratio ##sinh / cosh##. Compare with ordinary trigonometry.
--
-- Example 1:
-- <eucode>
-- ? tanh(LN2) -- prints out 0.6
-- </eucode>
--
-- See Also:
-- [[:cosh]], [[:sinh]], [[:tan]], [[:arctanh]]

public function tanh(object a)
    return sinh(a)/cosh(a)
end function

--**
-- computes the reverse hyperbolic sine of an object.
--
-- Parameters:
--		# ##x## : the object to process.
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
-- ? arcsinh(1) -- prints out 0,4812118250596034
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
-- computes the reverse hyperbolic cosine of an object.
--
-- Parameters:
--		# ##x## : the object to process.
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
-- ? arccosh(1) -- prints out 0
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
-- computes the reverse hyperbolic tangent of an object.
--
-- Parameters:
--		# ##x## : the object to process.
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
-- ? arctanh(1/2) -- prints out 0,5493061443340548456976
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
-- computes the sum of all atoms in the argument, no matter how deeply nested.
--
-- Parameters:
--		# ##values## : an object, all atoms of which will be added up, no matter how nested.
--
-- Returns:
--		An **atom**, the sum of all atoms in [[:flatten]](##values##).
--
-- Comments:
-- This function may be applied to an atom or to all elements of a sequence.
--
-- Example 1:
--   <eucode>
--   a = sum({10, 20, 30})
--   -- a is 60
--
--   a = sum({10.5, {11.2} , 8.1})
--   -- a is 29.8
--   </eucode>
--
-- See Also:
--		[[:product]], [[:or_all]]

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
-- computes the product of all the atom in the argument, no matter how deeply nested.
--
-- Parameters:
--		# ##values## : an object, all atoms of which will be multiplied up, no matter how nested.
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
--		[[:sum]], [[:or_all]]

public function product(object a)
	atom b
	if atom(a) then
		return a
	end if
	b = 1
	for i = 1 to length(a) do
		if atom(a[i]) then
			b *= a[i]
		else
			b *= product(a[i])
		end if
	end for
	return b
end function


--**
-- or's together all atoms in the argument, no matter how deeply nested.
--
-- Parameters:
--		# ##values## : an object, all atoms of which will be added up, no matter how nested.
--
-- Returns:
--		An **atom**, the result of bitwise or of all atoms in [[:flatten]](##values##).
--
-- Comments:
--
-- This function may be applied to an atom or to all elements of a sequence. It performs [[:or_bits]] operations repeatedly.
--
-- Example 1:
--   <eucode>
--   a = or_all({10, 7, 35})
--   -- a is 47 
--   -- To see why notice:
--   -- 10=0b1010, 7=0b111 and 35=0b100011.
--   -- combining these gives:
--   --               0b001010
--   --      (or_bits)0b000111
--   --               0b100011
--   --               --------
--   --               0b101111 = 47
--   </eucode>
--
-- See Also:
--		[[:sum]], [[:product]], [[:or_bits]]

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
-- === Bitwise Operations
--

--****
-- Signature:
-- <built-in> function and_bits(object a, object b)
--
-- Description:
-- performs the bitwise AND operation on corresponding bits in two objects. A bit in the
-- result will be 1 only if the corresponding bits in both arguments are 1.
--
-- Parameters:
-- 		# ##a## : one of the objects involved
-- 		# ##b## : the second object
--
-- Returns:
-- An **object**, whose shape depends on the shape of both arguments. Each atom in this object 
-- is obtained by bitwise AND between atoms on both objects.
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
-- Use the %x format of [[:printf]]. Using [[:int_to_bits]] is an even more direct approach.
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
-- -- but the result of a bitwise operation is interpreted
-- -- as a signed 32-bit number, so it's negative.
-- </eucode>
--
-- See Also:
--  [[:or_bits]], [[:xor_bits]], [[:not_bits]], [[:int_to_bits]]
--

--****
-- Signature:
-- <built-in> function xor_bits(object a, object b)
--
-- Description:
-- performs the bitwise XOR operation on corresponding bits in two objects. A bit in the
-- result will be 1 only if the corresponding bits in both arguments are different.
--
-- Parameters:
-- 		# ##a## : one of the objects involved
-- 		# ##b## : the second object
--
-- Returns:
-- An **object**, whose shape depends on the shape of both arguments. Each atom in this object 
-- is obtained by bitwisel XOR between atoms on both objects.
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

--****
-- Signature:
-- <built-in> function or_bits(object a, object b)
--
-- Description:
-- performs the bitwise OR operation on corresponding bits in two objects. A bit in the
-- result will be 1 only if the corresponding bits in both arguments are both 0.
--
-- Parameters:
-- 		# ##a## : one of the objects involved
-- 		# ##b## : the second object
--
-- Returns:
-- An **object**, whose shape depends on the shape of both arguments. Each atom in this object 
-- is obtained by bitwise OR between atoms on both objects.
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

--****
-- Signature:
-- <built-in> function not_bits(object a)
--
-- Description:
-- performs the bitwise NOT operation on each bit in an object. A bit in the result will be 1
-- when the corresponding bit in x1 is 0, and will be 0 when the corresponding bit in x1 is 1.
--
-- Parameters:
-- 		# ##a## : the object to invert the bits of.
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
-- moves the bits in the input value by the specified distance.
--
-- Parameters:
--   # ##source_number## : object: The value or values whose bits will be be moved.
--   # ##shift_distance## : integer: number of bits to be moved by. 
-- Comments:
-- * If ##source_number## is a sequence, each element is shifted.
-- * The value or values in ##source_number## are first truncated to a 32-bit integer.
-- * The output is truncated to a 32-bit integer.
-- * Vacated bits are replaced with zero.
-- * If ##shift_distance## is negative, the bits in ##source_number## are moved left.
-- * If ##shift_distance## is positive, the bits in ##source_number## are moved right.
-- * If ##shift_distance## is zero, the bits in ##source_number## are not moved.
--
-- Returns:
-- Atom or atoms containing a 32-bit integer. A single atom in ##source_number## is an atom, or
-- a sequence in the same form as ##source_number## containing 32-bit integers.
--
-- Example 1:
-- <eucode>
-- ? shift_bits((7, -3) --> 56
-- ? shift_bits((0, -9) --> 0
-- ? shift_bits((4, -7) --> 512
-- ? shift_bits((8, -4) --> 128
-- ? shift_bits((0xFE427AAC, -7) --> 0x213D5600
-- ? shift_bits((-7, -3) --> -56  which is 0xFFFFFFC8 
-- ? shift_bits((131, 0) --> 131
-- ? shift_bits((184.464, 0) --> 184
-- ? shift_bits((999_999_999_999_999, 0) --> -1530494977 which is 0xA4C67FFF
-- ? shift_bits((184, 3) -- 23
-- ? shift_bits((48, 2) --> 12
-- ? shift_bits((121, 3) --> 15
-- ? shift_bits((0xFE427AAC, 7) -->  0x01FC84F5
-- ? shift_bits((-7, 3) --> 0x1FFFFFFF
-- ? shift_bits({48, 121}, 2) --> {12, 30}
-- </eucode>
--
-- See Also:
--   [[:rotate_bits]]

public function shift_bits(object source_number, integer shift_distance)

	if sequence(source_number) then
		for i = 1 to length(source_number) do
			source_number[i] = shift_bits(source_number[i], shift_distance)
		end for
		return source_number
	end if
	source_number = and_bits(source_number, 0xFFFFFFFF)
	if shift_distance = 0 then
		return source_number
	end if
	
	if shift_distance < 0 then
		source_number *= power(2, -shift_distance)
	else
		integer lSigned = 0
		-- Check for the sign bit so we don't propagate it.
		if and_bits(source_number, 0x80000000) then
			lSigned = 1
			source_number = and_bits(source_number, 0x7FFFFFFF)
		end if
		source_number /= power(2, shift_distance)
		if lSigned and shift_distance < 32 then
			-- Put back the sign bit now shifted
			source_number = or_bits(source_number, power(2, 31-shift_distance))
		end if
	end if
	
	return and_bits(source_number, 0xFFFFFFFF)
end function

--**
-- rotates the bits in the input value by the specified distance.
--
-- Parameters:
--   # ##source_number## : object: value or values whose bits will be be rotated.
--   # ##shift_distance## : integer: number of bits to be moved by. 
-- Comments:
-- * If ##source_number## is a sequence, each element is rotated.
-- * The value(s) in ##source_number## are first truncated to a 32-bit integer.
-- * The output is truncated to a 32-bit integer.
-- * If ##shift_distance## is negative, the bits in ##source_number## are rotated left.
-- * If ##shift_distance## is positive, the bits in ##source_number## are rotated right.
-- * If ##shift_distance## is zero, the bits in ##source_number## are not rotated.
--
-- Returns:
-- Atom or atoms containing a 32-bit integer. A single atom in ##source_number## is an atom, or
-- a sequence in the same form as ##source_number## containing 32-bit integers.
--
-- Example 1:
-- <eucode>
-- ? rotate_bits(7, -3) --> 56
-- ? rotate_bits(0, -9) --> 0
-- ? rotate_bits(4, -7) --> 512
-- ? rotate_bits(8, -4) --> 128
-- ? rotate_bits(0xFE427AAC, -7) --> 0x213D567F
-- ? rotate_bits(-7, -3) --> -49  which is 0xFFFFFFCF 
-- ? rotate_bits(131, 0) --> 131
-- ? rotate_bits(184.464, 0) --> 184
-- ? rotate_bits(999_999_999_999_999, 0) --> -1530494977 which is 0xA4C67FFF
-- ? rotate_bits(184, 3) -- 23
-- ? rotate_bits(48, 2) --> 12
-- ? rotate_bits(121, 3) --> 536870927
-- ? rotate_bits(0xFE427AAC, 7) -->  0x59FC84F5
-- ? rotate_bits(-7, 3) --> 0x3FFFFFFF
-- ? rotate_bits({48, 121}, 2) --> {12, 1073741854}
-- </eucode>
--
-- See Also:
--   [[:shift_bits]]

public function rotate_bits(object source_number, integer shift_distance)
	atom lTemp
	atom lSave
	integer lRest
	
	if sequence(source_number) then
		for i = 1 to length(source_number) do
			source_number[i] = rotate_bits(source_number[i], shift_distance)
		end for
		return source_number
	end if
	
	source_number = and_bits(source_number, 0xFFFFFFFF)
	if shift_distance = 0 then
		return source_number
	end if

	if shift_distance < 0 then
		lSave = not_bits(power(2, 32 + shift_distance) - 1) 	
		lRest = 32 + shift_distance
	else
		lSave = power(2, shift_distance) - 1
		lRest = shift_distance - 32
	end if
	
	lTemp = shift_bits(and_bits(source_number, lSave), lRest)
	source_number = shift_bits(source_number, shift_distance)
	return or_bits(source_number, lTemp)
end function

--****
-- Arithmetic
--

--**
-- returns the greater common divisor of to atoms.
--
-- Parameters:
--		# ##p## : one of the atoms to consider
--		# ##q## : the other atom.
--
-- Returns:
-- A positive **integer**, which is the largest value that evenly divides
-- into both parameters.
--
-- Comments:
--
-- * Signs are ignored. Atoms are rounded down to integers.
-- * If both parameters are zero, 0 is returned.
-- * If one parameter is zero, the other parameter is returned.
--
-- Parameters and return value are atoms so as to take mathematical integers up to ##power(2,53)##.
--
-- Example 1:
-- <eucode>
-- ? gcd(76.3, -114) --> 38
-- ? gcd(0, -114) --> 114
-- ? gcd(0, 0) --> 0 (This is often regarded as an error condition)
-- </eucode>
--

public function gcd(atom p, atom q)
	atom r

	-- Both arguments must be positive.	
	if p < 0 then
		p = -p
	end if
	if q < 0 then
		q = -q
	end if
	
	-- Strip off any fractional part.
	p = floor(p)
	q = floor(q)
	
	-- Ensure that 'p' is not smaller than 'q'
	if p < q then
		r = p
		p = q
		q = r
	end if
	
	-- Special case.
	if q = 0 then
		return p
	end if

	-- repeat until I get a remainder less than 2.
    while r > 1 with entry do
    	-- set up next cycle using denominator and remainder from previous cycle.
		p = q
		q = r
	entry
		-- get remainder after dividing p by q
		r = remainder(p, q)
    end while
    
	if r = 1 then
		return 1
	else
		return q
	end if
end function


--****
-- Floating Point
--

--**
-- compares two (sets of) numbers based on approximate equality.
--
-- Parameters:
--		# ##p## : an object, one of the sets to consider
--		# ##q## : an object, the other set.
--      # ##epsilon## : an atom used to define the amount of inequality allowed.
--           This must be a positive value. Default is 0.005
--
-- Returns:
-- An **integer**,
-- * 1 when p > (q + epsilon) : P is definitely greater than q.
-- * -1 when p < (q - epsilon) : P is definitely less than q.
-- * 0 when p >= (q - epsilon) and p <= (q + epsilon) : p and q are approximately equal.
--
-- Comments:
-- This can be used to see if two numbers are near enough to each other.
--
-- Also, because of the way floating point numbers are stored, it not always possible
-- express every real number exactly, especially after a series of arithmetic
-- operations. You can use ##approx## to see if two floating point numbers
-- are almost the same value.
--
-- If ##p## and ##q## are both sequences, they must be the same length as each other.
--
-- If ##p## or ##q## is a sequence, but the other is not, then the result is a 
-- sequence of results whose length is the same as the sequence argument.
--
-- Example 1:
-- <eucode>
-- ? approx(10, 33.33 * 30.01 / 100) 
--           --> 0 because 10 and 10.002333 are within 0.005 of each other
-- ? approx(10, 10.001) 
--           --> 0 because 10 and 10.001 are within 0.005 of each other
-- ? approx(10, {10.001,9.999, 9.98, 10.04}) 
--           --> {0,0,1,-1}
-- ? approx({10.001,9.999, 9.98, 10.04}, 10) 
--           --> {0,0,-1,1}
-- ? approx({10.001,{9.999, 10.01}, 9.98, 10.04}, {10.01,9.99, 9.8, 10.4}) 
--           --> {-1,{1,1},1,-1}
-- ? approx(23,32, 10) 
--           --> 0 because 23 and 32 are within 10 of each other.
-- </eucode>
--
public function approx(object p, object q, atom epsilon = 0.005)

	if sequence(p) then
		if sequence(q) then
			if length(p) != length(q) then
				error:crash("approx(): Sequence arguments must be the same length")
			end if
			for i = 1 to length(p) do
				p[i] = approx(p[i], q[i])
			end for
			return p
		else
			for i = 1 to length(p) do
				p[i] = approx(p[i], q)
			end for
			return p
		end if
	elsif sequence(q) then
			for i = 1 to length(q) do
				q[i] = approx(p, q[i])
			end for
			return q
	else
		if p > (q + epsilon) then
			return 1
		end if
		
		if p < (q - epsilon) then
			return -1
		end if
	
		return 0
	end if
end function

--**
-- tests for power of 2.
--
-- Parameters:
--		# ##p## : an object. The item to test. This can be an integer, atom or sequence.
--
-- Returns:
-- An **integer**,
-- * 1 for each item in ##p## that is a power of two (like ## 2,4,8,16,32, ...##)
-- * 0 for each item in ##p## that is **not** a power of two (like ##3, 54.322, -2##)
--
-- Example 1:
-- <eucode>
-- for i = 1 to 10 do
--   ? {i, powof2(i)}
-- end for
-- -- output ... 
-- -- {1,1}
-- -- {2,1}
-- -- {3,0}
-- -- {4,1}
-- -- {5,0}
-- -- {6,0}
-- -- {7,0}
-- -- {8,1}
-- -- {9,0}
-- -- {10,0}
-- </eucode>
--

public function powof2(object p)
	return not (and_bits(p, p-1))
end function


--**
-- tests if the supplied integer is a even or odd number.
--
-- Parameters:
--		# ##test_integer## : an integer. The item to test.
--
-- Returns:
-- An **integer**,
-- * 1 if its even.
-- * 0 if its odd.
--
-- Example 1:
-- <eucode>
-- for i = 1 to 10 do
--   ? {i, is_even(i)}
-- end for
-- -- output ... 
-- -- {1,0}
-- -- {2,1}
-- -- {3,0}
-- -- {4,1}
-- -- {5,0}
-- -- {6,1}
-- -- {7,0}
-- -- {8,1}
-- -- {9,0}
-- -- {10,1}
-- </eucode>
--
public function is_even(integer test_integer)
	return (and_bits(test_integer, 1) = 0)
end function

--**
-- tests if the supplied Euphoria object is even or odd.
--
-- Parameters:
--		# ##test_object## : any Euphoria object. The item to test.
--
-- Returns:
-- An **object**,
-- * If ##test_object## is an integer...
-- ** 1 if its even.
-- ** 0 if its odd.
-- * Otherwise if ##test_object## is an atom this always returns 0
-- * otherwise if ##test_object## is an sequence it tests each element recursively, returning a
-- sequence of the same structure containing ones and zeros for each element. A
-- 1 means that the element at this position was even otherwise it was odd.
--
-- Example 1:
-- <eucode>
-- for i = 1 to 5 do
--   ? {i, is_even_obj(i)}
-- end for
-- -- output ... 
-- -- {1,0}
-- -- {2,1}
-- -- {3,0}
-- -- {4,1}
-- -- {5,0}
-- </eucode>
--
-- Example 2:
-- <eucode>
-- ? is_even_obj(3.4) --> 0 
-- </eucode>
--
-- Example 3:
-- <eucode>
-- ? is_even_obj({{1,2,3}, {{4,5},6,{7,8}},9}) --> {{0,1,0},{{1,0},1,{0,1}},0}
-- </eucode>
--
public function is_even_obj(object test_object)
	if atom(test_object) then
		if integer(test_object) then
			return (and_bits(test_object, 1) = 0)
		end if
		return 0
	end if
	for i = 1 to length(test_object) do
		test_object[i] = is_even_obj(test_object[i])
	end for
	
	return test_object
end function

