--****
-- == URL handling
-- 

namespace url

include std/get.e

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
      what[k] = value("#" & what[k+1..k+2])
      what[k] = what[k][2]
      what = what[1..k] & what[k+3..length(what)]
    else
        -- do nothing if it is a regular char ('0' or 'A' or etc)
    end if

    k += 1
  end while

  return what
end function
