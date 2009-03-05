global object _ = 0

include std/socket.e as sock

constant senddata = "This is a message."

atom socket = sock:new_socket(sock:AF_INET, sock:SOCK_STREAM, 0),
	result = sock:bind(socket, "127.0.0.1:5000")

puts(1, "Waiting for connections on 127.0.0.1:5000\n")
while sock:listen(socket, 10) = 0 do
	object client = sock:accept(socket)
	if sequence(client) then
		puts(1, "Connection from " & client[2] & "\n")
		_ = sock:send(client[1], "Hello " & client[2] & "\r\n", 0)
		_ = sock:close_socket(client[1])
	end if
end while
