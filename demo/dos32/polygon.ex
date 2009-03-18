		-----------------------------
		-- Polygon Pattern Program --
		-----------------------------

-- press space bar to see a new pattern
-- press any other key to quit

constant GRAPHICS_MODE = 18 -- SVGA, if this fails try mode 18 
			     -- see also euphoria\include\graphics.e
without type_check

include std/graphics.e
include std/graphcst.e
include std/dos/pixels.e
include select.e

include std/machine.e
-- use_vesa(1) -- for ATI cards

constant TRUE = 1

constant X = 1,
	 Y = 2

sequence config
integer nlines, npoints, spacing, solid

function poly_pattern()
    integer color, color_step, ncolors, key
    sequence points, deltas, history

    config = video_config()
    ncolors = config[VC_NCOLORS]
    color = 1
    color_step = 1
    points = rand(repeat(config[VC_XPIXELS..VC_YPIXELS], npoints)) - 1
    deltas = rand(repeat({2*spacing-1, 2*spacing-1}, npoints)) - spacing
    history = {}
    clear_screen()
    while TRUE do
	if length(history) >= nlines then
	    -- blank out oldest line
	    polygon(0, solid, history[1])
	    history = history[2..nlines]
	end if
	polygon(color, solid, points)
	history = append(history, points)
	points += deltas
	-- make vertices change direction at edge of screen
	for j = 1 to npoints do
	    if points[j][X] <= 0 or points[j][X] >= config[VC_XPIXELS] then
		deltas[j][X] = -deltas[j][X]
	    end if
	    if points[j][Y] <= 0 or points[j][Y] >= config[VC_YPIXELS] then
		deltas[j][Y] = -deltas[j][Y]
	    end if
	end for
	-- step through the colors
	color += color_step
	if color >= ncolors then
	    color_step = rand(ncolors)
	    color = color_step
	end if
	-- change background color once in a while
	if rand(100) = 1 then
	    bk_color(rand(ncolors)-1)
	end if
	-- see if user wants to quit
	key = get_key()
	if key = ' ' then
	    return 0
	elsif key != -1 then
	    return 1
	end if
    end while
end function

if not select_mode(GRAPHICS_MODE) then
    puts(1, "couldn't find a good graphics mode\n")
    abort(1)
end if

while TRUE do
    -- Play with these parameters for neat effects!
    nlines = 1+rand(140)   -- number of lines on screen at one time
    npoints = 2+rand(16)   -- number of points in polygons
    spacing = 1+rand(24)   -- spacing between lines
    solid = rand(2)-1      -- solid polygons? 1 or 0
    if poly_pattern() then
	exit
    end if
end while

if graphics_mode(-1) then
end if

