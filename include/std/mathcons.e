--****
-- == Math Constants
--
-- <<LEVELTOC level=2 depth=4>>
--

namespace mathcons

constant M_INFINITY = 102

--****
-- === Constants
--

public constant
	--** 
	-- PI is the ratio of a circle's circumference to it's diameter.
	--
	-- PI = C / D  :: C = PI * D :: C = PI * 2 * R(radius)
	PI        = 3.14159_26535_89793_23846,
	--**
	-- Quarter of PI
	QUARTPI   = 0.78539_81633_97448_30962,
	--**
	-- Half of PI
	HALFPI    = 1.57079_63267_94896_61923,
	--**
	-- Two times PI
	TWOPI     = 6.28318_53071_79586_47692,
	--**
	-- PI ^ 2
	PISQR     = 9.86960_44010_89358_61883,
	--**
	-- 1 / (sqrt(2PI))
	INVSQ2PI  = 0.39894_22804_01433_67794,
	--**
	-- phi  => Golden Ratio = (1 + sqrt(5)) / 2
	PHI       = 1.61803_39887_49894_84820,
	--** Euler (e)
	-- The base of the natural logarithm.
	E            = 2.71828_18284_59045_23536,
	--**
	-- ln(2) :: 2 = power(E, LN2)
	LN2       = 0.69314_71805_59945_30941,
	--**
	-- 1 / (ln(2))
	INVLN2    = 1.44269_50408_88963_40736,
	--**
	-- ln(10) :: 10 = power(E, LN10)
	LN10      = 2.30258_50929_94045_68401,
	--**
	-- 1 / ln(10)
	INVLN10   = 0.43429_44819_03251_82765,
	--**
	-- sqrt(2)
	SQRT2     = 1.41421_35623_73095_04880,
	--**
	-- sqrt(2)/ 2
	HALFSQRT2 = 0.70710_67811_86547_52440,
	--**
	-- Square root of 3
	SQRT3     = 1.73205_08075_68877_29353,
	--**
	-- Conversion factor: Degrees to Radians = PI / 180
	DEGREES_TO_RADIANS  = 0.01745_32925_19943_29576,
	--**
	-- Conversion factor: Radians to Degrees = 180 / PI
	RADIANS_TO_DEGREES   = 57.29577_95130_82320_90712,
	--**
	-- Gamma (Euler Gamma)	
	EULER_GAMMA  = 0.57721_56649_01532_86061,
	--**
	-- sqrt(e)
	SQRTE        = 1.64872_12707_00128_14684,
	$
	
ifdef EU4_0 then
	public constant
		--**
		-- Positive Infinity
		PINF     = 1E308 * 1000
elsedef
	public constant
		--**
		-- Positive Infinity
		PINF     = machine_func( M_INFINITY, {})
end ifdef

public constant
		--**
		-- Negative Infinity
		MINF     = - PINF,
		--**
		-- sqrt(5)
		SQRT5 = 2.23606_79774_99789_69641

