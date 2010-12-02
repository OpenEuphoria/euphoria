--****
-- == Common Internet Routines
--
-- <<LEVELTOC level=2 depth=4>>
--

namespace common

include std/get.e
include std/regex.e
include std/sequence.e as seq

constant
	DEFAULT_PORT = 80,
	re_ip = regex:new("""^(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])(\:[0-9]+)?$"""),
	re_http_url = regex:new("""(http|https|ftp|ftps|gopher|gophers)://([^/]+)(/[^?]+)?(\?.*)?""", regex:CASELESS),
	re_mail_url = regex:new("""(mailto):(([^@]+)@([^?]+))(\?.*)?""")

--****
-- === IP Address Handling

--**
-- Checks if x is an IP address in the form (#.#.#.#[:#])
--
-- Parameters:
--   # ##address## : the address to check
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

public function is_inetaddr(sequence address)
	return regex:is_match(re_ip, address)
end function

--**
-- Converts a text "address:port" into {"address", port} format.
--
-- Parameters:
--   # ##address## : ip address to connect, optionally with :PORT at the end
--   # ##port## : optional, if not specified you may include :PORT in
--     the address parameter otherwise the default port 80 is used.
--
-- Comments:
--   If ##port## is supplied, it overrides any ":PORT" value in the input
--   address.
--
-- Returns: 
--   A **sequence**, of two elements: "address" and integer port number.
--
-- Example 1:
-- <eucode>
-- addr = parse_ip_address("11.1.1.1") --> {"11.1.1.1", 80} -- default port
-- addr = parse_ip_address("11.1.1.1:110") --> {"11.1.1.1", 110}
-- addr = parse_ip_address("11.1.1.1", 345) --> {"11.1.1.1", 345}
-- </eucode>

public function parse_ip_address(sequence address, integer port = -1)
	address = seq:split(address, ':')
	
	if length(address) = 1 then
		if port < 0 or port > 65_535 then
			address &= DEFAULT_PORT
		else
			address &= port
		end if
	else
		if port < 0 or port > 65_535 then
			address[2] = stdget:value(address[2])
			if address[2][1] != stdget:GET_SUCCESS then
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

--****
-- === URL Parsing
--

public constant
	URL_ENTIRE        = 1,
	URL_PROTOCOL      = 2,
	URL_HTTP_DOMAIN   = 3,
	URL_HTTP_PATH     = 4,
	URL_HTTP_QUERY    = 5,
	URL_MAIL_ADDRESS  = 3,
	URL_MAIL_USER     = 4,
	URL_MAIL_DOMAIN   = 5,
	URL_MAIL_QUERY    = 6

--**
-- Parse a common URL. Currently supported URLs are http(s), ftp(s), gopher(s) and mailto.
--
-- Parameters:
--   # ##url## : url to be parsed
--
-- Returns:
--   A **sequence**, containing the URL details. You should use the ##URL_## constants
--   to access the values of the returned sequence. You should first check the
--   protocol ([[:URL_PROTOCOL]]) that was returned as the data contained in the
--   return value can be of different lengths.
--
--   On a parse error, -1 will be returned.
--
-- Example 1:
-- <eucode>
-- object url_data = parse_url("http://john.com/index.html?name=jeff")
-- -- url_data = {
-- --     "http://john.com/index.html?name=jeff", -- URL_ENTIRE
-- --     "http",          -- URL_PROTOCOL
-- --     "john.com",      -- URL_DOMAIN
-- --     "/index.html",   -- URL_PATH
-- --     "?name=jeff"     -- URL_QUERY
-- -- }
--
-- url_data = parse_url("mailto:john@mail.doe.com?subject=Hello%20John%20Doe")
-- -- url_data = {
-- --   "mailto:john@mail.doe.com?subject=Hello%20John%20Doe",
-- --   "mailto",
-- --   "john@mail.doe.com",
-- --   "john",
-- --   "mail.doe.com",
-- --   "?subject=Hello%20John%20Doe"
-- -- }
-- </eucode>
--

public function parse_url(sequence url)
	object m

	m = regex:matches(re_http_url, url)
	if sequence(m) then
		if length(m) < URL_HTTP_PATH then
			m &= { "/" }
		end if
		if length(m) < URL_HTTP_QUERY then
			m &= { "" }
		end if

		return m
	end if

	m = regex:matches(re_mail_url, url)
	if sequence(m) then
		if length(m) < URL_MAIL_QUERY then
			m &= { "" }
		end if

		return m
	end if

	return regex:ERROR_NOMATCH
end function
