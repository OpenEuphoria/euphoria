include std/unittest.e
include std/console.e
include std/os.e
include std/socket.e as sock
include std/pipeio.e as pipe
include std/filesys.e as fs
object _ = 0

test_equal("service_by_name echo", { "echo", "tcp", 7 }, service_by_name("echo", "tcp"))
test_equal("service_by_name ftp", { "ftp", "tcp", 21 }, service_by_name("ftp", "tcp"))
test_equal("service_by_name telnet", { "telnet", "tcp", 23}, service_by_name("telnet", "tcp"))
test_equal("service_by_port echo", { "echo", "tcp", 7 }, service_by_port(7, "tcp"))
test_equal("service_by_port ftp", { "ftp", "tcp", 21 }, service_by_port(21, "tcp"))
test_equal("service_by_port telnet", { "telnet", "tcp", 23}, service_by_port(23, "tcp"))

sock:socket socket = sock:create(AF_INET, SOCK_STREAM, 0)
test_equal("get_option #1", 0, get_option(socket, SOL_SOCKET, SO_DEBUG))
test_equal("set_option #1", 1, set_option(socket, SOL_SOCKET, SO_DEBUG, 1))
test_equal("get_option #2", 1, get_option(socket, SOL_SOCKET, SO_DEBUG))

--
-- testing both client and server in this case as the sever
-- is written in euphoria as well
--
-- new_socket, bind, listen, accept, send, receive, close_socket,
-- connect are all tested with the below test
--
sequence list = command_line()
sequence interpreter
ifdef EC then
	-- The tests test are here to test interpreters and libraries as we do not know where the
	-- interpreter is we just quit.
	test_report()
	abort(0)
elsedef
	if compare(list[1],list[2]) != 0 then
		-- okay, let's trust the EC variable.
		interpreter = list[1]
	else
		-- It's most likely the EC variable was not defined when translating
		-- yet this is a translated application.
		interpreter = "eui"
	end if
end ifdef

object p = pipe:exec(interpreter & " ../demo/sock_server.ex", pipe:create())
if atom(p) then
	test_fail("could not launch temporary server")
else
	-- Give the sever a second to actually launch
	sleep(1)

	for i = 1 to 4 do
		_ = sock:connect(socket, "127.0.0.1:5000")
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
		test_equal("send w/o newline", length(send_data), sock:send(socket, send_data, 0))
		test_equal("receive w/o newline", send_data, sock:receive(socket, 0))
		
		send_data = "world\n"
		test_equal("send with newline", length(send_data), sock:send(socket, send_data, 0))
		test_equal("receive with newline", send_data, sock:receive(socket, 0))
		
		send_data = repeat('a', 511) & "\n"
		test_equal("send large", length(send_data), sock:send(socket, send_data, 0))
		test_equal("receive large", send_data, sock:receive(socket, 0))
		
		_ = send(socket, "quit\n", 0)
	end if

	pipe:kill(p)
end if

test_equal("close", 1, sock:close(socket))

test_report()
