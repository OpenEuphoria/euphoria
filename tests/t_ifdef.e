include std/unittest.e

set_test_verbosity( TEST_SHOW_ALL )

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

--
-- Nested
--

ifdef ABC then
	ifdef DEF then
		test_pass("ifdef nested 1")
	elsedef
		test_fail("ifdef nested 1")
	end ifdef

	ifdef NOT_DEFINED then
		test_fail("ifdef nested 2")
	elsedef
		test_pass("ifdef nested 2")
	end ifdef
end ifdef

ifdef XYZ then
	test_fail( "XYZ not defined")
	ifdef UVW then
		test_fail( "nested UVW not defined" )
	elsifdef ABC then
		test_fail( "nested ifdef true elsifdef clause should never be evaluated" )
	end ifdef
end ifdef

ifdef XYZ or QWE then
	test_fail("ifdef XYZ or QWE then")
    ifdef not XYZ or not QWE then
		test_fail("ifdef not XYZ or not QWE then")
	elsifdef HJK or ABC or DEF or IOP or CVB or MNB or ASD or GFD then
		test_fail("elsifdef HJK or ABC or DEF or IOP or CVB or MNB or ASD or GFD then")
	end ifdef -- dead inside xyz or qwe
elsifdef HJK then

    ifdef XYZ or  QWE or ABC or DEF or IOP or CVB or MNB or ASD or GFD then
		test_fail("ifdef XYZ or  QWE or ABC or DEF or IOP or CVB or MNB or ASD or GFD then")
	end ifdef -- dead inside hjk
	
elsifdef ABC or FOO then
	test_pass( "found elseifdef ABC or FOO" )
	ifdef HJK or XYZ or QWE then
		test_fail("OS Name Conflict: Both ABC and non-ABC OS def-symbol defined. Defines: " & platform_defines)	
	end ifdef -- non matching hjk or xyz or qwe inside abc or foo
	ifdef DEF then
		test_pass("found 2nd elsifdef, second ifdef DEF")
	elsedef -- def
		test_fail("missed the ifdef")
	end ifdef -- end of def inside abc or foo
elsedef -- xyz or qwe
	test_fail("missed the elsifdef ABC or FOO")
end ifdef -- zxy or qwe

-- ifdef then
-- end ifdef
-- 
-- ifdef ABC DEF then
-- end ifdef
-- 
-- ifdef ABC and and DEF then
-- end ifdef
-- 
-- ifdef ABC or and DEF then
-- end ifdef
-- 
-- ifdef ABC and or DEF then
-- end ifdef
-- 
-- ifdef ABC and then
-- end ifdef
-- 
-- ifdef ABC or then
-- end ifdef
-- 
-- ifdef and then
-- end ifdef
-- 
-- ifdef or then
-- end ifdef
-- 
-- ifdef ABC and DEF GHI then
-- end ifdef
-- 
-- ifdef !ABC then
-- end ifdef
-- 
test_report()
