with define=DEFINED
include unittest.e

ifdef DEFINED then
elsifdef NOTDEFINED then
	end for
else
	end while
end ifdef

test_report()

