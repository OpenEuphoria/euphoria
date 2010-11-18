object _ = 0

include std/socket.e as sock
include std/text.e
include std/console.e

sequence port = "5000"
if length(command_line()) > 2 then
	port = command_line()
	port = port[3]
end if

ifdef OSX then
	-- I couldn't bind to 127.0.0.1 under OS X for some reason
	constant addr = "0.0.0.0:"&port
elsedef
	constant addr = "127.0.0.1:"&port
end ifdef

sock:socket server = sock:create(sock:AF_INET, sock:SOCK_STREAM, 0)
if sock:bind(server, addr) != sock:OK then
	printf(1, "Could not bind server to %s, error=%d\n", { addr, sock:error_code() })
	abort(1)
end if

object client

while sock:listen(server, 10) = sock:OK label "MAIN" do
	printf(1, "Waiting for connections on %s\n", { addr })
	
	-- what do we do if we want to shut down the server?
	-- do we have to use Ctrl+Break?! Is there no other way?
	
	client = sock:accept(server)
	if sequence(client) then
		puts(1, "Connection from " & client[2] & "\n")
		while 1 do
			object got_data = sock:receive(client[1], 0)
			if atom(got_data) then
				-- client disconnected
				continue "MAIN"
			end if

			printf(1, "Client sent: %s\n", { trim(got_data) })
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
puts(1, "Server closed\n")
