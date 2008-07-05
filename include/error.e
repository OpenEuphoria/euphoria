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
-- Crash running program, displaying a formatted error message the way printf() does.
--
-- Parameters:
-- 		# ##fmt##: a sequence representing the message text. It may have format specifiers in it
--		# ##data##: an object, defaulted to {}.
--
-- Comments:
-- 		The actual message being shown, both on standard error and in ex.err (or whatever file last passed to crash_file()), is ##sprintf(fmt,data)##.
--		The program terminates as for any runtime error. 
--
-- Example 1:
-- <eucode>
-- if PI = 3 then
-- 		crash("The whole structure of universe just changed - please reload solar_system.ex")
-- </eucode>
--
-- Example 2:
-- <eucode>
-- if token = end_of_file then
-- 	crash("Test file #%d is bad, text read so far is %s\n",{file_number,read_so_far})
-- end if
-- </eucode>
-- See Also:
--		[[:crash_file]], [[:crash_meaasge]], [[:printf]]
export procedure crash(sequence fmt, object data={})
	object msg
	msg = sprintf(fmt, data)
	machine_proc(M_CRASH, msg)
end procedure

--**
-- Specify a final message to display for your user, in the event
-- that Euphoria has to shut down your program due to an error.
-- Parameters:
-- 		# ##msg##: a sequence to display. It must only contain printable characters.
--
-- Comments:
-- 		There can be as many crash_message() call as needed in a program. Whatever was defined 
-- last will be used in case of a runtime error.
-- Example 1:
-- <eucode>
-- crash_message("The password you entered must have at least 8 characters.")
-- pwd_key = input_text[1..8]
-- -- if ##input_text## is too short, user will get a more meaningful message than "index out of bounds".
-- </eucode>
-- See Also:
-- 	[[:crash]], [[crash_file]]
export procedure crash_message(sequence msg)
	machine_proc(M_CRASH_MESSAGE, msg)
end procedure

--**
-- Specify a file path name in place of "ex.err" where you want
-- any diagnostic information to be written.
-- Parameters:
-- 		# ##fie_path##: a sequence, the new error and traceback file path.
--
-- Comments:
-- 		There can be as many calls to crash_file() as needed. Whatever was defined last will be used in case of an error at runtime, whether it was troggered by crash() or not.
--
-- See Also:
-- 		[[:crash]], [[:crash_message]]
export procedure crash_file(sequence file_path)
	machine_proc(M_CRASH_FILE, file_path)
end procedure

--**
-- Specify a file path where to output warnings. 
--
-- Parameters:
-- 		#file_path##: an object indicating where to dump any warning that were produced.
--
-- Comments:
-- 		By default, warnings are displayed on the standard error, and require pressing the 
-- Enter key to keep going. Redirecting to a file enables skipping the latter step and having 
-- a console window open, while retaining ability to inspect the warnings in case any was issued.
--
--	 	Any atom >=0 causes standard error to be used, thus reverting to default behaviour.
--
--		Any atom <0 suppresses both warning generation and output. Use this latter in extreme cases only.
--
-- 		On an error, some output to the console is performed anyway, so that whatever warning file was specified is ignored then.
--
-- Example 1:
-- <eucode>
-- warning_file("warnings.lst")
-- -- some code
-- warning_file(0)
-- -- changed opinion: warnings will go to standard error as usual
-- </eucode>
-- See Also:
-- 	[[:without warning]]
export procedure warning_file(object file_path)
	machine_proc(M_WARNING_FILE, file_path)
end procedure

--**
-- Specify a function to be called when an error takes place at run time.
--
-- Parameters:
-- 		# ##func##: an integer, the routine_id of the function to link in.
--
-- Comments:
-- 		The supplied function must have only one parameter, which should be integer or more general. Defaulted parameters in crash routines are not supported yet.
--
--		Euphoria maintains a linked list of routines to execute upon a crash. crash_routine() adds a new function to the list. The routines are executed last defined first. You cannot unlink a routine once it is linked, nor inspect the crash routine chain.
--
--		Currently, the crash routines are passed 0. Future versions may attempt to convey more
-- information to them. If a crash routine returns anything else than 0, the remaining
-- routines in the chain are skipped.
--
-- 		crash routines are not full fledged exception handlers, and they cannot resume execution at current or next statement. However, they can read the generated crash file, and might perform any action, including restarting the program.
--
-- Example 1:
-- <eucode>
-- function report_error(integer dummy)
--	  mylib:email("maintainer@remote_site.org",ex.err)
--    return 0 and dummy
-- end function
-- crash_routine(routine_id("report_error"))
-- </eucode>
-- See Also:
-- 	[[:crash_file]], [[routine_id]],[[:Debugging and profiling]]
export procedure crash_routine(integer func)
	machine_proc(M_CRASH_ROUTINE, func)
end procedure
