include std/unittest.e
include std/machine.e

ifdef ARCH32 or ARCH64 then
	test_pass("ARCH symbol")
elsedef
	test_fail("ARCH symbol")
end ifdef

ifdef X86 or X86_64 or ARM or ITANIUM then
	test_pass("Instruction set symbol")
elsedef
	test_fail("Instruction set symbol")
end ifdef

atom li
li = allocate(4)
poke4(li,#DEADBEEF)
li = peek(li)
ifdef LITTLE_ENDIAN then
	test_equal("Endian Symbol check",#EF,li)
elsifdef BIG_ENDIAN then	
	test_equal("Endian Symbol check",#DE,li)
elsifdef EC then
	-- translated sometimes neither symbol is defined
	-- No Endian Symbol check with translator
elsedef
	test_fail("Endian Symbol check")
end ifdef
test_report()

