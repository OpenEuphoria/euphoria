--****
-- == Errors and Warnings
--
-- <<LEVELTOC level=2 depth=4>>
--
-- === Routines

namespace error

constant
	M_CRASH_MESSAGE = 37,
	M_CRASH_FILE = 57,
	M_CRASH_ROUTINE = 66,
	M_CRASH = 67,
	M_WARNING_FILE = 72

--**
-- crashes the running program and displays a formatted error message.
--
-- Parameters:
-- 		# ##fmt## : a sequence representing the message text. It may have format specifiers in it
--		# ##data## : an object, defaulted to ##{}##.
--
-- Comments:
-- Formatting is the same as with ##printf##.
--
-- 		The actual message being shown, both on standard error and in ##ex.err## (or whatever 
-- 		file last passed to [[:crash_file]]), is ##sprintf(fmt, data)##.
--		The program terminates as for any runtime error. 
--
-- Example 1:
-- <eucode>
-- if PI = 3 then
--     crash("The structure of universe just changed -- reload solar_system.ex")
-- end if
-- </eucode>
--
-- Example 2:
-- <eucode>
-- if token = end_of_file then
--     crash("Test file #%d is bad, text read so far is %s\n", 
--                                                   {file_number, read_so_far})
-- end if
-- </eucode>
--
-- See Also:
--		[[:crash_file]], [[:crash_message]], [[:printf]]

public procedure crash(sequence fmt, object data={})
	object msg
	msg = sprintf(fmt, data)
	machine_proc(M_CRASH, msg)
end procedure

--**
-- specifies a final message to be displayed to your user, in the event
-- that Euphoria has to shut down your program due to an error.
--
-- Parameters:
--     # ##msg## : a sequence to display. It must only contain printable characters.
--
-- Comments:
--     There can be as many calls to ##crash_message## as needed in a program. Whatever was defined
--     last will be used in case of a runtime error.
--
-- Example 1:
-- <eucode>
-- crash_message("The password you entered must have at least 8 characters.")
-- pwd_key = input_text[1..8]
-- -- if ##input_text## is too short, 
-- -- user will get a more meaningful message than 
-- -- "index out of bounds".
-- </eucode>
--
-- See Also:
--     [[:crash]], [[:crash_file]]

public procedure crash_message(sequence msg)
	machine_proc(M_CRASH_MESSAGE, msg)
end procedure

--**
-- specifies a file path name in place of ##"ex.err"## where you want
-- any diagnostic information to be written.
--
-- Parameters:
-- 		# ##file_path## : a sequence, the new error and traceback file path.
--
-- Comments:
-- 		There can be as many calls to ##crash_file## as needed. Whatever was defined last will be used
--      in case of an error at runtime, whether it was triggered by [[:crash]] or not.
--
-- See Also:
-- 		[[:crash]], [[:crash_message]]

public procedure crash_file(sequence file_path)
	machine_proc(M_CRASH_FILE, file_path)
end procedure

--****
-- Signature:
-- <built-in> procedure abort(atom error)
--
-- Description:
-- aborts execution of the program. 
--
-- Parameters:
-- 		# ##error## : an integer, the exit code to return.
--
-- Comments:
-- ##error## is expected to lie in the ##0..255## range. Zero is usually interpreted as the sign of a successful completion.
--
-- Other values can indicate various kinds of errors. //Windows// batch (##.bat##) programs can read 
-- this value using the errorlevel feature. Non integer values are rounded down.
-- A Euphoria program can read this value using [[:system_exec]].
--
-- ##abort## is useful when a program is many levels deep in subroutine calls, and execution must end immediately,
-- perhaps due to a severe error that has been detected.
--
-- If you do not use ##abort## then the interpreter will normally return an exit status code of zero.
-- If your program fails with a Euphoria-detected compile-time or run-time error then a code of one is returned.
--  
-- Example 1:
-- <eucode>
-- if x = 0 then
--     puts(ERR, "can't divide by 0 !!!\n")
--     abort(1)
-- else
--     z = y / x
-- end if
-- </eucode>
-- 
-- See Also:
--  [[:crash_message]], [[:system_exec]]

--**
-- specifies a file path where to output warnings. 
--
-- Parameters:
-- 		# ##file_path## : an object indicating where to dump any warning that were produced.
--
-- Comments:
--   By default, warnings are displayed on the standard error, and require pressing the 
--   Enter key to keep going. Redirecting to a file enables skipping the latter step and having 
--   a console window open, while retaining ability to inspect the warnings in case any was issued.
--
--   Any atom ##>= 0## causes standard error to be used, thus reverting to default behaviour.
--
--   Any atom ##< 0## suppresses both warning generation and output. Use this latter in extreme cases
--   only.
--
--   On an error, some output to the console is performed anyway, so that whatever warning file 
--   was specified is ignored then.
--
-- Example 1:
-- <eucode>
-- warning_file("warnings.lst")
-- -- some code
-- warning_file(0)
-- -- changed opinion: warnings will go to standard error as usual
-- </eucode>
--
-- See Also:
--   [[:On/off options|without warning]], [[:warning]]

public procedure warning_file(object file_path)
	machine_proc(M_WARNING_FILE, file_path)
end procedure

--****
-- Signature:
-- <built-in> procedure warning(sequence message)
--
-- Description:
-- causes the specified warning message to be displayed as a regular warning.
--
-- Parameters:
-- 		# ##message## : a double quoted literal string, the text to display.
--
-- Comments:
--
-- Writing a library has specific requirements, since the code you write will be mainly used
-- inside code you did not write. It may be desirable then to influence, from inside the library,
-- that code you did not write.
-- 
-- This is what ##warning##, in a limited way, does. It enables to generate custom warnings in
-- code that will include yours. Of course, you can also generate warnings in your own code, for
-- instance as a kind of memo. The [[:On/off options|without warning]] top level statement disables such warnings.
--
-- The warning is issued with the ##custom_warning## level. This level is enabled by default, 
-- but can be turned off any time.
--
-- Using any kind of expression in ##message## will result in a blank warning text.
-- 
-- Example 1:
-- 
-- <eucode>
-- -- mylib.e
-- procedure foo(integer n)
--     warning("The foo() procedure is obsolete, use bar() instead.")
--     ? n
-- end procedure
-- 
-- -- some_app.exw
-- include mylib.e
-- foo(123)
-- </eucode>
-- 
-- will result, when ##some_app.exw## is run ##with warning##, in the following text being
-- displayed in the console (terminal) window
-- {{{
-- 123
-- Warning: ( custom_warning ):
--     The foo() procedure is obsolete, use bar() instead.
-- 
-- Press Enter...
-- }}}
-- 
-- See Also:
--   [[:warning_file]] [[:On/off options|without warning]]

--**
-- specifies a function to be called when an error takes place at run time.
--
-- Parameters:
-- 		# ##func## : an integer, the routine_id of the function to link in.
--
-- Comments:
--   The supplied function must have only one argument, which should be integer or more general. 
--   Defaulted parameters in crash routines are not supported yet.
--
--   Euphoria maintains a linked list of routines to execute upon a crash. ##crash_routine## adds 
--   a new function to the list. The routines defined first are executed last. You cannot unlink
--   a routine once it is linked, nor inspect the crash routine chain.
--
--   Currently, the crash routines are pass zero. Future versions may attempt to convey more
--   information to them. If a crash routine returns anything else than zero, the remaining
--   routines in the chain are skipped.
--
--   Crash routines are not fully fledged exception handlers, and they cannot resume execution at 
--   current or next statement. However, they can read the generated crash file, and might 
--   perform any action, including restarting the program.
--
-- Example 1:
-- <eucode>
-- function report_error(integer dummy)
--	  mylib:email("maintainer@remote_site.org", "ex.err")
--    return 0 and dummy
-- end function
-- crash_routine(routine_id("report_error"))
-- </eucode>
--
-- See Also:
-- 	[[:crash_file]], [[:routine_id]], [[:Debugging and Profiling]]

public procedure crash_routine(integer func)
	machine_proc(M_CRASH_ROUTINE, func)
end procedure
