with define=DEFINED
include unittest.e

ifdef NOT_DEFINED then
elsifdef DEFINED then
	end for
else
	end while
end ifdef

test_report()

