include std/socket.e as sock

sock:socket server = sock:create(sock:AF_INET, sock:SOCK_DGRAM, 0)
integer result = sock:bind(server, "0.0.0.0:27015")

puts(1, "Waiting for a client connection on port 27015\n")
object o = sock:receive_from(server)
if sequence(o) then
    printf(1, "From: %s:%d, '%s'\n", o)
else
	printf(1, "Error code: %d\n", { o })
end if

sock:close(server)
