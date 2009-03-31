--****
-- == Internet Sockets
--
-- Based on EuNet project, version 1.3.2, at SourceForge.
-- http://www.sourceforge.net/projects/eunet.
--
-- <<LEVELTOC depth=2>>
 
ifdef DOS32 then
	include std/error.e
	crash("socket.e is not supported on the DOS platform")
end ifdef

include std/dll.e
include std/machine.e
include std/get.e
include std/wildcard.e
include std/text.e

enum M_SOCK_GETSERVBYNAME=77, M_SOCK_GETSERVBYPORT, M_SOCK_SOCKET=81, M_SOCK_CLOSE, M_SOCK_SHUTDOWN,
	M_SOCK_CONNECT, M_SOCK_SEND, M_SOCK_RECV, M_SOCK_BIND, M_SOCK_LISTEN,
	M_SOCK_ACCEPT, M_SOCK_SETSOCKOPT, M_SOCK_GETSOCKOPT

--****
-- === Constants
--

--**
-- Socket types

ifdef WIN32 then
	public constant
		AF_UNSPEC=0, AF_UNIX=1, AF_INET=2, AF_APPLETALK=16, AF_INET6=-1,
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

--**
-- RFC 1700	

public constant
	IPPROTO_IP   = 0,
	IPPROTO_ICMP = 1,
	IPPROTO_TCP  = 6,
	IPPROTO_EGP  = 8,
	IPPROTO_PUP  = 12,
	IPPROTO_UDP  = 17,
	IPPROTO_IDP  = 22,
	IPPROTO_TP   = 29,
	IPPROTO_EON  = 80,
	IPPROTO_RM   = 113

public constant
	SOL_SOCKET = #FFFF,
		
	SD_SEND = 0,
	SD_RECEIVE = 1,
	SD_BOTH = 2,

	SO_DEBUG = 1,
	SO_ACCEPTCONN = 2,
	SO_REUSEADDR = 4,
	SO_KEEPALIVE = 8,
	SO_DONTROUTE = 16,
	SO_BROADCAST = 32,
	SO_USELOOPBACK = 64,
	SO_LINGER = 128,
	SO_OOBINLINE = 256,
	SO_REUSEPORT = 512,
	SO_SNDBUF = #1001,
	SO_RCVBUF = #1002,
	SO_SNDLOWAT = #1003,
	SO_RCVLOWAT = #1004,
	SO_SNDTIMEO = #1005,
	SO_RCVTIMEO = #1006,
	SO_ERROR = #1007,
	SO_TYPE = #1008,
	
	IP_OPTIONS = 1,
	IP_HDRINCL = 2,
	IP_TOS = 3,
	IP_TTL = 4,
	IP_RECVOPTS = 5,
	IP_RECVRETOPTS = 6,
	IP_RECVDSTADDR = 7,
	IP_RETOPTS = 8,
	IP_MULTICAST_IF = 9,
	IP_MULTICAST_TTL = 10,
	IP_MULTICAST_LOOP = 11,
	IP_ADD_MEMBERSHIP = 12,
	IP_DROP_MEMBERSHIP = 13,
	IP_DONTFRAGMENT = 14,
	IP_ADD_SOURCE_MEMBERSHIP = 15,
	IP_DROP_SOURCE_MEMBERSHIP = 16,
	IP_BLOCK_SOURCE = 17,
	IP_UNBLOCK_SOURCE = 18,
	IP_PKTINFO = 19,
	IPV6_UNICAST_HOPS = 4,
	IPV6_MULTICAST_IF = 9,
	IPV6_MULTICAST_HOPS = 10,
	IPV6_MULTICAST_LOOP = 11,
	IPV6_ADD_MEMBERSHIP = 12,
	IPV6_DROP_MEMBERSHIP = 13,
	IPV6_JOIN_GROUP = IPV6_ADD_MEMBERSHIP,
	IPV6_LEAVE_GROUP = IPV6_DROP_MEMBERSHIP,
	IPV6_PKTINFO = 19,
	IP_DEFAULT_MULTICAST_TTL = 1,
	IP_DEFAULT_MULTICAST_LOOP = 1,
	IP_MAX_MEMBERSHIPS = 20,
	TCP_EXPEDITED_1122 = 2,
	UDP_NOCHECKSUM = 1

public constant MSG_OOB = #1,
	MSG_PEEK = #2,
	MSG_DONTROUTE = #4,
	MSG_TRYHARD = #4,
	MSG_CTRUNC = #8,
	MSG_PROXY = #10,
	MSG_TRUNC = #20,
	MSG_DONTWAIT = #40,
	MSG_EOR = #80,
	MSG_WAITALL = #100,
	MSG_FIN = #200,
	MSG_SYN = #400,
	MSG_CONFIRM = #800,
	MSG_RST = #1000,
	MSG_ERRQUEUE = #2000,
	MSG_NOSIGNAL = #4000,
	MSG_MORE = #8000,
	
	EUNET_ERRORMODE_EUNET = 1,
	EUNET_ERRORMODE_OS = 2,
	EUNET_ERROR_NOERROR = 0,
	EUNET_ERROR_WRONGMODE = -998,
	EUNET_ERROR_NODATA = -1001,
	EUNET_ERROR_LINUXONLY = -1002,
	EUNET_ERROR_WINDOWSONLY = -1003,
	EUNET_ERROR_NODNSRECORDS = -1501,
	EUNET_ERROR_NOCONNECTION = -1502,
	EUNET_ERROR_NOTASOCKET = -1503,
	EUNET_ERROR_UNKNOWN = -1999,
	
	EAGAIN = 11,
	EWOULDBLOCK = EAGAIN,
	EBADF = 9,
	ECONNRESET = 104,
	ECONNREFUSED = 111,
	EFAULT = 14,
	EINTR = 4,
	EINVAL = 22,
	EIO = 5,
	ENOBUFS = 105,
	ENOMEM = 12,
	ENOSR = 63,
	ENOTCONN = 107,
	ENOTSOCK = 88,
	EOPNOTSUPP = 95,
	ETIMEDOUT = 110,
	WSA_WAIT_FAILED = -1,
	WSA_WAIT_EVENT_0 = 0,
	WSA_WAIT_IO_COMPLETION = #C0,
	WSA_WAIT_TIMEOUT = #102,
	
	WSABASEERR = 10000,
	WSAEINTR =                (WSABASEERR+4),
	WSAEBADF =               (WSABASEERR+9),
	WSAEACCES=               (WSABASEERR+13),
	WSAEFAULT=               (WSABASEERR+14),
	WSAEINVAL=               (WSABASEERR+22),
	WSAEMFILE=               (WSABASEERR+24),
	WSAEWOULDBLOCK =         (WSABASEERR+35),
	WSAEINPROGRESS =         (WSABASEERR+36),
	WSAEALREADY    =         (WSABASEERR+37),
	WSAENOTSOCK    =         (WSABASEERR+38),
	WSAEDESTADDRREQ=         (WSABASEERR+39),
	WSAEMSGSIZE    =         (WSABASEERR+40),
	WSAEPROTOTYPE  =         (WSABASEERR+41),
	WSAENOPROTOOPT =         (WSABASEERR+42),
	WSAEPROTONOSUPPORT =     (WSABASEERR+43),
	WSAESOCKTNOSUPPORT =     (WSABASEERR+44),
	WSAEOPNOTSUPP      =     (WSABASEERR+45),
	WSAEPFNOSUPPORT    =     (WSABASEERR+46),
	WSAEAFNOSUPPORT    =     (WSABASEERR+47),
	WSAEADDRINUSE      =     (WSABASEERR+48),
	WSAEADDRNOTAVAIL   =     (WSABASEERR+49),
	WSAENETDOWN        =     (WSABASEERR+50),
	WSAENETUNREACH     =     (WSABASEERR+51),
	WSAENETRESET       =     (WSABASEERR+52),
	WSAECONNABORTED    =     (WSABASEERR+53),
	WSAECONNRESET      =     (WSABASEERR+54),
	WSAENOBUFS         =     (WSABASEERR+55),
	WSAEISCONN         =     (WSABASEERR+56),
	WSAENOTCONN        =     (WSABASEERR+57),
	WSAESHUTDOWN       =     (WSABASEERR+58),
	WSAETOOMANYREFS    =     (WSABASEERR+59),
	WSAETIMEDOUT       =     (WSABASEERR+60),
	WSAECONNREFUSED    =     (WSABASEERR+61),
	WSAELOOP           =     (WSABASEERR+62),
	WSAENAMETOOLONG    =     (WSABASEERR+63),
	WSAEHOSTDOWN       =     (WSABASEERR+64),
	WSAEHOSTUNREACH    =     (WSABASEERR+65),
	WSAENOTEMPTY       =     (WSABASEERR+66),
	WSAEPROCLIM        =     (WSABASEERR+67),
	WSAEUSERS          =     (WSABASEERR+68),
	WSAEDQUOT          =     (WSABASEERR+69),
	WSAESTALE          =     (WSABASEERR+70),
	WSAEREMOTE         =     (WSABASEERR+71),
	WSASYSNOTREADY     =     (WSABASEERR+91),
	WSAVERNOTSUPPORTED =     (WSABASEERR+92),
	WSANOTINITIALISED  =     (WSABASEERR+93),
	
	POLLIN = 1,
	POLLPRI = 2,
	POLLOUT = 4,
	POLLRDNORM = #40,
	POLLRDBAND = #80,
	POLLWRNORM = #100,
	POLLWRBAND = #200,
	POLLMSG = #400,
	POLLERR = #8,
	POLLHUP = #10,
	POLLNVAL = #20,
	
	FD_READ = 1,
	FD_WRITE = 2,
	FD_OOB = 4,
	FD_ACCEPT = 8,
	FD_CONNECT = 16,
	FD_CLOSE = 32,
	
	HTTP_HEADER_HTTPVERSION = 1,
	HTTP_HEADER_GET = 2,
	HTTP_HEADER_HOST = 3,
	HTTP_HEADER_REFERER = 4,
	HTTP_HEADER_USERAGENT = 5,
	HTTP_HEADER_ACCEPT = 6,
	HTTP_HEADER_ACCEPTCHARSET = 7,
	HTTP_HEADER_ACCEPTENCODING = 8,
	HTTP_HEADER_ACCEPTLANGUAGE = 9,
	HTTP_HEADER_ACCEPTRANGES = 10,
	HTTP_HEADER_AUTHORIZATION = 11,
	HTTP_HEADER_DATE = 12,
	HTTP_HEADER_IFMODIFIEDSINCE = 13,
	HTTP_HEADER_POST = 14,
	HTTP_HEADER_POSTDATA = 15,
	HTTP_HEADER_CONTENTTYPE = 16,
	HTTP_HEADER_CONTENTLENGTH = 17,
	HTTP_HEADER_FROM = 18,
	HTTP_HEADER_KEEPALIVE = 19,
	HTTP_HEADER_CACHECONTROL = 20,
	HTTP_HEADER_CONNECTION = 21

constant BLOCK_SIZE = 4096

export atom sockdll_, dll_
atom ipdll_, kerneldll_,
	wsastart_, wsacleanup_, wsawaitformultipleevents_,
	wsacreateevent_, wsaeventselect_, wsaenumnetworkevents_, wsacloseevent_,
	ioctl_,
	sendto_, sendmsg_, recvfrom_, recvmsg_,
	poll_,
	error_, delay_

sequence windows_poll_seq = {}

atom error_mode = 1  -- This will indicate whether returned errors will be OS numbers (mode 2)
-- or EUNET_ERROR numbers (mode 1).  The default is mode 1.

-- select() will not be supported because Euphoria does not support
-- wrapping of macros.  FD_SET, etc. do not have extern functions
-- available, and are required in order for select() to work.
-- Use poll() instead.

-- gethostbyname() and getservbyname() are deprecated in favor of getaddrinfo().
-------------------------------------------------------------------------------
-- Initializations & support routines
-------------------------------------------------------------------------------
atom wsastatus, wsadata

ifdef DOS32 then
	dll_ = -1
elsifdef WIN32 then
	ipdll_ = open_dll("iphlpapi.dll")
	sockdll_ = open_dll("ws2_32.dll")
	kerneldll_ = open_dll("kernel32.dll")
	dnsdll_ = open_dll("dnsapi.dll")
	error_ = define_c_func(sockdll_,"WSAGetLastError",{},C_INT)
	poll_ = define_c_func(sockdll_,"WSAPoll",{C_POINTER,C_INT,C_INT},C_INT)
	ioctl_ = define_c_func(sockdll_,"ioctlsocket",{C_INT,C_INT,C_POINTER},C_INT)
	sendto_ = define_c_func(sockdll_,"sendto",{C_INT,C_POINTER,C_INT,C_INT,C_POINTER,C_INT},C_INT)
	sendmsg_ = define_c_func(sockdll_,"sendmsg",{C_INT,C_POINTER,C_INT},C_INT)
	recvfrom_ = define_c_func(sockdll_,"recvfrom",{C_INT,C_POINTER,C_INT,C_INT,C_POINTER,C_POINTER},C_INT)
	recvmsg_ = define_c_func(sockdll_,"recvmsg",{C_INT,C_POINTER,C_INT},C_INT)
	-- WSAStartup() is required when using WinSock.
	wsastart_ = define_c_func(sockdll_,"WSAStartup",{C_USHORT,C_POINTER},C_INT)
	wsadata = allocate(4096)
	wsastatus = c_func(wsastart_,{514,wsadata}) -- version 2.2 max
	if wsastatus!=0 then
		puts(1,sprintf("Winsock startup error %d",wsastatus))
	end if
	free(wsadata)
	wsacleanup_ = define_c_func(sockdll_,"WSACleanup",{},C_INT)   -- Windows apps need to run this when the program ends
	wsacreateevent_ = define_c_func(sockdll_,"WSACreateEvent",{},C_INT)
	wsacloseevent_ = define_c_func(sockdll_,"WSACloseEvent",{C_INT},C_INT)
	wsaeventselect_ = define_c_func(sockdll_,"WSAEventSelect",{C_INT,C_INT,C_INT},C_INT)
	wsaenumnetworkevents_ = define_c_func(sockdll_,"WSAEnumNetworkEvents",{C_INT,C_INT,C_POINTER},C_INT)
	wsawaitformultipleevents_ = define_c_func(sockdll_,"WSAWaitForMultipleEvents",
		{C_INT,C_POINTER,C_INT,C_INT,C_INT},C_INT)
	delay_ = define_c_proc(kerneldll_,"Sleep",{C_INT})
elsifdef LINUX then
	dll_ = open_dll("") -- libc
elsifdef FREEBSD then
	dll_ = open_dll("libc.so")
elsifdef SUNOS then
	dll_ = open_dll("libsocket.so")
elsifdef OSX then
	dll_ = open_dll("libc.dylib")
end ifdef

ifdef UNIX then
	error_ = define_c_func(dll_,"__errno_location",{},C_INT)
	ioctl_ = define_c_func(dll_,"ioctl",{C_INT,C_INT,C_INT},C_INT)
	poll_ = define_c_func(dll_,"poll",{C_POINTER,C_INT,C_INT},C_INT)
	sendto_ = define_c_func(dll_,"sendto",{C_INT,C_POINTER,C_INT,C_INT,C_POINTER,C_INT},C_INT)
	sendmsg_ = define_c_func(dll_,"sendmsg",{C_INT,C_POINTER,C_INT},C_INT)
	recvfrom_ = define_c_func(dll_,"recvfrom",{C_INT,C_POINTER,C_INT,C_INT,C_POINTER,C_POINTER},C_INT)
	recvmsg_ = define_c_func(dll_,"recvmsg",{C_INT,C_POINTER,C_INT},C_INT)
	delay_ = define_c_func(dll_,"nanosleep",{C_POINTER,C_POINTER},C_INT)
end ifdef

-------------------------------------------------------------------------------

export function _socket_trim(sequence s)
	atom c
	sequence rs
	rs = s
	c = 1
	while c <= length(s) and rs[c] <= 32 do
		c = c + 1
	end while
	rs = rs[c..length(rs)]
	c = length(rs)
	while c > 0 and rs[c] <= 32 do
		c = c - 1
	end while
	rs = rs[1..c]
	return rs
end function

-------------------------------------------------------------------------------

export function get_sockaddr(atom lpsz)
	sequence s = ""
	atom port

	if lpsz = 0 then
		return s
	end if

	-- sockaddr
	-- 2 bytes: AF_INET (or other type)
	-- 2 bytes: port
	-- 4 bytes: network address
	-- 8 bytes: null
	for ptr = lpsz+4 to lpsz+7 do
		s = s & sprintf("%d",peek(ptr))
		if ptr < lpsz+7 then s = s & '.' end if
	end for

	port = (peek(lpsz+2)*256)+peek(lpsz+3)

	s = s & sprintf(":%d",port)

	return s
end function

-------------------------------------------------------------------------------

function make_sockaddr(sequence inet_addr)
	
	atom sockaddr, cpos
	sequence temp
	sequence addr
	if find('.',inet_addr)=0 or find(':',inet_addr)=0 then
		return 0
	end if
	addr = {0,0,0,0,0}
	cpos = find('.',inet_addr)
	temp = value(inet_addr[1..cpos-1])
	if temp[1]=GET_SUCCESS then
		addr[1] = temp[2]
		inet_addr = inet_addr[cpos+1..length(inet_addr)]
	else
		return 0
	end if
	cpos = find('.',inet_addr)
	temp = value(inet_addr[1..cpos-1])
	if temp[1]=GET_SUCCESS then
		addr[2] = temp[2]
		inet_addr = inet_addr[cpos+1..length(inet_addr)]
	else
		return 0
	end if
	cpos = find('.',inet_addr)
	temp = value(inet_addr[1..cpos-1])
	if temp[1]=GET_SUCCESS then
		addr[3] = temp[2]
		inet_addr = inet_addr[cpos+1..length(inet_addr)]
	else
		return 0
	end if
	cpos = find(':',inet_addr)
	temp = value(inet_addr[1..cpos-1])
	if temp[1]=GET_SUCCESS then
		addr[4] = temp[2]
		inet_addr = inet_addr[cpos+1..length(inet_addr)]
	else
		return 0
	end if
	temp = value(inet_addr)
	if temp[1]=GET_SUCCESS then
		addr[5] = temp[2]
	else
		return 0
	end if
	sockaddr = allocate(16)
	poke(sockaddr,{AF_INET,0})
	poke(sockaddr+2,floor(addr[5]/256))
	poke(sockaddr+3,remainder(addr[5],256))
	poke(sockaddr+4,addr[1..4])
	poke(sockaddr+8,{0,0,0,0,0,0,0,0})
	return sockaddr
	
end function

--****
-- === Support routines
--

--**
-- Checks if x is an IP address in the form (#.#.#.#[:#])
--
-- Parameters:
--   # ##x##: the address to check
--
-- Returns:
--   An **integer**, 1 if x is an inetaddr, 0 if it is not

public function is_inetaddr(object s)
	-- Checks if s is an IP address in the form (#.#.#.#[:#])
	
	atom numdots, numcols
	numdots = 0
	numcols = 0
	
	if not sequence(s) then
		return 0
	end if
	if length(s) < 7 or length(s) > 21 then
		return 0
	end if
	for ctr = 1 to length(s) do
		if (s[ctr] < '0' or s[ctr] > '9') and s[ctr]!='.' and s[ctr]!=':' then
			return 0
		end if
		if s[ctr] = '.' then numdots = numdots + 1 end if
		if s[ctr] = ':' then numcols = numcols + 1 end if
	end for
	if numdots != 3 or numcols > 1 then
		return 0
	end if

	return 1
end function

--**
-- Returns the current error mode.
--
-- See Also:
--     [[:set_errormode]], [[:get_error]]

public function get_errormode()
	return error_mode
end function

--**
-- Sets the error mode.
--
-- Parameters:
--   # ##mode##: an integer, either EUNET_ERRORMODE_EUNET or EUNET_ERRORMODE_OS.
--
-- Comments:
--	The errors returned will either be generated by the kernel (OS) or massaged by 
--	the library for cross-platform compatibility (EUNET).

public function set_errormode(integer mode)
	if find(mode,{1,2}) = 0 then
		return EUNET_ERROR_WRONGMODE
	else
		error_mode = mode
		return 0
	end if
end function

--**
-- Retrieves the last error code and error string.
--
-- Returns:
--   A **sequence** of length 2, made of an integer, the error code, and the error string.
--
-- Comments:
--   If error mode is EUNET_ERRORMODE_EUNET, the error codes will be one of . . .
--
-- * EUNET_ERROR_NOERROR = 0
-- * EUNET_ERROR_WRONGMODE = -998
-- * EUNET_ERROR_NODATA = -1001
-- * EUNET_ERROR_LINUXONLY = -1002
-- * EUNET_ERROR_WINDOWSONLY = -1003
-- * EUNET_ERROR_NODNSRECORDS = -1501
-- * EUNET_ERROR_UNKNOWN = -1999
--
-- If error mode is EUNET_ERRORMODE_OS, the error returned will be
-- what the OS kernel returns.  Unless otherwise set, error mode is
-- EUNET_ERRORMODE_EUNET by default.
--
-- Example 1:
-- <eucode>
-- s = get_error()
-- printf(1,"Error %d: %s\n",s)
-- </eucode>
--
-- See Also:
--     [[:set_errormode]], [[:get_errormode]]

public function get_error()
	-- returns a 2-element sequence {ERROR_CODE,ERROR_STRING}
	sequence rtn
	rtn = {0,""}
	ifdef UNIX then
		rtn[1]=peek4u(c_func(error_,{}))
	elsifdef WIN32 then
		rtn[1] = c_func(error_,{})
	end ifdef
	if error_mode = EUNET_ERRORMODE_OS then
		return rtn
	end if
	if error_mode = EUNET_ERRORMODE_EUNET then
		if rtn[1] = EAGAIN or rtn[1] = WSAEWOULDBLOCK then
			rtn = {EUNET_ERROR_NODATA,"There is no data waiting."}
		elsif rtn[1] = 9501 or rtn[1] = 9003 then
			rtn = {EUNET_ERROR_NODNSRECORDS,"DNS could not find an exact match."}
		elsif rtn[1] = EOPNOTSUPP or rtn[1] = WSAEOPNOTSUPP then
			ifdef UNIX then
				rtn = {EUNET_ERROR_WINDOWSONLY,"This only works on Windows."}
			elsifdef WIN32 then
				rtn = {EUNET_ERROR_LINUXONLY,"This only works on Linux."}
			elsedef
				rtn = {EUNET_ERROR_UNKNOWN,"You are not using Windows or Linux."}
			end ifdef
		elsif rtn[1] = WSAENOTCONN or rtn[1] = ENOTCONN then
			rtn = {EUNET_ERROR_NOCONNECTION,"This socket is not connected to anything."}
		elsif rtn[1] = WSAENOTSOCK or rtn[1] = ENOTSOCK then
			rtn = {EUNET_ERROR_NOTASOCKET,"Either the socket is already closed, or "&
			"you are\n trying to use a file handle in an IP socket."}
		elsif rtn[1] = 0 then
			rtn = {EUNET_ERROR_NOERROR,"OK"}
		else
			rtn = {EUNET_ERROR_UNKNOWN,"Unknown error."}
		end if
	end if
	return rtn
	
end function

--**
-- Determine whether another socket read is appropriate.
--
-- Returns:
--     The packet block size in bytes.
--
-- Example 1:
-- <eucode>
-- success = 1
-- while success > 0 do
--     data = data & recv(socket,0)
--     success = length(data)-last_data_len
--     last_data_len = length(data)
--     if success < get_blocksize() then
--         exit
--     end if
-- end while
-- </eucode>

public function get_blocksize()
	return BLOCK_SIZE
end function

--**
-- Wait for a short delay.
--
-- Parameters:
--   # ##millisec##: an atom, the number of 1/1000 seconds to wait.
--
-- Returns:
--   0 for success, -1 for error.
--
-- Comments:
-- Since this function implements kernel routines on each platform, the delay is not
-- a CPU hogging busy loop.
--
-- Example 1:
-- <eucode>
-- error = delay(250)
-- if error then
--    puts(1,"Uh, oh.")
-- else
--    puts(1,"Get back to work!")
-- end if
-- </eucode>

public function delay(atom millisec)
	-- Delays nicely for a set number of milliseconds (or a few more)
	-- Returns 0 on success or something else on error.
	
	ifdef WIN32 then
		c_proc(delay_,{millisec})
		return 0
	elsifdef UNIX then
		atom result
		atom timptr

		timptr = allocate(16) -- Reserved for when OSs start using 64bit time_t
		if millisec >= 1000 then
			poke4(timptr,floor(millisec/1000))
		else
			poke4(timptr,0)
		end if
		poke4(timptr+4,remainder(millisec,1000)*1000000)
		result = c_func(delay_,{timptr,0})
		free(timptr)
		return result
	end ifdef
	
	return -1
end function

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Server-side sockets (bind, listeners, signal hooks, accepters)
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

--****
-- === Socket routines - server side
--

--**
-- Joins a socket to a specific local internet address and port so
-- later calls only need to provide the socket. 
--
-- Parameters:
--   # ##socket##: the socket
--   # ##family##: socket family
--   # ##address##: the address to bind the socket to
--   # ##port##: optional, if not specified you must include :PORT in
--     the address parameter.
--
-- Returns 
--   An **integer**, 0 on success and -1 on failure.
--
-- Example 1:
-- <eucode>
-- success = bind(socket, AF_INET, "0.0.0.0:8080")
-- -- Look for connections on port 8080 for any interface.
-- </eucode>

public function bind(atom socket, integer family, sequence address, integer port=0)
	if port = 0 then
		integer colon = find(':', address)
		if colon = 0 then
			return -1
		end if

		object port_v = value(address[colon+1..$])
		if port_v[1] != GET_SUCCESS then
			return -1
		end if

		port = port_v[2]
		address = address[1..colon-1]
	end if

	return machine_func(M_SOCK_BIND, { socket, family, address, port })
end function

--**
-- Start monitoring a connection. Only works with TCP sockets.
--
-- Parameters:
--   # ##socket##: an atom, the socket id
--   # ##backlog##: the number of connection requests that
--     can be kept waiting before the OS refuses to hear any more.
--
-- Returns:
--   An **integer**, 0 on success and an error code on failure.
--
-- Comments:
--   This function is used in a program that will be receiving
--   connections.
--
--   The value of ##backlog## is strongly dependent on both the hardware
--   and the amount of time it takes the program to process each
--   connection request.
--
--   This function must be executed after [[:bind]]().

public function listen(atom socket, integer backlog)
	return machine_func(M_SOCK_LISTEN, { socket, backlog })
end function

--**
-- Produces a new socket for an incoming connection.
--
-- Parameters:
--   # ##socket##: an atom, the side connection socket id
--
-- Returns:
--   An **object**, either -1 on failure, or a sequence
--   {atom new_socket, sequence peer_ip_address} on success.
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

public function accept(atom socket)
	return machine_func(M_SOCK_ACCEPT, { socket })
end function

--****
-- === Socket routines - client side

--**
-- Establish an outgoing connection to a remote computer. Only works with TCP sockets.
--
-- Parameters:
--   # ##family##: type of socket
--   # ##socket##: the socket
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
-- success = connect(AF_INET, socket, "11.1.1.1:80")
-- </eucode>

public function connect(integer family, atom socket, sequence address, integer port=0)
	if port = 0 then
		integer colon = find(':', address)
		if colon = 0 then
			return -1
		end if

		object port_v = value(address[colon+1..$])
		if port_v[1] != GET_SUCCESS then
			return -1
		end if

		port = port_v[2]
		address = address[1..colon-1]
	end if

	return machine_func(M_SOCK_CONNECT, { family, socket, address, port })
end function

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Routines for both server & client (socket, read, write, select)
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--****
-- === Socket routines - both sides
--

--**
-- Returns a handle to a newly created socket.
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
-- socket = new_socket(AF_INET, SOCK_STREAM, 0)
-- </eucode>

public function new_socket(integer family, integer sock_type, integer protocol)
	return machine_func(M_SOCK_SOCKET, { family, sock_type, protocol })
end function

--**
-- Closes a socket.
--
-- Parameters:
--   # ##socket##: an atom, the socket to close
--
-- Returns:
--   An **integer**, 0 on success and -1 on error. 
--
-- Comments:
-- It may take several minutes for the OS to declare the socket as closed.
-- 

public function close_socket(atom socket)
	return machine_func(M_SOCK_CLOSE, { socket })
end function

--**
-- Partially or fully close a socket. 
--
-- Parameters:
--   # ##socket##: an atom, the socket to close
--   # ##method##: an integer, the method used to close the socket
--
-- Returns:
--   An **integer**, 0 on success and -1 on error.
--
-- Comments:
--   A method of 0 closes the socket for reading, 1 closes the socket for writing, and
--   2 closes the socket for both.
--
--  It may take several minutes for the OS to declare the socket as closed.

public function shutdown_socket(atom socket, atom method=SD_BOTH)
	return machine_func(M_SOCK_SHUTDOWN, { socket, method })
end function

-------------------------------------------------------------------------------
-- poll
-- select() is not supported
-------------------------------------------------------------------------------
-- socket list is a sequence of 2-element sequences.  Each sequence contains
-- the socket number, and the flags of what to check for.  Timeout is the
-- number of milliseconds before returning.  0 returns immediately, -1 returns
-- only when an event occurs.
-- poll may return an atom on no event or error, and a sequence of
-- return event flags (matching socket_list) when an event has occurred.

function unix_poll(sequence socket_list, atom timeout)
	
	atom fdptr, nfds
	object rtn
	
	fdptr = allocate(length(socket_list)*8)
	nfds = 0
	
	for ctr = 1 to length(socket_list) do
		if sequence(socket_list[ctr]) and length(socket_list[ctr])>=2 and
				atom(socket_list[ctr][1]) and atom(socket_list[ctr][2]) and
				socket_list[ctr][2] > 0 then
			poke4(fdptr+(nfds*8),socket_list[ctr][1])
			poke(fdptr+5+(nfds*8),floor(socket_list[ctr][2]/256))
			poke(fdptr+4+(nfds*8),remainder(socket_list[ctr][2],256))
			poke(fdptr+6+(nfds*8),0)
			poke(fdptr+7+(nfds*8),0)
			nfds = nfds + 1
		end if
	end for
	if nfds = 0 then
		free(fdptr)
		return {}
	end if
	rtn = c_func(poll_,{fdptr,nfds,timeout})
	if rtn > 0 then
		rtn = {}
		for ctr = 0 to nfds-1 do
			rtn = rtn & ((peek(fdptr+6+(ctr*8)))+(peek(fdptr+7+(ctr*8))*256))
		end for
	end if
	free(fdptr)
	return rtn
	
end function

function windows_poll(sequence socket_list, atom timeout)
	atom wps_found, wps_index, wps_select
	atom eventlist
	object result
	-- WSAPoll is only available on Windows Vista+.
	if poll_ > 0 then
		return unix_poll(socket_list,timeout)
	end if
	-- windows_poll_seq = {{atom socket, atom events, atom event_handle, atom closeevent_status},...}
	for ctr = 1 to length(socket_list) do
		if sequence(socket_list[ctr]) and length(socket_list[ctr])>=2 and
				atom(socket_list[ctr][1]) and atom(socket_list[ctr][2]) then
			wps_found = 0
			for wps = 1 to length(windows_poll_seq) do
				if windows_poll_seq[wps][1]=socket_list[ctr][1] then
					wps_found = 1
					wps_index = wps
					if socket_list[ctr][2] = 0 then
						windows_poll_seq[wps][4] = c_func(wsacloseevent_,{windows_poll_seq[wps][3]})
						windows_poll_seq[wps][3] = -1
					elsif socket_list[ctr][2] != windows_poll_seq[wps][2] then
						windows_poll_seq[wps][4] = c_func(wsacloseevent_,{windows_poll_seq[wps][3]})
						windows_poll_seq[wps][3] = 0
						windows_poll_seq[wps][2] = socket_list[ctr][2]
					end if
					exit
				end if
			end for
			if not wps_found then
				windows_poll_seq = append(windows_poll_seq,{socket_list[ctr][1],socket_list[ctr][2],0,0})
				wps_index = length(windows_poll_seq)
			end if
		end if
	end for
	wps_found = 1   -- Remove cancelled polls
	while wps_found <= length(windows_poll_seq) do
		if windows_poll_seq[wps_found][3] != -1 then
			wps_found = wps_found + 1
		else
			windows_poll_seq = windows_poll_seq[1..wps_found-1] &
			windows_poll_seq[wps_found+1..length(windows_poll_seq)]
		end if
	end while
	if length(windows_poll_seq)>0 then
		eventlist = allocate(4*length(windows_poll_seq))
	else
		return -1
	end if
	for ctr = 1 to length(windows_poll_seq) do -- Link an event to a socket poll
		if windows_poll_seq[ctr][3] = 0 then
			windows_poll_seq[ctr][3] = c_func(wsacreateevent_,{})
			wps_select = 0
			if and_bits(windows_poll_seq[ctr][2],POLLIN) then
				wps_select = or_bits(wps_select,FD_READ)
				wps_select = or_bits(wps_select,FD_ACCEPT)
			end if
			if and_bits(windows_poll_seq[ctr][2],POLLPRI) then
				wps_select = or_bits(wps_select,FD_OOB)
			end if
			if and_bits(windows_poll_seq[ctr][2],POLLOUT) then
				wps_select = or_bits(wps_select,FD_WRITE)
			end if
			if and_bits(windows_poll_seq[ctr][2],POLLHUP) then
				wps_select = or_bits(wps_select,FD_CLOSE)
			end if
			-- Other poll flags are not supported on Windows other than Vista.
			windows_poll_seq[ctr][4] = c_func(wsaeventselect_,{windows_poll_seq[ctr][1],
				windows_poll_seq[ctr][3],wps_select})
		end if
		poke4(eventlist+(4*(ctr-1)),windows_poll_seq[ctr][3])
	end for
	wps_found = c_func(wsawaitformultipleevents_,{length(windows_poll_seq),
		eventlist,0,timeout,0})
	free(eventlist)
	if wps_found = WSA_WAIT_TIMEOUT then
		return 0
	end if
	if wps_found >= 0 and wps_found < length(windows_poll_seq) then
		-- zero-based indexing
		result = {}
		for ctr = 1 to length(socket_list) do
			if windows_poll_seq[wps_found+1][1] != socket_list[ctr][1] then
				result = result & 0
			else
				result = result & windows_poll_seq[wps_found+1][2]
				-- Issue: After closing the event, attempting to accept the connection results
				-- in WSAENOTSOCK.
				--        windows_poll_seq[wps_found+1][4] = c_func(wsacloseevent_,{windows_poll_seq[wps_found+1][3]})
				--        windows_poll_seq[wps_found+1][3] = 0
				--        windows_poll_seq[wps_found+1][2] = 0
			end if
		end for
		return result
	end if
	return wps_found
	
end function

--**
-- Monitor socket events.
--
-- Parameters:
--   # ##socket_list##: a sequence of polling policies, see Comments for details
--   # ##timeout##: an atom, the number of milliseconds before returning.
--
-- Returns:
--   An **object**:
-- * If no event occurred, or there was an error, an atom
-- * On an event, a sequence, the return flags for each socket in ##socket_list##.
--
-- Comments:
-- ##socket_list## is a sequence of 2-element sequences.  Each inner sequence
-- contains the socket number, and the flags of what to check for.
--
-- Special values for ##timeout## are  0 returns immediately, -1 returns only when an event occurs.
--
-- Another common socket querying routine, select(), is not supported
-- in this library.  Poll() provides the same functionality more
-- reliably.
--
-- Especially in Windows applications, it is the responsibility of the
-- calling application to cancel polling events when they are no
-- longer needed.  Failure to do say may result in memory leaks.
-- Cross-platform applications should cancel the polling events,
-- though the cancellation request is ignored on Linux (events are
-- implicitly cancelled at the end of the poll).  To keep the
-- returned sequence synchronized, it is best to separate polling
-- calls from cancellation calls, even though both may be done in
-- a single call.
--
-- Example 1:
-- <eucode>
-- rtn = poll( {{socket1,POLLIN+POLLOUT+POLLERR},
--             {socket2,POLLIN+POLLERR},
--             {socket3,POLLOUT+POLLERR}}, 500)
--
-- if atom(rtn) then
--     puts(1,"No traffic yet.\n")
-- else
--     puts(1,"The following events have occured:\n")
--     printf(1,"Socket1: %d, Socket2: %d, Socket3: %d\n",rtn)
--     -- Cancel polling events
--     rtn = poll( {{socket1,0},{socket2,0},{socket3,0}}, 0)
-- end if
-- </eucode>
--
-- Example 2:
-- <eucode>
-- bytes_tx = 0
-- sock_data = ""
--
-- while 1 do
--     ignore = poll({{sock,POLLIN}},250)
--     -- Give the server time to respond, but the value can be adjusted.
--     if sequence(ignore) then
--         sock_data = sock_data & recv(sock,0)
--     elsif bytes_tx > 0 then
--        exit
--        -- We've received some data, and there's
--        -- nothing left on the socket.
--     end if
--     bytes_tx = length(sock_data)
-- end while
-- puts(1, sock_data)
-- </eucode>

public function poll(sequence socket_list, atom timeout)
	ifdef WIN32 then
		return windows_poll(socket_list,timeout)
	elsifdef UNIX then
		return unix_poll(socket_list,timeout)
	end ifdef
	
	return -1
end function

--**
-- Send TCP data to a socket connected remotely.
--
-- Parameters:
--   # ##socket##: an atom, the socket id
--   # ##data##: a sequence of atoms, what to send
--   # ##flags##: an atom,
--
-- Returns:
--   An **integer**, the number of characters sent, or -1 for an error.
--

public function send(atom socket, sequence data, atom flags=0)
	return machine_func(M_SOCK_SEND, { socket, data, flags })
end function

-------------------------------------------------------------------------------
-- Sendto (good for stateless / broadcast datagrams)
-------------------------------------------------------------------------------
-- Returns the # of chars sent, or -1 for error

function unix_sendto(atom socket, sequence data, atom flags, sequence inet_addr)
	atom dataptr, datalen, sockaddr
	atom status
	sockaddr = make_sockaddr(inet_addr)
	datalen = length(data)
	dataptr = allocate(datalen+1)
	poke(dataptr,data&0)
	status = c_func(sendto_,{socket,dataptr,datalen,flags,sockaddr,16})
	free(sockaddr)
	free(dataptr)
	return status
end function

function windows_sendto(atom socket, sequence data, atom flags, sequence inet_addr)
	-- Windows does sendto the same as Linux
	return unix_sendto(socket,data,flags,inet_addr)
end function

--**
-- Send data to either a connected or unconnected socket.
--
-- Parameters:
--   # ##socket##: an atom, the socket id
--   # ##data##: a sequence of atoms, what to send
--   # ##flags##: an atom,
--   # ##inet_addr##: a sequence representing an IP address
--
-- Returns:
--   An **integer**, the number of characters sent, or -1 for an error.

public function sendto(atom socket, sequence data, atom flags, sequence inet_addr)
	ifdef WIN32 then
		return windows_sendto(socket,data,flags,inet_addr)
	elsifdef UNIX then
		return unix_sendto(socket,data,flags,inet_addr)
	end ifdef
	
	return -1
end function

--**
-- Receive data from a bound socket. 
--
-- Parameters:
--   # ##socket##: an atom, the socket id
--   # ##flags##: an atom,
--
-- Returns:     
--   A **sequence**, either a full string of data on success, or an atom indicating
--   the error code.
--
-- Comments:
-- This function will not return until data is actually received on the socket,
-- unless the flags parameter contains MSG_DONTWAIT.
--
-- MSG_DONTWAIT only works on Linux kernels 2.4 and above.  Similar
-- functionality is not available in Windows.  The only way to set
-- up a non-blocking polling loop on Windows is to use poll().
--

public function recv(atom socket, atom flags=0)
	return machine_func(M_SOCK_RECV, { socket, flags })
end function

-------------------------------------------------------------------------------
-- recvfrom (for unconnected sockets)
-------------------------------------------------------------------------------
-- Returns a sequence {sequence data, {atom error_number, sequence error_string}, string peer_address}
function unix_recvfrom(atom socket, atom flags)
	atom buf, buflen, rtnlen, sockaddr
	sequence rtndata, peer_addr, errno
	
	buflen = BLOCK_SIZE
	buf = allocate(buflen)
	sockaddr = allocate(20)
	poke4(sockaddr,16)
	rtnlen = c_func(recvfrom_,{socket,buf,buflen,flags,sockaddr+4,sockaddr})
	errno = get_error()
	
	if not find(errno[1],{EAGAIN,EBADF,EWOULDBLOCK,ECONNRESET,EFAULT,EINTR,EINVAL,EIO,ENOBUFS,ENOMEM,
			ENOSR,ENOTCONN,ENOTSOCK,EOPNOTSUPP,ETIMEDOUT}) then
		-- Only these errors are thrown by recvfrom.  Any other error is from a different function call.
		errno = {0,""}
	end if
	
	peer_addr = get_sockaddr(sockaddr+4)
	free(sockaddr)
	
	if rtnlen < 0 then
		free(buf)
		return {{},errno,peer_addr}
	end if
	
	rtndata = peek({buf,rtnlen})
	free(buf)
	
	return {rtndata,errno,peer_addr}
end function

function windows_recvfrom(atom socket, atom flags)
	-- Windows does recvfrom the same as Linux
	return unix_recvfrom(socket,flags)
end function

--**
-- Receive data from either a bound or unbound socket.
--
-- Parameters:
--   # ##socket##: an atom, the socket id
--   # ##flags##: an atom,
--
-- Returns:
--   A **sequence** as follows:
-- <eucode>
-- s = {
--     sequence data,
--     {atom error_number, sequence error_string},
-- 	    sequence peer_address
-- }
-- </eucode>
--
-- Here, ##peer_address## is the same string format used when passing an
-- internet address to a function, and can be used as is in
-- [[:sendto]]().
--
-- Comments:
-- This function will not return until data is actually received on
-- the socket, unless the flags parameter contains MSG_DONTWAIT.
--
-- Example 1:
-- <eucode>
-- t1 = time()
-- t2 = t1
-- while t2 < t1+15 and recvdata[2][1]=EAGAIN do
--     recvdata = recvfrom(socket,MSG_DONTWAIT)
--     if length(recvdata[1])>0 then
--         msg = msg & recvdata[1]
--         lastpeer = recvdata[3]
--         t1 = t1 - 60
--         recvdata = {"",{EAGAIN,""},""}
--     elsif recvdata[2][1] != EAGAIN then
--         puts(1,"Error: "&recvdata[2][2]&"\n")
--     end if
--     t2 = time()
-- end while
-- puts(1,sprintf("%d: ",cycle)&lastpeer&":  "&msg&'\n')
-- </eucode>

public function recvfrom(atom socket, atom flags)
	ifdef WIN32 then
		return windows_recvfrom(socket, flags)
	elsifdef UNIX then
		return unix_recvfrom(socket,flags)
	end ifdef

	return -1
end function

--**
-- Get options for a socket.
-- 
-- Parameters:
--   # ##socket##: an atom, the socket id
--   # ##level##: an integer, the option level
--   # ##optname##: a string with the name of the requested option
--
-- Returns:
--   An **object**, either:
-- * On error, {"ERROR",error_code}.  
-- * On success, either an atom or a sequence containing the option value, depending on the option.
--
-- Comments:
-- Primarily for use in multicast or more advanced socket
-- applications.  Level is the option level, and option_name is the
-- option for which values are being sought. Level is usually
-- SOL_SOCKET (#FFFF).
--
-- Returns:
--   On error, an atom indicating the error code.  On success, either an atom or
--   a sequence containing the option value.
--
-- See also:
--   [[:set_socket_options]]

public function get_socket_options(atom socket, integer level, integer optname)
	return machine_func(M_SOCK_GETSOCKOPT, { socket, level, optname })
end function

--**
-- Set options for a socket.
-- 
-- Parameters:
--   # ##socket##: an atom, the socket id
--   # ##level##: an integer, the option level
--   # ##optname##: a string with the name of the requested option
--   # ##val##: an object, the new value for the option
--
-- Returns:
--   An **integer**, 0 on success, -1 on error.
--
-- Comments:
--
-- Primarily for use in multicast or more advanced socket
-- applications.  Level is the option level, and option_name is the
-- option for which values are being set.  Level is usually
-- SOL_SOCKET (#FFFF).
--
-- See Also:
--    [[:get_socket_options]]

public function set_socket_options(atom socket, integer level, integer optname, object val)
	return machine_func(M_SOCK_SETSOCKOPT, { socket, level, optname, val })
end function

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

