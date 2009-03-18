-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == HTTP
--
-- Based on EuNet project, version 1.3.2, at SourceForge.
-- http://www.sourceforge.net/projects/eunet.
--
-- <<LEVELTOC depth=2>>

include std/socket.e
include std/text.e

sequence
	this_cookiejar = {},
	sendheader = {}, -- HTTP header sequence , sent to somewhere (usually the server)
	recvheader = {}  -- HTTP header sequence , received from somewhere (usually the server)

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


--****
-- === URL encoding
--

-- TODO: This is not parsing correctly with creole or eudoc

-- HTML form data is usually URL-encoded to package it in a GET or POST submission. In a nutshell, here's how you URL-encode the name-value pairs of the form data:
-- # Convert all "unsafe" characters in the names and values to "%xx", where "xx" is the ascii
--   value of the character, in hex. "Unsafe" characters include =, &, %, +, non-printable
--   characters, and any others you want to encode-- there's no danger in encoding too many
--   characters. For simplicity, you might encode all non-alphanumeric characters.
-- # Change all spaces to pluses.
-- # String the names and values together with = and &, like
--   name1=value1&name2=value2&name3=value3
-- # This string is your message body for POST submissions, or the query string for GET submissions.
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
--	An **object**:
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
--   [[:get_url]]

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
		cookie[1] = _socket_trim(data[1..cpos-1])
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

--**
-- Returns data from an http internet site. Other common protocols will be added in future versions.
--
-- Parameters:
--   # ##inet_addr##: a sequence holding an address
--   # ##hostname##: a string, the name for the host
--   # ##file##: a file name to transmit
--
-- Returns:	
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
