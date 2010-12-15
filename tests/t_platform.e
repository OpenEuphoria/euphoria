include std/unittest.e
include std/os.e
sequence platform_defines = ""

ifdef WIN32 then
	platform_defines &= "WIN32 "
end ifdef

ifdef WINDOWS then
	platform_defines &= "WINDOWS "
end ifdef

ifdef UNIX then
	platform_defines &= "UNIX "
end ifdef

ifdef LINUX then
	platform_defines &= "LINUX "
end ifdef

ifdef OPENBSD then
	platform_defines &= "OPENBSD "
end ifdef

ifdef NETBSD then
	platform_defines &= "NETBSD "
end ifdef

ifdef OSX then
	platform_defines &= "OSX "
end ifdef

ifdef WIN32 or WINDOWS then
    ifdef not WIN32 or not WINDOWS then
		test_fail("One of the accompanying defines is not defined. Defines: " & platform_defines)
	elsifdef DOS32 or UNIX or LINUX or OPENBSD or NETBSD or FREEBSD or OSX then
		test_fail("OS Name Conflict: Both Windows and non-Windows OS def-symbol defined. Defines: " & platform_defines)	
	end ifdef
	test_equal("WIN32=platform()", WIN32, platform() )
elsifdef DOS32 then
    ifdef WIN32 or  WINDOWS or  
		UNIX or LINUX or OPENBSD or NETBSD or FREEBSD or OSX then
		test_fail("OS Name Conflict: Both DOS and non-DOS OS def-symbol defined. Defines: " & platform_defines)	
	end ifdef
	test_equal("DOS32=platform()", 1, platform() )
	test_fail("Def-symbols set to an unsupported OS Defines: " & platform_defines)
elsifdef UNIX then
	ifdef DOS32 or WIN32 or WINDOWS then
		test_fail("OS Name Conflict: Both UNIX and non-UNIX OS def-symbol defined. Defines: " & platform_defines)	
	end ifdef
	ifdef LINUX then
		test_equal("LINUX=platform()", LINUX, platform())
	elsifdef OPENBSD then
	    test_equal("OPENBSD=platform()", OPENBSD, platform())
	elsifdef NETBSD then
	    test_equal("NETBSD=platform()", NETBSD, platform())	
	elsifdef FREEBSD then
	    test_equal("FREEBSD=platform()", FREEBSD, platform())
	elsifdef OSX then
	    test_equal("OSX=platform()", OSX, platform())
	elsedef
		test_fail("UNIX def-symbol is set but no supported UNIX def-symbol is set. Defines: " & platform_defines)
	end ifdef
elsedef
	test_fail("Invalid combination neither WINDOWS nor UNIX. Defines: " & platform_defines)
end ifdef

test_report()
