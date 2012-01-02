--****
-- === ascii.ex
--
-- Display ASCII / code page chart in 50 lines-per-screen mode

include std/graphics.e
include std/graphcst.e
include std/console.e

constant SCREEN = 1

text_rows(50)

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
		case 0 then
			puts(SCREEN, "NUL ")
			break
			
		case 9 then
			puts(SCREEN, "TAB ")
			break
			
		case 10 then
			puts(SCREEN, "LF  ")
			break
			
		case 13 then
			puts(SCREEN, "CR  ")
			break
			
		case else
			puts(SCREEN, i)
			puts(SCREEN, "   ")
	end switch
end for

puts(SCREEN, "\n\nPress Enter...")
gets(0)
