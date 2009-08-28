include std/socket.e as sock

sock:socket client = sock:create(sock:AF_INET, sock:SOCK_DGRAM, 0)
sock:set_option(client, sock:SOL_SOCKET, SO_BROADCAST, 1)

integer result = sock:send_to(client, "Hello World!", "127.0.0.1:27015")
if result > 0 then
    printf(1, "Sent %d bytes\n", { result })
else
	printf(1, "Error code: %d\n", { result })
end if

sock:close(client)
