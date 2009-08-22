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
--test_equal("head() bad len", "Joh", head(hs, -3))
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

test_equal("slice() string", "Middle", slice("John Middle Doe", 6, 11))
test_equal("slice() string, zero end", "Middle Doe", slice("John Middle Doe", 6, 0))
test_equal("slice() string, neg end", "Middle", slice("John Middle Doe", 6, -4))
test_equal("slice() sequence", {2,3}, slice({1,2,3,4}, 2, 3))
test_equal("slice() nested sequence", {{3,4},{5,6}}, slice({{1,2},{3,4},{5,6},{7,8}}, 2, 3))
test_equal("slice() bounds", "Middle Doe", slice("John Middle Doe", 6, 50))

test_equal("tail() string default", "ohn Middle Doe", tail("John Middle Doe"))
test_equal("tail() string", "Doe", tail("John Middle Doe", 3))
test_equal("tail() sequence", {3,4}, tail({1,2,3,4}, 2))
test_equal("tail() nested sequence", {{3,4},{5,6}}, tail({{1,2},{3,4},{5,6}}, 2))
test_equal("tail() bounds", {1,2,3,4}, tail({1,2,3,4}, 50))

test_equal("split() simple string no empty", {"John","Middle","Doe"}, split(" John  Middle  Doe  ",,,1))
test_equal("split() simple string", {"a","b","c"}, split("a,b,c", ","))
test_equal("split() sequence", {{1},{2},{3},{4}}, split({1,0,2,0,3,0,4}, 0))
test_equal("split() nested sequence", {{"John"}, {"Doe"}}, split({"John", 0, "Doe"}, 0))
test_equal("split() limit set", {"a", "b,c"}, split("a,b,c", ',', 1))
test_equal("split() single sequence delimiter",{"while 1 "," end while ",""},
	split("while 1 do end while do","do"))
test_equal("split() an empty string", {}, split("", ","))
test_equal("split() using an empty delimiter", {"1","2","3"}, split("123", ""))
test_equal("split() using an empty delimiter and limit", {"1","23"}, split("123", "", 1))

test_equal("split_any()", {"a", "b", "c"}, split_any("a,b.c", ",."))
test_equal("split_any() limit", {"a", "b", "c|d"}, split_any("a,b.c|d", ",.|", 2))
test_equal("split_any() no empty", {"a", "b", "c"}, split_any(",a,,b...c.", ",.",,1))

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

test_equal("insert() integer sequence", {1,2,3}, insert({1,3}, 2, 2))
test_equal("insert() string", {'J','o',"h",'n'}, insert("Jon", "h", 3))

test_equal("splice() integer sequence", {1,2,3}, splice({1,3}, 2, 2))
test_equal("splice() string", "John", splice("Jon", "h", 3))

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
test_equal("flatten() nested char delim", "abc,def,g h i", flatten({"abc", "def", "g h i"}, ','))

test_equal("vslice() #1", {1,2,3}, vslice({{5,1}, {5,2}, {5,3}}, 2))
test_equal("vslice() #2", {5,5,5}, vslice({{5,1}, {5,2}, {5,3}}, 1))

test_equal("can_add #1",0,can_add({{1,2},{3,4}},{5,6,7}))
test_equal("can_add #2",1,can_add({{1,2},{3,4}},{{5,6},7}))

test_equal("linear",{{1,5},{4,8},{7,11},{10,14}},linear({1,5},3,4))

sequence s
s={0,1,2,3,{"aaa",{{3},{1},{2}},"ccc"},4}
test_equal("fetch",{2},fetch(s,{5,2,3}))
test_equal("store",{0,1,2,3,{"aaa",{{3},{1},{98,98,98}},"ccc"},4},store(s,{5,2,3},"bbb"))

test_equal("repeat_pattern",{1,2,1,2,1,2,1,2},repeat_pattern({1,2},4))
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

test_equal("pivot #1", {{2, -4.8, 3.341, -8}, {6, 6, 6, 6}, {7, 8.5, "text"}}, pivot( {7, 2, 8.5, 6, 6, -4.8, 6, 6, 3.341, -8, "text"}, 6 ))
test_equal("pivot #2", {{-4, -1, -7}, {}, {4, 1, 6, 9, 10}}, pivot( {4, 1, -4, 6, -1, -7, 9, 10} ) )
test_equal("pivot #3", {{}, {}, {5}}, pivot( 5 ) )
test_equal("pivot #4", {{}, {5}, {}}, pivot( 5, 5 ) )
test_equal("pivot #5", {{5}, {}, {}}, pivot( 5, 10 ) )
test_equal("pivot #6", {{}, {}, {}}, pivot( {}) )
test_equal("pivot #7", {{"abc", "bcd"}, {}, {"def", "efg", "cdf"}}, pivot( {"abc", "def", "bcd", "efg", "cdf"}, "cat") )

function gt_ten(integer a, object t)
	return a > t
end function
test_equal("filter #1", {20,30,40}, filter({1,2,3,20,4,30,6,40,6}, routine_id("gt_ten"), 10))


function sprinter(object a, object t)
	return sprint(a + t)
end function
test_equal("apply #1", {"8","9","10","11"}, apply({1,2,3,4}, routine_id("sprinter"), 7))


test_equal("is_in_range #1", 0, is_in_range(1, {}))
test_equal("is_in_range #2", 0, is_in_range(1, {1}))
test_equal("is_in_range #3", 0, is_in_range(1, {2,9}))
test_equal("is_in_range #4", 0, is_in_range(10, {2,9}))
test_equal("is_in_range #5", 1, is_in_range(2, {2,9}))
test_equal("is_in_range #6", 1, is_in_range(9, {2,9}))
test_equal("is_in_range #7", 1, is_in_range(5, {2,9}))

test_equal("set_in_range #1", 1, set_in_range(1, {}))
test_equal("set_in_range #2", 1, set_in_range(1, {1}))
test_equal("set_in_range #3", 2, set_in_range(1, {2,9}))
test_equal("set_in_range #4", 9, set_in_range(10, {2,9}))
test_equal("set_in_range #5", 2, set_in_range(2, {2,9}))
test_equal("set_in_range #6", 9, set_in_range(9, {2,9}))
test_equal("set_in_range #7", 5, set_in_range(5, {2,9}))

test_equal("is_in_list #1", 0, is_in_list(1, {}))
test_equal("is_in_list #2", 1, is_in_list(1, {1}))
test_equal("is_in_list #3", 0, is_in_list(1, {100, 2, 45, 9, 17, -6}))
test_equal("is_in_list #4", 1, is_in_list(100, {100, 2, 45, 9, 17, -6}))
test_equal("is_in_list #5", 1, is_in_list(-6, {100, 2, 45, 9, 17, -6}))
test_equal("is_in_list #6", 1, is_in_list(9, {100, 2, 45, 9, 17, -6}))

test_equal("set_in_list #1", 1, set_in_list(1, {}))
test_equal("set_in_list #2", 1, set_in_list(1, {1}))
test_equal("set_in_list #3", 100, set_in_list(1, {100, 2, 45, 9, 17, -6}))
test_equal("set_in_list #4", 100, set_in_list(100, {100, 2, 45, 9, 17, -6}))
test_equal("set_in_list #5", -6, set_in_list(-6, {100, 2, 45, 9, 17, -6}))
test_equal("set_in_list #6", 9, set_in_list(9, {100, 2, 45, 9, 17, -6}))



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

-- replace_all
test_equal("replace_all #1", "XbrXcXdXbrX", replace_all("abracadabra", 'a', 'X'))
test_equal("replace_all #2", "abXcadabX", replace_all("abracadabra", "ra", 'X'))
test_equal("replace_all #3", "aabraacaadaabraa", replace_all("abracadabra", "a", "aa"))
test_equal("replace_all #4", "brcdbr", replace_all("abracadabra", "a", ""))
test_equal("replace_all #5", "abracadabra", replace_all("abracadabra", "", "X"))

test_equal("columnize #1", {{1,3,5}, {2,4,6}}, columnize({{1, 2}, {3, 4}, {5, 6}}))
test_equal("columnize #2", {{1,3,5}, {2,4,6}, {0,0,7}}, columnize({{1, 2}, {3, 4}, {5, 6, 7}}))
test_equal("columnize #3", {{1,3,5}, {2,4,6}, {-999,-999,7}}, columnize({{1, 2}, {3, 4}, {5, 6, 7}},,-999))
test_equal("columnize #4", {{2,4,6}}, columnize({{1, 2}, {3, 4}, {5, 6, 7}}, 2))
test_equal("columnize #5", {{2,4,6},{1,3,5}}, columnize({{1, 2}, {3, 4}, {5, 6, 7}}, {2,1}))
test_equal("columnize #6", {"adg", "beh", "cfi"}, columnize({"abc", "def", "ghi"}))



test_equal("remove_subseq #1", {4, 6, 0.1, 4}, remove_subseq({4,6,"Apple",0.1, {1,2,3}, 4}, SEQ_NOALT))
test_equal("remove_subseq #2", {4, 6, -1, 0.1, -1, 4}, remove_subseq({4,6,"Apple",0.1, {1,2,3}, 4}, -1))
test_equal("remove_subseq #3", {14, 16, 9, 0.1, 1, 2, 3, 4}, remove_subseq({14,16,9,0.1,1,2,3,4}, SEQ_NOALT))

include std/sort.e
sequence rds = { 4,7,9,7,2,5,5,9,0,4,4,5,6,5}
test_equal("remove_dups inplace", {4,7,9,2,5,0,6}, remove_dups(rds, RD_INPLACE))
test_equal("remove_dups sort",    {0,2,4,5,6,7,9}, remove_dups(rds, RD_SORT))
test_equal("remove_dups presorted #1", {4,7,9,7,2,5,9,0,4,5,6,5}, remove_dups(rds, RD_PRESORTED))
test_equal("remove_dups presorted #2", {0,2,4,5,6,7,9}, remove_dups(sort(rds), RD_PRESORTED))

test_equal("merge #1", {"cat","dog","fish","snail","whale","wolf","worm"}, merge({ {"cat", "dog"}, {"fish", "whale"}, {"wolf"}, {"snail", "worm"}}))
test_equal("merge #2", {0,2,4,4,5,5,5,6,7,7,9,9}, merge({ {4,7,9}, {7,2,5,9}, {0,4}, {5}, {6,5}}))

-- transforming
test_equal("transform", "HELLA", transform(" hello    ", {{routine_id("trim"), " ",0},routine_id("upper"), {routine_id("replace_all"), "O", "A"}}))

-- mapping
test_equal("mapping A", "ThE CAt In thE HAt", mapping("The Cat in the Hat", "aeiou", "AEIOU"))
test_equal("mapping B", "u cut uto this brewn nat", mapping("a cat ate this brown nut", "aeiou", "uoiea"))
test_equal("mapping C", "a23456789", mapping("123456789", "123", "a"))
test_equal("mapping D", {'a','b',{'c',4},5}, mapping({1,2,{3,4},5}, {1,2,3}, "abc"))
test_equal("mapping E", "312", mapping({"one", "two", "three"}, {"two", "three", "one"}, "123", 1))

test_report()

