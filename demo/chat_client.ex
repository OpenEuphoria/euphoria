object _ = 0

include std/console.e
include std/text.e
include std/socket.e as slib

puts(1, #/
____1. You must first enter your nick name.
	2. When you want to say something, press the "s" key for speak.
	3. When you want to leave, press the "l" key for leave.
/)

object name = trim(prompt_string("Enter your nickname please: "))

slib:socket sock = slib:create(slib:AF_INET, slib:SOCK_STREAM, 0)

sequence addr = "127.0.0.1:5000",
	args = command_line()

if length(args) > 2 then
	addr = args[3]
end if

printf(1, "Connecting to %s\n", { addr })

integer result = slib:connect(sock, "127.0.0.1:5000")
if not result then
	printf(1, "Could not connect to server %s, is it running?\nError = %d\n", { addr, result })
	puts(1, "Maybe try connecting to a different IP/Port?\n")
	puts(1, "   Usage: exwc chat_client.ex [IP:PORT]\n")
	abort(1)
end if

-- Send our nickname to the server
_ = slib:send(sock, name & "\n", 0)

-- Print the server greeting message
puts(1, recv(sock, 0))

while 1 label "top" do
	integer key = get_key()
	switch key do
		case -1 then
			break

		case 's' then
			sequence data = prompt_string(sprintf("%10s > ", { name }))
			if length(data) > 0 then
				_ = send(sock, sprintf("%10s > %s\n", { name, data }), 0)
			end if
			break

		case 'l' then
			exit "top"
	end switch

	object sock_data = slib:select(sock, 0)
	if sock_data[1][SELECT_IS_ERROR] then
		puts(1, "We've lost the server, exiting\n")
		exit "top"

	elsif sock_data[1][SELECT_IS_READABLE] then
		puts(1, recv(sock, 0))
	end if
end while

_ = slib:close(sock)
