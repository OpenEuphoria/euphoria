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

test_embedded_report()

