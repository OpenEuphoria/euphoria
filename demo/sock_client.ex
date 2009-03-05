global object _ = 0

include std/console.e
include std/socket.e as sock

atom socket = sock:new_socket(sock:AF_INET, sock:SOCK_STREAM, 0)
if sock:connect(socket, "127.0.0.1:5000") = -1 then
	puts(1, "Could not connect to server, is it running?\n")
	abort(1)
end if

sequence data = prompt_string("What do you want to say to the server? ")
_ = send(socket, data & "\r\n", 0)
puts(1, "The server says: " & recv(socket, 0))

_ = sock:close_socket(socket)