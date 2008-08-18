-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--

constant
	M_LINE           = 2,
	M_POLYGON        = 11,
	M_ELLIPSE        = 18

include ..\image.e
include ..\graphcst.e

type point_sequence(sequence x)
	return length(x) >= 2
end type

type point(sequence x)
	return length(x) = 2
end type

type boolean(integer x)
	return x = 0 or x = 1
end type

--****
-- === Pixel graphics routines
--

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
-- Example 1:
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

public procedure draw_line(color c, point_sequence xyarray)
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
public procedure polygon(color c, boolean fill, point_sequence xyarray)
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

public procedure ellipse(color c, boolean fill, point p1, point p2)
	machine_proc(M_ELLIPSE, {c, fill, p1, p2})
end procedure

--**
-- Display a 2-d sequence of pixels at some location.
--
-- Platform:
--		//DOS32//
--
-- Parameters:
-- 		# ##xy##: a sequence, the pair of 0-based coordinates of the point to start the display at.
-- 		# ##pixels##: a sequence of lists of pixel values.
--
-- Comments:
--   N.B. coordinates are ##{x, y}## with ##{0, 0}## at top left of screen and ##x## values
--   increasing towards the right, and ##y## values increasing towards the bottom of the screen. Pixel rows don't wrap.
--
-- ##pixels## might have been created by an earlier call to [[:save_image]], or in any other way. The sequences (rows) of the image do not have to all be the same length.
--
-- Example 1:
-- <eucode>
-- display_image({20,30}, {{7,5,9,4,8},
--                         {2,4,1,2},
--                         {1,0,1,0,4,6,1},
--                         {5,5,5,5,5,5}})
-- -- This will display a small image containing 4 rows of
-- -- pixels. The first pixel (7) of the top row will be at
-- -- {20,30}. The top row contains 5 pixels. The last row
-- -- contains 6 pixels ending at {25,33}.
-- </eucode>
--
-- Example 2:
--	 [[../demo/dos32/bitmap.ex]]
--
-- See Also: *
--   [[:save_image]], [[:read_bitmap]], [[:display_text_image]]

public procedure display_image(graphics_point xy, sequence pixels)
	for i = 1 to length(pixels) do
		pixel(pixels[i], xy)
		xy[2] += 1
	end for
end procedure

--**
-- Save a rectangular region on a graphics screen
--
-- Platform:
--	//DOS32//
--
-- Parameters:
-- 		# ##top_left##: the coordinates, given as a pair, of the upper left corner of the area to save
-- 		# ##bottom_right##: the coordinates, given as a pair, of the lower right corner of the area to save
--
-- Returns:
-- 		A **sequence** of pixel values, which [[:display_image]] will read as expected.
--
-- Comments:
--   The 0-based ##{x, y}## coordinates are for the top-left and bottom-right
--   corner pixels.
--
-- Example 1:
-- <eucode>
-- s = save_image({0,0}, {50,50})
-- display_image({100,200}, s)
-- display_image({300,400}, s)
-- -- saves a 51x51 square image, then redisplays it at {100,200}
-- -- and at {300,400}
-- </eucode>
--
-- See Also:
-- 		[[:display_image]], [[:save_text_image]]

public function save_image(graphics_point top_left, graphics_point bottom_right)
	integer x, width
	sequence save
	
	x = top_left[1]
	width = bottom_right[1] - x + 1
	save = {}
	for y = top_left[2] to bottom_right[2] do
		save = append(save, get_pixel({x, y, width}))
	end for
	return save
end function

--**
-- Signature:
-- global function get_pixel(sequence coords)
--
-- Description:
--
-- Retrieve the color (a small integer) of the pixel(s) on the pixel-graphics screen at a given location.
--
-- Parameters:
--		# ##coords##: a sequence, the first two elements of which are the coordinates of the (starting) point.
--
-- Returns:
-- An **object**, either:
-- * an integer, the color of the pixel at the requested location;
-- * a sequence of ##n## colors, where ##n## is the third element of ##coords##.
--
-- Comments:
--
-- When ##coords## is a 2-element sequence representing screen coordinates, ##get_pixel##() 
-- only returbn the color of this pixel.
--
-- When ##coords## is a 3-element sequence of the form ##{x, y, n}##, ##get_pixel##() returns a
-- sequence of ##n## colors for the points starting at ##{x, y}## and moving to the right 
-- ##{x+1, y}, {x+2, y}## etc.
--
-- A very fast algorithm is used to read the pixel colors on the screen, so that is much 
-- faster to call get_pixel() once, specifying a large value of n, than it is to call it many 
-- times, reading one pixel color at a time.
--
-- Points off the screen have unpredictable color values.
--
-- Example 1:
--<eucode>
--  object x
-- 
-- x = get_pixel({30,40})
-- -- x is set to the color value of point x=30, y=40
-- 
-- x = get_pixel({30,40,100})
-- -- x is set to a sequence of 100 integer values, representing
-- -- the colors starting at {30,40} and going to the right
-- </eucode>
--
-- See Also:
-- [[:pixel]], [[:graphics_mode]], [[:get_position]]
-- 
