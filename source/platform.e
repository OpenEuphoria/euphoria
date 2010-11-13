-- (c) Copyright - See License.txt
--
-- Platform settings
--

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

ifdef not BITS32 and not BITS64 then
	with define X86
	with define LITTLE_ENDIAN
	with define BITS32
end ifdef

include std/os.e
include std/text.e
include std/io.e

constant M_DEFINES      = 98

public constant
	DEFAULT_EXTS = { ".ex", ".exw", ".ex" }

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
ifdef WINDOWS then
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

sequence unices = {LINUX, FREEBSD, OSX, SUNOS, OPENBSD, NETBSD}
public procedure set_host_platform( atom plat )
	ihost_platform = floor(plat)

	TUNIX    = (find(ihost_platform, unices) != 0) 
	TWINDOWS = (ihost_platform = WIN32)
	TBSD     = (ihost_platform = FREEBSD)
	TOSX     = (ihost_platform = OSX)
	TLINUX   = (ihost_platform = LINUX)
	TSUNOS   = (ihost_platform = SUNOS)
	TOPENBSD = (ihost_platform = OPENBSD)
	TNETBSD  = (ihost_platform = NETBSD)
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

export type enum instruction_set
	x86, Itanium, x86_64, ARM
end type
export constant instruction_set_defines = upper({ "X86_32", "Itanium", "X86_64", "ARM" })                                   

export type enum byte_sex
	BIG_ENDIAN, LITTLE_ENDIAN
end type
export constant byte_sex_defines = { "BIG_ENDIAN", "LITTLE_ENDIAN" }

export constant word_size_defines = repeat(0,31) & {"BITS32"} & repeat(0,31) & {"BITS64"}

export integer iset   = 0
export integer endian = 0
export integer word_size = 0

public function GetPlatformDefines(integer for_translator = 0)
	sequence local_defines = {}

	if for_translator and (iset or endian or word_size) then

		if not instruction_set(iset) then
			if word_size = 32 or word_size = 0 then
				ifdef X86 then
					iset = x86
					endian = LITTLE_ENDIAN
				elsifdef ARM then
					iset = ARM
					endian = LITTLE_ENDIAN
				end ifdef
			end if
			if word_size = 64 or word_size = 0 then
				ifdef X86_64 or X86 then
					-- assume the extension to x86
					iset = x86_64
					-- biendian
				elsifdef ITANIUM then
					iset = Itanium
					-- biendian
				end ifdef
			end if
		end if
		
		if find(word_size,{32,64})=0 then
			ifdef BITS32 then
				word_size = 32
			elsifdef BITS64 then
				word_size = 64
			end ifdef
		end if
	
		if iset = 0 then
			ifdef X86 then
				iset = x86
				endian = LITTLE_ENDIAN
			elsifdef ARM then
				iset = ARM
				endian = LITTLE_ENDIAN
			elsifdef X86_64 then
				iset = x86_64
			elsifdef ITANIUM then
				iset = Itanium
			end ifdef
		end if
		
		local_defines &= { word_size_defines[word_size], 
			instruction_set_defines[iset] }
		
		if endian then
			local_defines &= { byte_sex_defines[endian] }
		end if
		puts(1,"Building defines from options\n")		
		
	else
		ifdef EU4_00_00 or ARCH32 then
			local_defines &= { "X86", "LITTLE_ENDIAN", "BITS32" }
			--puts(1, "Building defines because this is 4.0.0.\n")
		elsedef
			local_defines &= machine_func(M_DEFINES,{})
			--puts(1,"Building defines using machine_call\n")		
		end ifdef
	end if
	
	if (IWINDOWS and not for_translator) or (TWINDOWS and for_translator) then
		local_defines &= {"WINDOWS" }
		
		--puts(1,"__LOCAL DEFINES___" & 10)
		for i = 1 to length(local_defines) do
			--puts(1, local_defines[i] & 10)
		end for
		--puts(1,"__END__\n")
		if find( "BITS32", local_defines ) != 0 then
			local_defines &= { "WIN32" }			
		end if
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
				local_defines &= { "WIN32_GUI", "GUI" }
			elsif sk = 3 then
				local_defines &= { "WIN32_CONSOLE", "CONSOLE" }
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
