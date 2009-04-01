include std/unittest.e
include std/console.e
include std/socket.e as sock

object _ = 0

test_equal("getservbyname http", { "http", "tcp", 80 }, getservbyname("http", "tcp"))
test_equal("getservbyname ftp", { "ftp", "tcp", 21 }, getservbyname("ftp", "tcp"))
test_equal("getservbyname telnet", { "telnet", "tcp", 23}, getservbyname("telnet", "tcp"))

test_true( "is_inetaddr #1", is_inetaddr("127.0.0.1"))
test_true( "is_inetaddr #2", is_inetaddr("0.0.0.0"))
test_true( "is_inetaddr #3", is_inetaddr("127.0.0.1:100"))
test_true( "is_inetaddr #3", is_inetaddr("155.212.244.8"))
test_false("is_inetaddr #4", is_inetaddr("john doe"))
test_false("is_inetaddr #5", is_inetaddr("127.0.0.1:100.5"))
test_false("is_inetaddr #6", is_inetaddr("327.0.0.1"))
test_false("is_inetaddr #7", is_inetaddr("1.256.0.1"))
test_false("is_inetaddr #8", is_inetaddr("1.-18.0.1"))

atom socket = new_socket(AF_INET, SOCK_STREAM, 0)
test_equal("get_socket_option #1", 0, get_socket_options(socket, SOL_SOCKET, SO_DEBUG))
test_equal("set_socket_option #1", 1, set_socket_options(socket, SOL_SOCKET, SO_DEBUG, 1))
test_equal("get_socket_option #2", 1, get_socket_options(socket, SOL_SOCKET, SO_DEBUG))

ifdef SOCKET_TESTS then
	--
	-- testing both client and server in this case as the sever
	-- is written in euphoria as well
	--
	-- new_socket, bind, listen, accept, send, recv, close_socket,
	-- connect are all tested with the below test
	--

	puts(1, "========== ATTENTION ==========\n")
	puts(1, "Please open a new shell and execute demo\\sock_server.ex\n")
	any_key("Press any key when you are ready")
	puts(1, "===============================\n")

	for i = 1 to 4 do
		_ = connect(AF_INET, socket, "127.0.0.1:5000") 
		if _ != -1 then
			exit
		end if
		if i = 4 then
			test_fail("connect to server")
		else
			if i = 1 then
				puts(1, "waiting for server to start .. ")
			else
				puts(1, " .. ")
			end if
			
		end if
	end for
	
	if _ != -1 then
		sequence send_data = "Hello, "
		test_equal("send w/o newline", length(send_data), send(socket, send_data, 0))
		test_equal("recv w/o newline", send_data, recv(socket, 0))
		
		send_data = "world\n"
		test_equal("send with newline", length(send_data), send(socket, send_data, 0))
		test_equal("recv with newline", send_data, recv(socket, 0))
		
		send_data = repeat('a', 511) & "\n"
		test_equal("send large", length(send_data), send(socket, send_data, 0))
		test_equal("recv large", send_data, recv(socket, 0))
		
		_ = send(socket, "quit\n", 0)
	end if
end ifdef

test_equal("close", 1, close_socket(socket))

ifdef not SOCKET_TESTS then
    puts(2, " WARNING: all socket tests were not run, use -D SOCKET_TESTS for full test\n")
end ifdef

test_report()
