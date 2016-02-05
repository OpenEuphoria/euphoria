include std/error.e
include std/locale.e
include warning_code1.e as wc1

warning_file( "warnings_issued.txt" )

without warning
--with warning &= { resolution, short_circuit }

with warning = { override }

override function time()
	return 0*eu:time()
end function


without warning

atom a1 = time()

with warning {builtin_chosen}
-- the global puts defined in warning_code1.e is not used.  The built in puts is.
puts(1, "-")

with warning = { none }
with warning = { short_circuit }

-- warn here
if a1 and time() then
	-- do nothing
end if



with warning = { not_used }
-- warn here (not_used)
integer i1
integer i5


-- warn here but only if you have not_used and strict
procedure p1(integer i2)
-- warn here (not used)
	integer i3
	integer i4
	? i4
end procedure

constant a6 = 'f'

procedure void( object x )
end procedure

-- warn here override. :o
void( time() )

? i5
