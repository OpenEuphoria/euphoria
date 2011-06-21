include std/unittest.e
include std/console.e
include std/os.e
include std/socket.e as sock
include std/pipeio.e as pipe
include std/filesys.e as fs
include std/cmdline.e
ifdef WINDOWS then
	constant MAYBE_MSG_NOSIGNAL = 0
elsedef
	constant MAYBE_MSG_NOSIGNAL = MSG_NOSIGNAL
end ifdef
	
object _ = 0

test_equal("service_by_name echo", { "echo", "tcp", 7 }, service_by_name("echo", "tcp"))
test_equal("service_by_name ftp", { "ftp", "tcp", 21 }, service_by_name("ftp", "tcp"))
test_equal("service_by_name telnet", { "telnet", "tcp", 23}, service_by_name("telnet", "tcp"))
test_equal("service_by_port echo", { "echo", "tcp", 7 }, service_by_port(7, "tcp"))
test_equal("service_by_port ftp", { "ftp", "tcp", 21 }, service_by_port(21, "tcp"))
test_equal("service_by_port telnet", { "telnet", "tcp", 23}, service_by_port(23, "tcp"))

sock:socket socket = sock:create(AF_INET, SOCK_STREAM, 0)
-- Windows supports SO_DEBUG, but on Unix variants it is only supported when running as the
-- root user.
ifdef WINDOWS then
	test_equal("get_option #1", 0, get_option(socket, SOL_SOCKET, SO_DEBUG))
	test_equal("set_option #1", 1, set_option(socket, SOL_SOCKET, SO_DEBUG, 1))
	test_equal("get_option #2", 1, get_option(socket, SOL_SOCKET, SO_DEBUG))
end ifdef
-- these constants are converted in the backend should work in WINDOWS and all UNIX flavors.
test_equal("get_option #1", SOCK_STREAM, get_option(socket, SOL_SOCKET, SO_TYPE))
test_equal("get_option #2", 0, get_option(socket, SOL_SOCKET+5/5-1, SO_REUSEADDR))
test_equal("set_option #1", 1, set_option(socket, SOL_SOCKET, SO_REUSEADDR, 1))
test_equal("get_option #3", 1, get_option(socket, SOL_SOCKET+0.0, SO_REUSEADDR))
test_equal("get_option #4", 0, get_option(socket, SOL_SOCKET+0.0, SO_KEEPALIVE))
test_equal("set_option #2", 1, set_option(socket, SOL_SOCKET, SO_KEEPALIVE*3.1/3.1, 1))
test_equal("get_option #5", 1, get_option(socket, SOL_SOCKET, SO_KEEPALIVE*3.1/3.1))

--
-- testing both client and server in this case as the sever
-- is written in euphoria as well
--
-- new_socket, bind, listen, accept, send, receive, close_socket,
-- connect are all tested with the below test
--
sequence list = command_line()
sequence interpreter
ifdef EUC or EUB then
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

sequence port = sprintf("%d", rand(999) + 5000)
object p = pipe:exec(interpreter & " " & build_commandline( option_switches() ) & 
	" ../demo/net/sock_server.ex " & port, pipe:create())
if atom(p) then
	test_fail("could not launch temporary server")
else
	-- Give the server a second to actually launch
	sleep(1)
	integer maxwait = 10
	for i = 1 to maxwait do
		_ = sock:connect(socket, "127.0.0.1:"&port)
		if _ = 0 then
			exit
		end if
		if i = maxwait then
			test_fail("connect to server")
		else
			if i = 1 then
				puts(1, "waiting for server to start .. ")
			else
				puts(1, " .. ")
			end if
		end if
	end for
	
	if _ = 0 then
		sequence send_data = "Hello, "
		test_equal("send w/o newline", length(send_data), sock:send(socket, send_data, MAYBE_MSG_NOSIGNAL))
		test_equal("receive w/o newline", send_data, sock:receive(socket, MAYBE_MSG_NOSIGNAL))
		
		send_data = "world\n"
		test_equal("send with newline", length(send_data), sock:send(socket, send_data, MAYBE_MSG_NOSIGNAL))
		test_equal("receive with newline", send_data, sock:receive(socket, MAYBE_MSG_NOSIGNAL))
		
		send_data = repeat('a', 511) & "\n"
		test_equal("send large", length(send_data), sock:send(socket, send_data, MAYBE_MSG_NOSIGNAL))
		test_equal("receive large", send_data, sock:receive(socket, MAYBE_MSG_NOSIGNAL))
		
		_ = send(socket, "quit\n", MAYBE_MSG_NOSIGNAL)
	end if

	pipe:kill(p)
end if

test_equal("close", sock:OK, sock:close(socket))

procedure ticket680()
	test_false("atom not a valid socket", sock:socket( 0 ) )
	test_false("empty sequence not a valid socket", sock:socket( {} ) )
	test_false("one element sequence not a valid socket", sock:socket( {0} ) )
	test_false("three element sequence not a valid socket", sock:socket( {0,0,0} ) )
	test_false("first element sequence not a valid socket", sock:socket( {"", 0}) )
	test_false("second element sequence not a valid socket", sock:socket( {0, ""}) )
	test_true("two elements, both atoms, valid socket", sock:socket( {0,0} ) )
end procedure
ticket680()

test_report()
