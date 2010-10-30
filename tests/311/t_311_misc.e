include std/unittest.e
include std/io.e
include std/filesys.e

include misc.e

test_not_equal( "instance != 0", 0, instance() )

sleep(0)
test_pass("sleep(0)")

test_equal( "reverse", {1,2,3}, reverse( {3,2,1} ) )

test_equal("sprint() integer", "10", sprint(10) )
test_equal("sprint() float", "5.5", sprint(5.5))
test_equal("sprint() sequence #1", "{1,{2},3,{}}", sprint({1,{2},3,{}}))
test_equal("sprint() sequence #2", "{97,98,99}", sprint("abc"))
 
test_equal("arccos", 0, arccos(1.0) )
test_equal("arcsin", repeat(PI / 2.0, 2), arcsin( repeat( 1.0, 2) ) )

integer fn = open( "pp.txt", "w" )
pretty_print( fn, {1, 2.5, "abc"}, {} )
pretty_print( fn, repeat( 0, 10), {3,0,1,10,"%g","%f",32,127,5} )
pretty_print( fn, "a\n\t\r\"b" & 5, {3,0,1,10,"%g","%f",32,127,500} )
close(fn)

constant PP_VAL = `
{
  1,
  2.5,
  {97'a',98'b',99'c'}
}{0,0,
0,0,0,
0,0,0,
0,0}{'a',
'\n',
'\t',
'\r',
'"','b',
5}
`

test_equal( "pretty print", PP_VAL, read_file( "pp.txt" ) )

delete_file("pp.txt")

test_report()
