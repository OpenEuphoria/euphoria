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
export constant
		 BLACK = 0,  -- in graphics modes this is "transparent"
		 GREEN = 2,
		 MAGENTA = 5,
		 WHITE = 7,
		 GRAY  = 8,
		 BRIGHT_GREEN = 10,
		 BRIGHT_MAGENTA = 13,
		 BRIGHT_WHITE = 15
		 
export integer BLUE, CYAN, RED, BROWN, BRIGHT_BLUE, BRIGHT_CYAN, BRIGHT_RED, YELLOW

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

export constant BLINKING = 16  -- add to color to get blinking text

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
-- export procedure position(integer row, integer column)
--
-- Platform:
-- 	DOS32
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
--  </eucode>
-- See Also:
-- 		[[:get_position]]

--**
-- Draw a line on a pixel-graphics screen connecting two or more points in s, using color i.
--
-- Platform:
-- 	//DOS32//
--
-- Parameters:
-- 		# ##c##: an integer, the color with which the line is to be drawn
-- 		# ##xyarray##: a sequence of pairs of coordinates, which represent the vertices of the line.
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
--
-- See Also:
-- 		[[:polygon]]

export procedure draw_line(color c, point_sequence xyarray)
	machine_proc(M_LINE, {c, 0, xyarray})
end procedure

--**
-- Draw a polygon with 3 or more vertices on a pixel-graphics screen.
-- 
-- Platform:
-- 	//DOS32//
--
-- Parameters:
-- 		# ##c##: an integer, the color with which the border line is to be drawn
-- 		# ##fill##: an integer, 0 to draw the outline only, nonzero to fill the polygon
-- 		# ##xyarray##: a sequence of pairs of coordinates, which represent the vertices of the polygon outline.
--
-- Example:
-- <eucode>
-- polygon(GREEN, 1, {{100, 100}, {200, 200}, {900, 700}})
-- -- makes a solid green triangle.
-- </eucode>
-- See Also:
-- 		[[:draw_line]]
export procedure polygon(color c, boolean fill, point_sequence xyarray)
	machine_proc(M_POLYGON, {c, fill, xyarray})
end procedure

--**
-- Draw an ellipse with on a pixel-graphics screen. 
--
-- Platform:
-- 	//DOS32//
--
-- Parameters:
-- 		# ##c##: an integer, the color with which the border line is to be drawn
-- 		# ##fill##: an integer, 0 to draw the outline only, nonzero to fill the ellipse
-- 		# ##p1##: a sequence, the coordinates of the upper left corner of the bounding rectangle of the ellipse
-- 		# ##p2##: a sequence, the coordinates of the lower right corner of the bounding rectangle of the ellipse.
--
-- Comments:
-- The ellipse will neatly fit
-- inside the rectangle defined by diagonal points p1 {x1, y1} and p2 {x2, y2}. If the
-- rectangle is a square then the ellipse will be a circle. 
--
-- This procedure can only draw ellipses whose axes are horizontal and vertical, not tilted ones.
--
-- Example:	
-- <eucode>	
-- ellipse(MAGENTA, 0, {10, 10}, {20, 20})
--	
-- -- This would make a magenta colored circle just fitting
-- -- inside the square: 
-- --        {10, 10}, {10, 20}, {20, 20}, {20, 10}.
-- </eucode>

export procedure ellipse(color c, boolean fill, point p1, point p2)
	machine_proc(M_ELLIPSE, {c, fill, p1, p2})
end procedure

--**
-- Attempt to set up a new graphics mode.
--
-- Parameters:
-- 		# ##m###: an integer, the new graphic mode
--
-- Platform:
-- 	//DOS32//
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
-- Example:
-- <eucode>	
-- if graphics_mode(18) then
--     puts(SCREEN, "need VGA graphics!\n")
--     abort(1)
-- end if
-- draw_line(BLUE, {{0,0}, {50,50}})
-- </eucode>
-- See Also:
-- 		[[:video_config]]
export function graphics_mode(mode m)
   return machine_func(M_GRAPHICS_MODE, m)
end function

export enum 
	VC_COLOR,
	VC_MODE,
	VC_LINES,
	VC_COLUMNS,
	VC_XPIXELS,
	VC_YPIXELS,
	VC_NCOLORS,
	VC_PAGES

--**
-- Return a description of the current video configuration:
--
-- Returns:
-- 		A **sequence** of 8 nonnegative integers, laid out as follows:
--	# color monitor?: 1 0 if monochrome, 1 otherwise
--	# current video mode
-- 	# number of text rows
-- 	# number of text columns
--	# screen width in pixels
--	# screen height in pixels
--	# number of colors
--	# number of display pages
--
-- Comments:
-- An enum is available for convenient access to the returned configuration data:
-- <eucode>
-- export constant 
--     VC_COLOR   = 1,
--     VC_MODE    = 2,
--     VC_LINES   = 3,
--     VC_COLUMNS = 4,
--     VC_XPIXELS = 5,
--     VC_YPIXELS = 6,
--     VC_NCOLORS = 7,
--     VC_PAGES   = 8
-- </eucode>
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
-- See Also:
-- 		[[:graphics_mode]]
export function video_config()
	return machine_func(M_VIDEO_CONFIG, 0)
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
-- Example:	
-- <eucode>
-- cursor(BLOCK_CURSOR)
-- </eucode>
--
-- See Also:
--   [[:graphics_mode]], [[:text_rows]]

export procedure cursor(integer style)
	machine_proc(M_CURSOR, style)
end procedure

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
-- See Also:
-- 		[[:position]]

export function get_position()
	return machine_func(M_GET_POSITION, 0)
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
--   [[:graphics_mode]], [[:video_fonfig]]

export function text_rows(positive_int rows)
	return machine_func(M_TEXTROWS, rows)
end function

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

export procedure wrap(boolean on)
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
--   [[../bin/ed.ex]]
--
-- See Also:
--   [[:clear_screen]], [[:text_rows]]

export procedure scroll(integer amount, 
						positive_int top_line, 
						positive_int bottom_line)
	machine_proc(M_SCROLL, {amount, top_line, bottom_line})
end procedure

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

export procedure text_color(color c)
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

export procedure bk_color(color c)
-- set the background color to c - text or graphics modes
	machine_proc(M_SET_B_COLOR, c)
end procedure

--**
-- Mixture Type
-- Comments:
-- A mixture is a ##{red, green, blue}## triple of intensities, which enables you to define 
-- custom colors. Intensities must be from 0 (weakest) to 63 (strongest). Thus, the brightest 
-- white is {63, 63, 63}.

export type mixture(sequence s)
	if length(s) != 3 then
		return 0
	end if
	for i=1 to 3 do
		if not integer(s[i]) or and_bits(s[i],#FFFFFFC0) then
			return 0
		end if
	end for
	return 1
end type

--**
-- Change the color for color number ##c## to a mixture of elementary colors.
--
-- Platform:
--		//DOS32//
--
-- Parameters:
-- 		# ##c##: the color to redefine
--		# ##s##: a sequence of color intensities: ##{red, green, blue}##. Each value in ##s## can be from 0 to 63.
--
-- Returns:
-- 		An **object**, either -1 on failure, or a mixture representing the previous definition of ##c##.
--
-- Comments:
-- If successful, a  3-element sequence containing the previous color for ##c## will
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
--   [[:all_palette]]

export function palette(color c, mixture s)
-- choose a new mix of {red, green, blue} to be shown on the screen for
-- color number c. Returns previous mixture as {red, green, blue}.
	return machine_func(M_PALETTE, {c, s})
end function

--**
-- Specify new color intensities for the entire set of colors in the current graphics mode.
--
-- Platform:
--		//DOS32//
--
-- Parameters:
-- 		# ##s##: a sequence of 17 mixtures, i.e. ##{red, green, blue}## triples.
--
-- Comments:
-- Each element specifies a new color intensity ##{red, green, blue}## for the corresponding 
-- color number, starting with color number 0. The values for red, green and blue must be 
-- in the range 0 to 63. Last color is the border, also known as overscan, color.
--
-- This executes much faster than if you were to use ##[[:palette]]()## to set the new color
-- intensities one by one. This procedure can be used with ##[[:read_bitmap]]()## to quickly 
-- display a picture on the screen.
--
-- Example 1:
--   [[../demo/dos32/bitmap.ex]]

export procedure all_palette(sequence s)
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
-- Turn on the PC speaker at a specified frequency 
--
-- Platform:
--		//DOS32//
--
-- Parameters:
-- 		# ##f##: frequency of sound. If ##f## is 0 the speaker will be turned off.
--
-- Comments:
-- On //Windows// and //Unix// platforms no sound will be made.
--
-- Example:
-- <eucode>
-- sound(1000) -- starts a fairly high pitched sound
-- </eucode>

export procedure sound(frequency f)
-- turn on speaker at frequency f
-- turn off speaker if f is 0
	machine_proc(M_SOUND, f)
end procedure
