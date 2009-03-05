
include std/unittest.e
include std/socket.e as sock
include std/console.e

object _ = 0

-- TODO: Test HTTP stuff

test_equal("urlencode 1", "Hello%20%26%20World", urlencode("Hello & World"))

sequence addrinfo = sock:getaddrinfo("localhost", "http", 0)
test_equal("getaddrinfo localhost, http", "127.0.0.1:80", addrinfo[1][5])

test_true("is_inetaddr 1", is_inetaddr("127.0.0.1"))
test_true("is_inetaddr 2", is_inetaddr("127.0.0.1:100"))
test_false("is_inetaddr 3", is_inetaddr("john doe"))
test_false("is_inetaddr 4", is_inetaddr("127.0.0.1:100.5"))

sequence ifaces = get_iface_list()
test_true("get_iface_list", length(ifaces) > 0)

-- TODO: Jeremy could not retrieve details on the #1 interface on
-- his computer. His interface name was "TAP-Win32 Adapter V9". Is
-- this a problem or do some interfaces not have detailed information?
sequence iface = get_iface_details(ifaces[$])
test_equal("get_iface_details 1", 15, length(iface))
test_equal("get_iface_details 2", ifaces[$], iface[1])

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
	if connect(socket, "127.0.0.1:5000") = -1 then
		test_fail("connect to server")
	else
		test_equal("send", 7, send(socket, "hello\r\n", 0))
		test_equal("recv", "hello\r\n", recv(socket, 0))
	end if

	test_equal("close", 0, close_socket(socket))
end ifdef

test_report()
