include localeconv.e as lcc
include locale.e as l
include datetime.e as d
include unittest.e

set_test_module_name("locale.e")
sequence locale

locale = "en_US"

test_true("set()", l:set(locale))
test_equal("set/get", lcc:decanonical(locale), lcc:decanonical(l:get()))
test_equal("money", "$1,020.50", l:money(1020.50))
test_equal("number", "1,020.50", l:number(1020.5))

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

