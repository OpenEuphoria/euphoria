-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--

--****
-- === DOS Image Routines
--
ifdef DOS32 then
include ..\graphcst.e
include base_mem.e

constant
	M_PALETTE          = 3,
	M_USE_VESA         = 36,
	M_ALL_PALETTE      = 27,
	M_GET_DISPLAY_PAGE = 28,
	M_SET_DISPLAY_PAGE = 29,
	M_GET_ACTIVE_PAGE  = 30,
	M_SET_ACTIVE_PAGE  = 31

type page_number(integer p)
	return p >= 0 and p <= 7
end type

--**
-- Set how Euphoria should use the VESA standard to perform video operations.
--
-- Platform:
--		//DOS32//
--
-- Parameters:
-- 		# ##code##: an integer, must be 0 or 1.
--
-- Comments:
-- If ##code## is 1 then force Euphoria to use the VESA graphics standard.
-- This may let Euphoria work better in SVGA modes with certain graphics cards.
-- If ##code## is 0 then Euphoria's normal use of the graphics card is restored.
-- Values of ##code## other than 0 or 1 should not be used.
--
-- Most people can ignore this. However if you experience difficulty in SVGA graphics modes you 
-- should try calling ##use_vesa##(1) at the start of your program before any calls to 
-- [[:graphics_mode]]().
--
-- Example 1:
-- <eucode>
-- use_vesa(1)
-- fail = graphics_mode(261)
-- </eucode>
-- 
-- See Also: 
--       [[:graphics_mode]]

public procedure use_vesa(integer code)
	machine_proc(M_USE_VESA, code)
end procedure

--**
-- Get the number of the video page being displayed.
--
-- Platform:
--		//DOS32//
--
-- Returns
--		An **integer**, the current page number displayed bythe monitor.
--
-- Comments: 
--
-- Some graphics modes on most video cards have multiple pages of memory. This lets you write screen output to one page while displaying another. [[:video_config]]() will tell you how manypages are available in the current graphics mode.
--
-- The active and display pages are both 0 by default.
--  
-- See Also: 
--      [[:set_display_page]], [[:get_active_page]], [[:video_config]]
-- 

public function get_display_page()
	return machine_func(M_GET_DISPLAY_PAGE, 0)
end function

--**
-- Select a video memory page to be displayed
--
-- Platform:
--		//DOS32//
--
-- Parameters:
-- 		# ##page##: the number of the page to be mapped.
--
-- Comments: 
--
-- With multiple pages you can instantaneously change the entire screen without causing any visible "flicker". You can also save the screen and bring it back quickly.
-- [[:video_config]]() will tell you how many pages are available in the current graphics mode.
--
-- By default, the active page and the display page are both 0. 
-- 
-- This works under DOS, or in a full-screen DOS window. In a partial-screen window you cannot change the active page. 
--  
-- Example 1:
--   See the [[:set_active_page]] example.
--
-- See Also: 
--   [[:get_display_page]], [[:set_active_page]], [[:video_config]]


public procedure set_display_page(page_number page)
	machine_proc(M_SET_DISPLAY_PAGE, page)
end procedure

--**
-- Determine which is the video memory page output goes to.
--
-- Platform:
--		//DOS32//
--
-- Returns:
-- 		An **integer**, the current page number that screen output is sent to.
--
-- Comments:
--
-- Some graphics modes on most video cards have multiple pages of memory. This lets you write screen output to one page while displaying a different page. 
--
-- The active and display pages are both 0 by default.
-- [[:video_config]]() will tell you how many pages are available in the current graphics mode.
--  
-- See Also: set_active_page, get_display_page, video_config  
-- 
public function get_active_page()
	return machine_func(M_GET_ACTIVE_PAGE, 0)
end function

--**
-- Select a page for screen output
--
-- Platform:
--		//DOS32//
--
-- Parameters:
-- 		# ##page##: the number of the page to send output to.
--
-- Comments: 
--
-- With multiple pages you can instantaneously change the entire screen without causing any visible "flicker". You can also save the screen and bring it back quickly.
-- [[:video_config]]() will tell you how many pages are available in the current graphics mode.
-- 
-- By default, the active page and the display page are both 0. 
-- 
-- This works under DOS, or in a full-screen DOS window. In a partial-screen window you cannot change the active page. 
--
-- Example 1:
-- <a name="active_page">
-- <eucode>
-- include image.e
--
-- -- active & display pages are initially both 0
-- puts(1, "\nThis is page 0\n")
-- set_active_page(1)     -- screen output will now go to page 1
-- clear_screen()
-- puts(1, "\nNow we've flipped to page 1\n")
--
-- if getc(0) then        -- wait for key-press
-- end if
--
-- set_display_page(1)    -- "Now we've ..." becomes visible
-- if getc(0) then        -- wait for key-press
-- end if
--
-- set_display_page(0)    -- "This is ..." becomes visible again
-- set_active_page(0)
-- </eucode>
-- 
-- See Also: 
--
--      [[:get_active_page]], [[:set_display_page]], [[:video_config]]

public procedure set_active_page(page_number page)
	machine_proc(M_SET_ACTIVE_PAGE, page)
end procedure

include interrup.e
ifdef SAFE then
	public include safe.e
else
	public include memory.e
end ifdef

--**
-- Get color intensities for the entire set of colors in the current
-- graphics mode.
--
-- Platform:
-- //DOS32//
--
-- Returns:
--   A **sequence** of [[:mixture]]s.
--
-- Comments:
--
--   Intensity values are in the range 0 to 63.
--
--   This function might be used to get the palette values needed by [[:save_bitmap]]().
--   Remember to multiply these values by 4 before calling save_bitmap(), since save_bitmap()
--   expects values in the range 0 to 255.
--
-- See Also:
--    [[:video_config]], [[:palette]], [[:all_palette]], [[:read_bitmap]], [[:save_bitmap]],
--    [[:save_screen]]

public function get_all_palette()
	integer mem, numColors
	sequence vc, reg, colors
	
	vc = video_config()
	numColors = vc[VC_NCOLORS]
	reg = repeat(0, REG_LIST_SIZE)
	mem = allocate_low(numColors*3)
	if mem then
		reg[REG_AX] = #1017
		reg[REG_BX] = 0
		reg[REG_CX] = numColors
		reg[REG_ES] = floor(mem/16)
		reg[REG_DX] = and_bits(mem, 15)
		reg = dos_interrupt(#10, reg)
		colors = {}
		for col = mem to mem+(numColors-1)*3 by 3 do
			colors = append(colors, peek({col,3}))
		end for
		free_low(mem)
		return colors
	else
		return {} -- unlikely
	end if
end function

--**
-- Change the color for color number ##c## to a mixture of elementary colors.
--
-- Platform:
--		//DOS32//
--
-- Parameters:
-- 		# ##c##: the color to redefine
--		# ##s##: a sequence of color intensities: ##{red, green, blue}##. Each value in ##s##
--        can be from 0 to 63.
--
-- Returns:
-- 		An **object**, either -1 on failure, or a mixture representing the previous definition
--      of ##c##.
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

public function palette(color c, mixture s)
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
--   ##demo\dos32\bitmap.ex##

public procedure all_palette(sequence s)
	machine_proc(M_ALL_PALETTE, s)
end procedure

end ifdef
