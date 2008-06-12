-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- Category:
--    filesys
--
-- Title:
--    File System
--****
--
-- cross platform file operations for Euphoria

-- TODO: Add unit tests

include dll.e
include file.e
include machine.e

object slash

slash = '\\' -- for Windows/DOS. For Linux is defined below.

object xCopyFile, xMoveFile, xDeleteFile, xCreateDirectory, xRemoveDirectory
if platform() = WIN32 then
	xCopyFile         = define_c_func(open_dll("kernel32"), "CopyFileA", 
		{C_POINTER, C_POINTER, C_LONG}, C_LONG)
	xMoveFile         = define_c_func(open_dll("kernel32"), "MoveFileA", 
		{C_POINTER, C_POINTER}, C_LONG)
	xDeleteFile       = define_c_func(open_dll("kernel32"), "DeleteFileA", {C_POINTER}, C_LONG)
	xCreateDirectory  = define_c_func(open_dll("kernel32"), "CreateDirectoryA", 
		{C_POINTER, C_POINTER}, C_LONG)
	xRemoveDirectory  = define_c_func(open_dll("kernel32"), "RemoveDirectoryA", 
		{C_POINTER}, C_LONG)
elsif platform() = LINUX then
	slash = '/'
	xMoveFile   = define_c_func(open_dll(""), "rename", {C_POINTER, C_POINTER}, C_LONG)
	xDeleteFile = define_c_func(open_dll(""), "remove", {C_POINTER}, C_LONG)
end if

---------------------------------------------------------------------
--# File Operations
---------------------------------------------------------------------

--**
-- copy a file from src to dest.
--
-- Comments:
-- If overwrite is true, if dest file already exists, 
-- the function overwrites the existing file and succeeds.
-- Returns false if failed, true if succeeded.
--
global function copy_file(sequence src, sequence dest, atom overwrite)
	atom psrc, pdest, ret
	psrc = allocate_string(src)
	pdest = allocate_string(dest)
	ret = c_func(xCopyFile, {psrc, pdest, not overwrite})
	free(pdest)
	free(psrc)
	return ret
end function
--**

--**
-- move/rename a file from src to dest.
--
-- Comments:
-- Returns false if failed, true if succeeded.
global function move_file(sequence src, sequence dest)
	atom psrc, pdest, ret
	psrc = allocate_string(src)
	pdest = allocate_string(dest)
	ret = c_func(xMoveFile, {psrc, pdest})
	if platform() = LINUX then ret = not ret end if
	free(pdest)
	free(psrc)
	return ret
end function
--**

--**
-- delete a file named filename
--
-- Comments:
-- Returns false if failed, true if succeeded.
global function delete_file(sequence filename)
	atom pfilename, ret
	pfilename = allocate_string(filename)
	ret = c_func(xDeleteFile, {pfilename})
	if platform() = LINUX then ret = not ret end if
	free(pfilename)
	return ret
end function
--**

--**
-- create a directory named name
--
-- Comments:
-- Returns false if failed, true if succeeded.
global function create_directory(sequence name)
	atom pname, ret
	pname = allocate_string(name)
	ret = c_func(xCreateDirectory, {pname, 0})
	free(pname)
	return ret
end function
--**

--**
-- remove a directory named name
--
-- Comments:
-- Returns false if failed, true if succeeded.
global function remove_directory(sequence name)
	atom pname, ret
	pname = allocate_string(name)
	ret = c_func(xRemoveDirectory, {pname})
	free(pname)
	return ret
end function
--**

---------------------------------------------------------------------
--# File I/O
---------------------------------------------------------------------

--**
-- return length of file filename.
--
-- Comments:
-- if not found, returns -1
global function file_length(sequence filename)
	object list
	list = dir(filename)
	if atom(list) or length(list) = 0 then
		return -1
	end if
	return list[1][D_SIZE]
end function
--**

--**
-- returns the type of the file specified
-- 
-- Comments:
-- returns 0 if filename does not exist
-- returns 1 if filename is a file
-- returns 2 if filename is a directory
global function file_type(sequence filename)
object dirfil
	if find('*', filename) or find('*', filename) then return 0 end if
	
	if length(filename) = 2 and filename[2] = ':' then
		filename &= "\\"
	end if
	
	dirfil = dir(filename)
	if sequence(dirfil) then
		if find('d', dirfil[1][2]) or (length(filename)=3 and filename[2]=':') then
			return 2
		else
			return 1
		end if
	else
		return 0
	end if
end function
--**

