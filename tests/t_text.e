include std/text.e as seq
include std/unittest.e



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
test_equal("trim() almost empty", "a", trim(" a ", 32))
test_equal("trim() nothing", "abcdef", trim("abcdef", 32))

test_equal("lower() zero", 0, lower(0))
test_equal("lower() atom", 'a', lower('A'))
test_equal("lower() letters only", "john", lower("JoHN"))
test_equal("lower() mixed text", "john 55 &%.", lower("JoHN 55 &%."))
test_equal("lower() with \\0", "abc\0def", lower("abc" & 0 & "DEF"))
test_equal("lower() nested", {'a', "bcd", 'e', "fg"}, lower({'A', "BcD", 'e', "fG"}))

test_equal("upper() atom", 'A', upper('a'))
test_equal("upper() letters only", "JOHN", upper("joHn"))
test_equal("upper() mixed text", "JOHN 50 &%.", upper("joHn 50 &%."))
test_equal("upper() with \\0", "ABC\0DEF", upper("abc" & 0 & "DEF"))

test_equal("escape() default", "John \\\"Mc\\\" Doe", escape("John \"Mc\" Doe"))
test_equal("escape() non-standard", "\\$100\\.50", escape("$100.50", "$."))

test_equal("sprint() integer", "10", sprint(10))
test_equal("sprint() float", "5.5", sprint(5.5))
test_equal("sprint() sequence #1", "{1,{2},3,{}}", sprint({1,{2},3,{}}))
test_equal("sprint() sequence #2", "{97,98,99}", sprint("abc"))
test_equal("sprintf() integer", "i=1", sprintf("i=%d", {1}))
test_equal("sprintf() float", "i=5.5", sprintf("i=%.1f", {5.5}))
test_equal("sprintf() percent", "%", sprintf("%%", {}))


-- proper
test_equal("proper #1", {"The Quick Brown", "The Quick Brown", "_abc Abc_12_def34fgh", {2.3, 'a'}, "123Word*Another*Word((Here))"},
	proper({"the quick brown", "THE QUICK BROWN", "_abc abc_12_def34fgh", {2.3, 'a'}, "123word*another*word((here))"})
	)
test_equal("proper #2", "Euphoria Programming Language", proper("euphoria programming language"))
test_equal("proper #3", "Euphoria Programming Language", proper("EUPHORIA PROGRAMMING LANGUAGE"))
test_equal("proper #4", {"Euphoria Programming", "Language", "Rapid Deployment", "Software"},
			proper({"EUPHORIA PROGRAMMING", "language", "rapid dEPLOYMENT", "sOfTwArE"}))
test_equal("proper #5", {'A', 'b', 'c'}, proper({'a', 'b', 'c'}))
test_equal("proper #6", {'a', 'b', 'c', 3.1472}, proper({'a', 'b', 'c', 3.1472}))
test_equal("proper #7", {"Abc", 3.1472}, proper({"abc", 3.1472}))


-- keyvalues()
sequence s
s = keyvalues("foo=bar, qwe=1234,, asdf='contains space, comma, and equal(=)'")
test_equal("keyvalues #1", { {"foo", "bar"}, {"qwe", "1234"}, {"asdf", "contains space, comma, and equal(=)"}}, s)

s = keyvalues("abc fgh=ijk def, =")
test_equal("keyvalues #2", { {"p[1]", "abc"}, {"fgh", "ijk"}, {"p[3]", "def"},{} }, s)

s = keyvalues("abc=`'quoted'`")
test_equal("keyvalues #3", { {"abc", "'quoted'"} }, s)

s = keyvalues("'a b c'=quoted")
test_equal("keyvalues #3a", { {"a b c", "quoted"} }, s)

s = keyvalues("colors=(a=black, b=blue, c=red)")
test_equal("keyvalues #4", { {"colors", {{"a", "black"}, {"b", "blue"},{"c", "red"}}  } }, s)

s = keyvalues("colors={ a=black, b=blue, c=red}")
test_equal("keyvalues #4a", { {"colors", {"a=black", "b=blue","c=red"}}  } , s)

s = keyvalues("colors  =  [a=black, b=blue, c=red]")
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

s = keyvalues("colors=`[black, blue, red]`")
test_equal("keyvalues #9", { {"colors", {"black", "blue", "red"}}  }, s)

s = keyvalues("colors=black, blue, red", "",,,"")
test_equal("keyvalues #10", { {"colors", "black, blue, red"}  }, s)

s = keyvalues("colors=[black, blue, red]\n  animals=  [cat,dog, rabbit]\n")
test_equal("keyvalues #11", { {"colors", { "black", "blue", "red"}}, {"animals", { "cat", "dog", "rabbit"}  } }, s)

s = keyvalues("colors=[black, blue, red]\nanimals=~{cat,dog, rabbit}\n")
test_equal("keyvalues #11a", { {"colors", { "black", "blue", "red"}}, {"animals", "{cat,dog, rabbit}"  } }, s)

set_encoding_properties("Test Encoded", "aeiouy", "AEIOUY")
test_equal("Encoding #1", {"Test Encoded", "aeiouy", "AEIOUY"}, get_encoding_properties())

test_equal("Encoding uppercase #1", "thE cAt In thE hAt", upper("the cat in the hat"))
test_equal("Encoding lowercase #1", "THe CaT iN THe HaT", lower("THE CAT IN THE HAT"))

set_encoding_properties("", "", "")
test_equal("Encoding #2", {"ASCII", "", ""}, get_encoding_properties())

test_equal("Encoding uppercase #2", "THE CAT IN THE HAT", upper("the cat in the hat"))
test_equal("Encoding lowercase #3", "the cat in the hat", lower("THE CAT IN THE HAT"))

set_encoding_properties("../source/codepage/1251")
object ec
ec = get_encoding_properties()
test_equal("Encoding #3", "Windows 1251 (Cyrillic)", ec[1])
test_equal("Encoding uppercase #3", "THE CAT IN THE HAT", upper("the cat in the hat"))
-- Test cyrillic characters
test_equal("Encoding uppercase #4", {#80,#81,#8A,#8C,#8D,#8E,#8F,#A1,#A3,#A5,#A8,#AA,#AF,#B2,#BD,#C0,#C1,#C2,#C3,#C4,#C5,#C6,#C7,#C8,#C9,#CA,#CB,#CC,#CD,#CE,#CF,#D0,#D1,#D2,#D3,#D4,#D5,#D6,#D7,#D8,#D9,#DA,#DB,#DC,#DD,#DE,#DF},
							  upper({#90,#83,#9A,#9C,#9D,#9E,#9F,#A2,#BC,#B4,#B8,#BA,#BF,#B3,#BE,#E0,#E1,#E2,#E3,#E4,#E5,#E6,#E7,#E8,#E9,#EA,#EB,#EC,#ED,#EE,#EF,#F0,#F1,#F2,#F3,#F4,#F5,#F6,#F7,#F8,#F9,#FA,#FB,#FC,#FD,#FE,#FF}))

set_encoding_properties("", "", "")

set_encoding_properties("0737")

ec = get_encoding_properties()
test_equal("Encoding #5", "OEM 737 (Greek)", ec[1])
test_equal("Encoding uppercase #5", "THE CAT IN THE HAT", upper("the cat in the hat"))
-- Test greek characters
test_equal("Encoding uppercase #6", {#80,#81,#82,#83,#84,#85,#86,#87,#88,#89,#8A,#8B,#8C,#8D,#8E,#8F,#90,#91,#92,#93,#94,#95,#96,#97,#EA,#EB,#EC,#F4,#ED,#EE,#EF,#F5,#E9},
                              upper({#98,#99,#9A,#9B,#9C,#9D,#9E,#9F,#A0,#A1,#A2,#A3,#A4,#A5,#A6,#A7,#A8,#A9,#AB,#AC,#AD,#AE,#AF,#E0,#E1,#E2,#E3,#E4,#E5,#E6,#E7,#E8,#F0}))
                              
set_encoding_properties("", "", "")


-- quote()
test_equal("quote #1", "\"The small man\"", quote("The small man"))
test_equal("quote #2", "(The small man)", quote("The small man", {"(", ")"} ))
test_equal("quote #3", "(The ~(small~) man)", quote("The (small) man", {"(", ")"}, '~' ))
test_equal("quote #4", "The (small) man", quote("The (small) man", {"(", ")"}, '~', "#" ))
test_equal("quote #5", "(The #1 ~(small~) man)", quote("The #1 (small) man", {"(", ")"}, '~', "#" ))
test_equal("quote #6", "", quote( "" ) )
test_equal("quote #7", `"foo"`, quote( "foo", '\"' ) )
test_equal("quote #8", `"foo"`, quote( "foo", "" ) )
test_equal("quote #9", `"foo"`, quote( "foo", {`"`} ) )
test_equal("quote #10", `"foo"`, quote( "foo", {'\"'}, '?' ) )
test_equal("quote #11", "(The ~(small~) man)" , quote("The (small) man", {"(", ")"}, '~' ) )
test_equal("quote #12", "(The ~~~(small~~~) man)" , quote("The ~(small~) man", {"(", ")"}, '~' ) )
test_equal("quote #13", "$The ~$small~$ man$" , quote("The $small$ man", {"$"}, '~' ) )
test_equal("quote #14", "$The ~~~$small~~~$ man$" , quote("The ~$small~$ man", {"$"}, '~' ) )
test_equal("quote #15", repeat("\"The small man\"",2), quote( repeat("The small man", 2)))
test_equal("quote #16", `(The ~(small~)! man)`, quote("The (small)! man", {"(", ")"}, '~', "#!" ))

-- format()
sequence res
sequence exp
res = format("Cannot open file '[]' - code []", {"/usr/temp/work.dat", 32})
exp = "Cannot open file '/usr/temp/work.dat' - code 32"
test_equal("format 'A'", exp, res)

res = format("Err-[2], Cannot open file '[1]'", {"/usr/temp/work.dat", 32})
exp = "Err-32, Cannot open file '/usr/temp/work.dat'"
test_equal("format 'B'", exp, res)

res = format("[4w] [3z:2] [6] [5l] [2z:2], [1:4]", {2009,4,21,"DAY","MONTH","of"})
exp = "Day 21 of month 04, 2009"
test_equal("format 'C'", exp, res)

res = format("The answer is [:6.2]%", {35.22341})
exp = "The answer is  35.22%"
test_equal("format 'D'", exp, res)

res = format("The answer is [.2]", {0})
exp = "The answer is 0.00"
test_equal("format 'E'", exp, res)

res = format("The answer is [.6]", {1.2345})
exp = "The answer is 1.234500"
test_equal("format 'F'", exp, res)

res = format("The answer is [.2]", {1.2345})
exp = "The answer is 1.23"
test_equal("format 'G'", exp, res)

res = format("The answer is [.0]", {1.2345})
exp = "The answer is 1"
test_equal("format 'H'", exp, res)

res = format("The answer is [.4]", {1.2345e17})
exp = "The answer is 1.2345e+17"
test_equal("format 'I'", exp, res)

res = format("The answer is [b.2]", {0})
exp = "The answer is "
test_equal("format 'J'", exp, res)

res = format("The answer is [tb.2]", {0})
exp = "The answer is"
test_equal("format 'K'", exp, res)

res = format("[] [] []", {"one", "two", "three"})
exp = "one two three"
test_equal("format 'L'", exp, res)

res = format("[] [] []", {"one", "", "three"})
exp = "one  three" -- extra whitespace stripped out.
test_equal("format 'M'", exp, res)

res = format("[] [s] []", {"one", "", "three"})
exp = "one   three"
test_equal("format 'N'", exp, res)

res = format("[] [?]", {5, {"cats", "cat"}})
exp = "5 cats"
test_equal("format 'O'", exp, res)

res = format("[] [?]", {1, {"cats", "cat"}})
exp = "1 cat"
test_equal("format 'P'", exp, res)

res = format("don't eat [t] [?]", {"", {"worms", "worm"}})
exp = "don't eat worms"
test_equal("format 'Q'", exp, res)

res = format("don't eat [t] [?]", {"the", {"worms", "worm"}})
exp = "don't eat the worm"
test_equal("format 'R'", exp, res)

res = format("Array[[323:.323f][]]", {2})
exp = "Array[2]"
test_equal("format 'S'", exp, res)

res = format("[c:3]", {"abcdef"})
exp = "bcd"
test_equal("format 'T'", exp, res)

res = format("[c:4]", {"abcdef"})
exp = "bcde"
test_equal("format 'U'", exp, res)

res = format("[<:4]", {"abcdef"})
exp = "abcd"
test_equal("format 'V'", exp, res)

res = format("[>:4]", {"abcdef"})
exp = "cdef"
test_equal("format 'W'", exp, res)

res = format("[c:8]", {"abcdef"})
exp = " abcdef "
test_equal("format 'X'", exp, res)

res = format("[<:8]", {"abcdef"})
exp = "abcdef  "
test_equal("format 'Y'", exp, res)

res = format("[>:8]", {"abcdef"})
exp = "  abcdef"
test_equal("format 'Z'", exp, res)

res = format("seq is []", {{1.2, 5, "abcdef", {3}}})
exp = `seq is {1.2,5,"abcdef",{3}}`
test_equal("format 'AA'", exp, res)

res = format("hex is #[Xlz:8]", {1715004})
exp = "hex is #001a2b3c"
test_equal("format 'AB'", exp, res)

res = format("hex is #[:08X]", {1715004})
exp = "hex is #001A2B3C"
test_equal("format 'AC'", exp, res)

res = format("The answer is [,,.2]", {1234.56})
exp = "The answer is 1,234.56"
test_equal("format 'AD'", exp, res)

res = format("The answer is [,..2]", {1234.56})
exp = "The answer is 1.234,56"
test_equal("format 'AE'", exp, res)

res = format("The answer is [,:.2]", {1234.56})
exp = "The answer is 1:234.56"
test_equal("format 'AF'", exp, res)

res = format("[B]", 177)
exp = "10110001"
test_equal("format 'AG'", exp, res)

res = format("[B]", -177)
exp = "11111111111111111111111101001111"
ifdef BITS64 then
	exp = repeat( '1', 32 ) & exp
end ifdef
test_equal("format '[B]'", exp, res)

res = format("[B:16]", 177)
exp = "        10110001"
test_equal("format '[B:16]'", exp, res)

res = format("[, B]", 177)
exp = "1011 0001"
test_equal("format '[, B]'", exp, res)

res = format("[, X]", 0x123456ab)
exp = "1234 56AB"
test_equal("format 'AK'", exp, res)

res = format("[+z:8]", 117)
exp  = "+0000117"
test_equal("format 'AL'", exp, res)

res = format("[+z:8]", -117)
exp  = "-0000117"
test_equal("format 'AM'", exp, res)

res = format("[+z:8]", 0)
exp  = "00000000"
test_equal("format 'AN'", exp, res)

res = format("[+z:8]", 117.2)
exp  = "+00117.2"
test_equal("format 'AO'", exp, res)

res = format("[+z:8]", -117.2)
exp  = "-00117.2"
test_equal("format 'AP'", exp, res)

res = format("[+]", 117)
exp  = "+117"
test_equal("format 'AQ'", exp, res)

res = format("[+]", -117)
exp  = "-117"
test_equal("format 'AR'", exp, res)

res = format("[+]", 0)
exp  = "0"
test_equal("format 'AS'", exp, res)

res = format("[+]", 117.2)
exp  = "+117.2"
test_equal("format 'AT'", exp, res)

res = format("[+]", -117.2)
exp  = "-117.2"
test_equal("format 'AU'", exp, res)

res = format("[(]", -117.2)
exp  = "(117.2)"
test_equal("format 'AV'", exp, res)

res = format("[(z:8]", -117.2)
exp  = "(0117.2)"
test_equal("format 'AW'", exp, res)

res = format("[(]", -117)
exp  = "(117)"
test_equal("format 'AX'", exp, res)

res = format("[(z:8]", -117)
exp  = "(000117)"
test_equal("format 'AY'", exp, res)

res = format("[(z:3]", -117)
exp  = "17)"
test_equal("format 'AY#2'", exp, res)

res = format("[(]", 117)
exp  = "117"
test_equal("format 'AZ'", exp, res)

res = format("[(]", 117.2)
exp  = "117.2"
test_equal("format 'BA'", exp, res)

res = format("Today is [u{day}:9], the [{date], [{badname}]?", {"date=09/Oct/2012", "day=Tuesday"})
exp = "Today is TUESDAY  , the 09/Oct/2012, ?"
test_equal("format 'BB'", exp, res)

res = format("[T]", 117)
exp  = "u"
test_equal("format 'BC'", exp, res)

res = format("[T]", 117.45)
exp  = "u"
test_equal("format 'BC#2'", exp, res)

res = format("[T]", "U")
exp  = "U"
test_equal("format 'BD'", exp, res)

include std/os.e
setenv("testenv", "AbCdEf")
object gv
gv = getenv("testenv")
test_equal("env", "AbCdEf", "AbCdEf")

res = format("([lc%testenv%:20])")
exp = "(       abcdef       )"
test_equal("format 'BE'", exp, res)

res = format("[%testenv] symbol")
exp = "AbCdEf symbol"
test_equal("format 'BF'", exp, res)

res = format("[%badname%] symbol")
exp = " symbol"
test_equal("format 'BG'", exp, res)

res = format("[:08]", 0)
exp = "00000000"
test_equal("format 'BH'", exp, res)

res = format("[b:3]", 0.0)
exp  = "   "
test_equal("format 'BI'", exp, res)

res = format("hex is #[Xlz:8]", {1715.004})
exp = "hex is #000006b3"
test_equal("format 'BJ'", exp, res)

res = format("hex is #[:04X]", {171.5004})
exp = "hex is #00AB"
test_equal("format 'BK'", exp, res)

res = format("[(:07]", {-345.5004})
exp = "5.5004)"
test_equal("format 'BL'", exp, res)

-- dequote()
test_equal( "dequote empty", "", dequote( "" ) )
test_equal( "dequote no pairs", `foo`, dequote( `"foo"`, "" ) )
test_equal( "dequote atom pair", `foo`, dequote( `"foo"`, '\"' ) )
test_equal( "dequote defaults 1", "The small man", dequote("\"The small man\"") )
test_equal( "dequote defaults 2", "The small (? ) man", dequote("(The small ?(? ?) man)", {{"(",")"}}, '?') )

test_equal( "dequote multiple strings", {"The small man","The small () man"}, 
	dequote({"\"The small man\"", "(The small ?(?) man)"}, {{"(",")"},{"\"","\""}}, '?'))

test_equal("trim 1c ", {4,4},  trim(" \t .\t", " \t\r\n", 1)  )
test_equal("trim_head 1c ", 4,  trim_head(" \t .\t", " \t\r\n", 1)  )
test_equal("trim_tail 1c ", 4,  trim_tail(" \t .\t", " \t\r\n", 1)  )

test_equal("keyvalues 1c", { {"foo", "bar"}, {"qwe", "1234"}, {"asdf", "contains space, comma, and equal(=)"}},
	keyvalues("foo=bar, qwe=1234, asdf='contains space, comma, and equal(=)'")
 )

test_equal("keyvalues 2c", { {"p[1]", "abc"}, {"fgh", "ijk"}, {"p[3]", "def"} },
	keyvalues("abc fgh=ijk def")
 )
test_equal("keyvalues 3c", { {"abc", "'quoted'"} },
	keyvalues("abc=`'quoted'`")
 )
test_equal("keyvalues 4c", {{"c", ""}}, keyvalues("c=`\t`"))
test_equal("keyvalues 5c", {{"c", ""}}, keyvalues("c='\t'"))
test_equal("keyvalues 6c", {}, keyvalues(""))
test_equal("keyvalues 7c", {{"c", "=t"}},
	keyvalues("c:=t", 0x3B)  --;
 )
test_equal("keyvalues 8c", {{"c", "t"}},
	keyvalues("c=t",, 0x3D)  --=
 )
test_equal("keyvalues 9c", {{"c", "t"}},
	keyvalues("c=t",,, 0x60)  --`
 )
test_equal("keyvalues ac",{{"c", "t"}},
	keyvalues("c=\tt",,,, 0x09)  --\t
 )

 --need to also check is covered on more than one system
test_equal("change case 1uc","", upper("") )
test_equal("change case 1lc","", lower("") )
-- curent default initial max on len of case change string
test_equal("change case 2c",repeat('a',1024), lower(repeat('A',1024)) )

test_equal("wrap() #1", "Hello\nWorld", wrap("Hello World", 3))
test_equal("wrap() #2", "Hello World, How\nare you doing?", 
	wrap("Hello World, How are you doing?", 20))
test_equal("wrap() #3", "Hello World,\nHow are you doing?",
		wrap("Hello World, How are you doing?", 20, "\n", ","))

test_report()

