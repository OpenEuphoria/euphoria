include std/unittest.e

ifdef NOT_DEFINED then
	end if
end ifdef

ifdef NOT_DEF_1 then
	integer n=0
	ifdef NOT_DEF_2 then
		include dos_safe.e
	end ifdef
elsedef
	integer n=1
	ifdef NOT_DEF_2 then
		include dos_machine.e
	end ifdef
end ifdef

test_equal("Nested ifdefs 1",1,n)
test_report()

