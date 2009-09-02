-- (c) Copyright - See License.txt
--
-- Platform settings
--

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include std/os.e
include std/text.e
include std/io.e

public constant
	ULINUX = LINUX + 0.3,
	UFREEBSD = FREEBSD + 0.4,
	UOSX = OSX,
	USUNOS = SUNOS,
	UOPENBSD = OPENBSD,
	UNETBSD = NETBSD,
	DEFAULT_EXTS = { ".ex", ".exw", ".exd", "", ".ex" }

-- For cross-translation:
public integer
	IWINDOWS = 0, TWINDOWS = 0,
	ILINUX   = 0, TLINUX   = 0,
	IUNIX    = 0, TUNIX    = 0,
	IBSD     = 0, TBSD     = 0,
	IOSX     = 0, TOSX     = 0,
	ISUNOS   = 0, TSUNOS   = 0,
	IOPENBSD = 0, TOPENBSD = 0,
	INETBSD  = 0, TNETBSD  = 0

-- operating system:
ifdef WIN32 then
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

sequence unices = {ULINUX, UFREEBSD, UOSX, USUNOS, UOPENBSD, UNETBSD}
public procedure set_host_platform( atom plat )
	ihost_platform = floor(plat)

	TUNIX    = (find(ihost_platform, unices) != 0) 
	TWINDOWS = (ihost_platform = WIN32)
	TBSD     = (ihost_platform = UFREEBSD)
	TOSX     = (ihost_platform = UOSX)
	TLINUX   = (ihost_platform = ULINUX)
	TSUNOS   = (ihost_platform = USUNOS)
	TOPENBSD = (ihost_platform = UOPENBSD)
	TNETBSD  = (ihost_platform = UNETBSD)
	IUNIX    = TUNIX
	IWINDOWS = TWINDOWS
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
		local_defines &= {"WINDOWS", "WIN32"}
		sequence lcmds = command_line()
		
		-- Examine the executable's image file to determine subsystem.
		integer fh
		fh = open(lcmds[1], "rb")
		if fh = -1 then
			-- for some reason I can't open the file, so use the name instead.
 			if match("euiw", lower(lcmds[1])) != 0 then
 				local_defines &= { "WIN32_GUI" }
 			else
 				local_defines &= { "WIN32_CONSOLE" }
 			end if
		else
			atom sk
			sk = seek(fh, #18) -- Fixed location of relocation table.
			sk = get_integer16(fh)
			if sk = #40 then
				-- We have a Windows image and not a MS-DOS image.
				sk = seek(fh, #3C) -- Fixed location of COFF signature offset.
				sk = get_integer32(fh)
				sk = seek(fh, sk)
				sk = get_integer16(fh)
				if sk = #4550 then -- "PE" in intel endian
					sk = get_integer16(fh)
					if sk = 0 then
						-- We got a Portable Image format
						sk = seek(fh, where(fh) + 88 )
						sk = get_integer16(fh)
					else
						sk = 0	-- Don't know this format.
					end if
				elsif sk = #454E then -- "NE" in intel endian
					-- We got a pre-Win95 image
					sk = seek(fh, where(fh) + 54 )
					sk = getc(fh)
				else
					sk = 0
				end if
			else
				sk = 0
			end if
			if sk = 2 then
				local_defines &= { "WIN32_GUI" }
			elsif sk = 3 then
				local_defines &= { "WIN32_CONSOLE" }
			else
				local_defines &= { "WIN32_UNKNOWN" }
			end if
			close(fh)
		end if
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
