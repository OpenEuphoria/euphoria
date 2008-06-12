-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- Category: 
--   file
--
-- Title:
--   File/Device I/O
--****

include sort.e
include misc.e
include wildcard.e

constant M_SEEK  = 19,
		 M_WHERE = 20,
		 M_DIR	 = 22,
		 M_CURRENT_DIR = 23,
		 M_ALLOW_BREAK = 42,
		 M_CHECK_BREAK = 43,
		 M_FLUSH = 60,
		 M_LOCK_FILE = 61,
		 M_UNLOCK_FILE = 62,
		 M_CHDIR = 63

type file_number(integer f)
	return f >= 0
end type

type file_position(atom p)
	return p >= -1
end type

type boolean(integer b)
	return b = 0 or b = 1
end type

--**
-- Signature:
-- global constant PATHSEP
--
-- Description:
-- Current platform's path separator character
--
-- Comments:
-- When on DOS32 or WIN32, '\\'. When on LINUX or FREEBSD, '/'.
--
-- Example:
-- x = PATHSEP
-- -- x is '/' or '\\' depending on platform
--**

--**
-- Signature:
-- global constant NL
--
-- Description:
-- Current platforms newline character(s)
--**

global integer PATHSEP
global sequence PATHSEPS
global sequence NL

ifdef UNIX then
	PATHSEP='/'
	PATHSEPS = "/"
	NL = "\n"
else
	PATHSEP='\\'
	PATHSEPS = ":\\/"
	NL = "\r\n"
end ifdef

--**
-- Signature:
-- global function ? object x1
--
-- Description:
-- Shorthand way of saying: <b>pretty_print(1, x, {})</b> - i.e. printing the value of an 
-- expression to the standard output, with braces and indentation to show the structure.
--
-- Example 1:
-- ? {1, 2} + {3, 4}  -- will display {4, 6}
--**

--**
-- Signature:
-- global procedure close(atom fn)
--
-- Description:
-- Close a file or device and flush out any still-buffered characters.
--
-- Comments:
-- Any still-open files will be closed automatically when your program terminates.
--**

--**
-- Signature:
-- global function open(atom st1, sequence st2)
--
-- Description:
-- Open a file or device, to get the file number. -1 is returned if the open fails. st1 is 
-- the path name of the file or device. st2 is the mode in which the file is to be opened. 
-- Possible modes are:
--
-- "r" - open text file for reading
-- "rb" - open binary file for reading
-- "w" - create text file for writing
-- "wb" - create binary file for writing
-- "u" - open text file for update (reading and writing)
-- "ub" - open binary file for update
-- "a" - open text file for appending
-- "ab" - open binary file for appending
--
-- Files opened for read or update must already exist. Files opened for write or append will 
-- be created if necessary. A file opened for write will be set to 0 bytes. Output to a 
-- file opened for append will start at the end of file.
--
-- On DOS or Windows, output to text files will have carriage-return characters automatically 
-- added before linefeed characters. On input, these carriage-return characters are removed. 
-- A control-Z character (ASCII 26) will signal an immediate end of file. Note: on some 
-- versions of DOS, a control-Z typed by the user might cause standard input to permanently 
-- appear to be at the end-of-file, until the DOS window is closed.
--
-- I/O to binary files is not modified in any way. Any byte values from 0 to 255 can be 
-- read or written. On Linux and FreeBSD, all files are binary files, so "r" mode and "rb" 
-- mode are equivalent, as are "w" and "wb", "u" and "ub", and "a" and "ab".
--
-- Some typical devices that you can open on DOS or Windows are:
--
-- "CON" - the console (screen)
-- "AUX" - the serial auxiliary port
-- "COM1" - serial port 1
-- "COM2" - serial port 2
-- "PRN" - the printer on the parallel port
-- "NUL" - a non-existent device that accepts and discards output
--
-- Currently, files up to 2 Gb in size can be handled. Beyond that, some file operations may 
-- not work correctly. This limit will likely be increased in the future. 
--
-- Close a file or device and flush out any still-buffered characters.
--
-- Comments:
-- DOS32:  When running under Windows 95 or later, you can open any existing file that has a 
-- long file or directory name in its path (i.e. greater than the standard DOS 8.3 format) 
-- using any open mode - read, write etc. However, if you try to create a new file (open 
-- with "w" or "a" and the file does not already exist) then the name will be truncated if 
-- necessary to an 8.3 style name. We hope to support creation of new long-filename files in 
-- a future release.
--
-- WIN32, Linux and FreeBSD: Long filenames are fully supported for reading and writing and 
-- creating.
--
-- DOS32: Be careful not to use the special device names in a file name, even if you add an 
-- extension. e.g. CON.TXT, CON.DAT, CON.JPG etc. all refer to the CON device, not a file.
--
-- Example 1:
-- integer file_num, file_num95
-- sequence first_line
-- constant ERROR = 2
--
-- file_num = open("myfile", "r")
-- if file_num = -1 then
--     puts(ERROR, "couldn't open myfile\n")
-- else
--     first_line = gets(file_num)
-- end if
--
-- file_num = open("PRN", "w") -- open printer for output
--
-- -- on Windows 95:
-- file_num95 = open("bigdirectoryname\\verylongfilename.abcdefg",
--                   "r")
-- if file_num95 != -1 then
--     puts(1, "it worked!\n")
-- end if
--**

--**
-- Seek (move) to any byte position in the file fn or to the end of file if a1 is -1. For 
-- each open file there is a current byte position that is updated as a result of I/O 
-- operations on the file. The initial file position is 0 for files opened for read, write 
-- or update. The initial position is the end of file for files opened for append. The value 
-- returned by seek() is 0 if the seek was successful, and non-zero if it was unsuccessful. 
-- It is possible to seek past the end of a file. If you seek past the end of the file, and 
-- write some data, undefined bytes will be inserted into the gap between the original end 
-- of file and your new data.
--
-- Comments:
-- After seeking and reading (writing) a series of bytes, you may need to call seek() 
-- explicitly before you switch to writing (reading) bytes, even though the file position 
-- should already be what you want.
--
-- This function is normally used with files opened in binary mode. In text mode, DOS 
-- converts CR LF to LF on input, and LF to CR LF on output, which can cause great confusion 
-- when you are trying to count bytes. 
--
-- Example 1:
-- include file.e
--
-- integer fn
-- fn = open("mydata", "rb")
-- -- read and display first line of file 3 times:
-- for i = 1 to 3 do
--     puts(1, gets(fn))
--     if seek(fn, 0) then
--         puts(1, "rewind failed!\n")
--     end if
-- end for

global function seek(file_number fn, file_position pos)
-- Seeks to a byte position in the file, 
-- or to end of file if pos is -1.
-- This function is normally used with
-- files opened in binary mode.
	return machine_func(M_SEEK, {fn, pos})
end function
--**

--**
-- This function returns the current byte position in the file fn. This position is updated 
-- by reads, writes and seeks on the file. It is the place in the file where the next byte 
-- will be read from, or written to.

global function where(file_number fn)
-- Returns the current byte position in the file.
-- This function is normally used with
-- files opened in binary mode.
	return machine_func(M_WHERE, fn)
end function
--**

--**
-- When you write data to a file, Euphoria normally stores the data
-- in a memory buffer until a large enough chunk of data has accumulated. 
-- This large chunk can then be written to disk very efficiently. 
-- Sometimes you may want to force, or flush, all data out immediately, 
-- even if the memory buffer is not full. To do this you must call flush(fn),
-- where fn is the file number of a file open for writing or appending.
--
-- Comments:
-- When a file is closed, (see close()), all buffered data is flushed out. 
--  When a program terminates, all open files are flushed and closed 
--  automatically. Use flush() when another process may need to
--  see all of the data written so far, but you aren't ready
--   to close the file yet.
--
-- Example 1:
-- f = open("logfile", "w")
-- puts(f, "Record#1\n")
-- puts(1, "Press Enter when ready\n")
--
-- flush(f)  -- This forces "Record #1" into "logfile" on disk.
--           -- Without this, "logfile" will appear to have 
--           -- 0 characters when we stop for keyboard input.
--
-- s = gets(0) -- wait for keyboard input

global procedure flush(file_number fn)
-- flush out the buffer associated with file fn
	machine_proc(M_FLUSH, fn)
end procedure
--**

global constant LOCK_SHARED = 1, 
				LOCK_EXCLUSIVE = 2
		 
type lock_type(integer t)
	ifdef UNIX then
		return t = LOCK_SHARED or t = LOCK_EXCLUSIVE
	else
		return 1
	end ifdef
end type

type byte_range(sequence r)
	if length(r) = 0 then
		return 1
	elsif length(r) = 2 and r[1] <= r[2] then
		return 1
	else
		return 0
	end if
end type

--**
-- When multiple processes can simultaneously access a
-- file, some kind of locking mechanism may be needed to avoid mangling
-- the contents of the file, or causing erroneous data to be read from the file.
--
-- lock_file() attempts to place a lock on an open file, fn, to stop 
-- other processes from using the file while your program is reading it 
-- or writing it. Under Linux/FreeBSD, there are two types of locks that 
-- you can request using the i2 parameter. (Under DOS32 and WIN32 the i2 parameter
-- is ignored, but should be an integer.)
-- Ask for a <b><i>shared</i></b> lock when you intend to read a file, and you want to 
-- temporarily block other processes from writing it. Ask for an 
-- <b><i>exclusive</i></b> lock 
-- when you intend to write to a file and you want to temporarily block other 
-- processes from reading or writing it. It's ok for many processes to 
-- simultaneously have shared locks on the same file, but only one process 
-- can have an exclusive lock, and that can happen only when no other 
-- process has any kind of lock on the file. file.e contains the following
-- declaration:
-- 
-- <eucode>
-- global constant LOCK_SHARED = 1, 
-- 		LOCK_EXCLUSIVE = 2
-- </eucode>
--
-- On DOS32 and WIN32 you can lock a specified portion of a file using the s parameter. 
-- s is a sequence of the form: {first_byte, last_byte}. It indicates the first byte and 
-- last byte in the file,  that the lock applies to. Specify the empty sequence {}, 
-- if you want to lock the whole file. In the current release for Linux/FreeBSD, locks 
-- always apply to the whole file, and you should specify {}
-- for this parameter.
-- 
-- If it is successful in obtaining the desired lock, lock_file() will return 1. If 
-- unsuccessful, it will return 0. lock_file() does not wait
-- for other processes to relinquish their locks. You may have to call it repeatedly, 
-- before the lock request is granted.
--
-- Comments:
-- On Linux/FreeBSD, these locks are called advisory locks, which means they aren't enforced 
-- by the operating system. It is up to the processes that use a particular file to cooperate 
-- with each other. A process can access a file without first obtaining a lock on it. On 
-- WIN32 and DOS32, locks are enforced by the operating system.
--
-- 	On DOS32, lock_file() is more useful when file sharing is enabled. It will typically 
-- return 0 (unsuccessful) under plain MS-DOS, outside of Windows.
--
-- Example 1:
-- include misc.e
-- include file.e
-- integer v
-- atom t
-- v = open("visitor_log", "a")  -- open for append
-- t = time()
-- while not lock_file(v, LOCK_EXCLUSIVE, {}) do
--     if time() > t + 60 then
--         puts(1, "One minute already ... I can't wait forever!\n")
--         abort(1)
--     end if
--     sleep(5) -- let other processes run
-- end while
-- puts(v, "Yet another visitor\n")
-- unlock_file(v, {})
-- close(v)

global function lock_file(file_number fn, lock_type t, byte_range r)
-- Attempt to lock a file so other processes won't interfere with it.
-- The byte range can be {} if you want to lock the whole file
	return machine_func(M_LOCK_FILE, {fn, t, r})
end function
--**

--**
-- Unlock an open file fn, or a portion of file fn. You must have previously locked the 
-- file using lock_file(). On DOS32 and WIN32 you can unlock a range of bytes within a 
-- file by specifying the s parameter as {first_byte, last_byte}. The same range of bytes 
-- must have been locked by a previous call to lock_file(). On Linux/FreeBSD you can 
-- currently only lock or unlock an entire file. The s parameter should be {} when you 
-- want to unlock an entire file. On Linux/FreeBSD, s must always be {}.
--
-- Comments:
--  You should unlock a file as soon as possible so other processes can use it.
--
-- 	Any files that you have locked, will automatically be unlocked when your program 
--  terminates.
--
-- 	See lock_file() for further comments and an example.
--

global procedure unlock_file(file_number fn, byte_range r) 
-- The byte range can be {} if you want to unlock the whole file.
	machine_proc(M_UNLOCK_FILE, {fn, r})
end procedure
--**

global constant 
		D_NAME = 1,
		D_ATTRIBUTES = 2,
		D_SIZE = 3,

		D_YEAR = 4,
		D_MONTH = 5,
		D_DAY = 6,

		D_HOUR = 7,
		D_MINUTE = 8,
		D_SECOND = 9

--**
-- Return directory information for the file or directory named by
--  st. If there is no file or directory with this name then -1 is
--  returned. st can also contain * and ? wildcards to select multiple
--  files.
--
-- Comments:
-- This information is similar to what you would get from the DOS DIR command. A sequence 
-- is returned where each element is a sequence that describes one file or subdirectory.
-- 
-- If st names a <b>directory</b> you may have entries for "." and "..,"
--  just as with the DOS DIR command. If st names a <b>file</b> then x will
--  have just one entry, i.e. <a href="lib_seq.htm#length">length(x)</a> will
--  be 1. If st contains wildcards you may have multiple entries.
-- 
-- Each entry contains the name, attributes and file size as well as
--  the year, month, day, hour, minute and second of the last modification.
--  You can refer to the elements of an entry with the following constants
--  defined in <path>file.e</path>:
--  
-- <eucode>
--     global constant D_NAME = 1,
--               D_ATTRIBUTES = 2,
--                     D_SIZE = 3,

--                     D_YEAR = 4,
--                    D_MONTH = 5,
--                      D_DAY = 6,

--                     D_HOUR = 7,
--                   D_MINUTE = 8,
--                   D_SECOND = 9
-- </eucode>
--
-- The attributes element is a string sequence containing characters chosen from:
--  
-- <eucode>
--     'd' -- directory
--     'r' -- read only file
--     'h' -- hidden file
--     's' -- system file
--     'v' -- volume-id entry
--     'a' -- archive file
-- </eucode>
--
-- A normal file without special attributes would just have an empty string, "", in this field.
--
-- The top level directory, e.g. c:\ does not have "." or ".." entries.
-- 
-- This function is often used just to test if a file or
--  directory exists.
-- 
-- Under <platform>WIN32</platform>, st can have a long file or directory name anywhere in 
-- the path.
-- 
-- Under <platform>Linux/FreeBSD</platform>, the only attribute currently available is 'd'.
-- 
-- <platform>DOS32</platform>: The file name returned in D_NAME will be a standard DOS 8.3 
-- name. (See 
-- <a href="http://www.rapideuphoria.com/cgi-bin/asearch.exu?dos=on&keywords=dir">Archive
--  Web page</a> for a better solution).
-- 
-- <platform>WIN32</platform>: The file name returned in D_NAME will be a long file name.
--
-- <eucode>
-- d = dir(current_dir())
--
-- -- d might have:
--   {
--     {".",    "d",     0  1994, 1, 18,  9, 30, 02},
--     {"..",   "d",     0  1994, 1, 18,  9, 20, 14},
--     {"fred", "ra", 2350, 1994, 1, 22, 17, 22, 40},
--     {"sub",  "d" ,    0, 1993, 9, 20,  8, 50, 12}
--   }
--
-- d[3][D_NAME] would be "fred"
--  </eucode>
-- 
-- Example:
-- See <path>bin\search.ex</path>

global function dir(sequence name)
	object dir_data, data, the_name, the_dir
	integer idx

	-- Did the user give a wildcard? If not, just return the standard dir.
	if find('*', name) > 0 or find('?', name) > 0 then
		-- Empty if so that we can short circuit if * is found, otherwise
		-- we would have to run a search for * and ? even if * is found.
	else
		return machine_func(M_DIR, name)
	end if

	-- Is there a path involved?
	if find('/', name) = 0 and find('\\', name) = 0 then
		the_dir = "."
		the_name = name
	else
		-- Find a PATHSEP character and break the name there resulting in
		-- a directory and file name.
		idx = length(name)
		while idx > 0 do
			ifdef WIN32 then
				if name[idx] = '\\' then
					exit
				end if
			end ifdef
			if name[idx] = '/' then
				exit
			end if
			idx -= 1
		end while

		the_dir = name[1..idx]
		the_name = name[idx+1..$]
	end if

	-- Get directory contents
	dir_data = machine_func(M_DIR, the_dir)

	-- Did an error occur?
	if atom(dir_data) then
		return dir_data
	end if

	data = {}
	-- Filter the directory contents returning only those items
	-- matching name.
	for i = 1 to length(dir_data) do
		if wildcard_file(the_name, dir_data[i][1]) then
				data = append(data, dir_data[i])
		end if
	end for

	return data
end function
--**

--**
-- Return the name of the current working directory
--
-- Comments:
-- There will be no slash or backslash on the end of the current directory, except under
-- DOS/Windows, at the top-level of a drive, e.g. C:\
--
-- Example 1:
-- sequence s
-- s = current_dir()
-- -- s would have "C:\EUPHORIA\DOC" if you were in that directory

global function current_dir()
-- returns name of current working directory
	return machine_func(M_CURRENT_DIR, 0)
end function
--**

--**
-- Set the current directory to the path given by sequence s. s must name
--  an existing directory on the system. If successful, chdir() returns 1. 
--  If unsuccessful, chdir() returns 0.
--
-- Comments:
-- By setting the current directory, you can refer to files in that directory using just 
-- the file name.
-- 
-- The function current_dir() will return the name of the current directory.
-- 
-- On DOS32 and WIN32 the current directory is a global property shared
-- by all the processes running under one shell. On Linux/FreeBSD, a subprocess
-- can change the current directory for itself, but this won't
-- affect the current directory of its parent process.
--
-- Example 1:
-- if chdir("c:\\euphoria") then
--     f = open("readme.doc", "r")
-- else
--     puts(1, "Error: No euphoria directory?\n")
-- end if

global function chdir(sequence newdir)
-- Changes the current directory. Returns 1 - success, 0 - fail.
	return machine_func(M_CHDIR, newdir)
end function
--**

--**
-- Set behavior of CTRL+C/CTRL+Break
--
-- Comments:
-- When i is 1 (true) CTRL+C and CTRL+Break can terminate
-- your program when it tries to read input from the keyboard. When
-- i is 0 (false) your program will not be terminated by CTRL+C or CTRL+Break.
--
-- DOS will display ^C on the screen, even when your program cannot be terminated.
-- 
-- Initially your program can be terminated at any point where
--  it tries to read from the keyboard. It could also be terminated
--  by other input/output operations depending on options the user
--  has set in his <b>config.sys</b> file. (Consult an MS-DOS manual for the BREAK
--  command.) For some types of program this sudden termination could leave
--  things in a messy state and might result in loss of data.
--  allow_break(0) lets you avoid this situation.
-- 
-- You can find out if the user has pressed control-c or control-Break by calling 
-- check_break().
--
-- Example 1:
-- allow_break(0)  -- don't let the user kill the program!

global procedure allow_break(boolean b)
-- If b is TRUE then allow control-c/control-break to
-- terminate the program. If b is FALSE then don't allow it.
-- Initially they *will* terminate the program, but only when it
-- tries to read input from the keyboard.
	machine_proc(M_ALLOW_BREAK, b)
end procedure
--**

--**
-- Return the number of times that CTRL+C or CTRL+Break have
--  been pressed since the last call to check_break(), or since the
--  beginning of the program if this is the first call.
--
-- Comments:
-- This is useful after you have called allow_break(0) which
--  prevents CTRL+C or CTRL+Break from terminating your
--  program. You can use check_break() to find out if the user
--  has pressed one of these keys. You might then perform some action
--  such as a graceful shutdown of your program.
-- 
-- Neither CTRL+C or CTRL+Break will be returned as input
--  characters when you read the keyboard. You can only detect
--  them by calling check_break().
--
-- Example 1:
-- k = get_key()
-- if check_break() then
--     temp = graphics_mode(-1)
--     puts(1, "Shutting down...")
--     save_all_user_data()
--     abort(1)
-- end if

global function check_break()
-- returns the number of times that control-c or control-break
-- were pressed since the last time check_break() was called
	return machine_func(M_CHECK_BREAK, 0)
end function
--**

-- Generalized recursive directory walker

global constant W_BAD_PATH = -1 -- error code

function default_dir(sequence path)
-- Default directory sorting function for walk_dir().
-- * sorts by name *
	object d
	
	d = dir(path)
	if atom(d) then
		return d
	else
		-- sort by name
		return sort(d)
	end if
end function

-- override the dir sorting function with your own routine id
constant DEFAULT = -2
global integer my_dir 
my_dir = DEFAULT  -- it's better not to use routine_id() here,
				  -- or else users will have to bind with clear routine names

--**
-- Generalized Directory Walker
-- This routine will "walk" through a directory with path name given by st. i2 is the 
-- routine id of a routine that you supply. walk_dir() will call your routine once for 
-- each file and subdirectory in st. If i3 is non-zero (TRUE), then the subdirectories in 
-- st will be walked through recursively.
--
-- The routine that you supply should accept the path name and dir() entry for each file and 
-- subdirectory. It should return 0 to keep going, or non-zero to stop walk_dir(). 
--
-- Comments:
-- This mechanism allows you to write a simple function that handles one file at a time, 
-- while walk_dir() handles the process of walking through all the files and subdirectories.

-- By default, the files and subdirectories will be visited in alphabetical order. To use 
-- a different order, set the global integer my_dir to the routine id of your own modified 
-- dir() function that sorts the directory entries differently. See the default dir() 
-- function in file.e.

-- The path that you supply to walk_dir() must not contain wildcards (* or ?). Only a 
-- single directory (and its subdirectories) can be searched at one time. --
--
-- Example 1:
-- function look_at(sequence path_name, sequence entry)
-- -- this function accepts two sequences as arguments
--     printf(1, "%s\\%s: %d\n",
--            {path_name, entry[D_NAME], entry[D_SIZE]})
--     return 0 -- keep going
-- end function
--
-- exit_code = walk_dir("C:\\MYFILES", routine_id("look_at"), TRUE)
--
-- Example 2:
-- See <path>bin\search.ex</path>

global function walk_dir(sequence path_name, object your_function, 
						 integer scan_subdirs)
	object d, abort_now
	object orig_func
	object user_data
	
	orig_func = your_function
	if sequence(your_function) then
		user_data = your_function[2]
		your_function = your_function[1]
	end if
	-- get the full directory information
	if my_dir = DEFAULT then
		d = default_dir(path_name)
	else
		d = call_func(my_dir, {path_name})
	end if
	if atom(d) then
		return W_BAD_PATH
	end if
	
	-- trim any trailing blanks or '\' characters from the path
	while length(path_name) > 0 and 
		  find(path_name[$], {' ', PATHSEP}) do
		path_name = path_name[1..$-1]
	end while
	
	for i = 1 to length(d) do
		if find('d', d[i][D_ATTRIBUTES]) then
			-- a directory
			if not find(d[i][D_NAME], {".", ".."}) then
				if atom(orig_func) then
					abort_now = call_func(your_function, {path_name, d[i]})
				else
					abort_now = call_func(your_function, {path_name, d[i], user_data})
				end if
				if not equal(abort_now, 0) then
					return abort_now
				end if
				if scan_subdirs then
					abort_now = walk_dir(path_name & PATHSEP & d[i][D_NAME],
										 orig_func, scan_subdirs)
					
					if not equal(abort_now, 0) and 
					   not equal(abort_now, W_BAD_PATH) then
						-- allow BAD PATH, user might delete a file or directory 
						return abort_now
					end if
				end if
			end if
		else
			-- a file
			if atom(orig_func) then
				abort_now = call_func(your_function, {path_name, d[i]})
			else
				abort_now = call_func(your_function, {path_name, d[i], user_data})
			end if
			if not equal(abort_now, 0) then
				return abort_now
			end if
		end if
	end for
	return 0
end function
--**

--**
-- Read the contents of either file named s1 or an open file handle i1 as a sequence of lines.
--
-- Example 1:
-- data = read_lines("myfile.txt")
-- -- data contains the entire contents of 'myfile.txt', 1 sequence per line:
-- -- {"Line 1", "Line 2", "Line 3"}
--
-- Example 2:
-- fh = open("myfile.txt", "r")
-- data = read_lines(fh)
-- close(fh)
--
-- -- data contains the entire contents of 'myfile.txt', 1 sequence per line:
-- -- {"Line 1", "Line 2", "Line 3"}

global function read_lines(object f)
	object fn, ret, y
	if sequence(f) then
			fn = open(f, "r")
	else
			fn = f
	end if
	if fn < 0 then return -1 end if
	
	ret = {}
	while sequence(y) entry do
		if y[$] = '\n' then
			y = y[1..$-1]
		end if
		ret = append(ret, y)
	entry
		y = gets(fn)
	end while
	
	if sequence(f) then
			close(fn)
	end if
	return ret
end function
--**

--**
-- Write lines contained in s to file named x or file handle x. Returns 1 on success, -1 
-- on failure.
--
-- Comments:
-- If x is an atom, it is assumed to be an open file handle. If x is a sequence, it is assumed
-- to be a filename.
--
-- When x is a file handle, the file is not closed after writing is finished. When x is a
-- file name, it is opened, written to and then closed.
--
-- Example 1:
-- if write_lines("data.txt", {"This is important data", "Goodybe"}) != -1 then
--     puts(1, "Failed to write data\n")
-- end if
--
-- See Also:
--     read_lines, write_file

global function write_lines(object f, sequence lines)
	object fn

	if sequence(f) then
    	fn = open(f, "w")
	else
		fn = f
	end if
	if fn < 0 then return -1 end if

	for i = 1 to length(lines) do
		puts(fn, lines[i])
		puts(fn, '\n')
	end for

	if sequence(f) then
		close(fn)
	end if

	return 1
end function
--**

--**
-- Append lines contained in s2 to file named s1. Returns 1 on success, -1 on failure.
--
-- Comments:
-- s1 is a filename.
--
-- It is opened, written to and then closed.
--
-- Example 1:
-- if append_lines("data.txt", {"This is important data", "Goodbye"}) != -1 then
--     puts(1, "Failed to append data\n")
-- end if
--
-- See Also:
--     write_lines

global function append_lines(sequence f, sequence lines)
	object fn

  	fn = open(f, "a")
	if fn < 0 then return -1 end if

	for i = 1 to length(lines) do
		puts(fn, lines[i])
		puts(fn, '\n')
	end for

	close(fn)

	return 1
end function
--**

--**
-- Read the contents of either file named s1 or an open file handle i1. Returns the contents 
-- as 1 sequence.
--
-- Example 1:
-- data = read_file("myfile.txt")
-- -- data contains the entire contents of 'myfile.txt'
--
-- Example 2:
-- fh = open("myfile.txt", "r")
-- data = read_file(fh)
-- close(fh)
--
-- -- data contains the entire contents of 'myfile.txt'
--
-- See Also:
--     write_file, read_lines

global function read_file(object f)
	integer fn
	integer len
	sequence ret
	integer temp

	if sequence(f) then
		fn = open(f, "rb")
	else
		fn = f
	end if
	if fn < 0 then return -1 end if
	
	temp = seek(fn, -1) 	
	len = where(fn)
	temp = seek(fn, 0)

	ret = repeat(0, len)	
	for i = 1 to len do
		ret[i] = getc(fn)
	end for
		
	if sequence(f) then
		close(fn)
	end if

	return ret
end function
--**

--**
-- Write data to file named f or file handle f. Returns 1 on success, 0 on failure.
--
-- Comments:
-- If x is an atom, it is assumed to be an open file handle. If x is a sequence, it is 
-- assumed to be a filename.
--
-- When x is a file handle, the file is not closed after writing is finished. When x is a 
-- file name, it is opened, written to and then closed.
--
-- Example 1:
-- if write_file("data.txt", "This is important data\nGoodybe") = 0 then
--     puts(1, "Failed to write data\n")
-- end if
--
-- See Also:
--    read_file, write_lines

global function write_file(object f, sequence data)
	integer fn

	if sequence(f) then
		fn = open(f, "wb")
	else
		fn = f
	end if
	if fn < 0 then return -1 end if
	
	puts(fn, data)

	if sequence(f) then
		close(fn)
	end if

	return 1
end function
--**

--**
-- Parse the fully qualified pathname (s1) and return a sequence containing directory name, 
-- file name + file extension, file name and file extension.
--
-- Comments:
-- The host operating system path separator is used.
--
-- Example 1:
-- -- DOS32/WIN32
-- info = pathinfo("C:\\euphoria\\docs\\readme.txt")
-- -- info is {"C:\\euphoria\\docs", "readme.txt", "readme", "txt"}
--
-- Example 2:
-- -- Linux/FreeBSD
-- info = pathinfo("/opt/euphoria/docs/readme.txt")
-- -- info is {"/opt/euphoria/docs", "readme.txt", "readme", "txt"}
--
-- Example 3:
-- -- no extension
-- info = pathinfo("/opt/euphoria/docs/readme")
-- -- info is {"/opt/euphoria/docs", "readme", "readme", ""}
--
-- See Also:
--   driveid, dirname, filename, fileext

global function pathinfo(sequence path)
	integer slash, period, ch
	sequence dir_name, file_name, file_ext, file_full, drive_id

	dir_name  = ""
	file_name = ""
	file_ext  = ""
	file_full = ""
	drive_id  = ""

	slash = 0
	period = 0

	for i = length(path) to 1 by -1 do
		ch = path[i]
		if period = 0 and ch = '.' then
			period = i
		elsif find(ch, PATHSEPS) then
			slash = i
			exit
		end if
	end for

	if slash > 0 then
		dir_name = path[1..slash-1]
		
		ifdef !UNIX then
			ch = find(':', dir_name)
			if ch != 0 then
				drive_id = dir_name[1..ch-1]
				dir_name = dir_name[ch+1..$]
			end if
		end ifdef
	end if
	if period > 0 then
		file_name = path[slash+1..period-1]
		file_ext = path[period+1..$]
		file_full = file_name & '.' & file_ext
	else
		file_name = path[slash+1..$]
		file_full = file_name
	end if

	return {dir_name, file_full, file_name, file_ext, drive_id}
end function
--**

--**
-- Return the directory name of a fully qualified filename
--
-- Comments:
-- The host operating system path separator is used.
--
-- Example 1:
-- fname = dirname("/opt/euphoria/docs/readme.txt")
-- -- fname is "/opt/euphoria/docs"
--
-- See Also:
--   driveid, filename, fileext

global function dirname(sequence path)
	sequence data
	data = pathinfo(path)
	return data[1]
end function
--**

--**
-- Return the file name portion of a fully qualified filename
--
-- Comments:
-- The host operating system path separator is used.
--
-- Example 1:
-- fname = filename("/opt/euphoria/docs/readme.txt")
-- -- fname is "readme.txt"
--
-- See Also:
--   driveid, dirname, fileext
  
global function filename(sequence path)
	sequence data

	data = pathinfo(path)

	return data[2]
end function
--**

-- TODO: test, document
global function filebase(sequence path)
	sequence data

	data = pathinfo(path)

	return data[3]
end function

--**
-- Return the file extension of a fully qualified filename
--
-- Comments:
-- The host operating system path separator is used.
--
-- Example 1:
-- fname = fileext("/opt/euphoria/docs/readme.txt")
-- -- fname is "txt"
--
-- See Also:
--     driveid, dirname, filename, filebase

global function fileext(sequence path)
	sequence data
	data = pathinfo(path)
	return data[4]
end function
--**

-- TODO: document, test
global function driveid(sequence path)
	sequence data
	data = pathinfo(path)
	return data[5]
end function

