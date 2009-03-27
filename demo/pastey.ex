--
-- This demo sends a euphoria source code file to
-- http://euphoria.pastey.net for discussion on IRC
-- or other Internet means.
--
-- Program originally written by Kathy Smith (Kat) modified
-- for inclusion of a demo program by Jeremy Cowgar.
--

include std/io.e
include std/regex.e as r
include std/net/http.e

sequence cmds = command_line()
if not (length(cmds) = 5) then
    puts(1, "Usage: pastey.ex user title filename\n")
	abort(1)
end if

sequence username = cmds[3], title = cmds[4], filename = cmds[5]
object data = read_file(filename)

if atom(data) then
    printf(1, "Could not read file: '%s'\n", { filename })
	abort(1)
end if

username = urlencode(username)
title = urlencode(title)
data = urlencode(data)

set_sendheader("POSTDATA", sprintf("language=euphoria&paste=Paste&author=%s&subject=%s&text=%s",
    { username, title, data }))
data = get_url("http://euphoria.pastey.net/submit.php")

if equal(data[1], "") or equal(data[2], "") then
    puts(1, "An error occurred while submitting your file.\n")
    abort(1)
end if

data = data[2] -- we are only interested in the web page data, not it's header data

-- Test to see if the paste was a success
regex reLink = r:new("http://euphoria.pastey.net/[0-9]+")
if r:has_match(reLink, data) then
	sequence matchData = r:find(reLink, data)
	puts(1, data[matchData[1][1]..matchData[1][2]] & "\n")
else
    if match("Spam check", data) then
	    puts(1, #~
____________Your paste triggered a spam check of pastey.net which is
			normally triggered by including a URL in your paste. pastey.ex
			does not currently support this handshake, thus you need to
			try removing any URLs in your paste and try again, or submit
			your paste manually to http://euphoria.pastey.net
			~)
    else
        puts(1, "Your paste was not accepted. The HTML result is:\n")
	    puts(1, data & "\n")
	end if

    abort(1)
end if
