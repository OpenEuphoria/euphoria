include locale.e as l
include datetime.e as d
include unittest.e

set_test_module_name("locale.e")
sequence locale

if platform() = LINUX or platform() = FREEBSD then
    locale = "en_US"
elsif platform() = WIN32 then
    locale = "English_United States.1252"
end if

l:set(locale)
test_equal("set/get", locale, l:get())
test_equal("money", "$1,020.50", l:money(1020.50))
test_equal("number", "1,020.50", l:number(1020.5))

d:datetime dt1
dt1 = d:new(2008, 5, 4, 9, 55, 23)

test_equal("datetime", "Sunday, May 04, 2008",
    l:datetime("%A, %B %d, %Y", dt1))
