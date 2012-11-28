--****
-- == Graphics - Cross Platform
--
-- <<LEVELTOC level=2 depth=4>>
--

namespace graphics

include std/types.e

public include std/console.e
public include std/graphcst.e

constant
	M_GRAPHICS_MODE  = 5,
	M_WRAP           = 7,
	M_SCROLL         = 8,
	M_SET_T_COLOR    = 9,
	M_SET_B_COLOR    = 10,
	M_GET_POSITION   = 25

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
-- sets the cursor to where the next character will be output.
--
-- Comments:
--   Set the cursor to line ##row##, column ##column##, where the top left corner of the screen is line 1,
--   column 1. The next character displayed on the screen will be printed at this location.
--   ##position## will report an error if the location is off the screen. 
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
-- returns the current line and column position of the cursor. 
--
-- Returns:
-- 		A **sequence**, ##{line, column}##, the current position of the text mode cursor.
--
-- Comments:
--   The coordinate system for displaying text is different from the one for displaying pixels. 
--   Pixels are displayed such that the top-left is ##(x=0,y=0)## and the first coordinate controls 
--   the horizontal, left-right location. In pixel-graphics modes you can display both text and 
--   pixels. ##get_position## returns the current line and column for the text that you are 
--   displaying, not the pixels that you may be plotting. There is no corresponding routine for 
--   getting the current pixel position, because there is no such thing.
--
-- See Also:
--   [[:position]]

public function get_position()
	return machine_func(M_GET_POSITION, 0)
end function

public include std/graphcst.e

--**
-- sets the foreground text color. 
--
-- Parameters:
-- 		# ##c## : the new text color. Add ##BLINKING## to get blinking text in some modes.
--
-- Comments:
-- Text that you print after calling ##[[:text_color]]## will have the desired color.
--
-- When your program terminates, the last color that you selected and actually printed on the 
-- screen will remain in effect. Thus you may have to print something, maybe just ##'\n'##, 
-- in ##WHITE## to restore white text, especially if you are at the bottom line of the 
-- screen, ready to scroll up.
--
-- Example 1:
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
	c = true_fgcolor[c+1]
	machine_proc(M_SET_T_COLOR, c)
end procedure

--**
-- sets the background color to one of the sixteen standard colors. 
--
-- Parameters:
-- 		# ##c## : the new text color. Add ##BLINKING## to get blinking text in some modes.
--
-- Comments:
-- To restore the original background color when your program finishes, 
-- ( often ##0 - BLACK##), you must call ##[[:bk_color]](0)##. If the cursor is at the bottom 
-- line of the screen, you may have to actually print something before terminating your 
-- program; printing ##'\n'## may be enough.
--
-- Example 1:
-- <eucode>	
-- bk_color(BLACK)
-- </eucode>
--	
-- See Also:
--   [[:text_color]]

public procedure bk_color(color c)
-- set the background color to c - text or graphics modes
	c = and_bits(c, 0x1F)
	c = true_bgcolor[c+1]
	machine_proc(M_SET_B_COLOR, c)
end procedure

--**
-- sets the codes for the colors used in ##text_color## and ##bk_color##.
--
-- Parameters:
-- 	# ##colorset## : A sequence in one of two formats. 
--  ## Containing two sets of exactly sixteen color numbers in which the first set 
--  are foreground (text) colors and the other set are background colors.
--  ## Containing a set of exactly sixteen color numbers. These are to be
--  applied to both foreground and background.
--
-- Returns:
--    A sequence: This contains two sets of sixteen color values currently in
--    use for foreground and background respectively.
--
-- Comments:
-- * If the ##colorset## is omitted then this just returns the current values without
--   changing anything.
-- * A color set contains sixteen values. You can access the color value for a specific color
--   by using ##[X + 1]## where ##'X'## is one of the Euphoria color constants such as ##RED## or
--   ##BLUE##.
-- * This can be used to change the meaning of the standard color codes for
--   some consoles that are not using standard values. For example, the //Unix// default
--   color value for RED is 1 and BLUE is 4, but you might need this to swapped. See
--   code Example 1. Another use might be to suppress highlighted (bold) colors. See
--   code Example 2.
--
-- Example 1:
-- <eucode>	
-- sequence cs
-- cs = console_colors() -- Get the current FG and BG color values.
-- cs[FGSET][RED + 1] = 4 -- set RED to 4
-- cs[FGSET][BLUE + 1] = 1 -- set BLUE to 1
-- cs[BGSET][RED + 1] = 4 -- set RED to 4
-- cs[BGSET][BLUE + 1] = 1 -- set BLUE to 1
-- console_colors(cs)
-- </eucode>
--
-- Example 2:
-- <eucode>	
-- -- Prevent highlighted background colors
-- sequence cs
-- cs = console_colors()
-- for i = GRAY + 1 to BRIGHT_WHITE + 1 do
--    cs[BGSET][i] = cs[BGSET][i - 8]
-- end for
-- console_colors(cs)
-- </eucode>
--	
-- See Also:
--   [[:text_color]] [[:bk_color]]

public function console_colors(sequence colorset = {})
	sequence currentset
	
	-- Save the current values 
	currentset = {true_fgcolor[1 .. 16], true_bgcolor[1 .. 16]}
	
	if length(colorset) = 16 then
		-- A single set to be used for both fg and bg.
		colorset = {colorset, colorset}
	end if
	
	-- Check the sanity of the input, do nothing if it's not valid.
	if length(colorset) != 2 then
		return currentset
	end if
	if length(colorset[FGSET]) != 16 then
	   	return currentset
	end if
	if not types:char_test( colorset[FGSET], {{0,15}} ) then
	   	return currentset
	end if
	if length(colorset[BGSET]) != 16 then
	   	return currentset
	end if
	if not types:char_test( colorset[BGSET], {{0,15}} ) then
	   	return currentset
	end if
		
	-- Set text colors
	true_fgcolor[1..16]  = colorset[FGSET]
	true_fgcolor[17..32] = colorset[FGSET] + BLINKING
	
	-- Set background colors.
	true_bgcolor[1..16]  = colorset[BGSET]
	true_bgcolor[17..32] = colorset[BGSET] + BLINKING

	return currentset
end function

--**
-- determines whether text will wrap when hitting the rightmost column.
--
-- Parameters:
-- 		# ##on## : an object, 0 to truncate text, anything else to wrap.
--
-- Comments:
-- By default text will wrap.
--
-- Use ##wrap## in text modes or pixel-graphics modes when you are displaying long 
-- lines of text.
--
-- Example 1:
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

public procedure wrap(object on = 1)
	machine_proc(M_WRAP, not equal(on, 0))
end procedure

--**
-- scrolls a region of text on the screen.
--
-- Parameters:
--		# ##amount## : an integer, the number of lines by which to scroll. 
--        This is ##>0## to scroll up and ##<0## to scroll down.
-- 		# ##top_line## : the 1-based number of the topmost line to scroll.
-- 		# ##bottom_line## : the 1-based number of the bottom-most line to scroll.
--
-- Comments:
-- * New blank lines will appear at the vacated lines.
-- * You could perform the scrolling operation using a series of calls to ##[[:puts]]##, 
-- but ##scroll## is much faster.
-- * The position of the cursor after scrolling is not defined.
--
-- Example 1:
--   ##.../euphoria/bin/ed.ex##
--
-- See Also:
--   [[:clear_screen]], [[:text_rows]]

public procedure scroll(integer amount, 
						console:positive_int top_line, 
						console:positive_int bottom_line)
	machine_proc(M_SCROLL, {amount, top_line, bottom_line})
end procedure

--****
-- === Graphics Modes

--**
-- attempts to set up a new graphics mode.
--
-- Parameters:
-- 		# ##x## : an object, but it will be ignored.
--
-- Returns:
-- 		An **integer**, always returns zero. 
--
-- Platform:
--	//Windows//
--
-- Comments:
-- * This has no effect on //Unix// platforms.
-- * On //Windows// it causes a console to be shown if one has not already been created.
-- See Also:
-- 		[[:video_config]]

public function graphics_mode(object m = -1)
   return machine_func(M_GRAPHICS_MODE, m)
end function
