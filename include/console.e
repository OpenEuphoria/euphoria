	-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Console 
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>

include types.e
include get.e

constant
	M_WAIT_KEY    = 26,
	M_ALLOW_BREAK = 42,
	M_CHECK_BREAK = 43

--****
-- === Routines

--**
-- Signature:
-- 		global function get_key()
--
-- Returns:
--		An **integer**, either -1 if no key waiting, or the code of the next key waiting in keyboard buffer.
--
-- Description:
--     Return the key that was pressed by the user, without waiting. Special codes are returned for the function keys, arrow keys etc.
--
-- Comments:
--     The operating system can hold a small number of key-hits in its keyboard buffer. 
--     get_key() will return the next one from the buffer, or -1 if the buffer is empty.
--
--     Run the key.bat program to see what key code is generated for each key on your 
--     keyboard.
--
-- Example 1:
-- <eucode>
-- 	integer n = get_key()
-- 	if n=-1 then puts(1, "No key waiting.\n") end if
-- </eucode>
--
-- See Also:
-- 		[[:wait_key]]

--**
-- Set behavior of CTRL+C/CTRL+Break
--
-- Parameters:
-- 	# ##b##, a boolean: TRUE ( != 0 ) to enable the trapping of
-- Ctrl-C/Ctrl-Break, FALSE ( 0 ) to disable iy.
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
--  has set in his **config.sys** file. (Consult an MS-DOS manual for the BREAK
--  command.) For some types of program this sudden termination could leave
--  things in a messy state and might result in loss of data.
--  allow_break(0) lets you avoid this situation.
-- 
-- You can find out if the user has pressed control-c or control-Break by calling 
-- check_break().
--
-- Example 1:
-- <eucode>
-- allow_break(0)  -- don't let the user kill the program!
-- </eucode>
--
-- See Also:
-- 		[[:check_break]]

export procedure allow_break(boolean b)
	machine_proc(M_ALLOW_BREAK, b)
end procedure

--**
-- Description:
-- 		Returns the number of Control-C/Control-BREAK key presses.
--
-- Returns:
-- 		An **integer**, the number of times that CTRL+C or CTRL+Break have
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
-- <eucode>
-- k = get_key()
-- if check_break() then  -- ^C or ^Break was hit once or more
--     temp = graphics_mode(-1)
--     puts(STDOUT, "Shutting down...")
--     save_all_user_data()
--     abort(1)
-- end if
-- </eucode>
--
-- See Also:
-- 		[[:allow_break]]

export function check_break()
	return machine_func(M_CHECK_BREAK, 0)
end function

--**
-- Description:
-- 		Waits for user to press a key, unless any is pending, and returns key code.
--
-- Returns:
--		An **integer**, which is a key code. If one is waiting in keyboard bufer, then return it. Otherwise, wait for one to come up.
--
-- Comments:
--     You could achieve the same result using get_key() as in the example.
-- 	   However, on multi-tasking systems like Windows or Linux/FreeBSD/OS X, this "busy waiting"
--     would tend to slow the system down. wait_key() lets the operating system do other
--     useful work while your program is waiting for the user to press a key.
--
--     You could also use getc(0), assuming file number 0 was input from the keyboard, except 
-- that you wouldn't pick up the special codes for function keys, arrow keys etc.
--
-- Example 1:
--     <eucode>
--     while 1 do -- do this only under DOS!!
--         k = get_key()
--         if k != -1 then
--             exit
--         end if
--     end while
--     </eucode>
--
-- See Also:
-- 		[[:get_key]], [[:getc]]

export function wait_key()
	return machine_func(M_WAIT_KEY, 0)
end function

--**
-- Display a prompt to the user and wait for any key.
--
-- Parameters:
--   ##prompt## - Prompt to display, defaults to "Press Any Key to continue..."
--
-- Example 1:
-- <eucode>
-- any_key() -- "Press Any Key to continue..."
-- </eucode>
--
-- Example 2:
-- <eucode>
-- any_key("Press Any Key to quit")
-- </eucode>
--
-- See Also:
-- 	[[:wait_key]]
export procedure any_key(object prompt="Press Any Key to continue...")
	object ignore

	puts(1, prompt)
	ignore = wait_key()
	puts(1, "\n")
end procedure

--**
-- Description:
-- 		Promptz the user to enter a number, and returns only validated input.
--
-- Parameters:
--		# ##st## is a string of text that will be displayed on the screen.
--		# ##s## is a sequence of two values {lower, upper} which determine the range of values
-- that the user may enter. s can be empty, {}, if there are no restrictions.
--
-- Returns:
-- 		An **atom** in the assigned range which the user typed in.
--
-- Errors:
-- 		If puts() cnnot display ##st## on standard input, or if the first or second element of
-- ##s## is a sequence, a runtime error will be raied.
--		If user tries cancelling the prompt by hitting Ctrl-Z, the program will abort as well 
-- on a type check error.
--
-- Comments:
-- 		As long as the user enters a number that is less than lower or greater
-- than upper, he will be prompted again.
--
--   If this routine is too simple for your needs, feel free to copy it and make your
--   own more specialized version.
--
-- Example 1:
--   <eucode>
--   age = prompt_number("What is your age? ", {0, 150})
--   </eucode>
--
-- Example 2:
--   <eucode>
--   t = prompt_number("Enter a temperature in Celcius:\n", {})
--   </eucode>
--
-- See Also:
-- 	[[:puts]], [[:prompt_string]]
export function prompt_number(sequence prompt, sequence range)
	object answer

	while 1 do
		 puts(1, prompt)
		 answer = gets(0) -- make sure whole line is read
		 puts(1, '\n')

		 answer = value(answer)
		 if answer[1] != GET_SUCCESS or sequence(answer[2]) then
			  puts(1, "A number is expected - try again\n")
		 else
			 if length(range) = 2 then
				  if range[1] <= answer[2] and answer[2] <= range[2] then
					  return answer[2]
				  else
					  printf(1,
					  "A number from %g to %g is expected here - try again\n",
					   range)
				  end if
			  else
				  return answer[2]
			  end if
		 end if
	end while
end function

--**
-- Prompt the user to enter a string of text. 
--
-- Parameters:
--		# ##st## is a string that will be displayed on the screen.
--
-- Returns:
-- 		A **sequence**, the string that the user typed in, stripped of any new-line character.
--
-- Comments:
--     If the user happens to type control-Z (indicates end-of-file), "" will be returned.
--
-- Example 1:
--     <eucode>
--     name = prompt_string("What is your name? ")
--     </eucode>
--
-- See Also:
-- 	[[:prompt_string]]
export function prompt_string(sequence prompt)
	object answer
	
	puts(1, prompt)
	answer = gets(0)
	puts(1, '\n')
	if sequence(answer) and length(answer) > 0 then
		return answer[1..$-1] -- trim the \n
	else
		return ""
	end if
end function
