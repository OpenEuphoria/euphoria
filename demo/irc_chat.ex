--****
-- == Simple IRC Client
--
-- This is not a complete IRC client but a simple one that anyone who
-- has installed Euphoria can use to get on the Euphoria chat channel,
-- #euphoria, on irc.freenode.net.
--
-- It also is an example on how to use cmd_parse() from std/cmd_line.e
-- and also sockets to connect to a server, std/socket.e
--

-- std lib
include std/cmdline.e
include std/convert.e
include std/io.e
include std/map.e as map
include std/regex.e as re
include std/search.e
include std/sequence.e
include std/text.e
include std/utils.e

-- network includes
include std/socket.e as sock
include std/net/dns.e

--===========================================================================
--
-- Get all of our options
--
--===========================================================================

sequence cmd_opts = {
	{ "n", "nickname", "Nickname to sign on as",    { HAS_PARAMETER, "nick" } },
	{ "f", "fullname", "Full name",                 { HAS_PARAMETER, "name" } },
	{ "s", "server",   "Server name (irc.freenode.net)",
	                                                { HAS_PARAMETER, "host" } },
	{ "p", "port",     "Server port (6667)",        { HAS_PARAMETER, "port" } },
	{ "c", "channel",  "Channel name (#euphoria)",  { HAS_PARAMETER, "name" } },
	{ "d", "debug",    "Write a debug.log file",    { NO_PARAMETER } }
}

map opts = cmd_parse(cmd_opts)

sequence fullname   = map:get(opts, "fullname", "")
sequence nickname   = map:get(opts, "nickname", "")
sequence servername = map:get(opts, "server", "irc.freenode.net")
sequence port_s     = map:get(opts, "port", "")
sequence channel    = map:get(opts, "channel", "#euphoria")
integer  debug_mode = map:get(opts, "debug")
integer  debug_fh   = -1
integer  port       = 6667

sock:socket soc

if length(port_s) then
	port = to_number(port_s)
end if

while length(fullname) < 3 do
	puts(1, "Enter your full name (>3 chars): ")
	fullname = gets(0)
end while

while length(nickname) < 3 do
	puts(1, "Enter your nick name (>3 chars): ")
	nickname = gets(0)
end while

--===========================================================================
--
-- Setup a IRC message regular expressions
--
--===========================================================================

constant re_notice = re:new(`^:([^\s]+)\sNOTICE\s.+:(.*)$`)
constant re_other  = re:new(`^:([^\s]+)[^:]+:(.*)$`)
constant re_normal = re:new(`^:([^!]+)!~?([^\s]+)\s([^\s]+)\s([^:]+\s)?:?(.*)$`)

--===========================================================================
--
-- A few helper methods
--
--===========================================================================

-- Write a message to our debug log, only if requested
procedure dmsg(sequence msg, object params = {})
	if debug_mode then
		printf(debug_fh, msg & "\n", params)
		flush(debug_fh)
	end if
end procedure

-- Send a message to the server
function send_message(sock:socket s, sequence msg, object data = {})
	dmsg("[SEND]: " & msg, data)
	return sock:send(s, sprintf(msg & "\n", data))
end function

-- Display a message received from the server
procedure display_server_message(sequence msg)
	sequence msgs = stdseq:split(msg, "\n")
	for i = 1 to length(msgs) do
		sequence m = trim(msgs[i])
		if length(m) = 0 then
			continue
		end if

		dmsg("[RCVD]: " & m)

		object matches
		matches = re:matches(re_normal, m)
		if not equal(matches, re:ERROR_NOMATCH) then
			switch matches[4] do
				case "PRIVMSG" then
					if match("ACTION", matches[6]) and length(matches[6]) > 9 then
						printf(1, "%s %s\n", { matches[2], matches[6][9..$-1] })
					else
						printf(1, "<%s> %s\n", { matches[2], matches[6] })
					end if
				case "QUIT" then
					printf(1, "** %s ** has quit\n", { matches[2] })
				case "JOIN" then
					printf(1, "** %s ** has joined %s\n", { matches[2], matches[6] })
				case "PART" then
					printf(1, "** %s ** has left %s\n", { matches[2], matches[6] })
				case "NICK" then
					printf(1, "%s is now known as %s\n", { matches[2], matches[6] })
				case else
					printf(1, "<%s> [%s] %s\n", { matches[2], matches[4], matches[6] })
			end switch

			continue
		end if

		matches = re:matches(re_notice, m)
		if equal(matches, re:ERROR_NOMATCH) then
			matches = re:matches(re_other, m)
		end if

		if not equal(matches, re:ERROR_NOMATCH) then
			printf(1, "NOTICE: %s\n", { matches[3] })
			continue
		end if
	end for
end procedure

--===========================================================================
--
-- Main program body
--
--===========================================================================

-- open a debug log, if requested
if debug_mode then
	debug_fh = open("debug.log", "w")
end if

-- Look up host information
object addrinfo = host_by_name(servername)
if atom(addrinfo) or length(addrinfo) < 3 or length(addrinfo[3]) = 0 then
	puts(1, "Couldn't find DNS entry for irc.freenode.net\n")
	abort(1)
end if

-- Create our socket and connect to the server
soc = sock:create(sock:AF_INET, sock:SOCK_STREAM, 0)
if sock:connect(soc, addrinfo[3][1], port) != sock:OK then
	printf(1, "Couldn't connect to %s:%d\n", { servername, port })
	abort(1)
end if

-- Wait on and retrieve the initial data so we know we actually connected
-- and that the connection is functioning.
object initial = sock:receive(soc, 0)
if sequence(initial) then
	display_server_message(initial)
	-- Send our login information, set our nick and join the channel
	send_message(soc, "USER guest local_eu local_eu :%s", { fullname })
	send_message(soc, "NICK %s", { nickname })
	send_message(soc, "JOIN %s", { channel })
else
	printf(1, "Communication error with %s\n", { servername })
	abort(1)
end if

-- Program loop: 
--   1. Check our get_key, if has keyboard input, get full input and send to server
--   2. Check our server socket, if has information, parse and display
--   3. Goto 1 :-)

while 1 label "top" do
	integer ch = get_key()
	if ch > -1 then
		puts(1, "You Say: " & ch)
		sequence line = trim(ch & gets(0))
		if equal(upper(line), "/QUIT") then
			send_message(soc, "QUIT :doesn't want to talk anymore")
			exit "top"
		end if

		send_message(soc, "PRIVMSG %s :%s", { channel, line })
	end if

	-- Check if info is waiting from the server, wait up to 75ms
	object has_data = sock:select(soc, {}, {}, 0, 75)
	if (length(has_data[1]) > 2) and equal(has_data[1][2],1) then
		object data = sock:receive(soc, 0)
		if atom(data) then
			if data = 0 then
				-- zero bytes received, we the 'data' waiting was
				-- a disconnect.
				exit "top"
			else
				puts(1, "ERROR receiving from IRC server\n")
				abort(1)
			end if
		end if
		if begins("PING ", data) then
			send_message(soc, "PONG %s", { data[6..$] })
		else
			display_server_message(data)
		end if
	end if
end while

sock:close(soc)
