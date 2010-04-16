-- (c) Copyright - See License.txt
--

--****
-- == utils
--
-- <<LEVELTOC depth=2>>

namespace utils


--**
-- Used to embed an 'if' test inside an expression.
--
-- Parameters:
--   # ##test## : an atom, the result of a boolean expression
--   # ##ifTrue## : an object, returned if ##test## is **non-zero **
--   # ##ifFalse## : an object, returned if ##test## is zero
--
-- Returns:
-- An object. Either ##ifTrue## or ##ifFalse## is returned depending on
-- the value of ##test##.
--
-- Example 1:
-- <eucode>
-- msg = sprintf("%s: %s", {
--	iff(ErrType = 'E', "Fatal error", "Warning"),
--		errortext } )
-- </eucode>

public function iff( atom test, object ifTrue, object ifFalse )
	-- returns ifTrue if flag is true, else returns ifFalse
	if test then
		return ifTrue
	end if
	return ifFalse
end function

