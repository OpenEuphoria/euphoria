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
include std/filesys.e
include std/search.e
public include std/types.e

public constant
	NOT_INCLUDED     = 0,
	INDIRECT_INCLUDE = 1,
	DIRECT_INCLUDE   = 2,
	PUBLIC_INCLUDE   = 4,
	DIRECT_OR_PUBLIC_INCLUDE = DIRECT_INCLUDE + PUBLIC_INCLUDE,
	ANY_INCLUDE = DIRECT_OR_PUBLIC_INCLUDE + INDIRECT_INCLUDE

public sequence SymTab = {}  -- the symbol table

public sequence known_files = {}
public sequence known_files_hash = {}
public sequence finished_files = {}
public sequence file_include_depend = {}
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

object eudir = 0
integer cmdline_eudir = 0

export function open_locked(sequence file_path)
	integer fh

	fh = open(file_path, "u")

	if fh = -1 then
		fh = open(file_path, "r")
	end if

	return fh
end function

--**
-- Get the EUDIR
--
-- Search:
--   * $EUDIR
--   * Unix:
--   ** /usr/local/share/euphoria
--   ** /usr/share/euphoria
--   ** /opt/euphoria
--   ** $HOME/euphoria
--   * Windows:
--   ** C:/Program Files (x86)/Euphoria
--   ** C:/Program Files/Euphoria
--   ** C:/euphoria
--   ** $HOME/euphoria
--

public function get_eudir()
	if sequence(eudir) then
		return eudir
	end if

	eudir = getenv("EUDIR")
	if sequence(eudir) then
		return eudir
	end if

	ifdef UNIX then
		sequence possible_paths = {
			"/usr/local/share/euphoria",
			"/usr/share/euphoria",
			"/opt/euphoria"
		}
		object home = getenv("HOME")
		if sequence(home) then
			possible_paths = append(possible_paths, home & "/euphoria")
		end if
	elsedef
		sequence possible_paths = {
			"C:\\Program Files (x86)\\Euphoria",
			"C:\\Program Files\\Euphoria",
			"C:\\Euphoria"
		}
		object homepath = getenv("HOMEPATH")
		object homedrive = getenv("HOMEDRIVE")
		if sequence(homepath) and sequence(homedrive) then
			if length(homepath) and not equal(homepath[$], SLASH) then
				homepath &= SLASH
			end if

			possible_paths = append(possible_paths, homedrive & SLASH & homepath & "euphoria")
		end if
	end ifdef

	for i = 1 to length(possible_paths) do
		sequence possible_path = possible_paths[i]

		if file_exists(possible_path & SLASH & "include" & SLASH & "euphoria.h") then
			eudir = possible_path
			return eudir
		end if
	end for

	possible_paths = include_paths(0)
	for i = 1 to length(possible_paths) do
		sequence possible_path = possible_paths[i]
		if equal(possible_path[$], SLASH) then
			possible_path = possible_path[1..$-1]
		end if

		if not ends("include", possible_path) then
			continue
		end if

		sequence file_check = possible_path
		file_check &= SLASH & "euphoria.h"

		if file_exists(file_check) then
			eudir = possible_path[1..$-8] -- strip SLASH & "include"
			return eudir
		end if
	end for

	return ""
end function

public procedure set_eudir( sequence new_eudir )
	eudir = new_eudir
	cmdline_eudir = 1
end procedure

public function is_eudir_from_cmdline()
	return cmdline_eudir
end function
