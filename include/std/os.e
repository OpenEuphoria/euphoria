namespace os

--****
-- == Operating System Helpers
--
-- <<LEVELTOC depth=2>>
--

include std/sequence.e
include std/text.e
include std/machine.e

ifdef DOS32 then
	include std/dos/interrup.e
elsedef
	include std/dll.e
end ifdef

constant
	M_SLEEP     = 64,
	M_SET_ENV   = 73,
	M_UNSET_ENV = 74

--****
-- === Operating System Constants
--

public constant
	DOS32	= 1,
	WIN32	= 2,
	LINUX	= 3,
	OSX	    = 4,
	SUNOS	= 5,
	OPENBSD = 6,
	NETBSD  = 7,
	FREEBSD = 8

--****
-- These constants are returned by the [[:platform]] function.
--
-- * DOS32   - Host operating system is DOS
-- * WIN32   - Host operating system is Windows
-- * LINUX   - Host operating system is Linux **or** FreeBSD
-- * FREEBSD - Host operating system is Linux **or** FreeBSD
-- * OSX     - Host operating system is Mac OS X
-- * SUNOS   - Host operating system is Sun's OpenSolaris
-- * OPENBSD - Host operating system is OpenBSD
-- * NETBSD  - Host operating system is NetBSD
--
-- Note:
--   Via the [[:platform]] call, there is no way to determine if you are on Linux
--   or FreeBSD. This was done to provide a generic UNIX return value for
--   [[:platform]].
--
--   In most situations you are better off to test the host platform by using
--   the [[:ifdef statement]]. It is both more precise and faster.
--

--****
-- === Environment.

constant M_INSTANCE = 55

--**
-- Return ##hInstance## on //Windows//, Process ID (pid) on //Unix// and 0 on //DOS//
--
-- Comments:
-- On //Windows// the ##hInstance## can be passed around to various
-- //Windows// routines.

public function instance()
	return machine_func(M_INSTANCE, 0)
end function

ifdef WIN32 then
	constant M_UNAME = define_c_func(open_dll("kernel32.dll"), "GetVersionExA", {C_POINTER}, C_INT)
elsifdef UNIX then
	constant M_UNAME = 76
end ifdef

--**
-- Retrieves the name of the host OS.
--
-- Returns:
--    A **sequence**, starting with the OS name. If identification fails, returns
--    an OS name of UNKNOWN. Extra information depends on the OS.
--
--    On DOS, returns an OS name of "DOS" as well as a string representing the
--    DOS version number (e.g. "5.0").
--
--    On Unix, returns the same information as the uname() syscall in the same
--    order as the struct utsname. This information is:
--        OS Name/Kernel Name
--        Local Hostname
--        Kernel Version/Kernel Release
--        Kernel Specific Version information (This is usually the date that the
--        kernel was compiled on and the name of the host that performed the compiling.)
--        Architecture Name (Usually a string of i386 vs x86_64 vs ARM vs etc)
--
--    On Windows, returns the following in order:
--        Windows Platform (out of WinCE, Win9x, WinNT, Win32s, or Unknown Windows)
--        Name of Windows OS (Windows 3.1, Win95, WinXP, etc)
--        Platform Number
--        Build Number
--        Minor OS version number
--        Major OS version number
--
--    On UNKNOWN, returns an OS name of "UNKNOWN". No other information is returned.
--
--    Returns a string of "" if an internal error has occured.
--
-- Comments:
-- On Unix, M_UNAME is defined as a machine_func() and this is passed to the C
-- backend. If the M_UNAME call fails, the raw machine_func() returns -1.
-- On non Unix platforms, calling the machine_func() directly returns 0.

public function uname()
	ifdef WIN32 then
		atom buf
		sequence sbuf
		integer maj, mine, build, plat
		buf = allocate(148)
		poke4(buf, 148)
		if c_func(M_UNAME, {buf}) then
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
		object o = machine_func(M_UNAME, {})
		if atom(o) then
			return {}
		else
			return o
		end if
	elsifdef DOS32 then
    	sequence reg_list
	    reg_list = repeat(0,10)
    	reg_list[REG_AX] = #3000
	    reg_list = dos_interrupt(#21,reg_list)
		return {"DOS", sprintf("%g", remainder(reg_list[REG_AX],256) + 
			floor(reg_list[REG_AX]/256)/100)}
	elsedef
		return {"UNKNOWN"} --TODO
	end ifdef
end function

--**
-- Decides whether the host system is a newer Windows version (NT/2K/XP/Vista).
--
-- Returns:
-- An **integer**, 1 if host system is a newer Windows (NT/2K/XP/Vista), else 0.

public function is_win_nt()
	ifdef WIN32 then
		sequence s
		s = uname()
		return equal(s[1], "WinNT")
	elsedef
		return -1
	end ifdef
end function

--****
-- Signature:
-- <built-in> function getenv(sequence var_name)
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

public function setenv(sequence name, sequence val, integer overwrite=1)
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

public function unsetenv(sequence env)
	return machine_func(M_UNSET_ENV, {env})
end function

--****
-- Signature:
-- <built-in> function platform()
--
-- Description:
-- Indicates the platform that the program is being executed on.
--
-- Returns:
-- An **integer**:
-- <eucode>
-- public constant
--     DOS32   = 1,
--     WIN32   = 2,
--     LINUX   = 3,
--     FREEBSD = 3, -- NOTE: same as LINUX.
--     OSX     = 4,
--     SUNOS   = 5
-- </eucode>
--
-- Comments:
-- The [[:ifdef statement]] is much more versatile and in most cases supersedes ##platform##().
--
-- ##platform##() used to be the way to execute different code depending on which platform the program
-- is running on. Additional platforms will be added as Euphoria is ported to new machines and
-- operating environments.
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
-- [[:Platform-Specific Issues]], [[:ifdef statement]]


--****
-- === Interacting with the OS
--

--****
-- Signature:
-- <built-in> procedure system(sequence command, integer mode)
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

--****
-- Signature:
-- <built-in> function system_exec(sequence command, integer mode)
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

public procedure sleep(atom t)
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

public type frequency(integer x)
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

public procedure sound(frequency f)
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

public procedure tick_rate(atom rate)
	machine_proc(M_TICK_RATE, rate)
end procedure

--****
-- Signature:
-- <built-in> function include_paths(integer convert)
--
-- Description:
-- Returns the list of include paths, in the order in which they are searched
--
-- Parameters:
--    # ##convert##: an integer, nonzero to include converted path entries
--    that were not validated yet.
--
-- Returns:
--	A **sequence** of strings, each holding a fully qualified include path.
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
-- Example 1:
-- <eucode>
-- sequence s = include_paths(0)
-- -- s might contain
-- {
--   "/usr/euphoria/tests",
--   "/usr/euphoria/include",
--   "./include",
--   "../include"
-- }
-- </eucode>
--
-- See Also:
-- [[:euinc.conf]], [[:include]], [[:option_switches]]

