-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
include graphcst.e
include convert.e
include machine.e

--****
-- == Graphical Image Routines
--
-- <<LEVELTOC depth=2>>
--

constant BMPFILEHDRSIZE = 14
constant OLDHDRSIZE = 12, NEWHDRSIZE = 40
constant EOF = -1

integer fn, error_code

public type graphics_point(sequence p)
	return length(p) = 2 and p[1] >= 0 and p[2] >= 0
end type

function get_word()
-- read 2 bytes
	integer lower, upper
	
	lower = getc(fn)
	upper = getc(fn)
	if upper = EOF then
		error_code = BMP_UNEXPECTED_EOF
	end if
	return upper * 256 + lower
end function

function get_dword()
-- read 4 bytes
	integer lower, upper
	
	lower = get_word()
	upper = get_word()
	return upper * 65536 + lower
end function

function get_c_block(integer num_bytes)
-- read num_bytes bytes
	sequence s
	
	s = repeat(0, num_bytes)
	for i = 1 to num_bytes do
		s[i] = getc(fn)
	end for
	if s[$] = EOF then
		error_code = BMP_UNEXPECTED_EOF
	end if
	return s
end function

function get_rgb(integer set_size)
-- get red, green, blue palette values
	integer red, green, blue
	
	blue = getc(fn)
	green = getc(fn)
	red = getc(fn)
	if set_size = 4 then
		if getc(fn) then
		end if
	end if
	return {red, green, blue}
end function

function get_rgb_block(integer num_dwords, integer set_size)
-- reads palette 
	sequence s

	s = {}
	for i = 1 to num_dwords do
		s = append(s, get_rgb(set_size))
	end for
	if s[$][3] = EOF then
		error_code = BMP_UNEXPECTED_EOF
	end if
	return s
end function

function row_bytes(atom BitCount, atom Width)
-- number of bytes per row of pixel data
	return floor(((BitCount * Width) + 31) / 32) * 4
end function

function unpack(sequence image, integer BitCount, integer Width, integer Height)
-- unpack the 1-d byte sequence into a 2-d sequence of pixels
	sequence pic_2d, row, bits
	integer bytes, next_byte, byte
	
	pic_2d = {}
	bytes = row_bytes(BitCount, Width)
	next_byte = 1
	for i = 1 to Height do
		row = {}
		if BitCount = 1 then
			for j = 1 to bytes do
				byte = image[next_byte]
				next_byte += 1
				bits = repeat(0, 8)
				for k = 8 to 1 by -1 do
					bits[k] = and_bits(byte, 1)
					byte = floor(byte/2)
				end for
				row &= bits
			end for
		elsif BitCount = 2 then
			for j = 1 to bytes do
				byte = image[next_byte]
				next_byte += 1
				bits = repeat(0, 4)
				for k = 4 to 1 by -1 do
					bits[k] = and_bits(byte, 3)
					byte = floor(byte/4)
				end for
				row &= bits
			end for
		elsif BitCount = 4 then
			for j = 1 to bytes do
				byte = image[next_byte]
				row = append(row, floor(byte/16))
				row = append(row, and_bits(byte, 15))
				next_byte += 1
			end for
		elsif BitCount = 8 then
			row = image[next_byte..next_byte+bytes-1]
			next_byte += bytes
		else
			error_code = BMP_UNSUPPORTED_FORMAT
			exit
		end if
		pic_2d = prepend(pic_2d, row[1..Width])
	end for
	return pic_2d
end function

--****
-- === Bitmap handling
--

--**
-- Read a bitmap (.BMP) file into a 2-d sequence of sequences (image)
--
-- Parameters:
--		# ##file_name##: a sequence, the path to a .bmp file to read from. The extension is not assumed if missing.
--
-- Returns:
--   An **object**: on success, a sequence of the form ##{palette,image}##. On failure, an error code is returned.
--
-- Comments:
-- In the returned value, the first element is a list of mixtures, each of which defines 
-- a color, and the second, a list of point rows. Each pixel in a row is represented by its color ubdex.
--
-- The file should be in the bitmap format. The most common variations of the format are supported. 
-- You can pass the palette to [[:all_palette]]() (after dividing it by 4 to scale it). 
-- The image can be passed to [[:display_image]]().
--
-- Bitmaps of 2, 4, 16 or 256 colors are supported. If the file is not in a good format, an error
-- code (atom) is returned instead
--
-- <eucode>
-- public constant
--     BMP_OPEN_FAILED = 1,
--     BMP_UNEXPECTED_EOF = 2,
--     BMP_UNSUPPORTED_FORMAT = 3
-- </eucode>
--  
-- You can create your own bitmap picture files using Windows Paintbrush and many other 
-- graphics programs. You can then incorporate these pictures into your Euphoria programs.
--
-- Example 1:
--
-- <eucode>
-- x = read_bitmap("c:\\windows\\arcade.bmp")
-- </eucode>
--
-- note: double backslash needed to get single backslash in a string
--
-- Example 2: 
--	##demo/dos32/bitmap.ex##
--
-- See Also: 
--		[[:palette]], [[:all_palette]], [[:display_image]], [[:save_bitmap]]

public function read_bitmap(sequence file_name)
	atom Size 
	integer Type, Xhot, Yhot, Planes, BitCount
	atom Width, Height, Compression, OffBits, SizeHeader, 
		 SizeImage, XPelsPerMeter, YPelsPerMeter, ClrUsed,
		 ClrImportant, NumColors
	sequence Palette, Bits, two_d_bits

	error_code = 0
	fn = open(file_name, "rb")
	if fn = -1 then
		return BMP_OPEN_FAILED
	end if
	Type = get_word()
	Size = get_dword()
	Xhot = get_word()
	Yhot = get_word()
	OffBits = get_dword()
	SizeHeader = get_dword()

	if SizeHeader = NEWHDRSIZE then
		Width = get_dword()
		Height = get_dword()
		Planes = get_word()
		BitCount = get_word()
		Compression = get_dword()
		if Compression != 0 then
			close(fn)
			return BMP_UNSUPPORTED_FORMAT
		end if
		SizeImage = get_dword()
		XPelsPerMeter = get_dword()
		YPelsPerMeter = get_dword()
		ClrUsed = get_dword()
		ClrImportant = get_dword()
		NumColors = (OffBits - SizeHeader - BMPFILEHDRSIZE) / 4
		if NumColors < 2 or NumColors > 256 then
			close(fn)
			return BMP_UNSUPPORTED_FORMAT
		end if
		Palette = get_rgb_block(NumColors, 4) 
	
	elsif SizeHeader = OLDHDRSIZE then 
		Width = get_word()
		Height = get_word()
		Planes = get_word()
		BitCount = get_word()
		NumColors = (OffBits - SizeHeader - BMPFILEHDRSIZE) / 3
		SizeImage = row_bytes(BitCount, Width) * Height
		Palette = get_rgb_block(NumColors, 3) 
	else
		close(fn)
		return BMP_UNSUPPORTED_FORMAT
	end if
	if Planes != 1 or Height <= 0 or Width <= 0 then
		close(fn)
		return BMP_UNSUPPORTED_FORMAT
	end if
	Bits = get_c_block(row_bytes(BitCount, Width) * Height)
	close(fn)
	two_d_bits = unpack(Bits, BitCount, Width, Height)
	if error_code then
		return error_code 
	end if
	return {Palette, two_d_bits}
end function

-- type graphics_point(sequence p)
-- 	return length(p) = 2 and p[1] >= 0 and p[2] >= 0
-- end type
-- 
type text_point(sequence p)
	return length(p) = 2 and p[1] >= 1 and p[2] >= 1 
		   and p[1] <= 200 and p[2] <= 500 -- rough sanity check
end type

constant M_GET_SCREEN_CHAR = 58,
		 M_PUT_SCREEN_CHAR = 59

type positive_atom(atom x)
	return x >= 1
end type

ifdef DOS32 then
public include dos/image.e

function DOS_scr_addr(sequence vc, text_point xy)
-- calculate address in DOS screen memory for a given line, column
	atom screen_memory
	integer page_size
	
	if vc[VC_MODE] = 7 then
		screen_memory = MONO_TEXT_MEMORY
	else
		screen_memory = COLOR_TEXT_MEMORY
	end if
	page_size = vc[VC_LINES] * vc[VC_COLUMNS] * BYTES_PER_CHAR
	page_size = 1024 * floor((page_size + 1023) / 1024)
	screen_memory = screen_memory + get_active_page() * page_size
	return screen_memory + ((xy[1]-1) * vc[VC_COLUMNS] + (xy[2]-1)) 
						   * BYTES_PER_CHAR
end function
end ifdef

--**
-- Get the value and attribute of the character at a given screen location.
--
-- Parameters:
-- 		# ##line##: the 1-base line number of the location
-- 		# ##column##: the 1-base column number of the location
-- Returns:
-- 		A **sequence**, the pair ##{character, attributes}## for the specified location.
--
-- Comments:
--
-- This function inspects a single character on the //active page//.
--
-- The attribute is an atom that contains the foreground and background color of the character, and possibly other information describing the appearance of the character on the screen.
--  With get_screen_char() and [[:put_screen_char]]() you can save and restore a character on the screen along with its attributes.
--
-- Example 1:
-- <eucode>
--  -- read character and attributes at top left corner
-- s = get_screen_char(1,1) 
-- -- store character and attributes at line 25, column 10
-- put_screen_char(25, 10, {s})
-- </eucode>
-- 
-- See Also: 
--      [[:put_screen_char]], [[:save_text_image]]

public function get_screen_char(positive_atom line, positive_atom column)
	atom scr_addr
	sequence vc
	
	ifdef DOS32 then
		vc = video_config()
		if line >= 1 and line <= vc[VC_LINES] and
		   column >= 1 and column <= vc[VC_COLUMNS] then
			scr_addr = DOS_scr_addr(vc, {line, column})
			return peek({scr_addr, 2})
		else
			return {0,0}
		end if
	else    
		return machine_func(M_GET_SCREEN_CHAR, {line, column})
	end ifdef
end function

--**
-- Stores/displays a sequence of characters with attributes at a given location.
--
-- Parameters:
-- 		# ##line##: the 1-based line at which to start writing
-- 		# ##column##: the 1-based column at which to start writing
-- 		# ##char_attr##: a sequence of alternated characters and attributes.
--
-- Comments:
-- ##char_attr## must be in the form  ##{character, attributes, character, attributes, ...}##.
--
-- Errors: 
--   The length of ##char_attr## must be a multiple of 2.
--
-- Comments:
--
-- The attributes atom contains the foreground color, background color, and possibly other platform-dependent information controlling how the character is displayed on the screen.
-- If ##char_attr## has 0 length, nothing will be written to the screen. The characters are written to the //active page//.
-- It's faster to write several characters to the screen with a single call to put_screen_char() than it is to write one character at a time. 
--  
-- Example 1:
-- <eucode>
-- -- write AZ to the top left of the screen
-- -- (attributes are platform-dependent)
-- put_screen_char(1, 1, {'A', 152, 'Z', 131})
-- </eucode>
-- 
-- See Also: 
--   [[:get_screen_char]], [[:display_text_image]]

public procedure put_screen_char(positive_atom line, positive_atom column, 
								 sequence char_attr)
	atom scr_addr
	sequence vc
	integer overflow
	
	ifdef DOS32 then
		vc = video_config()
		if line <= vc[VC_LINES] and column <= vc[VC_COLUMNS] then
			scr_addr = DOS_scr_addr(vc, {line, column})
			overflow = length(char_attr) - 2 * (vc[VC_COLUMNS] - column + 1)
			if overflow > 0 then
				poke(scr_addr, char_attr[1..$ - overflow])  
			else
				poke(scr_addr, char_attr)
			end if
		end if
	else    
		machine_proc(M_PUT_SCREEN_CHAR, {line, column, char_attr})
	end ifdef
end procedure

--**
-- Display a text image in any text mode.
--
-- Parameters:
-- 		# ##xy##: a pair of 1-based coordinates representing the point at which to start writing
--		# ##text##: a list of sequences of alternated character and attribute.
--
-- Comments:
-- This routine displays to the active text page, and only works in text modes.
--   
-- On //DOS32//, the attribute should consist of the foreground color plus 16 times the background color.
-- ##text## may result from a previous call to [[:save_text_image]](), although you could construct it yourself. The sequences of the text image do not have to all be the same length.
-- 
-- You might use save_text_image()/display_text_image() in a text-mode graphical user interface, to allow "pop-up" dialog boxes, and drop-down menus to appear and disappear without losing what was previously on the screen. 
-- 
-- Example 1:
-- <eucode>
-- clear_screen()
-- display_text_image({1,1}, {{'A', WHITE, 'B', GREEN},
--                            {'C', RED+16*WHITE},
--                            {'D', BLUE}})
-- -- displays:
-- --     AB
-- --     C
-- --     D
-- -- at the top left corner of the screen.
-- -- 'A' will be white with black (0) background color,
-- -- 'B' will be green on black, 
-- -- 'C' will be red on white, and
-- -- 'D' will be blue on black.
-- </eucode>
-- 
-- See Also:
--   [[:save_text_image]], [[:display_image]], [[:put_screen_char]]
--

public procedure display_text_image(text_point xy, sequence text)
	atom scr_addr
	integer screen_width, extra_col2, extra_lines
	sequence vc, one_row
	
	vc = video_config()
	ifdef DOS32 then
		screen_width = vc[VC_COLUMNS] * BYTES_PER_CHAR
		scr_addr = DOS_scr_addr(vc, xy)
	end ifdef
	if xy[1] < 1 or xy[2] < 1 then
		return -- bad starting point
	end if
	extra_lines = vc[VC_LINES] - xy[1] + 1 
	if length(text) > extra_lines then
		if extra_lines <= 0 then
			return -- nothing to display
		end if
		text = text[1..extra_lines] -- truncate
	end if
	extra_col2 = 2 * (vc[VC_COLUMNS] - xy[2] + 1)
	for row = 1 to length(text) do
		one_row = text[row]
		if length(one_row) > extra_col2 then
			if extra_col2 <= 0 then
				return -- nothing to display
			end if
			one_row = one_row[1..extra_col2] -- truncate
		end if
		ifdef DOS32 then
			poke(scr_addr, one_row)
			scr_addr += screen_width
		else
			machine_proc(M_PUT_SCREEN_CHAR, {xy[1]+row-1, xy[2], one_row})
		end ifdef
	end for
end procedure

--**
-- Copy a rectangular block of text out of screen memory
--
-- Parameters:
-- 		# ##top_left##: the coordinates, given as a pair, of the upper left corner of the area to save.
-- 		# ##bottom_right##: the coordinates, given as a pair, of the lower right corner of the area to save.
--
-- Returns:
-- 		A **sequence** of {character, attribute, character, ...} lists.
-- Comments:
--
-- The returned value is appropriately handled by [[:display_text_image]].
-- On //DOS32//, an attribute byte is made up of two 4-bit fields that encode the foreground and background color of a character. The high-order 4 bits determine the background color, while the low-order 4 bits determine the foreground color.
--
-- This routine reads from the active text page, and only works in text modes.
-- 
-- You might use this function in a text-mode graphical user interface to save a portion of the screen before displaying a drop-down menu, dialog box, alert box etc. 
--
-- Example 1:
-- <eucode>
-- -- If the top 2 lines of the screen have Hello and World
-- s = save_text_image({1,1}, {2,5})
-- -- s is something like: {"H-e-l-l-o-", "W-o-r-l-d-"}
-- </eucode>
--
-- See Also:
--     [[:display_text_image]], [[:save_image]], [[:set_active_page]], [[:get_screen_char]]

public function save_text_image(text_point top_left, text_point bottom_right)
	sequence image, row_chars, vc
	atom scr_addr, screen_memory
	integer screen_width, image_width
	integer page_size

	vc = video_config()
	screen_width = vc[VC_COLUMNS] * BYTES_PER_CHAR
	ifdef DOS32 then
		if vc[VC_MODE] = 7 then
			screen_memory = MONO_TEXT_MEMORY
		else
			screen_memory = COLOR_TEXT_MEMORY
		end if
		page_size = vc[VC_LINES] * screen_width
		page_size = 1024 * floor((page_size + 1023) / 1024)
		screen_memory = screen_memory + get_active_page() * page_size
		scr_addr = screen_memory + 
				(top_left[1]-1) * screen_width + 
				(top_left[2]-1) * BYTES_PER_CHAR
	end ifdef
	image = {}
	image_width = (bottom_right[2] - top_left[2] + 1) * BYTES_PER_CHAR
	for row = top_left[1] to bottom_right[1] do
		ifdef DOS32 then
			row_chars = peek({scr_addr, image_width})
			scr_addr += screen_width
		else
			row_chars = {}
			for col = top_left[2] to bottom_right[2] do
				row_chars &= machine_func(M_GET_SCREEN_CHAR, {row, col})
			end for
		end ifdef
		image = append(image, row_chars)
	end for
	return image
end function

-- save_screen() and related functions were written by 
-- Junko C. Miura of Rapid Deployment Software.  

integer numXPixels, numYPixels, bitCount, numRowBytes
integer startXPixel, startYPixel, endYPixel

type region(object r)
	-- a region on the screen
	if atom(r) then
		return r = 0
	else
		return length(r) = 2 and graphics_point(r[1]) and
								 graphics_point(r[2])
	end if
end type

type two_seq(sequence s)
	-- a two element sequence, both elements are sequences
	return length(s) = 2 and sequence(s[1]) and sequence(s[2])
end type

procedure putBmpFileHeader(integer numColors)
	integer offBytes
	
	-- calculate bitCount, ie, color bits per pixel, (1, 2, 4, 8, or error) 
	if numColors = 256 then
		bitCount = 8            -- 8 bits per pixel
	elsif numColors = 16 then
		bitCount = 4            -- 4 bits per pixel
	elsif numColors = 4 then
		bitCount = 2            -- 2 bits per pixel 
	elsif numColors = 2 then
		bitCount = 1            -- 1 bit per pixel
	else 
		error_code = BMP_INVALID_MODE
		return
	end if

	puts(fn, "BM")  -- file-type field in the file header
	offBytes = 4 * numColors + BMPFILEHDRSIZE + NEWHDRSIZE
	numRowBytes = row_bytes(bitCount, numXPixels)
	-- put total size of the file
	puts(fn, int_to_bytes(offBytes + numRowBytes * numYPixels))
 
	puts(fn, {0, 0, 0, 0})              -- reserved fields, must be 0
	puts(fn, int_to_bytes(offBytes))    -- offBytes is the offset to the start
										--   of the bitmap information
	puts(fn, int_to_bytes(NEWHDRSIZE))  -- size of the secondary header
	puts(fn, int_to_bytes(numXPixels))  -- width of the bitmap in pixels
	puts(fn, int_to_bytes(numYPixels))  -- height of the bitmap in pixels
	
	puts(fn, {1, 0})                    -- planes, must be a word of value 1
	
	puts(fn, {bitCount, 0})     -- bitCount
	
	puts(fn, {0, 0, 0, 0})      -- compression scheme
	puts(fn, {0, 0, 0, 0})      -- size image, not required
	puts(fn, {0, 0, 0, 0})      -- XPelsPerMeter, not required 
	puts(fn, {0, 0, 0, 0})      -- YPelsPerMeter, not required
	puts(fn, int_to_bytes(numColors))   -- num colors used in the image
	puts(fn, int_to_bytes(numColors))   -- num important colors in the image
end procedure

procedure putOneRowImage(sequence x, integer numPixelsPerByte, integer shift)
-- write out one row of image data
	integer  j, byte, numBytesFilled
		
	x &= repeat(0, 7)   -- 7 zeros is safe enough
		
	numBytesFilled = 0
	j = 1
	while j <= numXPixels do
		byte = x[j]
		for k = 1 to numPixelsPerByte - 1 do
			byte = byte * shift + x[j + k]
		end for
	
		puts(fn, byte)
		numBytesFilled += 1
		j += numPixelsPerByte
	end while
	
	for m = 1 to numRowBytes - numBytesFilled do
		puts(fn, 0)
	end for
end procedure

procedure putImage()
-- Write image data packed according to the bitCount information, in the order
-- last row ... first row. Data for each row is padded to a 4-byte boundary.
	sequence x
	integer  numPixelsPerByte, shift
	
	numPixelsPerByte = 8 / bitCount
	shift = power(2, bitCount)
	for i = endYPixel to startYPixel by -1 do
		x = get_pixel({startXPixel, i, numXPixels})
		putOneRowImage(x, numPixelsPerByte, shift)
	end for
end procedure

procedure putColorTable(integer numColors, sequence pal)
-- Write color table information to the .BMP file. 
-- palette data is given as a sequence {{r,g,b},..,{r,g,b}}, where each
-- r, g, or b value is 0 to 255. 

	for i = 1 to numColors do
		puts(fn, pal[i][3])     -- blue first in .BMP file
		puts(fn, pal[i][2])     -- green second
		puts(fn, pal[i][1])     -- red third
		puts(fn, 0)             -- reserved, must be 0
	end for
end procedure

procedure putImage1(sequence image)
-- Write image data packed according to the bitCount information, in the order
-- last row ... first row. Data for each row is padded to a 4-byte boundary.
-- Image data is given as a 2-d sequence in the order first row... last row.
	object   x
	integer  numPixelsPerByte, shift

	numPixelsPerByte = 8 / bitCount
	shift = power(2, bitCount)
	for i = numYPixels to 1 by -1 do
		x = image[i]
		if atom(x) then
			error_code = BMP_INVALID_MODE
			return
		elsif length(x) != numXPixels then
			error_code = BMP_INVALID_MODE
			return
		end if
		putOneRowImage(x, numPixelsPerByte, shift) 
	end for
end procedure

--**
-- Create a .BMP bitmap file, given a palette and a 2-d sequence of sequences of colors.
--
-- Parameters:
-- 		# ##palette_n_image##: a {palette, image} pair, like [[:read_bitmap()]] returns
-- 		# ##file_name##: a sequence, the name of the file to save to.
--
-- Returns:
-- 		An **integer**, 0 on success.
--
-- Comments:
--   This routine does the opposite of [[:read_bitmap]]().
-- The first element of ##palette_n_image## is a sequence of [[:mixture]]s defining each 
-- color in the butmap. The second element is a sequence of sequences of pcolors. The inner 
-- sequences must have the same length.
--
-- The result will be one of the following codes: 
-- <eucode>
-- public constant
--     BMP_SUCCESS = 0,
--     BMP_OPEN_FAILED = 1,
--     BMP_INVALID_MODE = 4 -- invalid graphics mode
--                          -- or invalid argument
-- </eucode>
--
-- If you use ##get_all_palette##() to get the palette before calling this function, you must 
-- multiply the returned intensity values by 4 before calling [[:save_bitmap]](). You might use
-- [[:save_image]]() to get the 2-d image.
--
-- save_bitmap() produces bitmaps of 2, 4, 16, or 256 colors and these can all be read with 
-- read_bitmap(). Windows Paintbrush and some other tools do not support 4-color bitmaps.
--
-- Example 1:
-- <eucode>
-- paletteData = get_all_palette() * 4
-- code = save_bitmap({paletteData, imageData},
--                    "c:\\example\\a1.bmp")
-- </eucode>
--
-- See Also:
--   [[:read_bitmap]], [[:save_image]], [[:save_screen]], [[:get_all_palette]]

public function save_bitmap(two_seq palette_n_image, sequence file_name)
	sequence color, image
	integer numColors

	error_code = BMP_SUCCESS
	fn = open(file_name, "wb")
	if fn = -1 then
		return BMP_OPEN_FAILED
	end if

	color = palette_n_image[1]
	image = palette_n_image[2]
	numYPixels = length(image)
	numXPixels = length(image[1])   -- assume the same length with each row
	numColors = length(color)

	putBmpFileHeader(numColors)

	if error_code = BMP_SUCCESS then
		putColorTable(numColors, color)
		putImage1(image)
	end if
	close(fn)
	return error_code
end function

ifdef DOS32 then
--**
-- Capture the whole screen or a region of the screen, and create a Windows
-- bitmap (.BMP) file. 
--
-- Platform:
--		//DOS32//
--
-- Parameters:
-- 		# ##r##: an object, either 0 (whole screen) or a {top left, bottom right} pair
--        of {x,y} pairs of coordinates.
--		# ##file_name##: a sequence, the name of the save file.
--
-- Returns:
--		An **integer**, which is BMP_SUCCESS on success.
--
-- Comments:
-- The result will be one of the following codes:
-- <eucode>
-- public constant
--     BMP_SUCCESS = 0,
--     BMP_OPEN_FAILED = 1,
--     BMP_INVALID_MODE = 4 -- invalid graphics mode
--                          -- or invalid argument
-- </eucode>
--  
-- [[:save_screen]]() produces bitmaps of 2, 4, 16, or 256 colors and these can all be read with
-- [[:read_bitmap]](). Windows Paintbrush and some other tools do not support 4-color bitmaps.
--
-- save_screen() only works in pixel-graphics modes, not text modes.
--  
-- Example 1: 
-- <eucode> 
-- -- save whole screen:
-- code = save_screen(0, "c:\\example\\a1.bmp")
-- </eucode>
-- 
-- Example 2:  
-- <eucode>  
-- -- save part of screen:
-- err = save_screen({{0,0},{200, 15}}, "b1.bmp")
-- </eucode>
-- 
-- See Also:
--   [[:save_bitmap]], [[:save_image]], [[:read_bitmap]]

public function save_screen(region r, sequence file_name)
	sequence vc
	integer numColors

	error_code = BMP_SUCCESS
	fn = open(file_name, "wb")
	if fn = -1 then
		return BMP_OPEN_FAILED
	end if

	vc = video_config()
	if sequence(r) then
		numXPixels = r[2][1] - r[1][1] + 1
		numYPixels = r[2][2] - r[1][2] + 1
		if r[2][1] >= vc[VC_XPIXELS] or r[2][2] >= vc[VC_YPIXELS] then
			close(fn)
			return BMP_INVALID_MODE   -- not a valid argument 
		end if
		startXPixel = r[1][1]
		startYPixel = r[1][2]
		endYPixel   = r[2][2]
	else
		numXPixels = vc[VC_XPIXELS]
		numYPixels = vc[VC_YPIXELS]
		startXPixel = 0
		startYPixel = 0
		endYPixel   = numYPixels - 1
	end if
	
	if numXPixels <= 0 or numYPixels <= 0 then
		-- not a valid graphics mode or not a valid argument
		close(fn)
		return BMP_INVALID_MODE
	end if
	
	numColors = vc[VC_NCOLORS]
	putBmpFileHeader(numColors)
	
	if error_code = BMP_SUCCESS then
		putColorTable(numColors, get_all_palette()*4)
	end if
	if error_code = BMP_SUCCESS then
		putImage()
	end if
	close(fn)
	return error_code
end function    
end ifdef

