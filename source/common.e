-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Common definitions for backend.ex and other *.ex.
-- backend.ex does not include global.e

include misc.e

global constant TRUE = 1, FALSE = 0

-- operating system:
global constant ELINUX = platform() = LINUX,
				EWINDOWS = platform() = WIN32,
				EDOS = platform() = DOS32,
				EBSD = FALSE -- set manually - see also backend.ex


global integer PATH_SEPARATOR, SLASH
global sequence SLASH_CHARS
if ELINUX then
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
file_name = {} -- declared in common.e
file_include = {{}}

global integer AnyTimeProfile      -- time profile option was ever selected 
global integer AnyStatementProfile -- statement profile option was ever selected 

global sequence all_source  -- pointers to chunks

all_source = {}
