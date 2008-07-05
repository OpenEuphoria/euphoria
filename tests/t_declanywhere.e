include unittest.e

function foo()
	integer bar = 1
	if bar then
		bar = 0
	end if
	
	sequence hello = "hello world"
	return hello
end function

test_equal( "declare variable anywhere at top level of routine", "hello world", foo() )
test_report()
