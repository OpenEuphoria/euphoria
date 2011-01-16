include std/unittest.e
include std/os.e

ifdef hello then
    test_fail("not defined #1")
end ifdef

with define hello_
ifdef hello_ then
    test_pass("defined #1")
elsedef
    test_fail("defined #1")
end ifdef

without define hello_
ifdef hello then
    test_fail("undefine #1")
end ifdef

ifdef UNIX then
    if platform() >= 3 then
		test_pass("UNIX test")
	else
		test_fail("UNIX test")
	end if
end ifdef

ifdef OSX then
    test_equal("OSX test", 4, platform())
end ifdef

ifdef FREEBSD then
	test_equal("FREEBSD test", 8, platform())
end ifdef

ifdef LINUX then
	test_equal("LINUX test", 3, platform())
end ifdef

ifdef WINDOWS then
	test_equal("WINDOWS test", 2, platform())
end ifdef

ifdef EU4_1_0 then
    test_pass("EU4_1_0")
elsedef
    test_fail("EU4_1_0")
end ifdef

ifdef EU4_1 then
	test_pass("EU4_1")
elsedef
	test_fail("EU4_1")
end ifdef

ifdef EU4 then
	test_pass("EU4")
elsedef
	test_fail("EU4")
end ifdef

test_report()
