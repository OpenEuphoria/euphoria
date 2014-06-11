--****
-- == Graphics Constants
--
-- <<LEVELTOC level=2 depth=4>>
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
-- === video_config Sequence Accessors

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

-- COLOR values -- for characters and pixels
	--** in graphics modes BLACK is "transparent"


--****
-- ==== Colors
--

public constant
	BLACK          =  0,
	BLUE           =  1,
	GREEN          =  2,
	CYAN           =  3,
	RED            =  4,
	MAGENTA        =  5,
	BROWN          =  6,
	WHITE          =  7,
	GRAY           =  8,
	BRIGHT_BLUE    =  9,
	BRIGHT_GREEN   = 10,
	BRIGHT_CYAN    = 11,
	BRIGHT_RED     = 12,
	BRIGHT_MAGENTA = 13,
	YELLOW         = 14,
	BRIGHT_WHITE   = 15,
	$

ifdef WINDOWS then
-- **
-- @devdoc@
export sequence true_fgcolor = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15,
                                16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31}
-- **
-- @devdoc@
export sequence true_bgcolor = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15,
                                16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31}
-- 	BLACK          =  0,
-- 	BLUE           =  1,
-- 	GREEN          =  2,
-- 	CYAN           =  3,
-- 	RED            =  4,
-- 	MAGENTA        =  5,
-- 	BROWN          =  6,
-- 	WHITE          =  7,
-- 	GRAY           =  8,
-- 	BRIGHT_BLUE    =  9,
-- 	BRIGHT_GREEN   = 10,
-- 	BRIGHT_CYAN    = 11,
-- 	BRIGHT_RED     = 12,
-- 	BRIGHT_MAGENTA = 13,
-- 	YELLOW         = 14,
-- 	BRIGHT_WHITE   = 15,
elsifdef OSX then
-- **
-- @devdoc@
export sequence true_fgcolor = { 0, 4, 2, 6, 1, 5, 3, 7, 8,12,10,14, 9,13,11,15,
                                16,20,18,22,17,21,19,23,24,28,26,28,25,29,17,31}
-- **
-- @devdoc@
export sequence true_bgcolor = { 0, 4, 2, 6, 1, 5, 3, 7, 8,12,10,14, 9,13,11,15,
                                16,20,18,22,17,21,19,23,24,28,26,28,25,29,17,31}
-- 	BLACK          =  0,
-- 	RED            =  1,
-- 	GREEN          =  2,
-- 	BROWN          =  3,
-- 	BLUE           =  4,
-- 	MAGENTA        =  5,
-- 	CYAN           =  6,
-- 	WHITE          =  7,
-- 	GRAY           =  8,
-- 	BRIGHT_RED     =  9,
-- 	BRIGHT_GREEN   = 10,
-- 	YELLOW         = 11,
-- 	BRIGHT_BLUE    = 12,
-- 	BRIGHT_MAGENTA = 13,
-- 	BRIGHT_CYAN    = 14,
-- 	BRIGHT_WHITE   = 15,
elsifdef UNIX then
-- **
-- @devdoc@
export sequence true_fgcolor = { 0, 4, 2, 6, 1, 5, 3, 7, 8,12,10,14, 9,13,11,15,
                                16,20,18,22,17,21,19,23,24,28,26,28,25,29,17,31}
-- **
-- @devdoc@
export sequence true_bgcolor = { 0, 4, 2, 6, 1, 5, 3, 7, 8,12,10,14, 9,13,11,15,
                                16,20,18,22,17,21,19,23,24,28,26,28,25,29,17,31}
-- 	BLACK          =  0,
-- 	RED            =  1,
-- 	GREEN          =  2,
-- 	BROWN          =  3,
-- 	BLUE           =  4,
-- 	MAGENTA        =  5,
-- 	CYAN           =  6,
-- 	WHITE          =  7,
-- 	GRAY           =  8,
-- 	BRIGHT_RED     =  9,
-- 	BRIGHT_GREEN   = 10,
-- 	YELLOW         = 11,
-- 	BRIGHT_BLUE    = 12,
-- 	BRIGHT_MAGENTA = 13,
-- 	BRIGHT_CYAN    = 14,
-- 	BRIGHT_WHITE   = 15,
end ifdef

--** 
-- Add to color number to get blinking text.
public constant BLINKING = 16

public constant BYTES_PER_CHAR = 2

public type color(object x)
	if integer(x) and x >= 0 and x <= 255 then
		return 1
	else
		return 0
	end if
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
-- white is ##{63, 63, 63}##.

public type mixture(object s)
	if atom(s) then
		return 0
	end if
	
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
-- returns a description of the current video configuration.
--
-- Returns:
-- 		A **sequence**, of 10 non-negative integers, laid out as follows:
--	# color monitor? ~-- 0 if monochrome, 1 otherwise
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
-- A public enum is available for convenient access to the returned configuration data~:
--     * ##VC_COLOR##
--     * ##VC_MODE##
--     * ##VC_LINES##
--     * ##VC_COLUMNS##
--     * ##VC_XPIXELS##
--     * ##VC_YPIXELS##
--     * ##VC_NCOLORS##
--     * ##VC_PAGES##
--     * ##VC_SCRNLINES##
--     * ##VC_SCRNCOLS##
--
-- This routine makes it easy for you to parameterize a program so it will work in many
-- different graphics modes.
--
-- Example 1:
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


--****
-- === Color Set Selection
--
public enum
	--** 
	-- Foreground ( text) set of colors
	FGSET,
	
	--**
	-- Background set of colors
	BGSET,
	
	$
