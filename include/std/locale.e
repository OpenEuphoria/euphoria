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

map:map lang = map:new()

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
-- 		# ##filename##: a sequence, the //base// name of the fie to load.
--
-- Returns:
--		An **integer**: 0 on failure, 1 on success.
--
-- Comments:
-- The language file must be made of lines which either in the form
--
-- {{{
-- key value
-- }}}
--
-- without any space in the key part, or else start with a ~#~ character, in which case they are 
-- treated as comments. Leading whitespace does not count.
--
-- See Also:
--		[[:w]]

public function lang_load(sequence filename)
	object lines
	sequence line, key, msg
	integer sp, cont -- continuation

	cont = 0
	filename &= ".lng"

	lines = read_lines(filename)
	if atom(lines) then
		return 0  -- TODO: default to English?
	end if

	lang = map:new() -- clear any old data

	for i = 1 to length(lines) do
		line = trim(lines[i], " \r\n")
		if cont then
			msg &= trim_tail(line, " &")
			if line[$] != '&' then
				cont = 0
				map:put(lang, key, msg)
			else
				msg &= '\n'
			end if
		elsif length(line) > 0 and line[1] != '#' then
			sp = find(32, line)
			if sp then 
				if line[$] = '&' then
					cont = 1
					key = line[1..sp-1]
					msg = trim_tail(line[sp+1..$], " &") & '\n'
				else
					map:put(lang, line[1..sp-1], line[sp+1..$])
				end if
			else
				crash("Malformed Language file %s on line %d", {filename, i})
			end if
		end if
	end for

	return 1
end function

--**
-- Translates a word, using the current language file.
--
-- Parameters:
-- 		# ##word##: a sequence, the word to translate.
--
-- Returns:
--		A **sequence**, the value associated to the key ##word##.
--
-- Comments:
-- "" is returned if no translation was found.
--
-- See Also:
-- 		[[:set]], [[:lang_load]]

public function w(sequence word)
	return map:get(lang, word, "")
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
	atom pLocale, ign
	ifdef WIN32 then
		sequence nlocale
		nlocale = new_locale
	end ifdef
	
	new_locale = lcc:decanonical(new_locale)
	pLocale = allocate_string(new_locale)
	ign = c_func(f_setlocale, {LC_MONETARY, pLocale})
	ign = c_func(f_setlocale, {LC_NUMERIC, pLocale})
	ign = c_func(f_setlocale, {LC_ALL, pLocale})

	if sequence(lang_path) then
		ign = lang_load(new_locale)
		ifdef WIN32 then
			if ign then
				current_locale = nlocale
			end if
		end ifdef
		return ign
	end if

	ifdef WIN32 then
		if (ign != NULL) then
			current_locale = nlocale
		end if
	end ifdef
	return (ign != NULL)
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
