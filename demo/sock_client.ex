global object _ = 0

include std/socket.e as sock

atom socket = sock:new_socket(sock:AF_INET, sock:SOCK_STREAM, 0)
if sock:connect(socket, "127.0.0.1:5000") = -1 then
	puts(1, "Could not connect to server, is it running?\n")
	abort(1)
end if

puts(1, recv(socket, 0))

_ = sock:close_socket(socket)