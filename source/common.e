-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Common definitions for backend.ex and other *.ex.
-- backend.ex does not include global.e

include misc.e

global constant TRUE = 1, FALSE = 0

-- operating system:
global constant EUNIX = (platform() = LINUX or platform() = FREEBSD),
				EWINDOWS = platform() = WIN32,
				EDOS = platform() = DOS32,
				EBSD = FALSE -- set manually - see also backend.ex
global constant -- TODO make this cleaner
				ELINUX = not EBSD


global integer PATH_SEPARATOR, SLASH
global sequence SLASH_CHARS
if EUNIX then
	PATH_SEPARATOR = ':' -- in PATH environment variable
	SLASH = '/'          -- preferred on Linux/FreeBSD
	SLASH_CHARS =  "/"   -- special chars allowed in a path
else
	PATH_SEPARATOR = ';'
	SLASH = '\\'
	SLASH_CHARS = "\\/:"
end if


global sequence SymTab  -- the symbol table
SymTab = {}

global sequence file_name
global sequence file_include  -- remember which files were included where
global sequence file_export   -- also remember which files are exported
file_name = {} -- declared in common.e
file_include = {{}}
file_export = {{}}

global integer AnyTimeProfile      -- time profile option was ever selected 
global integer AnyStatementProfile -- statement profile option was ever selected 

global sequence all_source  -- pointers to chunks

all_source = {}
