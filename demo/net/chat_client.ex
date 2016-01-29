--****
-- === net/chat_client.ex
--
-- socket example that connects to the multi-user chat_server.ex application.
--

object _ = 0

include std/console.e
include std/text.e
include std/socket.e as slib
without warning

--**
-- @nodoc@
override procedure abort(integer x)
	maybe_any_key()
	eu:abort(x)
end procedure


procedure lost_server()
	puts(1, "We have been disconnected from the server,\n")
	puts(1, "Application is terminating.\n")
	abort(1)
end procedure

function get_nick()
	puts(1, `
________1. You must first enter your nick name.
	    2. When you want to say something, press the "s" key for speak.
	    3. When you want to leave, press the "l" key for leave.

        `)
	return trim(prompt_string("Enter your nickname please: "))
end function

procedure main(sequence args)
	slib:socket sock = slib:create(slib:AF_INET, slib:SOCK_STREAM, 0)
	sequence addr = "127.0.0.1:5000"

	if length(args) > 2 then
		addr = args[3]
	end if

	printf(1, "Connecting to %s\n", { addr })

	if slib:connect(sock, "127.0.0.1:5000") != slib:OK then
		printf(1, "Could not connect to server %s, is it running?\nError = %d\n", { addr, slib:error_code() })
		puts(1, "Maybe try connecting to a different IP/Port?\n")
		puts(1, "   Usage: eui chat_client.ex [IP:PORT]\n")
		abort(1)
	end if

	sequence name = get_nick()
	_ = slib:send(sock, name & "\n", 0)

	-- Print the server greeting message
	puts(1, receive(sock, 0))

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

			case 'l' then
				exit "top"
		end switch

		object sock_data = slib:select(sock, {}, {})
		if sock_data[1][SELECT_IS_ERROR] then
			lost_server()

		elsif sock_data[1][SELECT_IS_READABLE] then
			object o = receive(sock, 0)
			if atom(o) then
				lost_server()
			end if

			puts(1, o)
		end if
	end while

	_ = slib:close(sock)
end procedure

main(command_line())
