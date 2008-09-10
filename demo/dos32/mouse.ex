		----------------
		-- mouse test --
		----------------
-- This is a very simple program to demonstrate the get_mouse() built-in
-- function. No call is made to mouse_events(), so by default all events are
-- reported by get_mouse(). 

include std/mouse.e
include std/graphics.e
include std/graphcst.e
include std/dos/pixels.e
include std/os.e

sequence vc
vc = video_config()
if graphics_mode(17 + vc[VC_COLOR]) then -- 640x480 (16 colors)
    puts(1, "Can't get good graphics mode\n")
    abort(1)
end if 
vc = video_config()
constant origin = {vc[VC_XPIXELS]/2, vc[VC_YPIXELS]/2}
constant MAX_LINE = 5

procedure beep(integer pitch)
    atom t
    sound(pitch)
    t = time()
    while time() < t+0.07 do
    end while
    sound(0)
end procedure

procedure try_mouse()
    integer color, line, eventNo
    object event
    sequence movement, str

    color = 14
    eventNo = 0
    line = 1
    while 1 do
	event = get_mouse()
	if sequence(event) then
	    eventNo += 1
	    movement = "- -- -- --"

	    if and_bits(event[1], MOVE) then
		movement[1] = 'M'
		mouse_pointer(0)
		draw_line(color, {origin, {event[2], event[3]}}) 
		mouse_pointer(1)
	    end if

	    if and_bits(event[1], LEFT_DOWN) then
		movement[3] = 'D'
		beep(500)
		color += 1
		if color > 15 then
		    color = 0
		end if 
	    end if

	    if and_bits(event[1], LEFT_UP) then
		movement[4] = 'U'
		beep(500)
	    end if
				
	    if and_bits(event[1], MIDDLE_DOWN) then
		movement[6] = 'D'
		beep(1000)
	    end if
	    
	    if and_bits(event[1], MIDDLE_UP) then 
		movement[7] = 'U'
		beep(1000)
	    end if
	    
	    if and_bits(event[1], RIGHT_DOWN) then 
		movement[9] = 'D'
		beep(1000)
	    end if
	    
	    if and_bits(event[1], RIGHT_UP) then 
		movement[10] = 'U'
		beep(1000)
	    end if
	    
	    if eventNo > 1 then
		puts(1, str) 
		line += 1
		if line > MAX_LINE then
		    line = 1
		end if
		position(line, 1)
	    end if
	    
	    str = sprintf("event# %4d: %s, x:%d, y:%d       \r", 
		   {eventNo, movement, event[2], event[3]})

	    text_color(BRIGHT_MAGENTA)
	    puts(1, str)
	    text_color(WHITE)
	    puts(1, '\n' & repeat(' ', length(str))) 
	    position(line, 1)
	end if
	
	if get_key() != -1 then
	    exit
	end if
    end while
end procedure

try_mouse()

if graphics_mode(-1) then
end if

