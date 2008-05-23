-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.1
-- Directory and File Operations --

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

global integer PATHSEP
global sequence NL

if platform() = LINUX then
	PATHSEP='/'
	NL = "\n"
else
	PATHSEP='\\'
	NL = "\r\n"
end if

global function seek(file_number fn, file_position pos)
-- Seeks to a byte position in the file, 
-- or to end of file if pos is -1.
-- This function is normally used with
-- files opened in binary mode.
	return machine_func(M_SEEK, {fn, pos})
end function

global function where(file_number fn)
-- Returns the current byte position in the file.
-- This function is normally used with
-- files opened in binary mode.
	return machine_func(M_WHERE, fn)
end function

global procedure flush(file_number fn)
-- flush out the buffer associated with file fn
	machine_proc(M_FLUSH, fn)
end procedure

global constant LOCK_SHARED = 1, 
				LOCK_EXCLUSIVE = 2
		 
type lock_type(integer t)
	if platform() = LINUX then
		return t = LOCK_SHARED or t = LOCK_EXCLUSIVE
	else
		return 1
	end if
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

global function lock_file(file_number fn, lock_type t, byte_range r)
-- Attempt to lock a file so other processes won't interfere with it.
-- The byte range can be {} if you want to lock the whole file
	return machine_func(M_LOCK_FILE, {fn, t, r})
end function

global procedure unlock_file(file_number fn, byte_range r) 
-- The byte range can be {} if you want to unlock the whole file.
	machine_proc(M_UNLOCK_FILE, {fn, r})
end procedure

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

global function dir(sequence name)
-- returns directory information, given the name
-- of a file or directory. Format returned is:
-- {
--	{"name1", attributes, size, year, month, day, hour, minute, second},
--	{"name2", ...													  },
-- }
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
			if name[idx] = '/' or name[idx] = '\\' then
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

global function current_dir()
-- returns name of current working directory
	return machine_func(M_CURRENT_DIR, 0)
end function

global function chdir(sequence newdir)
-- Changes the current directory. Returns 1 - success, 0 - fail.
	return machine_func(M_CHDIR, newdir)
end function

global procedure allow_break(boolean b)
-- If b is TRUE then allow control-c/control-break to
-- terminate the program. If b is FALSE then don't allow it.
-- Initially they *will* terminate the program, but only when it
-- tries to read input from the keyboard.
	machine_proc(M_ALLOW_BREAK, b)
end procedure

global function check_break()
-- returns the number of times that control-c or control-break
-- were pressed since the last time check_break() was called
	return machine_func(M_CHECK_BREAK, 0)
end function

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

global function walk_dir(sequence path_name, object your_function, 
						 integer scan_subdirs)
-- Generalized Directory Walker
-- Walk through a directory and (optionally) its subdirectories,
-- "visiting" each file and subdirectory. Your function will be called
-- via its routine id. The visits will occur in alphabetical order.
-- Your function should accept the path name and dir() entry for
-- each file and subdirectory. It should return 0 to keep going,
-- or an error code (greater than 0) to quit, or it can return
-- any sequence or atom other than 0 as a useful diagnostic value.
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

global function read_lines(object f)
	object fn, ret, y
	if sequence(f) then
			fn = open(f, "r")
	else
			fn = f
	end if
	if fn < 0 then return -1 end if
	
	ret = {}
	y = gets(fn)
	while sequence(y) do
		if y[$] = '\n' then
			y = y[1..$-1]
		end if
		ret = append(ret, y)
		y = gets(fn)
	end while
	
	if sequence(f) then
			close(fn)
	end if
	return ret
end function

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

	for i = 1 to length(path) do
		ch = path[i]
		if ch = '.' then
			period = i
		elsif ch = PATHSEP then
			slash = i
			period = -1  -- extension has to be part of the filename
		end if
	end for

	if slash > 0 then
		dir_name = path[1..slash-1]
		if platform() != LINUX then
			ch = find(':', dir_name)
			if ch != 0 then
				drive_id = dir_name[1..ch-1]
				dir_name = dir_name[ch+1..$]
			end if
		end if
	else
		slash = 0
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

global function dirname(sequence path)
	sequence data
	data = pathinfo(path)
	return data[1]
end function

global function filename(sequence path)
	sequence data

	data = pathinfo(path)

	return data[2]
end function

global function filebase(sequence path)
	sequence data

	data = pathinfo(path)

	return data[3]
end function

global function fileext(sequence path)
	sequence data
	data = pathinfo(path)
	return data[4]
end function

global function driveid(sequence path)
	sequence data
	data = pathinfo(path)
	return data[5]
end function
