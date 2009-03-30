-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Common definitions for backend.ex and other *.ex.
-- backend.ex does not include global.e

include std/os.e
public include std/types.e

public constant
	NOT_INCLUDED     = 0,
	INDIRECT_INCLUDE = 1,
	DIRECT_INCLUDE   = 2,
	PUBLIC_INCLUDE   = 4,
	DIRECT_OR_PUBLIC_INCLUDE = DIRECT_INCLUDE + PUBLIC_INCLUDE,
	ANY_INCLUDE = DIRECT_OR_PUBLIC_INCLUDE + INDIRECT_INCLUDE

global sequence SymTab = {}  -- the symbol table

global sequence file_name = {}
global sequence file_include = {{}} -- remember which files were included where
global sequence include_matrix = {{DIRECT_INCLUDE}} -- quicker access to include information
global sequence indirect_include = {{1}}
global sequence file_public = {{}}  -- also remember which files are "public include"d
global sequence file_include_by = {{}}
global sequence file_public_by = {{}}

global integer AnyTimeProfile      -- time profile option was ever selected 
global integer AnyStatementProfile -- statement profile option was ever selected 

global sequence all_source = {} -- pointers to chunks

global constant
	ULINUX = LINUX + 0.3,
	UFREEBSD = FREEBSD + 0.4,
	UOSX = OSX + 0.5,
	USUNOS = SUNOS + 0.6

-- For cross-translation:
global sequence HOSTNL
global integer
	IWINDOWS = 0, TWINDOWS = 0,
	IDOS     = 0, TDOS     = 0,
	ILINUX   = 0, TLINUX   = 0,
	IUNIX    = 0, TUNIX    = 0,
	IBSD     = 0, TBSD     = 0,
	IOSX     = 0, TOSX     = 0,
	ISUNOS   = 0, TSUNOS   = 0,
	ihost_platform

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

elsifdef LINUX then
	ILINUX = 1
	TLINUX = 1

end ifdef

ifdef OSX or SUNOS or FREEBSD then
	IBSD = 1
	TBSD = 1
end ifdef

ifdef OSX or SUNOS or FREEBSD or LINUX then
	IUNIX = 1
	TUNIX = 1
end ifdef

ifdef UNIX then
	global constant
		PATH_SEPARATOR = ':',
		SLASH_CHARS = "/"
	HOSTNL = "\n"
elsedef
	global constant
		PATH_SEPARATOR = ';',
		SLASH_CHARS = "\\/:"
	HOSTNL = "\r\n"
end ifdef

global procedure set_host_platform( atom plat )
	ihost_platform = floor(plat)
	TUNIX    = (plat = ULINUX or plat = UFREEBSD or plat = UOSX or plat = USUNOS)
	TWINDOWS = plat = WIN32
	TDOS     = plat = DOS32
	TBSD     = plat = UFREEBSD
	TOSX     = plat = UOSX
	TLINUX   = plat = ULINUX
	TSUNOS   = plat = USUNOS
	if TUNIX then
		HOSTNL = "\n"
	else
		HOSTNL = "\r\n"
	end if
	IUNIX = TUNIX
	IWINDOWS = TWINDOWS
	IDOS = TDOS
	IBSD = TBSD
	IOSX = TOSX
	ILINUX = TLINUX
	ISUNOS = TSUNOS
end procedure

ihost_platform = platform()
global function host_platform()
	return ihost_platform
end function
