--
-- Platform settings
--

include std/os.e


public constant
	ULINUX = LINUX + 0.3,
	UFREEBSD = FREEBSD + 0.4,
	UOSX = OSX + 0.5,
	USUNOS = SUNOS + 0.6,
	UOPENBSD = OPENBSD + 0.7,
	UNETBSD = NETBSD + 0.8,
	DEFAULT_EXTS = { ".ex", ".exw", ".exd", "", ".ex" }

-- For cross-translation:
public integer
	IWINDOWS = 0, TWINDOWS = 0,
	IDOS     = 0, TDOS     = 0,
	ILINUX   = 0, TLINUX   = 0,
	IUNIX    = 0, TUNIX    = 0,
	IBSD     = 0, TBSD     = 0,
	IOSX     = 0, TOSX     = 0,
	ISUNOS   = 0, TSUNOS   = 0,
	IOPENBSD = 0, TOPENBSD = 0,
	INETBSD  = 0, TNETBSD  = 0

-- operating system:
ifdef DOS32 then
	IDOS = 1
	TDOS = 1

elsifdef WIN32 then
	IWINDOWS = 1
	TWINDOWS = 1

elsifdef OSX then
	IOSX = 1
	TOSX = 1

elsifdef SUNOS then
	ISUNOS = 1
	TSUNOS = 1

elsifdef FREEBSD then
	IBSD = 1
	TBSD = 1

elsifdef OPENBSD then
	IOPENBSD = 1
	TOPENBSD = 1

elsifdef NETBSD then
	INETBSD = 1
	TNETBSD = 1

elsifdef LINUX then
	ILINUX = 1
	TLINUX = 1

end ifdef

ifdef OSX or SUNOS or FREEBSD or OPENBSD or NETBSD then
	IBSD = 1
	TBSD = 1
end ifdef

ifdef UNIX then
	IUNIX = 1
	TUNIX = 1

	public constant
		PATH_SEPARATOR = ':',
		SLASH_CHARS = "/"
	public sequence HOSTNL = "\n" -- may change if cross-translating

elsedef
	public constant
		PATH_SEPARATOR = ';',
		SLASH_CHARS = "\\/:"
	public sequence HOSTNL = "\r\n" -- may change if cross-translating
end ifdef

integer ihost_platform = platform()
public function host_platform()
	return ihost_platform
end function

public procedure set_host_platform( atom plat )
	ihost_platform = floor(plat)

	TUNIX    = (plat = ULINUX or plat = UFREEBSD or plat = UOSX or plat = USUNOS or
	            plat = UOPENBSD or plat = UNETBSD)

	TWINDOWS = plat = WIN32
	TDOS     = plat = DOS32
	TBSD     = plat = UFREEBSD
	TOSX     = plat = UOSX
	TLINUX   = plat = ULINUX
	TSUNOS   = plat = USUNOS
	TOPENBSD = plat = UOPENBSD
	TNETBSD  = plat = UNETBSD
	IUNIX    = TUNIX
	IWINDOWS = TWINDOWS
	IDOS     = TDOS
	IBSD     = TBSD
	IOSX     = TOSX
	ILINUX   = TLINUX
	ISUNOS   = TSUNOS
	IOPENBSD = TOPENBSD
	INETBSD  = TNETBSD

	if TUNIX then
		HOSTNL = "\n"
	else
		HOSTNL = "\r\n"
	end if
end procedure

public function GetPlatformDefines(integer for_translator = 0)
	sequence local_defines = {}

	if (IWINDOWS and not for_translator) or (TWINDOWS and for_translator) then
		local_defines &= {"MICROSOFT", "WIN32"}
		sequence lcmds = command_line()
		if match("euiw", lcmds[1]) != 0 then
			local_defines &= { "WIN32_GUI" }
		else
			local_defines &= { "WIN32_CONSOLE" }
		end if
	elsif (IDOS and not for_translator) or (TDOS and for_translator) then
		local_defines &= {"MICROSOFT", "DOS32"}
	elsif (ILINUX and not for_translator) or (TLINUX and for_translator) then
		local_defines &= {"UNIX", "LINUX"}
	elsif (IOSX and not for_translator) or (TOSX and for_translator) then
		local_defines &= {"UNIX", "BSD", "OSX"}
	elsif (ISUNOS and not for_translator) or (TSUNOS and for_translator) then
		local_defines &= {"UNIX", "BSD", "SUNOS"}
	elsif (IOPENBSD and not for_translator) or (TOPENBSD and for_translator) then
		local_defines &= { "UNIX", "BSD", "OPENBSD"}
	elsif (INETBSD and not for_translator) or (TNETBSD and for_translator) then
		local_defines &= { "UNIX", "BSD", "NETBSD"}
	elsif (IBSD and not for_translator) or (TBSD and for_translator) then
		local_defines &= {"UNIX", "BSD", "FREEBSD"}
	end if

	-- So the translator knows what to strip from defines if translating
	-- to a different platform
	return { "_PLAT_START" } & local_defines & { "_PLAT_STOP" }
end function
