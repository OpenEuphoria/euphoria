		--------------------------------
		-- Plotting of 3-D Surfaces:  --
		-- Z as a function of X and Y --
		--------------------------------

-- The program does a quick plot of each function to get the scaling right,
-- then replots so the picture will fit neatly on the screen.
-- The 4 x-y quadrants are in different colors.
-- Where z is positive, a brighter shade of color is used.
-- edit the_function() to insert your function
-- set GRAPHICS_MODE = a good mode for your machine
--                     (see euphoria\include\graphics.e for a list of modes)
-- Press Enter at any time to skip to the next function.

constant GRAPHICS_MODE = 18  

without type_check

include graphics.e
include select.e

include machine.e
-- use_vesa(1) -- FOR ATI cards

constant NFUNCS = 6
constant c = sqrt(2.0) / 2
constant SCREEN = 1

atom x_min, x_max, x_inc
atom y_min, y_max, y_inc
atom z_min, z_max
atom xc_min, xc_max, yc_min, yc_max

atom origin_x, origin_y
origin_x = 400
origin_y = 150

integer func_no
integer grid_width, fine
integer x_res, y_res

atom h_magnifier, v_magnifier

sequence prev_coord

function abs(atom x)
    if x < 0 then
	return -x
    else
	return x
    end if
end function

function the_function(atom x, atom y)
-- compute a function z of two variables x and y
-- There are actually several different functions below,
-- selected by the func_no variable
    sequence pq, pr, ps -- points in the plane
    atom dq, dr, ds     -- distance from p
    atom z, w

    if func_no = 1 then
	return 100*x*x + 100*y*y - 50

    elsif func_no = 2 then
	return 200*x*x*x - 200*y*y*y

    elsif func_no = 3 then
	return 50 * cos(8*x*y)

    elsif func_no = 4 then
	return 50 * cos(8*(x+y))

    elsif func_no = 5 then
	z = 50 * cos(50 * sqrt(x*x+y*y))
	if z >= -0.01 then
	    if (x < 0 and y < 0) or (x > 0 and y > 0) then
		return z / 10
	    else
		return z
	    end if
	else
	    return -0.01
	end if
    elsif func_no = 6 then
	pq = {.6, -.4}
	pr = {-.6, 0}
	ps = {.5, +.5}
	dq = sqrt((x-pq[1]) * (x-pq[1]) + (y-pq[2]) * (y-pq[2]))
	dr = sqrt((x-pr[1]) * (x-pr[1]) + (y-pr[2]) * (y-pr[2]))
	ds = sqrt((x-ps[1]) * (x-ps[1]) + (y-ps[2]) * (y-ps[2]))
	z = -25 * cos(ds*15)/(0.1 + ds*sqrt(ds)) +
	     75 * cos(dq*3) /(0.1 + dq*sqrt(dq))
	if x < 0 then
	    w = 60 * cos(9 * dr)
	    if w < 0 then
		w = 0
	    else
		w *= 2 * sqrt(-x)
	    end if
	    z += w
	end if
	return z
    end if
end function

procedure set_range()
    -- magnification factors
    h_magnifier = 1.0
    v_magnifier = 1.0

    -- extreme values
    xc_min = 1e307
    xc_max = -1e307
    yc_min = xc_min
    yc_max = xc_max
    z_min = xc_min
    z_max = xc_max

    -- range of values to plot
    x_min = -1
    x_max = +1
    y_min = -1
    y_max = +1

   -- calculate some derived values:
    x_inc = (x_max - x_min) / x_res
    y_inc = (y_max - y_min) / y_res
end procedure

procedure note_extreme(sequence coord, atom z)
-- record the extreme values
    if coord[1] < xc_min then
	xc_min = coord[1]
    elsif coord[1] > xc_max then
	xc_max = coord[1]
    end if
    if coord[2] < yc_min then
	yc_min = coord[2]
    elsif coord[2] > yc_max then
	yc_max = coord[2]
    end if
    if z > z_max then
	z_max = z
    elsif z < z_min then
	z_min = z
    end if
end procedure

function set_coord(atom x, atom y, atom z)
-- return the coordinates to plot, given the x, y and z values
    atom k

    k = (x - x_min)/x_inc * c
    return {h_magnifier * (origin_x + (y - y_min)/y_inc - k),
	    v_magnifier * (origin_y - z + k)}
end function

procedure plot(atom x, atom y)
-- plot the point according to 3-D perspective
    atom z, col
    sequence coord

    z = the_function(x, y)
    coord = set_coord(x, y, z)
    note_extreme(coord, z)
    -- select color by quadrant
    col = (z >= 0) * 8 + (x >= 0) * 2 + (y >= 0) + 1
    if length(prev_coord) = 0 then
	pixel(col, coord)
    else
	draw_line(col, {prev_coord, coord})
    end if
    prev_coord = coord
end procedure

function plot_a_function()
-- generate 3d plotted graph

    for x = x_min to x_max by grid_width * x_inc do
	if get_key() != -1 then
	    return 0
	end if
	prev_coord = {}
	for y = y_min to y_max by fine * y_inc do
	    plot(x, y)
	end for
    end for

    for y = y_min to y_max by grid_width * y_inc do
	if get_key() != -1 then
	    return 0
	end if
	prev_coord = {}
	for x = x_min to x_max by fine * x_inc do
	    plot(x, y)
	end for
    end for
    return 1
end function

procedure box()
-- draw a box around the outside of edge of the screen
    polygon(5, 0, {{0, 0}, {0, y_res-1}, {x_res-1, y_res-1}, {x_res-1, 0}})
end procedure

procedure plot3d()
-- main program
    func_no = 1
    while func_no <= NFUNCS do
	set_range()
	-- do a quick trial run to establish range of values
	grid_width = 20
	fine = 4
	if plot_a_function() then
	    clear_screen()
	    box()
	    -- make next one fit screen better
	    v_magnifier = (y_res - 1) / (yc_max - yc_min)
	    h_magnifier = (x_res - 1) / (xc_max - xc_min)
	    origin_x -= xc_min
	    origin_y -= yc_min
	    grid_width = 20
	    fine = 1
	    if plot_a_function() then
		position(2, 2)
		printf(SCREEN, "x: %5.1f to %4.1f", {x_min, x_max})
		position(3, 2)
		printf(SCREEN, "y: %5.1f to %4.1f", {y_min, y_max})
		position(4, 2)
		printf(SCREEN, "z: %5.1f to %4.1f", {z_min, z_max})
		while get_key() = -1 do
		end while
	    end if
	end if
	func_no += 1
	clear_screen()
    end while
end procedure

sequence config

-- execution starts here:
if select_mode(GRAPHICS_MODE) then
    config = video_config()
    x_res = config[VC_XPIXELS]
    y_res = config[VC_YPIXELS]
    plot3d()
    if graphics_mode(-1) then
    end if
else
    puts(1, "couldn't find a good graphics mode\n")
end if

