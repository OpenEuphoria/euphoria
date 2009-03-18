-- Play back a Language War game
--
-- usage 1:
--    ex playback  
--    (plays lastgame.vid by default) 
--
-- usage 2:
--    ex playback filename.vid
--    e.g. ex playback win1
--
-- p           pauses or resumes
-- right-arrow speeds up
-- left-arrow  slows down
-- Esc         (and most other keys) quits

include graphics.e
include get.e

constant LEFT_ARROW = 331,
	 RIGHT_ARROW = 333

integer fn
integer row, startcol, endcol, odd, k
sequence segment, pack_segment, vidname, cl
atom t, delay

cl = command_line()
if length(cl) >= 3 then
    vidname = cl[3]
    if not find('.', vidname) then
	vidname &= ".vid"
    end if
else
    vidname = "lastgame.vid"
end if

fn = open(vidname, "rb")
if fn = -1 then
    for i = 99 to 1 by -1 do
	vidname = sprintf("win%d.vid", i)
	fn = open(vidname, "rb")
	if fn != -1 then
	    exit
	end if
    end for
    if fn = -1 then
	puts(2, "couldn't open .vid file\n")
	abort(1)
    end if
end if

if graphics_mode(18) then
end if

puts(1, "Playing " & vidname & "\n\n")
puts(1, "right-arrow - speed up\n\n")
puts(1, "left-arrow - slow down\n\n")
puts(1, "p - pause or resume\n\n")
puts(1, "Esc - quit\n\n")
puts(1, "Press Enter to start\n\n")

if getc(0) then
end if

delay = 0.25 -- to start with

integer prev_row 
prev_row = 480

while 1 do
    row = getc(fn)
    if row = -1 then
	exit
    end if
    row += 256 * getc(fn)
    
    startcol = getc(fn)
    startcol += 256 * getc(fn)
    
    endcol = getc(fn)
    endcol += 256 * getc(fn)
    
    odd = remainder(endcol - startcol, 2) = 0 
    endcol += odd
    
    pack_segment = {}
    for i = 1 to (endcol-startcol+1)/2 do
	pack_segment = append(pack_segment, getc(fn))
    end for 
    
    segment = repeat(0, 2*length(pack_segment))
    for i = 1 to length(pack_segment) do
	segment[2*i-1] = remainder(pack_segment[i], 16)
	segment[2*i] = floor(pack_segment[i] / 16)
    end for
    
    if odd then
	segment = segment[1..$-1]
    end if
    
    if row < prev_row then
	-- starting new frame, delay now
	k = get_key()
	if k != -1 then
	    if k = 'p' then
		while get_key() = -1 do
		end while
	    elsif k = LEFT_ARROW then
		if delay < 5 then
		    delay *= 2
		end if
	    elsif k = RIGHT_ARROW then
		if delay > .001 then
		    delay /= 2
		end if
	    elsif k != 13 then
		if graphics_mode(-1) then
		end if
		abort(0)
	    end if
	end if
	t = time()
	while time() < t + delay do
	end while
    end if
    
    pixel(segment, {startcol-1, row-1})
    prev_row = row
end while

while get_key() = -1 do
end while

if graphics_mode(-1) then
end if

