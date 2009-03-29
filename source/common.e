-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Common definitions for backend.ex and other *.ex.
-- backend.ex does not include global.e

include std/os.e

public include std/types.e

-- operating system:
ifdef DOS32 then
	global constant EDOS=1, EWINDOWS=0, EUNIX=0, ELINUX=0, EBSD=0, EOSX=0, ESUNOS=0
elsifdef WIN32 then
	global constant EDOS=0, EWINDOWS=1, EUNIX=0, ELINUX=0, EBSD=0, EOSX=0, ESUNOS=0
elsifdef OSX then
	global constant EDOS=0, EWINDOWS=0, EUNIX=1, ELINUX=0, EBSD=1, EOSX=1, ESUNOS=0
elsifdef SUNOS then
	global constant EDOS=0, EWINDOWS=0, EUNIX=1, ELINUX=0, EBSD=1, EOSX=0, ESUNOS=1
elsifdef FREEBSD then
	global constant EDOS=0, EWINDOWS=0, EUNIX=1, ELINUX=0, EBSD=1, EOSX=0, ESUNOS=0
elsifdef LINUX then
	global constant EDOS=0, EWINDOWS=0, EUNIX=1, ELINUX=1, EBSD=0, EOSX=0, ESUNOS=0
end ifdef

global constant
	ULINUX = LINUX + 0.3,
	UFREEBSD = FREEBSD + 0.4,
	UOSX = OSX + 0.5,
	USUNOS = SUNOS + 0.6

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
