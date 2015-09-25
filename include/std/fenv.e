include std/dll.e
include std/utils.e

-- true if running wine
constant wine = not equal(getenv("WINELOADERNOEXEC"),-1)
constant libm = iff(wine, 0, open_dll({"libm.so", "mscrv120.dll"}))
constant feclearexcept = iff(wine, -1, define_c_func(libm, "feclearexcept", {C_INT}, C_INT))
constant feraiseexcept = iff(wine, -1, define_c_func(libm, "feraiseexcept", {C_INT}, C_INT))
constant fetestexcept = iff(wine, -1, define_c_func(libm, "fetestexcept", {C_INT}, C_INT))

public type fexcept_t(object s)
    if atom(s) then
    	return 0
    end if
    for i = 1 to length(s) do
    	integer ef = s[i]
    	if find(ef, "uozev") = 0 then
    		return 0
    	end if
    end for
    return 1
end type

public constant FE_INEXACT = 'e',
	 FE_DIVBYZERO = 'z',
	 FE_UNDERFLOW = 'u',
	 FE_OVERFLOW  = 'o',
	 FE_INVALID   = 'i',
	 FE_ALL_EXCEPT = "eiouz"

ifdef ARM then
        type enum c_fe by *2
                C_FE_INVALID = 1,
                C_FE_DIVBYZERO = 2,
                C_FE_OVERFLOW = 4,
                C_FE_UNDERFLOW = 8,
                C_FE_INEXACT= 16
        end type
elsedef
        type enum c_fe by *2
                C_FE_INVALID,
                C_FE_DIVBYZERO = 4,
                C_FE_OVERFLOW,
                C_FE_UNDERFLOW,
                C_FE_INEXACT
        end type
end ifdef

sequence conv_table = repeat(0, 'z')
conv_table[FE_INEXACT] = C_FE_INEXACT
conv_table[FE_DIVBYZERO] = C_FE_DIVBYZERO
conv_table[FE_OVERFLOW] = C_FE_OVERFLOW
conv_table[FE_UNDERFLOW] = C_FE_UNDERFLOW
conv_table[FE_INVALID] = C_FE_INVALID

sequence rev = repeat(0, C_FE_INEXACT)
rev[C_FE_INEXACT]   = FE_INEXACT
rev[C_FE_DIVBYZERO] = FE_DIVBYZERO
rev[C_FE_OVERFLOW]  = FE_OVERFLOW
rev[C_FE_UNDERFLOW] = FE_UNDERFLOW
rev[C_FE_INVALID]   = FE_INVALID


function e_to_c(fexcept_t ee)
-- convert our sequence style flag set to
-- the C bitwise combo set.function conv(fexcept_t ee)
	integer ce = 0
	for i = 1 to length(ee) do
		ce = or_bits(ce, conv_table[ee[i]])
	end for
	return ce
end function

-- convert the C bitwise combo set to
-- our sequence style flag set.
function c_to_e(integer ce)
	sequence ee = {}
	integer i = 1
	while i <= C_FE_INEXACT do
		if and_bits(ce, i) = i then
			ee = append(ee, rev[i])
		end if
		i *= 2
	end while
	return ee
end function

-- clears a single exception or a sequence 
-- of exceptions
public function clear(object e_p)
	fexcept_t ee
	if integer(e_p) then
		ee = {e_p}
	else
		ee = e_p
	end if
	if feclearexcept != -1 then
		return c_func(feclearexcept, {e_to_c(ee)})
	else
		return -1
	end if
end function

public function raise(object e_p)
	fexcept_t ee
	if integer(e_p) then
		ee = {e_p}
	else
		ee = e_p
	end if
	if feraiseexcept = -1 then
		return -1
	end if
	return c_func(feraiseexcept, {e_to_c(ee)})
end function


public function test(object e_p)
	fexcept_t ee
	if integer(e_p) then
		ee = {e_p}
	else
		ee = e_p
	end if
	if fetestexcept = -1 then
		return 0
	end if
	integer ce = c_func(fetestexcept, {e_to_c(ee)})
	sequence ans = c_to_e(ce)
	if integer(e_p) then
		return ce
	end if
	return ans
end function
	 
	 
	 
    	
