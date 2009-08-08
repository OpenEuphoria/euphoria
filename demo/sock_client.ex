object _ = 0

include std/console.e
include std/socket.e as sock

sock:socket sock = sock:create(sock:AF_INET, sock:SOCK_STREAM, 0)
integer result = sock:connect(sock, "127.0.0.1:5000")

if not result then
	printf(1, "Could not connect to server, is it running?\nError = %d\n", { result })
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

