include std/search.e
include std/unittest.e

	

test_equal("find_all() empty", {}, find_all('Z', "ABACDE", 1))
test_equal("find_all() atom", {1,3}, find_all('A', "ABACDE", 1))
test_equal("find_all() atom from", {3}, find_all('A', "ABACDE", 2))
test_equal("find_all() sequence", {3,4}, find_all("Doe", {"John", "Middle", "Doe", "Doe"}, 1))

test_equal("match_all() empty", {}, match_all("ZZ", "ABDCABDEF", 1))
test_equal("match_all() string", {1,5}, match_all("AB", "ABDCABDEF", 1))
test_equal("match_all() string from", {5}, match_all("AB", "ABDCABDEF", 2))
test_equal("match_all() sequence", {1,5}, match_all({1,2}, {1,2,3,4,1,2,4,3}, 1))

test_equal("find_any() from string", 7, find_any("aeiou", "John Doe", 3))
test_equal("find_any() from integers", 6, find_any({1,3,5,8}, {2,4,5,6,7,8,9}, 4))
test_equal("find_any() from floats", 6,
        find_any({1.3,3.5,5.6,8.3}, {2.1,4.2,5.3,6.4,7.5,8.3,9.1}, 4))

test_equal("find_any() empty", 0, find_any("xyz", "John Doe"))
test_equal("find_any() string #1", 2, find_any("aeiou", "John Doe"))
test_equal("find_any() string #2", 3, find_any("Dh", "John Doe"))
test_equal("find_any() integers", 3, find_any({1,3,5,7,9}, {2,4,5,6,7,8,9}))
test_equal("find_any() floats", 3, find_any({1.1,3.2,5.3,7.4,9.5}, {2.1,4.2,5.3,6.4,7.5,8.6,9.7}))

test_equal("rfind() #1", 5, rfind('E', "EEEDEFG"))
test_equal("rfind() #2", 0, rfind('E', "ABC"))
test_equal("rfind() #3", 3, rfind('E', "EEEDEFG", 4))
test_equal("rfind() #4", 0, rfind('E', "ABC", 2))
test_equal("rfind() #5", 0, rfind('E', "ABC", -5))
test_equal("rfind() #6", 0, rfind('E', "ABC", 20))
test_equal("rfind() #7", 3, rfind("rob", {"fred", "rob", "rob", "george", "mary"}))
test_equal("rfind() #8", 2, rfind("rob", {"fred", "rob", "rob", "george", "mary"}, -3))

test_equal("rmatch() #1", 5, rmatch("ABC", "ABCDABC"))
test_equal("rmatch() #2", 0, rmatch("ABC", "DEFBCA"))
test_equal("rmatch() #3", 8, rmatch("ABC", "ABCDABCABC", 9))
test_equal("rmatch() #4", 0, rmatch("ABC", "EEEDDDABC", 5))
test_equal("rmatch() #8",28, rmatch("the", "the dog ate the steak from the table."))
test_equal("rmatch() #9",13, rmatch("the", "the dog ate the steak from the table.", -11))

test_equal("match_replace() string", "John Smith", match_replace("Doe", "John Doe","Smith",  0))
test_equal("match_replace() sequence", {1,1,1,1,1}, match_replace({5,2},{1,5,2,5,2},  {1,1}, 0))
test_equal("match_replace() max set", "BBBAAA", match_replace("A", "AAAAAA","B",  3))

test_equal("find_replace() letter", "John Dot", find_replace('e', "John Doe",'t',  0))
test_equal("find_replace() number", {1,1,2,1,2}, find_replace(5,{1,5,2,5,2}, 1, 0))
test_equal("find_replace() max set", "BBBAAA", find_replace('A',"AAAAAA",'B',  3))
test_equal("find_replace() 'b' to 'c'", "The catty cook was all cut in Canada",
	find_replace('b', "The batty book was all but in Canada", 'c'))


constant haystack = "012345678ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
test_equal("binary_search missing #1", -10, binary_search('9',haystack))
test_equal("binary_search missing #2", -1, binary_search(0,haystack))
test_equal("binary_search missing #3", -62, binary_search("rubbish",haystack))
test_equal("binary_search found first", 1, binary_search('0',haystack))
test_equal("binary_search found last", 61, binary_search('z',haystack))
test_equal("binary_search found middle#1", 30, binary_search('U',haystack))
test_equal("binary_search found middle#2", 31, binary_search('V',haystack))

test_equal("binary_search found subset #1", 10, binary_search('A',haystack, 5, 17))
test_equal("binary_search found subset #2", -17, binary_search('A',haystack, 17))
test_equal("binary_search found subset #3", -8, binary_search('A',haystack, 1, 7))
test_equal("binary_search found subset #4", -17, binary_search('A',haystack, 17, 1))

test_equal("binary_search empty input", -1, binary_search('A',{}))

test_equal("binary_search strings", 5, binary_search("cat",{"apple", "bat", "car", "cast", "cat", "category", "dog"}))

test_equal("find_nested, standard", {2, 3, 2}, find_nested(3,{1,{2,{},{1,3}},{1,{2,3}}}))
test_equal("find_nested, standard, at top", {1}, find_nested(1,{1,{2,{},{1,3}},{1,{2,3}}}))
test_equal("find_nested, backwards", {3, 2, 2}, find_nested(3,{1,{2,{},{1,3}},{1,{2,3}}},NESTED_BACKWARD))
test_equal("find_nested, all hits", {{2, 3, 2}, {3, 2, 2}}, find_nested(3,{1,{2,{},{1,3}},{1,{2,3}}},NESTED_ALL))
test_equal("find_nested, all hits, any in list",
	{{{2,1}, 2}, {{2,3,2}, 1}, {{3,2,1}, 2}, {{3,2,2}, 1}}
, find_nested({3,2},{1,{2,{},{1,3}},{1,{2,3}}},NESTED_ALL+NESTED_ANY+NESTED_INDEX))

test_equal("ends #1", 1, ends("txt", "hello.txt"))
test_equal("ends #2", 0, ends("txt", "hello.doc"))
test_equal("ends #3", 1, ends("exe", "hello.exe"))
test_equal("ends #4", 0, ends("ex", "hello.exe"))

test_equal("lookup #1", 'o', lookup('a', "cat", "dog"))
test_equal("lookup #1", 'x', lookup('d', "cat", "dogx"))
test_equal("lookup #1", 0, lookup('d', "cat", "dog"))
test_equal("lookup #1", -1, lookup('d', "cat", "dog", -1))
test_equal("lookup #1", "spider", lookup("ant", {"ant","bear","cat"}, {"spider","seal","dog","unknown"}))
test_equal("lookup #1", "unknown", lookup("dog", {"ant","bear","cat"}, {"spider","seal","dog","unknown"}))

sequence grid = {
       {"ant", "spider", "mortein"},
       {"bear", "seal", "gun"},
       {"cat", "dog", "ranger"},
       $
}

test_equal("vlookup #1", "spider", vlookup("ant", grid, 1, 2, "?"))
test_equal("vlookup #2", "mortein", vlookup("ant", grid, 1, 3, "?"))
test_equal("vlookup #3", "gun", vlookup("seal", grid, 2, 3, "?"))
test_equal("vlookup #4", "?", vlookup("mouse", grid, 2, 3, "?"))


test_equal("is_in_range #1", 0, is_in_range(1, {}))
test_equal("is_in_range #2", 0, is_in_range(1, {1}))
test_equal("is_in_range #3", 0, is_in_range(1, {2,9}))
test_equal("is_in_range #4", 0, is_in_range(10, {2,9}))
test_equal("is_in_range #5", 1, is_in_range(2, {2,9}))
test_equal("is_in_range #6", 1, is_in_range(9, {2,9}))
test_equal("is_in_range #7", 1, is_in_range(5, {2,9}))
test_equal("is_in_range l[]", 1, is_in_range(2, {2,9}, "[]"))
test_equal("is_in_range u[]", 1, is_in_range(9, {2,9}, "[]"))
test_equal("is_in_range l[)", 1, is_in_range(2, {2,9}, "[)"))
test_equal("is_in_range u[)", 0, is_in_range(9, {2,9}, "[)"))
test_equal("is_in_range l(]", 0, is_in_range(2, {2,9}, "(]"))
test_equal("is_in_range u(]", 1, is_in_range(9, {2,9}, "(]"))
test_equal("is_in_range l()", 0, is_in_range(2, {2,9}, "()"))
test_equal("is_in_range u()", 0, is_in_range(9, {2,9}, "()"))

test_equal("is_in_list #1", 0, is_in_list(1, {}))
test_equal("is_in_list #2", 1, is_in_list(1, {1}))
test_equal("is_in_list #3", 0, is_in_list(1, {100, 2, 45, 9, 17, -6}))
test_equal("is_in_list #4", 1, is_in_list(100, {100, 2, 45, 9, 17, -6}))
test_equal("is_in_list #5", 1, is_in_list(-6, {100, 2, 45, 9, 17, -6}))
test_equal("is_in_list #6", 1, is_in_list(9, {100, 2, 45, 9, 17, -6}))


test_report()

