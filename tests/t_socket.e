include std/unittest.e
include std/console.e
include std/socket.e as sock

object _ = 0

object addrinfo = sock:getaddrinfo("localhost", "http", 0)
if sequence(addrinfo) then
	test_equal("getaddrinfo localhost, http", "127.0.0.1:80", addrinfo[1][5])
else
	test_fail(sprintf("getaddrinfo returned error %d", addrinfo ))
end if

test_equal("getservbyname http", 80, getservbyname("http"))
test_equal("getservbyname ftp", 21, getservbyname("ftp"))
test_equal("getservbyname telnet", 23, getservbyname("telnet"))

test_true("is_inetaddr 1", is_inetaddr("127.0.0.1"))
test_true("is_inetaddr 2", is_inetaddr("127.0.0.1:100"))
test_false("is_inetaddr 3", is_inetaddr("john doe"))
test_false("is_inetaddr 4", is_inetaddr("127.0.0.1:100.5"))

ifdef SOCKET_TESTS then
	--
	-- delay
	--
	atom t = time()
	_ = delay(120)
	test_true("delay 100", time() - t > 0.1)

	--
	-- dns functions
	--

	_ = dnsquery("yahoo.com", NS_T_MX, 0)
	if atom(_) then
		test_fail("dnsquery 1")
	else
		test_true("dnsquery 1", length(_) > 0)
		test_true("dnsquery 2", length(_[1]) = 3)
		test_true("dnsquery 3", sequence(_[1][1]))
		test_true("dnsquery 4", integer(_[1][2]))
		test_true("dnsquery 5", integer(_[1][2]))
	end if

	_ = sock:getmxrr("yahoo.com", 0)
	if atom(_) then
		test_fail("getmxrr yahoo.com")
	else
		test_true("getmxrr yahoo.com", sequence(_) and length(_) > 0)
	end if

	_ = sock:getnsrr("yahoo.com", 0)
	if atom(_) then
		test_fail("getnsrr yahoo.com")
	else
		test_true("getnsrr yahoo.com 1", sequence(_) and length(_) > 0)
		test_true("getnsrr yahoo.com 2", length(_[1]) = 3)
		test_true("getnsrr yahoo.com 3", sequence(_[1][1]))
		test_true("getnsrr yahoo.com 4", integer(_[1][2]))
		test_true("getnsrr yahoo.com 5", integer(_[1][3]))
	end if
	_ = sock:gethostbyname("yahoo.com")
	test_true("gethostbyname yahoo.com", sequence(_))

	_ = getaddrinfo("yahoo.com", "http", 0)
	if atom(_) or length(_) = 0 then
		test_fail("getaddrinfo yahoo.com")
	else
		test_true("getaddrinfo yahoo.com 1", integer(_[1][ADDR_FLAGS]))
		test_true("getaddrinfo yahoo.com 2", integer(_[1][ADDR_FAMILY]))
		test_true("getaddrinfo yahoo.com 3", integer(_[1][ADDR_TYPE]))
		test_true("getaddrinfo yahoo.com 4", integer(_[1][ADDR_PROTOCOL]))
		test_true("getaddrinfo yahoo.com 5", sequence(_[1][ADDR_ADDRESS]))
	end if

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

	atom socket = new_socket(AF_INET, SOCK_STREAM, 0)
	for i = 1 to 4 do
		_ = connect(socket, "127.0.0.1:5000") 
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

	test_equal("close", 0, close_socket(socket))
elsedef
    puts(2, "Warning: all socket tests were not run, use -D SOCKET_TESTS for full test\n")
end ifdef

test_report()
