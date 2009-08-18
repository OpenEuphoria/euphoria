-- (c) Copyright - See License.txt
--

--****
-- === Error Code Constants
--
namespace graphcst

public enum
	BMP_SUCCESS,
	BMP_OPEN_FAILED,
	BMP_UNEXPECTED_EOF,
	BMP_UNSUPPORTED_FORMAT,
	BMP_INVALID_MODE

--****
-- === video_config sequence accessors

public enum
	VC_COLOR,
	VC_MODE,
	VC_LINES,
	VC_COLUMNS,
	VC_XPIXELS,
	VC_YPIXELS,
	VC_NCOLORS,
	VC_PAGES,
	VC_SCRNLINES,
	VC_SCRNCOLS

--****
-- ==== Colors
--

-- COLOR values -- for characters and pixels
public constant
	--** in graphics modes this is "transparent"
	BLACK = 0,
	GREEN = 2,
	MAGENTA = 5,
	WHITE = 7,
	GRAY  = 8,
	BRIGHT_GREEN = 10,
	BRIGHT_MAGENTA = 13,
	BRIGHT_WHITE = 15

public integer BLUE, CYAN, RED, BROWN, BRIGHT_BLUE, BRIGHT_CYAN,
	BRIGHT_RED, YELLOW

ifdef UNIX then
	BLUE        =  4
	CYAN        =  6
	RED         =  1
	BROWN       =  3
	BRIGHT_BLUE = 12
	BRIGHT_CYAN = 14
	BRIGHT_RED  =  9
	YELLOW      = 11
elsedef
	BLUE        =  1
	CYAN        =  3
	RED         =  4
	BROWN       =  6
	BRIGHT_BLUE =  9
	BRIGHT_CYAN = 11
	BRIGHT_RED  = 12
	YELLOW      = 14
end ifdef

--** Add to color to get blinking text
public constant BLINKING = 16

public constant BYTES_PER_CHAR = 2

public type color(integer x)
	return x >= 0 and x <= 255
end type

--****
-- === Routines

--**
-- Mixture Type
--
-- Comments:
--
-- A mixture is a ##{red, green, blue}## triple of intensities, which enables you to define
-- custom colors. Intensities must be from 0 (weakest) to 63 (strongest). Thus, the brightest
-- white is {63, 63, 63}.

public type mixture(sequence s)
	if length(s) != 3 then
		return 0
	end if
	for i=1 to 3 do
		if not integer(s[i]) then
			return 0
		end if
  		if and_bits(s[i],#FFFFFFC0) then
  			return 0
  		end if
	end for
	return 1
end type

constant
	M_VIDEO_CONFIG   = 13

--**
-- Return a description of the current video configuration:
--
-- Returns:
-- 		A **sequence**, of 10 non-negative integers, laid out as follows:
--	# color monitor? ~-- 1 0 if monochrome, 1 otherwise
--	# current video mode
-- 	# number of text rows in console buffer
-- 	# number of text columns in console buffer
--	# screen width in pixels
--	# screen height in pixels
--	# number of colors
--	# number of display pages
-- 	# number of text rows for current screen size
-- 	# number of text columns for current screen size
--
-- Comments:
--
-- A public enum is available for convenient access to the returned configuration data:
--     * ##VC_COLOR##
--     * ##VC_MODE##
--     * ##VC_LINES##
--     * ##VC_COLUMNS##
--     * ##VC_XPIXELS##
--     * ##VC_YPIXELS##
--     * ##VC_NCOLORS##
--     * ##VC_PAGES##
--     * ##VC_LINES##
--     * ##VC_COLUMNS##
--     * ##VC_SCRNLINES##
--     * ##VC_SCRNCOLS##
--
-- This routine makes it easy for you to parameterize a program so it will work in many
-- different graphics modes.
--
-- Example:
-- <eucode>
-- vc = video_config()
-- -- vc could be {1, 3, 300, 132, 0, 0, 32, 8, 37, 90}
-- </eucode>
--
-- See Also:
-- 		[[:graphics_mode]]

public function video_config()
	return machine_func(M_VIDEO_CONFIG, 0)
end function

