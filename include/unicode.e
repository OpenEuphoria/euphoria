-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Unicode
--
-- Unicode is not complete. This API will change, even in 4.1 release.
--
 
-- By default, strings are stored in UCS2. 
-- Actually Eu can store integers up to 0x3fffffff, but I think it is not so efficient for further conversion.
-- yuku 2008

constant M_ALLOC = 16

--****
-- === Types

--**
-- UCS-2 string (0-65535). In C known as wchar_t* (but \0's are allowed)

export type wstring(object s)
	if not sequence(s) then 
		return 0
	end if

	for i = 1 to length(s) do
		if not integer(s[i]) or s[i] < 0 or s[i] > 65535 then
			return 0
		end if
	end for

	return 1
end type

--**
-- ASCII string (0-255), or UTF-8 string. In C known as char* (but \0's are allowed)
export type astring(object s)
	if not sequence(s) then 
		return 0
	end if

	for i = 1 to length(s) do
		if not integer(s[i]) or s[i] < 0 or s[i] > 255 then
			return 0
		end if
	end for

	return 1
end type

--****
-- === Routines
--

--**
-- encode wstring to astring using utf-8

export function utf8_encode(wstring src)
	sequence tmp
	integer pos
	integer c

	tmp = repeat(0, length(src)*3) -- max length 3 times
		pos = 1
		
		for i = 1 to length(src) do
				c = src[i]
				if c <= #007F then
						tmp[pos] = c
						pos += 1
				elsif c <= #07FF then
						tmp[pos] = #C0 + floor(c / #40)
						pos += 1
						tmp[pos] = #80 + and_bits(c, #3F)
						pos += 1
				else
						tmp[pos] = #E0 + floor(c / #1000)
						pos += 1
						tmp[pos] = #80 + and_bits(floor(c / #40), #3F)
						pos += 1
						tmp[pos] = #80 + and_bits(c, #3F)
						pos += 1
				end if          
		end for
		
		return tmp[1..pos-1]
end function

--**
-- decode astring in utf-8 to wstring

export function utf8_decode(astring src)
	sequence tmp
	integer pos, spos
	integer c

		tmp = repeat(0, length(src)) -- max length is the same as source length
		pos = 1
		spos = 1
		
		while 1 do
				c = src[spos]
				if c < #80 then
						tmp[pos] = c
				elsif c < #C0 then
						-- invalid, but just ignore it and put on the dest
						tmp[pos] = c
				elsif c < #E0 then
						tmp[pos] = and_bits(c, #1F) * #40 + and_bits(src[spos+1], #3F)
						spos += 1
				elsif c < #F0 then
						tmp[pos] = and_bits(c, #0F) * #1000 + and_bits(src[spos+1], #3F) * #40 + and_bits(src[spos+2], #3F)
						spos += 2
				else 
						-- not supported, the resultant char is > #FFFF
				end if
				
				pos += 1
				spos += 1

				if spos > length(src) then
						exit
				end if
		end while
		
		return tmp[1..pos-1]
end function

--**
-- Create a C-style null-terminated wchar_t string in memory
--
-- Parameters:
--   * s - a unicode (utf16) string
--
-- Returns:
--   The address of the allocated string

export function allocate_wstring(wstring s)
		atom mem

		mem = machine_func(M_ALLOC, length(s)*2 + 2)
		if mem then
				poke2(mem, s)
				poke2(mem + length(s)*2, 0)
		end if
		
		return mem
end function

--**
-- Return a unicode (utf16) string that are stored at machine address a.
--
-- Parameters:
--   * addr - address of the string in memory
--
-- Returns:
--   The string at the memory position

export function peek_wstring(atom addr)
		atom ptr
		
		ptr = addr
		while peek2u(ptr) do
				ptr += 2
		end while
		
		return peek2u({addr, (ptr - addr) / 2})
end function
