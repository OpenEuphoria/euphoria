-- bitmap displayer
-- usage: ex bitmap file[.bmp]
--
-- example:  ex bitmap c:\windows\forest
--
-- It tries to use mode 261 for 256-color bitmaps and
-- mode 18 for 16-color or less. If you can't get into mode 261
-- try mode 19, or see graphics.e

without type_check
include std/image.e
include std/graphics.e
include std/graphcst.e
include std/dos/pixels.e

constant ERR = 2

sequence cl
object bitmap
integer xlen, ylen
sequence image, Palette, vc

cl = command_line()
if length(cl) < 3 then
    puts(ERR, "usage: ex bitmap file.bmp\n")
    abort(1)
end if
if not find('.', cl[3]) then
    cl[3] &= ".bmp"
end if

bitmap = read_bitmap(cl[3])

if atom(bitmap) then
    -- failure
    if bitmap = BMP_OPEN_FAILED then
	puts(ERR, cl[3] & ": " & "couldn't open\n")
    elsif bitmap = BMP_UNEXPECTED_EOF then
	puts(ERR, cl[3] & ": " & "unexpected end of file\n")
    else
	puts(ERR, cl[3] & ": " & "unsupported format\n")
    end if
    abort(1)
end if

Palette = bitmap[1]
image = bitmap[2]

integer mode, xstart

if length(Palette) > 16 then
    mode = 261  -- do you have this mode?
else
    mode = 18   -- almost everyone has this one
end if
if graphics_mode(mode) then
    puts(ERR, "bad graphics mode\n")
    abort(1)
end if

all_palette(Palette/4)  -- set the whole palette

display_image({0,0}, image) -- always display first one

vc = video_config()

-- display others if there's room:
xlen = length(image[1])
ylen = length(image)
xstart = xlen+1
for y = 0 to vc[VC_YPIXELS]-floor(ylen/2) by ylen+1 do
    for x = xstart to vc[VC_XPIXELS]-floor(xlen/2) by xlen+1 do
	display_image({x,y}, image)
    end for
    xstart = 0
end for

while get_key() = -1 do
end while
if graphics_mode(-1) then
end if

