include std/text.e
include std/sequence.e as seq
include std/search.e as srch

include std/unittest.e

test_equal("reverse() integer sequence", {3,2,1}, reverse({1,2,3}))
test_equal("reverse() string", "nhoJ", reverse("John"))
test_equal("reverse() sub-string 1", "ayxwvutsrqponmlkjihgfedcbz", reverse("abcdefghijklmnopqrstuvwxyz", 2, -1))
test_equal("reverse() sub-string 2", "azyxwvutsrqponmlkjihgfedcb", reverse("abcdefghijklmnopqrstuvwxyz", 2, 0))
test_equal("reverse() sub-string 3", "yxwvutsrqponmlkjihgfedcbaz", reverse("abcdefghijklmnopqrstuvwxyz", 1, -1))
test_equal("reverse() even count", "fedcba", reverse("abcdef"))
test_equal("reverse() odd count", "edcba", reverse("abcde"))
test_equal("reverse() 2-elements", "ba", reverse("ab"))
test_equal("reverse() 1-elements", "a", reverse("a"))
test_equal("reverse() 0-elements", "", reverse(""))
test_equal("reverse() atom", 42, reverse(42))
test_equal("reverse() with sub-seq", {{-10,-200}, {5,6,7}, {1,2}}, reverse({{1,2}, {5,6,7}, {-10, -200}}))

sequence rep1 = repeat(0, 12)
sequence rep2 = repeat(1, 12)
test_equal("repeat 0", {0,0,0,0,0,0,0,0,0,0,0,0}, rep1)
test_equal("repeat 1", {1,1,1,1,1,1,1,1,1,1,1,1}, rep2)

sequence hs = "John Doe"
hs = head(hs, 3)
test_equal("head() single ref a", "Joh", hs)
sequence dup = hs
hs = head(hs, 2)
test_equal("head() single ref a", "Jo", hs)
test_equal("head() single ref b", "Joh", dup)
test_equal("head() string default", "J", head("John Doe"))
test_equal("head() string", "John", head("John Doe", 4))
test_equal("head() sequence", {1,2,3}, head({1,2,3,4,5,6}, 3))
test_equal("head() nested sequence", {{1,2}, {3,4}}, head({{1,2},{3,4},{5,6}}, 2))
test_equal("head() bounds", "Name", head("Name", 50))

test_equal("mid() string", "Middle", mid("John Middle Doe", 6, 6))
test_equal("mid() sequence", {2,3,4}, mid({1,2,3,4,5,6}, 2, 3))
test_equal("mid() nested sequence", {{3,4},{5,6}}, mid({{1,2},{3,4},{5,6},{7,8}}, 2, 2))
test_equal("mid() bounds #1", {2,3}, mid({1,2,3}, 2, 50))
test_equal("mid() bounds #2",{1,2},mid({1,2,3},0,2))
test_equal("mid() bounds #3",{1,2},mid({1,2,3},1,-1))
test_equal("mid 1c", "", mid("John", 5, 4)  )

test_equal("slice() string", "Middle", slice("John Middle Doe", 6, 11))
test_equal("slice() string, zero end", "Middle Doe", slice("John Middle Doe", 6, 0))
test_equal("slice() string, neg end", "Middle", slice("John Middle Doe", 6, -4))
test_equal("slice() sequence", {2,3}, slice({1,2,3,4}, 2, 3))
test_equal("slice() nested sequence", {{3,4},{5,6}}, slice({{1,2},{3,4},{5,6},{7,8}}, 2, 3))
test_equal("slice() bounds", "Middle Doe", slice("John Middle Doe", 6, 50))
test_equal("slice() def start", "John ", slice("John Middle Doe", , 5))
test_equal("slice() def end", "Middle Doe", slice("John Middle Doe", 6))
test_equal("slice 1c", "it", slice("it", 0, 0))
test_equal("slice 2c", "", slice("it", 2, 1))

test_equal("tail() string default", "ohn Middle Doe", tail("John Middle Doe"))
test_equal("tail() string", "Doe", tail("John Middle Doe", 3))
test_equal("tail() sequence", {3,4}, tail({1,2,3,4}, 2))
test_equal("tail() nested sequence", {{3,4},{5,6}}, tail({{1,2},{3,4},{5,6}}, 2))
test_equal("tail() bounds", {1,2,3,4}, tail({1,2,3,4}, 50))

test_equal("split() simple string no empty", {"John","Middle","Doe"}, split(" John  Middle  Doe  ",,1))
test_equal("split() simple string", {"a","b","c"}, split("a,b,c", ","))
test_equal("split() sequence", {{1},{2},{3},{4}}, split({1,0,2,0,3,0,4}, 0))
test_equal("split() nested sequence", {{"John"}, {"Doe"}}, split({"John", 0, "Doe"},0))
test_equal("split() limit set", {"a", "b,c"}, split("a,b,c",',',, 1))
test_equal("split() single sequence delimiter",{"while 1 "," end while ",""},
	split("while 1 do end while do", "do"))
test_equal("split() an empty string", {}, split("", ","))
test_equal("split() using an empty delimiter", {"1","2","3"}, split("123", ""))
test_equal("split() using an empty delimiter and limit", {"1","23"}, split("123","",, 1))

test_equal("split_any()", {"a", "b", "c"}, split_any("a,b.c", ",."))
test_equal("split_any() limit", {"a", "b", "c|d"}, split_any("a,b.c|d", ",.|", 2))
test_equal("split_any() no empty", {"a", "b", "c"}, split_any(",a,,b...c.", ",.",,1))
test_equal("split_any 1c", {"a","c"}, split_any("abc", 0x62))

test_equal("join() simple string default", "a b c", join({"a", "b", "c"}))
test_equal("join() simple string", "a,b,c", join({"a", "b", "c"}, ","))
test_equal("join() nested sequence", {"John", 0, "Doe"}, join({{"John"}, {"Doe"}}, 0))
test_equal("join() empty", "123", join({"1","2","3"}, ""))

test_equal("remove() integer sequence", {1,3}, remove({1,2,3}, 2))
test_equal("remove() string", "Jon", remove("John", 3))
test_equal("remove() nested sequence", {{1,2}, {5,6}}, remove({{1,2},{3,4},{5,6}}, 2))
test_equal("remove() bounds", "John", remove("John", 55))

test_equal("remove() range integer sequence", {1,5}, remove({1,2,3,4,5}, 2, 4))
test_equal("remove() range string", "John Doe", remove("John M Doe", 5, 6))
test_equal("remove() range bounds #1", "John", remove("John Doe", 5, 100))
test_equal("remove() cnt 0", "John Doe", remove("John Doe", 3, 2))
test_equal("remove() end 0", "John Doe", remove("John Doe", 3, 0))
test_equal("remove() range bounds with floats", "n Doe", remove("John Doe", 1.5, 3))

test_equal("remove start 0", "cdefg",   remove("abcdefg", 0, 2))
test_equal("remove last plus", "abcdef",  remove("abcdefg", 7, 9))
test_equal("remove beyond last", "abcdefg", remove("abcdefg", 8, 9))
test_equal("remove all", "", remove("abcdefg", 1, 7))

test_equal("remove_all() 1", {2,3,4,3,2}, remove_all(1,{1,2,3,1,4,3,1,2,1}))
test_equal("remove_all() 2", "Ask what you can do for your country.", 
           remove_all('x',"xAxsk whxat you caxn do for yoxur countryx.x"))

test_equal("remove_all 1c", "it", remove_all("s", "it"))
test_equal("remove_all 2c", "itit", remove_all('s', "sitsit"))
test_equal("remove_all 3c", "sitsit", remove_all("si", "sitsit"))

test_equal("retain_all", {1,1,3,1,3}, retain_all( {1,3,5}, {1,2,4,1,3,2,4,1,2,3} ))
test_equal("retain_all no match", {}, retain_all( 7, {1,2,4,1,3,2,4,1,2,3} ))
test_equal("retain_all all match",{1,2,4,1,3,2,4,1,2,3} , retain_all( {1,2,3,4}, {1,2,4,1,3,2,4,1,2,3} ))
test_equal("retain_all no objects",{} , retain_all( {}, {1,2,4,1,3,2,4,1,2,3} ))
test_equal("retain_all 1c", {}, retain_all( {1,3,5}, {} ))

test_equal("insert() integer sequence", {1,2,3}, insert({1,3}, 2, 2))
test_equal("insert() string", {'J','o',"h",'n'}, insert("Jon", "h", 3))

procedure test_ticket_767(atom x)
    sequence objs = {}
    integer k = 1
    objs = insert(objs, x, k)
	test_equal( "insert an atom doesn't treat it like a double - ticket 767", {x}, objs )
end procedure
test_ticket_767( 1 )

test_equal("splice() integer sequence", {1,2,3}, splice({1,3}, 2, 2))
test_equal("splice() string", "John", splice("Jon", "h", 3))
test_equal("splice() string", "Johhhhhhhhhhn", splice("Jon", "hhhhhhhhhh", 3))
test_equal("splice() integer after length", "abc ", splice("abc", 32, 4 ) )

test_equal("patch() beyond target","John Doe  abc",patch("John Doe", "abc",11))
test_equal("patch() overlap target right","John Doabc",patch("John Doe", "abc",8))
test_equal("patch(): large patch","abcdefghij",patch("xyz","abcdefghij",-5))
test_equal("patch(): like replace()","Johabcoe",patch("John Doe","abc",4))
test_equal("patch(): beyond target left","abcJohn Doe",patch("John Doe","abc",-2))

test_equal("replace() integer sequence", {1,2,3}, replace({1,8,9,3}, 2, 2, 3))
test_equal("replace() integer sequence w/sequence", {1,2,3,4},
    replace({1,8,9,4}, {2,3}, 2, 3))
test_equal("replace() string sequence", "John", replace("Jahn", 'o', 2))
test_equal("replace() string sequence 2", "Jane", replace("John", "ane", 2, 4))
test_equal("replace() string sequence 1", "Jane", replace("Bone", "Ja", 1, 2) )
test_equal("replace() negative size slice", "Jane", replace("ne", "Ja", 1, 0 ) )
test_equal("replace() 2,5 #3a", "/--ething         "
              , replace("//something         ", "--" , 2, 5))

test_equal("replace() 2,5 #3b", "/--eething         "
             , replace("//something         ", "--e", 2, 5))

test_equal("replace() 2,5 #3c", " --something         "
             , replace(" //something         ", "--", 2, 3))

test_equal( "replace 4,-1", "aaajohndoe", replace("johndoe", "aaa", 4,-1 ))
test_equal( "replace 4,3", "johaaandoe", replace("johndoe", "aaa", 4,3 ))
test_equal( "replace 4,4", "johaaadoe",  replace("johndoe", "aaa", 4,4 ))
test_equal( "replace 4,5", "johaaaoe",   replace("johndoe", "aaa", 4,5 ))
test_equal( "replace 4,6", "johaaae",    replace("johndoe", "aaa", 4,6 ))
test_equal( "replace 4,7", "johaaa",     replace("johndoe", "aaa", 4,7 ))
test_equal( "replace 4,8", "johaaa",     replace("johndoe", "aaa", 4,8 ))

test_equal( "replace 4,5 with empty", "johoe",   replace("johndoe", "", 4,5 ))

test_equal( "replace 0,-1","aaajohndoe", replace("johndoe", "aaa", 0,-1 ))
test_equal( "replace 0,0", "aaajohndoe", replace("johndoe", "aaa", 0,0 ))
test_equal( "replace 0,1", "aaaohndoe",  replace("johndoe", "aaa", 0,1 ))
test_equal( "replace 0,2", "aaahndoe",   replace("johndoe", "aaa", 0,2 ))
test_equal( "replace 0,3", "aaandoe",    replace("johndoe", "aaa", 0,3 ))
test_equal( "replace 0,4", "aaadoe",     replace("johndoe", "aaa", 0,4 ))
test_equal( "replace 0,5", "aaaoe",      replace("johndoe", "aaa", 0,5 ))
test_equal( "replace 0,6", "aaae",       replace("johndoe", "aaa", 0,6 ))
test_equal( "replace 0,7", "aaa",        replace("johndoe", "aaa", 0,7 ))
test_equal( "replace 0,8", "aaa",        replace("johndoe", "aaa", 0,8 ))

test_equal( "replace 7,-1", "aaajohndoe", replace("johndoe", "aaa", 7,-1 ))
test_equal( "replace 7,0", "johndoaaae", replace("johndoe", "aaa", 7,0 ))
test_equal( "replace 7,1", "johndoaaae",  replace("johndoe", "aaa", 7,1 ))
test_equal( "replace 7,2", "johndoaaae",  replace("johndoe", "aaa", 7,2 ))
test_equal( "replace 7,3", "johndoaaae",  replace("johndoe", "aaa", 7,3 ))
test_equal( "replace 7,4", "johndoaaae",  replace("johndoe", "aaa", 7,4 ))
test_equal( "replace 7,5", "johndoaaae",  replace("johndoe", "aaa", 7,5 ))
test_equal( "replace 7,6", "johndoaaae",  replace("johndoe", "aaa", 7,6 ))
test_equal( "replace 7,7", "johndoaaa",  replace("johndoe", "aaa", 7,7 ))
test_equal( "replace 7,8", "johndoaaa",  replace("johndoe", "aaa", 7,8 ))

test_equal( "replace 8,-1","johndoeaaa", replace("johndoe", "aaa", 8,-1 ))
test_equal( "replace 8,0", "johndoeaaa", replace("johndoe", "aaa", 8,0 ))
test_equal( "replace 8,1", "johndoeaaa", replace("johndoe", "aaa", 8,1 ))
test_equal( "replace 8,2", "johndoeaaa", replace("johndoe", "aaa", 8,2 ))
test_equal( "replace 8,3", "johndoeaaa", replace("johndoe", "aaa", 8,3 ))
test_equal( "replace 8,4", "johndoeaaa", replace("johndoe", "aaa", 8,4 ))
test_equal( "replace 8,5", "johndoeaaa", replace("johndoe", "aaa", 8,5 ))
test_equal( "replace 8,8", "johndoeaaa", replace("johndoe", "aaa", 8,8 ))

-- Ticket:830 memory leak in replace()
integer deleted_830 = 0
procedure deleted_replaced_830( object o )
	deleted_830 += 1
end procedure
constant DR_830 = routine_id("deleted_replaced_830")
sequence bar_830, baz_830
bar_830 = delete_routine( "a" & "b", DR_830 )
baz_830 = bar_830
baz_830 = replace( bar_830, "c", 2, 2 )
bar_830 = ""
test_true( "replace() memory leak from ticket:830", deleted_830 )

sequence shuffleOrig = {1,2,3,3,4,5,5,5,6,"TEST"}, shuffled = shuffle(shuffleOrig)
-- Ensure that the result is the same length
test_equal( "shuffle size", length(shuffleOrig), length(shuffled))
-- Ensure that the same number of each original item is in shuffled.
for i = 1 to length(shuffleOrig) do
	test_equal( "shuffle items",  length(srch:find_all(shuffleOrig[i], shuffleOrig)),
	                              length(srch:find_all(shuffleOrig[i], shuffled)))
end for


procedure replace_objs()
	sequence 
		Code = {1,2,3,4,5},
		val = {"1234567890", {}, 9, 10, 0 }
	integer a, b, c , d, target, pc = 0	
	a = Code[pc+1]
 	b = Code[pc+2]
 	c = Code[pc+3]
 	d = Code[pc+4]
	test_equal( "replace end of sequence using temps",  "12345678", replace(val[a],val[b],val[c],val[d]) )
end procedure
replace_objs()
-- 
test_equal("pad_head() #1", "   ABC", pad_head("ABC", 6))
test_equal("pad_head() #2", "ABC", pad_head("ABC", 3))
test_equal("pad_head() #3", "ABC", pad_head("ABC", 1))
test_equal("pad_head() #4", "...ABC", pad_head("ABC", 6, '.'))

test_equal("pad_tail() #1", "ABC   ", pad_tail("ABC", 6))
test_equal("pad_tail() #2", "ABC", pad_tail("ABC", 3))
test_equal("pad_tail() #3", "ABC", pad_tail("ABC", 1))
test_equal("pad_tail() #4", "ABC...", pad_tail("ABC", 6, '.'))

test_equal("breakup(int, BK_LEN) sequence", {{1,2,3}, {4,5,6}}, breakup({1,2,3,4,5,6}, 3))
test_equal("breakup(int, BK_LEN) string", {"AB", "CD", "EF"}, breakup("ABCDEF", 2))
test_equal("breakup(int, BK_LEN) odd size", {"AB", "CD", "E"}, breakup("ABCDE", 2))
test_equal("breakup(int, BK_LEN) empty", {""}, breakup("", 2))
test_equal("breakup(int, BK_LEN) bad size 1", {"ABCDE"}, breakup("ABCDE", 0))
test_equal("breakup(int, BK_LEN) bad size 2", {"ABCDE"}, breakup("ABCDE", 99))

test_equal("breakup(int, BK_PIECES) sequence", {{1,2,3},{4,5,6}, {7,8,9}}, breakup({1,2,3,4,5,6,7,8,9}, 3, BK_PIECES))
test_equal("breakup(int, BK_PIECES) sequence", {{1,2,3,4}, {5,6,7}, {8, 9,10}}, breakup({1,2,3,4,5,6,7,8,9,10}, 3, BK_PIECES))
test_equal("breakup(int, BK_PIECES) sequence", {{1,2,3,4}, {5,6,7,8}, {9,10,11}}, breakup({1,2,3,4,5,6,7,8,9,10,11}, 3, BK_PIECES))
test_equal("breakup(int, BK_PIECES) string", {"ABC", "DEF"}, breakup("ABCDEF", 2, BK_PIECES))
test_equal("breakup(int, BK_PIECES) odd size", {"ABC", "DE"}, breakup("ABCDE", 2, BK_PIECES))
test_equal("breakup(int, BK_PIECES) empty", {""}, breakup("", 2, BK_PIECES))
test_equal("breakup(int, BK_PIECES) bad size 1", {"ABCDE"}, breakup("ABCDE", 0, BK_PIECES))
test_equal("breakup(int, BK_PIECES) bad size 2", {"A", "B", "C", "D", "E"}, breakup("ABCDE", 99, BK_PIECES))
test_equal("breakup(int, BK_PIECES) bad size 3 (size OK as non-integer atom)", {"A", "B", "C", "D", "E"}, breakup("ABCDE", 99.5, BK_PIECES))

test_equal("breakup(int, CUSTOM) sequence", {{1}, {2,3}, {4,5,6}}, breakup({1,2,3,4,5,6}, {1,2,3}))
test_equal("breakup(int, CUSTOM) string", {"", "ABCD", "E", "FGHI"}, breakup("ABCDEFGHI", {0,4,1}))
test_equal("breakup(int, CUSTOM) odd size", {"ABCD", "E", ""}, breakup("ABCDE", {4,1,0}))
test_equal("breakup(int, CUSTOM) odd size 2", {"ABCD", "E", "", "", "F"}, breakup("ABCDEF", {4,1,0,0}))
test_equal("breakup(int, CUSTOM) empty", {""}, breakup("", {4}))
test_equal("breakup(int, CUSTOM) bad size 1", {"", "ABCDE"}, breakup("ABCDE", {0}))
test_equal("breakup(int, CUSTOM) bad size 2", {"ABCDE"}, breakup("ABCDE", {99}))
test_equal("breakup(int, CUSTOM) bad size 3", {"ABCDE"}, breakup("ABCDE", {}))

test_equal("flatten() nested", {1,2,3}, flatten({{1}, {2}, {3}}))
test_equal("flatten() deeply nested", {1,2,3}, flatten({{{{1}}}, 2, {{{{{3}}}}}}))
test_equal("flatten() string", "JohnDoe", flatten({{"John", {"Doe"}}}))
test_equal("flatten() empty", "", flatten({{"", {""}},{{}}}))

test_equal("flatten() nested text delim", "abc def g h i", flatten({"abc", "def", "g h i"}, " "))
test_equal("flatten() nested no delim", "abcdefg h i", flatten({"abc", "def", "g h i"}, ""))
test_equal("flatten() nested char delim", "abc,def,g h i", flatten({"abc", "def", "g h i"}, ","))

test_equal("vslice 1", {1,2,3}, vslice({{5,1}, {5,2}, {5,3}}, 2))
test_equal("vslice 2", {5,5,5}, vslice({{5,1}, {5,2}, {5,3}}, 1))
test_equal("vslice 3", {1,2,3}, vslice({{5,1}, {5,2}, {5,3}}, 2))
test_equal("vslice 4", {5,5,5}, vslice({{5,1}, {5,2}, {5,3}}, 1, {}))
test_equal("vslice 5", {6,6,6}, vslice({{5,1}, {5,2}, {5,3}}, 3, {6}))
test_equal("vslice 6", {1,6,3}, vslice({{5,1}, {5}, {5,3}}, 2, {6}))
test_equal("vslice 7", {1,6,6}, vslice({{5,1}, {5}, {9}}, 2, {6}))
test_equal("vslice 8", {1,6,4}, vslice({{5,1}, {5}, {9}}, 2, {6,4}))
test_equal("vslice 9", {6},     vslice({0}, 2, {6,4}))


test_equal("binop_ok #1",  0, binop_ok({{1,2},{3,4}}, {5,6,7}))
test_equal("binop_ok #2",  0, binop_ok({{1,2},{3,4}}, {5,{6,7,8}}))
test_equal("binop_ok #3",  1, binop_ok({{1,2},{3,4}}, {{5,6},7}))
test_equal("binop_ok #4",  1, binop_ok({{1,2},{3,4}}, 5))
test_equal("binop_ok #5",  1, binop_ok(5, {{1,2},{3,4}}))
test_equal("binop_ok #6",  1, binop_ok(1, 2))

test_equal("series 1+", {{1,5},{4,8},{7,11},{10,14}},    series({1,5},  3, 4))
test_equal("series 2+", 0,                               series({1,2,3},1, -1 ) )
test_equal("series 3+", {{1,2,3}, {5,1,13}, {9,0,23}},   series({1,2,3}, {4,-1,10}, 3))
test_equal("series 4+", {{1,2,3}},                       series({1,2,3}, 1, 1 ) )
test_equal("series 5+", {1, {2,3,4}, {3,5,7}, {4,7,10}}, series(1, {1,2,3}, 4 ) )
test_equal("series 6+", {1, 5, 9, 13, 17, 21},           series(1, 4, 6 ) )
test_equal("series 7+", 0,                               series({1,2}, {1,2,3}, 4 ) )
test_equal("series 8+", {12, 9, 6, 3},                   series( 12, -3, 4 ) )

test_equal("series 1*", {{1,5},{3,15},{9,45},{27,135}},  series({1,5},  3, 4, '*'))
test_equal("series 2*", 0,                               series({1,2,3},1, -1, '*' ) )
test_equal("series 3*", {{1,2,3}, {4,-2,30}, {16,2,300}},series({1,2,3}, {4,-1,10}, 3, '*'))
test_equal("series 4*", {{1,2,3}},                       series({1,2,3}, 1, 1, '*' ) )
test_equal("series 5*", {1, {1,2,3}, {1,4,9}, {1,8,27}}, series(1, {1,2,3}, 4, '*' ) )
test_equal("series 6*", {1, 4, 16, 64, 256, 1024},       series(1, 4, 6, '*' ) )
test_equal("series 7*", 0,                               series({1,2}, {1,2,3}, 4, '*' ) )
test_equal("series 8*", {12, 6, 3, 1.5},                 series( 12, 0.5, 4, '*' ) )
test_equal("series 1?", 0,                               series({1,2}, {1,2,3}, 4, '?' ) )
test_equal("series empty", {},                           series(1,2,0) )

sequence s
s={0,1,2,3,{"aaa",{{3},{1},{2}},"ccc"},4}
test_equal("fetch",{2},fetch(s,{5,2,3}))
test_equal("store",{0,1,2,3,{"aaa",{{3},{1},{98,98,98}},"ccc"},4},store(s,{5,2,3},"bbb"))

test_equal("repeat_pattern",{1,2,1,2,1,2,1,2},repeat_pattern({1,2},4))
test_equal("repeat_pattern 1c", {}, repeat_pattern("it", 0))


sequence vect,coords
vect={{21,22,23},{4,5,6,7},{8,9,0},{10,-1,-2,-3}}
coords={{2,1},{1,3},{2}}
test_equal("project",{{{22,21},{21,23},{22}},{{5,4},{4,6},{5}},{{9,8},{8,0},{9}},{{-1,10},{10,-2},{-1}}},seq:project(vect,coords))

sequence S1
S1={{2,3,5,7,11,13},{17,19,23,29,31,37},{41,43,47,53,59,61}}

test_equal("project()",
{{{3,5,11},{2,7,13}},{{19,23,31},{17,29,37}},{{43,47,59},{41,53,61}}},
project(S1,{{2,3,5},{1,4,6}}))

test_equal("extract 1",{11,17,13},extract({13,11,9,17},{2,4,1}))
test_equal("extract 2",{11,13,11,13,9,9},extract({13,11,9,17},{2,1,2,1,3,3}))
test_equal("extract 3",{},extract({13,11,9,17},{}))
test_equal("extract 4",{17},extract({13,11,9,17},{4}))

test_equal("valid_index 1", 1,valid_index({1,2,3},3.5))
test_equal("valid_index 2", 0,valid_index({1,2,3}, -1))
test_equal("valid_index 3", 0,valid_index({1,2,3}, 0))
test_equal("valid_index 4", 0,valid_index({1,2,3}, 4))
test_equal("valid_index 5", 0,valid_index({1,2,3}, {}))
test_equal("valid_index 6", 0,valid_index({1,2,3}, {2}))
test_equal("valid_index 7", 1,valid_index({1,2,3}, 1))
test_equal("valid_index 8", 1,valid_index({1,2,3}, 2))
test_equal("valid_index 9", 1,valid_index({1,2,3}, 3))
test_equal("valid_index A", 0,valid_index({}, 0))
test_equal("valid_index B", 0,valid_index({}, 1))

test_equal("rotate: left -1", {1,6,2,3,4,5,7},rotate({1,2,3,4,5,6,7},-1*ROTATE_LEFT,2,6))
test_equal("rotate: left 0",  {1,2,3,4,5,6,7},rotate({1,2,3,4,5,6,7}, 0*ROTATE_LEFT,2,6))
test_equal("rotate: left 1",  {1,3,4,5,6,2,7},rotate({1,2,3,4,5,6,7}, 1*ROTATE_LEFT,2,6))
test_equal("rotate: left 2",  {1,4,5,6,2,3,7},rotate({1,2,3,4,5,6,7}, 2*ROTATE_LEFT,2,6))
test_equal("rotate: left 3",  {1,6,2,3,4,5,7},rotate({1,2,3,4,5,6,7}, 4*ROTATE_LEFT,2,6))
test_equal("rotate: left 4",  {1,2,3,4,5,6,7},rotate({1,2,3,4,5,6,7}, 5*ROTATE_LEFT,2,6))
test_equal("rotate: left 7",  {1,4,5,6,2,3,7},rotate({1,2,3,4,5,6,7}, 7*ROTATE_LEFT,2,6))
test_equal("rotate: left 2/0",{1,2,3,4,5,6,7},rotate({1,2,3,4,5,6,7}, 2*ROTATE_LEFT,5,5))

test_equal("rotate: right -1", {1,3,4,5,6,2,7},rotate({1,2,3,4,5,6,7},-1*ROTATE_RIGHT,2,6))
test_equal("rotate: right 0",  {1,2,3,4,5,6,7},rotate({1,2,3,4,5,6,7}, 0*ROTATE_RIGHT,2,6))
test_equal("rotate: right 1",  {1,6,2,3,4,5,7},rotate({1,2,3,4,5,6,7}, 1*ROTATE_RIGHT,2,6))
test_equal("rotate: right 2",  {1,5,6,2,3,4,7},rotate({1,2,3,4,5,6,7}, 2*ROTATE_RIGHT,2,6))
test_equal("rotate: right 3",  {1,3,4,5,6,2,7},rotate({1,2,3,4,5,6,7}, 4*ROTATE_RIGHT,2,6))
test_equal("rotate: right 4",  {1,2,3,4,5,6,7},rotate({1,2,3,4,5,6,7}, 5*ROTATE_RIGHT,2,6))
test_equal("rotate: right 7",  {1,5,6,2,3,4,7},rotate({1,2,3,4,5,6,7}, 7*ROTATE_RIGHT,2,6))
test_equal("rotate: right 2/0",{1,2,3,4,5,6,7},rotate({1,2,3,4,5,6,7}, 2*ROTATE_RIGHT,5,5))



sequence a, b, c
a = split("John Doe")
b = a[1]
c = a[2]
test_equal("More defaulted params and tokens",{"John","Doe"},{b,c})
test_equal("replace()  #2,5a", "/--ething", replace("//something", "--", 2, 5))
test_equal("replace() #2,5b ", "/--ething        ", replace("//something        ", "--", 2, 5))
test_not_equal("replace() 2,5 #3a", "/--omeething         ", replace("//something                                        ", "--", 2, 5))
test_not_equal("replace() 2,5 #3b", "/--eething         ", replace("//something                                            ", "--", 2, 5))
test_not_equal("replace() 2,5 #3c", " --someething         ", replace(" //something                                           ", "--", 2, 3))

test_equal("reverse 1c", "tegrat", reverse("target", -1))
test_equal("reverse 2c", "target", reverse("target", 2, 1))
test_equal("reverse 3c", "tategr", reverse("target", 3, 0))
test_equal("reverse 4c", "tategr", reverse("target", 3, 7))
test_equal("reverse 5c", "target", reverse("target", 7))

test_equal("pivot #1", {{2, -4.8, 3.341, -8}, {6, 6, 6, 6}, {7, 8.5, "text"}}, pivot( {7, 2, 8.5, 6, 6, -4.8, 6, 6, 3.341, -8, "text"}, 6 ))
test_equal("pivot #2", {{-4, -1, -7}, {}, {4, 1, 6, 9, 10}}, pivot( {4, 1, -4, 6, -1, -7, 9, 10} ) )
test_equal("pivot #3", {{}, {}, {5}}, pivot( 5 ) )
test_equal("pivot #4", {{}, {5}, {}}, pivot( 5, 5 ) )
test_equal("pivot #5", {{5}, {}, {}}, pivot( 5, 10 ) )
test_equal("pivot #6", {{}, {}, {}}, pivot( {}) )
test_equal("pivot #7", {{"abc", "bcd"}, {}, {"def", "efg", "cdf"}}, pivot( {"abc", "def", "bcd", "efg", "cdf"}, "cat") )


function mask_nums(atom a, object t)
    if sequence(t) then
        return 0
    end if
    return and_bits(a, t) != 0
end function

function even_nums(atom a, object t)
    return and_bits(a,1) = 0
end function

constant data = {5,8,20,19,3,2,10}
test_equal("filter #1", {5,19,3}, filter(data, routine_id("mask_nums"), 1))
test_equal("filter #2", {19, 3, 2, 10}, filter(data, routine_id("mask_nums"), 2))
test_equal("filter #3", {8, 20, 2, 10}, filter(data, routine_id("even_nums")))

test_equal("filter in lt", {5,3,2}, filter(data, "lt", 8))
test_equal("filter in <", {5,3,2}, filter(data, "<", 8))
test_equal("filter in le", {5,8,3,2}, filter(data, "le", 8))
test_equal("filter in <=", {5,8,3,2}, filter(data, "<=", 8))
test_equal("filter in eq", {8}, filter(data, "eq", 8))
test_equal("filter in =", {8}, filter(data, "=", 8))
test_equal("filter in ==", {8}, filter(data, "==", 8))
test_equal("filter in ne", {5,20,19,3,2,10}, filter(data, "ne", 8))
test_equal("filter in !=", {5,20,19,3,2,10}, filter(data, "!=", 8))
test_equal("filter in gt", {20,19,10}, filter(data, "gt", 8))
test_equal("filter in >", {20,19,10}, filter(data, ">", 8))
test_equal("filter in ge", {8,20,19,10}, filter(data, "ge", 8))
test_equal("filter in >=", {8,20,19,10}, filter(data, ">=", 8))

-- Using 'in' and 'out' with sets.
test_equal("filter in set", {5,8,3}, filter(data, "in", {3,4,5,6,7,8}))
test_equal("filter out set", {20,19,2,10}, filter(data, "out", {3,4,5,6,7,8}))

-- Using 'in' and 'out' with ranges.
test_equal("filter in [] range", {5,8,3}, filter(data, "in",  {3,8}, "[]"))
test_equal("filter in [) range", {5,3}, filter(data, "in",  {3,8}, "[)")) 
test_equal("filter in (] range", {5,8}, filter(data, "in",  {3,8}, "(]")) 
test_equal("filter in () range", {5}, filter(data, "in",  {3,8}, "()")) 
test_equal("filter out [] range", {20,19,2,10}, filter(data, "out", {3,8}, "[]")) 
test_equal("filter out [) range", {8,20,19,2,10}, filter(data, "out", {3,8}, "[)")) 
test_equal("filter out (] range", {20,19,3,2,10}, filter(data, "out", {3,8}, "(]")) 
test_equal("filter out () range", {8,20,19,3,2,10}, filter(data, "out", {3,8}, "()")) 
test_equal("filter STDFLTR_ALPHA", "abc",
		filter("123abc123", STDFLTR_ALPHA, {})
	)

constant data1 = {5,8,20,19,3,2,10}
test_equal("filter 1c", {5,8,3}, filter(data1, "in", {3,4,5,6,7,8}))
test_equal("filter 2c", {20,19,2,10}, filter(data1, "out", {3,4,5,6,7,8}))
test_equal("filter3c", {}, filter({}, "in"))

test_equal("sim_index 0c", 0.08784, round(sim_index("sit", "sin"), 1e5))
test_equal("sim_index 1c", 0.32394, round(sim_index("sit", "sat"), 1e5))
test_equal("sim_index 2c", 0.34324, round(sim_index("sit", "skit"), 1e5))
test_equal("sim_index 3c", 0.68293, round(sim_index("sit", "its"), 1e5))

test_equal("minsize 1c", {4,3,6,2,7,1,2,-1,-1,-1}, minsize({4,3,6,2,7,1,2}, 10, -1))
test_equal("minsize 2c", {4,3,6,2,7,1,2}, minsize({4,3,6,2,7,1,2}, 5, -1))


function quiksort(sequence s)
	if length(s) < 2 then
		return s
	end if
	return quiksort( filter(s[2..$], "<=", s[1]) ) & s[1] & quiksort(filter(s[2..$], ">", s[1]))
end function
test_equal("qs", {0,1,2,2,4,4,4,5,5,7,7,8,9,32,54,67,445}, 
				quiksort( {5,4,7,2,4,9,1,0,4,32,7,54,2,5,8,445,67} ))


function sprinter(object a, object t)
	return sprint(a + t)
end function
test_equal("apply #1", {"8","9","10","11"}, apply({1,2,3,4}, routine_id("sprinter"), 7))


include std/math.e
include std/search.e

function f1(object x, sequence i, object q)
 -- modify the input if twice the input is above a threshold
	if (2 * abs(x) > q) then
   		return {1,{abs(x) * x, i[1]}}
   	else	
   		return {0}
   	end if 
end function

function f2(object x, sequence i, object q)
 -- remove zeros if they in an 'even' position
 

	if (x = 0) and (remainder(i[1],2) = 0) then
		return {0}
	else
		return {1,x}
	end if
end function

function f3(object x, sequence i, object q)
 -- remove items
	if (x < q) then
		return {0}
	else
		return {1,x}
	end if
end function

function f4(object x, sequence i, object q)
 -- Create alternate file names for C source code files.
	integer pos
	
	if atom(x) then return {} end if
	pos = rfind('.', x)
	if pos > 0 then
		if find(x[pos+1 ..$], {"c", "h", "cpp", "hpp"}) then
			x = x[1..pos] 
		else 
			return {}
		end if
	else
		x = x & '.' 
	end if
	x &= q 
	if (i[1] != i[2]) then
		x &= ','
	end if
	return {1,x }

end function

integer r1 = routine_id("f1")
integer r2 = routine_id("f2")
integer r3 = routine_id("f3")
integer r4 = routine_id("f4")

test_equal("build_list #1", {-9,1,-4,2,-1.5,0,1.1,4,6,9,7}, build_list({-3,-2,-1.5,0,1.1,2,3}, {r1,r2,-1}, 0, 3))
test_equal("build_list #2", {{-9,1},{-4,2},-1.5,0,1.1,{4,6},{9,7}}, build_list({-3,-2,-1.5,0,1.1,2,3}, {r1,r2,-1},, 3))
test_equal("build_list #3", {-9,1,-4,2,4,6,9,7}, build_list({-3,-2,-1.5,0,1.1,2,3}, r1,0, 3))
test_equal("build_list #4", {-3,-2,-1.5,0,1.1,2,3}, build_list({-3,-2,-1.5,0,1.1,2,3}, -1))
test_equal("build_list #5", {0,1.1,2,3}, build_list({-3,-2,-1.5,0,1.1,2,3}, r3,,0))
test_equal("build_list #6", "reader.bak,conio.bak,writer.bak,utils.bak",  build_list({
		"reader.c", "conio.h", 123.456, "app.obj", "writer", "utils.cpp"
			}, r4,0, "bak"))

function replace_with_refcount( sequence s2 )
	return replace( s2, "abc", 2, 4)
end function

sequence replace_ref_count = "1234567890_"
sequence replace_ref_result = replace_with_refcount( replace_ref_count )
test_equal( "replace_refcount", replace_ref_result, "1abc567890_" )
test_equal( "replace doesn't clobber target if refcount > 1", "1234567890_", replace_ref_count )

sequence result = replace( "xyza", "kcd", 2, 4 )
test_not_equal( "replace doesn't modify temps (failure will display expected and result as equal)", "xyza", result )

-- insert in place
sequence in_place
in_place = "1234567890"
in_place = insert( in_place, 'a', 2 )
test_equal( "first in place insert (will make copy)", in_place, "1a234567890" )
in_place = insert( in_place, 'b', 4 )
test_equal( "second in place insert (actually change in place)", in_place, "1a2b34567890" )

-- splice in place
in_place = "1234567890"
in_place = splice( in_place, "a", 2 )
test_equal( "first in place splice (will make copy)", "1a234567890", in_place )
in_place = splice( in_place, "b", 4 )
test_equal( "second in place splice (actually change in place)", "1a2b34567890", in_place )

-- in place replace
in_place = "1234567890"
in_place = replace( in_place, "a", 1, 1 )
test_equal( "replace in place sequence same size", "a234567890", in_place )
in_place = replace( in_place, "b", 2, 2 )
test_equal( "replace in place sequence same size (2)", "ab34567890", in_place )
in_place = replace( in_place, "cd", 3, 2 )
test_equal( "inplace replace 3, 2", "abcd34567890", in_place )
test_equal( "replace 3, 2", "abcd34567890", replace( "ab34567890", "cd", 3, 2 ) )
test_equal( "replace 4,3", "johaaandoe", replace("johndoe", "aaa", 4,3 ))
test_equal( "replace all with sequence", "5678", replace( "1234", "5678", 1, 4 ) )
test_equal( "replace all with integer", {1}, replace( "1234", 1, 1, 4 ) )

-- remove in place
in_place = "1234567890"
in_place = remove( in_place, 1, 1 )
test_equal( "remove in place (will make a copy)", "234567890", in_place )
in_place = remove( in_place, 1, 1 )
test_equal( "remove in place 1,1", "34567890", in_place )
in_place = remove( in_place, 2, 3 )
test_equal( "remove in place 2,3", "367890", in_place )
in_place = remove( in_place, 5, 6 )
test_equal( "remove in place 5,6", "3678", in_place )

test_equal("columnize #1", {{1,3,5}, {2,4,6}}, columnize({{1, 2}, {3, 4}, {5, 6}}))
test_equal("columnize #2", {{1,3,5}, {2,4,6}, {0,0,7}}, columnize({{1, 2}, {3, 4}, {5, 6, 7}}))
test_equal("columnize #3", {{1,3,5}, {2,4,6}, {-999,-999,7}}, columnize({{1, 2}, {3, 4}, {5, 6, 7}},,-999))
test_equal("columnize #4", {{2,4,6}}, columnize({{1, 2}, {3, 4}, {5, 6, 7}}, 2))
test_equal("columnize #5", {{2,4,6},{1,3,5}}, columnize({{1, 2}, {3, 4}, {5, 6, 7}}, {2,1}))
test_equal("columnize #6", {"adg", "beh", "cfi"}, columnize({"abc", "def", "ghi"}))
test_equal("columnize 1c", {"adg", "beh", "cfi" }, columnize({"abc", "def", "ghi"}) )
test_equal("columnize 2c", {"ac", {'d',0}}, columnize({"ad", "c"}) )



test_equal("remove_subseq #1", {4, 6, 0.1, 4}, remove_subseq({4,6,"Apple",0.1, {1,2,3}, 4}, SEQ_NOALT))
test_equal("remove_subseq #2", {4, 6, -1, 0.1, -1, 4}, remove_subseq({4,6,"Apple",0.1, {1,2,3}, 4}, -1))
test_equal("remove_subseq #3", {14, 16, 9, 0.1, 1, 2, 3, 4}, remove_subseq({14,16,9,0.1,1,2,3,4}, SEQ_NOALT))

include std/sort.e as sort
sequence rds = { 4,7,9,7,2,5,5,9,0,4,4,5,6,5}
test_equal("remove_dups inplace", {4,7,9,2,5,0,6}, remove_dups(rds, RD_INPLACE))
test_equal("remove_dups sort",    {0,2,4,5,6,7,9}, remove_dups(rds, RD_SORT))
test_equal("remove_dups presorted #1", {4,7,9,7,2,5,9,0,4,5,6,5}, remove_dups(rds, RD_PRESORTED))
test_equal("remove_dups presorted #2", {0,2,4,5,6,7,9}, remove_dups(sort(rds), RD_PRESORTED))

test_equal("combine #1s", {"cat","dog","fish","snail","whale","wolf","worm"}, combine({ {"cat", "dog"}, {"fish", "whale"}, {"wolf"}, {"snail", "worm"}}))
test_equal("combine #1u", {"cat", "dog", "fish", "whale", "wolf", "snail", "worm"}, combine({ {"cat", "dog"}, {"fish", "whale"}, {"wolf"}, {"snail", "worm"}}, COMBINE_UNSORTED))
test_equal("combine #2s", {0,2,4,4,5,5,5,6,7,7,9,9}, combine({ {4,7,9}, {7,2,5,9}, {0,4}, {5}, {6,5}}))
test_equal("combine #2u", {4,7,9,7,2,5,9,0,4,5,6,5}, combine({ {4,7,9}, {7,2,5,9}, {0,4}, {5}, {6,5}}, COMBINE_UNSORTED))
test_equal("combine #3s", "aaacdeffghhiilllmnooorsstwww", combine({"cat", "dog","fish", "whale", "wolf", "snail", "worm"}))
test_equal("combine #3u", "catdogfishwhalewolfsnailworm", combine({"cat", "dog","fish", "whale", "wolf", "snail", "worm"}, COMBINE_UNSORTED))
test_equal("combine 1c", {}, combine(""))
test_equal("combine 2c", '1', combine("1"))

-- transforming
test_equal("transform", "HELLO", transform(" hello    ", {{routine_id("trim"), " ",0},routine_id("upper")}))
test_equal("transform 1c", "HELLO", transform("hello",routine_id("upper")))

-- mapping
test_equal("mapping A", "ThE CAt In thE HAt", mapping("The Cat in the Hat", "aeiou", "AEIOU"))
test_equal("mapping B", "u cut uto this brewn nat", mapping("a cat ate this brown nut", "aeiou", "uoiea"))
test_equal("mapping C", "a23456789", mapping("123456789", "123", "a"))
test_equal("mapping D", {'a','b',{'c',4},5}, mapping({1,2,{3,4},5}, {1,2,3}, "abc"))
test_equal("mapping E", "312", mapping({"one", "two", "three"}, {"two", "three", "one"}, "123", 1))
test_equal("mapping F", 4, mapping( 1, {1, 2, 3}, {4, 5, 6}) )

-- remove_item
test_equal("remove_item #1", {3,4,2}, remove_item( 1, {3,4,2,1} ))
test_equal("remove_item #2", {3,4,2,1}, remove_item( 5, {3,4,2,1} ))
test_equal("remove_item 1c", "itsit", remove_item('s', "sitsit"))
test_equal("remove_item 2c", "itit", remove_item('s', "itsit"))

-- transmute()
test_equal("transmute Comp:sub Repl:item", "2e 3ool 1oes", transmute("the school shoes", {{}, "sh", "th", "sch"}, "123"))
test_equal("transmute Comp:sub Repl:seq", "THe SCHool SHoes", transmute("the school shoes", {{}, "sh", "th", "sch"}, {{}, "SH", "TH", "SCH"}))
test_equal("transmute Comp:sub Remove", "e ool oes", transmute("the school shoes", {{}, "sh", "th", "sch"}, {{}, "", "", ""}))
test_equal("transmute Comp:sub Repl:mixed", "THe SCHool xoes", transmute("the school shoes", {{}, "sh", "th", "sch"}, {{}, 'x', "TH", "SCH"}))
test_equal("transmute Comp:item Repl:item", "JIhn SmOth UnjIAs EncIIkUd YpplUs.", transmute("John Smith enjoys uncooked apples.", "aeiouy", "YUOIEA"))
test_equal("transmute Comp:item Repl:seq", "J'O'hn Sm'I'th 'E'nj'O''Y's 'U'nc'O''O'k'E'd 'A'ppl'E's.", transmute("John Smith enjoys uncooked apples.", "aeiouy", {{}, "'A'", "'E'", "'I'", "'O'", "'U'", "'Y'"}))
test_equal("transmute Comp:item Remove", "Jhn Smth njs nckd ppls.", transmute("John Smith enjoys uncooked apples.", "aeiouy", {{}, "", "", "", "", "", ""}))
test_equal("transmute Comp:item Repl:mixed", "JOWhn Smth 1njOW{}s 2ncOWOWk1d AAppl1s.", transmute("John Smith enjoys uncooked apples.", "aeiouy", {{}, "AA", '1', "", "OW", '2', "{}"}))


-- added at r3525, crashing the translator
s = { {{1}}, {1} } + 1
s = s[1][1]
test_equal("RHS SUBS self assignment", 2,  s[1] )

procedure xor_test()
	sequence x = {0, 1, 2, 3, 4, 5}
	sequence y = {1, 0, 1, 1, 0, 0}
   
	if not equal(x xor y, y xor x) then
		test_fail("sanity basic sequence xor test")
	end if
	if compare({{1,1,0,0,1,1}}, {x} xor {y}) != 0 then
		test_fail("sanity comparison sequence xor test")
	end if
end procedure
xor_test()

procedure ticket_639()
	sequence a, b
	a = "abc" & "d"
	a = a[2..$]
	b = "123"
	a = splice( a, b, 2 )
	test_equal("in place RHS_slice + in place splice()", "b123cd", a )
end procedure
ticket_639()

procedure test_add_item()
	sequence items = {}
	items = add_item( 1, items )
	test_equal( "add_item: empty sequence", {1}, items )
	
	items = add_item( 1, items )
	test_equal( "add_item: duplicate value to add_item", {1}, items )
	
	items = add_item( 2, items )
	test_equal( "add_item: default is prepend", {2, 1}, items )
	
	items = add_item( 3, items, ADD_APPEND )
	test_equal( "add_item:  ADD_APPEND", {2,1,3}, items )
	
	items = add_item( {}, items )
	test_equal( "add_item: add sequence item", {{},2,1,3}, items )
	
	items = add_item( "a", items, ADD_SORT_UP )
	test_equal( "add_item: sort ascending", {1,2,3,{},"a"}, items )
	
	items = add_item( "b", items, ADD_SORT_DOWN )
	test_equal( "add_item: sort descending", {"b","a",{},3,2,1}, items )
end procedure
test_add_item()


test_report()

