-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Operating System Helpers
--

include sequence.e
include math.e

constant M_SLEEP = 64

--****
-- === Constants
--
-- ==== Operating System Constants
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
	DOS32   = 1, -- ex.exe
	WIN32   = 2, -- exw.exe
	LINUX   = 3, -- exu
	FREEBSD = 3, -- exu
	OSX     = 4  -- exu

export constant
	NO_PARAMETER = 0,
	HAS_PARAMETER = 1

constant
	SINGLE = 1,
	DOUBLE = 2,
	HELP   = 3,
	PARAM  = 4,
	RID    = 5

--**
-- Show help message for the given opts

export procedure show_help(sequence opts, integer add_help_rid=-1)
	integer pad_size, this_size
	sequence cmds, cmd

	cmds = command_line()

	pad_size = 0
	for i = 1 to length(opts) do
		this_size = 0
		if sequence(opts[i][SINGLE]) then this_size += length(opts[i][SINGLE]) + 1 end if
		if sequence(opts[i][DOUBLE]) then this_size += length(opts[i][DOUBLE]) + 2 end if

		if opts[i][PARAM] = HAS_PARAMETER then
			this_size += 4
		end if

		pad_size = max({pad_size, this_size + 6})
	end for

	printf(1, "%s options:\n", {cmds[2]})
	for i = 1 to length(opts) do
		cmd = ""
		if sequence(opts[i][SINGLE]) then
			cmd &= '-' & opts[i][SINGLE]
			if opts[i][PARAM] = HAS_PARAMETER then
				cmd &= " x"
			end if
		end if
		if sequence(opts[i][DOUBLE]) then
			if length(cmd) > 0 then cmd &= ", " end if
			cmd &= "--" & opts[i][DOUBLE]
			if opts[i][PARAM] = HAS_PARAMETER then
				cmd &= "=x"
			end if
		end if
		puts(1, "    " & pad_tail(cmd, pad_size))
		puts(1, " " & opts[i][HELP] & '\n')
	end for

	if add_help_rid >= 0 then
		puts(1, "\n")
		call_proc(add_help_rid, {})
	end if
end procedure

function find_opt(sequence opts, integer typ, object name)
	integer slash

	slash = 0 -- should we check both single char and words?
	if typ = 3 then
		slash = 1
		typ = 2
	end if

	for i = 1 to length(opts) do
		if equal(name, opts[i][typ]) or (slash and equal(name, opts[i][1])) then
			return i
		end if
	end for

	return 0
end function

--****
-- === Routines
--

--**
-- Parse command line options
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
--     { "v", "verbose", "Verbose output",  NO_PARAMETER, routine_id("opt_verbose") },
--     { "o", "output",  "Output filename", HAS_PARAMETER, routine_id("opt_output_filename") }
-- }
--
-- sequence extras = cmd_parse(opts)
--
-- -- When run as: exu/exwc myprog.ex -v -o john.txt input1.txt input2.txt
-- -- verbose will be 1, output_filename will be "john.txt" and
-- -- extras = { "input1.txt", "input2.txt" }
-- </eucode>

export function cmd_parse(sequence opts, integer add_help_rid=-1, 
			sequence cmds = command_line())
	integer idx, cmd_idx, opts_done
	sequence cmd, extras, param

	extras = {}
	idx = 3
	opts_done = 0

	while idx <= length(cmds) do
		cmd_idx = -1 -- cause functions not to be called by default
		cmd = cmds[idx]
		if opts_done then
			extras = append(extras, cmd)
		elsif cmd[1] = '-' and length(cmd) = 1 then
			extras = append(extras, cmd)
		elsif cmd[2] = '-' and length(cmd) = 2 then
			opts_done = 1
		elsif cmd[2] = '-' then    -- found --opt-name
			cmd_idx = find_opt(opts, 2, cmd[3..$])
		elsif cmd[1] = '-' then -- found -o
			cmd_idx = find_opt(opts, 1, cmd[2..$])
		elsif cmd[1] = '/' then -- found /o
			cmd_idx = find_opt(opts, 3, cmd[2..$])
		else                    -- found extra
			extras = append(extras, cmd)
		end if

		if cmd_idx = 0 then
			-- invalid parameter
			printf(1, "Invalid parameter: %s\n\n", {cmd})
			show_help(opts, add_help_rid)
			abort(1)
		elsif cmd_idx > 0 then
			if opts[cmd_idx][PARAM] = HAS_PARAMETER then
				param = cmds[idx+1]
				call_proc(opts[cmd_idx][RID], {param})
				idx += 1
			else
				call_proc(opts[cmd_idx][RID], {})
			end if
		end if

		idx += 1
	end while

	return extras
end function

--**
-- Suspend execution for ##t## seconds.
-- 
-- Comments:
-- On //Windows// and //Unix//, the operating system will suspend your process and 
-- schedule other processes. On //DOS//, your program will go into a busy loop for 
-- ##t## seconds, during which time other processes may run, but they will compete 
-- with your process for the CPU.
--
-- With multiple tasks, the whole program sleeps, not just the current task. To make 
-- just the current task sleep, you can call ##[[:task_schedule]]([[:task_self]](), {i, i})##
-- and then execute ##[[:task_yield]]()##.
--
-- Example:
-- <eucode>
-- puts(1, "Waiting 15 seconds...\n")
-- sleep(15)
-- puts(1, "Done.\n")
-- </eucode>

global procedure sleep(atom t)
-- go to sleep for t seconds
-- allowing (on WIN32 and Linux) other processes to run
	if t >= 0 then
		machine_proc(M_SLEEP, t)
	end if
end procedure

constant M_INSTANCE = 55

--**
-- Return ##hInstance## on Windows, Process ID (pid) on Unix and 0 on DOS
--
-- Comments:
-- On //Windows// the ##hInstance## can be passed around to various
-- //Windows// routines.

export function instance()
	return machine_func(M_INSTANCE, 0)
end function
