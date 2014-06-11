-- (c) Copyright - See License.txt
ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include std/convert.e
include std/dll.e

--****
-- == Scientific Notation Parsing
--
-- <<LEVELTOC level=2 depth=4>>
--
-- === Parsing routines
-- The parsing functions require a sequence containing a correctly formed scientific notation
-- representation of a number.  The general pattern is an optional negative sign (-), a number, 
-- usually with a decimal point, followed by an upper case or lower case 'e', then optionally 
-- a plus (+) or a minus (-) sign, and an integer.  There should be no spaces or other characters.  
-- The following are valid numbers~:
-- {{{
-- 1e0
-- 3.1415e-2
-- -9.0E+3
-- }}}
-- This library evaluates scientific notation to the highest level of precision possible using
-- Euphoria atoms.  An atom in 32-bit euphoria can have up to 16 digits of precision 
-- (19 in 64-bit euphoria).  A number represented by scientific notation could contain up to 17 
-- (or 20) digits.  The 17th (or 20th) supplied digit may have an effect upon the value of the 
-- atom due to rounding errors in the calculations.  
-- 
-- This does not mean that if the 17th (or 20th) digit is 5 or higher, you should include it.  The 
-- calculations are much more complicated, because a decimal fraction has to be converted to a 
-- binary fraction, and there is not really a one-to-one correspondence between the decimal 
-- digits and the bits in the resulting atom.  The 18th or higher digit, however, will never 
-- have an effect on the resulting atom.
-- 
-- The biggest and smallest (magnitude) atoms possible are~: 
-- {{{
-- 32-bit:
--    1.7976931348623157e+308
--    4.9406564584124654e-324 
-- }}}


--****
-- === Floating Point Types

public enum type floating_point
--**
-- NATIVE
-- Description:
-- Use whatever is the appropriate format based upon the version of
-- euphoria being used (DOUBLE for 32-bit, EXTENDED for 64-bit)
	NATIVE,
--**
-- DOUBLE:
-- Description
-- IEEE 754 double (64-bit) floating point format.
-- The native 32-bit euphoria floating point representation.
	DOUBLE,
--** EXTENDED: 80-bit floating point format.
-- The native 64-bit euphoria floating point reprepresentation.
	EXTENDED
end type

integer NATIVE_FORMAT

ifdef EU4_0 then
	NATIVE_FORMAT = DOUBLE
elsedef
	if sizeof( C_POINTER ) = 4 then
		NATIVE_FORMAT = DOUBLE
	else
		NATIVE_FORMAT = EXTENDED
	end if
end ifdef

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

--**
-- Description:
-- Takes a sequence of bits (all elements either 0 or 1) and converts it
-- into a sequence of bytes.
--
-- Parameters:
--  # ##bits## : sequence of ones and zeroes
--
-- Returns a sequence of 8-bit integers
public function bits_to_bytes( sequence bits )
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

--**
-- Description:
-- Converts a sequence of bytes (all elements integers between 0 and 255) and
-- converts it into a sequence of bits.
--
-- Parameters:
--  # ##bytes## : sequence of values from 0-255
--
-- Returns:
--	Sequence of bits (ones and zeroes)
public  function bytes_to_bits( sequence bytes )
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

function decimals_to_bits( sequence decimals, integer size )
	sequence sub, bits
	integer bit, assigned
	sub = {5}
	bits = repeat( 0, size )
	bit = 1
	assigned = 0

	-- Check for the simple case of zero. It must be guaranteed that no element of decimals
	-- is itself negative when this function is called and that its length is less than size+2.
	if compare(decimals, bits) > 0 then 

		while (not assigned) or (bit < find( 1, bits ) + size + 1)  do
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
			bits = remove( bits, length( bits ) )
		end while
		return bits
end function

constant
	DOUBLE_SIGNIFICAND   =    52,
	DOUBLE_EXPONENT      =    11,
	DOUBLE_MIN_EXP       = -1023,
	DOUBLE_EXP_BIAS      =  1023,
	
	EXTENDED_SIGNIFICAND =     64,
	EXTENDED_EXPONENT    =     15,
	EXTENDED_MIN_EXP     = -16383,
	EXTENDED_EXP_BIAS    =  16383,
	$


--**
-- Description:
-- Takes a string reprepresentation of a number in scientific notation and
-- the requested precision (DOUBLE or EXTENDED) and returns a sequence of 
-- bytes in the raw format of an IEEE 754 double or extended
-- precision floating point number.  This value can be passed to the euphoria
-- library function, ##[[:float64_to_atom]]## or ##[[:float80_to_atom]]##, respectively.
--
-- Parameters:
--	# ##s## : string representation of a number, e.g., "1.23E4"
--	# ##fp## : the required precision for the ultimate representation
--	## ##DOUBLE## Use IEEE 754, the euphoria representation used in 32-bit euphoria
--	## ##EXTENDED## Use Extended Floating Point, the euphoria representation in 64-bit euphoria
--
-- Returns:
-- Sequence of bytes that represents the physical form of the converted floating point number.
--
-- Note: 
-- Does not check if the string exceeds IEEE 754 double precision limits.
--
public  function scientific_to_float( sequence s, floating_point fp = NATIVE )
	integer dp, e, exp
	sequence int_bits, frac_bits, mbits, ebits, sbits
	
	integer significand, exponent, min_exp, exp_bias
	if fp = NATIVE then
		fp = NATIVE_FORMAT
	end if
	if fp = DOUBLE then
		significand = DOUBLE_SIGNIFICAND
		exponent    = DOUBLE_EXPONENT
		min_exp     = DOUBLE_MIN_EXP
		exp_bias    = DOUBLE_EXP_BIAS
		
	elsif fp = EXTENDED then
		significand = EXTENDED_SIGNIFICAND
		exponent    = EXTENDED_EXPONENT
		min_exp     = EXTENDED_MIN_EXP
		exp_bias    = EXTENDED_EXP_BIAS
	end if
	
	-- Determine if negative or positive
	if s[1] = '-' then
		sbits = {1}
		s = remove( s, 1 )
	else
		sbits = {0}
		if s[1] = '+' then
			s = remove( s, 1 )
		end if
	end if
	
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
		s = remove( s, dp )
		e -= 1
		
		-- Adjust the exponent, because we moved the decimal point:
		exp -= e - dp
	end if
	
	-- We split the integral and fractional parts, because they have to be
	-- calculated differently.
	s = s[1..e-1] - '0'
	
	-- If LHS only consists of zeros, then return zero.
	if not find(0, s = 0) then
		if fp = DOUBLE then
			return atom_to_float64(0)
		elsif fp = EXTENDED then
			return atom_to_float80(0)
		end if
	end if
	
	if exp >= 0 then
		-- We have a large exponent, so it's all integral.  Pad it to account for 
		-- the positive exponent.
		int_bits = trim_bits( bytes_to_bits( convert_radix( repeat( 0, exp ) & reverse( s ), 10, #100 ) ) )
		frac_bits = {}
	else
		if -exp > length(s) then
			-- all fractional
			int_bits = {}
			frac_bits = decimals_to_bits( repeat( 0, -exp-length(s) ) & s, significand ) 
		
		else
			-- some int, some frac
			int_bits = trim_bits( bytes_to_bits( convert_radix( reverse( s[1..$+exp] ), 10, #100 ) ) )
			frac_bits =  decimals_to_bits( s[$+exp+1..$], significand )
		end if
	end if
	
	if length(int_bits) > significand then
		-- Can disregard the fractional component, because the integral 
		-- component takes up all of the precision for which we have room.
		if fp = DOUBLE then
			-- the first 1 is implicit in a double
			mbits = int_bits[$-significand..$-1]
		else
			-- EXTENDED precision floats don't have an implicit bit
			mbits = int_bits[$-significand+1..$]
		end if
		
		if length(int_bits) > significand + 1 and int_bits[$-(significand+1)] then
			-- If the first bit that missed the precision is '1', then round up
			mbits[1] += 1
			mbits = carry( mbits, 2 )
		end if
		exp = length(int_bits)-1
			
	else
		if length(int_bits) then
			-- both fractional and integral
			exp = length(int_bits)-1
			
		else
			-- fractional only
			exp = - find( 1, reverse( frac_bits ) )
			if exp < min_exp then
				-- min_exp is the smallest exponent possible, so we may have to lose
				-- some precision.
				exp = min_exp
			end if
			
			if exp then
				-- Truncate it based on the exponent.\
				frac_bits = remove( frac_bits, length(frac_bits) + exp + 2, length( frac_bits ) )
			end if
			
		end if
		
		-- Now we combine the integral and fracional parts, and pad them
		-- just to make the slice easier.
		mbits = frac_bits & int_bits
		mbits = repeat( 0, significand + 1 ) & mbits
			
		if exp > min_exp then
			-- normalized
			if mbits[$-(significand+1)] then
				-- If the first bit that missed the precision is '1', then round up
				mbits[$-significand] += 1
				mbits = carry( mbits, 2 )
			end if
			if fp = DOUBLE then
				-- the first 1 is implicit in a double
				mbits = mbits[$-significand..$-1]
			else
				-- EXTENDED precision floats don't have an implicit bit
				mbits = remove( mbits, 1, length(mbits) - significand )
			end if
		else
			-- denormalized
			if mbits[$-significand] then
				-- If the first bit that missed the precision is '1', then round up
				mbits[$-significand] += 1
				mbits = carry( mbits, 2 )
			end if
			mbits = remove( mbits, 1, length(mbits) - significand )
		end if
			
	end if
	
	-- Add the IEEE 784 specified exponent bias and turn it into bits
	ebits = int_to_bits( exp + exp_bias, exponent )
	
	-- Combine everything and convert to bytes (float64)
	return bits_to_bytes( mbits & ebits & sbits )
end function

--**
-- Description:
-- Takes a string reprepresentation of a number in scientific notation and returns
-- an atom.
--
-- Parameters:
--	# ##s## : string representation of a number (such as "1.23E4" ).
--	# ##fp## : the required precision for the ultimate representation.
--	## ##DOUBLE## Use IEEE 754, the euphoria representation used in 32-bit Euphoria.
--	## ##EXTENDED## Use Extended Floating Point, the euphoria representation in 64-bit Euphoria.
-- 
-- Returns:
-- Euphoria atom floating point number.

public  function scientific_to_atom( sequence s, floating_point fp = NATIVE )
	if fp = NATIVE then
		fp = NATIVE_FORMAT
	end if
	sequence float = scientific_to_float( s, fp )
	if fp = DOUBLE then
		return float64_to_atom( float )
	elsif fp = EXTENDED then
		return float80_to_atom( float )
	end if
end function



