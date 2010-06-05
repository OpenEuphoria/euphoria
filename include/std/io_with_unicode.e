
public enum
	ANSI,
	UTF,
	UTF_8,
	UTF_16,
	UTF_16BE,
	UTF_16LE,
	UTF_32,
	UTF_32BE,
	UTF_32LE,
	$
	
--**
-- Read the contents of a file as a single sequence of bytes.
--
-- Parameters:
--		# ##file## : an object, either a file path or the handle to an open file.
--      # ##as_text## : integer, **BINARY_MODE** (the default) assumes //binary mode// that
--                     causes every byte to be read in,
--                     and **TEXT_MODE** assumes //text mode// that ensures that
--                     lines end with just a Ctrl-J (NewLine) character,
--                     and the first byte value of 26 (Ctrl-Z) is interpreted as End-Of-File.
--		# ##encoding##: An integer. One of 	ANSI, UTF, UTF_8, UTF_16, UTF_16BE,
--                     UTF_16LE, UTF_32, UTF_32BE, UTF_32LE. The default is ANSI.
--
-- Returns:
--		A **sequence**, holding the entire file. 
--
-- Comments
-- * When using BINARY_MODE, each byte in the file is returned as an element in
--   the return sequence.
-- * When not using BINARY_MODE, the file will be interpreted as a text file. This
-- means that all line endings will be transformed to a single 0x0A character and
-- the first 0x1A character (Ctrl-Z) will indicate the end of file (all data after this 
-- will not be returned to the caller.)
-- * Text files are always returned as UTF_32 encoded files.
-- * Encoding ...
-- ** ANSI: no interpretation of the file data is done. All bytes are simply returned
-- as characters.
-- ** UTF: The file data is examined to work out which UTF encoding method was used
-- to create the file. If the file starts with a valid Byte Order Marker (BOM) it can
-- quickly decide between UTF_8, UTF_16 and UTF_32. For files without a BOM, 
-- if the file is completely valid UTF_8 encoding then that is what is used. Failing
-- that, if there are no null bytes, the ANSI is assumed. Failing that, it is tested
-- for being a valid UTF_16 or UTF_32 format. As a last resort, it will be assumed to
-- be an ANSI file.
-- ** UTF_8: Any valid UTF_8 BOM is removed and the data is converted to UTF_32 
-- format before returning. This means that if it contains any invalidly encoded
-- Unicode characters, they will be ignored.
-- ** UTF_16: Any valid UTF_16 BOM is removed and the data is converted to UTF_32 
-- format before returning. This means that if it contains any invalidly encoded
-- Unicode characters, they will be ignored.
-- ** UTF_16LE: Any valid little-endian UTF_16 BOM is removed and the data is converted to UTF_32 
-- format before returning. This means that if it contains any invalidly encoded
-- Unicode characters, they will be ignored.
-- ** UTF_16BE: Any valid big-endian UTF_16 BOM is removed and the data is converted to UTF_32 
-- format before returning. This means that if it contains any invalidly encoded
-- Unicode characters, they will be ignored.
-- ** UTF_32: Any valid UTF_32 BOM is removed.
-- ** UTF_32LE: Any valid little-endian UTF_32 BOM is removed.
-- ** UTF_32BE: Any valid big-endian UTF_32 BOM is removed.
-- * If one of the UTF_32 encodings is supplied, invalid Unicode characters are 
-- not stripped out but are returned in the file data.
--
-- Example 1:
-- <eucode>
-- data = read_file("my_file.txt")
-- -- data contains the entire contents of ##my_file.txt##
-- </eucode>
--
-- Example 2:
-- <eucode>
-- fh = open("my_file.txt", "r")
-- data = read_file(fh)
-- close(fh)
--
-- -- data contains the entire contents of ##my_file.txt##
-- </eucode>
--
-- Example 3:
-- <eucode>
-- data = read_file("my_file.txt", TEXT_MODE, UTF_8)
-- -- The UTF encoded contents of ##my_file.txt## is stored in 'data' as UTF_32
-- </eucode>
--
--
-- See Also:
--     [[:write_file]], [[:read_lines]]

public function read_file(object file, integer as_text = BINARY_MODE, integer encoding = ANSI)
	integer fn
	integer len
	sequence ret
	object temp
	atom adr

	if sequence(file) then
		fn = open(file, "rb")
	else
		fn = file
	end if
	if fn < 0 then return -1 end if

	temp = seek(fn, -1)
	len = where(fn)
	temp = seek(fn, 0)

	ret = repeat(0, len)
	for i = 1 to len do
		ret[i] = getc(fn)
	end for

	if sequence(file) then
		close(fn)
	end if

	ifdef WINDOWS then
		-- Remove any extra -1 (EOF) characters in case file
		-- had been opened in Windows 'text mode'.
		for i = len to 1 by -1 do
			if ret[i] != -1 then
				if i != len then
					ret = ret[1 .. i]
				end if
				exit
			end if
		end for
	end ifdef

	if as_text = BINARY_MODE then
		return ret
	end if
	
	-- Treat as a text file.
	while 1 label "ChkEnc" do
		switch encoding do
			case ANSI then
				break
				
			case UTF_8 then
				if length(ret) >= 3 then
					if equal(ret[1..3], x"ef bb bf") then
						-- strip out any BOM that might be present.
						ret = ret[4..$]
					end if
				end if
				ret = toUTF(ret, utf_8, utf_32)
				
			case UTF_16 then
				if length(ret) >= 2 then
					if equal(ret[1 .. 2], x"fe ff") then
						encoding = UTF_16BE
						
					elsif equal(ret[1 .. 2], x"ff fe") then
						encoding = UTF_16LE
						
					else
						if validate(ret, utf_16) = 0 then -- is valid
							encoding = UTF_16BE
						else
							encoding = UTF_16LE -- assume little-endian and retest.
						end if
					end if
				else
					break
				end if
				retry "ChkEnc"
			
			case UTF_16BE then
				if length(ret) >= 2 then
					if equal(ret[1 .. 2], x"fe ff") then
						ret = ret[3..$]
					end if
				end if
				for i = 1 to length(ret) - 1 by 2 do
					temp = ret[i]
					ret[i] = ret[i+1]
					ret[i+1] = temp
				end for
				
				fallthru
				
			case UTF_16LE then
				if length(ret) >= 2 then
					if equal(ret[1 .. 2], x"ff fe") then
						ret = ret[3..$]
					end if
				end if
				
				adr = allocate(length(ret),1)
				poke(adr, ret)
				ret = peek2u({adr, length(ret) / 2})

				ret = toUTF(ret, utf_16, utf_32)
				
			case UTF_32 then
				if length(ret) >= 4 then
					if equal(ret[1 .. 4], x"00 00 fe ff") then
						encoding = UTF_32BE
						
					elsif equal(ret[1 .. 4], x"ff fe 00 00") then
						encoding = UTF_32LE
						
					else
						if validate(ret, utf_32) = 0 then -- is valid
							encoding = UTF_32BE
						else
							encoding = UTF_32LE -- assume little-endian and retest.
						end if
					end if
				else
					break
				end if
				retry "ChkEnc"
			
			case UTF_32BE then
				if length(ret) >= 4 then
					if equal(ret[1 .. 4], x"00 00 fe ff") then
						ret = ret[5..$]
					end if
				end if
				for i = 1 to length(ret) - 3 by 4 do
					temp = ret[i]
					ret[i] = ret[i+3]
					ret[i+3] = temp
					temp = ret[i+1]
					ret[i+1] = ret[i+2]
					ret[i+2] = temp
				end for
				
				fallthru
				
			case UTF_32LE then
				if length(ret) >= 4 then
					if equal(ret[1 .. 2], x"ff fe 00 00") then
						ret = ret[5..$]
					end if
				end if
				
				adr = allocate(length(ret),1)
				poke(adr, ret)
				ret = peek4u({adr, length(ret) / 4})

			case UTF then
				if length(ret) >= 4 then
					if equal(ret[1 .. 4], x"ff fe 00 00") then
						encoding = UTF_32LE
						retry "ChkEnc"
					end if
					if equal(ret[1 .. 4], x"00 00 fe ff") then
						encoding = UTF_32BE
						retry "ChkEnc"
					end if
				end if
				if length(ret) >= 2 then
					if equal(ret[1 .. 2], x"ff fe") then
						encoding = UTF_16LE
						retry "ChkEnc"
					end if
					if equal(ret[1 .. 2], x"fe ff") then
						encoding = UTF_16BE
						retry "ChkEnc"
					end if
				end if
				if length(ret) >= 3 then
					if equal(ret[1 .. 3], x"ef bb bf") then
						encoding = UTF_8
						retry "ChkEnc"
					end if
				end if
				
				if validate(ret, utf_8) = 0 then
					encoding = UTF_8
					retry "ChkEnc"
				end if
								
				if find(0, ret) = 0 then
					-- No nulls, so assume ANSI
					exit "ChkEnc"
				end if
				
				adr = allocate(length(ret), 1)
				poke(adr, ret)
				
				temp = peek2u({adr, length(ret) / 2})
				if validate(temp, utf_16) = 0 then
					encoding = UTF_16LE
					retry "ChkEnc"
				end if
				temp = peek4u({adr, length(ret) / 4})
				if validate(temp, utf_32) = 0 then
					encoding = UTF_32LE
					retry "ChkEnc"
				end if
				
				temp = ret
				for i = 1 to length(temp) - 1 by 2 do
					integer tmp = temp[i]
					temp[i] = temp[i+1]
					temp[i+1] = tmp
				end for
				poke(adr, temp)
				temp = peek2u({adr, length(ret) / 2})
				if validate(temp, utf_16) = 0 then
					encoding = UTF_16LE
					retry "ChkEnc"
				end if
				
				temp = ret
				for i = 1 to length(temp) - 3 by 4 do
					integer tmp = temp[i]
					temp[i] = temp[i+3]
					temp[i+3] = tmp
					tmp = temp[i+1]
					temp[i+1] = temp[i+2]
					temp[i+2] = tmp
				end for
				poke(adr, temp)
				temp = peek4u({adr, length(ret) / 4})
				if validate(temp, utf_32) = 0 then
					encoding = UTF_32LE
					retry "ChkEnc"
				end if
				
				-- assume ANSI at this point.				
		end switch	
		
		exit
	end while
		
	fn = find(26, ret) -- Any Ctrl-Z found?
	if fn then
		-- Ok, so truncate the file data
		ret = ret[1 .. fn - 1]
	end if

	-- Convert Windows endings
	ret = replace_all(ret, {13,10}, {10})
	if length(ret) > 0 then
		if ret[$] != 10 then
			ret &= 10
		end if
	else
		ret = {10}
	end if

	return ret
end function

--**
-- Write a sequence of bytes to a file.
--
-- Parameters:
--		# ##file## : an object, either a file path or the handle to an open file.
--		# ##data## : the sequence of bytes to write
--      # ##as_text## : integer
--         ** **BINARY_MODE** (the default) assumes //binary mode// that
--                     causes every byte to be written out as is,
--         ** **TEXT_MODE** assumes //text mode// that causes a NewLine
--                     to be written out according to the operating system's
--                     end of line convention. In Unix this is Ctrl-J and in
--                     Windows this is the pair {Ctrl-L, Ctrl-J}.
--         ** **UNIX_TEXT** ensures that lines are written out with unix style
--                     line endings (Ctrl-J).
--         ** **DOS_TEXT** ensures that lines are written out with Windows style
--                     line endings {Ctrl-L, Ctrl-J}.
--		# ##encoding##: an integer. One of ANSI, UTF_8, UTF_16LE, UTF_16BE,
--                      UTF_32LE, UTF_32BE. The default is ANSI.
--		# ##with_bom##: an integer. Either 0 or 1. If 1 then when encoding as a UTF
--                      file, this will prepend a Byte Order Marker (BOM) to the
--                      file output.
--
-- Returns:
--     An **integer**, 1 on success, -1 on failure.
--
-- Comments:
-- * UTF_16LE, and UTF_32LE create little-endian files, which are the normal ones
--  for Intel based CPUs. Big-endian files are more commonly found on Motorola CPUs.
--
-- Errors:
--		If [[:puts]] cannot write ##data##, a runtime error will occur.
--
-- Comments:
-- * When ##file## is a file handle, the file is not closed after writing is finished. When ##file## is a
-- file name, it is opened, written to and then closed.
-- * Note that when writing the file in ony of the text modes, the file is truncated
-- at the first Ctrl-Z character in the input data.
--
-- Example 1:
-- <eucode>
-- if write_file("data.txt", "This is important data\nGoodbye") = -1 then
--     puts(STDERR, "Failed to write data\n")
-- end if
-- </eucode>
--
-- See Also:
--    [[:read_file]], [[:write_lines]]

public function write_file(object file, sequence data, integer as_text = BINARY_MODE, integer encoding = ANSI, integer with_bom = 1)
	integer fn
	atom adr

	if as_text != BINARY_MODE then
		-- Truncate at first Ctrl-Z
		fn = find(26, data)
		if fn then
			data = data[1 .. fn-1]
		end if
		-- Ensure last line has a line-end marker.
		if length(data) > 0 then
			if data[$] != 10 then
				data &= 10
			end if
		else
			data = {10}
		end if

		if as_text = TEXT_MODE then
			-- Standardize all line endings
			data = replace_all(data, {13,10}, {10})

		elsif as_text = UNIX_TEXT then
			data = replace_all(data, {13,10}, {10})

		elsif as_text = DOS_TEXT then
			data = replace_all(data, {13,10}, {10})
			data = replace_all(data, {10}, {13,10})

		end if
	end if

	switch encoding do
		case ANSI then
			break
			
		case UTF_8 then
			data = toUTF(data, utf_32, utf_8)
			if with_bom = 1 then
				data = x"ef bb bf" & data
			end if
			as_text = BINARY_MODE
			
		case UTF_16LE then
			data = toUTF(data, utf_32, utf_16)
			adr = allocate( length(data) * 2, 1)
			poke2(adr, data)
			data = peek({adr, length(data) * 2})
			if with_bom = 1 then
				data = x"ff fe" & data
			end if
			as_text = BINARY_MODE
			
		case UTF_16BE then
			data = toUTF(data, utf_32, utf_16)
			adr = allocate( length(data) * 2, 1)
			poke2(adr, data)
			data = peek({adr, length(data) * 2})
			for i = 1 to length(data) - 1 by 2 do
				integer tmp = data[i]
				data[i] = data[i+1]
				data[i+1] = tmp
			end for
			if with_bom = 1 then
				data = x"fe ff" & data
			end if
			as_text = BINARY_MODE
			
		case UTF_32LE then
			adr = allocate( length(data) * 4, 1)
			poke4(adr, data)
			data = peek({adr, length(data) * 4})
			if with_bom = 1 then
				data = x"ff fe 00 00" & data
			end if
			as_text = BINARY_MODE
			
		case UTF_32BE then
			adr = allocate( length(data) * 4, 1)
			poke4(adr, data)
			data = peek({adr, length(data) * 4})
			for i = 1 to length(data) - 3 by 4 do
				integer tmp = data[i]
				data[i] = data[i+3]
				data[i+3] = tmp
				tmp = data[i+1]
				data[i+1] = data[i+2]
				data[i+2] = tmp
			end for
			if with_bom = 1 then
				data = x"00 00 fe ff" & data
			end if
			as_text = BINARY_MODE
			
		case else
			-- Assume ANSI
	end switch
			
			
	if sequence(file) then
		if as_text = TEXT_MODE then
			fn = open(file, "w")
		else
			fn = open(file, "wb")
		end if
	else
		fn = file
	end if
	if fn < 0 then return -1 end if

	puts(fn, data)

	if sequence(file) then
		close(fn)
	end if

	return 1
end function
