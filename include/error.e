-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- === Error Handling
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>

constant
	M_CRASH_MESSAGE = 37,
	M_CRASH_FILE = 57,
	M_CRASH_ROUTINE = 66,
	M_CRASH = 67,
	M_WARNING_FILE = 72

-- Crash handling routines:

--**
export procedure crash(sequence fmt, object data={})
	object msg
	msg = sprintf(fmt, data)
	machine_proc(M_CRASH, msg)
end procedure

--**
export procedure crash_message(sequence msg)
-- Specify a final message to display for your user, in the event 
-- that Euphoria has to shut down your program due to an error.
	machine_proc(M_CRASH_MESSAGE, msg)
end procedure

--**
export procedure crash_file(sequence file_path)
-- Specify a file path name in place of "ex.err" where you want
-- any diagnostic information to be written.
	machine_proc(M_CRASH_FILE, file_path)
end procedure

--**
export procedure warning_file(object file_path)
-- Specify a file path where to output warnings. Any atom >=0 causes STDERR to be used, and a 
-- value <0 suppresses output. Use the latter in extreme cases only.
	machine_proc(M_WARNING_FILE, file_path)
end procedure

--**
export procedure crash_routine(integer proc)
-- specify the routine id of a 1-parameter Euphoria function to call in the
-- event that Euphoria must shut down your program due to an error.
	machine_proc(M_CRASH_ROUTINE, proc)
end procedure
