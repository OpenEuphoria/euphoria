namespace http2

include std/socket.e as sock
include std/net/url.e as url
include std/net/dns.e
include std/sequence.e
include std/text.e
include std/convert.e
include euphoria/info.e

constant USER_AGENT_HEADER = sprintf("User-Agent: Euphoria-HTTP/%d.%d\r\n", {
		version_major(), version_minor() })

--****
-- === Error Codes
--

public enum
	ERR_MALFORMED_URL = -1000,
	ERR_INVALID_PROTOCOL,
	ERR_HOST_LOOKUP_FAILED,
	ERR_CONNECT_FAILED,
	ERR_SEND_FAILED,
	ERR_RECEIVE_FAILED

--**
-- Get an HTTP resource.
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
-- See Also:
--   [[http_post]]
--

public function http_get(sequence url, object headers = 0, integer follow_redirects = 10, integer timeout = 15)
	sequence request = ""

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

	request = sprintf("GET %s HTTP/1.1\r\nHost: %s:%d\r\n", {
		path, host, port })

	integer has_user_agent = 0

	if sequence(headers) then
		for i = 1 to length(headers) do
			object header = headers[i]
			if equal(header[1], "User-Agent") then
				has_user_agent = 1
			end if

			request &= sprintf("%s: %s\r\n", header)
		end for
	end if

	if not has_user_agent then
		request &= USER_AGENT_HEADER
	end if

	request &= "\r\n"

	object addrinfo = host_by_name(host)
	if atom(addrinfo) or length(addrinfo) < 3 or length(addrinfo[3]) = 0 then
		return ERR_HOST_LOOKUP_FAILED
	end if

	sock:socket sock = sock:create(sock:AF_INET, sock:SOCK_STREAM, 0)

	if sock:connect(sock, addrinfo[3][1], port) != sock:OK then
		return ERR_CONNECT_FAILED
	end if

	if not sock:send(sock, request, 0) = length(request) then
		sock:close(sock)
		return ERR_SEND_FAILED
	end if

	atom start_time = time()
	integer got_header = 0, content_length = 0
	sequence content = ""
	sequence body = ""
	headers = {}
	while time() - start_time < timeout do
		if got_header and length(content) = content_length then
			exit
		end if

		object has_data = sock:select(sock, {}, {}, timeout)
		if (length(has_data[1]) > 2) and equal(has_data[1][2],1) then
			object data = sock:receive(sock, 0)
			if atom(data) then
				return ERR_RECEIVE_FAILED
			end if

			content &= data

			if not got_header then
				integer header_end_pos = match("\r\n\r\n", content)
				if header_end_pos then
					-- we have a header, let's parse it and figure out
					-- the content length.
					sequence raw_header = content[1..header_end_pos]
					content = content[header_end_pos + 4..$]

					sequence header_lines = split(raw_header, "\r\n")
					headers = append(headers, split(header_lines[1], " "))
					for i = 2 to length(header_lines) do
						object header = header_lines[i]
						sequence this_header = split(header, ": ", , 1)
						this_header[1] = lower(this_header[1])
						headers = append(headers, this_header)

						if equal(this_header[1], "content-length") then
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

ifdef TEST then
	object r = http_get("http://test.openeuphoria.org/post_test.txt", , 8)
	if sequence(r) then
		puts(1, r[2])
	end if
end ifdef
