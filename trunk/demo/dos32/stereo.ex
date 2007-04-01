-- Random Dot Stereo Pictures
-- Like the ones you've seen in all the shopping malls!
-- Relax your eyes so that you are focusing a few inches
-- behind the screen - maybe on your reflection if you have
-- a lot of glare. You should see 2 letters of the alphabet,
-- one upper case, one lower case.

-- usage:  ex stereo [filename]
-- (will read PICTURE file by default)

-- picture can contain digits from 1 to 9 to indicate "depth"

without type_check
include graphics.e

constant DEPTH = 13
sequence vc
integer xpixels_per_char, ypixels_per_char, in_file

procedure gstereo()
    object input
    sequence image, row, line
    integer index, height, w
    
    image = {}
    while 1 do
	input = gets(in_file)
	if atom(input) then
	    exit
	end if
	image = append(image, repeat(' ', DEPTH) & input)
    end while
    w = DEPTH * xpixels_per_char
    for y = 0 to (length(image)-1)*ypixels_per_char do
	line = image[floor(y/ypixels_per_char+1)]
	row = repeat(0, (length(image[1])-1)*xpixels_per_char)
	row[1..w] = rand(repeat(vc[VC_NCOLORS], w))-1
	for x = w + 1 to length(row) do
	    height = line[x/xpixels_per_char+1]
	    index = x - w
	    if height >= '0' then
		if height <= '9' then
		    index += (height - '0') * xpixels_per_char
		end if
	    end if  
	    row[x] = row[index]
	end for
	pixel(row, {0, y})
    end for
end procedure

if graphics_mode(18) then
    puts(2, "need VGA graphics\n")
    abort(1)
end if

sequence cmd, file_name

cmd = command_line()
if length(cmd) >= 3 then
    file_name = cmd[3]
else
    file_name = "picture"
end if

in_file = open(file_name, "r")
if in_file = -1 then
    printf(1, "Can't open %s\n", {file_name})
    abort(1)
end if

clear_screen()
vc = video_config()
xpixels_per_char = floor(vc[VC_XPIXELS]/80)
ypixels_per_char = floor(vc[VC_YPIXELS]/25)

gstereo()

while get_key() = -1 do
end while
if graphics_mode(-1) then
end if

