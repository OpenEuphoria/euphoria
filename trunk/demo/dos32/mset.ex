		---------------------------------
		-- Plotting the Mandelbrot Set --
		---------------------------------
-- Usage: ex mset

-- Generates M-Set pictures.
-- Hit Enter at any time to stop the display. Hit Enter again to save 
-- the current picture and display a grid. Use the arrow keys to select 
-- the most interesting box in the grid. Hit Enter to redraw this box at 
-- the full size of the screen, or hit Esc to quit. The pictures that you 
-- display are saved in eu_mseta.bmp, eu_msetb.bmp, ...

-- Move any eu_mset.bmp file of the right screen dimensions to \windows 
-- and it will be added to your list of choices for "wallpaper". 
-- Right click on your wallpaper to change it (Win95/98).

constant GRAPHICS_MODE = 18
		       --  18 is  640x480  16 color  VGA (guaranteed to work)
		       -- 257 is  640x480 256 color SVGA
		       -- 259 is  800x600 256 color SVGA
		       -- 261 is 1024x768 256 color SVGA

without type_check

include image.e
include select.e
include get.e

-- use_vesa(1) -- for ATI cards

constant ZOOM_FACTOR = 20    -- grid size for zooming in

constant FALSE = 0, TRUE = 1
constant REAL = 1, IMAG = 2

constant ARROW_LEFT  = 331,
	 ARROW_RIGHT = 333,
	 ARROW_UP    = 328,
	 ARROW_DOWN  = 336

	-- types --

type natural(integer x)
    return x >= 0
end type

type complex(sequence x)
    return length(x) = 2 and atom(x[1]) and atom(x[2])
end type

procedure beep()
-- make a beep sound
    atom t

    t = time()
    sound(500)
    while time() < t + .2 do
    end while
    sound(0)
end procedure

natural ncolors
natural max_iter

sequence vc -- current video configuration

procedure randomize_palette()
-- choose random color mixtures    
    sequence new_pal 
    
    new_pal = rand(repeat(repeat(64, 3), ncolors)) - 1
    if ncolors > 16 then
	new_pal[17] = {0,0,0}  -- black border
    end if
    all_palette(new_pal)
end procedure

procedure grid(sequence x, sequence y, natural color)
-- draw the grid
    atom dx, dy

    dx = vc[VC_XPIXELS]/ZOOM_FACTOR
    dy = vc[VC_YPIXELS]/ZOOM_FACTOR

    for i = x[1] to x[2] do
	draw_line(color, {{i*dx, y[1]*dy}, {i*dx, y[2]*dy}})
    end for
    for i = y[1] to y[2] do
	draw_line(color, {{x[1]*dx, i*dy}, {x[2]*dx, i*dy}})
    end for
end procedure

function zoom()
-- select place to zoom in on next time
    integer key
    sequence box

    grid({0, ZOOM_FACTOR}, {0, ZOOM_FACTOR}, 7)
    box = {0, ZOOM_FACTOR-1}
    while TRUE do
	grid({box[1], box[1]+1}, {box[2], box[2]+1}, rand(15))
	key = get_key()
	if key != -1 then
	    grid({box[1], box[1]+1}, {box[2], box[2]+1}, 7)
	    if key = ARROW_UP then
		if box[2] > 0 then
		    box[2] -= 1
		end if
	    elsif key = ARROW_DOWN then
		if box[2] < ZOOM_FACTOR-1 then
		    box[2] += 1
		end if
	    elsif key = ARROW_RIGHT then
		if box[1] < ZOOM_FACTOR-1 then
		    box[1] += 1
		end if
	    elsif key = ARROW_LEFT then
		if box[1] > 0 then
		    box[1] -= 1
		end if
	    elsif key >= 27  then
		return {}  -- quit
	    else
		return {box[1], ZOOM_FACTOR - 1  - box[2]}
	    end if
	end if
    end while
end function

procedure mset(complex lower_left,  -- lower left corner
	      complex upper_right) -- upper right corner
-- Plot the Mandelbrot set over some region.
-- The Mandelbrot set is defined by the equation: z = z * z + C
-- where z and C are complex numbers. The starting point for z is 0.
-- If, for a given value of C, z approaches infinity, C is considered to
-- *not* be a member of the set. It can be shown that if the absolute value
-- of z ever becomes greater than 2, then the value of z will increase
-- towards infinity from then on. After a large number of iterations, if
-- the absolute value of z is still less than 2 then we assume with high
-- probability that C is a member of the Mset and this program will show
-- that point in black.
    complex c
    atom zr, zi, zr2, zi2, cr, ci, xsize, ysize
    natural member, stop, color, width, height
    sequence color_line
    
    clear_screen()
    height = vc[VC_YPIXELS]
    width = vc[VC_XPIXELS]
    color_line = repeat(0, width)
    xsize = (upper_right[REAL] - lower_left[REAL])/(width - 1)
    ysize = (upper_right[IMAG] - lower_left[IMAG])/(height - 1)
    c = {0, 0}

    for y = 0 to height - 1 do
	if get_key() != -1 then
	    return 
	end if
	c[IMAG] = upper_right[IMAG] - y * ysize
	for x = 0 to width - 1 do
	    c[REAL] = lower_left[REAL] + x * xsize
	    member = TRUE
	    zr = 0
	    zi = 0
	    zr2 = 0
	    zi2 = 0
	    cr = c[REAL]
	    ci = c[IMAG]
	    for i = 1 to max_iter do
		zi = 2.0 * zr * zi + ci
		zr = zr2 - zi2 + cr
		zr2 = zr * zr
		zi2 = zi * zi
		if zr2 + zi2 > 4.0 then
		    member = FALSE
		    stop = i
		    exit
		end if
	    end for
	    if member = TRUE then
		color = 0
	    else
		color = stop + 51 -- gives nice sequence of colors
		while color >= ncolors do
		    color -= ncolors
		end while
	    end if
	    color_line[x+1] = color
	end for
	pixel(color_line, {0, y}) -- write out a whole line of pixels at once
    end for
end procedure

procedure Mandelbrot()
-- main procedure
    sequence delta, new_box
    complex lower_left, upper_right
    sequence pic_name
    integer p, c
    natural file_no
    atom t
    
    -- initially show the upper half:
    max_iter = 30 -- increases as we zoom in
    lower_left = {-1, 0}
    upper_right = {1, 1}
    
    -- set up for desired graphics mode
    if not select_mode(GRAPHICS_MODE) then
	puts(2, "couldn't find a good graphics mode\n")
	return
    end if
    vc = video_config()
    ncolors = vc[VC_NCOLORS]

    while TRUE do
	-- Display the M-Set
	mset(lower_left, upper_right)
	beep()
	
	-- choose a new file to save the picture into
	file_no = 0
	for i = 'a' to 'z' do
	    p = open("eu_mset" & i & ".bmp", "rb")
	    if p = -1 then
		file_no = i
		exit
	    else
		-- file exists
		close(p)
	    end if
	end for
	if file_no then
	    pic_name = "eu_mset" & file_no & ".bmp"
	else
	    puts(1, "Couldn't find a new file name to use\n")
	    return 
	end if

	-- choose new colors
	while 1 do
	    t = time() + 5
	    while time() < t do
		c = get_key()
		if c != -1 then
		    exit
		end if
	    end while
	    if c != -1 then
		exit
	    end if
	    randomize_palette()
	end while

	-- save the picture into a .bmp file
	if save_screen(0, pic_name) then
	end if
	
	-- clear the keyboard buffer
	while get_key() != -1 do
	end while
	
	new_box = zoom()
	if length(new_box) = 0 then
	    exit
	end if
	
	delta = (upper_right - lower_left)
	lower_left += new_box / ZOOM_FACTOR * delta
	upper_right = lower_left + delta / ZOOM_FACTOR
	max_iter *= 2  -- need more iterations as we zoom in
    end while
end procedure

Mandelbrot()

if graphics_mode(-1) then
end if

