include unittest.e

ifdef NOT_DEFINED then
	procedure abc()
		integer a
		a = 10
	end procedure

	procedure def()
		integer a
		a = 10
	end procedure
else
	procedure abc()
		integer a
		a = 10
	end procedure

	procedure def()
		integer a
		a = 10
	end procedure
end ifdef

integer n=1
ifdef NOT_DEFINED then
	if n=1 then n=2 end if
else
	n=0
end ifdef
test_equal("Format of ifdef code",0,n)

test_report()

