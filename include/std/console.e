	-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Console 
--
-- <<LEVELTOC depth=2>>

include types.e
include get.e

constant
	M_WAIT_KEY    = 26,
	M_ALLOW_BREAK = 42,
	M_CHECK_BREAK = 43

--****
-- === Keyboard related routines

--**
-- Signature:
-- 		global function get_key()
--
-- Description:
--     Return the key that was pressed by the user, without waiting. Special codes are returned for the function keys, arrow keys etc.
--
-- Returns:
--		An **integer**, either -1 if no key waiting, or the code of the next key waiting in keyboard buffer.
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
-- integer n = get_key()
-- if n=-1 then
--     puts(1, "No key waiting.\n")
-- end if
-- </eucode>
--
-- See Also:
--   [[:wait_key]]

--**
-- Set behavior of CTRL+C/CTRL+Break
--
-- Parameters:
-- 	# ##b##, a boolean: TRUE ( != 0 ) to enable the trapping of
-- Ctrl-C/Ctrl-Break, FALSE ( 0 ) to disable it.
--
-- Comments:
-- When ##b## is 1 (true), CTRL+C and CTRL+Break can terminate
-- your program when it tries to read input from the keyboard. When
-- i is 0 (false) your program will not be terminated by CTRL+C or CTRL+Break.
--
-- //DOS// will display ^C on the screen, even when your program cannot be terminated.
-- 
-- Initially your program can be terminated at any point where
--  it tries to read from the keyboard. It could also be terminated
--  by other input/output operations depending on options the user
--  has set in his **config.sys** file: consult an MS-DOS manual for the BREAK
--  command. For some types of program this sudden termination could leave
--  things in a messy state and might result in loss of data.
--  ##allow_break##(0) lets you avoid this situation.
--
-- You can find out if the user has pressed Control-C or Control-Break by calling
-- [[:check_break]]().
--
-- Example 1:
-- <eucode>
-- allow_break(0)  -- don't let the user kill the program!
-- </eucode>
--
-- See Also:
--
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
--
-- This is useful after you have called [[:allow_break]](0) which
--  prevents CTRL+C or CTRL+Break from terminating your
--  program. You can use ##check_break##() to find out if the user
--  has pressed one of these keys. You might then perform some action
--  such as a graceful shutdown of your program.
-- 
-- Neither CTRL+C or CTRL+Break will be returned as input
--  characters when you read the keyboard. You can only detect
--  them by calling ##check_break##().
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
--
-- 		[[:allow_break]]

export function check_break()
	return machine_func(M_CHECK_BREAK, 0)
end function

--**
-- Description:
-- 		Waits for user to press a key, unless any is pending, and returns key code.
--
-- Returns:
--		An **integer**, which is a key code. If one is waiting in keyboard buffer, then return it. Otherwise, wait for one to come up.
--
-- Comments:
--     You could achieve the same result using [[:get_key]]() as in the example.
-- 	   However, on multi-tasking systems, that is, all except //DOS//, this "busy waiting"
--     would tend to slow the system down. wait_key() lets the operating system do other
--     useful work while your program is waiting for the user to press a key.
--
--     You could also use [[:getc]](0), assuming file number 0 was input from the keyboard, except
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
--
-- 		[[:get_key]], [[:getc]]

export function wait_key()
	return machine_func(M_WAIT_KEY, 0)
end function

--**
-- Display a prompt to the user and wait for any key.
--
-- Parameters:
-- 		# ##prompt## - Prompt to display, defaults to "Press Any Key to continue..."
--
-- Comments:
-- This wraps [[:wait_key]] by giving a clue to user that s/he should press a key, and 
-- perhaps do some other things as well.
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
--
-- 	[[:wait_key]]

export procedure any_key(object prompt="Press Any Key to continue...")
	object ignore

	puts(1, prompt)
	ignore = wait_key()
	puts(1, "\n")
end procedure

--**
-- Description:
-- 		Prompts the user to enter a number, and returns only validated input.
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
-- 		If [[:puts]]() cannot display ##st## on standard output, or if the first or second element
--      of ##s## is a sequence, a runtime error will be raised.
--
--		If user tries cancelling the prompt by hitting Ctrl-Z, the program will abort as well,
-- issuing a type check error.
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
--
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
					printf(1, "A number from %g to %g is expected here - try again\n", range)
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
--
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

--****
-- === Cross Platform Text Graphics

-- machine() commands

constant M_CURSOR         = 6,
		 M_TEXTROWS       = 12,
		 M_FREE_CONSOLE = 54,
		 M_GET_SCREEN_CHAR = 58,
		 M_PUT_SCREEN_CHAR = 59

type positive_atom(atom x)
	return x >= 1
end type

type text_point(sequence p)
	return length(p) = 2 and p[1] >= 1 and p[2] >= 1 
		   and p[1] <= 200 and p[2] <= 500 -- rough sanity check
end type

export type positive_int(integer x)
	return x >= 1
end type

ifdef DOS32 then
include std/dos/image.e
end ifdef

include graphcst.e

ifdef DOS32 then
function DOS_scr_addr(sequence vc, text_point xy)
-- calculate address in DOS screen memory for a given line, column
	atom screen_memory
	integer page_size
	
	if vc[VC_MODE] = 7 then
		screen_memory = MONO_TEXT_MEMORY
	else
		screen_memory = COLOR_TEXT_MEMORY
	end if
	page_size = vc[VC_LINES] * vc[VC_COLUMNS] * BYTES_PER_CHAR
	page_size = 1024 * floor((page_size + 1023) / 1024)
	screen_memory = screen_memory + get_active_page() * page_size
	return screen_memory + ((xy[1]-1) * vc[VC_COLUMNS] + (xy[2]-1)) 
						   * BYTES_PER_CHAR
end function
end ifdef

--**
-- Signature:
-- global procedure clear_screen()
--
-- Description:
--
-- Clear the screen using the current background color (may be set by [[:bk_color]]()).
--
-- Comments: 
--
-- This works in all text and pixel-graphics modes.
--
-- See Also: 
--
-- [[:bk_color]], [[:graphics_mode]]
--

--**
-- Get the value and attribute of the character at a given screen location.
--
-- Parameters:
-- 		# ##line##: the 1-base line number of the location
-- 		# ##column##: the 1-base column number of the location
--
-- Returns:
-- 		A **sequence**, the pair ##{character, attributes}## for the specified location.
--
-- Comments:
--
-- This function inspects a single character on the //active page//.
--
-- The attribute is an atom that contains the foreground and background color of the character, and possibly other information describing the appearance of the character on the screen.
--  With get_screen_char() and [[:put_screen_char]]() you can save and restore a character on the screen along with its attributes.
--
-- Example 1:
-- <eucode>
-- -- read character and attributes at top left corner
-- s = get_screen_char(1,1) 
-- -- store character and attributes at line 25, column 10
-- put_screen_char(25, 10, {s})
-- </eucode>
-- 
-- See Also: 
--   [[:put_screen_char]], [[:save_text_image]]

export function get_screen_char(positive_atom line, positive_atom column)
	ifdef DOS32 then
		atom scr_addr
		sequence vc
		vc = video_config()
		if line >= 1 and line <= vc[VC_LINES] and
		   column >= 1 and column <= vc[VC_COLUMNS] then
			scr_addr = DOS_scr_addr(vc, {line, column})
			return peek({scr_addr, 2})
		else
			return {0,0}
		end if
	else    
		return machine_func(M_GET_SCREEN_CHAR, {line, column})
	end ifdef
end function

--**
-- Stores/displays a sequence of characters with attributes at a given location.
--
-- Parameters:
-- 		# ##line##: the 1-based line at which to start writing
-- 		# ##column##: the 1-based column at which to start writing
-- 		# ##char_attr##: a sequence of alternated characters and attributes.
--
-- Comments:
--
-- ##char_attr## must be in the form  ##{character, attributes, character, attributes, ...}##.
--
-- Errors: 
-- 		The length of ##char_attr## must be a multiple of 2.
--
-- Comments:
--
-- The attributes atom contains the foreground color, background color, and possibly other platform-dependent information controlling how the character is displayed on the screen.
-- If ##char_attr## has 0 length, nothing will be written to the screen. The characters are written to the //active page//.
-- It's faster to write several characters to the screen with a single call to put_screen_char() than it is to write one character at a time. 
--  
-- Example 1:
-- <eucode>
-- -- write AZ to the top left of the screen
-- -- (attributes are platform-dependent)
-- put_screen_char(1, 1, {'A', 152, 'Z', 131})
-- </eucode>
-- 
-- See Also: 
--   [[:get_screen_char]], [[:display_text_image]]

export procedure put_screen_char(positive_atom line, positive_atom column, 
								 sequence char_attr)
	ifdef DOS32 then
		atom scr_addr
		sequence vc
		integer overflow
		vc = video_config()
		if line <= vc[VC_LINES] and column <= vc[VC_COLUMNS] then
			scr_addr = DOS_scr_addr(vc, {line, column})
			overflow = length(char_attr) - 2 * (vc[VC_COLUMNS] - column + 1)
			if overflow > 0 then
				poke(scr_addr, char_attr[1..$ - overflow])  
			else
				poke(scr_addr, char_attr)
			end if
		end if
	else    
		machine_proc(M_PUT_SCREEN_CHAR, {line, column, char_attr})
	end ifdef
end procedure

--**
-- Display a text image in any text mode.
--
-- Parameters:
-- 		# ##xy##: a pair of 1-based coordinates representing the point at which to start writing
--		# ##text##: a list of sequences of alternated character and attribute.
--
-- Comments:
-- This routine displays to the active text page, and only works in text modes.
--   
-- On //DOS32//, the attribute should consist of the foreground color plus 16 times the background color.
-- ##text## may result from a previous call to [[:save_text_image]](), although you could construct it yourself. The sequences of the text image do not have to all be the same length.
-- 
-- You might use [[:save_text_image]]()/[[:display_text_image]]() in a text-mode graphical 
-- user interface, to allow "pop-up" dialog boxes, and drop-down menus to appear and disappear
-- without losing what was previously on the screen.
-- 
-- Example 1:
-- <eucode>
-- clear_screen()
-- display_text_image({1,1}, {{'A', WHITE, 'B', GREEN},
--                            {'C', RED+16*WHITE},
--                            {'D', BLUE}})
-- -- displays:
-- --     AB
-- --     C
-- --     D
-- -- at the top left corner of the screen.
-- -- 'A' will be white with black (0) background color,
-- -- 'B' will be green on black, 
-- -- 'C' will be red on white, and
-- -- 'D' will be blue on black.
-- </eucode>
-- 
-- See Also:
--   [[:save_text_image]], [[:display_image]], [[:put_screen_char]]
--

export procedure display_text_image(text_point xy, sequence text)
	integer extra_col2, extra_lines
	sequence vc, one_row
	
	vc = video_config()
	ifdef DOS32 then
		atom scr_addr
		integer screen_width
		screen_width = vc[VC_COLUMNS] * BYTES_PER_CHAR
		scr_addr = DOS_scr_addr(vc, xy)
	end ifdef
	if xy[1] < 1 or xy[2] < 1 then
		return -- bad starting point
	end if
	extra_lines = vc[VC_LINES] - xy[1] + 1 
	if length(text) > extra_lines then
		if extra_lines <= 0 then
			return -- nothing to display
		end if
		text = text[1..extra_lines] -- truncate
	end if
	extra_col2 = 2 * (vc[VC_COLUMNS] - xy[2] + 1)
	for row = 1 to length(text) do
		one_row = text[row]
		if length(one_row) > extra_col2 then
			if extra_col2 <= 0 then
				return -- nothing to display
			end if
			one_row = one_row[1..extra_col2] -- truncate
		end if
		ifdef DOS32 then
			poke(scr_addr, one_row)
			scr_addr += screen_width
		else
			machine_proc(M_PUT_SCREEN_CHAR, {xy[1]+row-1, xy[2], one_row})
		end ifdef
	end for
end procedure

--**
-- Copy a rectangular block of text out of screen memory
--
-- Parameters:
-- 		# ##top_left##: the coordinates, given as a pair, of the upper left corner of the area to save.
-- 		# ##bottom_right##: the coordinates, given as a pair, of the lower right corner of the area to save.
--
-- Returns:
-- 		A **sequence** of {character, attribute, character, ...} lists.
-- Comments:
--
-- The returned value is appropriately handled by [[:display_text_image]].
-- On //DOS32//, an attribute byte is made up of two 4-bit fields that encode the foreground and background color of a character. The high-order 4 bits determine the background color, while the low-order 4 bits determine the foreground color.
--
-- This routine reads from the active text page, and only works in text modes.
-- 
-- You might use this function in a text-mode graphical user interface to save a portion of the screen before displaying a drop-down menu, dialog box, alert box etc. 
-- 
-- Example 1:
-- <eucode>
-- -- Top 2 lines are: Hello and World
-- s = save_text_image({1,1}, {2,5})
--
-- -- s is something like: {"H-e-l-l-o-", "W-o-r-l-d-"}
-- </eucode>
--
-- See Also:
--   [[:display_text_image]], [[:save_image]], [[:set_active_page]], [[:get_screen_char]]

export function save_text_image(text_point top_left, text_point bottom_right)
	sequence image, row_chars, vc
	integer screen_width, image_width

	vc = video_config()
	screen_width = vc[VC_COLUMNS] * BYTES_PER_CHAR
	ifdef DOS32 then
		atom scr_addr, screen_memory
		integer page_size
		if vc[VC_MODE] = 7 then
			screen_memory = MONO_TEXT_MEMORY
		else
			screen_memory = COLOR_TEXT_MEMORY
		end if
		page_size = vc[VC_LINES] * screen_width
		page_size = 1024 * floor((page_size + 1023) / 1024)
		screen_memory = screen_memory + get_active_page() * page_size
		scr_addr = screen_memory + 
				(top_left[1]-1) * screen_width + 
				(top_left[2]-1) * BYTES_PER_CHAR
	end ifdef
	image = {}
	image_width = (bottom_right[2] - top_left[2] + 1) * BYTES_PER_CHAR
	for row = top_left[1] to bottom_right[1] do
		ifdef DOS32 then
			row_chars = peek({scr_addr, image_width})
			scr_addr += screen_width
		else
			row_chars = {}
			for col = top_left[2] to bottom_right[2] do
				row_chars &= machine_func(M_GET_SCREEN_CHAR, {row, col})
			end for
		end ifdef
		image = append(image, row_chars)
	end for
	return image
end function

--**
-- Set the number of lines on a text-mode screen.
--
-- Parameters:
-- 		# ##rows##: an integer, the desired number of rows.
--
-- Platforms:
--		Not //Unix//
--
-- Returns:
-- 		An **integer**, the actual number of text lines.
--
-- Comments:
-- Values of 25, 28, 43 and 50 lines are supported by most video cards.
--
-- See Also:
--
--   [[:graphics_mode]], [[:video_fonfig]]

export function text_rows(positive_int rows)
	return machine_func(M_TEXTROWS, rows)
end function

-- cursor styles:
export constant 
	NO_CURSOR              = #2000,
	UNDERLINE_CURSOR       = #0607,
	THICK_UNDERLINE_CURSOR = #0507,
	HALF_BLOCK_CURSOR      = #0407,
	BLOCK_CURSOR           = #0007
		 
--**
-- Select a style of cursor.
--
-- Parameters:
-- 		# ##style##: an integer defining the cursor shape.
--
-- Platform:
--		Not //Unix//
-- Comments:
-- Predefined cursors are:
--	
-- <eucode>
-- export constant 
--     NO_CURSOR              = #2000,
--     UNDERLINE_CURSOR       = #0607,
--     THICK_UNDERLINE_CURSOR = #0507,
--     HALF_BLOCK_CURSOR      = #0407,
--     BLOCK_CURSOR           = #0007
-- </eucode>
--
-- The second and fourth hex digits (from the left) determine the top and bottom rows 
-- of pixels in the cursor. The first digit controls whether the cursor will be visible 
-- or not. For example, #0407 turns on the 4th through 7th rows.
--
--   In pixel-graphics modes no cursor is displayed.
--
-- Example 1:
-- <eucode>
-- cursor(BLOCK_CURSOR)
-- </eucode>
--
-- See Also:
--
--   [[:graphics_mode]], [[:text_rows]]

export procedure cursor(integer style)
	machine_proc(M_CURSOR, style)
end procedure

--**
-- Free (delete) any console window associated with your program.
--
-- Comments:
--     Euphoria will create a console text window for your program the first time that your 
--     program prints something to the screen, reads something from the keyboard, or in some 
--     way needs a console (similar to a DOS-prompt window). On WIN32 this window will 
--     automatically disappear when your program terminates, but you can call free_console()
--     to make it disappear sooner. On Linux or FreeBSD, the text mode console is always 
--     there, but an xterm window will disappear after Euphoria issues a "Press Enter" prompt 
--     at the end of execution.
--
--     On Unix-style systems, free_console() will set the terminal parameters back to normal,
--     undoing the effect that curses has on the screen.
--
--     In an xterm window, a call to free_console(), without any further
--     printing to the screen or reading from the keyboard, will eliminate the 
--     "Press Enter" prompt that Euphoria normally issues at the end of execution.
--
--     After freeing the console window, you can create a new console window by printing 
--     something to the screen, or simply calling clear_screen(), position() or any other 
--     routine that needs a console.
--
--     When you use the trace facility, or when your program has an error, Euphoria will 
--     automatically create a console window to display trace information, error messages etc.
--
--     There's a WIN32 API routine, FreeConsole() that does something similar to 
--     free_console(). You should use free_console() instead, because it lets the interpreter know
--     that there is no longer a console to write to or read from.
--
-- See Also:
--     [[:clear_screen]]

export procedure free_console()
	machine_proc(M_FREE_CONSOLE, 0)
end procedure


