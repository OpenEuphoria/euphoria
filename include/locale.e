-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.2
-- Locale routines

include misc.e
include dll.e
include machine.e
include datetime.e as dt
include sequence.e
include file.e
include map.e as m
include localeconv.e as lcc

------------------------------------------------------------------------------------------
--
-- Local Constants
--
------------------------------------------------------------------------------------------

constant P = C_POINTER, I = C_INT, D = C_DOUBLE

------------------------------------------------------------------------------------------
--
-- Local Variables
--
------------------------------------------------------------------------------------------

m:map lang
lang = m:new()

object lang_path
lang_path = 0

------------------------------------------------------------------------------------------
--
-- Message translation functions
--
------------------------------------------------------------------------------------------

-- TODO: document
global procedure set_lang_path(object pp)
	lang_path = pp
end procedure

-- TODO: document
global function get_lang_path()
	return lang_path
end function

-- TODO: document
global function lang_load(sequence filename)
	object lines
	sequence line, key, msg
	integer sp, cont -- continuation

	cont = 0
	filename &= ".lng"

	lines = read_lines(filename)
	if atom(lines) then
		return 0  -- TODO: default to English?
	end if

	lang = m:new() -- clear any old data

	for i = 1 to length(lines) do
		line = trim(lines[i], " \r\n")
		if cont then
			msg &= trim_tail(line, " &")
			if line[$] != '&' then
				cont = 0
				lang = m:put(lang, key, msg)
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
					lang = m:put(lang, line[1..sp-1], line[sp+1..$])
				end if
			else
				crash("Malformed Language file %s on line %d", {filename, i})
			end if
		end if
	end for

	return 1
end function

-- TODO: document
global function w(sequence word)
	return m:get(lang, word, "")
end function

------------------------------------------------------------------------------------------
--
-- Library Open/Checking
--
------------------------------------------------------------------------------------------

atom lib, lib2
integer LC_ALL, LC_COLLATE, LC_CTYPE, LC_MONETARY, LC_NUMERIC,
	LC_TIME, LC_MESSAGES, f_strfmon, f_strfnum

if platform() = WIN32 then
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

elsif platform() = FREEBSD then

	lib = open_dll("libc.so")
	f_strfmon = define_c_func(lib, "strfmon", {P, I, P, D}, I)
	f_strfnum = -1

	LC_ALL      = 0
	LC_COLLATE  = 1
	LC_CTYPE    = 2
	LC_MONETARY = 3
	LC_NUMERIC  = 4
	LC_TIME     = 5
	LC_MESSAGES = 6

  
elsif platform() = LINUX then

	lib = open_dll("")
	f_strfmon = define_c_func(lib, "strfmon", {P, I, P, D}, I)
	f_strfnum = -1
	LC_ALL      = 6
	LC_CTYPE    = 0
	LC_NUMERIC  = 1
	LC_TIME     = 2
	LC_COLLATE  = 3
	LC_MONETARY = 4
	LC_MESSAGES = 5

else

	crash("locale.e requires Windows, Linux or FreeBSD", {})

end if

------------------------------------------------------------------------------------------
--
-- Global Functions/Procedures
--
------------------------------------------------------------------------------------------

constant
	f_setlocale = define_c_func(lib, "setlocale", {I, P}, P),
	f_strftime = define_c_func(lib, "strftime", {P, I, P, P}, I)

-- TODO: document
global function set(sequence new_locale)
	atom pLocale, ign
	
	new_locale = lcc:decanonical(new_locale)
	pLocale = allocate_string(new_locale)
	ign = c_func(f_setlocale, {LC_MONETARY, pLocale})
	ign = c_func(f_setlocale, {LC_NUMERIC, pLocale})
	ign = c_func(f_setlocale, {LC_ALL, pLocale})

	if sequence(lang_path) then
		return lang_load(new_locale)
	end if

	return (ign != NULL)
end function

-- TODO: document
global function get()
	sequence r
	atom p

	p = c_func(f_setlocale, {LC_ALL, NULL})
	if p = NULL then
		return ""
	end if

	r = peek_string(p)
	r = lcc:canonical(r)

	return r
end function

function money_unix(atom amount)
	atom pResult, pFmt
	sequence result
	integer size

	pResult = allocate(4 * 160)
	pFmt = allocate_string("%n")
	size = c_func(f_strfmon, {pResult, 4 * 160, pFmt, amount})
	free(pFmt)

	result = peek_string(pResult)
	free(pResult)

	return result
end function

function money_win32(atom amount)
	atom pAmount, pResult
	sequence result
	integer size

	pAmount = allocate_string(sprintf("%.8f", {amount}))
	pResult = allocate(4 * 160)
	size = c_func(f_strfmon, {LC_ALL, 0, pAmount, NULL, pResult, 4 * 160})
	result = peek_string(pResult)
	free(pAmount)
	free(pResult)

	return result
end function

-- TODO: document
global function money(atom amount)
	if platform() = WIN32 then
		return money_win32(amount)
	else
		return money_unix(amount)
	end if
end function

function number_unix(atom num)
	atom pResult, pFmt
	sequence result
	integer size

	pResult = allocate(4 * 160)
	pFmt = allocate_string("%!n")
	size = c_func(f_strfmon, {pResult, 4 * 160, pFmt, num})
	free(pFmt)

	result = peek_string(pResult)
	free(pResult)

	return result
end function

function number_win32(atom num)
	atom pNum, pResult
	sequence result
	integer size

	pNum = allocate_string(sprintf("%.8f", {num}))
	pResult = allocate(4 * 160)
	size = c_func(f_strfnum, {LC_ALL, 0, pNum, NULL, pResult, 4 * 160})
	result = peek_string(pResult)
	free(pNum)
	free(pResult)

	return result
end function

-- TODO: document
global function number(atom num)
	if platform() = WIN32 then
		return number_win32(num)
	else
		return number_unix(num)
	end if
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

-- TODO: document
global function datetime(sequence fmt, dt:datetime dtm)
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
