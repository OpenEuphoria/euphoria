		----------------------------
		-- 3-D Wire Frame Picture --
		----------------------------
-- Hit space bar to freeze/restart the picture.
-- Any other key to quit.

without type_check

public include std/graphics.e
public include std/graphcst.e
include select.e

include std/machine.e
include std/dos/pixels.e
-- use_vesa(1)  -- for ATI cards if you use SVGA

constant GRAPHICS_MODE = 18 

constant X = 1, Y = 2, Z = 3
constant TRUE = 1
constant SCREEN = 1
constant ANY_MODE_WHITE = 255

type point(sequence x)
    return length(x) = 3
end type

type matrix(sequence x)
    return length(x) = 4 and sequence(x[1])
end type

type vector(sequence x)
    return length(x) = 4 and atom(x[1])
end type

integer axis
atom sin_angle, cos_angle

function product(sequence factor)
-- matrix multiply a number of 4-vectors/4x4 matrices
-- only the first one could be a vector
    sequence a, c
    matrix b

    a = factor[1]
    for f = 2 to length(factor) do
	b = factor[f]
	if atom(a[1]) then
	    -- a is a vector
	    c = repeat(0, 4)
	    for j = 1 to 4 do
		c[j] = a[1] * b[1][j] +
		       a[2] * b[2][j] +
		       a[3] * b[3][j] +
		       a[4] * b[4][j]
	    end for
	else
	    -- a is a matrix
	    c = repeat(repeat(0, 4), 4)
	    for i = 1 to 4 do
		for j = 1 to 4 do
		    for k = 1 to 4 do
			c[i][j] += a[i][k] * b[k][j]
		    end for
		end for
	    end for
	end if
	a = c
    end for
    return c
end function

sequence vc -- video configuration

procedure display(sequence old_coords, sequence coords)
-- erase the old lines, draw the new ones
    for i = 1 to length(old_coords) do
	draw_line(BLACK, old_coords[i][1..2])
    end for
    for i = 1 to length(coords) do
	if vc[VC_COLOR] then
	    draw_line(coords[i][3], coords[i][1..2])
	else
	    draw_line(ANY_MODE_WHITE, coords[i][1..2])
	end if
    end for
end procedure

function view(point view_point)
-- compute initial view
    matrix t1, t2, t3, t4, n
    atom cos_theta, sin_theta, hyp, a_b

    -- change origin
    t1 = {{1, 0, 0, 0},
	  {0, 1, 0, 0},
	  {0, 0, 1, 0},
	  -view_point & 1}

    -- get left-handed coordinate system
    t2 = {{-1, 0,  0, 0},
	  { 0, 0, -1, 0},
	  { 0, 1,  0, 0},
	  { 0, 0,  0, 1}}

    -- rotate so Ze points properly
    hyp = sqrt(view_point[1] * view_point[1] + view_point[2] * view_point[2])
    sin_theta = view_point[1] / hyp
    cos_theta = view_point[2] / hyp
    t3 = {{cos_theta, 0, sin_theta, 0},
	  {        0, 1,         0, 0},
	  {-sin_theta,0, cos_theta, 0},
	  {        0, 0,         0, 1}}

    -- rotate so Ze points at the origin (0, 0, 0)
    t4 = {{1, 0, 0, 0},
	  {0, cos_theta, -sin_theta, 0},
	  {0, sin_theta, cos_theta, 0},
	  {0, 0, 0, 1}}

    a_b = 2

    n = {{a_b, 0, 0, 0},
	 {0, a_b, 0, 0},
	 {0, 0, 1, 0},
	 {0, 0, 0, 1}}

    return product({t1, t2, t3, t4, n})
end function

function new_coords(sequence overall, sequence shape)
-- compute the screen coordinates from the 3-D coordinates
    sequence screen_coords, final
    point p
    atom x2, y2

    x2 = vc[VC_XPIXELS]/2
    y2 = vc[VC_YPIXELS]/2
    screen_coords = repeat({0, 0, 0}, length(shape))
    for i = 1 to length(shape) do
	for j = 1 to 2  do
	    p = shape[i][j]
	    final = product({p & 1, overall})
	    screen_coords[i][j] = {x2*(final[X]/final[Z]+1),
				   y2*(final[Y]/final[Z]+1)}
	end for
	screen_coords[i][3] = shape[i][3]
    end for
    return screen_coords
end function

function x_rotate(point p)
-- compute x rotation of a point
    return {p[X],
	    p[Y] * cos_angle + p[Z] * sin_angle,
	    p[Z] * cos_angle - p[Y] * sin_angle}
end function

function y_rotate(point p)
-- compute y rotation of a point
    return {p[X] * cos_angle - p[Z] * sin_angle,
	    p[Y],
	    p[X] * sin_angle + p[Z] * cos_angle}
end function

function z_rotate(point p)
-- compute z rotation matrix
    return {p[X] * cos_angle + p[Y] * sin_angle,
	    p[Y] * cos_angle - p[X] * sin_angle,
	    p[Z]}
end function

function compute_rotate(integer axis, sequence shape)
-- rotate a shape
    for i = 1 to length(shape) do
	for j = 1 to 2 do
	    if axis = X then
		shape[i][j] = x_rotate(shape[i][j])
	    elsif axis = Y then
		shape[i][j] = y_rotate(shape[i][j])
	    else
		shape[i][j] = z_rotate(shape[i][j])
	    end if
	end for
    end for
    return shape
end function

-- lines for a block E
constant E = {
{{.2, 1.1, 2}, {.2, -.5, 2}, BLUE},
{{.2, -.5, 2}, {.2, -.5, -2}, YELLOW},
{{.2, -.5, -2}, {.2, 1.1, -2}, GREEN},
{{.2, 1.1, -2}, {.2, 1.2, -1.6}, BRIGHT_RED},
{{.2, 1.2, -1.6}, {.2, 1, -1.8}, BRIGHT_RED},
{{.2, 1, -1.8}, {.2, 0, -1.8}, MAGENTA},
{{.2, 0, -1.8}, {.2, 0, -.1}, BRIGHT_CYAN},
{{.2, 0, -.1}, {.2, .5, -.1}, BLUE},
{{.2, .5, -.1}, {.2, .6, -.2}, BLUE},
{{.2, .6, -.2}, {.2, .6, .2}, ANY_MODE_WHITE},
{{.2, .6, .2}, {.2, .5, .1}, BLUE},
{{.2, .5, .1}, {.2, 0, .1}, BRIGHT_BLUE},
{{.2, 0, .1}, {.2, 0, 1.8}, BRIGHT_GREEN},
{{.2, 0, 1.8}, {.2, 1, 1.8}, BRIGHT_CYAN},
{{.2, 1, 1.8}, {.2, 1.2, 1.6}, BRIGHT_CYAN},
{{.2, 1.2, 1.6}, {.2, 1.1, 2}, BRIGHT_RED},

-- opposite side:
{{-.2, 1.1, 2}, {-.2, -.5, 2}, BLUE},
{{-.2, -.5, 2}, {-.2, -.5, -2}, YELLOW},
{{-.2, -.5, -2}, {-.2, 1.1, -2}, GREEN},
{{-.2, 1.1, -2}, {-.2, 1.2, -1.6}, BRIGHT_RED},
{{-.2, 1.2, -1.6}, {-.2, 1, -1.8}, BRIGHT_RED},
{{-.2, 1, -1.8}, {-.2, 0, -1.8}, MAGENTA},
{{-.2, 0, -1.8}, {-.2, 0, -.1}, BRIGHT_CYAN},
{{-.2, 0, -.1}, {-.2, .5, -.1}, BLUE},
{{-.2, .5, -.1}, {-.2, .6, -.2}, BLUE},
{{-.2, .6, -.2}, {-.2, .6, .2}, ANY_MODE_WHITE},
{{-.2, .6, .2}, {-.2, .5, .1}, BLUE},
{{-.2, .5, .1}, {-.2, 0, .1}, BRIGHT_BLUE},
{{-.2, 0, .1}, {-.2, 0, 1.8}, BRIGHT_GREEN},
{{-.2, 0, 1.8}, {-.2, 1, 1.8}, BRIGHT_CYAN},
{{-.2, 1, 1.8}, {-.2, 1.2, 1.6}, BRIGHT_CYAN},
{{-.2, 1.2, 1.6}, {-.2, 1.1, 2}, BRIGHT_RED},

-- cross pieces:
{{.2, 1.1, 2}, {-.2, 1.1, 2}, BLUE},
{{.2, -.5, 2}, {-.2, -.5, 2}, BLUE},
{{.2, -.5, -2}, {-.2, -.5, -2}, GREEN},
{{.2, 1.1, -2}, {-.2, 1.1, -2}, GREEN},
{{.2, 1.2, -1.6}, {-.2, 1.2, -1.6}, BRIGHT_GREEN},
{{.2, .6, -.2}, {-.2, .6, -.2}, ANY_MODE_WHITE},
{{.2, .6, .2}, {-.2, .6, .2}, ANY_MODE_WHITE},
{{.2, 1.2, 1.6}, {-.2, 1.2, 1.6}, BRIGHT_GREEN}
}

procedure spin(sequence shape)
-- spin a 3-D shape around on the screen in interesting ways
    sequence history, coords, overall
    point view_point
    integer spread, r, c
    atom rot_speed

    view_point = {6, 8, 7.5} / 2.2
    overall = view(view_point)
    rot_speed = 0.09
    sin_angle = sin(rot_speed)
    cos_angle = cos(rot_speed)
    axis = Z
    history = {}
    spread = 0
    while TRUE do
	coords = new_coords(overall, shape)
	if length(history) > spread then
	    display(history[1], coords)
	    history = history[2..length(history)]
	    if length(history) > spread then
		display(history[1], {})
		history = history[2..length(history)]
	    end if
	else
	    display({}, coords)
	end if
	history = append(history, coords)
	c = get_key()
	if c != -1 then
	    if c = ' ' then
		while TRUE do
		    c = get_key()
		    if c != -1 and c != ' ' then
			return
		    elsif c = ' ' then
			exit
		    end if
		end while
	    else
		return
	    end if
	end if
	r = rand(250)
	if r = 1 then
	    axis = X
	elsif r = 2 then
	    axis = Y
	elsif r = 3 then
	    axis = Z
	elsif r = 4 then
	    spread = 5 * rand(25)  -- leave behind many trailing wire images
	elsif r = 5 or r = 6 then
	    spread = 0             -- reduce the images back to a sharp picture
	elsif r = 7 then
	    if rand(2) = 1 then
		rot_speed = .04
		spread = 0
	    else
		rot_speed = .02 * rand(10)
	    end if
	    sin_angle = sin(rot_speed)
	    cos_angle = cos(rot_speed)
	end if
	shape = compute_rotate(axis, shape)
    
    end while
end procedure

-- execution starts here:
if not select_mode(GRAPHICS_MODE) then
    puts(SCREEN, "can't find a good graphics mode\n")
else
    vc = video_config()
    bk_color(7)
    text_color(5)
    clear_screen()
    spin(E)
    bk_color(0)
    if graphics_mode(-1) then
       -- we do this just to ignore the result of graphics_mode(-1)
    end if
end if

