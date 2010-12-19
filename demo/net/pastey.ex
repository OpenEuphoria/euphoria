--****
-- === net/pastey.ex
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
include std/net/url.e as url
include std/console.e
include std/cmdline.e
include std/text.e
include std/map.e

without warning
override procedure abort(integer x, sequence msg = {}, sequence data = {})
	if length(msg) then
    	printf(2, msg & "\n", data)
    end if

	eu:abort(x)
end procedure

sequence opts = {
	{ "u", 0, "OpenEuphoria.org username", { MANDATORY, HAS_PARAMETER, "username" } },
    { "p", 0, "OpenEuphoria.org password", { MANDATORY, HAS_PARAMETER, "password" } },
    { "f", 0, "Format (Euphoria, Text, Creole)", { HAS_PARAMETER, "format" } },
    { "t", 0, "Title of new pastey", { MANDATORY, HAS_PARAMETER } },
    {  0,  0, "Filename to paste", { MANDATORY } },
    $
}

map o = cmd_parse(opts)

sequence filenames = map:get(o, cmdline:EXTRAS)
object data = read_file(filenames[1])
if atom(data) then
	abort(1, "Could not read file: '%s'", { filenames[1] })
end if

sequence format = map:get(o, "f", "text")
integer format_i

switch lower(format) do
	case "text" then
    	format_i = 1
    case "euphoria" then
    	format_i = 2
    case "creole" then
    	format_i = 3
    case else
    	abort(1, "Invalid format specified '%s'\n" &
        	"Try Text, Euphoria or Creole", { format })
end switch

sequence form_data = {
	{ "code",     map:get(o, "u") },
    { "password", map:get(o, "p") },
    { "title",    map:get(o, "t") },
    { "format",   sprintf("%d", format_i) },
    { "body",     data },
    { "submit",   "Paste" },
    $
}

data = http_post("http://localhost/pastey/create.wc", form_data)

if equal(data[1], "") or equal(data[2], "") then
    abort(1, "An error occurred while submitting your file.\n")
end if

data = data[2] -- we are only interested in the web page data, not it's header data
puts(1, data & "\n")
