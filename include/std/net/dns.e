--****
-- == DNS
--
-- <<LEVELTOC level=2 depth=4>>
--

namespace dns

/*
include std/get.e
include std/socket.e
*/

--constant BLOCK_SIZE = 4096
enum M_SOCK_GETHOSTBYNAME = 79, M_SOCK_GETHOSTBYADDR

--****
-- ===  Constants

public enum ADDR_FLAGS, ADDR_FAMILY, ADDR_TYPE, ADDR_PROTOCOL, ADDR_ADDRESS

public enum HOST_OFFICIAL_NAME, HOST_ALIASES, HOST_IPS, HOST_TYPE

public constant
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
	NS_T_AAAA = 28,
	NS_T_A6 = 38,
	NS_T_ANY = 255

--****
-- === General Routines

/*
ifdef WINDOWS then
	constant dnsdll_ = open_dll("dnsapi.dll")

	constant getaddrinfo_ = define_c_func(sockdll_,"getaddrinfo",{C_POINTER,C_POINTER,C_POINTER,C_POINTER},C_INT)
	constant dnsquery_ = define_c_func(dnsdll_,"DnsQuery_A",{C_POINTER,C_USHORT,C_INT,C_POINTER,C_POINTER,C_POINTER},C_INT)
	constant dnsrlfree_ = define_c_proc(dnsdll_,"DnsRecordListFree",{C_POINTER,C_INT})
	constant dnsexpand_ = -1
	constant freeaddrinfo_ = define_c_proc(sockdll_,"freeaddrinfo",{C_POINTER})

elsifdef LINUX then
	constant dnsdll_ = open_dll("libresolv.so")

elsifdef BSD then
	constant dnsdll_ = open_dll("libc.so")

elsifdef OSX then
	constant dnsdll_ = open_dll("libresolv.dylib")

end ifdef

ifdef UNIX then
	constant dnsquery_ = define_c_func(dnsdll_,"res_query",{C_POINTER,C_INT,C_INT,C_POINTER,C_INT},C_INT)
	constant dnsrlfree_ = -1
	constant dnsexpand_ = define_c_func(dnsdll_,"dn_expand",{C_POINTER,C_POINTER,C_POINTER,C_POINTER,C_INT},C_INT)
	constant getaddrinfo_ = define_c_func(dll_,"getaddrinfo",{C_POINTER,C_POINTER,C_POINTER,C_POINTER},C_INT)
	constant freeaddrinfo_ = define_c_proc(dll_,"freeaddrinfo",{C_POINTER})
end ifdef

function _socket_trim(sequence s)
	atom c
	sequence rs
	rs = s
	c = 1
	while c <= length(s) and rs[c] <= 32 do
		c = c + 1
	end while
	rs = rs[c .. $]
	c = length(rs)
	while c > 0 and rs[c] <= 32 do
		c = c - 1
	end while
	rs = rs[1..c]
	return rs
end function

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
		line[2] = peek_string(dnameptr)
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
				subx[1] = peek_string(dnameptr)
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
				subx[1] = peek_string(dnameptr)
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
			subx[1] = peek_string(peek4u(recptr+24)) -- Mail server name
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
			subx[1] = peek_string(peek4u(recptr+24)) -- NS server name
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
--		# ##dname## : a string, the name to look up
--		# ##q_type## : an integer, the type of lookup requested
--		# ##options## : an atom,
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
	ifdef WINDOWS then
		return windows_dnsquery(dname, q_type, options)
	elsifdef UNIX then
		return unix_dnsquery(dname, q_type)
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
--		# ##dname## : a string, the name to look up
--		# ##options## : an atom,
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
	
	dname = _socket_trim(dname)
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
--		# ##dname## : a string, the name to look up
--		# ##options## : an atom,
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
	atom addrinfo, success, node_ptr, service_ptr, hints_ptr, addrinfo_ptr, 
		svcport, cpos
	sequence rtn, val
	
	hints = hints -- TODO -- not implemented.
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
		return 0
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
				eu:compare(rtn[1][5][$ - 1 .. $],":0")=0 then
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
	return unix_getaddrinfo(node, service, hints)
end function

--**
-- Retrieve information about a given server name and named service.
--
-- Parameters:
--   # ##node## : an object, ???
--   # ##service## : an object, ???
--   # ##hints## : an object, currently not used
--
-- Returns:
--   A **sequence**, of sequences containing the requested information.
--   The inner sequences have fields that can be accessed with public constants
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
	ifdef WINDOWS then
		return windows_getaddrinfo(node,service,hints)
	elsifdef UNIX then
		return unix_getaddrinfo(node,service,hints)
	end ifdef
	
	return -999
end function
*/

--**
-- Get the host information by name.
--
-- Parameters:
--   # ##name## : host name
--
-- Returns:
--   A ##sequence##, containing
--   <eucode>
--   {
--     official name,
--     { alias1, alias2, ... },
--     { ip1, ip2, ... },
--     address_type
--   }
--   </eucode>
--
-- Example 1:
-- <eucode>
-- object data = host_by_name("www.google.com")
-- -- data = {
-- --   "www.l.google.com",
-- --   {
-- --     "www.google.com"
-- --   },
-- --   {
-- --     "74.125.93.104",
-- --     "74.125.93.147",
-- --     ...
-- --   },
-- --   2
-- -- }
-- </eucode>
--

public function host_by_name(sequence name)
	return machine_func(M_SOCK_GETHOSTBYNAME, { name })
end function

--**
-- Get the host information by address.
--
-- Parameters:
--   # ##address## : host address
--
-- Returns:
--   A ##sequence##, containing
--   <eucode>
--   {
--     official name,
--     { alias1, alias2, ... },
--     { ip1, ip2, ... },
--     address_type
--   }
--   </eucode>
--
-- Example 1:
-- <eucode>
-- object data = host_by_addr("74.125.93.147")
-- -- data = {
-- --   "www.l.google.com",
-- --   {
-- --     "www.google.com"
-- --   },
-- --   {
-- --     "74.125.93.104",
-- --     "74.125.93.147",
-- --     ...
-- --   },
-- --   2
-- -- }
-- </eucode>
--

public function host_by_addr(sequence address)
	return machine_func(M_SOCK_GETHOSTBYADDR, { address })
end function
