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

include std/cmdline.e
include std/console.e
include std/io.e
include std/map.e
include std/net/http.e
include std/net/url.e as url
include std/regex.e as r
include std/text.e
include std/sequence.e

sequence username, password, title

without warning
--**
-- @nodoc@
override procedure abort(integer x, sequence msg = {}, sequence data = {})
	if length(msg) then
    	printf(2, msg & "\n", data)
    end if

	eu:abort(x)
end procedure

sequence opts = {
	{ "u", 0, "OpenEuphoria.org username", { HAS_PARAMETER, "username" } },
    { "p", 0, "OpenEuphoria.org password", { HAS_PARAMETER, "password" } },
    { "f", 0, "Format (Euphoria, Text, Creole)", { HAS_PARAMETER, "format" } },
    { "t", 0, "Title of new pastey", { HAS_PARAMETER } },
    {  0,  0, "Filename to paste", { } },
    $
}

map o = cmd_parse(opts)
sequence filenames = map:get(o, cmdline:EXTRAS)
constant in_stdin = not length(filenames)

username = map:get(o, "u", "")
if length(username) = 0 then
	if in_stdin then
		puts(1, "Missing OpenEuphoria username.\n")
		abort(4)
	end if
	username = prompt_string("OpenEuphoria username: ")
end if

password = map:get(o, "p", "")
if length(password) = 0 then
	if in_stdin then
		puts(1, "Missing OpenEuphoria password.\n")
		abort(5)
	end if
	password = prompt_string("OpenEuphoria.org password: ")
end if

title = map:get(o, "t", "")
if length(title) = 0 then
	if in_stdin then
		puts(1, "Missing Pastey title.\n")
		abort(6)
	end if
	title = prompt_string("Pastey title: ")
end if

object data
if length(filenames) then
	data = read_file(filenames[1], TEXT_MODE)
else
	data = flatten(read_lines(0))
end if
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
	{ "code",     username },
    { "password", password },
    { "title",    title },
    { "format",   sprintf("%d", format_i) },
    { "body",     data },
    { "submit",   "Paste" },
    $
}

data = http_post("http://openeuphoria.org/pastey/create.wc", form_data)
if atom(data) then
	abort(1, "Could not connect to pastey server")
elsif equal(data[1], "") or equal(data[2], "") then
    abort(1, "An error occurred while submitting your file.\n")
end if

data = data[2] -- we are only interested in the web page data, not it's header data
puts(1, data & "\n")
