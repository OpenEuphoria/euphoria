--****
-- ==  Locale Routines
--
-- <<LEVELTOC level=2 depth=4>>

namespace locale

include std/datetime.e as dt
include std/dll.e
include std/filesys.e
include std/io.e
include std/lcid.e as lcid
include std/localeconv.e as lcc
include std/machine.e
include std/map.e
include std/mathcons.e
include std/search.e
include std/text.e
include std/eds.e
include std/types.e

------------------------------------------------------------------------------------------
--
-- Local Constants
--
------------------------------------------------------------------------------------------

constant P = dll:C_POINTER, I = dll:C_INT, L = dll:C_LONG

------------------------------------------------------------------------------------------
--
-- Local Variables
--
------------------------------------------------------------------------------------------

object def_lang = 0

object lang_path = 0

--****
-- === Message Translation Functions
--

--**
-- sets the language path.
--
-- Parameters:
-- 		# ##pp## : an object, either an actual path or an atom.
--
-- Comments:
--	When the language path is not set, and it is unset by default, [[:set]] does not load any language file.
--
-- See Also:
--		[[:set]]

public procedure set_lang_path(object pp)
	lang_path = pp
end procedure

--**
-- gets the language path.
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
-- loads a language file.
--
-- Parameters:
-- 		# ##filename## : a sequence, the name of the file to load. If no file
--                      extension is supplied, then ##".lng"## is used.
--
-- Returns:
--	A language **map**, if successful. This is to be used when calling [[:translate]].
--
-- If the load fails it returns a zero.
--
-- Comments:
-- The language file must be made of lines which are either comments, empty lines
-- or translations. Note that leading whitespace is ignored on all lines except 
-- continuation lines.
--
-- * //Comments// are lines that begin with a ##~### character and extend to the end of the line.
-- * //Empty Lines// are ignored.
-- * //Translations// have two forms.
-- 
-- {{{
-- keyword translation_text
-- }}}
-- In which the 'keyword' is a word that must not have any spaces in it.
-- {{{
-- keyphrase = translation_text
-- }}}
-- In which the 'keyphrase' is anything up to the first ##'='## symbol.
--
-- It is possible to have the translation text span multiple lines. You do this by 
-- having ##'&'## as the last character of the line. These are placed by newline characters
-- when loading.
--
-- Example 1:
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
	filename = filesys:defaultext(filename, "lng")

	if sequence(lang_path) and length(lang_path) > 0 then
		sequence tempname 
		tempname = filesys:locate_file(filename, {lang_path})
		if equal(tempname, filename) then
			filename = filesys:locate_file(filename)
		else
			filename = tempname
		end if
	else
		filename = filesys:locate_file(filename)
	end if

	lines = io:read_lines(filename)
	if atom(lines) then
		return 0  -- Language maps unchanged.
	end if

	for i = 1 to length(lines) do
		
		if cont then

			line = text:trim_tail(lines[i])
			if line[$] = '&' then
				msg &= line[1..$-1] & '\n'
			else
				msg &= line
				map:put(keylang, key, msg)
				map:put(altlang, msg, key)
				cont = 0
			end if
		else
			line = text:trim(lines[i])
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
			
			key = text:trim(line[1..delim-1])
			if line[$] = '&' then
				cont = 1
				msg = text:trim(line[delim+1..$-1])
				if length(msg) > 0 then
					msg &= '\n'
				end if
			else
				msg = text:trim(line[delim+1..$])
				map:put(keylang, key, msg)
				map:put(altlang, msg, key)
			end if
		end if
	end for

	return {keylang, altlang}
end function

--**
-- sets the default language (translation) map.
--
-- Parameters:
-- # ##langmap## : A value returned by [[:lang_load]], or zero to remove any default map.
-- 
-- Example 1:
-- <eucode>
--   set_def_lang( lang_load("appmsgs") )
-- </eucode>

public procedure set_def_lang( object langmap )
	if atom(langmap) and langmap = 0 then
		def_lang = langmap
	elsif length(langmap) = 2 then
		def_lang = langmap
	end if
end procedure

--**
-- gets the default language (translation) map.
--
-- Parameters: 
-- none.
--
-- Returns:
-- An **object**, a language map, or zero if there is no default language map yet.
-- 
-- Example 1:
-- <eucode>
--   object langmap = get_def_lang()
-- </eucode>

public function get_def_lang( )
	return def_lang
end function

--**
-- translates a word, using the current language file.
--
-- Parameters:
-- 		# ##word## : a sequence, the word to translate.
--      # ##langmap## : Either a value returned by [[:lang_load]] or zero to use the default language map
-- 		# ##defval## : a object. The value to return if the word cannot be translated.
--                              Default is "". If ##defval## is ##PINF## then the ##word## is returned
--                              if it can not be translated.
--      # ##mode## : an integer. If zero (the default) it uses ##word## as the keyword and returns
--                              the translation text. If not zero it uses ##word##
--                              as the translation and returns the keyword.
--                              
-- Returns:
--		A **sequence**, the value associated with ##word##, or ##defval## if there
--      is no association.
--
-- Example 1:
-- <eucode>
-- sequence newword
-- newword = translate(msgtext)
-- if length(msgtext) = 0 then
--    error_message(msgtext)
-- else
--    error_message(newword)
-- end if
-- </eucode>
--
-- Example 2:
-- <eucode>
-- error_message(translate(msgtext, , PINF))
-- </eucode>
--
-- See Also:
-- 		[[:set]], [[:lang_load]]

public function translate(sequence word, object langmap = 0, object defval="", integer mode = 0)
	if equal(defval, mathcons:PINF) then
		defval = word
	end if
	
	if equal(langmap, 0) then
		if equal(def_lang, 0) then
			-- No default language map loaded yet.
			return defval
		else
			langmap = def_lang
		end if
	end if

	if atom(langmap) or length(langmap) != 2 then
		-- Not a valid language map passed.
		return defval
	end if
	
	if mode = 0 then
		return map:get(langmap[1], word, defval)
	else
		return map:get(langmap[2], word, defval)
	end if
end function

--**
-- returns a formatted string with automatic translation performed on the parameters.
--
-- Parameters:
-- # ##fmt## : A sequence. Contains the formatting string. See [[:printf]] for details.
-- # ##data## : A sequence. Contains the data that goes into the formatted result. see [[:printf]] for details.
-- # ##langmap## : An object. Either 0 (the default) to use the default language maps, or
--                the result returned from [[:lang_load]] to specify a particular
--                language map.
--
-- Returns:
-- A **sequence**, the formatted result.
--
-- Comments:
-- This works very much like the [[:sprintf]] function. The difference is that the ##fmt## sequence
-- and sequences contained in the ##data## parameter are [[:translate | translated ]] before 
-- passing them to [[:sprintf]]. If an item has no translation, it remains unchanged.
--
-- Further more, after the translation pass, if the result text begins with {{{"__"}}},
--  the {{{"__"}}} is removed. 
-- This function can be used when you do not want an item to be translated.
--
-- Example 1:
-- <eucode>
-- -- Assuming a language has been loaded and
-- --   "greeting" translates as '%s %s, %s'
-- --   "hello"  translates as "G'day"
-- --   "how are you today" translates as "How's the family?"
-- sequence UserName = "Bob"
-- sequence result = trsprintf( "greeting", {"hello", "__" & UserName, "how are you today"})
--    --> "G'day Bob, How's the family?"
-- </eucode>
-- 

public function trsprintf(sequence fmt, sequence data, object langmap = 0)
	for i = 1 to length(data) do
		if sequence(data[i]) then
			data[i] = translate(data[i], langmap, mathcons:PINF)
			if search:begins("__", data[i]) then
				data[i] = data[i][3 .. $]
			end if
		end if
	end for

	fmt = translate(fmt, langmap, mathcons:PINF)

	if search:begins("__", fmt) then
		fmt = fmt[3 .. $]
	end if

	return sprintf(fmt, data)	
end function


------------------------------------------------------------------------------------------
--
-- Library Open/Checking
--
------------------------------------------------------------------------------------------

ifdef WINDOWS then
	constant
		lib = open_dll("MSVCRT.DLL"),
		lib2 = open_dll("KERNEL32.DLL"),
		f_strfmon = define_c_func(lib2, "GetCurrencyFormatA", {I, I, P, P, P, I}, I),
		f_strfnum = define_c_func(lib2, "GetNumberFormatA", {I, I, P, P, P, I}, I),
		f_setlocale = define_c_func(lib, "+setlocale", {I, P}, P),
		f_strftime = define_c_func(lib, "+strftime", {P, I, P, P}, I),
		LC_ALL         = 0,
	--	LC_COLLATE     = 1,
	--	LC_CTYPE       = 2,
		LC_MONETARY    = 3,
		LC_NUMERIC     = 4,
	--	LC_TIME        = 5,
	--	LC_MESSAGES    = 6,
		$

	/* constant
		FORMAT_SIZE    = 6 * 4,
		NUM_DIGITS     = 0,
		LEADING_ZERO   = 4,
		GROUPING       = 8,
		DECIMAL_SEP    = 12,
		THOUSANDS_SEP  = 16,
		NEGATIVE_ORDER = 20
	*/
		sequence current_locale = ""

elsifdef LINUX then
	constant
		lib = dll:open_dll(""),
		f_setlocale = dll:define_c_func(lib, "setlocale", {I, P}, P),
		f_strftime = dll:define_c_func(lib, "strftime", {P, L, P, P}, L),
		f_strfnum = -1,
		LC_ALL      = 6,
	--	LC_CTYPE    = 0,
		LC_NUMERIC  = 1,
	--	LC_TIME     = 2,
	--	LC_COLLATE  = 3,
		LC_MONETARY = 4,
	--	LC_MESSAGES = 5,
		$
	ifdef ARM then
		include std/convert.e
		-- ugly hack..this is a variadic function, and we pass a double,
		-- which doesn't work with the ARM C calling implementation
		constant
			f_strfmon = dll:define_c_func(lib, "strfmon", {P, L, P, L, C_ULONG, C_ULONG}, L),
			$
	elsedef
		constant
			f_strfmon = dll:define_c_func(lib, "strfmon", {P, L, P, dll:C_DOUBLE}, L),
			$
	end ifdef
	
elsifdef OSX then
	constant
		lib = dll:open_dll("libc.dylib"),
		f_strfmon = dll:define_c_func(lib, "strfmon", {P, I, P, dll:C_DOUBLE}, I),
		f_strfnum = -1,
		f_setlocale = dll:define_c_func(lib, "setlocale", {I, P}, P),
		f_strftime = dll:define_c_func(lib, "strftime", {P, I, P, P}, I),
		LC_ALL      = 0,
	--	LC_COLLATE  = 1,
	-- 	LC_CTYPE    = 2,
		LC_MONETARY = 3,
		LC_NUMERIC  = 4,
	--	LC_TIME     = 5,
	--	LC_MESSAGES = 6,
		$

elsifdef BSD then
	constant
		lib = dll:open_dll("libc.so"),
		f_strfmon = dll:define_c_func(lib, "strfmon", {P, I, P, dll:C_DOUBLE}, I),
		f_strfnum = -1,
		f_setlocale = dll:define_c_func(lib, "setlocale", {I, P}, P),
		f_strftime = dll:define_c_func(lib, "strftime", {P, I, P, P}, I),
		LC_ALL      = 0,
	--	LC_COLLATE  = 1,
	--	LC_CTYPE    = 2,
		LC_MONETARY = 3,
		LC_NUMERIC  = 4,
	--	LC_TIME     = 5,
	--	LC_MESSAGES = 6,
		$

elsedef
	constant
		lib = -1,
		lib2 = -1,
		f_strfmon = -1,
		f_strfnum = -1,
		f_setlocale = -1,
		f_strftime = -1,
		LC_ALL         = -1,
	--	LC_COLLATE     = -1,
	--	LC_CTYPE       = -1,
		LC_MONETARY    = -1,
		LC_NUMERIC     = -1,
	--	LC_TIME        = -1,
	--	LC_MESSAGES    = -1,
		$

end ifdef


--****
-- === Time and Number Translation

--**
-- sets the computer locale, and possibly loads an appropriate translation file.
--
-- Parameters:
--		# ##new_locale## : a sequence representing a new locale.
--
-- Returns:
--		An **integer**, either 0 on failure or 1 on success.
--
-- Comments:
-- Locale strings have the following format: ##xx_YY## or ##xx_YY.xyz## .
-- The ##xx## part refers to a culture, or main language or script. For instance, ##"en"## refers to 
-- English, ##"de"## refers to German, and so on. For some languages, a script may be specified, 
-- like ##"mn_Cyrl_MN"## (Mongolian in cyrillic transcription).
--
-- The ##YY## part refers to a subculture, or variant, of the main language. For instance, ##"fr_FR"## 
-- refers to metropolitan France, while ##"fr_BE"## refers to the variant spoken in Wallonie, the 
-- French speaking region of Belgium.
--
-- The optional ##.xyz## part specifies an encoding, like ##.utf8## or ##.1252## . This is required in some cases.

public function set(sequence new_locale)
	atom lAddr_localename
	atom ign
	sequence nlocale
	
	nlocale = lcc:decanonical(new_locale)
	lAddr_localename = machine:allocate_string(nlocale)
	ign = c_func(f_setlocale, {LC_MONETARY, lAddr_localename})
	ign = c_func(f_setlocale, {LC_NUMERIC, lAddr_localename})
	ign = c_func(f_setlocale, {LC_ALL, lAddr_localename})
	machine:free(lAddr_localename)
	
	if sequence(lang_path) then
		-- Note: Failure to update language map does not fail this function.
		def_lang = lang_load(nlocale)
	end if

	ign = (ign != dll:NULL)
	ifdef WINDOWS then
		if ign then
			current_locale = new_locale
		end if
	end ifdef
	return ign
end function

--**
-- gets the current locale string.
--
-- Returns:
--		A **sequence**, a locale string.
--
-- See Also:
--		[[:set]]

public function get()
	sequence r
	atom p

	p = c_func(f_setlocale, {LC_ALL, dll:NULL})
	if p = dll:NULL then
		return ""
	end if

	r = peek_string(p)
	ifdef WINDOWS then
		if equal(lcc:decanonical(r), lcc:decanonical(current_locale)) then
			return current_locale
		end if
	end ifdef
	r = lcc:canonical(r)

	return r
end function

--**
-- converts an amount of currency into a string representing that amount.
--
-- Parameters:
--   # ##amount## : an atom, the value to write out.
--
-- Returns:
--   A **sequence**, a string that writes out ##amount## of current currency.
--
-- Example 1:
-- <eucode>
-- -- Assuming an en_US locale
-- money(1020.5) -- returns"$1,020.50"
-- </eucode>
--
-- See Also:
--		[[:set]], [[:number]]
--

public function money(object amount)
	sequence result
	atom pResult, pTmp

	if f_strfmon != -1 then
		ifdef UNIX then
			pResult = machine:allocate(4 * 160, 1)
			pTmp = machine:allocate_string("%n", 1)
			ifdef ARM then
				sequence f = atom_to_float64( amount )
				c_func(f_strfmon, {pResult, 4 * 160, pTmp, 0,bytes_to_int( f[1..4] ),  bytes_to_int( f[5..8] ) })
			elsedef
				c_func(f_strfmon, {pResult, 4 * 160, pTmp, amount})
			end ifdef
			
		elsifdef WINDOWS then
			pResult = machine:allocate(4 * 160, 1)
			pTmp = machine:allocate_string(sprintf("%.8f", {amount}), 1)
			c_func(f_strfmon, {lcid:get_lcid(get()), 0, pTmp, NULL, pResult, 4 * 160})
		end ifdef
	
		result = peek_string(pResult)
		
		return result
	else
		return text:format("$[,,.2]", amount)
	end if
end function

--**
-- converts a number into a string representing that number.
--
-- Parameters:
--   # ##num## : an atom, the value to write out.
--
-- Returns:
--   A **sequence**, a string that writes out ##num##.
--
-- Example 1:
-- <eucode>
-- -- Assuming an en_US locale
-- number(1020.5) -- returns "1,020.50"
-- </eucode>
--
-- See Also:
--   [[:set]], [[:money]]

public function number(object num)
	sequence result
	atom pResult, pTmp

	ifdef UNIX then
		if f_strfmon != -1 then
			pResult = machine:allocate(4 * 160)
			if integer(num) then
				pTmp = machine:allocate_string("%!.0n")
			else
				pTmp = machine:allocate_string("%!n")
			end if
			ifdef ARM then
				sequence f = atom_to_float64( num )
				c_func(f_strfmon, {pResult, 4 * 160, pTmp, 0,  bytes_to_int( f[1..4] ), bytes_to_int( f[5..8] ) })
			elsedef
				c_func(f_strfmon, {pResult, 4 * 160, pTmp, num})
			end ifdef
		else
			return text:format("[,,]", num)
		end if
		
	elsifdef WINDOWS then
		atom lpFormat
		if f_strfnum != -1 then
			pResult = machine:allocate(4 * 160)
			if integer(num) then
				pTmp = machine:allocate_string(sprintf("%d", {num}))
				-- lpFormat must not only be machine:allocated but completely populated
				-- with values from the current locale.
				lpFormat = NULL
			else
				lpFormat = NULL
				pTmp = machine:allocate_string(sprintf("%.15f", {num}))
			end if
			c_func(f_strfnum, {lcid:get_lcid(get()), 0, pTmp, lpFormat, pResult, 4 * 160})
		else
			return text:format("[,,]", num)
		end if

	elsedef
		return text:format("[,,]", num)
	end ifdef

	result = peek_string(pResult)
	machine:free(pResult)
	machine:free(pTmp)

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
					result = eu:remove(result, i, is_int - 1)
				end if
				exit
			end if
		end for
	end if
	
	return result
end function

function mk_tm_struct(datetime:datetime dtm)
	atom pDtm

	pDtm = machine:allocate(36)
	poke4(pDtm,    dtm[SECOND])        -- int tm_sec
	poke4(pDtm+4,  dtm[MINUTE])        -- int tm_min
	poke4(pDtm+8,  dtm[HOUR])          -- int tm_hour
	poke4(pDtm+12, dtm[DAY])           -- int tm_mday
	poke4(pDtm+16, dtm[MONTH] - 1)     -- int tm_mon
	poke4(pDtm+20, dtm[YEAR] - 1900)   -- int tm_year
	poke4(pDtm+24, datetime:weeks_day(dtm) - 1)    -- int tm_wday
	poke4(pDtm+28, datetime:years_day(dtm))        -- int tm_yday
	poke4(pDtm+32, 0)                  -- int tm_isdst

	return pDtm
end function

--**
-- formats a date according to current locale.
--
-- Parameters:
--   # ##fmt## : A format string, as described in datetime:[[:format]]
--   # ##dtm## : the datetime to write out.
--
-- Returns:
--   A **sequence**, representing the formatted date.
--
-- Example 1:
-- <eucode>
-- include std/datetime.e
--
-- datetime("Today is a %A", datetime:now())
-- </eucode>
--
-- See Also:
--   [[:datetime:format]]
--

public function datetime(sequence fmt, datetime:datetime dtm)
	atom pFmt, pRes, pDtm
	sequence res

	if f_strftime != -1 then
		pDtm = mk_tm_struct(dtm)
		pFmt = machine:allocate_string(fmt)
		pRes = machine:allocate(1024)
		c_func(f_strftime, {pRes, 256, pFmt, pDtm})
		res = peek_string(pRes)
		machine:free(pRes)
		machine:free(pFmt)
		machine:free(pDtm)
	else
		res = date()
		res[1] += 1900
		res = datetime:format(res[1..6], fmt)
	end if
	
	return res
end function

--**
-- gets the text associated with the message number in the requested locale.
--
-- Parameters:
--   # ##MsgNum## : An integer. The message number whose text you are trying to get.
--   # ##LocalQuals## : A sequence. Zero or more locale codes. Default is ##{}##.
--   # ##DBBase##: A sequence. The base name for the database files containing the
--                 locale text strings. The default is ##"teksto"##.
--
-- Returns:
-- A string **sequence**, the text associated with the message number and locale.\\
-- The **integer** zero, if associated text can not be found for any reason.
--
-- Comments:
-- * This first scans the database or databases linked to the locale codes supplied.
-- * The database name for each locale takes the format of ##"<DBBase>_<Locale>.edb"##
-- so if the default ##DBBase## is used, and the locales supplied are ##{"enus", "enau"}##
-- the databases scanned are ##"teksto_enus.edb"## and ##"teksto_enau.edb"##.
-- The database table name searched is ##"1"## with the key being the message number,
-- and the text is the record data.
-- * If the message is not found in these databases (or the databases do not exist)
-- a database called ##"<DBBase>.edb"## is searched. Again the table name is ##"1"## but
-- it first looks for keys with the format ##{<locale>,msgnum}## and failing that it
-- looks for keys in the format ##{"", msgnum}##, and if that fails it looks for a
-- key of just the ##msgnum##.
--

public function get_text(integer MsgNum, sequence LocalQuals = {}, sequence DBBase = "teksto")
	integer db_res
	object lMsgText
	sequence dbname

	db_res = -1
	lMsgText = 0
	-- First, scan through the specialized local dbs
	if string(LocalQuals) and length(LocalQuals) > 0 then
		LocalQuals = {LocalQuals}
	end if
	for i = 1 to length(LocalQuals) do
		dbname = DBBase & "_" & LocalQuals[i] & ".edb"
		db_res = eds:db_select( filesys:locate_file( dbname ), eds:DB_LOCK_READ_ONLY)
		if db_res = eds:DB_OK then
			db_res = eds:db_select_table("1")
			if db_res = eds:DB_OK then
				lMsgText = eds:db_fetch_record(MsgNum)
				if sequence(lMsgText) then
					exit
				end if
			end if
		end if
	end for

	-- Next, scan through the generic db
	if atom(lMsgText) then
		dbname = filesys:locate_file( DBBase & ".edb" )
		db_res = eds:db_select(	dbname, DB_LOCK_READ_ONLY)
		if db_res = eds:DB_OK then
			db_res = eds:db_select_table("1")
			if db_res = eds:DB_OK then
				for i = 1 to length(LocalQuals) do
					lMsgText = eds:db_fetch_record({LocalQuals[i],MsgNum})
					if sequence(lMsgText) then
						exit
					end if
				end for
				if atom(lMsgText) then
					lMsgText = eds:db_fetch_record({"",MsgNum})
				end if
				if atom(lMsgText) then
					lMsgText = eds:db_fetch_record(MsgNum)
				end if
			end if
		end if
	end if
	if atom(lMsgText) then
		return 0
	else
		return lMsgText
	end if
end function
