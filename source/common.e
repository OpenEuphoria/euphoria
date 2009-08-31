-- (c) Copyright - See License.txt
--
-- Common definitions for backend.ex and other *.ex.
-- backend.ex does not include global.e

ifdef ETYPE_CHECK then
with type_check
elsedef
without type_check
end ifdef

include std/os.e
public include std/types.e

public constant
	NOT_INCLUDED     = 0,
	INDIRECT_INCLUDE = 1,
	DIRECT_INCLUDE   = 2,
	PUBLIC_INCLUDE   = 4,
	DIRECT_OR_PUBLIC_INCLUDE = DIRECT_INCLUDE + PUBLIC_INCLUDE,
	ANY_INCLUDE = DIRECT_OR_PUBLIC_INCLUDE + INDIRECT_INCLUDE

public sequence SymTab = {}  -- the symbol table

public sequence file_name = {}
public sequence file_include = {{}} -- remember which files were included where
public sequence include_matrix = {{DIRECT_INCLUDE}} -- quicker access to include information
public sequence indirect_include = {{1}}
public sequence file_public = {{}}  -- also remember which files are "public include"d
public sequence file_include_by = {{}}
public sequence file_public_by = {{}}
public sequence preprocessors = {}
public integer force_preprocessor = 0
public sequence LocalizeQual = {}
public sequence LocalDB = "teksto"

public integer AnyTimeProfile      -- time profile option was ever selected 
public integer AnyStatementProfile -- statement profile option was ever selected 

public sequence all_source = {} -- pointers to chunks

public integer usage_shown = 0 -- Indicates if the help/usage text has shown yet.

export function open_locked(sequence file_path)
	integer fh
	
	fh = open(file_path, "u")
	
	if fh = -1 then
		fh = open(file_path, "r")
	end if
	
	return fh
end function

