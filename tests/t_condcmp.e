include unittest.e
include os.e

ifdef hello then
    test_fail("not defined #1")
end ifdef

with define=hello
ifdef hello then
    test_pass("defined #1")
else
    test_fail("defined #1")
end ifdef

without define=hello
ifdef hello then
    test_fail("undefine #1")
end ifdef

ifdef UNIX then
    if platform() = 3 or platform() = 4 then
		test_pass("UNIX test")
	else
		test_fail("UNIX test")
	end if
end ifdef

ifdef OSX then
    test_equal("OSX test", 4, platform())
end ifdef

ifdef FREEBSD then
	test_equal("FREEBSD test", 3, platform())
end ifdef

ifdef LINUX then
	test_equal("LINUX test", 3, platform())
end ifdef

ifdef WIN32 then
	test_equal("WIN32 test", 2, platform())
end ifdef

ifdef DOS32 then
	test_equal("DOS32 test", 1, platform())
end ifdef

ifdef EU400 then
    test_pass("EU400")
else
    test_fail("EU400")
end ifdef

test_embedded_report()

