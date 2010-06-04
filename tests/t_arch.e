include std/unittest.e
ifdef INTEL32 then
	test_pass("INTEL32 symbol works.")
elsedef
	test_fail("No ARCH symbol.")
end ifdef

test_report()

