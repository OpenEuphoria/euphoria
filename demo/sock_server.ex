global object _ = 0

include std/socket.e as sock

atom socket = sock:new_socket(sock:AF_INET, sock:SOCK_STREAM, 0),
	result = sock:bind(socket, "127.0.0.1:5000")

puts(1, "Waiting for connections on 127.0.0.1:5000\n")
object client

while sock:listen(socket, 10) = 0 label "MAIN" do
	client = sock:accept(socket)
	if sequence(client) then
		puts(1, "Connection from " & client[2] & "\n")
		while 1 do 
			sequence got_data = sock:recv(client[1], 0)
			puts(1, got_data)
			_ = sock:send(client[1], got_data, 0)
			if equal(got_data, "quit\n") then
				exit "MAIN"
			end if
		end while
	end if
end while
_ = sock:close_socket(client[1])
puts(1, "Server closed\n")

