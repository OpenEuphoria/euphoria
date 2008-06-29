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
	end if
	ifdef LINUX then
		if i = 128 then
		    if getc(0) then
	    	end if
		end if
	end ifdef

    if remainder(i, 32) = 0 then
		puts(SCREEN, '\n')
    end if
    printf(SCREEN, "%3d: ", i)
    switch i do
    	case 0:
			puts(SCREEN, "NUL ")
			break
			
		case 9:
			puts(SCREEN, "TAB ")
			break
			
		case 10:
			puts(SCREEN, "LF  ")
			break
			
		case 13:
			puts(SCREEN, "CR  ")
			break
			
		case else
			puts(SCREEN, i)
			puts(SCREEN, "   ")
    end switch
end for

text_color(WHITE)
puts(SCREEN, "\n\nPress Enter...")
if atom(gets(0)) then
end if

if graphics_mode(-1) then
end if

