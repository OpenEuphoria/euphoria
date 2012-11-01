--****
-- == URL handling
-- 
-- <<LEVELTOC level=2 depth=4>>
--

namespace url

include std/get.e
include std/map.e

--****
-- === Parsing
-- 

constant 
	PAIR_SEP_A = '&',
	PAIR_SEP_B = ';',
	HEX_SIG    = '%',
	WHITESPACE = '+',
	VALUE_SEP  = '=',
	$

--**
-- Parse a query string into a map
-- 
-- Parameters:
--   # ##query_string##: Query string to parse
-- 
-- Returns:
--   [[:map]] containing the key/value pairs
--
-- Example 1:
-- <eucode>
-- map qs = parse_querystring("name=John&age=18")
-- printf(1, "%s is %s years old\n", { map:get(qs, "name"), map:get(qs, "age) })
-- </eucode>
-- 

public function parse_querystring(object query_string)
	integer i, char
	object tmp
	sequence charbuf, fname=""
	map:map the_map = map:new()

	if atom(query_string) then
		return the_map
	end if

	charbuf = {}  
	i = 1
	while i <= length(query_string) do
		char = query_string[i]  -- character we're working on
		switch char do
			case HEX_SIG then
				tmp = stdget:value("#" & query_string[i+1] & query_string[i+2])
				charbuf &= tmp[2]
				i += 2 -- skip over hex digits
				
			case WHITESPACE then
				charbuf &= " "
				
			case VALUE_SEP then
				fname = charbuf
				charbuf = {}
				
			case PAIR_SEP_A, PAIR_SEP_B then
				map:put(the_map, fname, charbuf)
				fname = {}
				charbuf = {}
				
			case else
				charbuf &= char
				
		end switch
		i += 1
	end while

	if length(fname) then
		map:put(the_map, fname, charbuf)
	end if

	return the_map
end function

--****
-- === URL Parse Accessor Constants
--
-- Use with the result of [[:parse]].
--
-- Notes:
--   If the host name, port, path, username, password or query string are not part of the 
--   URL they will be returned as an integer value of zero.
--

public enum 
	--**
	-- The protocol of the URL
	URL_PROTOCOL, 

	--**
	-- The hostname of the URL
	URL_HOSTNAME, 

	--**
	-- The TCP port that the URL will connect to
	URL_PORT, 

	--**
	-- The protocol-specific pathname of the URL
	URL_PATH,

	--**
	-- The username of the URL
	URL_USER,

	--**
	-- The password the URL
	URL_PASSWORD, 

	--**
	-- The HTTP query string
	URL_QUERY_STRING

--**
-- Parse a URL returning its various elements.
-- 
-- Parameters:
--   # ##url##: URL to parse
--   # ##querystring_also##: Parse the query string into a map also?
--   
-- Returns: 
--   A multi-element sequence containing:
--   # protocol
--   # host name
--   # port
--   # path
--   # user name
--   # password
--   # query string
--   
--   Or, zero if the URL could not be parsed.
-- 
-- Notes:
--   If the host name, port, path, username, password or query string are not part of the 
--   URL they will be returned as an integer value of zero.
--   
-- Example 1:
-- <eucode>
-- sequence parsed = 
--       parse("http://user:pass@www.debian.org:80/index.html?name=John&age=39")
-- -- parsed is
-- -- { 
-- --     "http",
-- --     "www.debian.org",
-- --     80,
-- --     "/index.html",
-- --     "user",
-- --     "pass",
-- --     "name=John&age=39"
-- -- }
-- </eucode>
-- 

public function parse(sequence url, integer querystring_also=0)
    sequence protocol = ""
    object host_name, path, user_name, password, query_string
    integer port
    
    -- Set the defaults for some optional values
    host_name = 0
    port = 0
    path = 0
    user_name = 0
    password  = 0
    query_string = 0

	integer pos = find(':', url)
    if not pos then
        return 0
    end if

	protocol = url[1..pos - 1]
    pos += 1

	-- Can have a maximum of 2 // before we move into the hostname or possibly 
    -- the path (http://john.com) or (file:///home/jeremy/hello.txt)
    if url[pos] = '/' then
        pos += 1
    end if
    if url[pos] = '/' then
        pos += 1
    end if
	if url[pos] = '/' then
        -- We do not have a username, password, host or port, we have moved right into 
        -- the path area of the URL. Let's jump ahead
        goto "parse_path"
    end if

	integer at = find('@', url)
    if not at then
        -- We do not have a user or password, skip ahead to parsing the domain
        goto "parse_domain"
    end if
    
    integer password_colon = find(':', url, pos)
    if password_colon > 0 and password_colon < at then
        -- We have a password too!
        user_name = url[pos..password_colon-1]
        password = url[password_colon+1..at-1]
    else
    	-- Just a user name
    	user_name = url[pos..at-1]
    end if
    
    pos = at + 1

label "parse_domain"
	
    integer qs_start = find('?', url, pos)
	integer first_slash = find('/', url, pos)
    integer port_colon = find(':', url, pos)
    
    if port_colon then
        -- We can easily read the host until the port colon
        host_name = url[pos..port_colon-1]
    else
    	-- Gotta go through a bit more complex way of getting the path
        if not first_slash then
            -- there is no path, thus we must parse to either the query string begin
            -- or the string end
            if not qs_start then
                host_name = url[pos..$]
            else
            	host_name = url[pos..qs_start-1]
            end if
        else
        	-- Ok, we can read up to the first slash
        	host_name = url[pos..first_slash-1]
        end if
    end if
    
    if port_colon then
        integer port_end = 0

		if first_slash then
            port_end = first_slash - 1
        elsif qs_start then
            port_end = qs_start - 1
        else
        	port_end = length(url)
        end if

		port = stdget:defaulted_value(url[port_colon+1..port_end], 0)
    end if
    
    -- Increment the position to the next element to parse
    if first_slash then
        pos = first_slash
    elsif qs_start then
        pos = qs_start
    else
    	-- Nothing more to parse
        goto "parse_done"
    end if
    
label "parse_path"
	
    if not qs_start then
        path = url[pos..$]
        goto "parse_done"
    end if

	-- Avoid getting a path when there is none.
    if pos != qs_start then
        path = url[pos..qs_start - 1]
    end if

    pos = qs_start

label "parse_query_string"

	query_string = url[qs_start + 1..$]
    
    if querystring_also and length(query_string) then
        query_string = parse_querystring(query_string)
    end if

label "parse_done"
    return { protocol, host_name, port, path, user_name, password, query_string }
end function

--****
-- === URL encoding and decoding
--

-- TODO: This is causing a creole parsing problem
-- HTML form data is usually URL-encoded to package it into a GET or POST submission.
-- In a nutshell, here's how you URL-encode the name-value pairs of the form data:
-- # Convert all "unsafe" characters in the names and values to "%xx", where "xx" is the ascii
--	 value of the character, in hex. "Unsafe" characters include =, &, %, +, non-printable
--	 characters, and any others you want to encode-- there's no danger in encoding too many
--	 characters. For simplicity, you might encode all non-alphanumeric characters.
--	 A big nono is \n and \r chars in POST data.
-- # Change all spaces to pluses.
-- # String the names and values together with = and &, like
--	 name1=value1&name2=value2&name3=value3
-- # This string is your message body for POST submissions, or the query string for GET submissions.
--
-- For example, if a form has a field called "name" that's set to "Lucy", and a field called "neighbors"
-- that's set to "Fred & Ethel", the URL-encoded form data would be:
--
--	  name=Lucy&neighbors=Fred+%26+Ethel <<== note no \n or \r
--
-- with a length of 34.

constant
	alphanum = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz01234567890",
	hexnums = "0123456789ABCDEF"

--**
-- Converts all non-alphanumeric characters in a string to their
-- percent-sign hexadecimal representation, or plus sign for
-- spaces.
--
-- Parameters:
--	 # ##what## : the string to encode
--	 # ##spacecode## : what to insert in place of a space
--
-- Returns:
--	 A **sequence**, the encoded string.
--
-- Comments:
--	 ##spacecode## defaults to ##+## as it is more correct, however, some sites
--	 want ##%20## as the space encoding.
--
-- Example 1:
-- <eucode>
-- puts(1, encode("Fred & Ethel"))
-- -- Prints "Fred+%26+Ethel"
-- </eucode>
-- 
-- See Also:
--   [[:decode]]
--   

public function encode(sequence what, sequence spacecode="+")
	sequence encoded = ""
	object junk = "", junk1, junk2

	for idx = 1 to length(what) do
		if find(what[idx],alphanum) then
			encoded &= what[idx]

		elsif equal(what[idx],' ') then
			encoded &= spacecode

		elsif 1 then
			junk = what[idx]
			junk1 = floor(junk / 16)
			junk2 = floor(junk - (junk1 * 16))
			encoded &= "%" & hexnums[junk1+1] & hexnums[junk2+1]
		end if
	end for

	return encoded
end function

--**
-- Convert all encoded entities to their decoded counter parts
-- 
-- Parameters:
--   # ##what##: what value to decode
--   
-- Returns:
--   A decoded sequence
--   
-- Example 1:
-- <eucode>
-- puts(1, decode("Fred+%26+Ethel"))
-- -- Prints "Fred & Ethel"
-- </eucode>
-- 
-- See Also:
--   [[:encode]]
--   

public function decode(sequence what)
  integer k = 1
  
  while k <= length(what) do
    if what[k] = '+' then
      what[k] = ' ' -- space is a special case, converts into +
    elsif what[k] = '%' then
      if k = length(what) then
        -- strip empty percent sign
        what = what[1..k-1] & what[k+1 .. $]
      elsif k+1 = length(what) then
        what[k] = stdget:value("#0" & decode_upper(what[k+1]))
        what[k] = what[k][2]
        what = what[1..k] & what[k+2 .. $]
      else
        what[k] = stdget:value("#" & decode_upper(what[k+1..k+2]))
        what[k] = what[k][2]
        what = what[1..k] & what[k+3 .. $]
      end if
    else
        -- do nothing if it is a regular char ('0' or 'A' or etc)
    end if

    k += 1
  end while

  return what
end function

function decode_upper(object x)
  return x - (x >= 'a' and x <= 'z') * ('a' - 'A')
end function
