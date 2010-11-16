		----------------------------------------
		--    Key Code Display in Euphoria    --
		----------------------------------------
-- Notes:
--
-- Press Keyboard to see what code is displayed  
-- 
include std/console.e

integer x


puts(1, "Press Any Control-Key combination to see the code it generates.\n")
puts(1, "Press Control+C to quit.\n")

while 1 do
	x = get_key()
	if x = -1 then
		continue
	else
		puts(1, "The code you pressed was:")
		? x
	end if
	puts(1, "Press Control+C to quit.\n")
end while
