-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.1
-- Graphics & Sound Routines

--    GRAPHICS MODES --  argument to graphics_mode()

-- mode  description
-- ----  -----------
--   -1  restore to original default mode
--    0  40 x 25 text, 16 grey
--    1  40 x 25 text, 16/8 color
--    2  80 x 25 text, 16 grey
--    3  80 x 25 text, 16/8 color
--    4  320 x 200, 4 color
--    5  320 x 200, 4 grey
--    6  640 x 200, BW
--    7  80 x 25 text, BW
--   11  720 x 350, BW  (many video cards are lacking this one)
--   13  320 x 200, 16 color
--   14  640 x 200, 16 color
--   15  640 x 350, BW  (may be 4-color with blinking)
--   16  640 x 350, 4 or 16 color
--   17  640 x 480, BW
--   18  640 x 480, 16 color
--   19  320 x 200, 256 color
--  256  640 x 400, 256 color  (some cards are missing this one)
--  257  640 x 480, 256 color  (some cards are missing this one)
--  258  800 x 600, 16 color
--  259  800 x 600, 256 color
--  260  1024 x 768, 16 color
--  261  1024 x 768, 256 color

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
global integer 
	 BLUE, CYAN, RED, BROWN, BRIGHT_BLUE, BRIGHT_CYAN, BRIGHT_RED, YELLOW

include misc.e

if platform() = LINUX then
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
end if

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

global function graphics_mode(mode m)
-- try to set up a new graphics mode
-- return 0 if successful, non-zero if failed
   return machine_func(M_GRAPHICS_MODE, m)
end function

global constant VC_COLOR = 1,
		VC_MODE  = 2,
		VC_LINES = 3,
		VC_COLUMNS = 4,
		VC_XPIXELS = 5,
		VC_YPIXELS = 6,
		VC_NCOLORS = 7,
		VC_PAGES = 8
global function video_config()
-- return sequence of information on video configuration
-- {color?, mode, text lines, text columns, xpixels, ypixels, #colors, pages}
    return machine_func(M_VIDEO_CONFIG, 0)
end function

-- cursor styles:
global constant NO_CURSOR       = #2000,
	 UNDERLINE_CURSOR       = #0607,
	 THICK_UNDERLINE_CURSOR = #0507,
	 HALF_BLOCK_CURSOR      = #0407,
	 BLOCK_CURSOR           = #0007
	 

global procedure cursor(integer style)
-- choose a cursor style
    machine_proc(M_CURSOR, style)
end procedure

global function get_position()
-- return {line, column} of current cursor position
    return machine_func(M_GET_POSITION, 0)
end function

global function text_rows(positive_int rows)
    return machine_func(M_TEXTROWS, rows)
end function

global procedure wrap(boolean on)
-- on = 1: characters will wrap at end of long line
-- on = 0: lines will be truncated
    machine_proc(M_WRAP, on)
end procedure

global procedure scroll(integer amount, 
			positive_int top_line, 
			positive_int bottom_line)
-- scroll lines of text on screen between top_line and bottom_line
-- amount > 0: scroll text up by amount lines
-- amount < 0: scroll text down by amount lines
-- (had only the first parameter in v1.2)   
    machine_proc(M_SCROLL, {amount, top_line, bottom_line})
end procedure

global procedure text_color(color c)
-- set the foreground text color to c - text or graphics modes
-- add 16 to get blinking
    machine_proc(M_SET_T_COLOR, c)
end procedure

global procedure bk_color(color c)
-- set the background color to c - text or graphics modes
    machine_proc(M_SET_B_COLOR, c)
end procedure



