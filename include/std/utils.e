--****
-- == Utilities
--
-- <<LEVELTOC level=2 depth=4>>

namespace utils

--****
-- === Routines

--**
-- Used to embed an 'if' test inside an expression. iif stands for inline if or 
-- immediate if.
--
-- Parameters:
--   # ##test## : an atom, the result of a boolean expression
--   # ##ifTrue## : an object, returned if ##test## is **non-zero **
--   # ##ifFalse## : an object, returned if ##test## is zero
--
-- Returns:
--   An object. Either ##ifTrue## or ##ifFalse## is returned depending on
--   the value of ##test##.
--
-- Warning Note:
--   This statement does not do any short circuiting. Thus, it cannot be used when one
--   condition could fail. For example, this is an **improper** use of the ##iif## method
--   <eucode>
--   first = iif(sequence(var), var[1], var)
--   </eucode>
--   The reason for this is that both ##var[1]## and ##var## will be executed. Thus, if
--   ##var## happens to be an atom, the ##var[1]## statement will fail.
--
-- Example 1:
-- <eucode>
-- msg = sprintf("%s: %s", {
--     iif(ErrType = 'E', "Fatal error", "Warning"), 
--     errortext 
-- })
-- </eucode>

public function iif(atom test, object ifTrue, object ifFalse)
	if test then
		return ifTrue
	end if
	return ifFalse
end function

--**
-- @nodoc@

public function iff(atom test, object ifTrue, object ifFalse)
	return iif(test, ifTrue, ifFalse)
end function
