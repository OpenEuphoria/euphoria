-- used by t_defparms.e

include defparam2.e

export function defparams( integer a = DEFPARAM1, integer b = DEFPARAM2 )
	return a + b
end function

constant DEFPARAM1 = 1
