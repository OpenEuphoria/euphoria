-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Graphics and Sound
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>
--
-- === Graphics Modes
-- 
-- argument to graphics_mode()
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

--****
-- === Constants
--
-- ==== Colors
-- ===== Normal
-- * BLACK
-- * BLUE
-- * BROWN
-- * CYAN
-- * GRAY
-- * GREEN
-- * MAGENTA
-- * RED
-- * WHITE
-- * YELLOW
--
-- ===== Bright
-- * BRIGHT_BLUE
-- * BRIGHT_CYAN
-- * BRIGHT_GREEN
-- * BRIGHT_MAGENTA
-- * BRIGHT_RED
-- * BRIGHT_WHITE
--
-- ===== Miscellaneous
-- * BLINKING

-- COLOR values -- for characters and pixels
global constant 
		 BLACK = 0,  -- in graphics modes this is "transparent"
		 GREEN = 2,
		 MAGENTA = 5,
		 WHITE = 7,
		 GRAY  = 8,
		 BRIGHT_GREEN = 10,
		 BRIGHT_MAGENTA = 13,
		 BRIGHT_WHITE = 15
		 
global integer BLUE, CYAN, RED, BROWN, BRIGHT_BLUE, BRIGHT_CYAN, BRIGHT_RED, YELLOW

ifdef UNIX then
	BLUE  = 4
	CYAN =  6
	RED   = 1
	BROWN = 3
	BRIGHT_BLUE = 12
	BRIGHT_CYAN = 14
	BRIGHT_RED = 9
	YELLOW = 11
else
	BLUE  = 1
	CYAN =  3
	RED   = 4
	BROWN = 6
	BRIGHT_BLUE = 9
	BRIGHT_CYAN = 11
	BRIGHT_RED = 12
	YELLOW = 14
end ifdef

global constant BLINKING = 16  -- add to color to get blinking text

-- machine() commands
constant M_SOUND          = 1,
		 M_LINE           = 2,
		 M_PALETTE        = 3,
		 M_GRAPHICS_MODE  = 5,
		 M_CURSOR         = 6,
		 M_WRAP           = 7,
		 M_SCROLL         = 8,
		 M_SET_T_COLOR    = 9,
		 M_SET_B_COLOR    = 10,
		 M_POLYGON        = 11,
		 M_TEXTROWS       = 12,
		 M_VIDEO_CONFIG   = 13,
		 M_ELLIPSE        = 18,
		 M_GET_POSITION   = 25,
		 M_ALL_PALETTE    = 27

type mode(integer x)
	return (x >= -3 and x <= 19) or (x >= 256 and x <= 263)
end type

type color(integer x)
	return x >= 0 and x <= 255
end type

type boolean(integer x)
	return x = 0 or x = 1
end type

type positive_int(integer x)
	return x >= 1
end type

type point(sequence x)
	return length(x) = 2
end type

type point_sequence(sequence x)
	return length(x) >= 2
end type

--****
-- === Routines
--

--**
-- Signature:
-- global procedure position(integer i1, integer i2)
--
-- Description:
--   Set the cursor to line i1, column i2, where the top left corner of the screen is line 1, 
--   column 1. The next character displayed on the screen will be printed at this location. 
--   position() will report an error if the location is off the screen.
--
-- Comments:
--   position() works in both text and pixel-graphics modes.
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
---  </eucode>

--**
-- Draw a line on a pixel-graphics screen connecting two or more points in s, using color i.
--
-- Example: 	
-- <eucode>
-- draw_line(WHITE, {{100, 100}, {200, 200}, {900, 700}})
--
-- -- This would connect the three points in the sequence using
-- -- a white line, i.e. a line would be drawn from {100, 100} to
-- -- {200, 200} and another line would be drawn from {200, 200} to
-- -- {900, 700}.
-- </eucode>

global procedure draw_line(color c, point_sequence xyarray)
-- draw a line connecting the 2 or more points
-- in xyarray: {{x1, y1}, {x2, y2}, ...}
-- using a certain color 
	machine_proc(M_LINE, {c, 0, xyarray})
end procedure

--**
-- Draw a polygon with 3 or more vertices given in s, on a pixel-graphics screen using a certain 
-- color i1. Fill the area if i2 is 1. Don't fill if i2 is 0.
--
-- Example:
-- <eucode>
-- polygon(GREEN, 1, {{100, 100}, {200, 200}, {900, 700}})
-- -- makes a solid green triangle.
-- </eucode>

global procedure polygon(color c, boolean fill, point_sequence xyarray)
-- draw a polygon using a certain color
-- fill the area if fill is TRUE
-- 3 or more vertices are given in xyarray
	machine_proc(M_POLYGON, {c, fill, xyarray})
end procedure

--**
-- Draw an ellipse with color i1 on a pixel-graphics screen. The ellipse will neatly fit 
-- inside the rectangle defined by diagonal points s1 {x1, y1} and s2 {x2, y2}. If the 
-- rectangle is a square then the ellipse will be a circle. Fill the ellipse when i2 is 1. 
-- Don't fill when i2 is 0.
--
-- Example:	
-- <eucode>	
-- ellipse(MAGENTA, 0, {10, 10}, {20, 20})
--	
-- -- This would make a magenta colored circle just fitting
-- -- inside the square: 
-- --        {10, 10}, {10, 20}, {20, 20}, {20, 10}.
-- </eucode>

global procedure ellipse(color c, boolean fill, point p1, point p2)
-- draw an ellipse with a certain color that fits in the
-- rectangle defined by diagonal points p1 and p2, i.e. 
-- {x1, y1} and {x2, y2}. The ellipse may be filled or just an outline.   
	machine_proc(M_ELLIPSE, {c, fill, p1, p2})
end procedure

--**
-- Select graphics mode i2. If successful, i1 is set to 0, otherwise i1 is set to 1.
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
-- always tell from the i1 value, whether the graphics mode was set up successfully.
--
-- On the //Windows// and //Unix// platforms, ##[[:graphics_mode]]()## will allocate a plain, text mode 
-- console if one does not exist yet. It will then return 0, no matter what value is passed as i2.
--
-- Example:
-- <eucode>	
-- if graphics_mode(18) then
--     puts(SCREEN, "need VGA graphics!\n")
--     abort(1)
-- end if
-- draw_line(BLUE, {{0,0}, {50,50}})
-- </eucode>

global function graphics_mode(mode m)
-- try to set up a new graphics mode
-- return 0 if successful, non-zero if failed
   return machine_func(M_GRAPHICS_MODE, m)
end function

global enum 
	VC_COLOR,
	VC_MODE,
	VC_LINES,
	VC_COLUMNS,
	VC_XPIXELS,
	VC_YPIXELS,
	VC_NCOLORS,
	VC_PAGES

--**
-- Return a sequence of values describing the current video configuration:
--
-- {{{
-- {
--     color monitor?, graphics mode, text rows, text columns, xpixels, 
--     ypixels, number of colors, number of pages
-- }
-- }}}
--
--
-- <eucode>
-- global constant 
--     VC_COLOR   = 1,
--     VC_MODE    = 2,
--     VC_LINES   = 3,
--     VC_COLUMNS = 4,
--     VC_XPIXELS = 5,
--     VC_YPIXELS = 6,
--     VC_NCOLORS = 7,
--     VC_PAGES   = 8
-- </eucode>
--
-- Comments:
-- This routine makes it easy for you to parameterize a program so it will work in many 
-- different graphics modes.
--
-- On the PC there are two types of graphics mode. The first type, text mode, lets you 
-- print text only. The second type, pixel-graphics mode, lets you plot pixels, or points, 
-- in various colors, as well as text. You can tell that you are in a text mode, because 
-- the ##VC_XPIXELS## and ##VC_YPIXELS## fields will be 0. Library routines such as 
-- [[:polygon]], [[:draw_line]], and [[:ellipse]] only work in a pixel-graphics mode.
--
-- Example:
-- <eucode>
-- -- vc = video_config()  -- in mode 3 with 25-lines of text:
-- -- vc is {1, 3, 25, 80, 0, 0, 32, 8}
-- </eucode>

global function video_config()
-- return sequence of information on video configuration
-- {color?, mode, text lines, text columns, xpixels, ypixels, #colors, pages}
	return machine_func(M_VIDEO_CONFIG, 0)
end function

-- cursor styles:
global constant 
	NO_CURSOR              = #2000,
	UNDERLINE_CURSOR       = #0607,
	THICK_UNDERLINE_CURSOR = #0507,
	HALF_BLOCK_CURSOR      = #0407,
	BLOCK_CURSOR           = #0007
		 
--**
-- Select a style of cursor.
--
-- Predefined cursors are:
--	
-- <eucode>
-- global constant 
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
-- Comments:
--   In pixel-graphics modes no cursor is displayed.
--
-- Example:	
-- <eucode>
-- cursor(BLOCK_CURSOR)
-- </eucode>
--
-- See Also:
--   [[:graphics_mode]], [[:text_rows]]

global procedure cursor(integer style)
-- choose a cursor style
	machine_proc(M_CURSOR, style)
end procedure

--**
-- Return the current line and column position of the cursor as a 2-element 
-- sequence ##{line, column}##.
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
--   getting the current pixel position.
--
-- See Also:
--   [[:position]], [[:get_pixel]]

global function get_position()
-- return {line, column} of current cursor position
	return machine_func(M_GET_POSITION, 0)
end function

--**
-- Set the number of lines on a text-mode screen to i1 if possible. i2 will be set to the actual 
-- new number of lines.
--
-- Comments:
-- Values of 25, 28, 43 and 50 lines are supported by most video cards.
--
-- See Also:
--   [[:graphics_mode]]

global function text_rows(positive_int rows)
	return machine_func(M_TEXTROWS, rows)
end function

--**
-- Allow text to wrap at the right margin (##on## = ##TRUE##) or get truncated 
-- (##on## = ##FALSE##).
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

global procedure wrap(boolean on)
-- on = 1: characters will wrap at end of long line
-- on = 0: lines will be truncated
	machine_proc(M_WRAP, on)
end procedure

--**
-- Scroll a region of text on the screen either up (##amount## positive) or down 
-- (##amount## negative) by ##amount## lines. The region is the series of lines on 
-- the screen from ##top_line## to ##bottom_line##, inclusive. New blank lines will 
-- appear at the top or bottom.
--
-- Comments:
-- You could perform the scrolling operation using a series of calls to ##[:puts]]()##, 
-- but ##scroll()## is much faster.
--
-- The position of the cursor after scrolling is not defined.
--
-- Example Program:
--   ##bin\ed.ex##
--
-- See Also:
--   [[:clear_screen]], [[:text_rows]]

global procedure scroll(integer amount, 
						positive_int top_line, 
						positive_int bottom_line)
-- scroll lines of text on screen between top_line and bottom_line
-- amount > 0: scroll text up by amount lines
-- amount < 0: scroll text down by amount lines
-- (had only the first parameter in v1.2)   
	machine_proc(M_SCROLL, {amount, top_line, bottom_line})
end procedure

--**
-- Set the foreground text color. Add ##BLINKING## to get blinking text in some modes.
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
--   [[:bk_color]]

global procedure text_color(color c)
-- set the foreground text color to c - text or graphics modes
-- add 16 to get blinking
	machine_proc(M_SET_T_COLOR, c)
end procedure

--**
-- Set the background color to one of the 16 standard colors. In pixel-graphics modes the 
-- whole screen is affected immediately. In text modes any new characters that you print 
-- will have the new background color. In some text modes there might only be 8 distinct 
-- background colors available.
--
-- Comments:
-- In pixel-graphics modes, color 0 which is normally BLACK, will be set to the same 
-- ##{r,g,b}## palette value as color number i.
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

global procedure bk_color(color c)
-- set the background color to c - text or graphics modes
	machine_proc(M_SET_B_COLOR, c)
end procedure

--**
-- Mixture Type
--
-- ##{red, green, blue}##

export type mixture(sequence s)
	return length(s) = 3
end type

--**
-- Change the color for color number ##c## to ##s##, where ##s## is a sequence of 
-- color intensities: ##{red, green, blue}##. Each value in ##s## can be from 0 to 
-- 63. If successful, a  3-element sequence containing the previous color for ##c## will 
-- be returned, and all pixels on the screen with value ##c## will be set to the new 
-- color. If unsuccessful, the ##atom -1## will be returned.
--
-- Example:
-- <eucode>	 	
-- x = palette(0, {15, 40, 10})
-- -- color number 0 (normally black) is changed to a shade
-- -- of mainly green.
-- </eucode>
--
-- See Also:
--   [[:all_pallet]]

global function palette(color c, mixture s)
-- choose a new mix of {red, green, blue} to be shown on the screen for
-- color number c. Returns previous mixture as {red, green, blue}.
	return machine_func(M_PALETTE, {c, s})
end function

--**
-- Specify new color intensities for the entire set of colors in the current graphics mode. 
-- s is a sequence of the form:
-- 
-- ##{{r,g,b}, {r,g,b}, ..., {r,g,b}}##
--
-- Each element specifies a new color intensity ##{red, green, blue}## for the corresponding 
-- color number, starting with color number 0. The values for red, green and blue must be 
-- in the range 0 to 63.
--
-- Comments:
-- This executes much faster than if you were to use ##[[:palette]]()## to set the new color 
-- intensities one by one. This procedure can be used with ##[[:read_bitmap]]()## to quickly 
-- display a picture on the screen.
--
-- Example Program:
--   ##demo\dos32\bitmap.ex##

global procedure all_palette(sequence s)
-- s is a sequence of the form: {{r,g,b},{r,g,b}, ...{r,g,b}}
-- that specifies new color intensities for the entire set of
-- colors in the current graphics mode.  
	machine_proc(M_ALL_PALETTE, s)
end procedure

--****
-- === Sound Effects

--**
-- Frequency Type

export type frequency(integer x)
	return x >= 0
end type

--**
-- Turn on the PC speaker at frequency i. If i is 0 the speaker will be turned off.
--
-- Comments:
-- On //Windows// and //Unix// platforms no sound will be made.
--
-- Example:
-- <eucode>	
-- sound(1000) -- starts a fairly high pitched sound
-- </eucode>

global procedure sound(frequency f)
-- turn on speaker at frequency f
-- turn off speaker if f is 0
	machine_proc(M_SOUND, f)
end procedure
