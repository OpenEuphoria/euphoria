--****
-- == HTTP Client
--
-- <<LEVELTOC level=2 depth=4>>
--

namespace http

include std/base64.e
include std/convert.e
include std/rand.e
include std/sequence.e
include std/socket.e as sock
include std/text.e
include std/types.e

include std/net/dns.e
include std/net/url.e as url

include euphoria/info.e

ifdef not EUC_DLL then
include std/task.e
end ifdef

constant USER_AGENT_HEADER = 
	sprintf("User-Agent: Euphoria-HTTP/%d.%d\r\n", {
		version_major(), version_minor() })

enum R_HOST, R_PORT, R_PATH, R_REQUEST
constant FR_SIZE = 4

--****
-- === Error Codes
--

public enum by -1
	ERR_MALFORMED_URL = -1,
	ERR_INVALID_PROTOCOL,
	ERR_INVALID_DATA,
	ERR_INVALID_DATA_ENCODING,
	ERR_HOST_LOOKUP_FAILED,
	ERR_CONNECT_FAILED,
	ERR_SEND_FAILED,
	ERR_RECEIVE_FAILED

--****
-- === Constants

public enum
	FORM_URLENCODED,
	MULTIPART_FORM_DATA
	
public enum
	--**
	-- No encoding is necessary
	ENCODE_NONE = 0,
	--**
	-- Use Base64 encoding
	ENCODE_BASE64

constant ENCODING_STRINGS = {
	"application/x-www-form-urlencoded",
	"multipart/form-data"
}

type natural(integer n)
	return n>=0
end type


--
-- returns: { host, port, path, base_reqest }
--

function format_base_request(sequence request_type, sequence url, object headers)
	sequence request = ""
	sequence formatted_request
	natural noport = 0

	object parsedUrl = url:parse(url)
	if atom(parsedUrl) then
		return ERR_MALFORMED_URL
	elsif not equal(parsedUrl[URL_PROTOCOL], "http") then
		return ERR_INVALID_PROTOCOL
	end if

	sequence host = parsedUrl[URL_HOSTNAME]

	integer port = parsedUrl[URL_PORT]
	if port = 0 then
		port = 80
		noport = 1
	end if

	sequence path
	if sequence(parsedUrl[URL_PATH]) then
		path = parsedUrl[URL_PATH]
	else
		path = "/"
	end if

	if sequence(parsedUrl[URL_QUERY_STRING]) then
		path &= "?" & parsedUrl[URL_QUERY_STRING]
	end if

	-- only specify the port in the request if the caller did so explicitly
	-- some sites, such as euphoria.pastey.net, will break otherwise
	if noport then
		request = sprintf("%s %s HTTP/1.0\r\nHost: %s\r\n", {
			request_type, path, host })
	else
		request = sprintf("%s %s HTTP/1.0\r\nHost: %s:%d\r\n", {
			request_type, path, host, port })
	end if

	integer has_user_agent = 0
	integer has_connection = 0

	if sequence(headers) then
		for i = 1 to length(headers) do
			object header = headers[i]
			if equal(header[1], "User-Agent") then
				has_user_agent = 1
			elsif equal(header[1], "Connection") then
				has_connection = 1
			end if

			request &= sprintf("%s: %s\r\n", header)
		end for
	end if

	if not has_user_agent then
		request &= USER_AGENT_HEADER
	end if
	if not has_connection then
		request &= "Connection: close\r\n"
	end if

	formatted_request = repeat(0, FR_SIZE)
	formatted_request[R_HOST] = host
	formatted_request[R_PORT] = port
	formatted_request[R_PATH] = path
	formatted_request[R_REQUEST] = request
	return formatted_request
end function

--
-- encode a sequence of key/value pairs
--

function form_urlencode(sequence kvpairs)
	sequence data = ""

	for i = 1 to length(kvpairs) do
		object kvpair = kvpairs[i]

		if i > 1 then
			data &= "&"
		end if

		data &= kvpair[1] & "=" & url:encode(kvpair[2])
	end for

	return data
end function

function multipart_form_data_encode(sequence kvpairs, sequence boundary)
	sequence data = ""
	
	for i = 1 to length(kvpairs) do
		object kvpair = kvpairs[i]

		integer enctyp = ENCODE_NONE
		sequence mimetyp = ""
		
		if i > 1 then
			data &= "\r\n"
		end if
		
		data &= "--" & boundary & "\r\n"
		data &= "Content-Disposition: form-data; name=\"" & kvpair[1] & "\""
		if length(kvpair) = 5 then
			data &= "; filename=\"" & kvpair[3] & "\"\r\n"
			data &= "Content-Type: " & kvpair[4] & "\r\n"
			
			switch kvpair[5] do
				case ENCODE_NONE then
				case ENCODE_BASE64 then
					data &= "Content-Transfer-Encoding: base64\r\n"
					kvpair[2] = base64:encode(kvpair[2], 76)
			end switch
		else
			data &= "\r\n"
		end if	
			
		data &= "\r\n" & kvpair[2]
	end for

	return data & "\r\n--" & boundary & "--"
end function

constant rand_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
constant rand_chars_len = length(rand_chars)

function random_boundary(natural len)
	sequence boundary = repeat(0, len)
	
	for i = 1 to len do
		boundary[i] = rand_chars[rand(rand_chars_len)]
	end for
	
	return boundary
end function

--
-- Send an HTTP request
--

function execute_request(sequence host, integer port, sequence request, integer timeout)
	object addrinfo
	integer conn_port
	
	if proxy_port > 0 then
		addrinfo = host_by_name(proxy_ip)
		conn_port = proxy_port
	else
		addrinfo = host_by_name(host)
		conn_port = port
	end if
	
	if atom(addrinfo) or length(addrinfo) < 3 or length(addrinfo[3]) = 0 then
		return ERR_HOST_LOOKUP_FAILED
	end if

	sock:socket sock = sock:create(sock:AF_INET, sock:SOCK_STREAM, 0)

	if sock:connect(sock, addrinfo[3][1], conn_port) != sock:OK then
		return ERR_CONNECT_FAILED
	end if

	if not sock:send(sock, request, 0) = length(request) then
		sock:close(sock)
		return ERR_SEND_FAILED
	end if

	atom start_time = time()
	integer got_header = 0, content_length = -1
	sequence content = ""
	sequence headers = {}
	while time() - start_time < timeout label "top" do
		if got_header and length(content) = content_length then
			exit
		end if

		object has_data = sock:select(sock, {}, {}, timeout)
		if (length(has_data[1]) > 2) and equal(has_data[1][2],1) then
			object data = sock:receive(sock, 0)
			if atom(data) then
				if data = 0 then
					-- zero bytes received, we the 'data' waiting was
					-- a disconnect.
					exit "top"
				else
					return ERR_RECEIVE_FAILED
				end if
			end if

			content &= data
			ifdef not EUC_DLL then
				-- tasking doesn't work currently with EU dlls
				task_yield()
			end ifdef

			if not got_header then
				integer header_end_pos = match("\r\n\r\n", content)
				if header_end_pos then
					-- we have a header, let's parse it and figure out
					-- the content length.
					sequence raw_header = content[1..header_end_pos-1]
					content = content[header_end_pos + 4..$]

					sequence header_lines = split(raw_header, "\r\n")
					headers = append(headers, split(header_lines[1], " "))
					for i = 2 to length(header_lines) do
						object header = header_lines[i]
						sequence this_header = split(header, ": ", , 1)
						this_header[1] = lower(this_header[1])
						headers = append(headers, this_header)

						if equal(lower(this_header[1]), "content-length") then
							content_length = to_number(this_header[2])
						end if
					end for

					got_header = 1
				end if
			end if
		end if
	end while

	return { headers, content }
end function

--****
-- === Configuration Routines

sequence proxy_ip = {}
integer proxy_port = 0

--**
-- Configure http client to use a proxy server
--
-- Parameters:
--   * ##proxy_ip## - IP address of the proxy server
--   * ##proxy_port## - Port of the proxy server
--

public procedure set_proxy_server(sequence ip, integer port)
	proxy_ip = ip
	proxy_port = port
end procedure

--****
-- === Get/Post Routines

--**
-- Post data to a HTTP resource.
--
-- Parameters:
--   * ##url##     - URL to send post request to
--   * ##data##    - Form data (described later)
--   * ##headers## - Additional headers added to request
--   * ##follow_redirects## - Maximum redirects to follow
--   * ##timeout## - Maximum number of seconds to wait for a response
--
-- Returns:
--   An integer error code or a 2 element sequence. Element 1 is a sequence
--   of key/value pairs representing the result header information. element
--   2 is the body of the result.
--
--   If result is a negative integer, that represents a local error condition.
--
--   If result is a positive integer, that represents a HTTP error value from
--   the server.
--
-- Data Sequence:
--  This sequence should contain key value pairs representing the expected form
--  elements of the called URL. For a simple url-encoded form:
--
--  <eucode>
--  { {"name", "John Doe"}, {"age", "22"}, {"city", "Small Town"}}
--  </eucode>
--
--  All Keys and Values should be a sequence.
--
--  If the post requires multipart form encoding then the sequence is a little
--  different. The first element of the data sequence must be [[:MULTIPART_FORM_DATA]].
--  All subsequent field values should be key/value pairs as described above **except**
--  for a field representing a file upload. In that case the sequence should be:
--
--  ##{ FIELD-NAME, FILE-VALUE, FILE-NAME, MIME-TYPE, ENCODING-TYPE }##
--
--  Encoding type can be
--    * [[:ENCODE_NONE]]
--    * [[:ENCODE_BASE64]]
--
--  An example for a multipart form encoded post request data sequence
--
--  <eucode>
--  { 
--    { "name", "John Doe" }, 
--    { "avatar", file_content, "me.png", "image/png", ENCODE_BASE64 },
--    { "city", "Small Town" }
--  }
--  </eucode>
--
-- See Also:
--   [[:http_get]]
--

public function http_post(sequence url, object data, object headers = 0,
		natural follow_redirects = 10, natural timeout = 15)
		
	if not sequence(data) or length(data) = 0 then
		return ERR_INVALID_DATA
	end if

	object request = format_base_request("POST", url, headers)
	if atom(request) then
		return request
	end if

	integer data_type
	if ascii_string(data) or sequence(data[1]) then
		data_type = FORM_URLENCODED
	else
		if data[1] < 1 or data[1] > 2 then
			return ERR_INVALID_DATA_ENCODING
		end if

		data_type = data[1]
		data = data[2]
	end if

	-- data now contains either a string sequence already encoded or
	-- a sequence of key/value pairs to be encoded. We know the length
	-- is greater than 0, so check the first element to see if it's a
	-- sequence or an atom. That will tell us what we have.
	--
	-- If we have key/value pairs then we will need to encode that data
	-- according to our data_type.

	sequence content_type = ENCODING_STRINGS[data_type]
	if sequence(data[1]) then
		-- We have key/value pairs
		if data_type = FORM_URLENCODED then
			data = form_urlencode(data)
		else
			sequence boundary = random_boundary(20)
			content_type &= "; boundary=" & boundary
			data = multipart_form_data_encode(data, boundary)
		end if
	end if

	request[R_REQUEST] &= sprintf("Content-Type: %s\r\n", { content_type })
	request[R_REQUEST] &= sprintf("Content-Length: %d\r\n", { length(data) })
	request[R_REQUEST] &= "\r\n"
	request[R_REQUEST] &= data

	object content = execute_request(request[R_HOST], request[R_PORT], request[R_REQUEST], timeout)
	if follow_redirects and length(content)=2 then
		sequence content_1 = content[1]
		if length(content_1) >= 1 and length(content_1[1]) >= 2 and equal(content_1[2][2], "303") then
			--sequence http_response_code = content[1][1][2]
			-- 301, 302, 307 : must not be redirected without user interaction (RFC 2616)
			for i = 1 to length(content_1) do
				sequence headers_i = content_1[i]
				if equal(headers_i[1],"location") then
					return http_get(headers_i[2], headers, follow_redirects-1, timeout)
				end if
			end for
		end if
	end if
	
	return content
end function

--**
-- Get a HTTP resource.
--
-- Returns:
--   An integer error code or a 2 element sequence. Element 1 is a sequence
--   of key/value pairs representing the result header information. Element
--   2 is the body of the result.
--
--   If result is a negative integer, that represents a local error condition.
--
--   If result is a positive integer, that represents a HTTP error value from
--   the server.
--
-- Example:
--
-- <eucode>
-- include std/console.e -- for display()
-- include std/net/http.e
--
-- object result = http_get("http://example.com") 
-- if atom(result) then 
--    printf(1, "Web error: %d\n", result) 
--     abort(1) 
-- end if 
-- 
-- display(result[1]) -- header key/value pairs
-- printf(1, "Content: %s\n", { result[2] }) 
-- </eucode>
--
-- See Also:
--   [[:http_post]]
--

public function http_get(sequence url, object headers = 0, natural follow_redirects = 10,
		natural timeout = 15)
	object request
		
	request = format_base_request("GET", url, headers)
	
	if atom(request) then
		return request
	end if

	-- No more work necessary, terminate the request with our ending CR LF
	request[R_REQUEST] &= "\r\n"

	object content = execute_request(request[R_HOST], request[R_PORT], request[R_REQUEST], timeout)
	if follow_redirects and length(content)=2 then
		sequence content_1 = content[1] 
		if length(content_1) >= 1 and length(content_1[1]) >= 2 and
				find(content_1[1][2], {"301","302","303","307","308"}) then
			for i = 1 to length(content_1) do
				sequence headers_i = content_1[i]
				if equal(headers_i[1],"location") then
					return http_get(headers_i[2], headers, follow_redirects-1, timeout)
				end if
			end for
		end if
	end if

	return content	
end function
