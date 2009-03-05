
include std/unittest.e
include std/socket.e as sock
include std/console.e

object _ = 0

-- TODO: add more tests. This at least checks to make sure socket.e is
-- compiling and at least partly functions.

sequence addrinfo = sock:getaddrinfo("localhost", "http", 0)
test_equal("getaddrinfo localhost, http", "127.0.0.1:80", addrinfo[1][5])

object dns = sock:getmxrr("yahoo.com",0)
test_true("getmxrr yahoo.com", sequence(dns) and length(dns) > 0)

ifdef SOCKET_TESTS then
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
