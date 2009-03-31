object _ = 0

include std/socket.e as sock
include std/text.e

ifdef OSX then
	-- I couldn't bind to 127.0.0.1 under OS X for some reason
	constant addr = "0.0.0.0:5000"
elsedef
	constant addr = "127.0.0.1:5000"
end ifdef

atom server = sock:new_socket(sock:AF_INET, sock:SOCK_STREAM, 0),
	result = sock:bind(server, sock:AF_INET, addr)

if result != 0 then
	printf(1, "Could not bind server to %s, error=%d\n", { addr, result })
	abort(1)
end if

object client

while sock:listen(server, 10) = 0 label "MAIN" do
	printf(1, "Waiting for connections on %s\n", { addr })
	client = sock:accept(server)
	if sequence(client) then
		puts(1, "Connection from " & client[2] & "\n")
		while 1 do
			object got_data = sock:recv(client[1], 0)
			if atom(got_data) then
				-- client disconnected
				continue "MAIN"
			end if

			printf(1, "Client sent: %s\n", { trim(got_data) })
			_ = sock:send(client[1], got_data, 0)
			if match("quit\n", got_data) then
				_ = sock:close_socket(client[1])
				exit "MAIN"
			end if
		end while
	end if
end while

_ = sock:shutdown_socket(server)
puts(1, "Server closed\n")

