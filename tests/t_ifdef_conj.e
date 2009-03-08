include std/unittest.e

with define ABC
with define DEF

ifdef ABC then
	test_pass("ifdef normal")
end ifdef

ifdef not ABC then
	test_fail("ifdef not")
elsedef
	test_pass("ifdef not")
end ifdef

ifdef ABC and DEF then
	test_pass("ifdef and")
elsedef
	test_fail("ifdef and")
end ifdef

ifdef ABC or DEF then
	test_pass("ifdef or 1")
elsedef
	test_fail("ifdef or 1")
end ifdef

ifdef ABC or NOT_DEFINED then
	test_pass("ifdef or 2")
elsedef
	test_fail("ifdef or 2")
end ifdef

ifdef NOT_DEFINED or ABC then
	test_pass("ifdef or 3")
elsedef
	test_fail("ifdef or 3")
end ifdef

ifdef ABC and not DEF then
	test_fail("ifdef and not 1")
elsedef
	test_pass("ifdef and not 1")
end ifdef

ifdef ABC and not NOT_DEFINED then
	test_pass("ifdef and not 2")
elsedef
	test_pass("ifdef and not 2")
end ifdef

ifdef ABC or not DEF then
	test_pass("ifdef or not 1")
elsedef
	test_fail("ifdef or not 1")
end ifdef

ifdef ABC or not NOT_DEFINED then
	test_pass("ifdef or not 2")
elsedef
	test_fail("ifdef or not 2")
end ifdef

ifdef ABC and DEF and not NOT_DEFINED then
	test_pass("ifdef and and not")
elsedef
	test_fail("ifdef and and not")
end ifdef

test_report()
