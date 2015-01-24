-- (c) Copyright - See License.txt

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include std/convert.e
include fenv.e as fenv
include std/math.e
include std/error.e

--/topic Introduction
--/info
--
--scientific.e was written by Matt Lewis (matthewwalkerlewis@gmail.com)
--
--It's purpose is to parse numbers in scientific notation to the maximum
--precision allowed by the IEEE 754 floating point standard.
--
--
--LICENSE AND DISCLAIMER
--/code
--The MIT License
--
--Copyright (c) 2007 Matt Lewis
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this 
-- software and associated documentation files (the "Software"), to deal in the Software 
-- without restriction, including without limitation the rights to use, copy, modify, merge,
--publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
-- to whom the Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies or 
-- substantial portions of the Software.
--/endcode
--/code
--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
--INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
--PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
--FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
--OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
--DEALINGS IN THE SOFTWARE.
--/endcode

--/topic Scientific Notation
--/info
--Parsing routines
--The parsing functions require a sequence containing a correctly formed scientific notation
--representation of a number.  The general pattern is an optional negative sign (-), a number, 
--usually with a decimal point, followed by an upper case or lower case 'e', then optionally 
--a plus (+) or a minus (-) sign, and an integer.  There should be no spaces or other characters.  
--The following are valid numbers:
--/code
--      1e0
--      3.1415e-2
--      -9.0E+3
--/endcode
--This library evaluates scientific notation to the highest level of precision possible using
--Euphoria atoms.  An atom can have up to 16 digits of precision.  A number represented by
--scientific notation could contain up to 17 digits.  The 17th supplied digit may have an
--effect upon the value of the atom due to rounding errors in the calculations.  
--
--This doesn't mean that if the 17th digit is 5 or higher, you should include it.  The 
--calculations are much more complicated, because a decimal fraction has to be converted to a 
--binary fraction, and there's not really a one-to-one correspondence between the decimal 
--digits and the bits in the resulting atom.  The 18th or higher digit, however, will never 
--have an effect on the resulting atom.
--
--The biggest and smallest (magnitude) atoms possible are: 
--/code
--    1.7976931348623157e+308
--    4.9406564584124654e-324 
--/endcode

--/topic Low level
--/info
--Helper routines
--

-- taken from misc.e to avoid including
function reverse(sequence s)
-- reverse the top-level elements of a sequence.
-- Thanks to Hawke' for helping to make this run faster.
	integer lower, n, n2
	sequence t
	
	n = length(s)
	n2 = floor(n/2)+1
	t = repeat(0, n)
	lower = 1
	for upper = n to n2 by -1 do
		t[upper] = s[lower]
		t[lower] = s[upper]
		lower += 1
	end for
	return t
end function


function carry( sequence a, integer radix )
		atom q, r, b, rmax, i
		rmax = radix - 1
		i = 1
		while i <= length(a) do
				b = a[i]
				if b > rmax then
						q = floor( b / radix )
						r = remainder( b, radix )
						a[i] = r
						if i = length(a) then
								a &= 0
						end if
						a[i+1] += q
				end if
				i += 1
		end while
		
		return a
end function

function add( sequence a, sequence b )
		
		if length(a) < length(b) then
				a &= repeat( 0, length(b) - length(a) )
		elsif length(b) < length(a) then
				b &= repeat( 0, length(a) - length(b) )
		end if
		
		return a + b
		
end function

function borrow( sequence a, integer radix )
		for i = length(a) to 2 by -1 do
				if a[i] < 0 then
						a[i] += radix
						a[i-1] -= 1
				end if
		end for
		return a
end function

--/topic Low level
--/func bits_to_bytes( sequence bits )
--
--Takes a sequence of bits (all elements either 0 or 1) and converts it
--into a sequence of bytes.
export function bits_to_bytes( sequence bits )
		sequence bytes
		integer r
		r = remainder( length(bits), 8 )
		if r  then
				bits &= repeat( 0, 8 - r )
		end if
		
		bytes = {}
		for i = 1 to length(bits) by 8 do
				bytes &= bits_to_int( bits[i..i+7] )
		end for
		return bytes
end function

--/topic Low level
--/func bytes_to_bits( sequence bytes )
--
--Converts a sequence of bytes (all elements integers between 0 and 255) and
--converts it into a sequence of bits.
export function bytes_to_bits( sequence bytes )
		sequence bits
		bits = {}
		for i = 1 to length(bytes) do
				bits &= int_to_bits( bytes[i], 8 )
		end for
		
		return bits
end function

function convert_radix( sequence number, integer from_radix, integer to_radix )
		sequence target, base
		
		base = {1}
		target = {0}
		for i = 1 to length(number) do
				target = carry( add( base * number[i], target ), to_radix )
				base *= from_radix
				base = carry( base, to_radix )
		end for
		
		return target
end function

function half( sequence decimal )
		sequence quotient
		atom q, Q
		
		quotient = repeat( 0, length(decimal) )
		for i = 1 to length( decimal ) do
				q = decimal[i] / 2
				Q = floor( q )
				quotient[i] +=  Q
				
				if q != Q then
						if length(quotient) = i then
								quotient &= 0
						end if
						quotient[i+1] += 5
				end if
		end for
		return reverse( carry( reverse( quotient ), 10 ) )
end function

function first_non_zero( sequence s )
		for i = 1 to length(s) do
				if  s[i] then
						return i
				end if
		end for
		return 0
end function

function decimals_to_bits( sequence decimals )
		sequence sub, bits
		integer bit, assigned
		sub = {5}
		bits = repeat( 0, 53 )
		bit = 1
		assigned = 0

		-- Check for the simple case of zero. It must be guaranteed that no element of decimals
		-- is itself negative when this function is called and that its length is less than 54.
		if compare(decimals, bits) > 0 then 

			while (not assigned) or (bit < find( 1, bits ) + 54)  do
				if compare( sub, decimals ) <= 0 then
						assigned = 1
						if length( bits ) < bit then
								bits &= repeat( 0, bit - length(bits)) 
						end if
						
						bits[bit] += 1
						decimals = borrow( add( decimals, -sub ), 10 )
				end if
				sub = half( sub )
				
				bit += 1
			end while

		end if	
		return reverse(bits)
end function

function string_to_int( sequence s )
		integer int
		int = 0
		for i = 1 to length(s) do
				int *= 10
				int += s[i] - '0'
		end for
		return int
end function

function trim_bits( sequence bits )
		while length(bits) and not bits[$] do
				bits = bits[1..$-1]
		end while
		return bits
end function

type ebits_t(sequence s)
	return length(s) = 11
end type

type sbits_t(sequence s)
	return length(s) = 1
end type

--/topic Scientific Notation
--/func scientific_to_float64( sequence s )
--
--Takes a string reprepresentation of a number in scientific notation and
--returns a sequence of bytes in the raw format of an IEEE 754 double 
--precision floating point number.  This value can be passed to the euphoria
--library function, float64_to_atom().
--raises FE_OVERFLOW on overflow.
--raises FE_UNDERFLOW on underflow.
export function scientific_to_float64( sequence s )
		integer dp, e, exp, almost_nothing, carried
		sequence int_bits, frac_bits
		sequence mbits
		ebits_t ebits
		sbits_t sbits
		
		-- if true, this number might evaluate to zero although the user wrote a non-zero matissa
		almost_nothing = 0
		-- if true, the mbits has overflowed and we need to adjust exp
		carried = 0
				
		-- Determine if negative or positive
		if s[1] = '-' then
				sbits = {1}
				s = s[2..$]
		else
				sbits = {0}
				if s[1] = '+' then
						s = s[2..$]
				end if
		end if
		
		-- In order to correctly judge the size we must get rid of the extra left hand side zeros
		while length(s) and s[1] = '0' do
			s = s[2..$]
		end while
		
		
		-- find the decimal point (if exists) and the exponent
		dp = find('.', s)		
		e = find( 'e', s )
		if not e then
				e = find('E', s )
		end if
		
		-- calculate the exponent
		exp = 0
		if s[e+1] = '-' then
				exp -= string_to_int( s[e+2..$] )
		else

				if s[e+1] = '+' then
						exp += string_to_int( s[e+2..$] )
				else
						exp += string_to_int( s[e+1..$] )
				end if
		end if
		
		if dp then
				-- remove the decimal point
				s = s[1..dp-1] & s[dp+1..$]
				e -= 1
				
				-- Adjust the exponent, because we moved the decimal point:
				exp -= e - dp
		end if
		
		-- We split the integral and fractional parts, because they have to be
		-- calculated differently.
		s = s[1..e-1] - '0'
		
		while length(s) and s[1] = 0 do
			s = s[2..$]
			e -= 1
			dp -= 1
		end while
		
		-- If LHS only consists of zeros, then return zero.
		if not find(0, s = 0) then
			return atom_to_float64(0)
		end if
		
		if exp + length(s) - 1 > 308 then
			-- make inf or -inf
			exp = 1024
			mbits = repeat(0, 52)
		elsif exp + length(s) - 1 < -324 then -- -324 = floor((-1022-52)*log(2)/log(10))
			-- make 0
			fenv:raise(FE_UNDERFLOW)
			exp = -1023
			mbits = repeat(0, 52)
		else
			if exp >= 0 then
					-- We have a large exponent, so it's all integral.  Pad it to account for 
					-- the positive exponent.
					int_bits = trim_bits( bytes_to_bits( convert_radix( repeat( 0, exp ) & reverse( s ), 10, #100 ) ) )
					frac_bits = {}
			else
					almost_nothing = exp + e - dp = -324
					if -exp > length(s) then
							-- all fractional
							int_bits = {}
							frac_bits = decimals_to_bits( repeat( 0, -exp-length(s) ) & s )
					
					else
							-- some int, some frac
							int_bits = trim_bits( bytes_to_bits( convert_radix( reverse( s[1..$+exp] ), 10, #100 ) ) )
							frac_bits =  decimals_to_bits( s[$+exp+1..$] )
					end if
			end if
			
			
			if length(int_bits) >= 53 then
				-- Can disregard the fractional component, because the integral 
				-- component takes up all of the precision for which we have room.
				mbits = int_bits[$-52..$-1]
				if length(int_bits) > 53 and int_bits[$-53] then
						-- If the first bit that missed the precision is '1', then round up
						mbits[1] += 1
						mbits = carry( mbits, 2 )
						if length(mbits) = 53 then
							-- this only happens if mbits is now: { 0, 0, ..., 0, 0, 1 }
							-- and is heavy one because it was    { 1, 1, ....,1, 1 }
							--    1.000000000000 (implicit 1)
							-- +  0.111111111111 (mbits before)
							--    0.000000000001 (value to round off the number)
							--    --------------
							--   10.000000000000 (implicit 1)
							--    0.000000000000 (new mbits)
							-- mbits should be 52 zeroes and it so 
							-- happens mbits[1..$-1] is just that.
							mbits = mbits[1..$-1]
							-- set carried flag so we increment exp later.
							carried = 1
						end if
				end if
				exp = length(int_bits)-1
			else
					if length(int_bits) then
							-- both fractional and integral
							exp = length(int_bits)-1
							
					else
							-- fractional only
							exp = - find( 1, reverse( frac_bits ) )
							if exp < -1023 then
									-- -1023 is the smallest exponent possible, so we may have to lose
									-- some precision.
									exp = -1023
							end if
							
							if exp then
									-- Truncate it based on the exponent.
									frac_bits = frac_bits[1..$+exp+1]
							end if
							
					end if
					
					-- Now we combine the integral and fracional parts, and pad them
					-- just to make the slice easier.
					mbits = frac_bits & int_bits
					mbits = repeat( 0, 53 ) & mbits
					
					if exp > -1023 then
							-- normalized
							if mbits[$-53] then
									-- If the first bit that missed the precision is '1', then round up
									mbits[$-52] += 1
									integer mbits_len = length(mbits)
									mbits = carry( mbits, 2 )
									if length(mbits) = mbits_len + 1 then
										carried = 1
									end if
							end if
							mbits = mbits[$-52..$-1]
					else
							-- denormalized
							if mbits[$-52] then
									-- If the first bit that missed the precision is '1', then round up
									mbits[$-52] += 1
									integer mbits_len = length(mbits)
									mbits = carry( mbits, 2 )
									if length(mbits) = mbits_len + 1 then
										carried = 1
									end if
							end if
							mbits = mbits[$-51..$]
					end if
					
			end if
			
			-- this handles denormalized.
			exp += carried
		end if
		
		if exp >= 1024 then
			-- we have exceeded exp's legal values for real numbers
			-- meaning that we cannot represent this number being parsed
			-- set to inf or -inf and raise an overflow floating point exception.
			-- This value is a special value for infinity.
			exp   = 1024
			mbits = repeat(0, 52)
			fenv:raise(fenv:FE_OVERFLOW)
		end if
		
		-- Add the IEEE 784 specified exponent bias and turn it into bits
		ebits = int_to_bits( exp + 1023, 11 )
		
		if almost_nothing and not find(1, mbits & ebits) then
			-- the user wrote a non-zero value but in the end it is evaluated as 0.
			-- ebits is only all 0, in the subnormal or 0 cases
			-- mbits is only all 0, in the case of 0.
			-- but the case of 0 is handled about 120 lines above, so this 
			-- non-zero number when parsed turns out to be too small for EUPHORIA.
			fenv:raise(fenv:FE_UNDERFLOW)
		end if
		
		-- Combine everything and convert to bytes (float64)
		return bits_to_bytes( mbits & ebits & sbits )
end function

--/topic Scientific Notation
--/func scientific_to_atom( sequence s )
--
--Takes a string reprepresentation of a number in scientific notation and returns
--an atom.
export function scientific_to_atom( sequence s )
		return float64_to_atom( scientific_to_float64( s ) )
end function



