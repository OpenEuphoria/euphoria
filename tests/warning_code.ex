include std/error.e
include std/locale.e

warning_file( "warnings_issued.txt" )

without warning
--with warning &= { resolution, short_circuit }

function time()
	return eu:time()
end function

-- warning resolution
atom a1 = time()

with warning {resolution}
atom a2 = time()

with warning = { none }
with warning = { short_circuit }

-- warn here
if a1 and a2 then
	-- do nothing
end if



with warning = { not_used }
-- warn here (not_used)
integer i1
integer i5
? i5


-- warn here but only if you have not_used and strict
procedure p1(integer i2)
-- warn here (not used)
	integer i3
	integer i4
	? i4
end procedure

constant a6 = 'f'
