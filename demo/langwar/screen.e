-- screen.e: access to the screen

	      --------------------------------
	      -- graphics portion of screen --
	      --------------------------------
-- in calls to read_screen and write_screen
-- the screen looks like:

-- (1,1)..................(1,HSIZE)
-- ................................
-- ................................
-- (VSIZE,1)..........(VSIZE,HSIZE)

-- Note however that pixel() uses origin (0,0) coordinates

global constant HSIZE = 80 * 8,  -- horizontal size (char positions)
		VSIZE = 26 * 16, -- vertical size (lines) graphics portion
	    FULLVSIZE = 30 * 16  -- vertical size (lines) full screen  
	   
	   ----------------------------
	   -- text portion of screen --
	   ----------------------------

global constant QUAD_LINE = VSIZE/16 + 1,
		WARP_LINE = VSIZE/16 + 2,
		CMD_LINE  = VSIZE/16 + 3,
		MSG_LINE  = VSIZE/16 + 4

global constant CMD_POS = 18,     -- place for first char of user command
	       WARP_POS = 9,      -- place for "WARP:" to appear
	       DREP_POS = 51,     -- place for damage report
	       WEAPONS_POS = 30,  -- place for torpedos/pos/deflectors display
	       ENERGY_POS = 67,   -- place for ENERGY display
	       DOCKING_POS = 29,  -- place for "DOCKING"
	       MSG_POS = 16,      -- place for messages to start
	       DIRECTIONS_POS = 1 -- place to put directions

global type h_coord(integer x)
-- true if x is a horizontal screen coordinate
    return x >= 1 and x <= HSIZE
end type

global type v_coord(integer y)
-- true if y is a vertical screen coordinate
    return y >= 1 and y <= VSIZE
end type

global type extended_h_coord(atom x)
    -- horizontal coordinate, can be reasonably far off the screen
    return x >= -1000 and x <= HSIZE + 1000
end type

global type extended_v_coord(atom y)
    -- vertical coordinate, can be reasonably far off the screen
    return y >= -1000 and y <= VSIZE + 1000
end type

integer last_text_color
last_text_color = -1

global procedure set_color(integer color)
-- all foreground color changes come through here
    last_text_color = color
end procedure

integer last_bk_color
last_bk_color = -1

global procedure set_bk_color(integer color)
-- all background color changes come through here
    last_bk_color = color
end procedure

global boolean scanon -- galaxy scan on/off

integer cursor_line=1, cursor_column=1

-- override position()

without warning
override procedure position(integer line, integer column)
    cursor_line = line
    cursor_column = column
end procedure

global type image(sequence s)
-- a 2-d rectangular image
    return sequence(s[1])
end type

global procedure console_puts(object string)
-- write text to the screen
    sequence gpos
    
    if atom(string) then
	string = {string}
    elsif length(string) = 0 then
	return
    end if
    
    gpos = {(cursor_column-1) * 8, (cursor_line-1) * 16}  -- {x pixel, y pixel}
    cursor_column += length(string)
    putsxy(gpos, string, last_text_color, last_bk_color, 'a')
end procedure

global procedure console_printf(sequence format, object values)
-- write printf output to the screen
    console_puts(sprintf(format, values))   
end procedure

global function is_pod(image s)
-- check if an image contains any POD pixels, range 16..31 
    sequence row
    
    for i = 1 to length(s) do
	row = s[i]
	for j = 1 to length(row) do
	    if row[j] >= 16 and row[j] <= 31 then
		return TRUE  
	    end if
	end for
    end for
    return FALSE
end function

global function all_clear(image s)
-- check if an image contains only 0's, stars and torpedo/phasor/explosion
-- "fluff".
-- 33..47 is just "fluff" (not really there - phasors etc.)
-- 32 is transparent areas of an object
    sequence row
    
    for i = 1 to length(s) do
	row = s[i]
	for j = 1 to length(row) do
	    if row[j] >= 1 and row[j] <= 32 then
		return FALSE  
	    end if
	end for
    end for
    return TRUE
end function

global sequence screen -- Contains a copy of what should be on the
		       -- action screen above the console.
		       -- The galaxy scan is handled separately.
		       
global function read_screen(h_coord x, extended_v_coord y, image shape)
-- return the rectangular 2-d image at (x, y) with the same dimensions as shape
    sequence r
    integer width1
    
    width1 = length(shape[1])-1
    r = repeat(0, length(shape))
    y -= 1
    for i = 1 to length(shape) do
	r[i] = screen[y+i][x..x+width1]
    end for
    return r
end function

global function read_torp(h_coord x, v_coord y)
-- read the torpedo shape - assumed to be 2x2 for higher performance
    return {screen[y][x..x+1], 
	    screen[y+1][x..x+1]}
end function

global function update_image(image background, positive_int x, positive_int y,
			     image shape)
-- write shape into background image    
    integer width1
    
    width1 = length(shape[1])-1
    y -= 1
    for i = 1 to length(shape) do
	background[y+i][x..x+width1] = shape[i]
    end for
    return background
end function

global procedure write_screen(h_coord x, extended_v_coord y, image shape)
-- write a rectangular 2-d image into the screen variable and onto the 
-- physical screen

    integer width1
    
    width1 = length(shape[1])-1
    y -= 1
    for i = 1 to length(shape) do
	screen[y+i][x..x+width1] = shape[i]
    end for
    if not scanon then
	display_image({x-1, y}, shape)
    end if
end procedure

-- delayed-write rectangular region {{xmin,ymin}, {xmax, ymax}}
object delayed 
delayed = 0

global procedure delayed_write_screen(h_coord x, extended_v_coord y, image shape)
-- write a rectangular 2-d image into the screen variable but *not* to the 
-- physical screen (yet). Avoids flicker.

    integer w, x1, y1
    
    w = length(shape[1])-1
    y -= 1
    for i = 1 to length(shape) do
	screen[y+i][x..x+w] = shape[i]
    end for
    y += 1
    x1 = x + w
    y1 = y + length(shape)-1
    if atom(delayed) then
	delayed = {{x,y},{x1,y1}}
    else
	-- enlarge the delayed-write region?
	if x < delayed[1][1] then
	    delayed[1][1] = x
	end if
	if y < delayed[1][2] then
	    delayed[1][2] = y
	end if
	if x1 > delayed[2][1] then
	    delayed[2][1] = x1
	end if
	if y1 > delayed[2][2] then
	    delayed[2][2] = y1
	end if
    end if
end procedure

global procedure flush_screen()
-- write the delayed-write region to the physical screen   
    sequence delayed_image
    natural xmin, xmax, ybase
    
    if not scanon and sequence(delayed) then
	delayed_image = repeat(0, delayed[2][2] - delayed[1][2] + 1)
	xmin = delayed[1][1]
	xmax = delayed[2][1]
	ybase = delayed[1][2]-1
	for i = 1 to length(delayed_image) do
	    delayed_image[i] = screen[ybase+i][xmin..xmax]
	end for
	display_image(delayed[1]-1, delayed_image)
    end if
    delayed = 0
end procedure

global procedure write_torp(extended_h_coord x, v_coord y, image shape)
-- write a torpedo-shaped object - assumed to be 2x2 for higher performance
    screen[y  ][x..x+1] = shape[1]
    screen[y+1][x..x+1] = shape[2]
    if not scanon then
	x -= 1
	pixel(shape[1], {x, y-1})
	pixel(shape[2], {x, y  })
    end if
end procedure

global constant BLANK_LINE = repeat(' ', 80)

sequence black_screen
-- (doesn't use much space, because of shared pointers)
black_screen = repeat(repeat(BLACK, HSIZE), VSIZE)

-- quadrants on galaxy scan
global constant QXSIZE = 64, 
		QYSIZE = 40,
		QXBASE = 32,
		QYBASE = -8      

sequence blue_screen -- background for scan
sequence blue_black_line, blue_line
blue_screen = repeat(0, VSIZE)
blue_black_line = repeat(BLUE, QXBASE+QXSIZE) & 
		  repeat(BLACK, QXSIZE*G_SIZE) &
		  repeat(BLUE, QXBASE+QXSIZE)
blue_line = repeat(BLUE, HSIZE)
for i = 1 to VSIZE do
    if i > QYBASE+QYSIZE and i <= QYBASE+QYSIZE+G_SIZE*QYSIZE then
	blue_screen[i] = blue_black_line
    else
	blue_screen[i] = blue_line
    end if
end for

global procedure BlueScreen()
-- set physical upper screen to BLUE for scan
    display_image({0,0}, blue_screen)
end procedure

global procedure BlackScreen()
-- Set physical upper screen to BLACK
-- and set the screen variable too.
-- Initially the screen variable is undefined

    screen = black_screen
    if not scanon then
	display_image({0,0}, screen)
    end if
end procedure

global procedure ShowScreen()
-- rewrite screen after galaxy scan
    display_image({0, 0}, screen)
end procedure

global atom frame_rate
frame_rate = 0.5   -- time between snapshots

global sequence frame_list
frame_list = {}

global boolean recording
recording = TRUE

global procedure task_video_snapshot()
-- task a snapshot of the screen
    sequence row, frame, arg
    sequence new_frame
    integer endscan
    
    endscan = 8 * QYSIZE - 9

    new_frame = repeat(repeat(0, HSIZE), FULLVSIZE)
    arg = {0, 0, HSIZE}
    while recording do
	if scanon then
	    -- this is a fairly big chunk of work to do in one shot
	    -- (0.085 seconds, repeated after .500 seconds)
	    
	    -- top blue piece
	    for y = 1 to 32 do
		new_frame[y] = blue_line -- saves a bit of time and space
	    end for
	    
	    -- read galaxy from video memory
	    for y = 33 to endscan do
		arg[2] = y-1
		new_frame[y] = get_pixel(arg)
	    end for
	    
	    -- Take a tiny break to allow any overdue tasks to get in.
	    -- This could create some slight inconsistency, but it probably
	    -- won't be significant, and will be corrected quickly.
	    task_schedule(t_video_snapshot, {0, 0})
	    task_yield()
	    
	    -- now read the rest (might be a tad out-of-sync with above)
	    for y = endscan+1 to FULLVSIZE do
		arg[2] = y-1
		new_frame[y] = get_pixel(arg)
	    end for
	else
	    -- get upper part from screen variable (much faster)
	    new_frame[1..length(screen)] = screen
	    -- read lower part only from video memory
	    for y = length(screen)+1 to FULLVSIZE do
		arg[2] = y-1
		new_frame[y] = get_pixel(arg)
	    end for
	end if
	frame_list = append(frame_list, new_frame)
	
	if length(frame_list) > 100 then
	    -- machine is too slow, can't keep up
	    frame_rate *= 1.1
	end if
	
	task_schedule(t_video_snapshot, {.9*frame_rate, frame_rate})
	task_yield()
    end while
end procedure 

global integer video_file

procedure save_segment(sequence row, integer y, integer d1, integer d2)
-- save a horizontal segment of pixels to disk  
    sequence segment, pack_segment
    
    puts(video_file, y)
    puts(video_file, floor(y/256))
		    
    puts(video_file, d1)
    puts(video_file, floor(d1/256))
		    
    puts(video_file, d2)
    puts(video_file, floor(d2/256))
			
    segment = row[d1..d2]
    if remainder(length(segment), 2) = 1 then
	-- odd length
	segment = append(segment, 0) -- pad
    end if
    
    -- pack 2 pixels per byte
    pack_segment = repeat(0, length(segment)/2)  
    for p = 1 to length(pack_segment) do
	pack_segment[p] = 16 * and_bits(segment[p*2], #0F) + 
			       and_bits(segment[p*2-1], #0F)
    end for
    
    puts(video_file, pack_segment)
end procedure

global procedure task_video_save()
-- save one or more snapshots to disk
    sequence frame
    integer d1, d2, iter, same, width
    sequence previous_frame, previous_row, row

    previous_frame = repeat(repeat(-1, HSIZE), FULLVSIZE)
    iter = 0
    while TRUE do
	if length(frame_list) > 0 then
	    -- one or more frames in the queue
	    frame = frame_list[1]
	    frame_list = frame_list[2..$]
	    width = length(frame[1])
	    
	    for y = 1 to FULLVSIZE do
		row = frame[y]
		previous_row = previous_frame[y]
		if not equal(row, previous_row) then
		    -- this row has changed vs. previous frame
		    d1 = 1
		    while d1 <= width do
			-- skip same pixels
			while d1 <= width and 
			      row[d1] = previous_row[d1] do
			    d1 += 1
			end while
			if d1 > width then
			    exit
			end if
			
			-- we're at a different pixel
			d2 = d1
			same = 0
			while TRUE do
			    if row[d2] = previous_row[d2] then
				same += 1
				if same > 20 then -- small segments are not efficient
				    exit
				end if
			    else
				same = 0
			    end if
			    if d2 = width then
				exit
			    end if
			    d2 += 1
			end while
			d2 -= same -- back up to last different pixel
			
			-- this segment differs - save it
			save_segment(row, y, d1, d2)
			
			d1 = d2+same+1
		    end while
		    
		    iter += 1
		    
		    if iter > 2 * length(frame_list) or iter > 20 then
			-- To avoid impacting the game, we normally yield 
			-- after each row that differs, but if there's a 
			-- queue building up, we do more rows each time
			task_yield()
			iter = 0
		    end if
		end if
	    end for
	    
	    previous_frame = frame
	else
	    task_yield()
	end if
    end while
end procedure

