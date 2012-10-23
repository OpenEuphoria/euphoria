--****
-- == Utilities
--
-- <<LEVELTOC level=2 depth=4>>

namespace utils

--****
-- === Routines

--**
-- Used to embed an 'if' test inside an expression. ##iif## stands for inline if or 
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
-- Warning Note:\\
--   You must take care when using this function because just like all other 
--   Euphoria routines, this does not do any //lazy evaluation//. 
--   All parameter expressions are evaluated **before**
--   the function is called, thus, it cannot be used when one of the
--   parameters could fail to evaluate correctly. For example, this is 
--   an **improper** use of the ##iif## statement~:
-- <eucode>
--   first = iif(sequence(var), var[1], var)
-- </eucode>
--   The reason for this is that both ##var[1]## and ##var## will be evaluated. 
--   Therefore if ##var## happens to be an atom, the ##var[1]## statement will fail.
--   \\In situations like this, it is better to use the //long// style.
-- <eucode>
--   if sequence(var) then
--      first = var[1]
--   else
--      first = var
--   end if
-- </eucode>
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
