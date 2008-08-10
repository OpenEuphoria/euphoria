-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Operating System Helpers
--
-- <<LEVELTOC depth=2>>
--

include sequence.e

include text.e

ifdef !DOS32 then
	include dll.e
end ifdef

ifdef DOS32 then
	export include dos\memory.e
	include dos\interrup.e
end ifdef

include machine.e

constant
	M_SLEEP = 64, 
	M_SET_ENV = 73, 
	M_UNSET_ENV = 74

--****
-- ==== Operating System Constants
--

--**
-- These constants are returned by the [[:platform]] function.
--
-- * DOS32 - Host operating system is DOS
-- * WIN32 - Host operating system is Windows
-- * LINUX - Host operating system is Linux **or** FreeBSD
-- * FREEBSD - Host operating system is Linux **or** FreeBSD
-- * OSX - Host operating system is Mac OS X
--
-- Note:
-- Via the [[:platform]] call, there is no way to determine if you are on Linux
-- or FreeBSD. This was done to provide a generic UNIX return value for
-- [[:platform]].
--
-- In most situations you are better off to test the host platform by using
-- the [[:ifdef statement]]. It is both more accurate and faster.
--

export constant
	DOS32	= 1, -- ex.exe
	WIN32	= 2, -- exw.exe
	LINUX	= 3, -- exu
	FREEBSD = 3, -- exu
	OSX		= 4  -- exu

export constant
	NO_PARAMETER = 0,
	HAS_PARAMETER = 1,
	NO_CASE = 0,
	HAS_CASE = 1

enum
	SINGLE,
	DOUBLE,
	HELP,
	PARAM,
	RID
--	USECASE

--****
-- === Command line utilities.

--**
-- Signature:
-- global procedure command_line()
--
-- Description:
-- A **sequence** of strings, where each string is a word from the command-line that started your program.
--
-- Comments:
--
-- The returned sequence contains the following information:
-- # Tthe path to either the Euphoria executable, ex.exe, exw.exe or exu, or to your bound executable file.
-- # The next word is either the name of your Euphoria main file, or 
-- (again) the path to your bound executable file.
-- # Any extra words typed by the user. You can use these words in your program.
--
-- There are as many entries as words, plus the two mentioned above.
--
-- The Euphoria interpreter itself does not use any command-line options. You are free to use
-- any options for your own program. It does have [[:command line switches]] though.
--
-- The user can put quotes around a series of words to make them into a single argument.
--
-- If you convert your program into an executable file, either by binding it, or translating it to C, 
-- you will find that all command-line arguments remain the same, except for the first two, 
-- even though your user no longer types "ex" on the command-line (see examples below).
--  
-- Example 1:
-- <eucode>  
--  -- The user types:  ex myprog myfile.dat 12345 "the end"
-- 
-- cmd = command_line()
-- 
-- -- cmd will be:
--       {"C:\EUPHORIA\BIN\EX.EXE",
--        "myprog",
--        "myfile.dat",
--        "12345",
--        "the end"}
-- </eucode>
--
-- Example 2:  
-- <eucode>  
--  -- Your program is bound with the name "myprog.exe"
-- -- and is stored in the directory c:\myfiles
-- -- The user types:  myprog myfile.dat 12345 "the end"
-- 
-- cmd = command_line()
-- 
-- -- cmd will be:
--        {"C:\MYFILES\MYPROG.EXE",
--         "C:\MYFILES\MYPROG.EXE", -- place holder
--         "myfile.dat",
--         "12345",
--         "the end"
--         }
-- 
-- -- Note that all arguments remain the same as example 1
-- -- except for the first two. The second argument is always
-- -- the same as the first and is inserted to keep the numbering
-- -- of the subsequent arguments the same, whether your program
-- -- is bound or translated as a .exe, or not.
-- </eucode>
--
-- See Also:
-- [[:getenv]], [[:cmd_parse]], [[:show_help]]

--**
-- Signature:
-- global function option_switches()
--
-- Description:
-- Retrieves the list of switches passed to the interpreter on the comand line.
--
-- Returns:
-- A **sequence** of strings, each containing a word related to switches.
--
-- Comments:
--
-- All switches are recorded in upper case.
--
-- Example 1:
-- exw -d helLo will result in ##option_switches##() being ##{"-D","helLo"}##.
--
-- See Also:
-- [[:Command line switches]]

--**
-- Show help message for the given opts.
--
-- Parameters:
-- # ##opts##: a sequence of options. See the Comments: section for details
-- # ##add_help_rid##: an integer, the routine_id of a procedure that will be called on
--     completion. Defaults to -1 (no call).
--
-- Comments:
-- If ##add_help_rid## is specified, it must be the id of a procedure that takes no arguments.
--
-- ##opts## is a sequence of records, each of which describes a command line option for a program.
-- The name of the program is fetched from the command line. Each option record is a 5 element
-- sequence
-- # a sequence representing some text following a "-". Use an atom if not relevant;
-- # a sequence representing some text following a "--". Use an atom if not relevant;
-- # a sequence, some help text which concerns the above synonymous options.
-- # either 1 to denote a parameter of the options, or anything else if none.
-- # an integer, a routine_id. Currently not used by this procedure.
--
-- When the second element is specified and there is a parameter, the syntax "=x" is used. When
-- the first element is specified, the " x" syntax is used.
--
-- Example 1:
-- <eucode>
-- -- in myfile.ex
-- show_help({
--      {"q", "silent", "Suppresses any output to console", NO_PARAMETER, 0},
--      {"r", 0, "Sets how many lines the console should display", HAS_PARAMETER, 1}})
-- </eucode>
--
-- myfile.ex options:
-- -q, ~--silent		Suppresses any output to console
-- -r x				Sets how many lines the console should display

export procedure show_help(sequence opts, integer add_help_rid=-1)
	integer pad_size, this_size
	sequence cmds, cmd

	cmds = command_line()

	pad_size = 0
	for i = 1 to length(opts) do
		this_size = 0
		if sequence(opts[i][SINGLE]) then this_size += length(opts[i][SINGLE]) + 1 end if
		if sequence(opts[i][DOUBLE]) then this_size += length(opts[i][DOUBLE]) + 2 end if

		if equal(opts[i][PARAM],HAS_PARAMETER) then
			this_size += 4
		end if

		if pad_size < this_size + 6 then
			pad_size = this_size + 6
		end if
	end for

	printf(1, "%s options:\n", {cmds[2]})
	for i = 1 to length(opts) do
		cmd = ""
		if sequence(opts[i][SINGLE]) then
			cmd &= '-' & opts[i][SINGLE]
			if equal(opts[i][PARAM],HAS_PARAMETER) then
				cmd &= " x"
			end if
		end if
		if sequence(opts[i][DOUBLE]) then
			if length(cmd) > 0 then cmd &= ", " end if
			cmd &= "--" & opts[i][DOUBLE]
			if equal(opts[i][PARAM], HAS_PARAMETER) then
				cmd &= "=x"
			end if
		end if
		puts(1, "     " & pad_tail(cmd, pad_size))
		puts(1, " " & opts[i][HELP] & '\n')
	end for

	if add_help_rid >= 0 then
		puts(1, "\n")
		call_proc(add_help_rid, {})
	end if
end procedure

function find_opt(sequence opts, integer typ, object name)
	integer slash
	-- sequence lResult
	integer lPos = 0
	sequence lOptName
	object lOptParam

	lOptName = repeat(' ', length(name))
	lOptParam = 0
	for i = 1 to length(name) do
		if name[i] = '"' then
			lPos = i
		elsif find(name[i], ":=") then
			if lPos = 0 then
				lPos = i
				lOptName = lOptName[1..lPos-1]
				lOptParam = name[lPos + 1 .. $]
				exit
			end if
		end if

		lOptName[i] = name[i]
	end for


	slash = 0 -- should we check both single char and words?
	if typ = 3 then
		slash = 1
		typ = 2
	end if

	for i = 1 to length(opts) do
		if length(opts[i]) > 5 then
			if equal(opts[i][6], NO_CASE) then
				if equal(lower(lOptName), lower(opts[i][typ])) or 
					(slash and equal(lower(lOptName), lower(opts[i][1]))) 
				then
					return {i, lOptParam}
				end if
			end if
		end if

		if equal(lOptName, opts[i][typ]) or (slash and equal(lOptName, opts[i][1])) then
			return {i, lOptParam}
		end if
	end for

	return {0, "Unrecognised"}
end function

--**
-- Parse command line options, and optionally call procedures that relate to these options
--
-- Parameters:
-- * ##opts## - a sequence of valid option records: See Comments: section for details
-- * ##add_help_rid## - an integer, the id of ???. Defaults to -1.
--
-- Returns:
--  A **sequence**, the list of all command line arguments.
--
-- Comments:
--
-- 6 sorts of tokens are recognized on the command line:
-- # a single '-'. Simply added to the option list
-- # a single "~-~-". This signals the end of command line options. What remains of the command
--   line is added to the option list, and the parsing terminates.
-- # -something. The option will be looked up in ##opts##.
-- # ~-~-something. Ditto.
-- # /something. Ditto.
-- # anything else. The word is simply added to the option list.
--
-- On a failed lookup, the program shows the help by calling [[:show_help]](##opts##,
-- ##add_help_rid##) and terminates with status code 1.
--
-- Option records have the following structure:
-- # a sequence representing some text following a "-". Use an atom if not relevant;
-- # a sequence representing some text following a "~-~-". Use an atom if not relevant;
-- # a sequence, some help text which concerns the above synonymous options.
-- # either ##HAS_PARAMETER## to denote a parameter of the options, or anything else if none.
-- # an integer, a [[:routine_id]]. This id will be called when a lookup he this entry.
-- # an integer, a value of ##NO_CASE## to indicate that the case of the supplied option
--   is not significant.
--
-- The fifth member of the record must be the id of a procedure. If the fourth member is
-- ##NO_PARAMETER##, the procedure takes no argument. Otherwise, it will be passed a sequence,
-- the next word on the command line.
--
-- For more details on how the command line is being pre parsed, see [[:command_line]].
--
-- Example:
-- <eucode>
-- integer verbose = 0
-- sequence output_filename = ""
--
-- procedure opt_verbose()
--     verbose = 1
-- end procedure
--
-- procedure opt_output_filename(object param)
--     output_filename = param
-- end procedure
--
-- sequence opts = {
--     { "v", "verbose", "Verbose output",	NO_PARAMETER, routine_id("opt_verbose") },
--     { "o", "output",  "Output filename", HAS_PARAMETER, routine_id("opt_output_filename") }
-- }
--
-- sequence extras = cmd_parse(opts)
--
-- -- When run as: exu/exwc myprog.ex -v -o john.txt input1.txt input2.txt
-- -- verbose will be 1, output_filename will be "john.txt" and
-- -- extras = { "input1.txt", "input2.txt" }
-- </eucode>
--
-- See Also:
--     [[:show_help]], [[command_line]]

export function cmd_parse(sequence opts, integer add_help_rid=-1, sequence cmds = command_line())
	integer idx, opts_done
	sequence cmd, extras
	sequence param
	sequence find_result
	integer lType
	integer lFrom

	extras = {}
	idx = 2
	opts_done = 0

	while idx < length(cmds) do
		idx += 1

		cmd = cmds[idx]
		if opts_done then
			extras = append(extras, cmd)
			continue
		end if

		if equal(cmd, "--") then
			opts_done = 1
			continue
		end if

		if find(cmd[1], "-/") =  0 then
			extras = append(extras, cmd)
			continue
		end if


		if length(cmd) = 1 then
			extras = append(extras, cmd)
			continue
		end if

		if equal(cmd[1..2], "--") then	  -- found --opt-name
			lType = 2
			lFrom = 3
		elsif cmd[1] = '-' then -- found -opt
			lType = 1
			lFrom = 2
		else  -- found /opt
			lType = 3
			lFrom = 2
		end if

		find_result = find_opt(opts, lType, cmd[lFrom..$])

		if find_result[1] = 0 then
			-- something is wrong with the option
			printf(1, "%s option: %s\n\n", {find_result[2], cmd})
			show_help(opts, add_help_rid)
			abort(1)
		elsif find_result[1] > 0 then
			if equal(opts[find_result[1]][PARAM],HAS_PARAMETER) then
				idx += 1
				if idx <= length(cmds) then
					param = {cmds[idx]}
				else
					param = {""}
				end if

			elsif equal(opts[find_result[1]][PARAM],NO_PARAMETER) then
				param = {}

			elsif sequence(opts[find_result[1]][PARAM]) then
				if atom(find_result[2]) then
					idx += 1
					if idx <= length(cmds) then
						param = {cmds[idx]}
					else
						param = {""}
					end if
				else
					param = {find_result[2]}
				end if

			else
				-- Unknown option parameter so don't call the RID.
				opts[find_result[1]][RID] = -1
			end if

			if opts[find_result[1]][RID] >= 0 then
				call_proc(opts[find_result[1]][RID], param)
			end if
		end if

	end while

	return extras
end function

--****
-- === Environment.

constant M_INSTANCE = 55

--**
-- Return ##hInstance## on //Windows//, Process ID (pid) on //Unix// and 0 on //DOS//
--
-- Comments:
-- On //Windows// the ##hInstance## can be passed around to various
-- //Windows// routines.

export function instance()
	return machine_func(M_INSTANCE, 0)
end function

ifdef WIN32 then
	constant UNAME = define_c_func(open_dll("kernel32.dll"), "GetVersionExA", {C_POINTER}, C_INT)
elsifdef LINUX then
	constant UNAME = define_c_func(open_dll(""), "uname", {C_POINTER}, C_INT)
elsifdef FREEBSD then
	constant UNAME = define_c_func(open_dll("libc.so"), "uname", {C_POINTER}, C_INT)
elsifdef OSX then
	constant UNAME = define_c_func(open_dll("libc.dylib"), "uname", {C_POINTER}, C_INT)
end ifdef

--**
-- Retrieves the name of the host OS.
--
-- Returns:
--    A **sequence**, starting with the OS name. If identification fails, returned string
--    is "". Extra information depends on the OS (details unavailable).

export function uname()
	ifdef WIN32 then
		atom buf
		sequence sbuf
		integer maj, mine, build, plat
		buf = allocate(148)
		poke4(buf, 148)
		if c_func(UNAME, {buf}) then
			maj = peek4u(buf+4)
			mine = peek4u(buf+8)
			build = peek4u(buf+12)
			plat = peek4u(buf+16)
			sbuf = {}
			if plat = 0 then
				sbuf = append(sbuf, "Win32s")
				sbuf = append(sbuf, sprintf("Windows %d.%d", {maj,mine}))
			elsif plat = 1 then
				sbuf = append(sbuf, "Win9x")
				if mine = 0 then
					sbuf = append(sbuf, "Win95")
				elsif mine = 10 then
					sbuf = append(sbuf, "Win98")
				elsif mine = 90 then
					sbuf = append(sbuf, "WinME")
				else
					sbuf = append(sbuf, "Unknown")
				end if
			elsif plat = 2 then
				sbuf = append(sbuf, "WinNT")
				if maj = 6 and mine = 1 then
					sbuf = append(sbuf, "Windows7")
				elsif maj = 6 and mine = 0 then
					sbuf = append(sbuf, "Vista")
				elsif maj = 5 and mine = 1 or 2 then
					sbuf = append(sbuf, "WinXP")
				elsif maj = 5 and mine = 0 then
					sbuf = append(sbuf, "Win2K")
				elsif maj = 4 and mine = 0 then
					sbuf = append(sbuf, "WinNT 4.0")
				elsif maj = 3 and mine = 51 then
					sbuf = append(sbuf, "WinNT 3.51")
				elsif maj = 3 and mine = 50 then --is it 50 or 5?
					sbuf = append(sbuf, "WinNT 3.5")
				elsif maj = 3 and mine = 1 then
					sbuf = append(sbuf, "WinNT 3.1")
				else
					sbuf = append(sbuf, sprintf("WinNT %d.%d", {maj,mine}))
				end if
			elsif plat = 3 then
				sbuf = append(sbuf, "WinCE")
				sbuf = append(sbuf, sprintf("WinCE %d.%d", {maj,mine}))
			else
				sbuf = append(sbuf, "Unknown Windows")
				sbuf = append(sbuf, sprintf("Version %d.%d", {maj,mine}))
			end if
			sbuf = append(sbuf, peek_string(buf+20))
			sbuf &= {plat, build, mine, maj}
			return sbuf
		else
			return {}
		end if
	elsifdef UNIX then
		atom buf, pbuf
		integer i, c, k
		sequence sbuf, snam
		buf = allocate(4096) --excessive, but to be safe
		if c_func(UNAME, {buf}) = 0 then
			sbuf = {}
			pbuf = buf
			snam = ""
			i = 0
			k = 0
			while 1 do
				c = peek(pbuf)
				i = i + 1
				if c = 0 and length(snam) then
					sbuf = append(sbuf, snam)
					snam = ""
					k = k + 1
					if k > 4 then exit end if
				elsif c != 0 then
					snam &= c
					pbuf = pbuf + 1
					i = i + 1
				else
					pbuf = pbuf + 1
					i = i + 1
				end if
			end while
			free(buf)
			return sbuf
		else
			free(buf)
			return ""
		end if
	elsifdef DOS32 then
    	sequence reg_list
	    reg_list = repeat(0,10)
    	reg_list[REG_AX] = #3000
	    reg_list = dos_interrupt(#21,reg_list)
		return {"DOS", sprintf("%g", remainder(reg_list[REG_AX],256) + 
			floor(reg_list[REG_AX]/256)/100)}
	else
		return {"UNKNOWN"} --TODO
	end ifdef
end function

--**
-- Decides whether the host system is a newer Windows version (NT/2K/XP/Vista).
--
-- Returns:
-- An **integer**, 1 if host system is a newer Windows (NT/2K/XP/Vista), else 0.

export function is_win_nt()
	ifdef WIN32 then
		sequence s
		s = uname()
		return equal(s[1], "WinNT")
	else
		return -1
	end ifdef
end function

--**
-- Signature:
-- global function getenv(sequence var_name)
--
-- Description:
-- Return the value of an environment variable. 
--
-- Parameters:
-- 		# ##var_name##: a string, the name of the variable being queried.
--
-- Returns:
--		An **object**, -1 if the variable does not exist, else a sequence holding its value.
--
-- Comments: 
--
-- Both the argument and the return value, may, or may not be, case sensitive. You might need to test this on your own system.
--
-- Example:
-- <eucode>
--  e = getenv("EUDIR")
-- -- e will be "C:\EUPHORIA" -- or perhaps D:, E: etc.
-- </eucode>
-- 
-- See Also:   
-- [[:setenv]], [[:command_line]]

--**
-- Set an environment variable.
--
-- Parameters:
--
-- # ##name##: a string, the environment variable name
-- # ##val##: a string, the value to set to
-- # ##overwrite##: an integer, nonzero to overwrite an existing variable, 0 to disallow this.
--
-- Example 1:
-- <eucode>
-- ? setenv("NAME", "John Doe")
-- ? setenv("NAME", "Jane Doe")
-- ? setenv("NAME", "Jim Doe", 0)
-- </eucode>
--
-- See Also:
--   [[:getenv]], [[:unsetenv]]

export function setenv(sequence name, sequence val, integer overwrite=1)
	return machine_func(M_SET_ENV, {name, val, overwrite})
end function

--**
-- Unset an environment variable
--
-- Parameters:
-- * ##name## - name of environment variable to unset
--
-- Example 1:
-- <eucode>
-- ? unsetenv("NAME")
-- </eucode>
--
-- See Also:
--   [[:setenv]], [[:getenv]]

export function unsetenv(sequence env)
	return machine_func(M_UNSET_ENV, {env})
end function

--**
-- Signature:
-- global function platform()
--
-- Description:
-- Indicates the platform that the program is being executed on: DOS32, WIN32, Linux/FreeBSD or OS X.
--
-- Returns:
-- A small **integer**:
-- <eucode>
--      global constant DOS32 = 1,
--                     WIN32 = 2,
--                     LINUX = 3,
--                     FREEBSD = 3,
--					   OSX   = 4
-- </eucode>
--
-- Comments: 
--
-- The [[:ifdef statement]] is much more versatile and supersedes ##platform##(), which is 
-- supported for backward vompatibility and for a limited time only.
--
-- When ex.exe is running, the platform is //DOS32//. When exw.exe is running the platform is //WIN32//. 
-- When exu is running the platform is //LINUX// (or //FREEBSD//) or //OSX//.
--
--  ##platform##() used to be the way to execute different code depending on which platform the program is running on.
-- Additional platforms will be added as Euphoria is ported to new machines and operating environments.
--
-- Example 1:
-- <eucode>
--  if platform() = WIN32 then
--     -- call system Beep routine
--     err = c_func(Beep, {0,0})
-- elsif platform() = DOS32 then
--     -- make beep
--     sound(500)
--     t = time()
--     while time() < t + 0.5 do
--     end while
--     sound(0)
-- else
--     -- do nothing (Linux/FreeBSD)
-- end if
-- </eucode>
--
-- See Also: 
-- [[:platform.txt]], [[:ifdef statement]]


--****
-- === Interacting with the OS
--
--**
-- Signature:
-- global procedure system(sequence command, integer mode)
--
-- Description:
-- Pass a command string to the operating system command interpreter. 
--
-- Parameters:
--		# ##command##: a string to be passed to the shell
--		# ##mode##: an integer, indicating the manner in which to return from the call.
--
-- Errors:
-- ##command## should not exceed 1,024 characters.
--
-- Comments:
-- Allowable values for ##mode## are:
-- * 0: the previous graphics mode is restored and the screen is cleared.
-- * 1: a beep sound will be made and the program will wait for the user to press a key before the previous graphics mode is restored.
-- * 2: the graphics mode is not restored and the screen is not cleared.
--
-- ##mode## = 2 should only be used when it is known that the command executed by ##system##() will not change the graphics mode.
--
-- You can use Euphoria as a sophisticated "batch" (.bat) language by making calls to ##system##() and ##system_exec##().
-- 
-- ##system##() will start a new DOS or Linux/FreeBSD shell.
-- 
-- ##system##() allows you to use command-line redirection of standard input and output in  
-- ##command##.
--
-- Under //DOS32//, a Euphoria program will start off using extended memory. 
-- If extended memory runs out the program will consume conventional memory. 
-- If conventional memory runs out it will use virtual memory, i.e. swap space on disk. 
-- The //DOS// command run by ##system##() will fail if there is not enough conventional memory available.
-- To avoid this situation you can reserve some conventional (low) memory by typing:
--  {{{
--      SET CAUSEWAY=LOWMEM:xxx
--  }}}
--  
--  where ##xxx## is the number of K of conventional memory to reserve. Type this before running your program. 
-- You can also put this in autoexec.bat, or in a .bat file that runs your program. For example:
-- {{{
--      SET CAUSEWAY=LOWMEM:80
--     ex myprog.ex
-- }}}
--  This will reserve 80K of conventional memory, which should be enough to run simple //DOS //commands like COPY, MOVE, MKDIR etc.
--
-- Example 1:
-- <eucode>
--  system("copy temp.txt a:\\temp.bak", 2)
-- -- note use of double backslash in literal string to get
-- -- single backslash
-- </eucode>
-- 
-- Example 2:  
-- <eucode>
--  system("ex \\test\\myprog.ex < indata > outdata", 2)
-- -- executes myprog by redirecting standard input and
-- -- standard output
-- </eucode>
-- 
-- See Also:
-- [[:system_exec]], [[:command_line]], [[:current_dir]], [[:getenv]]
--
--**
-- Signature:
-- global function system_exec(sequence command, integer mode)
--
-- Description: 
-- Try to run the a shell executable command
--
-- Parameters:
--		# ##command##: a string to be passed to the shell, representing an executable command
--		# ##mode##: an integer, indicating the manner in which to return from the call.
--
-- Returns:
-- An **integer**, basically the exit/return code from the called process.
--
-- Errors:
-- ##command## should not exceed 1,024 characters.
--
-- Comments:
--
-- Allowable values for ##mode## are:
-- * 0: the previous graphics mode is restored and the screen is cleared.
-- * 1: a beep sound will be made and the program will wait for the user to press a key before the previous graphics mode is restored.
-- * 2: the graphics mode is not restored and the screen is not cleared.
--
-- If it is not possible to run the program, ##system_exec##() will return -1.
--
-- On //DOS32// or //WIN32//, ##system_exec##() will only run .exe and .com programs. 
-- To run .bat files, or built-in DOS commands, you need [[:system]](). Some commands, 
-- such as DEL, are not programs, they are actually built-in to the command interpreter.
--
-- On //DOS32// and //WIN32//, ##system_exec##() does not allow the use of command-line redirection in ##command##.
-- Nor does it allow you to quote strings that contain blanks, such as file names.
--
-- exit codes from DOS or Windows programs are normally in the range 0 to 255, with 0 indicating "success". 
-- 
-- You can run a Euphoria program using ##system_exec##(). A Euphoria program can return an exit code using [[:abort]]().
-- 
-- ##system_exec##() does not start a new //DOS// shell.
--  
-- Example 1:  
-- <eucode>
--  integer exit_code
-- exit_code = system_exec("xcopy temp1.dat temp2.dat", 2)
-- 
-- if exit_code = -1 then
--     puts(2, "\n couldn't run xcopy.exe\n")
-- elsif exit_code = 0 then
--     puts(2, "\n xcopy succeeded\n")
-- else
--     printf(2, "\n xcopy failed with code %d\n", exit_code)
-- end if
-- </eucode>
--  
-- Example 2:  
-- <eucode>
--  -- executes myprog with two file names as arguments
-- if system_exec("ex \\test\\myprog.ex indata outdata", 2) then
--     puts(2, "failure!\n")
-- end if
-- </eucode>
--
-- See Also:
-- [[:system]], [[:abort]]
--
--****
-- === Miscellaneous

--**
-- Suspend thread execution. for ##t## seconds.
--
-- Parameters:
-- # ##t##: an atom, the number of seconds for which to sleep.
--
-- Comments:
-- On //Windows// and //Unix//, the operating system will suspend your process and
-- schedule other processes. On //DOS//, your program will go into a busy loop for
-- ##t## seconds, during which time other processes may run, but they will compete
-- with your process for the CPU.
--
-- With multiple tasks, the whole program sleeps, not just the current task. To make
-- just the current task sleep, you can call ##[[:task_schedule]]([[:task_self]](), {i, i})##
-- and then execute [[:task_yield]](). Another option is to call [[:task_delay]]().
--
-- Example:
-- <eucode>
-- puts(1, "Waiting 15 seconds and a quarter...\n")
-- sleep(15.25)
-- puts(1, "Done.\n")
-- </eucode>
--
-- See Also:
--     [[:task_schedule]], [[:tick_rate]], [[:task_yield]], [[:task_delay]]

export procedure sleep(atom t)
-- go to sleep for t seconds
-- allowing (on WIN32 and Linux) other processes to run
	if t >= 0 then
		machine_proc(M_SLEEP, t)
	end if
end procedure

constant
 	M_SOUND      = 1,
	M_TICK_RATE = 38


--**
-- Frequency Type

export type frequency(integer x)
	return x >= 0
end type

--**
-- Turn on the PC speaker at a specified frequency 
--
-- Parameters:
-- 		# ##f##: frequency of sound. If ##f## is 0 the speaker will be turned off.
--
-- Comments:
--
-- On //Windows// and //Unix// platforms, no sound will be made.
--
-- Example 1:
-- <eucode>
-- sound(1000) -- starts a fairly high pitched sound
-- </eucode>

export procedure sound(frequency f)
-- turn on speaker at frequency f
-- turn off speaker if f is 0
	machine_proc(M_SOUND, f)
end procedure

--**
-- Specify the number of clock-tick interrupts per second.
--
-- Parameters:
-- 		# ##rate##, an atom, the number of ticks by seconds.
--
-- Errors:
-- The rate must not be greater than the inverse frequency of the motherboard clock, at 1193181 2/3 Hz.
--
-- Comments:
--
-- This setting determines the precision of the time() library routine.
-- It also affects the sampling rate for time profiling.
--
-- ##tick_rate## is effective under //DOS// only, and is a no-op elsewhere.
-- Under //DOS//, the tick rate is 18.2 ticks per second. Under //WIN32//,
-- it is always 100 ticks per second.
--
-- ##tick_rate##() can increase the setting above the default value. As a
-- special case, ##tick_rate(0)## resets //DOS// to the default tick rates.
--
-- If a program runs in a DOS window with a tick rate other than 18.2, the
-- time() function will not advance unless the window is the active window. 
--
-- With a tick rate other than 18.2, the time() function on DOS takes about
-- 1/100 the usual time that it needs to execute. On Windows and FreeBSD,
-- time() normally executes very quickly.
-- 
-- While ex.exe is running, the system will maintain the correct time of day.
-- However if ex.exe should crash (e.g. you see a "CauseWay..." error)
-- while the tick rate is high, you (or your user) may need to reboot the
-- machine to restore the proper rate. If you don't, the system time may
-- advance too quickly. This problem does not occur on Windows 95/98/NT,
-- only on DOS or Windows 3.1. You will always get back the correct time
-- of day from the battery-operated clock in your system when you boot up
-- again. 
--  
-- Example 1:
-- <eucode>
-- tick_rate(100)
-- -- time() will now advance in steps of .01 seconds
-- -- instead of the usual .055 seconds
-- </eucode>
-- 
-- See Also: 
--		[[:time]], [[:Debugging and profiling]]
--

export procedure tick_rate(atom rate)
	machine_proc(M_TICK_RATE, rate)
end procedure

--**
-- Signature:
-- global function include_paths(integer convert)
--
-- Description:
-- Returns the list of include paths, i the order in which they are searched
--
-- Parameters:
--		# ##convert##: an integer, nonzero to include converted path entries that were not validated yet.
--
-- Returns:
--	A **sequence** of strings, ach holding a fully qualified include path.
--
-- Comments:
--
-- ##convert## is checked only under //Windows//. If a path has accented characters in it, then 
-- it may or may not be valid to convert those to the OEM code page. Setting ##convert## to a nonzero value
-- will force conversion for path entries that have accents and which have not been checked to be valid yet.
-- The extra entries, if any, are returned at the end of the returned sequence.
--
-- The paths are ordered in the order they are searched: 
-- # current directory
-- # configuration file,
-- # command line switches,
-- # EUINC
-- # a default based on EUDIR.
--
-- Backslashes are redoubled, so that the paths can be passd unaltered to [[:system]]() or [[:system_exec]]().
--
-- Example 1:
-- <eucode>
-- sequence s = include_paths(0)
-- -- s might contain
-- {
--   "C:\\EuphoriA\\tests",
--   "C:\\EUPHORIA\\INCLUDE",
--   "C:\\EUPHORIA\\xcontrols\\include",
--   "C:\\EUPHORIA\\win32lib_0_70_4a\\include"
-- }
-- </eucode>
--
-- See Also:
-- [[:euinc.conf]], [[:include]], [[:option_switches]]





