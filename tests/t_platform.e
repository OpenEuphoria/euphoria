include std/unittest.e
include std/os.e

ifdef WIN32 or WINDOWS then
    ifdef not WIN32 or not WINDOWS then
		test_fail("One of the accompanying defines is not defined.")
	elsifdef DOS32 or UNIX or LINUX or OPENBSD or NETBSD or FREEBSD or SUNOS or OSX then
		test_fail("OS Name Conflict: Both Windows and non-Windows OS def-symbol defined.")	
	end ifdef
	test_equal("WIN32=platform()", WIN32, platform() )
elsifdef DOS32 then
    ifdef WIN32 or  WINDOWS or  
		UNIX or LINUX or OPENBSD or NETBSD or FREEBSD or SUNOS or OSX then
		test_fail("OS Name Conflict: Both DOS and non-DOS OS def-symbol defined.")	
	end ifdef
	test_equal("DOS32=platform()", 1, platform() )
	test_fail("Def-symbols set to an unsupported OS")
elseifdef UNIX then
	ifdef DOS32 or WIN32 or WINDOWS then
		test_fail("OS Name Conflict: Both UNIX and non-UNIX OS def-symbol defined.")	
	end ifdef
	ifdef LINUX then
		test_equal("LINUX=platform()", LINUX, platform())
	elsifdef OPENBSD then
	    test_equal("OPENBSD=platform()", OPENBSD, platform())
	elsifdef NETBSD then
	    test_equal("NETBSD=platform()", NETBSD, platform())	
	elsifdef FREEBSD then
	    test_equal("FREEBSD=platform()", FREEBSD, platform())
	elsifdef SUNOS then
	    test_equal("SUNBSD=platform()", SUNOS, platform())
	elsifdef OSX then
	    test_equal("OSX=platform()", OSX, platform())
	elsedef
		test_fail("UNIX def-symbol is set but no supported UNIX def-symbol is set")
	end ifdef
elsedef
	test_fail("Invalid combination neither WINDOWS nor UNIX")
end ifdef

test_report()
