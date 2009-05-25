-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- ==  Locale Routines
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>
-- 

include std/dll.e
include std/machine.e
include std/error.e
include std/datetime.e as dt
include std/text.e
include std/io.e
include std/map.e
include std/localeconv.e as lcc
include std/lcid.e as lcid
include std/convert.e
include std/filesys.e

------------------------------------------------------------------------------------------
--
-- Local Constants
--
------------------------------------------------------------------------------------------

constant P = C_POINTER, I = C_INT

------------------------------------------------------------------------------------------
--
-- Local Variables
--
------------------------------------------------------------------------------------------

object def_lang = 0

object lang_path = 0

--****
-- === Message translation functions
--

--**
-- Set the language path.
--
-- Parameters:
-- 		# ##pp##: an object, either an actual path or an atom.
--
-- Comments:
--	When the language path is not set, and it is unset by default, [[:set]]() does not load any language file.
--
-- See Also:
--		[[:set]]

public procedure set_lang_path(object pp)
	lang_path = pp
end procedure

--**
-- Get the language path.
--
-- Returns:
-- 		An **object**, the current language path.
--
-- See Also:
--		[[:get_lang_path]]

public function get_lang_path()
	return lang_path
end function

--**
-- Load a language file.
--
-- Parameters:
-- 		# ##filename##: a sequence, the name of the file to load. If no file
--                      extention is supplied, then ".lng" is used.
--
-- Returns:
--	A language map, if successful. This is to be used when calling [[:translate]]().
--
-- If the load fails it returns a zero.
--
-- Comments:
-- The language file must be made of lines which are either comments, empty lines
-- or translations. Note that leading whitespace is ignored on all lines except 
-- continuation lines.
--
-- * **Comments** are lines that begin with a ~# character and extend to the end of the line.
-- * **Empty Lines** are ignored.
-- * **Translations** have two forms ...
-- 
-- {{{
-- keyword translation_text
-- }}}
-- In which the 'keyword' is a word that must not have any spaces in it.
-- {{{
-- keyphrase = translation_text
-- }}}
-- In which the 'keyphrase' is anything up to the first '=' symbol.
--
-- It is possible to have the translation text span multiple lines. You do this by 
-- having '&' as the last character of the line. These are placed by newline characters
-- when loading.
--
-- Example:
--{{{
--# Example translation file
--#
-- 
-- 
--hello Hola
--world Mundo
--greeting %s, %s!
-- 
--help text = &
--This is an example of some &
--translation text that spans &
--multiple lines.
--
-- # End of example PO #2
--}}}
--
-- See Also:
--		[[:translate]]

public function lang_load(sequence filename)
	object lines
	sequence line, key, msg
	integer delim
	integer cont -- continuation
	map:map keylang
	map:map altlang
	
	keylang = map:new()
	altlang = map:new()
	cont = 0
	filename = defaultext(filename, "lng")

	if sequence(lang_path) and length(lang_path) > 0 then
		sequence tempname 
		tempname = locate_file(filename, {lang_path})
		if equal(tempname, filename) then
			filename = locate_file(filename)
		else
			filename = tempname
		end if
	else
		filename = locate_file(filename)
	end if

	lines = read_lines(filename)
	if atom(lines) then
		return 0  -- Language maps unchanged.
	end if

	for i = 1 to length(lines) do
		
		if cont then

			line = trim_tail(lines[i])
			if line[$] = '&' then
				msg &= line[1..$-1] & '\n'
			else
				msg &= line
				map:put(keylang, key, msg)
				map:put(altlang, msg, key)
				cont = 0
			end if
		else
			line = trim(lines[i])
			if length(line) = 0 then
				continue
			end if
			if line[1] = '#' then
				continue
			end if
			
			delim = find('=', line)
			if delim = 0 then
				delim = find(' ', line)
			end if
			
			if delim = 0 then
				-- Ignore lines with missing translation text
				continue
			end if
			
			key = trim(line[1..delim-1])
			if line[$] = '&' then
				cont = 1
				msg = trim(line[delim+1..$-1])
				if length(msg) > 0 then
					msg &= '\n'
				end if
			else
				msg = trim(line[delim+1..$])
				map:put(keylang, key, msg)
				map:put(altlang, msg, key)
			end if
		end if
	end for

	return {keylang, altlang}
end function

--**
-- Sets the default language (translation) map
--
-- Parameters:
-- # ##langmap## - A value returned by [[:lang_load]](), or zero to remove any default map.
-- 
-- Example:
--<eucode>
--   set_def_lang( lang_load("appmsgs") )
--</eucode>

public procedure set_def_lang( object langmap )
	if atom(langmap) and langmap = 0 then
		def_lang = langmap
	elsif length(langmap) = 2 then
		def_lang = langmap
	end if
end procedure

--**
-- Gets the default language (translation) map
--
-- Parameters: none.
--
-- Returns:
-- An object; a language map, or zero if there is no default language map yet.
-- 
-- Example:
--<eucode>
--   object langmap = get_def_lang()
--</eucode>

public function get_def_lang( )
	return def_lang
end function

--**
-- Translates a word, using the current language file.
--
-- Parameters:
-- 		# ##word##: a sequence, the word to translate.
--      # ##langmap##: Either a value returned by [[:lang_load]]() or zero to use the default language map
-- 		# ##defval##: a object. The value to return if the word cannot be translated.
--                              Default is "".
--      # ##mode##: an integer. If zero (the default) it uses ##word## as the keyword and returns
--                              the translation text. If not zero it uses ##word##
--                              as the translation and returns the keyword.
--                              
-- Returns:
--		A **sequence**, the value associated with ##word##, or ##defval## if there
--      is no association.
--
-- See Also:
-- 		[[:set]], [[:lang_load]]

public function translate(sequence word, object langmap = 0, object defval="", integer mode = 0)
	if equal(langmap, 0) then
		if equal(def_lang, 0) then
			return defval
		else
			langmap = def_lang
		end if
	end if
	if atom(langmap) or length(langmap) != 2 then
		return defval
	end if
	
	if mode = 0 then
		return map:get(langmap[1], word, defval)
	else
		return map:get(langmap[2], word, defval)
	end if

end function

------------------------------------------------------------------------------------------
--
-- Library Open/Checking
--
------------------------------------------------------------------------------------------

atom lib, lib2
integer LC_ALL, LC_COLLATE, LC_CTYPE, LC_MONETARY, LC_NUMERIC,
	LC_TIME, LC_MESSAGES, f_strfmon, f_strfnum

ifdef WIN32 then
	lib = open_dll("MSVCRT.DLL")
	lib2 = open_dll("KERNEL32.DLL")
	f_strfmon = define_c_func(lib2, "GetCurrencyFormatA", {I, I, P, P, P, I}, I)
	f_strfnum = define_c_func(lib2, "GetNumberFormatA", {I, I, P, P, P, I}, I)
	LC_ALL      = 0
	LC_COLLATE  = 1
	LC_CTYPE    = 2
	LC_MONETARY = 3
	LC_NUMERIC  = 4
	LC_TIME     = 5
	LC_MESSAGES = 6
	
-- 	constant FORMAT_SIZE = 6 * 4
-- 	constant NUM_DIGITS = 0
-- 	constant LEADING_ZERO = 4
-- 	constant GROUPING = 8
-- 	constant DECIMAL_SEP = 12
-- 	constant THOUSANDS_SEP = 16
-- 	constant NEGATIVE_ORDER = 20

elsifdef LINUX then

	lib = open_dll("")
	f_strfmon = define_c_func(lib, "strfmon", {P, I, P, C_DOUBLE}, I)
	f_strfnum = -1
	LC_ALL      = 6
	LC_CTYPE    = 0
	LC_NUMERIC  = 1
	LC_TIME     = 2
	LC_COLLATE  = 3
	LC_MONETARY = 4
	LC_MESSAGES = 5

elsifdef FREEBSD or SUNOS then

	lib = open_dll("libc.so")
	f_strfmon = define_c_func(lib, "strfmon", {P, I, P, C_DOUBLE}, I)
	f_strfnum = -1

	LC_ALL      = 0
	LC_COLLATE  = 1
	LC_CTYPE    = 2
	LC_MONETARY = 3
	LC_NUMERIC  = 4
	LC_TIME     = 5
	LC_MESSAGES = 6

elsifdef OSX then

	lib = open_dll("libc.dylib")
	f_strfmon = define_c_func(lib, "strfmon", {P, I, P, C_DOUBLE}, I)
	f_strfnum = -1

	LC_ALL      = 0
	LC_COLLATE  = 1
	LC_CTYPE    = 2
	LC_MONETARY = 3
	LC_NUMERIC  = 4
	LC_TIME     = 5
	LC_MESSAGES = 6
  
elsedef

	crash("locale.e requires Windows, Linux, FreeBSD or OS X", {})

end ifdef

--****
-- === Time/Number Translation

constant
	f_setlocale = define_c_func(lib, "setlocale", {I, P}, P),
	f_strftime = define_c_func(lib, "strftime", {P, I, P, P}, I)

ifdef WIN32 then
	sequence current_locale = ""
end ifdef

--**
-- Set the computer locale, and possibly load appropriate translation file.
--
-- Parameters:
--		# ##new_locale##: a sequence representing a new locale.
--
-- Returns:
--		An **integer**, either 0 on failure or 1 on success.
--
-- Comments:
-- Locale strings have the following format: xx_YY or xx_YY.xyz .
-- The xx part refers to a culture, or main language/script. For instance, "en" refers to 
-- English, "de" refers to German, and so on. For some language, a script may be specified, 
-- like in "mn_Cyrl_MN" (mongolian in cyrillic transcription).
--
-- The YY part refers to a subculture, or variant, of the main language. For instance, "fr_FR" 
-- refers to metropolitan France, while "fr_BE" refers to the variant spoken in Wallonie, the 
-- French speaking region of Belgium.
--
-- The optional .xyz part specifies an encoding, like .utf8 or .1252 . This is required in some cases.

public function set(sequence new_locale)
	atom lAddr_localename
	atom ign
	sequence nlocale
	
	nlocale = lcc:decanonical(new_locale)
	lAddr_localename = allocate_string(nlocale)
	ign = c_func(f_setlocale, {LC_MONETARY, lAddr_localename})
	ign = c_func(f_setlocale, {LC_NUMERIC, lAddr_localename})
	ign = c_func(f_setlocale, {LC_ALL, lAddr_localename})
	free(lAddr_localename)
	
	if sequence(lang_path) then
		-- Note: Failure to update language map does not fail this function.
		def_lang = lang_load(nlocale)
	end if

	ign = (ign != NULL)
	ifdef WIN32 then
		if ign then
			current_locale = new_locale
		end if
	end ifdef
	return ign
end function

--**
-- Get current locale string
--
-- Returns:
--		A **sequence**, a locale string.
--
-- See Also:
--		[[:set]]

public function get()
	sequence r
	atom p

	p = c_func(f_setlocale, {LC_ALL, NULL})
	if p = NULL then
		return ""
	end if

	r = peek_string(p)
	ifdef WIN32 then
		if equal(lcc:decanonical(r), lcc:decanonical(current_locale)) then
			return current_locale
		end if
	end ifdef
	r = lcc:canonical(r)

	return r
end function

--**
-- Converts an amount of currency into a string representing that amount.
--
-- Parameters:
--		# ##amount##: an atom, the value to write out.
--
-- Returns:
-- 		A **sequence**, a string that writes out ##amount## of current currency.
--
-- Example 1:
-- <eucode>
-- -- Assuming an en_US locale
-- ? money(1020.5) -- returns"$1,020.50"
-- </eucode>
--
-- See Also:
--		[[:set]], [[:number]]

public function money(object amount)
	sequence result
	integer size
	atom pResult, pTmp

	ifdef UNIX then
		pResult = allocate(4 * 160)
		pTmp = allocate_string("%n")
		size = c_func(f_strfmon, {pResult, 4 * 160, pTmp, amount})
	elsifdef WIN32 then
		pResult = allocate(4 * 160)
		pTmp = allocate_string(sprintf("%.8f", {amount}))
		size = c_func(f_strfmon, {lcid:get_lcid(get()), 0, pTmp, NULL, pResult, 4 * 160})
	-- else doesn't work under DOS
	end ifdef

	result = peek_string(pResult)
	free(pResult)
	free(pTmp)

	return result
end function

--**
-- Converts a number into a string representing that number.
--
-- Parameters:
--   # ##num##: an atom, the value to write out.
--
-- Returns:
--   A **sequence**, a string that writes out ##num##.
--
-- Example 1:
-- <eucode>
-- -- Assuming an en_US locale
-- ?number(1020.5) -- returns"1,020.50"
-- </eucode>
--
-- See Also:
--   [[:set]], [[:money]]

public function number(object num)
	sequence result
	integer size
	atom pResult, pTmp

	ifdef UNIX then
		pResult = allocate(4 * 160)
		if integer(num) then
			pTmp = allocate_string("%!.0n")
		else
			pTmp = allocate_string("%!n")
		end if
		size = c_func(f_strfmon, {pResult, 4 * 160, pTmp, num})
	elsifdef WIN32 then
		atom lpFormat
		pResult = allocate(4 * 160)
		if integer(num) then
			pTmp = allocate_string(sprintf("%d", {num}))
			-- lpFormat must not only be allocated but completely populated
			-- with values from the current locale.
			lpFormat = NULL
		else
			lpFormat = NULL
			pTmp = allocate_string(sprintf("%.15f", {num}))
		end if
		size = c_func(f_strfnum, {lcid:get_lcid(get()), 0, pTmp, lpFormat, pResult, 4 * 160})
	-- else doesn't work under DOS
	end ifdef

	result = peek_string(pResult)
	free(pResult)
	free(pTmp)

	-- Assumption: All locales remove trailing zeros and decimal point from integers
	integer is_int = integer(num)
	if is_int = 0 then
		sequence float = sprintf("%.15f", num)
		is_int = find('.', float)
		if is_int then
			for i = length(float) to is_int+1 by -1 do
				if float[i] != '0' then
					is_int = 0
					exit
				end if
			end for
		end if
	end if
	if is_int != 0 then -- The input was an integer
		-- remove all trailing zeros and decimal point, but not any trailing symbols --
		-- Step 1. Locate rightmost digit.
		is_int = 0
		for i = length(result) to 1 by -1 do
			if find(result[i], "1234567890") then
				is_int = i + 1
				exit
			end if
		end for
		-- Step 2. From rightmost digit, stop when we get to a non-zero
		for i = is_int - 1 to 1 by -1 do
			if result[i] != '0' then
				if not find(result[i], "1234567890") then
					-- Step 3. Remove decimal point and all zeros, preserving any trailing symbols.
					result = result[1..i-1] & result[is_int .. $]
				end if
				exit
			end if
		end for
	end if
	
	return result
end function

function mk_tm_struct(dt:datetime dtm)
	atom pDtm

	pDtm = allocate(36)
	poke4(pDtm,    dtm[SECOND])        -- int tm_sec
	poke4(pDtm+4,  dtm[MINUTE])        -- int tm_min
	poke4(pDtm+8,  dtm[HOUR])          -- int tm_hour
	poke4(pDtm+12, dtm[DAY])           -- int tm_mday
	poke4(pDtm+16, dtm[MONTH] - 1)     -- int tm_mon
	poke4(pDtm+20, dtm[YEAR] - 1900)   -- int tm_year
	poke4(pDtm+24, dt:dow(dtm) - 1)    -- int tm_wday
	poke4(pDtm+28, dt:doy(dtm))        -- int tm_yday
	poke4(pDtm+32, 0)                  -- int tm_isdst

	return pDtm
end function

--**
-- Formats a date according to current locale.
--
-- Parameters:
--   # ##fmt##: A format string, as described in [[:format]]
--   # ##dtm##: the datetime to write out.
--
-- Returns:
--   A **sequence**, representing the formatted date.
--
-- Example 1:
-- <eucode>
-- ? datetime("Today is a %A",dt:now())
-- </eucode>
--
-- See Also:
--   [[:format]]

public function datetime(sequence fmt, dt:datetime dtm)
	atom pFmt, pRes, pDtm
	integer size
	sequence res

	pDtm = mk_tm_struct(dtm)
	pFmt = allocate_string(fmt)
	pRes = allocate(1024)
	size = c_func(f_strftime, {pRes, 256, pFmt, pDtm})
	res = peek_string(pRes)
	free(pRes)
	free(pFmt)
	free(pDtm)

	return res
end function
