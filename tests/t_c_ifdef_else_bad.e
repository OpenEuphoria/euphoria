with define DEFINED
include std/unittest.e

ifdef NOT_DEFINED then
elsifdef DEFINED then
	end for
elsedef
	end while
end ifdef

test_report()

