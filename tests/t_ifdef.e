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

include std/dll.e
ifdef X86 then
	test_equal("sizeof C_POINTER X86", 4, sizeof( C_POINTER ) )
elsifdef X86_64 then
	test_equal("sizeof C_POINTER X86_64", 8, sizeof( C_POINTER ) )
elsifdef ARM then
	test_equal("sizeof C_POINTER ARM", 4, sizeof( C_POINTER ) )
elsedef
	test_fail("no valid arch ifdef exists")
end ifdef

ifdef BITS32 then
	test_equal("sizeof C_POINTER BITS32", 4, sizeof( C_POINTER ) )
elsifdef BITS64 then
	test_equal("sizeof C_POINTER BITS64", 8, sizeof( C_POINTER ) )
elsedef
	test_fail("no valid BITS ifdef exists")
end ifdef


ifdef LONG32 then
	test_equal("sizeof C_LONG", 4, sizeof( C_LONG ) )
elsifdef LONG64 then
	test_equal("sizeof C_LONG LONG64", 8, sizeof( C_LONG ) )
elsedef
	test_fail("no valid LONG ifdef exists")
end ifdef

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
