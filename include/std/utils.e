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
--   an **improper** use of the ##iif## method
-- <eucode>
--   first = iif(sequence(var), var[1], var)
-- </eucode>
--   The reason for this is that both ##var[1]## and ##var## will be evaluated. 
--   Therefore if ##var## happens to be an atom, the ##var[1]## statement will fail.
--   \\In situations like this, it is better to use the //long// method.
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

public function assign(integer i1, object val1, 
                       integer i2  = 0, object val2  = 0,
                       integer i3  = 0, object val3  = 0,
                       integer i4  = 0, object val4  = 0,
                       integer i5  = 0, object val5  = 0,
                       integer i6  = 0, object val6  = 0,
                       integer i7  = 0, object val7  = 0,
                       integer i8  = 0, object val8  = 0,
                       integer i9  = 0, object val9  = 0,
                       integer i10 = 0, object val10 = 0)
	   sequence s = {i1, val1, i2, val2, i3, val3, i4, val4, i5, val5, i6, val6, i7, val7, i8, val8, i9, val9, i10, val10}
	   for i = 3 to 19 by 2 do
	       if s[i] = 0 then
	           return assign_s(s[1..i-1])
	       end if
	   end for
	   return assign_s(s)
end function

function assign_s(sequence s)
    integer maxi
    sequence ret
    maxi=0
    for i = 1 to length(s) by 2 do
            if s[i] > maxi then
                    maxi = s[i]
            end if
    end for
    ret = repeat(0,maxi)
    for i = 1 to length(s) by 2 do
            ret[s[i]] = s[i+1]
    end for
    return ret     
end function
--**
-- @nodoc@

public function iff(atom test, object ifTrue, object ifFalse)
	return iif(test, ifTrue, ifFalse)
end function
