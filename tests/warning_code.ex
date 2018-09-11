without warning
include std/error.e
include std/locale.e
include warning_code1.e as wc1 -- includes a puts() routine

warning_file( "warnings_issued.txt" )

without warning

with warning = { override }
-- warning here.  Override time()
override function time()
	return 0*eu:time()
end function
without warning

atom a1 = time()

with warning {builtin_chosen}
-- the global puts defined in warning_code1.e is not used.  The built in puts is.
-- warn here
puts(1, "-")

with warning = { none }
with warning = { short_circuit }

-- do not warn here.  Since time() has no side-effect, there is no need to issue a warning
if a1 and time() then
	-- do nothing
end if

function increment_a1()
    a1 += 1
    return a1
end function

-- do warn here because increment_a1() has a side-effect
if a1 and increment_a1() then
    -- do nothing
end if

with warning = { not_used }
-- warn here (not_used)
integer i1
integer i5

-- warn here but only if you have not_used and strict
procedure p1(integer i2)
	-- warn here (not used) *different* from i1 warning
	integer i3
	integer i4
	-- warn here (not used) *different* from i1 and i3 warnings
	? i4
end procedure

constant a6 = 'f'

procedure void( object x )
end procedure

-- warn here override. :o
void( time() )

-- no warning here it is disabled.
abort(0)

-- warning (not used) from this line of code *different* from other warnings
? i5
