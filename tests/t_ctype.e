include ctype.e
include unittest.e

setTestModuleName("ctype.e")

testEqual("isalnum() #1", 1, isalnum('a'))
testEqual("isalnum() #2", 1, isalnum('A'))
testEqual("isalnum() #3", 0, isalnum('-'))
testEqual("isalnum() #4", 0, isalnum('('))
testEqual("isalnum() #5", 1, isalnum('0'))
testEqual("isalnum() #6", 1, isalnum('8'))

testEqual("isalpha() #1", 1, isalpha('a'))
testEqual("isalpha() #2", 1, isalpha('Z'))
testEqual("isalpha() #3", 1, isalpha('b'))
testEqual("isalpha() #4", 1, isalpha('g'))
testEqual("isalpha() #5", 0, isalpha('-'))
testEqual("isalpha() #6", 0, isalpha('.'))
testEqual("isalpha() #7", 0, isalpha('0'))
testEqual("isalpha() #8", 0, isalpha('3'))

testEqual("isascii() #1", 1, isascii('~'))
testEqual("isascii() #2", 1, isascii('a'))
testEqual("isascii() #3", 0, isascii(232))

testEqual("iscntrl() #1", 1, iscntrl(7))
testEqual("iscntrl() #2", 0, iscntrl('h'))
testEqual("iscntrl() #3", 1, iscntrl(30))

testEqual("isdigit() #1", 1, isdigit('3'))
testEqual("isdigit() #2", 0, isdigit(0))
testEqual("isdigit() #3", 0, isdigit('a'))

testEqual("isgraph() #1", 1, isgraph('A'))
testEqual("isgraph() #2", 0, isgraph(8))
testEqual("isgraph() #3", 0, isgraph(200))

testEqual("islower() #1", 1, islower('a'))
testEqual("islower() #2", 1, islower('z'))
testEqual("islower() #3", 0, islower('A'))
testEqual("islower() #4", 0, islower(13))

testEqual("isprint() #1", 1, isprint('A'))
testEqual("isprint() #2", 1, isprint(' '))
testEqual("isprint() #3", 0, isprint(2))
testEqual("isprint() #4", 0, isprint(200))

testEqual("ispunct() #1", 1, ispunct('.'))
testEqual("ispunct() #2", 1, ispunct('~'))
testEqual("ispunct() #3", 1, ispunct('!'))
testEqual("ispunct() #4", 1, ispunct('-'))
testEqual("ispunct() #5", 0, ispunct('a'))
testEqual("ispunct() #6", 0, ispunct('Z'))

testEqual("isspace() #1", 1, isspace(' '))
testEqual("isspace() #2", 0, isspace('j'))
testEqual("isspace() #3", 1, isspace('\n'))
testEqual("isspace() #3", 1, isspace('\r'))
testEqual("isspace() #3", 1, isspace('\t'))
testEqual("isspace() #3", 1, isspace(11))

testEqual("isupper() #1", 1, isupper('A'))
testEqual("isupper() #2", 1, isupper('Z'))
testEqual("isupper() #3", 0, isupper('.'))
testEqual("isupper() #4", 0, isupper('a'))

testEqual("isxdigit() #1", 1, isxdigit('0'))
testEqual("isxdigit() #2", 1, isxdigit('9'))
testEqual("isxdigit() #3", 1, isxdigit('A'))
testEqual("isxdigit() #4", 1, isxdigit('a'))
testEqual("isxdigit() #5", 1, isxdigit('F'))
testEqual("isxdigit() #6", 1, isxdigit('f'))
testEqual("isxdigit() #7", 0, isxdigit('h'))
testEqual("isxdigit() #8", 0, isxdigit('z'))
