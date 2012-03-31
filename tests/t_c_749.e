include std/unittest.e
without inline
function foo( integer baz ) 
	return baz - 1 
end function 
 
procedure main() 
	integer t 
	while 1 with entry do 
		printf(1, "hello t\n", t ) 
		exit 
	entry 
		t = foo( t ) 
	end while 
end procedure 
main() 

test_pass("ticket 749")
test_report()
