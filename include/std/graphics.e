-- (c) Copyright - See License.txt
--
--****
-- == Graphics - Cross Platform
--
-- <<LEVELTOC depth=2>>
--
namespace graphics

constant
	M_GRAPHICS_MODE  = 5,
	M_WRAP           = 7,
	M_SCROLL         = 8,
	M_SET_T_COLOR    = 9,
	M_SET_B_COLOR    = 10,
	M_GET_POSITION   = 25

public include std/console.e

--****
-- === Routines
--

--****
-- Signature:
-- <built-in> procedure position(integer row, integer column)
--
-- Parameters:
-- 		# ##row## : an integer, the index of the row to position the cursor on.
-- 		# ##column## : an integer, the index of the column to position the cursor on.
--
-- Description:
--   Set the cursor to line ##row##, column ##column##, where the top left corner of the screen is line 1,
--   column 1. The next character displayed on the screen will be printed at this location.
--   ##position##() will report an error if the location is off the screen. 
--   The //Windows// console does not check for rows, as the physical height of the
--   console may be vastly less than its logical height.
--
-- Example 1:
--   <eucode>
--   position(2,1)
--   -- the cursor moves to the beginning of the second line from the top
--  </eucode>
-- See Also:
-- 		[[:get_position]]

--**
-- Return the current line and column position of the cursor 
--
-- Returns:
-- 		A **sequence**, ##{line, column}##, the current position of the text mode cursor.
--
-- Comments:
--   The coordinate system for displaying text is different from the one for displaying pixels. 
--   Pixels are displayed such that the top-left is (x=0,y=0) and the first coordinate controls 
--   the horizontal, left-right location. In pixel-graphics modes you can display both text and 
--   pixels. ##get_position##() returns the current line and column for the text that you are 
--   displaying, not the pixels that you may be plotting. There is no corresponding routine for 
--   getting the current pixel position, because there is not such a thing.
--
-- See Also:
--   [[:position]]

public function get_position()
	return machine_func(M_GET_POSITION, 0)
end function

public include std/graphcst.e

--**
-- Set the foreground text color. 
--
-- Parameters:
-- 		# ##c## : the new text color. Add ##BLINKING## to get blinking text in some modes.
--
-- Comments:
-- Text that you print after calling ##[[:text_color]]##() will have the desired color.
--
-- When your program terminates, the last color that you selected and actually printed on the 
-- screen will remain in effect. Thus you may have to print something, maybe just ##'\n'##, 
-- in ##WHITE## to restore white text, especially if you are at the bottom line of the 
-- screen, ready to scroll up.
--
-- Example:
-- <eucode>	
-- text_color(BRIGHT_BLUE)
-- </eucode>
--
-- See Also:
--   [[:bk_color]] , [[:clear_screen]]

public procedure text_color(color c)
-- set the foreground text color to c - text or graphics modes
-- add 16 to get blinking
	c = and_bits(c, 0x1F)
ifdef OSX then
	c = true_color[c+1]
elsifdef UNIX then
	c = true_color[c+1]
end ifdef
	machine_proc(M_SET_T_COLOR, c)
end procedure

--**
-- Set the background color to one of the 16 standard colors. 
--
-- Parameters:
-- 		# ##c## : the new text color. Add ##BLINKING## to get blinking text in some modes.
--
-- Comments:
-- To restore the original background color when your program finishes, 
-- e.g. ##0 - BLACK##, you must call ##[[:bk_color]](0)##. If the cursor is at the bottom 
-- line of the screen, you may have to actually print something before terminating your 
-- program. Printing ##'\n'## may be enough.
--
-- Example:
-- <eucode>	
-- bk_color(BLACK)
-- </eucode>
--	
-- See Also:
--   [[:text_color]]

public procedure bk_color(color c)
-- set the background color to c - text or graphics modes
	c = and_bits(c, 0x1F)
ifdef OSX then
	c = true_color[c+1]
elsifdef UNIX then
	c = true_color[c+1]
end ifdef
	machine_proc(M_SET_B_COLOR, c)
end procedure

type boolean(integer n)
	return n = n = 1
end type

--**
-- Determine whether text will wrap when hitting the rightmost column.
--
-- Parameters:
-- 		# ##on## : a boolean, 0 to truncate text, nonzero to wrap.
--
-- Comments:
-- By default text will wrap.
--
-- Use ##wrap##() in text modes or pixel-graphics modes when you are displaying long 
-- lines of text.
--
-- Example:
-- <eucode>	
-- puts(1, repeat('x', 100) & "\n\n")
-- -- now have a line of 80 'x' followed a line of 20 more 'x'
-- wrap(0)
-- puts(1, repeat('x', 100) & "\n\n")
-- -- creates just one line of 80 'x'
-- </eucode>
--	
-- See Also:
--   [[:puts]], [[:position]]

public procedure wrap(boolean on)
	machine_proc(M_WRAP, on)
end procedure

--**
-- Scroll a region of text on the screen.
--
-- Parameters:
--		# ##amount## : an integer, the number of lines by which to scroll. This is >0 to scroll up and <0 to scroll down.
-- 		# ##top_line## : the 1-based number of the topmost line to scroll.
-- 		# ##bottom_line## : the 1-based number of the bottom-most line to scroll.
--
-- Comments:
-- inclusive. New blank lines will
-- appear at the top or bottom.
--
-- You could perform the scrolling operation using a series of calls to ##[:puts]]()##, 
-- but ##scroll##() is much faster.
--
-- The position of the cursor after scrolling is not defined.
--
-- Example 1:
--   ##bin/ed.ex##
--
-- See Also:
--   [[:clear_screen]], [[:text_rows]]

public procedure scroll(integer amount, 
						positive_int top_line, 
						positive_int bottom_line)
	machine_proc(M_SCROLL, {amount, top_line, bottom_line})
end procedure

--****
-- === Graphics Modes

type mode(integer x)
	return (x >= -3 and x <= 19) or (x >= 256 and x <= 263)
end type

--**
-- Attempt to set up a new graphics mode.
--
-- Parameters:
-- 		# ##m## : an integer, ignored.
--
-- Returns:
-- 		An **integer**, always returns zero. 
--
-- Comments:
-- * This has no effect on Unix platforms.
-- * On Windows, it causes a console to be shown if one has not already been created.
-- See Also:
-- 		[[:video_config]]

public function graphics_mode(mode m = -1)
   return machine_func(M_GRAPHICS_MODE, m)
end function
