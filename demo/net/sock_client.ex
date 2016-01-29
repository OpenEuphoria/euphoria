--****
-- === net/sock_client.ex
-- 
-- Simple example of how to connect to a socket. Be sure to launch ##sock_server.ex##
-- first.
--

object _ = 0
without warning

include std/console.e
include std/socket.e as sock

--**
-- @nodoc@
override procedure abort(integer x)
	maybe_any_key()
	eu:abort(x)
end procedure
sock:socket sock = sock:create(sock:AF_INET, sock:SOCK_STREAM, 0)

if sock:connect(sock, "127.0.0.1:5000") != sock:OK then
	printf(1, "Could not connect to server, is it running?\nError = %d\n", 
		{ sock:error_code() })
	abort(1)
end if

while 1 do
	sequence data = prompt_string("What do you want to say to the server or quit? ")

	sock:send(sock, data & "\n", 0)

	if equal(data, "quit") then
		exit
	else
		printf(1, "The server says: %s", { sock:receive(sock, 0) })
	end if
	
end while

sock:close(sock)

