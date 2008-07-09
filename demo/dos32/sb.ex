		------------------------------------
		-- Atomic Reaction Screen Blanker --
		------------------------------------
without type_check

include graphics.e
include select.e

--use_vesa(1) -- for modes 256...261

constant GRAPHICS_MODE = 18 -- VGA

constant MAX_POPULATION = 125          -- maximum number of circles
constant MAX_SIZE = 5, MIN_SIZE = 1    -- size of circles

constant TRUE = 1
constant X = 1, Y = 2
constant FILL = 1

sequence size, circles, dirs, colors
sequence vc

procedure init()
-- initialize global variables
    if not select_mode(GRAPHICS_MODE) then
	puts(1, "needs VGA graphics\n")
	abort(1)
    end if
    vc = video_config()
    circles = {}
    dirs = {}
    colors = {}
    size = {}
end procedure

procedure bounce()
-- main routine
    sequence top_left, prev_circle
    integer x, y, s
    atom t

    init()
    t = time()
    while t+1 > time() do
	-- wait for screen to settle - looks better
    end while
    while TRUE do
	if get_key() != -1 then
	    exit
	end if
	
	if length(circles) < MAX_POPULATION then
	    -- add a new circle
	    x = 0  y = 0 -- start each circle at top left corner of screen
	    s = MIN_SIZE + rand(MAX_SIZE+1-MIN_SIZE) - 1
	    size = append(size, s)
	    circles = append(circles, {{x, y}, {x, y}+s})
	    dirs = append(dirs, floor(s/2)+rand({10*s, 10*s})/10)
	    colors = append(colors, 8+rand(vc[VC_NCOLORS]/2-1))
	end if
	
	-- move all the circles
	for i = 1 to length(circles) do
	    top_left = circles[i][1]
	    prev_circle = circles[i]
	    if top_left[X] < 0 or top_left[X]+size[i] >= vc[VC_XPIXELS] then 
		dirs[i][X] = -dirs[i][X] 
	    end if
	    if top_left[Y] < 0 or top_left[Y]+size[i] >= vc[VC_YPIXELS] then 
		dirs[i][Y] = -dirs[i][Y] 
	    end if
	    top_left += dirs[i]
	    circles[i] = {top_left, top_left+size[i]}
	    -- blank out old position
	    ellipse(BLACK, FILL, prev_circle[1], prev_circle[2])
	    -- draw at new position
	    ellipse(colors[i], FILL, circles[i][1], circles[i][2])
	end for
    end while
    if graphics_mode(-1) then
    end if
end procedure

bounce()

