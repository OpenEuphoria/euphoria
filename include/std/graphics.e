-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Cross Platform Graphics
--
-- <<LEVELTOC depth=2>>
--

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

--**
-- Signature:
-- <built-in> procedure position(integer row, integer column)
--
-- Parameters:
-- 		# ##row##: an integer, the index of the row to position the cursor on.
-- 		# ##column##: an integer, the index of the column to position the cursor on.
--
-- Description:
--   Set the cursor to line ##row##, column ##column##, where the top left corner of the screen is line 1,
--   column 1 in text mode, row 0 and column 0 in graphic mode. The next character displayed on the screen will be printed at this location.
--   position() will report an error if the location is off the screen. The //Windows// console does not check for rows, as the physical height of the console may be vastly less than its logical height.
--
-- Comments:
--   ##position##() works in both text and pixel-graphics modes.
--
--   The coordinate system for displaying text is different from the one for displaying
--   pixels. Pixels are displayed such that the top-left is (x=0,y=0) and the first
--   coordinate controls the horizontal, left-right location. In pixel-graphics modes 
--   you can display both text and pixels. position() only sets the line and column for 
--   the text that you display, not the pixels that you plot. There is no corresponding 
--   routine for setting the next pixel position. 
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
-- 		A **sequence** ##{line, column}##, the current position of the text mode cursor.
--
-- Comments:
--   ##get_position()## works in both text and pixel-graphics modes. In pixel-graphics 
--   modes no cursor will be displayed, but ##get_position()## will return the line and 
--   column where the next character will be displayed.
--	
--   The coordinate system for displaying text is different from the one for displaying pixels. 
--   Pixels are displayed such that the top-left is (x=0,y=0) and the first coordinate controls 
--   the horizontal, left-right location. In pixel-graphics modes you can display both text and 
--   pixels. ##get_position()## returns the current line and column for the text that you are 
--   displaying, not the pixels that you may be plotting. There is no corresponding routine for 
--   getting the current pixel position, because there is not such a thing.
--
-- See Also:
--   [[:position]], [[:get_pixel]]

public function get_position()
	return machine_func(M_GET_POSITION, 0)
end function

public include std/graphcst.e
--**
-- Set the foreground text color. 
--
-- Parameters:
-- 		# ##c##: the new text color. Add ##BLINKING## to get blinking text in some modes.
--
-- Comments:
-- Text that you print after calling ##[[:text_color]]()## will have the desired color.
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
	machine_proc(M_SET_T_COLOR, c)
end procedure

--**
-- Set the background color to one of the 16 standard colors. 
--
-- Parameters:
-- 		# ##c##: the new text color. Add ##BLINKING## to get blinking text in some modes.
-- Comments:
-- 		In pixel-graphics modes the
-- whole screen is affected immediately. In text modes any new characters that you print 
-- will have the new background color. In some text modes there might only be 8 distinct 
-- background colors available.
--
-- In pixel-graphics modes, color 0 which is normally BLACK, will be set to the same 
-- ##{r,g,b}## palette value as color number ##c##.
--
-- In some pixel-graphics modes, there is a border color that appears at the edges of 
-- the screen. In 256-color modes, this is the 17th color in the palette. You can control
-- it as you would any other color.
--
-- In text modes, to restore the original background color when your program finishes, 
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
--   [[:text_color]], [[:palette]]

public procedure bk_color(color c)
-- set the background color to c - text or graphics modes
	machine_proc(M_SET_B_COLOR, c)
end procedure

type boolean(integer n)
	return n = n = 1
end type

--**
-- Determine whether text will wrap when hitting the rightmost column.
--
-- Parameters:
-- 		# ##on##: a boolean, 0 to truncate text, nonzero to wrap.
--
-- Comments:
-- By default text will wrap.
--
-- Use ##wrap()## in text modes or pixel-graphics modes when you are displaying long 
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
--		# ##amount##: an integer, the number of lines byy which to scroll. This is >0 to scroll up and <0 to scroll down.
-- 		# ##top_line##: the 1-based number of the topmost line to scroll.
-- 		# ##bottom_line##: the 1-based number of the bottom-most line to scroll.
--
-- Comments:
-- inclusive. New blank lines will
-- appear at the top or bottom.
--
-- You could perform the scrolling operation using a series of calls to ##[:puts]]()##, 
-- but ##scroll()## is much faster.
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
-- 		# ##m##: an integer, the new graphic mode
--
-- Returns:
-- 		An **integer**, 0 on success, 1 on failure.
--
-- Comments:
-- Some modes are referred to as text modes because they only let you display text. Other modes are 
-- referred to as pixel-graphics modes because you can display pixels, lines, ellipses etc., 
-- as well as text.
-- 
-- As a convenience to your users, it is usually a good idea to switch back from a pixel-graphics 
-- mode to the standard text mode before your program terminates. You can do this with 
-- [[:graphics_mode]](-1). If a pixel-graphics program leaves your screen in a mess, you can clear 
-- it up with the DOS CLS command, or by running ex or ed.
--
-- Some graphics cards will be unable to enter some SVGA modes, under some conditions. You can't 
-- always tell from the returned value, whether the graphics mode was set up successfully.
--
-- On the //Windows// and //Unix// platforms, ##[[:graphics_mode]]()## will allocate a plain, text mode 
-- console if one does not exist yet. It will then return 0, no matter what value is passed as m.
--
-- Possible graphic modes:
--
-- | mode |  description |
-- |  -1  | restore to original default mode |
-- |   0  | 40 x 25 text, 16 grey |
-- |   1  | 40 x 25 text, 16/8 color |
-- |   2  | 80 x 25 text, 16 grey |
-- |   3  | 80 x 25 text, 16/8 color |
-- |   4  | 320 x 200, 4 color |
-- |   5  | 320 x 200, 4 grey |
-- |   6  | 640 x 200, BW |
-- |   7  | 80 x 25 text, BW |
-- |  11  | 720 x 350, BW  (many video cards are lacking this one) |
-- |  13  | 320 x 200, 16 color |
-- |  14  | 640 x 200, 16 color |
-- |  15  | 640 x 350, BW  (may be 4-color with blinking) |
-- |  16  | 640 x 350, 4 or 16 color |
-- |  17  | 640 x 480, BW |
-- |  18  | 640 x 480, 16 color |
-- |  19  | 320 x 200, 256 color |
-- | 256  | 640 x 400, 256 color  (some cards are missing this one) |
-- | 257  | 640 x 480, 256 color  (some cards are missing this one) |
-- | 258  | 800 x 600, 16 color |
-- | 259  | 800 x 600, 256 color |
-- | 260  | 1024 x 768, 16 color |
-- | 261  | 1024 x 768, 256 color |
--
-- Example 1:
-- <eucode>	
-- if graphics_mode(18) then
--     puts(SCREEN, "need VGA graphics!\n")
--     abort(1)
-- end if
-- draw_line(BLUE, {{0,0}, {50,50}})
-- </eucode>
--
-- See Also:
-- 		[[:video_config]]

public function graphics_mode(mode m)
   return machine_func(M_GRAPHICS_MODE, m)
end function
