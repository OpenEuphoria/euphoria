--****
-- === net/sock_server.ex
--
-- Very simple socket server. Launch and then execute ##sock_client.ex## to see it in
-- action.
--

object _ = 0
include std/error.e
crash_file("sock_server.err")

include std/socket.e as sock
include std/text.e
include std/console.e

integer logfn = 1
sequence port = "5000"
sequence cmd = command_line()
display( cmd )
if length( cmd ) > 2 then
	port = cmd
	port = port[3]
end if

if length( cmd ) > 3 then
	logfn = open( cmd[4], "w" )
end if

ifdef OSX then
	-- I couldn't bind to 127.0.0.1 under OS X for some reason
	constant addr = "0.0.0.0:"&port
elsedef
	constant addr = "127.0.0.1:"&port
end ifdef

sock:socket server = sock:create(sock:AF_INET, sock:SOCK_STREAM, 0)
if equal( server, -1 ) or sock:bind(server, addr) != sock:OK then
	sequence msg = sprintf( "Could not bind server to %s, error=%d\n", { addr, sock:error_code() })
	if logfn != 1 then
		puts( logfn, msg )
	end if
	crash( msg )
end if

object client

while sock:listen(server, 10) = sock:OK label "MAIN" do
	printf(logfn, "Waiting for connections on %s\n", { addr })
	
	-- what do we do if we want to shut down the server?
	-- do we have to use Ctrl+Break?! Is there no other way?
	
	client = sock:accept(server)
	if sequence(client) then
		puts( logfn, "Connection from " & client[2] & "\n")
		while 1 do
			object got_data = sock:receive(client[1], 0)
			if atom(got_data) then
				-- client disconnected
				continue "MAIN"
			end if

			printf( logfn, "Client sent: %s\n", { trim(got_data) })
			if equal("quit\n", got_data) then
				sock:close(client[1])
				exit "MAIN"
			else
				sock:send(client[1], got_data, 0)
			end if
		end while
	end if
end while

sock:shutdown(server)
puts( logfn, "Server closed\n")
