include unittest.e
include unicode.e

wstring s1, s2, s3
s1 = "abcd"
s2 = ""
s3 = {#FFFF, #0001, #1000, #8080}

test_equal("peek_wstring and allocate_wstring#1", s1, peek_wstring(allocate_wstring(s1)))
test_equal("peek_wstring and allocate_wstring#2", s2, peek_wstring(allocate_wstring(s2)))
test_equal("peek_wstring and allocate_wstring#3", s3, peek_wstring(allocate_wstring(s3)))


-- type tests
object a1, a2, a3, a4, a5, a6, a7
a1 = "this is ascii string \t \n \r " & #FF & #00
a2 = 123
a3 = {{"not", "string", 999}}
a4 = "this is unicode string " & #100
a5 = "this is unicode string " & #FFFF
a6 = "this is not unicode string " & #10000
a7 = "this is not unicode string " & #FFFFFFFF

test_equal("astring type#1", 1, astring(a1))
test_equal("astring type#2", 0, astring(a2))
test_equal("astring type#3", 0, astring(a3))
test_equal("astring type#4", 0, astring(a4))
test_equal("astring type#5", 0, astring(a5))

test_equal("wstring type#1", 1, wstring(a1))
test_equal("wstring type#2", 0, wstring(a2))
test_equal("wstring type#3", 0, wstring(a3))
test_equal("wstring type#4", 1, wstring(a4))
test_equal("wstring type#5", 1, wstring(a5))
test_equal("wstring type#6", 0, wstring(a6))
test_equal("wstring type#7", 0, wstring(a7))


-- utf8 tests -- taken from rfc 2279

wstring e1, e2, e3
astring f1, f2, f3

e1 = {#0041, #2262, #0391, #002E} -- "A<NOT IDENTICAL TO><ALPHA>."
e2 = {#D55C, #AD6D, #C5B4} -- "hangugo" in Hangul
e3 = {#65E5, #672C, #8A9E} -- "nihongo" in Kanji

f1 = utf8_encode(e1)
f2 = utf8_encode(e2)
f3 = utf8_encode(e3)

test_equal("utf8_encode#1", {#41, #E2, #89, #A2, #CE, #91, #2E}, f1)
test_equal("utf8_encode#2", {#ED, #95, #9C, #EA, #B5, #AD, #EC, #96, #B4}, f2)
test_equal("utf8_encode#3", {#E6, #97, #A5, #E6, #9C, #AC, #E8, #AA, #9E}, f3)

test_equal("utf8_decode#1", e1, utf8_decode({#41, #E2, #89, #A2, #CE, #91, #2E}))
test_equal("utf8_decode#2", e2, utf8_decode({#ED, #95, #9C, #EA, #B5, #AD, #EC, #96, #B4}))
test_equal("utf8_decode#3", e3, utf8_decode({#E6, #97, #A5, #E6, #9C, #AC, #E8, #AA, #9E}))

test_embedded_report()

