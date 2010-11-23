--test terminal colours - seems to be working on some terminals, but not others 

include std/graphics.e
include std/graphcst.e
include std/text.e
include std/console.e

integer ESC = 27

integer key

sequence colour_names = {
	"BLACK",
	"GREEN",
	"MAGENTA",
	"WHITE",
	"GRAY",
	"BRIGHT_GREEN",
	"BRIGHT_MAGENTA",
	"BRIGHT_WHITE",
	"BLUE",
	"CYAN",
	"RED",
	"BROWN",
	"BRIGHT_BLUE",
	"BRIGHT_CYAN",
	"BRIGHT_RED",
	"YELLOW" }
sequence colour_values = {
	BLACK,
	GREEN,
	MAGENTA,
	WHITE,
	GRAY,
	BRIGHT_GREEN,
	BRIGHT_MAGENTA,
	BRIGHT_WHITE,
	BLUE,
	CYAN,
	RED,
	BROWN,
	BRIGHT_BLUE,
	BRIGHT_CYAN,
	BRIGHT_RED,
	YELLOW
	}

integer fgrnd = 0, bgrnd = 0
sequence fgn = "", bgn = ""
integer blink_on = 0

while 1 do
	text_color(WHITE)
	bk_color(BLACK)
	
	clear_screen()
	position(1, 1)
	puts(1, "This tests the screen colour capabilities of the terminal\nPress ...\n")
	puts(1, "   F  -> next foreground colour\n")
	puts(1, "   B  -> next background colour\n")
	puts(1, "   L  -> toggles 'blink'\n")
	puts(1, "  Esc -> quits\n")
	
	--get fg and bg names 
	fgn = "?" bgn = "?"
	for i = 1 to 16 do
		if colour_values[i] = fgrnd then
			fgn = colour_names[i]
		end if
	end for
	
	for i = 1 to 16 do
		if colour_values[i] = bgrnd then
			bgn = colour_names[i]
		end if
	end for
	
	position(7, 1)
	printf(1, "%-10s %-20s %-10s\n", { "", "Name", "Value" })
	printf(1, "%-10s %-20s %-10d\n", { "Fore", fgn, fgrnd })
	printf(1, "%-10s %-20s %-10d\n", { "Back", bgn, bgrnd })
	printf(1, "%-10s %d\n\n\n\n", { "Blink", blink_on })
	
	text_color(fgrnd + (blink_on * 16))
	bk_color(bgrnd)
	
	puts(1, "----------------------------------------------\n")
	puts(1, "This is an example of what it would look like!\n")
	puts(1, "----------------------------------------------\n")
	
	key = wait_key()
	if key = ESC then exit end if
	
	if upper(key) = 'B' then
		bgrnd += 1
		if bgrnd = 16 then bgrnd = 0 end if
	end if
	if upper(key) = 'F' then
		fgrnd += 1
		if fgrnd = 16 then fgrnd = 0 end if
	end if
	if upper(key) = 'L' then
		blink_on = (blink_on - 1) * - 1
	end if
	
end while
text_color(WHITE)
bk_color(BLACK)

graphics_mode(18)
clear_screen()

