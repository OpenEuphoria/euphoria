	-- Display ASCII / code page chart
	-- in 50 lines-per-screen mode  

include graphics.e

constant SCREEN = 1

if text_rows(50) then
end if

text_color(WHITE)
for i = 0 to 255 do
    if remainder(i, 8) = 0 then 
	puts(SCREEN, '\n')
	if i = 128 and platform() = LINUX then
	    if getc(0) then
	    end if
	end if
    end if
    if remainder(i, 32) = 0 then
	puts(SCREEN, '\n')
    end if
    printf(SCREEN, "%3d: ", i)
    if i = 0 then
	puts(SCREEN, "NUL ")
    elsif i = 9 then
	puts(SCREEN, "TAB ")
    elsif i = 10 then
	puts(SCREEN, "LF  ")
    elsif i = 13 then
	puts(SCREEN, "CR  ")
    else
	puts(SCREEN, i)
	puts(SCREEN, "   ")
    end if
end for

text_color(WHITE)
puts(SCREEN, "\n\nPress Enter...")
if atom(gets(0)) then
end if

if graphics_mode(-1) then
end if

