include std/unittest.e

procedure ticket_666()
	sequence foo = ""
	if 0 and length( foo ) then
		test_fail("translated if optimization of known temp false value")
	end if
	test_pass("translated if optimization of known temp false value")
end procedure
ticket_666()

test_report()
