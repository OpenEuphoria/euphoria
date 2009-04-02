--****
-- == Sockets
--
-- <<LEVELTOC depth=2>>
 
ifdef DOS32 then
	include std/error.e
	crash("socket.e is not supported on the DOS platform")
end ifdef

include std/get.e
include std/regex.e as re
include std/sequence.e as seq

enum M_SOCK_GETSERVBYNAME=77, M_SOCK_GETSERVBYPORT, M_SOCK_SOCKET=81, M_SOCK_CLOSE, M_SOCK_SHUTDOWN,
	M_SOCK_CONNECT, M_SOCK_SEND, M_SOCK_RECV, M_SOCK_BIND, M_SOCK_LISTEN,
	M_SOCK_ACCEPT, M_SOCK_SETSOCKOPT, M_SOCK_GETSOCKOPT, M_SOCK_SELECT

--****
-- === Constants
--

--**
-- Socket types

ifdef WIN32 then
	public constant
		AF_UNSPEC=0, AF_UNIX=-1, AF_INET=2, AF_APPLETALK=17, AF_INET6=23, AF_BTH=32,
		SOCK_STREAM=1, SOCK_DGRAM=2, SOCK_RAW=3, SOCK_RDM=4, SOCK_SEQPACKET=5

elsifdef LINUX then
	public constant
		AF_UNSPEC=0, AF_UNIX=1, AF_INET=2, AF_APPLETALK=5, AF_INET6=10,
		SOCK_STREAM=1, SOCK_DGRAM=2, SOCK_RAW=3, SOCK_RDM=4, SOCK_SEQPACKET=5

elsifdef SUNOS then
	public constant
		AF_UNSPEC=0, AF_UNIX=1, AF_INET=2, AF_APPLETALK=16, AF_INET6=26,
		SOCK_STREAM=2, SOCK_DGRAM=1, SOCK_RAW=4, SOCK_RDM=5, SOCK_SEQPACKET=6

elsifdef OSX then
	public constant
		AF_UNSPEC=0, AF_UNIX=1, AF_INET=2, AF_APPLETALK=16, AF_INET6=30,
		SOCK_STREAM=1, SOCK_DGRAM=2, SOCK_RAW=3, SOCK_RDM=4, SOCK_SEQPACKET=5

elsifdef FREEBSD then
	public constant
		AF_UNSPEC=0, AF_UNIX=1, AF_INET=2, AF_APPLETALK=16, AF_INET6=28,
		SOCK_STREAM=1, SOCK_DGRAM=2, SOCK_RAW=3, SOCK_RDM=4, SOCK_SEQPACKET=5
end ifdef

--****
-- === Select Accessor Constants
--
-- Use with the result of [[:select]].
--

public enum
	--** The socket
	SELECT_SOCKET,
	--** Boolean value indicating the readability.
	SELECT_IS_READABLE,
	--** Boolean value indicating the writability.
	SELECT_IS_WRITABLE,
	--** Boolean value indicating the error state.
	SELECT_IS_ERROR

--****
-- === Shutdown Options
--
-- Pass one of the following to the ##method## parameter of [[:shutdown]].
--

public constant
	--** Shutdown the send operations.
	SD_SEND    = 0,
	--** Shutdown the receive operations.
	SD_RECEIVE = 1,
	--** Shutdown both send and receive operations.
	SD_BOTH    = 2

--****
-- === Socket Options
--
-- Pass to the ##optname## parameter of the functions [[:get_socket_options]]
-- and [[:set_socket_options]].

public constant
	SOL_SOCKET     = #FFFF,
	SO_DEBUG       = #0001,
	SO_ACCEPTCONN  = #0002,
	SO_REUSEADDR   = #0004,
	SO_KEEPALIVE   = #0008,
	SO_DONTROUTE   = #0010,
	SO_BROADCAST   = #0020,
	SO_USELOOPBACK = #0040,
	SO_LINGER      = #0080,
	SO_DONTLINGER  = not_bits(SO_LINGER),
	SO_OOBINLINE   = #0100,
	SO_REUSEPORT   = #9999, -- TODO: Undefined for Windows, what is it elsewhere?
	SO_SNDBUF      = #1001,
	SO_RCVBUF      = #1002,
	SO_SNDLOWAT    = #1003,
	SO_RCVLOWAT    = #1004,
	SO_SNDTIMEO    = #1005,
	SO_RCVTIMEO    = #1006,
	SO_ERROR       = #1007,
	SO_TYPE        = #1008,
	SO_CONNDATA    = #7000,
	SO_CONNOPT     = #7001,
	SO_DISCDATA    = #7002,
	SO_DISCOPT     = #7003,
	SO_CONNDATALEN = #7004,
	SO_CONNOPTLEN  = #7005,
	SO_DISCDATALEN = #7006,
	SO_DISCOPTLEN  = #7007,
	SO_OPENTYPE    = #7008,
	SO_MAXDG       = #7009,
	SO_MAXPATHDG   = #700A,
	SO_SYNCHRONOUS_ALTERT   = #10,
	SO_SYNCHRONOUS_NONALERT = #20

--****
-- === Send Flags
--
-- Pass to the ##flags## parameter of [[:send]] and [[:recv]]
--

public constant
	MSG_OOB       = #1,
	MSG_PEEK      = #2,
	MSG_DONTROUTE = #4,
	MSG_TRYHARD   = #4,
	MSG_CTRUNC    = #8,
	MSG_PROXY     = #10,
	MSG_TRUNC     = #20,
	MSG_DONTWAIT  = #40,
	MSG_EOR       = #80,
	MSG_WAITALL   = #100,
	MSG_FIN       = #200,
	MSG_SYN       = #400,
	MSG_CONFIRM   = #800,
	MSG_RST       = #1000,
	MSG_ERRQUEUE  = #2000,
	MSG_NOSIGNAL  = #4000,
	MSG_MORE      = #8000

--****
-- === Other Constants

public constant
	FD_READ    = 1,
	FD_WRITE   = 2,
	FD_OOB     = 4,
	FD_ACCEPT  = 8,
	FD_CONNECT = 16,
	FD_CLOSE   = 32

constant DEFAULT_PORT = 80
		
--****
-- === Support routines
--

constant ip_re = re:new(#/^(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])(\:[0-9]+)?$/)

--**
-- Checks if x is an IP address in the form (#.#.#.#[:#])
--
-- Parameters:
--   # ##address##: the address to check
--
-- Returns:
--   An **integer**, 1 if x is an inetaddr, 0 if it is not
--
-- Comments:
--   Some ip validation algorithms do not allow 0.0.0.0. We do here because
--   many times you will want to bind to 0.0.0.0. However, you cannot connect
--   to 0.0.0.0 of course.
--
--   With sockets, normally binding to 0.0.0.0 means bind to all interfaces
--   that the computer has.
--

public function is_inetaddr(object address)
	return re:is_match(ip_re, address)
end function

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Routines for both server & client (socket, read, write, select)
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

--****
-- === Server and Client sides
--

--**
-- Socket type
--

public type socket(object o)
	if not sequence(o) then return 0 end if
	if not length(o) = 2 then return 0 end if
	if not atom(o[1]) then return 0 end if
	if not atom(o[2]) then return 0 end if

	return 1
end type

-- Not made public as the end user should have no need of accessing one value
-- or the other.
enum
	--** Accessor index for socket handle of a socket type
	SOCKET_SOCKET,
	--** Accessor index for the sockaddr_in pointer of a socket type
	SOCKET_SOCKADDR_IN

--**
-- Create a new socket
--
-- Parameters:
--   # ##family##: an integer
--   # ##sock_type##: an integer, the type of socket to create
--   # ##protocol##: an integer, the communication protocol being used
--
-- Returns:
--   An **atom**, -1 on failure, else a supposedly valid socket id.
--
-- Example 1:
-- <eucode>
-- socket = create(AF_INET, SOCK_STREAM, 0)
-- </eucode>

public function create(integer family, integer sock_type, integer protocol)
	return machine_func(M_SOCK_SOCKET, { family, sock_type, protocol })
end function

--**
-- Closes a socket.
--
-- Parameters:
--   # ##sock##: the socket to close
--
-- Returns:
--   An **integer**, 0 on success and -1 on error. 
--
-- Comments:
--   It may take several minutes for the OS to declare the socket as closed.
-- 

public function close(socket sock)
	return machine_func(M_SOCK_CLOSE, { sock })
end function

--**
-- Partially or fully close a socket. 
--
-- Parameters:
--   # ##sock##: the socket to shutdown
--   # ##method##: the method used to close the socket
--
-- Returns:
--   An **integer**, 0 on success and -1 on error.
--
-- Comments:
--   Three constants are defined that can be sent to ##method##:
--   * [[:SD_SEND]] - shutdown the send operations.
--   * [[:SD_RECEIVE]] - shutodnw the receive operations.
--   * [[:SD_BOTH]] - shutdown both send and receive operations.
--
--  It may take several minutes for the OS to declare the socket as closed.
--

public function shutdown_socket(socket sock, atom method=SD_BOTH)
	return machine_func(M_SOCK_SHUTDOWN, { sock, method })
end function

--**
-- Determine the read, write and error status of one or more sockets.
--
-- Using select, you can check to see if a socket has data waiting and
-- is read to be read, if a socket can be written to and if a socket has
-- an error status.
--
-- Parameters:
--   # ##sockets##: either one socket or a sequence of sockets.
--   # ##timeout##: maximum time to wait to determine a sockets status
--
-- Returns:
--   A sequence of the same size of sockets containing
--   { socket, read_status, write_status, error_status } for each socket passed
--  2 to the function.
--

public function select(object sockets, integer timeout=0)
	if socket(sockets) then
		sockets = { sockets }
	end if

	return machine_func(M_SOCK_SELECT, { sockets, timeout })
end function

--**
-- Send TCP data to a socket connected remotely.
--
-- Parameters:
--   # ##sock##: the socket to send data to
--   # ##data##: a sequence of atoms, what to send
--   # ##flags##: flags (see [[:Send Flags]])
--
-- Returns:
--   An **integer**, the number of characters sent, or -1 for an error.
--

public function send(socket sock, sequence data, atom flags=0)
	return machine_func(M_SOCK_SEND, { sock, data, flags })
end function

--**
-- Receive data from a bound socket. 
--
-- Parameters:
--   # ##sock##: the socket to get data from
--   # ##flags##: flags (see [[:Send Flags]])
--
-- Returns:     
--   A **sequence**, either a full string of data on success, or an atom indicating
--   the error code.
--
-- Comments:
--   This function will not return until data is actually received on the socket,
--   unless the flags parameter contains MSG_DONTWAIT.
--
--   MSG_DONTWAIT only works on Linux kernels 2.4 and above. To be cross-platform
--   you should use [[:select]] to determine if a socket is readable, i.e. has data
--   waiting.
--

public function recv(socket sock, atom flags=0)
	return machine_func(M_SOCK_RECV, { sock, flags })
end function

--**
-- Get options for a socket.
-- 
-- Parameters:
--   # ##sock##: the socket
--   # ##level##: an integer, the option level
--   # ##optname##: requested option (See [[:Socket Options]])
--
-- Returns:
--   An **object**, either:
-- * On error, {"ERROR",error_code}.  
-- * On success, either an atom or a sequence containing the option value, depending on the option.
--
-- Comments:
--   Primarily for use in multicast or more advanced socket
--   applications.  Level is the option level, and option_name is the
--   option for which values are being sought. Level is usually
--   SOL_SOCKET (#FFFF).
--
-- Returns:
--   On error, an atom indicating the error code.  On success, either an atom or
--   a sequence containing the option value.
--
-- See also:
--   [[:set_socket_options]]

public function get_socket_options(socket sock, integer level, integer optname)
	return machine_func(M_SOCK_GETSOCKOPT, { sock, level, optname })
end function

--**
-- Set options for a socket.
-- 
-- Parameters:
--   # ##sock##: an atom, the socket id
--   # ##level##: an integer, the option level
--   # ##optname##: requested option (See [[:Socket Options]])
--   # ##val##: an object, the new value for the option
--
-- Returns:
--   An **integer**, 0 on success, -1 on error.
--
-- Comments:
--   Primarily for use in multicast or more advanced socket
--   applications.  Level is the option level, and option_name is the
--   option for which values are being set.  Level is usually
--   SOL_SOCKET (#FFFF).
--
-- See Also:
--   [[:get_socket_options]]

public function set_socket_options(socket sock, integer level, integer optname, object val)
	return machine_func(M_SOCK_SETSOCKOPT, { sock, level, optname, val })
end function

--****
-- === Client side only

--**
-- Establish an outgoing connection to a remote computer. Only works with TCP sockets.
--
-- Parameters:
--   # ##sock##: the socket
--   # ##address##: ip address to connect, optionally with :PORT at the end
--   # ##port##: port number
--
-- Returns 
--   An **integer**, 0 for success and -1 on failure.
--
-- Comments:
--   ##address## can contain a port number. If it does not, it has to be supplied
--   to the ##port## parameter.
--
-- Example 1:
-- <eucode>
-- success = connect(sock, "11.1.1.1") -- uses default port 80
-- success = connect(sock, "11.1.1.1:110") -- uses port 110
-- success = connect(sock, "11.1.1.1", 345) -- uses port 345
-- </eucode>

public function connect(socket sock, sequence address, integer port=-1)
	object sock_data = parse_address(address, port)

	return machine_func(M_SOCK_CONNECT, { sock, sock_data[1], sock_data[2] })
end function

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Server-side sockets (bind, listeners, signal hooks, accepters)
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

--****
-- === Server side only

--**
-- Converts a text "address:port" into {"address", port} format.
--
-- Parameters:
--   # ##address##: ip address to connect, optionally with :PORT at the end
--   # ##port##: optional, if not specified you may include :PORT in
--     the address parameter otherwise the default port 80 is used.
--
-- Comments:
--   If ##port## is supplied, it overrides any ":PORT" value in the input
--   address.
--
-- Returns 
--   A sequence of two elements: "address" and integer port number.
--
-- Example 1:
-- <eucode>
-- addr = parse_address("11.1.1.1") --> {"11.1.1.1", 80} -- default port
-- addr = parse_address("11.1.1.1:110") --> {"11.1.1.1", 110}
-- addr = parse_address("11.1.1.1", 345) --> {"11.1.1.1", 345}
-- </eucode>

public function parse_address(sequence address, integer port = -1)
	address = seq:split(address, ':')
	
	if length(address) = 1 then
		if port < 0 or port > 65_535 then
			address &= DEFAULT_PORT
		else
			address &= port
		end if
	else
		if port < 0 or port > 65_535 then
			address[2] = value(address[2])
			if address[2][1] != GET_SUCCESS then
				address[2] = DEFAULT_PORT
			else
				address[2] = address[2][2]
			end if
		else
			address[2] = port
		end if
	end if
	
	return address
end function

--**
-- Joins a socket to a specific local internet address and port so
-- later calls only need to provide the socket. 
--
-- Parameters:
--   # ##sock##: the socket
--   # ##address##: the address to bind the socket to
--   # ##port##: optional, if not specified you must include :PORT in
--     the address parameter.
--
-- Returns 
--   An **integer**, 0 on success and -1 on failure.
--
-- Example 1:
-- <eucode>
-- -- Bind to all interfcaes on the default port 80.
-- success = bind(socket, "0.0.0.0")
-- -- Bind to all interfaces on port 8080.
-- success = bind(socket, "0.0.0.0:8080")
-- -- Bind only to the 243.17.33.19 interface on port 345.
-- success = bind(socket, "243.17.33.19", 345)
-- </eucode>

public function bind(socket sock, sequence address, integer port=-1)
	object sock_data = parse_address(address, port)

	return machine_func(M_SOCK_BIND, { sock, sock_data[1], sock_data[2] })
end function

--**
-- Start monitoring a connection. Only works with TCP sockets.
--
-- Parameters:
--   # ##sock##: the socket
--   # ##backlog##: the number of connection requests that
--     can be kept waiting before the OS refuses to hear any more.
--
-- Returns:
--   An **integer**, 0 on success and an error code on failure.
--
-- Comments:
--   Once the socket is created and bound, this will indicate to the
--   operating system that you are ready to being listening for connections.
--
--   The value of ##backlog## is strongly dependent on both the hardware
--   and the amount of time it takes the program to process each
--   connection request.
--
--   This function must be executed after [[:bind]]().
--

public function listen(socket sock, integer backlog)
	return machine_func(M_SOCK_LISTEN, { sock, backlog })
end function

--**
-- Produces a new socket for an incoming connection.
--
-- Parameters:
--   # ##sock##: the server socket
--
-- Returns:
--   An **object**, either -1 on failure, or a sequence
--   {socket client, sequence client_ip_address} on success.
--
-- Comments:
--   Using this function allows communication to occur on a
--   "side channel" while the main server socket remains available
--   for new connections.
--
--   ##accept##() must be called after ##bind##() and ##listen##().
--
--   On failure, use [[:get_error]] to determine the cause of the failure.
--

public function accept(socket sock)
	return machine_func(M_SOCK_ACCEPT, { sock })
end function

--****
-- === Information

--**
-- Get service information by name.
--
-- Parameters
--   # ##name##: service name.
--   # ##protocol##: protocol. Default is not to search by protocol.
--
-- Returns:
--   A ##sequence## containing { offical protocol name, protocol, port number } or
--   an atom indicating the error code.
--
-- Example 1:
-- <eucode>
-- object result = getservbyname("http")
-- -- result = { "http", "tcp", 80 }
-- </eucode>
--

public function getservbyname(sequence name, object protocol=0)
	return machine_func(M_SOCK_GETSERVBYNAME, { name, protocol })
end function

--**
-- Get service information by port number.
--
-- Parameters
--   # ##port##: port number.
--   # ##protocol##: protocol. Default is not to search by protocol.
--
-- Returns:
--   A ##sequence## containing { offical protocol name, protocol, port number } or
--   an atom indicating the error code.
--
-- Example 1:
-- <eucode>
-- object result = getservbyport(80)
-- -- result = { "http", "tcp", 80 }
-- </eucode>
--

public function getservbyport(integer port, object protocol=0)
	return machine_func(M_SOCK_GETSERVBYPORT, { port, protocol })
end function
