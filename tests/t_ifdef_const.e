with define=DEFINED
include unittest.e


ifdef NOT_DEFINED then
	constant a = 0
elsifdef DEFINED then
	constant a = 1
end ifdef

ifdef DEFINED then
	constant b = 1
elsifdef NOT_DEFINED then
	constant b = 0
end ifdef

test_equal("ifdef constant a", 1, a)
test_equal("ifdef constant b", 1, b)

test_embedded_report()
