object _ = 0

include std/socket.e as sock
include std/text.e

object clients = {}, nicks = {}

procedure send_to_all(sequence message, integer skip=0)
	for i = 1 to length(clients) do
		if i = skip then continue end if
		_ = sock:send(clients[i], trim_tail(message) & "\n")
	end for
end procedure

procedure remove_client(integer sock)
	for i = 1 to length(clients) do
		if sock = clients[i] then
			sequence nick = nicks[i]
			printf(1, "Client %d (%d of %d) disconnected\n", { sock, i, length(clients) })
			clients = remove(clients, i)
			nicks = remove(nicks, i)

			send_to_all(sprintf("%10s = left", { nick }))

			exit
		end if
	end for
end procedure

procedure main(sequence args)
	sequence addr = "0.0.0.0:5000"
	if length(args) > 2 then
		addr = args[3]
	end if

	sequence remove_sockets = {}
	atom server = sock:new_socket(sock:AF_INET, sock:SOCK_STREAM, 0),
		result = sock:bind(server, sock:AF_INET, addr)

	if result != 0 then
		printf(1, "Could not bind server to %s, error=%d\n", { addr, result })
		abort(1)
	end if


	printf(1, "Waiting for connections on %s\n", { addr })
	while sock:listen(server, 0) = 0 label "MAIN" do

		-- get socket states
		object sock_data = sock:select(server & clients, -1)

		-- check for new incoming connects on server socket
		if sock_data[1][SELECT_IS_READABLE] = 1 then
			object client = sock:accept(server)
			printf(1, "Connection from " & client[2] & ", socket = %d\n", { client[1] })

			-- Client sends their name, get it and send a join message
			object got_data = sock:recv(client[1], 0)
			if atom(got_data) then
				-- client disconnected already!? Ignore them then
			else
				got_data = trim(got_data)
				clients &= client[1]
				nicks &= { got_data }
				_ = sock:send(client[1], "Welcome to the Euphoria Chat Server Demo, " &
					trim(got_data) & "\n", 0)

				send_to_all(sprintf("%10s = joined", { got_data }))
			end if
		end if

		-- check for any activity on the client sockets
		for i = 2 to length(sock_data) do
			if sock_data[i][SELECT_IS_READABLE] then
				object got_data = sock:recv(sock_data[i][SELECT_SOCKET], 0)
				if atom(got_data) then
					remove_client(sock_data[i][SELECT_SOCKET])
					continue
				end if

				printf(1, "Client %d (%d of %d) sent %s\n", {
					sock_data[i][SELECT_SOCKET], i - 1, length(clients), trim(got_data)
				})

				-- Send the message out to everyone
				send_to_all(got_data, i-1)
			elsif sock_data[i][SELECT_IS_ERROR] then
				printf(1, "Client %d (%d of %d) is in an error state, disconnecting\n", {
					sock_data[i][SELECT_SOCKET], i - 1, length(clients)
				})
				remove_sockets &= sock_data[i][SELECT_SOCKET]
			end if
		end for

		for i = 1 to length(remove_sockets) do
			remove_client(remove_sockets[i])
		end for

		remove_sockets = {}
	end while

	_ = sock:shutdown_socket(server)
	puts(1, "Server closed\n")
end procedure

main(command_line())
