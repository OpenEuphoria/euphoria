include std/socket.e as sock

sock:socket server = sock:create(sock:AF_INET, sock:SOCK_DGRAM, 0)
if sock:bind(server, "0.0.0.0:27015") != sock:OK then
	printf(1, "Binding to 0.0.0.0:27015 has failed, errno: %s\n", { 
		sock:error_code() })
	abort(1)
end if

puts(1, "Waiting for a client connection on port 27015\n")
object o = sock:receive_from(server)
if sequence(o) then
    printf(1, "From: %s:%d, '%s'\n", o)
else
	printf(1, "Error code: %d\n", { o })
end if

sock:close(server)
