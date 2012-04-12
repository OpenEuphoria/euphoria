include std/unittest.e
without inline
function foo( integer baz ) 
	return baz - 1 
end function 
 
procedure goto_init( integer y )
	integer x
	if y then
		goto "x not initialized"
	end if
	x = 5
	label "x not initialized"
	x = foo( x )
end procedure 
goto_init( 8 )

test_pass("ticket 749 goto")
test_report()
