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
-- global function get_key()
--
-- Description:
--     Return the key that was pressed by the user, without waiting. Return -1 if no key was 
--     pressed. Special codes are returned for the function keys, arrow keys etc.
--
-- Comments:
--     The operating system can hold a small number of key-hits in its keyboard buffer. 
--     get_key() will return the next one from the buffer, or -1 if the buffer is empty.
--
--     Run the key.bat program to see what key code is generated for each key on your 
--     keyboard. 

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

export procedure allow_break(boolean b)
-- If b is TRUE then allow control-c/control-break to
-- terminate the program. If b is FALSE then don't allow it.
-- Initially they *will* terminate the program, but only when it
-- tries to read input from the keyboard.
	machine_proc(M_ALLOW_BREAK, b)
end procedure

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
-- <eucode>
-- k = get_key()
-- if check_break() then
--     temp = graphics_mode(-1)
--     puts(STDOUT, "Shutting down...")
--     save_all_user_data()
--     abort(1)
-- end if
-- </eucode>

export function check_break()
-- returns the number of times that control-c or control-break
-- were pressed since the last time check_break() was called
	return machine_func(M_CHECK_BREAK, 0)
end function

--**
-- Return the next key pressed by the user. Don't return until a key is pressed.
--
-- Comments:
--     You could achieve the same result using get_key() as follows:
--
--     <eucode>
--     while 1 do
--         k = get_key()
--         if k != -1 then
--             exit
--         end if
--     end while
--     </eucode>
--
-- 	   However, on multi-tasking systems like Windows or Linux/FreeBSD, this "busy waiting" 
--     would tend to slow the system down. wait_key() lets the operating system do other 
--     useful work while your program is waiting for the user to press a key.
--
--     You could also use getc(0), assuming file number 0 was input from the keyboard, except 
--     that you wouldn't pick up the special codes for function keys, arrow keys etc. 

export function wait_key()
-- Get the next key pressed by the user.
-- Wait until a key is pressed.
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

export procedure any_key(object prompt="Press Any Key to continue...")
	object ignore
	puts(1, prompt)
	ignore = wait_key()
	puts(1, "\n")
end procedure

--**
-- Prompt the user to enter a number. st is a string of text that will be displayed on the 
-- screen. s is a sequence of two values {lower, upper} which determine the range of values 
-- that the user may enter. If the user enters a number that is less than lower or greater 
-- than upper, he will be prompted again. s can be empty, {}, if there are no restrictions.
--
-- Comments:
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

export function prompt_number(sequence prompt, sequence range)
-- Prompt the user to enter a number.
-- A range of allowed values may be specified.
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
-- Prompt the user to enter a string of text. st is a string that will be displayed on the screen.
-- The string that the user types will be returned as a sequence, minus any new-line character.
--
-- Comments:
--     If the user happens to type control-Z (indicates end-of-file), "" will be returned.
--
-- Example 1:
--     <eucode>
--     name = prompt_string("What is your name? ")
--     </eucode>

export function prompt_string(sequence prompt)
-- Prompt the user to enter a string
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
