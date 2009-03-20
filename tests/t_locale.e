
ifdef not DOS32 then
include std/localeconv.e as lcc
include std/locale.e as l
include std/datetime.e as d
end ifdef

include std/unittest.e

ifdef not DOS32 then
sequence locale

locale = "en_US"

-- The OS may use an optional encoding specifier:
integer ix = set( "" )
sequence native_locale = l:get()
ix = find( '.', native_locale )
sequence encoding
if ix then
	encoding = native_locale[ix..$]
else
	encoding = ""
end if

test_true("set()", l:set("C"))
test_equal("set/get", lcc:decanonical("C"), lcc:decanonical(l:get()))
if l:set(locale & encoding) then
	test_equal("set/get en_US", lcc:decanonical(locale & encoding), lcc:decanonical(l:get()))
	test_equal("money", "$1,020.50", l:money(1020.50))
	test_equal("number", "1,020.50", l:number(1020.5))
else
	-- can not test, maybe emit a warning?
	puts(1, "warning can not test en_US locale, testing against C locale..")
	test_equal("money", "1020.50", l:money(1020.50))
	test_equal("number", "1020.50", l:number(1020.5))
end if

d:datetime dt1
dt1 = d:new(2008, 5, 4, 9, 55, 23)

test_equal("datetime", "Sunday, May 04, 2008",
    l:datetime("%A, %B %d, %Y", dt1))

------------------------------------------------------------------------------------------
--
-- Test Language Translation
--
------------------------------------------------------------------------------------------

l:set_lang_path("") -- current director
test_equal("set_lang_path/get_lang_path", "", l:get_lang_path())

test_true("lang_load() #1", l:lang_load("test"))
test_equal("w() #1", "Hello", l:w("hello"))
test_equal("w() #2", "World", l:w("world"))
test_equal("w() #3", "%s, %s!", l:w("greeting"))
test_equal("w() sprintf() #1", "Hello, World!",
    sprintf(l:w("greeting"), {l:w("hello"), l:w("world")}))
test_equal("w() long message #1", "Hello %s,\nI hope you enjoy this email!",
    l:w("long_message"))

test_true("lang_load() #2", l:lang_load("test2"))
test_equal("w() #4", "Hola", l:w("hello"))
test_equal("w() #5", "Mundo", l:w("world"))
test_equal("w() #6", "%s, %s!", l:w("greeting"))
test_equal("w() sprintf() #2", "Hola, Mundo!",
    sprintf(l:w("greeting"), {l:w("hello"), l:w("world")}))
end ifdef

test_report()
