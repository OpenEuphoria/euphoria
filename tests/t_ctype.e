include ctype.e
include unittest.e

set_test_module_name("ctype.e")

test_equal("isalnum() #1", 1, isalnum('a'))
test_equal("isalnum() #2", 1, isalnum('A'))
test_equal("isalnum() #3", 0, isalnum('-'))
test_equal("isalnum() #4", 0, isalnum('('))
test_equal("isalnum() #5", 1, isalnum('0'))
test_equal("isalnum() #6", 1, isalnum('8'))

test_equal("isalpha() #1", 1, isalpha('a'))
test_equal("isalpha() #2", 1, isalpha('Z'))
test_equal("isalpha() #3", 1, isalpha('b'))
test_equal("isalpha() #4", 1, isalpha('g'))
test_equal("isalpha() #5", 0, isalpha('-'))
test_equal("isalpha() #6", 0, isalpha('.'))
test_equal("isalpha() #7", 0, isalpha('0'))
test_equal("isalpha() #8", 0, isalpha('3'))

test_equal("isascii() #1", 1, isascii('~'))
test_equal("isascii() #2", 1, isascii('a'))
test_equal("isascii() #3", 0, isascii(232))

test_equal("iscntrl() #1", 1, iscntrl(7))
test_equal("iscntrl() #2", 0, iscntrl('h'))
test_equal("iscntrl() #3", 1, iscntrl(30))

test_equal("isdigit() #1", 1, isdigit('3'))
test_equal("isdigit() #2", 0, isdigit(0))
test_equal("isdigit() #3", 0, isdigit('a'))

test_equal("isgraph() #1", 1, isgraph('A'))
test_equal("isgraph() #2", 0, isgraph(8))
test_equal("isgraph() #3", 0, isgraph(200))

test_equal("islower() #1", 1, islower('a'))
test_equal("islower() #2", 1, islower('z'))
test_equal("islower() #3", 0, islower('A'))
test_equal("islower() #4", 0, islower(13))

test_equal("isprint() #1", 1, isprint('A'))
test_equal("isprint() #2", 1, isprint(' '))
test_equal("isprint() #3", 0, isprint(2))
test_equal("isprint() #4", 0, isprint(200))

test_equal("ispunct() #1", 1, ispunct('.'))
test_equal("ispunct() #2", 1, ispunct('~'))
test_equal("ispunct() #3", 1, ispunct('!'))
test_equal("ispunct() #4", 1, ispunct('-'))
test_equal("ispunct() #5", 0, ispunct('a'))
test_equal("ispunct() #6", 0, ispunct('Z'))

test_equal("isspace() #1", 1, isspace(' '))
test_equal("isspace() #2", 0, isspace('j'))
test_equal("isspace() #3", 1, isspace('\n'))
test_equal("isspace() #3", 1, isspace('\r'))
test_equal("isspace() #3", 1, isspace('\t'))
test_equal("isspace() #3", 1, isspace(11))

test_equal("isupper() #1", 1, isupper('A'))
test_equal("isupper() #2", 1, isupper('Z'))
test_equal("isupper() #3", 0, isupper('.'))
test_equal("isupper() #4", 0, isupper('a'))

test_equal("isxdigit() #1", 1, isxdigit('0'))
test_equal("isxdigit() #2", 1, isxdigit('9'))
test_equal("isxdigit() #3", 1, isxdigit('A'))
test_equal("isxdigit() #4", 1, isxdigit('a'))
test_equal("isxdigit() #5", 1, isxdigit('F'))
test_equal("isxdigit() #6", 1, isxdigit('f'))
test_equal("isxdigit() #7", 0, isxdigit('h'))
test_equal("isxdigit() #8", 0, isxdigit('z'))
