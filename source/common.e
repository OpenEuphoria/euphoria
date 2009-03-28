-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Common definitions for backend.ex and other *.ex.
-- backend.ex does not include global.e

include std/os.e

public include std/types.e

-- operating system:
global constant EUNIX = (platform() = LINUX or platform() = FREEBSD or platform() = OSX),
				EWINDOWS = platform() = WIN32,
				EDOS = platform() = DOS32,
				EBSD = (atom(dir("/proc/dev/net")) or platform() = OSX),
				EOSX = platform() = OSX,
				ELINUX = (platform() = LINUX) and not EBSD and not EOSX,
				-- this is here so traninit.e and tranplat.e can distinguish between FREEBSD and LINUX
				ULINUX = LINUX + 0.3,
				UFREEBSD = FREEBSD + 0.4,
				-- this is not strictly necessary yet
				UOSX = OSX + 0.5

global integer PATH_SEPARATOR
global sequence SLASH_CHARS
if EUNIX then
	PATH_SEPARATOR = ':' -- in PATH environment variable
	SLASH_CHARS =  "/"   -- special chars allowed in a path
else
	PATH_SEPARATOR = ';'
	SLASH_CHARS = "\\/:"
end if

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
