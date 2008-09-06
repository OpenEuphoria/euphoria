-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Internet Sockets
--
-- Based on EuNet project, version 1.3.2, at SourceForge.
-- http://www.sourceforge.net/projects/eunet.
--
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>
 
include std/dll.e
include std/machine.e
include std/get.e
include std/wildcard.e
include std/text.e
include std/memory.e
--****
-- === Constants
--

--**
-- getaddrinfo accessors

public enum ADDR_FLAGS, ADDR_FAMILY, ADDR_TYPE, ADDR_PROTOCOL, ADDR_ADDRESS

--**
-- Socket types

public constant AF_INET = 2, SOCK_STREAM=1, SOCK_DGRAM = 2, SOCK_RAW = 3,
	SOCK_RDM = 4, SOCK_SEQPACKET = 5

--**
-- RFC 1700	

public constant
	IPPROTO_IP = 0,
	IPPROTO_ICMP = 1,
	IPPROTO_TCP = 6,
	IPPROTO_EGP = 8,
	IPPROTO_PUP = 12,
	IPPROTO_UDP = 17,
	IPPROTO_IDP = 22,
	IPPROTO_TP = 29,
	IPPROTO_EON = 80,
	IPPROTO_RM = 113

public constant
	SOL_SOCKET = #FFFF,
		
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
	
	NS_C_IN = 1,
	NS_C_ANY = 255,
	NS_KT_RSA = 1,
	NS_KT_DH = 2,
	NS_KT_DSA = 3,
	NS_KT_PRIVATE = 254,
	NS_T_A = 1,
	NS_T_NS = 2,
	NS_T_PTR = 12,
	NS_T_MX = 15,
	NS_T_AAAA = 28, -- deprecated
	NS_T_A6 = 38,
	NS_T_ANY = 255,
	
	DNS_QUERY_STANDARD = 0,
	DNS_QUERY_ACCEPT_TRUNCATED_RESPONSE = 1,
	DNS_QUERY_USE_TCP_ONLY = 2,
	DNS_QUERY_NO_RECURSION = 4,
	DNS_QUERY_BYPASS_CACHE = 8,
	DNS_QUERY_NO_WIRE_QUERY = 16,
	DNS_QUERY_NO_LOCAL_NAME = 32,
	DNS_QUERY_NO_HOSTS_FILE = 64,
	DNS_QUERY_NO_NETBT = 128,
	DNS_QUERY_WIRE_ONLY = 256,
	DNS_QUERY_RETURN_MESSAGE = 512,
	DNS_QUERY_TREAT_AS_FQDN = #1000,
	DNS_QUERY_DONT_RESET_TTL_VALUES = #100000,
	DNS_QUERY_RESERVED = #FF000000,
	
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

atom dll_, ipdll_, sockdll_, kerneldll_, dnsdll_,
	wsastart_, wsacleanup_, wsawaitformultipleevents_,
	wsacreateevent_, wsaeventselect_, wsaenumnetworkevents_, wsacloseevent_,
	ioctl_, socket_, bind_, connect_, listen_, accept_,
	send_, sendto_, sendmsg_, recv_, recvfrom_, recvmsg_,
	poll_, close_, shutdown_,
	getsockopts_, setsockopts_,
	getiftable_, dnsquery_, dnsrlfree_, dnsexpand_,
	gethostbyname_, getservbyname_, getaddrinfo_, freeaddrinfo_,
	--     read_, write_, getsockname_, getpeername_,
	error_, delay_

sequence windows_poll_seq, this_cookiejar, sendheader, recvheader
windows_poll_seq = {}
this_cookiejar = {}
sendheader = {}  -- HTTP header sequence , sent to somewhere (usually the server)
recvheader = {}  -- HTTP header sequence , received from somewhere (usually the server)

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
	socket_ = define_c_func(sockdll_,"socket",{C_INT,C_INT,C_INT},C_INT)
	getiftable_ = define_c_func(ipdll_,"GetAdaptersInfo",{C_POINTER,C_POINTER},C_LONG)
	bind_ = define_c_func(sockdll_,"bind",{C_INT,C_POINTER,C_INT},C_INT)
	connect_ = define_c_func(sockdll_,"connect",{C_INT,C_POINTER,C_INT},C_INT)
	poll_ = define_c_func(sockdll_,"WSAPoll",{C_POINTER,C_INT,C_INT},C_INT)
	listen_ = define_c_func(sockdll_,"listen",{C_INT,C_INT},C_INT)
	--  accept_ = define_c_func(sockdll_,"accept",{C_INT,C_POINTER,C_POINTER},C_INT)
	accept_ = define_c_func(sockdll_,"WSAAccept",{C_INT,C_POINTER,C_POINTER,C_POINTER,C_INT},C_INT)
	socket_ = define_c_func(sockdll_,"socket",{C_INT,C_INT,C_INT},C_INT)
	ioctl_ = define_c_func(sockdll_,"ioctlsocket",{C_INT,C_INT,C_POINTER},C_INT)
	getsockopts_ = define_c_func(sockdll_,"getsockopt",{C_INT,C_INT,C_INT,C_POINTER,C_POINTER},C_INT)
	setsockopts_ = define_c_func(sockdll_,"setsockopt",{C_INT,C_INT,C_INT,C_POINTER,C_INT},C_INT)
	send_ = define_c_func(sockdll_,"send",{C_INT,C_POINTER,C_INT,C_INT},C_INT)
	sendto_ = define_c_func(sockdll_,"sendto",{C_INT,C_POINTER,C_INT,C_INT,C_POINTER,C_INT},C_INT)
	sendmsg_ = define_c_func(sockdll_,"sendmsg",{C_INT,C_POINTER,C_INT},C_INT)
	recv_ = define_c_func(sockdll_,"recv",{C_INT,C_POINTER,C_INT,C_INT},C_INT)
	recvfrom_ = define_c_func(sockdll_,"recvfrom",{C_INT,C_POINTER,C_INT,C_INT,C_POINTER,C_POINTER},C_INT)
	recvmsg_ = define_c_func(sockdll_,"recvmsg",{C_INT,C_POINTER,C_INT},C_INT)
	close_ = define_c_func(sockdll_,"closesocket",{C_INT},C_INT)
	shutdown_ = define_c_func(sockdll_,"shutdown",{C_INT,C_INT},C_INT)
	gethostbyname_ = define_c_func(sockdll_,"gethostbyname",{C_POINTER},C_POINTER)
	getservbyname_ = define_c_func(sockdll_,"getservbyname",{C_POINTER,C_POINTER}, C_POINTER)
	getaddrinfo_ = define_c_func(sockdll_,"getaddrinfo",{C_POINTER,C_POINTER,C_POINTER,C_POINTER},C_INT)
	freeaddrinfo_ = define_c_proc(sockdll_,"freeaddrinfo",{C_POINTER})
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
	dnsquery_ = define_c_func(dnsdll_,"DnsQuery_A",{C_POINTER,C_USHORT,C_INT,C_POINTER,C_POINTER,C_POINTER},C_INT)
	dnsrlfree_ = define_c_proc(dnsdll_,"DnsRecordListFree",{C_POINTER,C_INT})
elsifdef LINUX then
	dll_ = open_dll("") -- libc
	dnsdll_ = open_dll("libresolv.so")
elsifdef FREEBSD then
	dll_ = open_dll("libc.so")
	dnsdll_ = open_dll("libresolv.so")
elsifdef OSX then
	dll_ = open_dll("libc.dylib")
	dnsdll_ = open_dll("libresolv.dylib")
end ifdef

ifdef UNIX then
	error_ = define_c_func(dll_,"__errno_location",{},C_INT)
	ioctl_ = define_c_func(dll_,"ioctl",{C_INT,C_INT,C_INT},C_INT)
	socket_ = define_c_func(dll_,"socket",{C_INT,C_INT,C_INT},C_INT)
	getsockopts_ = define_c_func(dll_,"getsockopt",{C_INT,C_INT,C_INT,C_POINTER,C_POINTER},C_INT)
	setsockopts_ = define_c_func(dll_,"setsockopt",{C_INT,C_INT,C_INT,C_POINTER,C_INT},C_INT)
	bind_ = define_c_func(dll_,"bind",{C_INT,C_POINTER,C_INT},C_INT)
	connect_ = define_c_func(dll_,"connect",{C_INT,C_POINTER,C_INT},C_INT)
	poll_ = define_c_func(dll_,"poll",{C_POINTER,C_INT,C_INT},C_INT)
	listen_ = define_c_func(dll_,"listen",{C_INT,C_INT},C_INT)
	accept_ = define_c_func(dll_,"accept",{C_INT,C_POINTER,C_POINTER},C_INT)
	send_ = define_c_func(dll_,"send",{C_INT,C_POINTER,C_INT,C_INT},C_INT)
	sendto_ = define_c_func(dll_,"sendto",{C_INT,C_POINTER,C_INT,C_INT,C_POINTER,C_INT},C_INT)
	sendmsg_ = define_c_func(dll_,"sendmsg",{C_INT,C_POINTER,C_INT},C_INT)
	recv_ = define_c_func(dll_,"recv",{C_INT,C_POINTER,C_INT,C_INT},C_INT)
	recvfrom_ = define_c_func(dll_,"recvfrom",{C_INT,C_POINTER,C_INT,C_INT,C_POINTER,C_POINTER},C_INT)
	recvmsg_ = define_c_func(dll_,"recvmsg",{C_INT,C_POINTER,C_INT},C_INT)
	close_ = define_c_func(dll_,"close",{C_INT},C_INT)
	shutdown_ = define_c_func(dll_,"shutdown",{C_INT,C_INT},C_INT)
	gethostbyname_ = define_c_func(dll_,"gethostbyname",{C_POINTER},C_POINTER)
	getservbyname_ = define_c_func(dll_,"getservbyname",{C_POINTER,C_POINTER}, C_POINTER)
	getaddrinfo_ = define_c_func(dll_,"getaddrinfo",{C_POINTER,C_POINTER,C_POINTER,C_POINTER},C_INT)
	freeaddrinfo_ = define_c_proc(dll_,"freeaddrinfo",{C_POINTER})
	delay_ = define_c_func(dll_,"nanosleep",{C_POINTER,C_POINTER},C_INT)
	dnsquery_ = define_c_func(dnsdll_,"res_query",{C_POINTER,C_INT,C_INT,C_POINTER,C_INT},C_INT)
	dnsexpand_ = define_c_func(dnsdll_,"dn_expand",{C_POINTER,C_POINTER,C_POINTER,C_POINTER,C_INT},C_INT)
end ifdef

-------------------------------------------------------------------------------

function trim_(sequence s)
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

function get_string(atom lpsz)
	
	atom ptr, c
	sequence s
	s = ""
	if lpsz = 0 then
		return s
	end if
	ptr = 0
	c = peek(lpsz+ptr)
	while c != 0 do
		s = s & c
		ptr = ptr + 1
		c = peek(lpsz+ptr)
	end while
	return s
	
end function

-------------------------------------------------------------------------------

function get_sockaddr(atom lpsz)
	
	sequence s
	atom port
	s = ""
	if lpsz = 0 then  -- Null pointer
		return s
	end if
	-- sockaddr
	-- 2bytes: AF_INET (or other type)
	-- 2bytes: port
	-- 4bytes: network address
	-- 8bytes: null
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

-------------------------------------------------------------------------------
--****
-- === Support routines
--

--**
-- Checks if x is an IP address in the form (#.#.#.#[:#])
--
-- Parameters:
--		# ##x##: the address to check
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
--		# ##mode##: an integer, either EUNET_ERRORMODE_EUNET or EUNET_ERRORMODE_OS.
--
-- Comments:
--	The errors returned will either be generated
-- by the kernel (OS) or massaged by the library for cross-platform
-- compatibility (EUNET).

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
--		A **sequence** of length 2, made of an integer, the error code, and the error string.
--
-- Comments:
-- If error mode is EUNET_ERRORMODE_EUNET, the error codes will be one of . . .
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
			else
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
--		# ##millisec##: an atom, the number of 1/1000 seconds to wait.
--
-- Returns:
--     0 for success, -1 for error.
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
	
	atom result, timptr
	
	ifdef WIN32 then
		c_proc(delay_,{millisec})
		return 0
	elsifdef UNIX then
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

-- Andy Serpa's Turbo version
-- c = "object" by Kat ; modded and used in strtok.e
-- c can now be a list {'z','\n','etc'} and s will be parsed by all those in list
-- made case insensitive by Kat
-- mod'd again for eunet
function eunet_parse(sequence s, object c)
	
	integer slen, spt, flag
	sequence parsed, upperc, uppers
	
	upperc = ""
	uppers = ""
	
	if atom(c) -- kat
			then c = {c}
	end if
	
	parsed = {}
	slen = length(s)
	spt = 1
	flag = 0
	
	upperc = upper(c)
	uppers = upper(s)
	for i = 1 to slen do
		if find(uppers[i],upperc) then
			if flag = 1 then
				parsed = append(parsed,s[spt..i-1])
				flag = 0
				spt = i+1
			else
				spt += 1
			end if
		else
			flag = 1
		end if
	end for
	if flag = 1 then
		parsed = append(parsed,s[spt..slen])
	end if
	
	return parsed
	
end function

-------------------------------------------------------------------------------
-- Get list of networking interfaces
-------------------------------------------------------------------------------
--****
-- === Network interface availability
--

function windows_get_adapters_table()
	
	atom iftable, status
	atom iftablesize, ptr
	sequence ifaces, row, breadcrumbs
	ifaces = {}
	iftable = allocate((640*1)+4) -- The records are a singly linked list
	poke4(iftable,644)
	status = c_func(getiftable_,{iftable+4,iftable})
	if status != 0 then
		iftablesize = peek4u(iftable)
		free(iftable)
		iftable = allocate(iftablesize+4)
		poke4(iftable,iftablesize)
		status = c_func(getiftable_,{iftable+4,iftable})
		if status !=0 then
			free(iftable)
			return {}
		end if
	end if
	iftablesize = peek4u(iftable)
	breadcrumbs = {iftable+4}
	ptr = iftable+4
	while ptr!=0 do
		breadcrumbs = append(breadcrumbs,peek4u(ptr))
		row = {"","","",0,0,"",""}
		row[1] = trim_(peek({ptr+8,256}))     -- Adapter name
		row[2] = trim_(peek({ptr+268,128}))   -- Adapter description
		row[3] = peek({ptr+404,peek4u(ptr+400)})  -- HW address (not a string)
		row[4] = peek4u(ptr+412)     -- Index
		row[5] = peek4u(ptr+416)     -- Type
		-- If there is more than one IP address on an adapter, it can be discovered
		-- by peek(peek4u(ptr+428)+4,16).  The first 4 bytes of IP_ADDR_STRING are
		-- a pointer to the next IP_ADDR_STRING struct.
		row[6] = trim_(peek({ptr+432,16})) -- Current IP address (string)
		row[7] = trim_(peek({ptr+448,16})) -- Netmask (string)
		ifaces = append(ifaces,row)
		ptr = breadcrumbs[length(breadcrumbs)]
	end while
	free(iftable)
	return ifaces
	
end function

-------------------------------------------------------------------------------
-- Returns sequence of interface names
function unix_get_iface_list()
	sequence ifaces
	atom cpos
	object row
	atom fn
	fn = open("/proc/net/dev","r")
	ifaces = {}
	row = gets(fn)
	while sequence(row) do
		if length(row)>1 then
			cpos = find(':',row)
			if cpos > 0 then
				ifaces = append(ifaces,trim_(row[1..cpos-1]))
			else
				ifaces = append(ifaces,trim_(row))
			end if
		end if
		row = gets(fn)
	end while
	close(fn)
	if length(ifaces)>=3 then
		ifaces = ifaces[3..length(ifaces)]
	end if
	
	return ifaces
	
end function

function windows_get_iface_list()
	sequence ifaces, rtn
	ifaces = windows_get_adapters_table()
	rtn = {}
	for ctr = 1 to length(ifaces) do
		rtn = append(rtn,ifaces[ctr][2])
	end for
	
	return rtn
end function

--**
-- Returns a list of network interface names.

public function get_iface_list()
	ifdef WIN32 then
		return windows_get_iface_list()
	elsifdef UNIX then
		return unix_get_iface_list()
	else
		return {}
	end ifdef
end function

-------------------------------------------------------------------------------
-- Get networking interface details
-------------------------------------------------------------------------------
-- returns a sequence of details as:
-- {seq InterfaceName, int index, int flags, seq MACaddr, int metric, int mtu, int serial_outfill,
	--  int serial_keepalive, seq if_map, int tx_Q_len, seq IP_addr, seq PPP_Dest_IP_addr,
	--  seq IP_Bcast_addr, seq IP_Netmask, seq stats}
--  Note: if PPP_Dest_IP_addr = IP_addr, serial_keepalive will be the up/down status of the address

function windows_get_iface_details(sequence iface_name)
	
	sequence row, list, list2
	atom iptable, tblptr, getipaddrtable_, status, sz
	
	list = windows_get_adapters_table()
	iptable = allocate(24+(24*(length(list)+1)))
	poke4(iptable,(20+(24*(length(list)+1))))
	getipaddrtable_ = define_c_func(ipdll_,"GetIpAddrTable",{C_POINTER,C_POINTER,C_INT},C_INT)
	status = c_func(getipaddrtable_,{iptable+4,iptable,0})
	if status != 0 then
		sz = peek4u(iptable+8)
		free(iptable)
		iptable = allocate(sz+24)
		poke4(iptable,sz+20)
		status = c_func(getipaddrtable_,{iptable+4,iptable,0})
		if status != 0 then
			free(iptable)
			return {}
		end if
	end if
	list2 = {}
	sz = peek4u(iptable+4)
	tblptr = iptable+8
	for ctr = 1 to sz do
		row = {sprintf("%d.%d.%d.%d",peek({tblptr,4})),  -- IP address
			peek4u(tblptr+4),                         -- Index
			sprintf("%d.%d.%d.%d",peek({tblptr+8,4})),   -- Netmask
			sprintf("%d.%d.%d.%d",256+or_bits(peek({tblptr,4}),not_bits(peek({tblptr+8,4})))),  -- Broadcast
			-- a bug (or undefined parameter) in or_bits(not_bits) throws the result into negative numbers.
		-- Adding 256 to the sequence gives us what we're really looking for.
		peek4u(tblptr+16),                           -- Reassemble size
			peek(tblptr+22)}                             -- IP type
		tblptr = tblptr + 24
		list2 = append(list2,row)
	end for
	free(iptable)
	
	for ctr = 1 to length(list) do
		if eu:compare(iface_name,list[ctr][2])=0 then
			row = {list[ctr][2],list[ctr][4],0,"",0,0,0,0,{},0,list[ctr][6],"","",list[ctr][7],{}}
			for ctr2 = 1 to length(list2) do
				if eu:compare(list2[ctr2][2],list[ctr][4])=0 then -- matching index
					row[4] = ""
					for ctr3 = 1 to length(list[ctr][3]) do
						row[4] = row[4] & sprintf("%02x:",list[ctr][3][ctr3])
					end for
					row[4] = row[4][1..length(row[4])-1]
					row[8] = list2[ctr2][6]
					row[11] = list2[ctr2][1]
					row[12] = row[11]
					row[13] = list2[ctr2][4]
					row[14] = list2[ctr2][3]
					return row
				end if
			end for
		end if
	end for
	
	return {}
	
end function

function unix_get_iface_details(sequence iface_name)
	sequence details
	atom ifreq, sockid, status
	
	--{#8910,#8913,#8927,#891d,#8921,?,?,#8970,#8942,#8915,#8917,#8919,#891b,?}
	details = {iface_name,0,0,"",0,0,0,0,{},0,"","","","",{}}
	ifreq = allocate(200)
	sockid = c_func(socket_,{AF_INET,SOCK_DGRAM,0})
	if sockid < 0 then
		free(ifreq)
		return {}
	end if
	poke(ifreq,iface_name&0)
	status = c_func(ioctl_,{sockid,#8913,ifreq}) -- Flags
	if status >= 0 then
		details[3] = peek(ifreq+16)+(256*peek(ifreq+17))
	end if
	status = c_func(ioctl_,{sockid,#8927,ifreq}) -- HW Address
	if status >= 0 then
		--details[4] = get_sockaddr(ifreq+16)
		details[4] = ""
		for ctr = 18 to 25 do
			details[4] = details[4] & sprintf("%02x:",peek(ifreq+ctr))
		end for
		details[4] = details[4][1..length(details[4])-1]
	end if
	status = c_func(ioctl_,{sockid,#891D,ifreq}) -- metric
	if status >= 0 then
		details[5] = peek4u(ifreq+16)
	end if
	status = c_func(ioctl_,{sockid,#8921,ifreq}) -- mtu
	if status >= 0 then
		details[6] = peek4u(ifreq+16)
	end if
	status = c_func(ioctl_,{sockid,#8942,ifreq}) -- transmit queue length
	if status >= 0 then
		details[10] = peek4u(ifreq+16)
	end if
	status = c_func(ioctl_,{sockid,#8915,ifreq}) -- IP address
	if status >= 0 then
		details[11] = get_sockaddr(ifreq+16)
	end if
	status = c_func(ioctl_,{sockid,#8917,ifreq}) -- PPP destination IP address
	if status >= 0 then
		details[12] = get_sockaddr(ifreq+16)
	end if
	status = c_func(ioctl_,{sockid,#8919,ifreq}) -- Broadcast address
	if status >= 0 then
		details[13] = get_sockaddr(ifreq+16)
	end if
	status = c_func(ioctl_,{sockid,#891B,ifreq}) -- Netmask
	if status >= 0 then
		details[14] = get_sockaddr(ifreq+16)
	end if
	
	return details
	
end function

--**
-- Given a network interface name returned by [[:get_iface_list]](),
-- returns a sequence of details about that interface.
--
-- Parameters:
-- 		# ##iface_name##: a string, a network interface name
--
-- Returns:
--		A **sequence** of details about the interface. Its layout is as follows:
--
-- <eucode>
-- s = {
-- sequence InterfaceName,
-- integer index,
-- integer flags,
-- sequence MAC_address,
-- integer metric,
-- integer mtu,
-- integer serial_outfill,
-- integer serial_keepalive,
-- sequence interface_map,
-- integer transmit_queue_length,
-- sequence IP_address,
-- sequence PPP_Destination_IP_address,
-- sequence IP_broadcast_address,
-- sequence IP_Netmask,
-- sequence stats }
-- </eucode>
--
-- Comments:
--    If PPP_Dest_IP_addr = IP_addr, serial_keepalive will be the
--    up/down status of the address.

public function get_iface_details(sequence iface_name)
	ifdef WIN32 then
		return windows_get_iface_details(iface_name)
	elsifdef UNIX then
		return unix_get_iface_details(iface_name)
	end ifdef
	
	return {}
end function

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Server-side sockets (bind, listeners, signal hooks, accepters)
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

--****
-- === Socket routines - server side
--

-------------------------------------------------------------------------------
-- Bind
-------------------------------------------------------------------------------
-- Bind is typically used in TCP and SOCK_STREAM connections.
-- It returns 0 on success and -1 on failure.
function unix_bind(atom socket, sequence inet_addr)
	atom sockaddr
	sockaddr = make_sockaddr(inet_addr)
	if sockaddr = 0 then
		return -1
	end if
	return c_func(bind_,{socket,sockaddr,16})
end function

function windows_bind(atom socket, sequence inet_addr)
	-- Windows does bind the same as Linux
	return unix_bind(socket,inet_addr)
end function

--**
-- Joins a socket to a specific local internet address and port so
-- later calls only need to provide the socket. 
--
-- Parameters:
--		# ##socket##: an atom, the socket id
--		# ##inet_addr##: a sequence, the address to bind the socket to
--
-- Returns 
--		An **integer**, 0 on success and -1 on failure.
--
-- Example 1:
-- <eucode>
-- success = bind(socket, "0.0.0.0:8080")
-- -- Look for connections on port 8080 for any interface.
-- </eucode>

public function bind(atom socket, sequence inet_addr)
	ifdef WIN32 then
		return windows_bind(socket,inet_addr)
	elsifdef UNIX then
		return unix_bind(socket,inet_addr)
	end ifdef
	
	return -1
end function

-------------------------------------------------------------------------------
-- Listen
-------------------------------------------------------------------------------
-- Listen is typically used in TCP and SOCK_STREAM connections.
-- It returns 0 on success and error_code on failure.
function unix_listen(atom socket, integer pending_conn_len)
	return c_func(listen_,{socket,pending_conn_len})
end function

function windows_listen(atom socket, integer pending_conn_len)
	-- Windows does listen the same as Linux
	return unix_listen(socket,pending_conn_len)
end function

--**
-- Start monitoring a connection. Only works with TCP sockets.
--
-- Parameters:
--		# ##socket##: an atom, the socket id
--		# ##pending_conn_len##: an integer, the number of connection requests that
-- can be kept waiting before the OS refuses to hear any more.
--
-- Returns:
--    An **integer**, 0 on success and an error code on failure.
--
-- Comments:
-- This function is used in a program that will be receiving
-- connections.
--
-- The value of ##pending_conn_len## is strongly dependent on both the hardware and the
-- amount of time it takes the program to process each connection
-- request. 
--
-- This function must be executed after [[:bind]]().

public function listen(atom socket, integer pending_conn_len)
	ifdef WIN32 then
		return windows_listen(socket, pending_conn_len)
	elsifdef UNIX then
		return unix_listen(socket, pending_conn_len)
	end ifdef
	
	return -1
end function

-- Accept: Returns {atom new_socket, sequence peer_ip_addres} on success, or
-- -1 on error.

function unix_accept(atom socket)
	
	atom sockptr, result
	sequence peer
	
	sockptr = allocate(20)
	poke4(sockptr,16)
	for ctr = 4 to 16 by 4 do
		poke4(sockptr+ctr,0)
	end for
	result = c_func(accept_,{socket,sockptr+4,sockptr})
	if result < 0 then
		free(sockptr)
		return -1
	end if
	peer = get_sockaddr(sockptr+4)
	free(sockptr)
	return {result,peer}
	
end function

function windows_accept(atom socket)
	
	atom sockptr, result
	sequence peer
	
	sockptr = allocate(20)
	poke4(sockptr,16)
	for ctr = 4 to 16 by 4 do
		poke4(sockptr+ctr,0)
	end for
	result = c_func(accept_,{socket,sockptr+4,sockptr,0,0})
	if result < 0 then
		free(sockptr)
		return -1
	end if
	peer = get_sockaddr(sockptr+4)
	free(sockptr)
	return {result,peer}
	
end function

--**
-- Produces a new socket for an incoming connection.
--
-- Parameters:
--		# ##socket##: an atom, the side connection socket id
--
-- Returns:
--     An **object**, either -1 on failure, or a sequence {atom new_socket, sequence peer_ip_address} on success.
--
-- Comments:
-- Using this function allows
-- communication to occur on a "side channel" while the main server
-- socket remains available for new connections. 
--
-- ##accept##() must be called after ##bind##() and ##listen##().
--
-- On failure, use [[:get_error]] to determine the cause of the failure.
--

public function accept(atom socket)
	ifdef WIN32 then
		return windows_accept(socket)
	elsifdef UNIX then
		return unix_accept(socket)
	end ifdef
	
	return -1
end function

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Client-side sockets (connect)
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--****
-- === Socket routines - client side

-- Returns 0 on success and -1 on failure

function unix_connect(atom socket, sequence inet_addr)
	atom sockaddr
	sockaddr = make_sockaddr(inet_addr)
	if sockaddr = 0 then
		return -1
	end if
	return c_func(connect_,{socket,sockaddr,16})
end function


function windows_connect(atom socket, sequence inet_addr)
	-- Windows connect works the same as Linux
	return unix_connect(socket,inet_addr)
end function

--**
-- Establish an outgoing connection to a remote computer. Only works with TCP sockets.
--
-- Parameters:
--		# ##socket##: an atom, the socket id
--		# ##inet_addr##: a sequence, the address to bind the socket to
--
-- Returns 
--		An **integer**, 0 for success and -1 on failure.
--
-- Comments:
--	##inet_address## should contain both the IP address and port of the remote listening socket as a string.
--
-- Example 1:
-- <eucode>
-- success = connect(socket, "11.1.1.1:80")
-- </eucode>

public function connect(atom socket, sequence inet_addr)
	ifdef WIN32 then
		return windows_connect(socket,inet_addr)
	elsifdef UNIX then
		return unix_connect(socket,inet_addr)
	end ifdef
	
	return -1
end function

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Routines for both server & client (socket, read, write, select)
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--****
-- === Socket routines - both sides
--

-------------------------------------------------------------------------------
-- New socket
-------------------------------------------------------------------------------

function unix_new_socket(integer family, integer sock_type, integer protocol)
	return c_func(socket_,{family,sock_type,protocol})
end function

function windows_new_socket(integer family, integer sock_type, integer protocol)
	-- Windows does socket the same as Linux
	return unix_new_socket(family,sock_type,protocol)
end function

--**
-- Returns a handle to a newly created socket.
--
-- Parameters:
--		# ##family##: an integer
--		# ##sock_type##: an integer, the type of socket to create
--		# ##protocol##: an integer, the communication protocol being used
--
-- Returns:
--		An **atom**, -1 on failure, else a supposedly valid socket id.
--
-- Example 1:
-- <eucode>
-- socket = new_socket(AF_INET, SOCK_STREAM, 0)
-- </eucode>

public function new_socket(integer family, integer sock_type, integer protocol)
	ifdef WIN32 then	
		return windows_new_socket(family,sock_type,protocol)
	elsifdef UNIX then
		return unix_new_socket(family,sock_type,protocol)
	end ifdef
	
	return -1
	
end function

-------------------------------------------------------------------------------
-- Close socket
-------------------------------------------------------------------------------

function unix_close_socket(atom socket)
	return c_func(close_,{socket})
end function

function windows_close_socket(atom socket)
	return c_func(close_,{socket})
end function

--**
-- Closes a socket.
--
-- Parameters:
--		# ##socket##: an atom, the socket to close
--
-- Returns:
--		An **integer**, 0 on success and -1 on error. 
--
-- Comments:
-- It may take several minutes for the OS to declare the socket as closed.
-- 

public function close_socket(atom socket)
	ifdef WIN32 then
		return windows_close_socket(socket)
	elsifdef UNIX then
		return unix_close_socket(socket)
	end ifdef
	
	return -1
end function

-------------------------------------------------------------------------------
-- Shutdown socket
-------------------------------------------------------------------------------

function unix_shutdown_socket(atom socket, atom method)
	return c_func(shutdown_,{socket,method})
end function

function windows_shutdown_socket(atom socket, atom method)
	return c_func(shutdown_,{socket,method})
end function

--**
-- Partially or fully close a socket. 
--
-- Parameters:
--		# ##socket##: an atom, the socket to close
--      # ##method##: an integer, the method used to close the socket
--
-- Returns:
--		An **integer**, 0 on success and -1 on error. 
--
-- Comments:
--
-- A method of 0 closes the socket for reading, 1 closes the socket for writing, and
-- 2 closes the socket for both.
--
--  It may take several minutes for the OS to declare the socket as closed.

public function shutdown_socket(atom socket, atom method)
	ifdef WIN32 then
		return windows_shutdown_socket(socket,method)
	elsifdef UNIX then
		return unix_shutdown_socket(socket,method)
	end ifdef
	
	return -1
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
--		# ##socket_list##: a sequence of polling policies, see Comments for details
--		# ##timeout##: an atom, the number of milliseconds before returning.
--
-- Returns:
--		An **object**:
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

-------------------------------------------------------------------------------
-- Send (requires bound/connected socket)
-------------------------------------------------------------------------------
-- Returns the # of chars sent, or -1 for error
function unix_send(atom socket, sequence data, atom flags)
	atom datalen, dataptr, status
	datalen = length(data)
	dataptr = allocate(datalen+1)
	poke(dataptr,data&0)
	status = c_func(send_,{socket,dataptr,datalen,flags})
	free(dataptr)
	return status
end function

function windows_send(atom socket, sequence data, atom flags)
	-- Windows does send the same as Linux
	return unix_send(socket,data,flags)
end function

--**
-- Send TCP data to a socket connected remotely.
--
-- Parameters:
--		# ##socket##: an atom, the socket id
--		# ##data##: a sequence of atoms, what to send
--		# ##flags##: an atom,
--
-- Returns:
--		An **integer**, the number of characters sent, or -1 for an error.
--
-- Comments:
-- ##sSend##() works regardless of which socket is the listener and which is the
-- connector. 

public function send(atom socket, sequence data, atom flags)
	ifdef WIN32 then
		return windows_send(socket,data,flags)
	elsifdef UNIX then
		return unix_send(socket,data,flags)
	end ifdef
	
	return -1
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
--		# ##socket##: an atom, the socket id
--		# ##data##: a sequence of atoms, what to send
--		# ##flags##: an atom,
--		# ##inet_addr##: a sequence representing an IP address
--
-- Returns:
--		An **integer**, the number of characters sent, or -1 for an error.

public function sendto(atom socket, sequence data, atom flags, sequence inet_addr)
	ifdef WIN32 then
		return windows_sendto(socket,data,flags,inet_addr)
	elsifdef UNIX then
		return unix_sendto(socket,data,flags,inet_addr)
	end ifdef
	
	return -1
end function

-------------------------------------------------------------------------------
-- recv (for connected sockets)
-------------------------------------------------------------------------------
-- Returns either a sequence of data, or a 2-element sequence {ERROR_CODE,ERROR_STRING}.
function unix_recv(atom socket, atom flags)
	atom buf, buflen, rtnlen
	sequence rtndata
	buflen = BLOCK_SIZE
	buf = allocate(buflen)
	rtnlen = c_func(recv_,{socket,buf,buflen,flags})
	if rtnlen < 0 then
		free(buf)
		return get_error()
	end if
	rtndata = peek({buf,rtnlen})
	free(buf)
	return rtndata
end function

function windows_recv(atom socket, atom flags)
	-- Windows does recv the same as Linux
	-- The flag MSG_DONTWAIT is a Linux-only extension, and should not be used
	-- in cross-platform applications.
	-- From the Linux Man page on recv:
	-- The MSG_DONTWAIT flag requests the call to return when it would block otherwise.
	-- If no data is available, errno is set to EAGAIN. This flag is not available in
	-- strict ANSI or C99 compilation mode.
	return unix_recv(socket,flags)
end function

--**
-- Receive data from a bound socket. 
--
-- Parameters:
--		# ##socket##: an atom, the socket id
--		# ##flags##: an atom,
--
-- Returns:     
--   A **sequence**, either a full string of data on success, or a pair {error code, error string} on error or no data.
--
-- Comments:
-- This function will not return
-- until data is actually received on the socket, unless the flags
-- parameter contains MSG_DONTWAIT.
--
-- MSG_DONTWAIT only works on Linux kernels 2.4 and above.  Similar
-- functionality is not available in Windows.  The only way to set
-- up a non-blocking polling loop on Windows is to use poll().

public function recv(atom socket, atom flags)
	ifdef WIN32 then
		return windows_recv(socket, flags)
	elsifdef UNIX then
		return unix_recv(socket,flags)
	end ifdef
	
	return -1
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
--		# ##socket##: an atom, the socket id
--		# ##flags##: an atom,
--
-- Returns:
--		A **sequence** as follows:
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

-------------------------------------------------------------------------------
-- Socket options
-------------------------------------------------------------------------------
-- Get_socket_options returns an OBJECT containing the option value, or {"ERROR",errcode} on error.
-- Set_socket_options returns 0 on success and -1 on error.

function unix_getsockopts(atom socket, integer level, integer optname)
	object rtn
	atom buf, status, bufsiz
	buf = allocate(1028)
	poke4(buf,1024)
	status = c_func(getsockopts_,{socket,level,optname,buf+4,buf})
	if status = 0 then
		bufsiz = peek4u(buf)
		if bufsiz = 0 then
			rtn = {}
		elsif bufsiz = 4 then
			rtn = peek4u(buf+4)
		else
			rtn = {}
			for ctr = 1 to bufsiz do
				rtn = rtn & peek(buf+3+ctr)
			end for
		end if
	else
		rtn = {"ERROR",status}
	end if
	free(buf)
	return rtn
	
end function

function windows_getsockopts(atom socket, integer level, integer optname)
	return unix_getsockopts(socket,level,optname)
end function

--**
-- Get options for a socket.
-- 
-- Parameters:
--		# ##socket##: an atom, the socket id
--		# ##level##: an integer, the option level
--		# ##optname##: a string with the name of the requested option
--
-- Returns:
--		An **object**, either:
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
--    On error, {"ERROR",error_code}.  On success, either an atom or
--    a sequence containing the option value.
--
-- See also:
--     set_socket_options

public function get_socket_options(atom socket, integer level, integer optname)
	ifdef WIN32 then
		return windows_getsockopts(socket,level,optname)
	elsifdef UNIX then
		return unix_getsockopts(socket,level,optname)
	end ifdef
	
	return {"ERROR",-999}
end function

function unix_setsockopts(atom socket, integer level, integer optname, object val)
	object rtn
	atom buf, bufsiz
	if atom(val) then
		buf = allocate(8)
		bufsiz = 4
		poke4(buf,bufsiz)
		poke4(buf+4,val)
	else
		buf = allocate(length(val)+4)
		bufsiz = length(val)
		poke4(buf,bufsiz)
		poke(buf+4,val)
	end if
	rtn = c_func(setsockopts_,{socket,level,optname,buf+4,buf})
	return rtn
end function

function windows_setsockopts(atom socket, integer level, integer optname, object val)
	return unix_setsockopts(socket,level,optname,val)
end function

--**
-- Set options for a socket.
-- 
-- Parameters:
--		# ##socket##: an atom, the socket id
--		# ##level##: an integer, the option level
--		# ##optname##: a string with the name of the requested option
--		# ##val##: an object, the new value for the option
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
	ifdef WIN32 then
		return windows_setsockopts(socket,level,optname,val)
	elsifdef UNIX then
		return unix_setsockopts(socket,level,optname,val)
	end ifdef
	
	return -999 -- TODO: is this correct, or -1?
end function

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Getters
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- DNSQuery
-------------------------------------------------------------------------------
--****
-- === DNS query routines
--

-- Returns a set of sequences of {ip_addr, q_type, order} resolving the IP address for
-- the given domain name and/or host.
-- At present, only A,MX,and NS queries are supported.
-- Error 9501 = No record found

function unix_dnsquery(sequence dname, integer q_type)
	
	atom nameptr, rtnptr, success, ptrptr, dnameptr, qlen
	atom answer_start, answer_end, num_as_rec, num_qr_rec
	sequence rtn, line, subx
	object temp
	
	nameptr = allocate_string(dname&0)
	rtnptr = allocate(BLOCK_SIZE*8)
	success = c_func(dnsquery_,{nameptr,NS_C_IN,q_type,rtnptr,BLOCK_SIZE*8})
	if success < 0 then
		free(nameptr)
		free(rtnptr)
		return success
	end if
	-- The parsing of rtnptr is significantly more difficult in Linux than
	-- in Windows.  Much of the code that follows is based on Postfix-2.5.1/
	-- src/dns/dns_lookup.c.
	if success > BLOCK_SIZE * 8 then  -- The Answer has been truncated & is invalid.
		free(nameptr)
		free(rtnptr)
		return -2
	end if
	-- Size of Header = 12 bytes.  # Query = [5..6], # Answer = [7..8], # Auth = [9..10]
	-- # Res = [11..12]
	num_qr_rec = (peek(rtnptr+4)*256)+peek(rtnptr+5)
	num_as_rec = (peek(rtnptr+6)*256)+peek(rtnptr+7)
	if num_as_rec = 0 then
		free(nameptr)
		free(rtnptr)
		return 9501  -- No Data
	end if
	ptrptr = rtnptr + 12 -- Start of query record
	dnameptr = allocate(1024)
	for ctr = 1 to num_qr_rec do
		qlen = c_func(dnsexpand_,{rtnptr,rtnptr+success,ptrptr,dnameptr,1024})
		if qlen < 0 then
			free(dnameptr)
			free(nameptr)
			free(rtnptr)
			return qlen
		end if
		ptrptr = ptrptr + qlen + 4
	end for
	answer_start = ptrptr
	answer_end = rtnptr + success
	
	-- Now we're finally at the answer section
	rtn = {}
	for seq = 1 to num_as_rec do
		line = repeat(0,8)
		subx = repeat(0,32)
		if ptrptr >= answer_end then
			free(dnameptr)
			free(nameptr)
			free(rtnptr)
			return -4
		end if
		qlen = c_func(dnsexpand_,{rtnptr,answer_end,ptrptr,dnameptr,1024})
		if qlen < 0 then
			free(dnameptr)
			free(nameptr)
			free(rtnptr)
			return -5
		end if
		line[2] = get_string(dnameptr)
		ptrptr = ptrptr + qlen
		if ptrptr+10 >= answer_end then
			free(dnameptr)
			free(nameptr)
			free(rtnptr)
			return -4
		end if
		line[3] = (peek(ptrptr)*256)+peek(ptrptr+1) -- type
		line[7] = (peek(ptrptr+2)*256)+peek(ptrptr+3) -- Class
		line[6] = (peek(ptrptr+4)*256*256*256)+(peek(ptrptr+5)*256*256)+
		(peek(ptrptr+6)*256)+peek(ptrptr+7)  -- TTL
		line[4] = (peek(ptrptr+8)*256)+peek(ptrptr+9)  -- Data Length
		ptrptr = ptrptr + 10
		if ptrptr + line[4] - 1 >= answer_end then
			free(dnameptr)
			free(nameptr)
			free(rtnptr)
			return -4
		end if
		if line[3] = NS_T_NS then
			qlen = c_func(dnsexpand_,{rtnptr,answer_end,ptrptr,dnameptr,1024})
			if qlen > 0 then
				subx[1] = get_string(dnameptr)
				temp = unix_dnsquery(subx[1],NS_T_A)
				if atom(temp) then
					rtn = append(rtn,{subx[1],line[3],seq})
				else
					for ctr = 1 to length(temp) do
						rtn = append(rtn,{temp[ctr][1],line[3],seq+ctr-1})
					end for
				end if
			end if
		elsif line[3] = NS_T_MX then
			subx[2] = (peek(ptrptr)*256)+peek(ptrptr+1)  -- Priority
			qlen = c_func(dnsexpand_,{rtnptr,answer_end,ptrptr+2,dnameptr,1024})
			if qlen > 0 then
				subx[1] = get_string(dnameptr)
				temp = unix_dnsquery(subx[1],NS_T_A)
				if atom(temp) then
					rtn = append(rtn,{subx[1],line[3],subx[2]})
				else
					for ctr = 1 to length(temp) do
						rtn = append(rtn,{temp[ctr][1],line[3],subx[2]+ctr-1})
					end for
				end if
			end if
		elsif line[3] = NS_T_A and line[4] >= 4 then
			subx[1] = sprintf("%d.%d.%d.%d",{peek(ptrptr),peek(ptrptr+1),
				peek(ptrptr+2),peek(ptrptr+3)})
			if q_type = NS_T_ANY or q_type = NS_T_A then
				rtn = append(rtn,{subx[1],line[3],seq})
			end if
		elsif line[3] = NS_T_PTR then
			
		end if
		ptrptr = ptrptr + line[4]
		
	end for
	
	-- Finally, we're done.
	free(dnameptr)
	free(nameptr)
	free(rtnptr)
	
	return rtn
	
end function

function windows_dnsquery(sequence dname, integer q_type, atom options)
	-- NOTE: This function does not work on Windows versions below Windows 2000.
	
	atom success,nameptr, rtnptr, recptr, seq
	sequence rtn, line, subx
	object temp
	
	if dnsquery_ < 0 then
		return -999
	end if
	
	nameptr = allocate_string(dname)
	rtnptr = allocate(4)
	success = c_func(dnsquery_,{nameptr,q_type,options,0,rtnptr,0})
	if success != 0 then
		free(nameptr)
		free(rtnptr)
		return success
	end if
	rtn = {}
	recptr = peek4u(rtnptr)
	seq = 1
	while recptr > 0 do
		line = repeat(0,8)
		subx = repeat(0,32)
		line[1]=peek4u(recptr) -- Pointer to the next record
		line[2]=peek4u(recptr+4) -- Pointer to the name string
		line[3]=peek(recptr+8)+(peek(recptr+9)*256) -- type
		line[4]=peek(recptr+10)+(peek(recptr+11)*256) -- Data Length
		line[5]=peek4u(recptr+12) -- Flags
		line[6]=peek4u(recptr+16) -- TTL
		line[7]=peek4u(recptr+20) -- reserved
		if line[3] = NS_T_MX then
			subx[1] = get_string(peek4u(recptr+24)) -- Mail server name
			subx[2] = peek(recptr+28)+(peek(recptr+29)*256) -- Preference
			temp = windows_dnsquery(subx[1],NS_T_A,options)
			if atom(temp) then
				rtn = append(rtn,{subx[1],line[3],subx[2]})
			else
				for ctr = 1 to length(temp) do
					rtn = append(rtn,{temp[ctr][1],line[3],subx[2]+ctr-1})
				end for
			end if
		elsif line[3] = NS_T_NS then
			subx[1] = get_string(peek4u(recptr+24)) -- NS server name
			temp = windows_dnsquery(subx[1],NS_T_A,options)
			if atom(temp) then
				rtn = append(rtn,{subx[1],line[3],seq})
			else
				for ctr = 1 to length(temp) do
					rtn = append(rtn,{temp[ctr][1],line[3],seq+ctr-1})
				end for
			end if
		elsif line[3] = NS_T_A then
			subx[1] = sprintf("%d.%d.%d.%d",{peek(recptr+24),peek(recptr+25),
				peek(recptr+26),peek(recptr+27)})
			if q_type = NS_T_ANY or q_type = NS_T_A then
				rtn = append(rtn,{subx[1],line[3],seq})
			end if
		elsif line[3] = NS_T_PTR then
			
		end if
		recptr = line[1]
		seq = seq + 1
	end while
	c_proc(dnsrlfree_,{peek4u(rtnptr),1})
	free(nameptr)
	free(rtnptr)
	
	return rtn
	
end function

--**
-- Query DNS info.
--
-- Parameters:
--		# ##dname##: a string, the name to look up
--		# ##q_type##: an integer, the type of lookup requested
--		# ##options##: an atom,
--
-- Returns:
--     An **object**, either a negative integer on error, or a sequence of sequences in the form {{string ip_address, integer query_type, integer priority},...}.
--
-- Comments:
--
-- For standard A record lookups, getaddrinfo is preferred.
-- But sometimes, more advanced DNS lookups are required.  Eventually,
-- this routine will support all types of DNS lookups.  In Euphoria
-- 4.0, only NS, MX, and A lookups are accepted.
--
-- Example 1:
-- <eucode>
-- result = dnsquery("yahoo.com",NS_T_MX,0)
-- if atom(result) then
--     puts(1,"Uh, oh!")
-- else
--     for ctr = 1 to length(result) do
--         printf(1,"%s\t%d\t%d\n",result[ctr])
--     end for
-- end if
-- </eucode>
--
-- See Also:
--     [[:getaddrinfo]], [[:gethostbyname]], [[:getmxrr]], [[:getnsrr]]

public function dnsquery(sequence dname, integer q_type, atom options)
	ifdef WIN32 then
		return windows_dnsquery(dname, q_type, options)
	elsifdef UNIX then
		return unix_dnsquery(dname,q_type)
	end ifdef
	
	return -999 -- TODO: -999 or -1?
end function

-------------------------------------------------------------------------------
-- getmxrr
-------------------------------------------------------------------------------

--**
-- Find a mail server for a given domain. If none can be found,
-- attempt a smart query by looking up common variations on
-- domain_name.
--
-- Parameters:
--		# ##dname##: a string, the name to look up
--		# ##options##: an atom,
--
-- Returns:
--
--     An **object**, either a negative integer on error, or a sequence of sequences in the form {{string ip_address, integer query_type, integer priority},...}.
--
-- See Also:
--     [[:dnsquery]]

public function getmxrr(sequence dname, atom options)
	object rtn

	-- Error 9003 = MS: RCODE_NAME_ERROR - Something's there, but it's not exact.
	-- Error 9501 = No Data Found
	
	dname = trim_(dname)
	rtn = dnsquery(dname,NS_T_MX,options)
	if sequence(rtn) and length(rtn)>0 then
		return rtn
	end if
	if rtn = 9501 or rtn = 9003 or rtn = -1 or
			(sequence(rtn) and length(rtn)=0) then
		rtn = dnsquery("mail."&dname,NS_T_MX,options)
	end if
	return rtn
end function

-------------------------------------------------------------------------------
-- getnsrr
-------------------------------------------------------------------------------

--**
-- Find a name server for a given domain. If none can be found,
-- attempt a smart query by looking up common variations on
-- domain_name.
--
-- Parameters:
--		# ##dname##: a string, the name to look up
--		# ##options##: an atom,
--
-- Returns:
--     An **object**, either a negative integer on error, or a sequence of sequences in the form {{string ip_address, integer query_type, integer priority},...}.
--
-- See Also:
--   [[:dnsquery]]

public function getnsrr(sequence dname, atom options)
	return dnsquery(dname,NS_T_NS,options)
end function

-------------------------------------------------------------------------------
-- GetHostByName (deprecated - replaced by GetAddrInfo)
-------------------------------------------------------------------------------

function unix_gethostbyname(sequence name)
	
	-- Based on SOCKS.EXU demo from Irv Mullins.
	
	atom hostent,name_ptr,host_addr_ptr
	sequence host_addr
	
	name_ptr = allocate_string(name)
	hostent = c_func(gethostbyname_,{name_ptr})
	free(name_ptr)
	if hostent = 0 then
		return ""
	end if
	host_addr_ptr = peek4u(hostent+16)  -- May be hostent+12 on Windows, may be hostent+16 on Linux
	if host_addr_ptr > 0 then
		host_addr = sprintf("%d.%d.%d.%d",peek({peek4u(host_addr_ptr),4}))
	else
		host_addr = ""
	end if
	free(hostent)
	return host_addr
	
end function

function windows_gethostbyname(sequence name)
	-- The returned structure may not be the same on Windows and Linux, but
	-- we'll assume they are for now.
	
	atom hostent,name_ptr,host_addr_ptr
	sequence host_addr
	
	name_ptr = allocate_string(name)
	hostent = c_func(gethostbyname_,{name_ptr})
	free(name_ptr)
	if hostent = 0 then
		return ""
	end if
	host_addr_ptr = peek4u(hostent+12)  -- May be hostent+12 on Windows, may be hostent+16 on Linux
	if host_addr_ptr > 0 then
		host_addr = sprintf("%d.%d.%d.%d",peek({peek4u(host_addr_ptr),4}))
	else
		host_addr = ""
	end if
	-- Windows does not permit freeing the hostent structure
	return host_addr
	
end function

--**
-- Get host address, given its name.
--
-- Parameters:
--		# ##name##: a string, the name of te host to look up.
--
-- Returns:
--	A **sequence**, a string representing the IP address of queried host.

public function gethostbyname(sequence name)
	ifdef WIN32 then
		return windows_gethostbyname(name)
	elsifdef UNIX then
		return unix_gethostbyname(name)
	end ifdef
	
	return -999
end function

-------------------------------------------------------------------------------
-- GetServByName (deprecated - replaced by GetAddrInfo)
-------------------------------------------------------------------------------
-- Returns the (integer) port number of the service

function unix_getservbyname(sequence name)
	-- Based on SOCKS.EXU demo from Irv Mullins.
	atom name_ptr,port_ptr,port
	
	name_ptr = allocate_string(name)
	port_ptr = c_func(getservbyname_,{name_ptr,0})
	if port_ptr = 0 then
		free(name_ptr)
		return 0
	end if
	port = (peek(port_ptr+8)*256)+(peek(port_ptr+9))
	free(name_ptr)
	return port
	
end function

function windows_getservbyname(sequence name)
	return unix_getservbyname(name)
end function

function getservbyname(sequence name)
	ifdef WIN32 then
		return windows_getservbyname(name)
	elsifdef UNIX then
		return unix_getservbyname(name)
	end ifdef
	
	return -999
end function

-------------------------------------------------------------------------------
-- GetAddrInfo
-------------------------------------------------------------------------------
-- Returns a sequence of sequences {atom flags, atom family, atom socktype, atom protocol, sequence inet_addr}
-- on success or an error code on failure

--memset(&hints, 0, sizeof(hints));
--hints.ai_flags = AI_NUMERICHOST;
--hints.ai_family = PF_UNSPEC;
--hints.ai_socktype = 0;
--hints.ai_protocol = 0;
--hints.ai_addrlen = 0;
--hints.ai_canonname = NULL;
--hints.ai_addr = NULL;
--hints.ai_next = NULL;
--getaddrinfo(ip, port, &hints, &aiList)
--nodename A pointer to a NULL-terminated ANSI string that contains a host (node) name or a numeric host address string. For the Internet protocol, the numeric host address string is a dotted-decimal IPv4 address or an IPv6 hex address.
--servname A pointer to a NULL-terminated ANSI string that contains either a service name or port number represented as a string.
--hints A pointer to an addrinfo structure that provides hints about the type of socket the caller supports. See Remarks.
--res A pointer to a linked list of one or more addrinfo structures that contains response information about the host.

function unix_getaddrinfo(object node, object service, object hints)
	atom addrinfo, success, node_ptr, service_ptr, hints_ptr, addrinfo_ptr, svcport
	atom cpos
	sequence rtn, val
	
	addrinfo = allocate(32)
	poke(addrinfo,repeat(0,32))
	if sequence(node) then
		node_ptr = allocate_string(node)
	else
		node_ptr = node
	end if
	svcport = 0
	if sequence(service) then
		service_ptr = allocate_string(service)
		val = value(service)
		if val[1] = GET_SUCCESS then
			svcport = val[2]
		end if
	else
		service_ptr = service
		if service > 0 and service <= #FFFF then
			svcport = service
			service_ptr = 0
		end if
	end if
	hints_ptr = 0    -- Not yet implemented
	success = c_func(getaddrinfo_,{node_ptr,service_ptr,hints_ptr,addrinfo})
	if success != 0 then
		free(addrinfo)
		if sequence(node) then free(node_ptr) end if
		if sequence(service) then free(service_ptr) end if
		return success
	end if
	rtn = {}
	-- addrinfo is a pointer to a pointer to a structure in Linux.
	addrinfo_ptr = peek4u(addrinfo)
	-- 27 Nov 2007: Only one addrinfo structure is supported
	--  while addrinfo_ptr != 0 do
	rtn = append(rtn,{
	peek4u(addrinfo_ptr),
		peek4u(addrinfo_ptr+4),
		peek4u(addrinfo_ptr+8),
		peek4u(addrinfo_ptr+12),
		get_sockaddr(peek4u(addrinfo_ptr+20))
	})
	addrinfo_ptr = peek4u(addrinfo_ptr+28)
	--  end while
	c_proc(freeaddrinfo_,{peek4u(addrinfo)})
	if svcport = 0 and rtn[1][4] > 0 then
		svcport = rtn[1][4]
	end if
	if length(rtn[1][5])=0 and sequence(node) then
		rtn[1][5] = gethostbyname(node)
		if sequence(service) and svcport = 0 then
			rtn[1][5] = rtn[1][5] & sprintf(":%d",getservbyname(service))
		elsif svcport > 0 then
			rtn[1][5] = rtn[1][5] & sprintf(":%d",svcport)
		end if
	elsif svcport > 0 then
		cpos = find(':',rtn[1][5])
		if cpos = 0 or cpos = length(rtn[1][5]) or
				eu:compare(rtn[1][5][length(rtn[1][5])-1..length(rtn[1][5])],":0")=0 then
			if cpos = 0 then
				rtn[1][5] = rtn[1][5] & sprintf(":%d",svcport)
			else
				rtn[1][5] = rtn[1][5][1..cpos-1] & sprintf(":%d",svcport)
			end if
		end if
	end if
	free(addrinfo)
	return rtn
end function

function windows_getaddrinfo(object node, object service, object hints)
	return unix_getaddrinfo(node,service,hints)
end function

--**
-- Retrieve information about a given server name and named service.
--
-- Parameters:
-- 		# ##node##: an object, ???
--		# ##service##: an object, ???
--		# ##hints##: an object, currently not used
--
-- Returns:
--		A **sequence** of sequences containing the requested information.
-- The inner sequences have fields that can be accessed with public constants
--
-- * ADDR_FLAGS
-- * ADDR_FAMILY
-- * ADDR_TYPE
-- * ADDR_PROTOCOL
-- * ADDR_ADDRESS
--
-- Comments:
-- Different DNS servers may return conflicting information about a
-- name, but getaddrinfo will only return the first.  Future
-- versions will allow multiple entries to be returned, so this
-- return format will keep programs using this library from breaking
-- when the functionality is added.  The hints parameter is not
-- currently used.  Service may be either a string containing the
-- service name, a string containing the port number, or an integer
-- port number between 0 and 65535.
--
-- Example 1:
-- <eucode>
-- puts(1,"The IP address and port for http://www.yahoo.com is "&
-- getaddrinfo("www.yahoo.com","http",0)&"\n")
-- </eucode>

public function getaddrinfo(object node, object service, object hints)
	ifdef WIN32 then
		return windows_getaddrinfo(node,service,hints)
	elsifdef UNIX then
		return unix_getaddrinfo(node,service,hints)
	end ifdef
	
	return -999
end function

public function get_addrinfo(object node, object service, object hints)
	-- Added version 1.3.1 for consistency.
	return getaddrinfo(node,service,hints)
end function

-----------------------------------------------------------------------------------
--URL-encoding
-----------------------------------------------------------------------------------
--****
-- === URL encoding
--

-- HTML form data is usually URL-encoded to package it in a GET or POST submission. In a nutshell, here's how you URL-encode the name-value pairs of the form data:
--   1. Convert all "unsafe" characters in the names and values to "%xx", where "xx" is the ascii 
--      value of the character, in hex. "Unsafe" characters include =, &, %, +, non-printable 
--      characters, and any others you want to encode-- there's no danger in encoding too many 
--      characters. For simplicity, you might encode all non-alphanumeric characters.
--   2. Change all spaces to pluses.
--   3. String the names and values together with = and &, like
--          name1=value1&name2=value2&name3=value3
--   4. This string is your message body for POST submissions, or the query string for GET submissions.
--
-- For example, if a form has a field called "name" that's set to "Lucy", and a field called "neighbors" 
-- that's set to "Fred & Ethel", the URL-encoded form data would be:
--
--    name=Lucy&neighbors=Fred+%26+Ethel <<== note no \n or \r
--
-- with a length of 34.

--**
-- Converts all non-alphanumeric characters in a string to their
-- percent-sign hexadecimal representation, or plus sign for
-- spaces.
--
-- Parameters:
--		# ##what##: the string to encode
--
-- Returns:
--
-- 		A **sequence**, the encoded string.
--
-- Example 1:
-- <eucode>
-- puts(1,urlencode("Fred & Ethel"))
-- -- Prints "Fred+%26+Ethel"
-- </eucode>

public function urlencode(sequence what)
	-- Function added by Kathy Smith (Kat)(KAT12@coosahs.net), version 1.3.0
	sequence encoded, alphanum, hexnums
	object junk, junk1, junk2
	
	encoded = ""
	junk = ""
	alphanum = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz01234567890/" -- encode all else
	hexnums = "0123456789ABCDEF"
	
	for idx = 1 to length(what) do
		if find(what[idx],alphanum) then
			encoded &= what[idx]
		else
			junk = what[idx]
			junk1 = floor(junk / 16)
			junk2 = floor(junk - (junk1 * 16))
			encoded &= "%" & hexnums[junk1+1] & hexnums[junk2+1]
		end if
	end for
	
	return encoded
	
end function -- urlencode(sequence what)

-------------------------------------------------------------------------------
-- sendheader manipulation
-------------------------------------------------------------------------------
--****
-- === Header management
--

--**
-- Retrieve either the whole sendheader sequence, or just a single
-- field. 
--
-- Parameters:
--		# ##field##: an object indicating which part is being requested, see Comments section.
--
-- Returns:
--		An **object**, either:
-- * -1 if the field cannot be found, 
-- * ##{{"label","delimiter","value"},...}## for the whole sendheader sequence
-- * a three-element sequence in the form ##{"label","delimiter","value"}## when only a single field is selected.
--
-- Comments:
-- ##field## can be either an HTTP_HEADER_xxx access constant,
-- the number 0 to retrieve the whole sendheader sequence, or
-- a string matching one of the header field labels.  The string is
-- not case sensitive.
--

public function get_sendheader(object field)
	-- if field is 0, return the whole sequence.
	-- if field is 1..length(sendheader), return just that field
	-- if field is invalid, return -1.
	-- if field is a sequence, try to match it to sendheader[x][1].
	
	-- Kat: should i return [1] & [2] as well? Mike: yes
	-- most server interfaces return the only value, saves parsing
	-- we'll return a {"Name","spacer","value"} format
	
	sequence upperfield
	
	-- Function added by Kathy Smith (Kat)(KAT12@coosahs.net), version 1.3.0
	if sequence(field) then
		upperfield = upper(field)
		for idx = 1 to length(sendheader) do
			if equal(upperfield,upper(sendheader[idx][1])) then
				return sendheader[idx]
			end if
		end for
		return -1
	elsif field < 0 or field > length(sendheader) then
		return -1
	elsif field = 0 then
		return sendheader
	else
		return sendheader[field]
	end if
end function

--**
-- Sets 21 header elements to default values.  The default User Agent
-- is Opera (currently the most standards compliant).  Before setting
-- any header option individually, programs must call this procedure.
--
-- See Also:
--     [[:get_sendheader]], [[:set_sendheader]], [[:set_sendheader_useragent_msie]]

public procedure set_sendheader_default()
	-- sets some defaults
	-- httpversion MUST come before GET in this program: some servers default to 1.0, even if you say 1.1
	-- NO spaces around [3] on httpversion
	-- POSTDATA MUST come before Content-Length in this program
	-- Referer is often used by sites to be sure your fetch was from one of their own pages
	-- headers with [3] = "" won't be sent
	
	-- Function added by Kathy Smith (Kat)(KAT12@coosahs.net), version 1.3.0
	sendheader = { -- you can add more [1], and modify [3], [2] is the ' ' or ": " (GET has no ": ")
		{"httpversion","","HTTP/1.0"}, -- not a legal http headerline, but to append to GET later
		{"GET"," ",""}, -- [3] = the filename you want
		{"Host",": ",""},
		{"Referer",": ",""}, -- i know it's misspelled, but that's official!
		{"User-Agent",": ","Opera/5.02 (Windows 98; U)  [en]"}, --</joke> pick your own :-)
		{"Accept",": ","*/*"},
		{"Accept-Charset",": ","ISO-8859-1,utf-8;q=0.7,*;q=0.7"},
		{"Accept-Encoding",": ","identity"}, -- "identity" = no decoder in eunet so far
		{"Accept-Language",": ","en-us"}, -- pick your own language abbr here
		{"Accept-Ranges",": ",""},
		{"Authorization",": ",""},
		{"Date",": ",""}, -- who cares if the server has my time?
		{"If-Modified-Since",": ",""},
		{"POST"," ",""}, -- if POST, obviously
		{"POSTDATA","",""}, -- not a legal headerline, but has to go somewhere
		{"Content-Type",": ",""}, -- if POST transaction
		{"Content-Length",": ",""}, -- if POST transaction
		{"From",": ",""}, -- possible in POST or Authorization
		{"Keep-Alive",": ","0"},
		{"Cache-Control",": ","no"},
		{"Connection",": ","close"}
	}	
end procedure

--**
-- Set an individual header field.
--
-- Parameters:
--		# ##whatheader##: an object, either an explicit name string or a HTTP_HEADER_xxx constant
--		# ##whatdata##: a string, the associated data
--
-- Comments:
-- If the requested field is not one of the 21
-- default header fields, the field MUST be set by string.  This will
-- increase the length of the header overall.  
--
-- Example 1:
-- <eucode>
-- set_sendheader("Referer","search.yahoo.com")
-- </eucode>
--
-- See Also:
--     [[:get_sendheader]]

public procedure set_sendheader(object whatheader, sequence whatdata)
	if atom(whatheader) then
		if whatheader > 0 and whatheader <= length(sendheader) then
			sendheader[whatheader][3] = whatdata
		end if
		return
	end if
	
	-- Function added by Kathy Smith (Kat)(KAT12@coosahs.net), version 1.3.0
	for idx = 1 to length(sendheader) do
		if match(upper(whatheader),upper(sendheader[idx][1])) then
			sendheader[idx][3] = whatdata
			return
		end if
	end for
	
	--  sendheader &= { whatheader & whatdata } -- you better know what you are doing here!
	sendheader = append(sendheader,{whatheader, ": ",whatdata})
	
end procedure -- setsendheaderline(sequence whatheader, sequence whatdata)

--**
-- Inform listener that user agent is Microsoft (R) Internet Explorer (TM).
--
-- Comments:
-- This is a convenience procedure to tell a website that a Microsoft
-- Internet Explorer (TM) browser is requesting data.  Because some
-- websites format their response differently (or simply refuse data)
-- depending on the browser, this procedure provides a quick means
-- around that.

public procedure set_sendheader_useragent_msie()
	set_sendheader("UserAgent","Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0)")
end procedure

--------------------------------------------------------------------------------
-- this can also be used to flatten the sendheader record, for printing, etc
function eunet_format_sendheader()	
	-- Function added by Kathy Smith (Kat)(KAT12@coosahs.net), version 1.3.0
	sequence tempheader, temppostdata, httpversion
	tempheader = ""
	temppostdata = ""
	httpversion = ""
	for idx = 1 to length(sendheader) do
		if not equal("",sendheader[idx][3]) and
				not equal("httpversion",sendheader[idx][1]) and
				not equal("POSTDATA",sendheader[idx][1]) then
			if equal("GET",sendheader[idx][1])
					then tempheader &= sendheader[idx][1] & sendheader[idx][2] & sendheader[idx][3] & " " & httpversion & "\n"
				else tempheader &= sendheader[idx][1] & sendheader[idx][2] & sendheader[idx][3] & "\r\n"
			end if
		end if
		if equal("POSTDATA",sendheader[idx][1]) and not equal("",sendheader[idx][3]) then
			--temppostdata = urlencode(sendheader[idx][3])
			temppostdata = sendheader[idx][3]
			set_sendheader("Content-Length",sprintf("%d",length(temppostdata)))
		end if
		if equal("httpversion",sendheader[idx][1]) and not equal("",sendheader[idx][3]) then
			httpversion = sendheader[idx][3]
		end if
	end for
	
	tempheader &= "\r\n" -- end of header
	if not equal(temppostdata,"") -- but if there's POST data,
			then tempheader &= temppostdata  -- tack that on too
	end if
	
	return tempheader
	
end function -- formatsendheader()

--**
-- Populates the internal sequence recvheader from the flat string header.
--
-- Parameters:
--		# ##header##: a string, the header data
--
-- Comments:
--     This must be called prior to calling [[:get_recvheader]]().

public procedure parse_recvheader(sequence header)
	sequence junk
	atom place
	
	junk = {"",""} -- init it, it looks like this
	recvheader = eunet_parse(header,{10,13}) -- could be \n or \r or both
	for idx = 1 to length(recvheader) do
		place = match(": ",recvheader[idx])
		if place then
			junk[1] = recvheader[idx][1..place-1]
			junk[2] = recvheader[idx][place+2..length(recvheader[idx])]
			recvheader[idx] = junk
		else
			if match("HTTP/",upper(recvheader[idx])) then
				recvheader[idx] = {"httpversion",recvheader[idx]} -- what else to call that line?
			end if
		end if
	end for
end procedure

--**
-- Return the value of a named field in the received http header as
-- returned by the most recent call to [[:get_http]].
--
-- Parameters:
--		# ##field##: an object, either a string holding a field name (case insensitive),
-- 0 to return the whole header, or a numerical index.
--
-- Returns:	
--
--	An **ovject**:
--     * -1 on error
--     * a sequence in the form, ##{field name, field value}## on success.

public function get_recvheader(object field)
	sequence upperfield
	-- recvheader was parsed out previously in parse_recvheader()
	-- if field is 0, return the whole sequence.
	-- if field is 1..length(recvheader), return just that field
	-- if field is invalid, return -1.
	-- if field is a sequence, try to match it to recvheader[x][1].
	
	-- we'll NOT return a {"Name","value"} format
	-- because that leads to using a junk seq to get the [2] from
	-- --> And yet, that's exactly what we're doing.  -- Mike.
	
	-- Function added by Kathy Smith (Kat)(KAT12@coosahs.net), version 1.3.1
	
	if sequence(field) and equal(field,"") then return -1 end if
	if atom(field) then
		if ( field <= 0 ) or ( field > length(recvheader) ) then return -1 end if
		return recvheader[field]
	end if
	
	upperfield = upper(field)
	for idx = 1 to length(recvheader) do
		if equal(upperfield,upper(recvheader[idx][1])) then
			return recvheader[idx] -- {"header_name","value"}
		end if
	end for
	
	return -1 -- not found!
	
end function

-------------------------------------------------------------------------------
-- get_http
-------------------------------------------------------------------------------
--****
-- === Web interface
--

--**
-- Returns data from an http internet site.
--
-- Parameters:
--		# ##inet_addr##: a sequence holding an address
--		# ##hostname##: a string, the name for the host
-- 		# ##file##: a file name to transmit
--
-- Returns:
--   A **sequence**, empty sequence on error, of length 2 on success, like ##{sequence header, sequence data}##.

public function get_http(sequence inet_addr, sequence hostname, sequence file)
	
	atom socket, success, last_data_len
	sequence header, data, hline
	
	-- Notes for future additions:
	--GET /index.html HTTP/1.1
	--Host: www.amazon.com
	--Accept: */*
	--Accept-Language: en-us
	--User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0)
	
	if length(inet_addr)=0 then
		return {"",""}
	end if
	
	-- Modification added by Kathy Smith (Kat)(KAT12@coosahs.net), version 1.3.0 {
	if equal(sendheader,"") then
		set_sendheader_default() -- it really should be set to something! But is not **required**
	end if
	
	if length(file)=0 or file[1]!='/' then file = '/'&file end if
	set_sendheader("GET",file)
	-- TO DO: Allow transmission of POST data by using set_sendheader("POST",data)
	set_sendheader("HOST",hostname)
	hline = get_sendheader("Referer")
	if equal(hline[3],"") then
		set_sendheader("Referer",hostname)
	end if
	data = {}
	last_data_len = 0
	socket = new_socket(AF_INET,SOCK_STREAM,0)
	success = connect(socket,inet_addr)
	if success = 0 then
		--    success = send(socket,
			--                  sprintf("GET /%s HTTP/1.0\nHost: %s\n\n",{file,hostname}),0)
		success = send(socket,eunet_format_sendheader(),0)
		-- } end version 1.3.0 mod
		while success > 0 do
			data = data & recv(socket,0)
			success = length(data)-last_data_len
			last_data_len = length(data)
		end while
	end if
	if close_socket(socket) then end if
	
	success = match({13,10,13,10},data)
	if success > 0 then
		header = data[1..success-1]
		parse_recvheader(header)
		data = data[success+4..length(data)]
	else
		header = data
		data = {}
	end if
	return {header,data}
	
end function

--**
-- Works the same as [[:get_url]](), but maintains an internal
-- state register based on cookies received. 
--
-- Parameters:
--		# ##inet_addr##: a sequence holding an address
--		# ##hostname##: a string, the name for the host
-- 		# ##file##: a file name to transmit
--
-- Returns:	
--   A **sequence** {header, body} on success, or an empty sequence on error.
--
-- Comments:
--
--   As of Euphoria 4.0, only the internal state is maintained. Future versions of this 
--   library will expand state functionality.
--
-- Example 1:
-- <eucode>
-- addrinfo = getaddrinfo("www.yahoo.com","http",0)
-- if atom(addrinfo) or length(addrinfo) < 1 or
--    length(addrinfo[1]) < 5 then
--    puts(1,"Uh, oh")
--    return {}
-- else
--     inet_addr = addrinfo[1][5]
-- end if
-- data = get_http_use_cookie(inet_addr,"www.yahoo.com","")
-- </eucode>
--
-- See also:
--     get_url

public function get_http_use_cookie(sequence inet_addr, sequence hostname,
                                          sequence file)
	atom socket, success, last_data_len, cpos, offset
	sequence header, header2, body, data, updata, hline
	sequence cookielist, request, cookie
	cookielist = {}
	request = ""
	-- cookie = {name,domain,path,expires,encrypted,version}
	
	if length(inet_addr)=0 then
		return {"",""}
	end if
	-- Modification added by Kathy Smith (Kat)(KAT12@coosahs.net), version 1.3.0 {
	if equal(sendheader,"") then
		set_sendheader_default() -- it really should be set to something! But is not **required**
	end if
	
	if length(file)=0 or file[1]!='/' then file = '/'&file end if
	set_sendheader("GET",file)
	set_sendheader("HOST",hostname)
	hline = get_sendheader("Referer")
	if equal(hline[3],"") then
		set_sendheader("Referer",hostname)
	end if
	
	for ctr = 1 to length(this_cookiejar) do
		if sequence(this_cookiejar[ctr]) and length(this_cookiejar[ctr])>=2 and
				sequence(this_cookiejar[ctr][1]) and
				(match(hostname,this_cookiejar[ctr][2])>0 or match(this_cookiejar[ctr][2],hostname)>0) and
				(length(file)=0 or match(this_cookiejar[ctr][3],file)>0) then
			cookielist = append(cookielist,this_cookiejar[ctr])
		end if
	end for
	
	-- TO DO: Sort cookielist by domain, path (longer path before shorter path)
	--  request = sprintf("GET /%s HTTP/1.0\nHost: %s\n",{file,hostname})
	for idx = 1 to length(cookielist) do
		--    if idx = 1 then
		--      request = request & "Cookie: "&cookielist[idx][1]
		--    else
		--      request = request & "        "&cookielist[idx][1]
		--    end if
		request = request & cookielist[idx][1]
		if length(cookielist[idx][3])>0 then
			request = request & "; $Path=" & cookielist[idx][3]
		end if
		if idx < length(cookielist) then
			--request = request & ";\n"
			request = request & ";"
		else
			--request = request & "\n"
		end if
	end for
	--  request = request & "\n"
	set_sendheader("Cookie",request)
	
	data = {}
	last_data_len = 0
	socket = new_socket(AF_INET,SOCK_STREAM,0)
	success = connect(socket,inet_addr)
	if success = 0 then
		--    success = send(socket,request,0)
		success = send(socket,eunet_format_sendheader(),0)
		-- } end version 1.3.0 modification
		while success > 0 do
			data = data & recv(socket,0)
			success = length(data)-last_data_len
			last_data_len = length(data)
		end while
	end if
	if close_socket(socket) then end if
	
	success = match({13,10,13,10},data)
	if success > 0 then
		header = data[1..success-1]
		parse_recvheader(header)
		body = data[success+4..length(data)]
	else
		header = data
		body = {}
		data = {}
	end if
	
	header2 = header
	cpos = match("SET-COOKIE",upper(header2))
	while cpos > 0 do
		header2 = header2[cpos+10..length(header2)]
		data = header2
		cpos = find(':',data)
		if cpos > 0 then
			data = data[cpos+1..length(data)]
		end if
		offset = 0
		cpos = match(13&10,data)
		while cpos > 1 and data[offset+cpos-1]=';' do
			offset = offset + cpos + 2
			cpos = match(13&10,data[offset..length(data)])
		end while
		offset = offset + cpos - 1
		data = data[1..offset]
		updata = upper(data)
		cookie = {"","","","","N",""}
		offset = match("PATH=",updata)
		if offset > 0 then
			cpos = find(';',data[offset..length(data)])
			if cpos = 0 then cpos = length(data)-offset+2 end if
			cookie[3] = data[offset+5..offset+cpos-2]
		end if
		cpos = find(';',data)
		if cpos = 0 then cpos = length(data)+1 end if
		cookie[1] = trim_(data[1..cpos-1])
		if cpos > length(data) then
			data = ""
			updata = ""
		else
			data = data[cpos+1..length(data)]
			updata = updata[cpos+1..length(data)]
		end if
		offset = match("DOMAIN=",updata)
		if offset > 0 then
			cpos = find(';',data[offset..length(data)])
			if cpos = 0 then cpos = length(data)-offset+2 end if
			cookie[2] = data[offset+7..offset+cpos-2]
			-- Offset is base 1.  If the semicolon is in the first position, cpos
			-- is also 1.  Since we don't want to include the semicolon, we need
			-- to subtract 1 for offset's base and 1 to go to the char before
			-- cpos, thus the subtracting of two.  In the case of end of string
			-- (cpos = 0), we need to add those two back to compensate for the
			-- different scenario (+offset-offset = 0 and +2-2 = 0, therefore
			-- cpos = length(data), which is what we want).
		end if
		offset = match("EXPIRES=",updata)
		if offset > 0 then
			cpos = find(';',data[offset..length(data)])
			if cpos = 0 then cpos = length(data)-offset+2 end if
			cookie[4] = data[offset+8..offset+cpos-2]
		end if
		offset = match("VERSION=",updata)
		if offset > 0 then
			cpos = find(';',data[offset..length(data)])
			if cpos = 0 then cpos = length(data)-offset+2 end if
			cookie[6] = data[offset+8..offset+cpos-2]
		end if
		offset = match("MAX-AGE=",updata)
		if offset > 0 then
			cpos = find(';',data[offset..length(data)])
			if cpos = 0 then cpos = length(data)-offset+2 end if
			cookie[4] = data[offset+8..offset+cpos-2]
		end if
		offset = match("SECURE",updata)
		if offset > 0 then
			cookie[5] = "Y"
		end if
		cpos = find('=',cookie[1])
		if cpos > 0 then
			request = cookie[1][1..cpos]
		else
			request = "="
		end if
		cpos = 0
		for ctr = 1 to length(this_cookiejar) do
			if sequence(this_cookiejar[ctr]) and length(this_cookiejar[ctr])>=2 and
					match(cookie[1],this_cookiejar[ctr][1])>0 and
					eu:compare(cookie[2],this_cookiejar[ctr][2])=0 and
					eu:compare(this_cookiejar[ctr][3],cookie[3])=0 then
				this_cookiejar[ctr] = cookie
				cpos = ctr
				exit
			end if
		end for
		if cpos = 0 then
			this_cookiejar = append(this_cookiejar,cookie)
		end if
		cpos = match("SET-COOKIE",upper(header2))
	end while
	
	return {header,body}
end function

-------------------------------------------------------------------------------
-- get_url
-------------------------------------------------------------------------------

--**
-- Returns data from an http internet site. Other common protocols will be added in future versions.
--
-- Parameters:
--		# ##inet_addr##: a sequence holding an address
--		# ##hostname##: a string, the name for the host
-- 		# ##file##: a file name to transmit
--
-- Returns:	
--
--   A **sequence** {header, body} on success, or an empty sequence on error.
--
-- Example 1:
-- <eucode>
-- url = "http://banners.wunderground.com/weathersticker/mini" &
--     "Weather2_metric_cond/language/www/US/PA/Philadelphia.gif"
--
-- temp = get_url(url)
-- if length(temp)>=2 and length(temp[2])>0 then
--     tempfp = open(TEMPDIR&"current_weather.gif","wb")
--     puts(tempfp,temp[2])
--     close(tempfp)
-- end if
-- </eucode>

public function get_url(sequence url)
	sequence node, hostname, protocol, port, file, inet_addr
	sequence data
	atom cpos
	object addrinfo
	
	-- TO DO: If the changes in version 1.2.2 prove stable, remove redundant
	-- code under the search for '?'.
	cpos = match("://",url)
	if cpos > 0 then
		protocol = url[1..cpos-1]
		url = url[cpos+3..length(url)]
	else
		protocol = "http"  -- assumed default
	end if
	cpos = find(':',url)
	if cpos = 0 then
		cpos = find('/',url)
		if cpos = 0 then
			cpos = find('?',url)
			if cpos = 0 then
				hostname = url
				node = url
				port = ""
				file = ""
				url = ""
			else
				node = url[1..cpos-1]
				hostname = url
				port = ""
				file = ""
				url = ""
			end if
		else
			node = url[1..cpos-1]
			url = url[cpos..length(url)]
			cpos = find('?',url)
			if cpos = 0 then
				file = url
				port = ""
				hostname = node
				url = ""
			else
				-- hostname = node&url
				-- file = ""
				hostname = node
				file = url
				port = ""
				url = ""
			end if
		end if
	else
		node = url[1..cpos-1]
		url = url[cpos+1..length(url)]
		cpos = find('/',url)
		if cpos = 0 then
			cpos = find('?',url)
			if cpos = 0 then
				port = url
				hostname = node
				file = ""
				url = ""
			else
				port = url[1..cpos-1]
				hostname = node & url[cpos..length(url)]
				file = ""
				url = ""
			end if
		else
			port = url[1..cpos-1]
			url = url[cpos..length(url)]
			cpos = find('?',url)
			if cpos = 0 then
				hostname = node
				file = url
				url = ""
			else
				--hostname = node & url
				-- file = ""
				hostname = node
				file = url
				url = ""
			end if
		end if
	end if
	
	if length(file)>0 and file[1]='/' then file = file[2..length(file)] end if
	addrinfo = getaddrinfo(node,protocol,0)
	if atom(addrinfo) or length(addrinfo)<1 or length(addrinfo[1])<5 then
		-- attempt to use deprecated methods
		return {} -- failed
	else
		inet_addr = addrinfo[1][5]
	end if
	data = {}
	if eu:compare(lower(protocol),"http")=0 then
		data = get_http(inet_addr,hostname,file)
	end if
	
	return data
	
end function
