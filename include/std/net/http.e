--****
-- == HTTP
--
-- <<LEVELTOC depth=2>>

namespace http

include std/socket.e as sock
include std/net/url.e
include std/net/dns.e
include std/text.e
include std/get.e as val
include euphoria/info.e

--****
-- === Constants

public constant
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

sequence
	this_cookiejar = {},
	sendheader = {}, -- HTTP header sequence , sent to somewhere (usually the server)
	recvheader = {},  -- HTTP header sequence , received from somewhere (usually the server)
	defaultsendheader = {} -- a list of what may be sent in the sendheader, and minimum typical values

function eunet_parse(sequence s, object c)
	integer slen, spt, flag
	sequence parsed, upperc, uppers

	upperc = ""
	uppers = ""

	if atom(c) then
		c = {c}
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

--****
-- === Header management
--

--**
-- Retrieve either the whole sendheader sequence, or just a single
-- field.
--
-- Parameters:
--	 # ##field## : an object indicating which part is being requested, see Comments section.
--
-- Returns:
--	 An **object**, either:
--	 * -1 if the field cannot be found,
--	 * ##{{"label","delimiter","value"},...}## for the whole sendheader sequence
--	 * a three-element sequence in the form ##{"label","delimiter","value"}## when only a single field is selected.
--
-- Comments:
--	 ##field## can be either an HTTP_HEADER_xxx access constant,
--	 the number 0 to retrieve the whole sendheader sequence, or
--	 a string matching one of the header field labels.	The string is
--	 not case sensitive.
--

public function get_sendheader(object field)
	-- if field is 0, return the whole sequence.
	-- if field is 1..length(sendheader), return just that field
	-- if field is invalid, return -1. -- no, this is a problem , some code needs a sequence
	-- if field is a sequence, try to match it to sendheader[x][1].

	-- Kat: should i return [1] & [2] as well? Mike: yes
	-- most server interfaces return the only value, saves parsing
	-- we'll return a {"Name","spacer","value"} format

	sequence upperfield

	if sequence(field) then
		upperfield = upper(field)
		for idx = 1 to length(sendheader) do
			if equal(upperfield,upper(sendheader[idx][1])) then
				return sendheader[idx]
			end if
		end for
		return {"","",""}
	elsif field < 0 or field > length(sendheader) then
		return {"","",""}
	elsif field = 0 then
		return sendheader
	else
		return sendheader[field]
	end if
end function

--**
-- Sets header elements to default values. The default User Agent
-- is Opera (currently the most standards compliant).  Before setting
-- any header option individually, programs must call this procedure.
--
-- See Also:
--   [[:get_sendheader]], [[:set_sendheader]], [[:set_sendheader_useragent_msie]]

public procedure set_sendheader_default()
	sequence tempnewheader = {}
	sequence temps = ""
	sequence whoami = "OpenEuphoria " & version_string_long()

	-- this sets some defaults, if not previously set to something by the user
	-- if a header line was previously set by the user, do not change it here
	-- httpversion MUST come before GET in this program: some servers default to 1.0, even if you say 1.1
	-- NO spaces around [3] on httpversion
	-- POSTDATA MUST come before Content-Length in this program
	-- Referer is often used by sites to be sure your fetch was from one of their own pages
	-- headers with [3] = "" won't be sent
	-- you can add more [1], and modify [3], [2] is the ' ' or ": " (GET and POST have no ": ")

	defaultsendheader = {
		{"httpversion","","HTTP/1.0"}, -- not a legal http headerline, but to append to GET or POST later on
		{"GET"," ",""}, -- [3] = the filename you want
		{"POST"," ",""}, -- [3] = the filename you want
		{"Host",": ",""}, -- the domain. You might think this was obvious, but for vhosting sites it's necessary.
		{"Referer",": ",""}, -- i know it's misspelled, but that's official! , the site that sent you to this one
		{"User-Agent",": ", whoami},
		{"Accept-Charset",": ","utf-8,ISO-8859-1;q=0.7,*;q=0.5"},
		{"Accept-Ranges",": ",""},
		{"Authorization",": ",""},
		{"Date",": ",""}, -- who cares if the server has my time? Except for cookie timeouts, that is.
		{"If-Modified-Since",": ",""}, -- for keeping a local cache sync'd
		{"POSTDATA","",""}, -- not a legal headerline, but has to go somewhere; put the POST data here, it will be appended to the bottom later
		{"Content-Type",": ",""}, -- if POST or PUT transaction
		{"Content-Length",": ",""}, -- if POST or PUT transaction
		{"From",": ",""}, -- possible in POST or PUT or Authorization
		{"Keep-Alive",": ",""}, -- set value depending on Connection
		{"Cache-Control",": ",""},
		{"Connection",": ","close"} -- this is usually "close", sometimes "keep-alive" for http/1.1 and SSL, even if you set "close" the server may ignore you
	}


	-- the following not only puts the default header lines,
	-- it sorts the already-set lines to match the defaultsendheader order
	for defaultndx = 1 to length(defaultsendheader) do -- loop through defaultsendheader
		temps = get_sendheader(defaultsendheader[defaultndx][1]) -- see if it was already set to something
		if equal(temps[1],"") then
			tempnewheader &= {defaultsendheader[defaultndx]} -- so set the default line
		else
			tempnewheader &= {temps} -- use the pre-definition
	   end if
	end for

	sendheader = tempnewheader
end procedure

--**
-- Set an individual header field.
--
-- Parameters:
--	 # ##whatheader## : an object, either an explicit name string or a HTTP_HEADER_xxx constant
--	 # ##whatdata## : a string, the associated data
--
-- Comments:
--	 If the requested field is not one of the default header fields,
--   the field MUST be set by string.  This will increase the length
--   of the header overall.
--
-- Example 1:
-- <eucode>
-- set_sendheader("Referer","search.yahoo.com")
-- </eucode>
--
-- See Also:
--	   [[:get_sendheader]]

public procedure set_sendheader(object whatheader, sequence whatdata)
	if atom(whatheader) then
		if whatheader > 0 and whatheader <= length(sendheader) then -- how does this work?
			sendheader[whatheader][3] = whatdata
		end if
		return
	end if

	for idx = 1 to length(sendheader) do
		-- is this whatheader already in sendheader?
		if match(upper(whatheader),upper(sendheader[idx][1])) then
			-- then simply set it to this value
			sendheader[idx][3] = whatdata
			return
		end if
	end for

	-- ok, if we got here, then whatheader isn't in sendheader

	--	you better know what you are doing here!
	-- ": " is supplied as default, lets hope it's not an aberration like GET or POST
	-- this doesn't put it in any correct order
	sendheader = append(sendheader,{whatheader, ": ",whatdata})
end procedure

--**
-- Inform listener that user agent is Microsoft (R) Internet Explorer (TM).
--
-- Comments:
--	 This is a convenience procedure to tell a website that a Microsoft
--	 Internet Explorer (TM) browser is requesting data.  Because some
--	 websites format their response differently (or simply refuse data)
--	 depending on the browser, this procedure provides a quick means
--	 around that.
--      For example, see:
--      http://www.missporters.org/podium/nonsupport.aspx

public procedure set_sendheader_useragent_msie()
	set_sendheader("User-Agent","Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0)")
end procedure

--------------------------------------------------------------------------------
-- this can also be used to flatten the sendheader record, for printing, etc
function eunet_format_sendheader()
	sequence
		tempheader = "",
		temppostdata = "",
		httpversion = ""

	for idx = 1 to length(sendheader) do
		if not equal("httpversion",sendheader[idx][1]) and
				not equal("POSTDATA",sendheader[idx][1])
		then
			-- if the data field is not empty...
			if not equal("",sendheader[idx][3]) then
				switch sendheader[idx][1] with fallthru do
					case "GET" then
						-- remove any trailing nulls
						while find(0, sendheader[idx][3]) do
							sendheader[idx][3][find(0, sendheader[idx][3])] = ' '
						end while
						-- append the http version
						tempheader &= sendheader[idx][1] & sendheader[idx][2] &
							sendheader[idx][3] & " " & httpversion & "\r\n"
						break

					case "POST" then
						-- remove any trailing nulls
						while find(0, sendheader[idx][3]) do
							sendheader[idx][3][find(0, sendheader[idx][3])] = ' '
						end while
						-- append the http version
						tempheader &= sendheader[idx][1] & sendheader[idx][2] &
							sendheader[idx][3] & " " & httpversion & "\r\n"
						break

					case else
						-- remove any trailing nulls
						while find(0, sendheader[idx][3]) do
							sendheader[idx][3][find(0, sendheader[idx][3])] = ' '
						end while
						-- else just flatten the sequence
						tempheader &= sendheader[idx][1] & sendheader[idx][2] &
							sendheader[idx][3] & "\r\n"
				end switch
			end if
		end if

		-- this is done here because
		-- this is where the POSTDATA is moved to the bottom of the header,
		-- the Content-length and Content-Type is filled in

		if equal("POSTDATA",sendheader[idx][1]) and not equal("",sendheader[idx][3]) then
			-- POSTDATA was set to something
			set_sendheader("Content-Type","application/x-www-form-urlencoded")
			temppostdata = sendheader[idx][3]
			set_sendheader("Content-Length",sprintf("%d",length(temppostdata)))
			sendheader[idx][3] = "" -- clear it, so it's not accidentally sent again
		end if

		if equal("httpversion",sendheader[idx][1]) and not equal("",sendheader[idx][3]) then
			httpversion = sendheader[idx][3]
		end if
	end for

	tempheader &= "\r\n" -- end of header
	if not equal(temppostdata,"") then-- but if there's POST data,
		 tempheader = tempheader & temppostdata  & "\r\n" -- tack that on too
	end if

	return tempheader
end function

--**
-- Populates the internal sequence recvheader from the flat string header.
--
-- Parameters:
--	 # ##header## : a string, the header data
--
-- Comments:
--	 This must be called prior to calling [[:get_recvheader]]().

public procedure parse_recvheader(sequence header)
	sequence junk
	atom place

	junk = {"",""} -- init it, it looks like this
	recvheader = eunet_parse(header,{10,13}) -- could be \n or \r or both
	for idx = 1 to length(recvheader) do
		place = match(": ",recvheader[idx])
		if place then
			junk[1] = recvheader[idx][1..place-1]
			junk[2] = recvheader[idx][place+2 .. $]
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
--	 # ##field## : an object, either a string holding a field name (case insensitive),
--	   0 to return the whole header, or a numerical index.
--
-- Returns:
--	 An **object**,
--	 * -1 on error
--	 * a sequence in the form, ##{field name, field value}## on success.

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

	if sequence(field) and equal(field,"") then
		return -1
	end if

	if atom(field) then
		if ( field <= 0 ) or ( field > length(recvheader) ) then
			return -1
		end if

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

--****
-- === Web interface
--

--**
-- Returns data from an http internet site.
--
-- Parameters:
--	 # ##inet_addr## : a sequence holding an address
--	 # ##hostname## : a string, the name for the host
--	 # ##file## : a file name to transmit
--
-- Returns:
--	 A **sequence**, empty sequence on error, of length 2 on success,
--	 like ##{sequence header, sequence data}##.

public function get_http(sequence inet_addr, sequence hostname, sequence file, integer timeout = 300, integer port = 80)
	object junk, junk2, header
	sock:socket sock
	atom success, last_data_len, gotheader, contentlen, last
	sequence data

	-- Notes for future additions:
	-- HUGE differences in HTTP/1.1 vs HTTP/1.0
	-- GET /index.html HTTP/1.1

	if length(inet_addr)=0 then
		return {"",""}
	end if

	if length(file)=0 or file[1]!='/' then
		file = '/' & file
	end if

	junk = get_sendheader("POSTDATA")
	-- was the POSTDATA set?
	if equal(junk[3],"") then
		-- if no, assume it's a GET
		set_sendheader("GET",file)
	else
		-- if so, then it's definitely a POST (err, or PUT, but we don't do PUT)
		set_sendheader("POST",file)
	end if

	-- This is required for virtual shared hosting. On dedicated boxes on fixed ip,
	-- you can http to the ip, and GET/POST is enough to deal with it. Setting it is
	-- safe, either way.
	set_sendheader("HOST",hostname)

	last_data_len = 0
	sock = sock:create(AF_INET,SOCK_STREAM,0)
	success = sock:connect(sock,inet_addr,port)
 	
	if success = sock:OK then
		-- eunet_format_sendheader sets up the header to sent,
		-- putting the POST data at the end,
		-- filling in the CONTENT-LENGTH,
		-- and avoiding sending empty fields for any field
		success = sock:send(sock,eunet_format_sendheader(),0)
 
		-- } end version 1.3.0 mod
		data = ""
		header= {}
		contentlen = 0
		gotheader = 0
				if success 
					then		
				   last = time()
				   while sequence(junk) with entry do
					data = data & junk
					if gotheader and equal(contentlen,length(data)) then 
					   exit  -- we got all the server said it had
					end if
					if not gotheader and match({13,10,13,10},data) then -- we got the header in there
									  header = data[1..match({13,10,13,10},data)-1] -- split off the header
							  data = data[match({13,10,13,10},data)+4..$] -- and the data is what's left, we keep using data in the sock loop
							  parse_recvheader(header) -- sets up recvheader -- global var
							  junk = get_recvheader("Content-Length")
							  if not equal(junk,-1) then
								  junk = val:value(junk[2])
								  contentlen = junk[2]
								  if equal(contentlen,0) then exit end if -- there's no more
								  if equal(contentlen,length(data)) then exit end if -- there's no more
						   end if       
							  gotheader = 1 -- we got what we came for here
					end if
				entry

 				        junk2 = sock:select(sock, {}, {}, timeout) -- status check
 						-- Do we have readable data?
 				        if (length(junk2[1]) > 2)  and equal(junk2[1][2],1) then
							last = time()
							junk = sock:receive(sock, 0) -- then recieve it
					else
							-- assume server has hung, abort
							exit
					end if
				end while
			else
				header = -1
				data = "could not send or recieve using socket"
		end if -- if success -- sock:send
	else 
		header = -1
		data = "could not connect to socket"
	end if -- if success = 1 then -- sock:connect
	if sock:close(sock) then end if

	-- clear any POSTDATA
		set_sendheader("POSTDATA", "")
	set_sendheader("POST", "")
	set_sendheader("GET", "")
	set_sendheader("Content-Type", "")
	set_sendheader("Content-Length", "0")
	set_sendheader_default()

	return {header,data}
end function

--**
-- Works the same as [[:get_url]](), but maintains an internal
-- state register based on cookies received.
--
-- Warning:
--   This function is not yet implemented.
--
-- Parameters:
--	 # ##inet_addr## : a sequence holding an address
--	 # ##hostname## : a string, the name for the host
--	 # ##file## : a file name to transmit
--
-- Returns:
--	 A **sequence**, {header, body} on success, or an empty sequence on error.
--
-- Example 1:
-- <eucode>
-- addrinfo = getaddrinfo("www.yahoo.com","http",0)
-- if atom(addrinfo) or length(addrinfo) < 1 or
--     length(addrinfo[1]) < 5 then
--     puts(1,"Uh, oh")
--     return {}
-- else
--     inet_addr = addrinfo[1][5]
-- end if
-- data = get_http_use_cookie(inet_addr,"www.yahoo.com","")
-- </eucode>
--
-- See also:
--	 [[:get_url]]

public function get_http_use_cookie(sequence inet_addr, sequence hostname, sequence file)
/*
	atom socket, success, last_data_len, cpos, offset
	sequence header, header2, body, data, updata
	sequence cookielist, request, cookie
	object junk -- a general throwaway temp var

	cookielist = {}
	request = ""
	-- cookie = {name,domain,path,expires,encrypted,version}

	if length(inet_addr)=0 then
		return {"",""}
	end if

	if length(file)=0 or file[1]!='/' then file = '/'&file end if

	-- was the POSTDATA set?
	junk = get_sendheader("POSTDATA")
	if equal(junk[3],"")  then
		-- if no, assume it's a GET
		set_sendheader("GET",file)
	else
		-- if so, then it's definitely a POST (err, or PUT, but we don't do PUT)
		set_sendheader("POST",file)
	end if

	-- This is required for virtual shared hosting.
	-- On dedicated boxes on fixed ip,
	-- you can http to the ip, and GET/POST is enough to deal with it.
	-- Setting it is safe, either way.
	set_sendheader("HOST",hostname)

	for ctr = 1 to length(this_cookiejar) do
		if sequence(this_cookiejar[ctr]) and length(this_cookiejar[ctr])>=2 and
				sequence(this_cookiejar[ctr][1]) and
				(match(hostname,this_cookiejar[ctr][2])>0 or match(this_cookiejar[ctr][2],hostname)>0) and
				(length(file)=0 or match(this_cookiejar[ctr][3],file)>0)
		then
			cookielist = append(cookielist,this_cookiejar[ctr])
		end if
	end for

	-- TO DO: Sort cookielist by domain, path (longer path before shorter path)
	--	request = sprintf("GET /%s HTTP/1.0\nHost: %s\n",{file,hostname})
	for idx = 1 to length(cookielist) do
		--	  if idx = 1 then
		--		request = request & "Cookie: "&cookielist[idx][1]
		--	  else
		--		request = request & "		 "&cookielist[idx][1]
		--	  end if
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
	--	request = request & "\n"
	set_sendheader("Cookie",request)

	data = {}
	last_data_len = 0
	socket = sock:create(AF_INET,SOCK_STREAM,0)
	success = sock:connect(AF_INET, socket,inet_addr)
	if success = 0 then
		--	  success = sock:send(socket,request,0)
		success = sock:send(socket,eunet_format_sendheader(),0)
		-- } end version 1.3.0 modification
		if success > 0 then
					junk = sock:receive(sock, 0)
			while sequence(junk) do
				data = data & junk
				if gotheader and equal(contentlen,length(data)) then 
				   exit  -- we got all the server said it had
				end if
				if not gotheader and match({13,10,13,10},data) then -- we got the header in there
								  header = data[1..match({13,10,13,10},data)-1] -- split off the header
						  data = data[match({13,10,13,10},data)+4..$] -- and the data is what's left, we keep using data in the sock loop
						  parse_recvheader(header) -- sets up recvheader -- global var
						  junk = get_recvheader("Content-Length")
						  if not equal(junk,-1) then
							  junk = val:value(junk[2])
							  contentlen = junk[2]
							  if equal(contentlen,0) then exit end if -- there's no more
							  if equal(contentlen,length(data)) then exit end if -- there's no more
					   end if       
						  gotheader = 1 -- we got what we came for here
				end if
				junk = sock:receive(sock, 0)
			end while
		 end if
	end if
	if close_socket(socket) then end if


	header2 = header
	cpos = match("SET-COOKIE",upper(header2)) -- this should be using get_recvheader() etc
	while cpos > 0 do
		header2 = header2[cpos+10 .. $]
		data = header2
		cpos = find(':',data)
		if cpos > 0 then
			data = data[cpos+1..$]
		end if
		offset = 0
		cpos = match(13&10,data)
		while cpos > 1 and data[offset+cpos-1]=';' do
			offset = offset + cpos + 2
			cpos = match(13&10,data[offset..$])
		end while
		offset = offset + cpos - 1
		data = data[1..offset]
		updata = upper(data)
		cookie = {"","","","","N",""}
		offset = match("PATH=",updata)
		if offset > 0 then
			cpos = find(';',data[offset .. $])
			if cpos = 0 then cpos = length(data)-offset+2 end if
			cookie[3] = data[offset+5..offset+cpos-2]
		end if
		cpos = find(';',data)
		if cpos = 0 then cpos = length(data)+1 end if
		cookie[1] = _socket_trim(data[1..cpos-1])
		if cpos > length(data) then
			data = ""
			updata = ""
		else
			data = data[cpos+1 .. $]
			updata = updata[cpos+1..length(data)]
		end if
		offset = match("DOMAIN=",updata)
		if offset > 0 then
			cpos = find(';',data[offset .. $])
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
			cpos = find(';',data[offset .. $])
			if cpos = 0 then cpos = length(data)-offset+2 end if
			cookie[4] = data[offset+8..offset+cpos-2]
		end if
		offset = match("VERSION=",updata)
		if offset > 0 then
			cpos = find(';',data[offset..$])
			if cpos = 0 then cpos = length(data)-offset+2 end if
			cookie[6] = data[offset+8..offset+cpos-2]
		end if
		offset = match("MAX-AGE=",updata)
		if offset > 0 then
			cpos = find(';',data[offset..$])
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

	-- clear any POSTDATA
	set_sendheader("POSTDATA", "")
	set_sendheader("POST", "")
	set_sendheader("GET", "")
	set_sendheader("Content-Type", "")
	set_sendheader("Content-Length", "0")
	set_sendheader_default()

	return {header,body}
*/
	return -1
end function

--**
-- Returns data from an http internet site.
--
-- Parameters:
--	 # ##url##: URL to access
--	 # ##post_data##: Optional post data
--
-- Returns:
--	 A **sequence** {header, body} on success, or an empty sequence on error.
--
-- Comments:
--   If ##post_data## is empty, then a normal GET request is done. If ##post_data## is non-empty
--	 then ##get_url## will perform a POST request and supply ##post_data## during the request.
--	 
-- Example 1:
-- <eucode>
-- url = "http://banners.wunderground.com/weathersticker/mini" &
--	   "Weather2_metric_cond/language/www/US/PA/Philadelphia.gif"
--
-- temp = get_url(url)
-- if length(temp)>=2 and length(temp[2])>0 then
--	   tempfp = open(TEMPDIR&"current_weather.gif","wb")
--	   puts(tempfp,temp[2])
--	   close(tempfp)
-- end if
-- </eucode>

public function get_url(sequence url, sequence post_data="")
	object addrinfo, url_data

	url_data = parse(url)
	if atom(url_data) then return 0 end if

	addrinfo = host_by_name(url_data[URL_HOSTNAME])
	if atom(addrinfo) or length(addrinfo) < 3 or length(addrinfo[3]) = 0 then
		return 0
	end if

	set_sendheader("POSTDATA", post_data)

	if url_data[URL_PORT] = 0 then
		-- url didn't specify a port, so default to 80
		url_data[URL_PORT] = 80
	end if

	sequence data = {"",""}
	if eu:compare(lower(url_data[URL_PROTOCOL]),"http") = 0 then
		data = get_http(addrinfo[3][1],  url_data[URL_HOSTNAME],
			url_data[URL_PATH] & url_data[URL_QUERY_STRING], , url_data[URL_PORT])
	end if

	return data
end function

-- set the lines in the "proper" order for sending, not that the defaults will get sent.
set_sendheader_default()

