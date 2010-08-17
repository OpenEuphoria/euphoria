-- Run this as with eui, or euiw, or translate with euc and it will inform you what platform
-- you are using (as long as you are on Windows).  However, if you bind this program it
-- into an executable the executable will report DOS32!

include std/win32/msgbox.e
atom ok
sequence strings = { "DOS32", "WIN32" }
function to_string(integer p)
	if p != 1 and p != 2 then
	     return sprintf("%d", {p})
	end if
	return strings[p]
end function
ok = message_box( sprintf( "platform()=%s", {to_string(platform())} ), "Information", MB_OK )
--printf(1, "platform()=%s\n", { to_string(platform()) } )
