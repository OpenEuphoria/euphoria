include sequence.e as seq
include unittest.e

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

test_equal("split() simple string", {"a","b","c"}, split("a,b,c", ","))
test_equal("split() sequence", {{1},{2},{3},{4}}, split({1,0,2,0,3,0,4}, 0))
test_equal("split() nested sequence", {{"John"}, {"Doe"}}, split({"John", 0, "Doe"}, 0))
test_equal("split() limit set", {"a", "b,c"}, split("a,b,c", ',', 2))
test_equal("split() any character", {"a", "b", "c"}, split("a,b.c", ",.", 0, 1))
test_equal("split() limit and any character", {"a", "b", "c|d"},
    split("a,b.c|d", ",.|", 3, 1))
test_equal("split() single sequence delimiter",{"while 1 "," end while ",""},
    split("while 1 do end while do","do"))

test_equal("join() simple string default", "a b c", join({"a", "b", "c"}))
test_equal("join() simple string", "a,b,c", join({"a", "b", "c"}, ","))
test_equal("join() nested sequence", {"John", 0, "Doe"}, join({{"John"}, {"Doe"}}, 0))

test_equal("remove() integer sequence", {1,3}, remove({1,2,3}, 2))
test_equal("remove() string", "Jon", remove("John", 3))
test_equal("remove() nested sequence", {{1,2}, {5,6}}, remove({{1,2},{3,4},{5,6}}, 2))
test_equal("remove() bounds", "John", remove("John", 55))

test_equal("remove() range integer sequence", {1,5}, remove({1,2,3,4,5}, 2, 4))
test_equal("remove() range string", "John Doe", remove("John M Doe", 5, 6))
test_equal("remove() range bounds #1", "John", remove("John Doe", 5, 100))
test_equal("remove() range bounds #2", "John Doe", remove("John Doe", 3, 1))
test_equal("remove() range bounds #3", "John Doe", remove("John Doe", -3, -1))
test_equal("remove() range bounds with floats", "n Doe", remove("John Doe", 1.5, 3))

test_equal("remove_all() 1", {2,3,4,3,2}, remove_all(1,{1,2,3,1,4,3,1,2,1}))
test_equal("remove_all() 2", "Ask what you can do for your country.", 
           remove_all('x',"xAxsk whxat you caxn do for yoxur countryx.x"))

test_equal("insert() integer sequence", {1,2,3}, insert({1,3}, 2, 2))
test_equal("insert() string", {'J','o',"h",'n'}, insert("Jon", "h", 3))

test_equal("splice() integer sequence", {1,2,3}, splice({1,3}, 2, 2))
test_equal("splice() string", "John", splice("Jon", "h", 3))

test_equal("replace() integer sequence", {1,2,3}, replace({1,8,9,3}, 2, 2, 3))
test_equal("replace() integer sequence w/sequence", {1,2,3,4},
    replace({1,8,9,4}, {2,3}, 2, 3))
test_equal("replace() string sequence", "John", replace("Jahn", 'o', 2))
test_equal("replace() string sequence 2", "Jane", replace("John", "ane", 2, 4))
test_equal("replace() 2,5 #3a", "/--ething         "
              , replace("//something         ", "--" , 2, 5))

test_equal("replace() 2,5 #3b", "/--eething         "
             , replace("//something         ", "--e", 2, 5))

--unittest crashing pretty.e:133 in procedure rPrint()
--subscript value 34 is out of bounds, reading from a sequence of length 33
test_equal("replace() 2,5 #3c", " --something         "
             , replace(" //something         ", "--", 2, 3))

test_equal("trim_head() default", "John", trim_head(" \r\n\t John"))
test_equal("trim_head() specified", "Doe", trim_head("John Doe", " hoJn"))
test_equal("trim_head() integer", "John", trim_head("\nJohn", 10))
test_equal("trim_head() floating number", {-1,{}} , trim_head({0.5,1/2,-1,{}},0.5))
test_equal("trim_head() to empty", "", trim_head("  ", 32))

test_equal("trim_tail() defaults", "John", trim_tail("John\r \n\t"))
test_equal("trim_tail() specified", "John", trim_tail("John Doe", " eDo"))
test_equal("trim_tail() integer", "John", trim_tail("John\n", 10))
test_equal("trim_tail() floating number", {-1,{}} , trim_tail({-1,{},0.5,1/2},0.5))
test_equal("trim_tail() to empty", "", trim_tail(" ", 32))

test_equal("trim() defaults", "John", trim("\r\n\t John \n\r\t"))
test_equal("trim() specified", "John", trim("abcJohnDEF", "abcDEF"))
test_equal("trim() integer", "John\t\n", trim(" John\t\n ", 32))
test_equal("trim() to empty", "", trim("  ", 32))

test_equal("pad_head() #1", "   ABC", pad_head("ABC", 6))
test_equal("pad_head() #2", "ABC", pad_head("ABC", 3))
test_equal("pad_head() #3", "ABC", pad_head("ABC", 1))
test_equal("pad_head() #4", "...ABC", pad_head("ABC", 6, '.'))

test_equal("pad_tail() #1", "ABC   ", pad_tail("ABC", 6))
test_equal("pad_tail() #2", "ABC", pad_tail("ABC", 3))
test_equal("pad_tail() #3", "ABC", pad_tail("ABC", 1))
test_equal("pad_tail() #4", "ABC...", pad_tail("ABC", 6, '.'))

test_equal("chunk() sequence", {{1,2,3}, {4,5,6}}, chunk({1,2,3,4,5,6}, 3))
test_equal("chunk() string", {"AB", "CD", "EF"}, chunk("ABCDEF", 2))
test_equal("chunk() odd size", {"AB", "CD", "E"}, chunk("ABCDE", 2))

test_equal("flatten() nested", {1,2,3}, flatten({{1}, {2}, {3}}))
test_equal("flatten() deeply nested", {1,2,3}, flatten({{{{1}}}, 2, {{{{{3}}}}}}))
test_equal("flatten() string", "JohnDoe", flatten({{"John", {"Doe"}}}))

test_equal("vslice() #1", {1,2,3}, vslice({{5,1}, {5,2}, {5,3}}, 2))
test_equal("vslice() #2", {5,5,5}, vslice({{5,1}, {5,2}, {5,3}}, 1))

test_equal("lower() atom", 'a', lower('A'))
test_equal("lower() letters only", "john", lower("JoHN"))
test_equal("lower() mixed text", "john 55 &%.", lower("JoHN 55 &%."))
test_equal("upper() atom", 'A', upper('a'))
test_equal("upper() letters only", "JOHN", upper("joHn"))
test_equal("upper() mixed text", "JOHN 50 &%.", upper("joHn 50 &%."))

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

test_equal("extract",{11,17,13},extract({13,11,9,17},{2,4,1}))
test_equal("valid_index",1,valid_index({1,2,3},3.5))

test_equal("rotate_left: left",{1,4,5,6,2,3,7},rotate_left({1,2,3,4,5,6,7},2,6,2))
test_equal("rotate_left: right",{1,5,6,2,3,4,7},rotate_left({1,2,3,4,5,6,7},2,6,-2))

sequence a, b, c
a = split("John Doe")
b = a[1]
c = a[2]
test_equal("More defaulted params and tokens",{"John","Doe"},{b,c})
					
test_equal("sprint() integer", "10", sprint(10))
test_equal("sprint() float", "5.5", sprint(5.5))
test_equal("sprint() sequence", "{1,2,3}", sprint({1,2,3}))
test_equal("sprintf() integer", "i=1", sprintf("i=%d", {1}))
test_equal("sprintf() float", "i=5.5", sprintf("i=%.1f", {5.5}))
test_equal("sprintf() percent", "%", sprintf("%%", {}))

-- keyvalues()
s = keyvalues("foo=bar, qwe=1234, asdf='contains space, comma, and equal(=)'")
test_equal("keyvalues #1", { {"foo", "bar"}, {"qwe", "1234"}, {"asdf", "contains space, comma, and equal(=)"}}, s)

s = keyvalues("abc fgh=ijk def")
test_equal("keyvalues #2", { {"p[1]", "abc"}, {"fgh", "ijk"}, {"p[3]", "def"} }, s)

s = keyvalues("abc=`'quoted'`")
test_equal("keyvalues #3", { {"abc", "'quoted'"} }, s)

s = keyvalues("colors=(a=black, b=blue, c=red)")
test_equal("keyvalues #4", { {"colors", {{"a", "black"}, {"b", "blue"},{"c", "red"}}  } }, s)

s = keyvalues("colors={a=black, b=blue, c=red}")
test_equal("keyvalues #4a", { {"colors", {"a=black", "b=blue","c=red"}}  } , s)

s = keyvalues("colors=[a=black, b=blue, c=red]")
test_equal("keyvalues #4b", { {"colors", {"a=black", "b=blue","c=red"}}  } , s)

s = keyvalues("colors=(black=[0,0,0], blue=[0,0,FF], red=[FF,0,0])")
test_equal("keyvalues #5", { {"colors", {{"black",{"0", "0", "0"}}, {"blue",{"0", "0", "FF"}},{"red", {"FF","0","0"}}}} }, s)

s = keyvalues("colors=(black=(r=0,g=0,b=0), blue={r=0,g=0,b=FF}, red=['F`F',0,0])")
test_equal("keyvalues #5a", { {"colors", {{"black",{{"r","0"}, {"g","0"}, {"b","0"}}}, 
              {"blue",{"r=0", "g=0", "b=FF"}},{"red", {"F`F","0","0"}}}} }, s)

s = keyvalues("colors=[black, blue, red]")
test_equal("keyvalues #6", { {"colors", { "black", "blue", "red"}  } }, s)

s = keyvalues("colors=~[black, blue, red]")
test_equal("keyvalues #7", { {"colors", "[black, blue, red]"}  } , s)

s = keyvalues("colors=`~[black, blue, red]`")
test_equal("keyvalues #8", { {"colors", "[black, blue, red]"}  }, s)

s = keyvalues("colors=`[black, blue, red]")
test_equal("keyvalues #9", { {"colors", {"black", "blue", "red"}}  }, s)

test_equal("replace()  #2,5a", "/--ething", replace("//something", "--", 2, 5))

test_equal("replace() #2,5b ", "/--ething        ", replace("//something        ", "--", 2, 5))

test_not_equal("replace() 2,5 #3a", "/--omeething         ", replace("//something                                        ", "--", 2, 5))

test_not_equal("replace() 2,5 #3b", "/--eething         ", replace("//something                                            ", "--", 2, 5))

test_not_equal("replace() 2,5 #3c", " --someething         ", replace(" //something                                           ", "--", 2, 3))

test_report()

