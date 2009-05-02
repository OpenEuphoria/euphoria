-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Math Constants
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
	E = 2.7182818284590452353602874


--**
-- PI
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
	PI        = 3.141592653589793238462643

public constant
	--** Quarter of PI
	QUARTPI   = 0.78539816339744830962,
	--** Half of PI
	HALFPI    = 1.57079632679489661923,
	--** Two times PI
	TWOPI     = 6.28318530717958647692

public constant
	LN2       = 0.69314718055994530941,
	INVLN2    = 1 / LN2,
	LN10      = 2.30258509299404568401,
	INVLN10   = 1 / LN10,
	SQRT2     = 1.41421356237309504880,
	HALFSQRT2 = 0.70710678118654752440,
	DEGREES_TO_RADIANS  = 0.01745329251994329576,
	RADIANS_TO_DEGREES   = 1/DEGREES_TO_RADIANS,
	EULER_GAMMA  = machine_func(47,{25,182,111,252,140,120,226,63}),
	EULER_NORMAL = machine_func(47,{81,54,212,51,69,136,217,63})


public constant
	PINF     = 1E308 * 1000,       -- Plus infinity (used in several routines)
	MINF     = - PINF             -- Minus infinity (used in several routines)
