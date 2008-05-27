include misc.e
include unittest.e

set_test_module_name("t_condcmp.e")

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
    if platform() = LINUX then -- for backwards compatibility
        test_pass("UNIX test")
    else
        test_fail("UNIX test")
    end if
end ifdef

ifdef FREEBSD then
    if platform() = FREEBSD then -- for backwards compatibility, FREEBSD = LINUX
        test_pass("FREEBSD test")
    else
        test_fail("FREEBSD test")
    end if
end ifdef

ifdef LINUX then
    if platform() = LINUX then
        test_pass("LINUX test")
    else
        test_fail("LINUX test")
    end if
end ifdef

ifdef WIN32 then
    if platform() = WIN32 then
        test_pass("WIN32 test")
    else
        test_fail("WIN32 test")
    end if
end ifdef

ifdef DOS32 then
    if platform() = DOS32 then
        test_pass("DOS32 test")
    else
        test_fail("DOS32 test")
    end if
end ifdef

ifdef EU400 then
    test_pass("EU400")
else
    test_fail("EU400")
end ifdef
