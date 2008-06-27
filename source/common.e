-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Common definitions for backend.ex and other *.ex.
-- backend.ex does not include global.e

include os.e

global constant TRUE = 1, FALSE = 0

-- operating system:
global constant EUNIX = (platform() = LINUX or platform() = FREEBSD or platform() = OSX),
				EWINDOWS = platform() = WIN32,
				EDOS = platform() = DOS32,
				EBSD = FALSE,
				EOSX = FALSE,
				ELINUX = not EBSD and not EOSX

global integer PATH_SEPARATOR
global sequence SLASH_CHARS
if EUNIX then
	PATH_SEPARATOR = ':' -- in PATH environment variable
	SLASH_CHARS =  "/"   -- special chars allowed in a path
else
	PATH_SEPARATOR = ';'
	SLASH_CHARS = "\\/:"
end if

global sequence SymTab = {}  -- the symbol table

global sequence file_name = {}
global sequence file_include = {{}} -- remember which files were included where
global sequence file_export = {{}}  -- also remember which files are exported

global integer AnyTimeProfile      -- time profile option was ever selected 
global integer AnyStatementProfile -- statement profile option was ever selected 

global sequence all_source = {} -- pointers to chunks
