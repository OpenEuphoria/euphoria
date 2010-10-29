include std/unittest.e
include std/filesys.e

include get.e

test_equal("value() no data supplied", {GET_EOF, 0}, value(""))
test_equal("value() integer", {GET_SUCCESS, 10}, value("10"))
test_equal("value() bad integer", {GET_FAIL, 0}, value("John"))
test_equal("value() float", {GET_SUCCESS, 10.5}, value("10.5"))
test_equal("value() sequence", {GET_SUCCESS, {1,2}}, value("{1,2}"))
test_equal("value_from() integer", {GET_FAIL, 0}, value("Data: 10"))



test_equal("value() scientific notation #1", {GET_SUCCESS, 3.14e2}, value("3.14e2"))
test_equal("value() scientific notation #2", {GET_SUCCESS, 3.14e-12}, value("3.14E-12"))
test_equal("value() scientific notation #3", {GET_SUCCESS, 3.14e+12}, value("+3.14e+12"))
test_equal("value() scientific notation #4 no exponent", {GET_FAIL, 0}, value("+3.14e"))

test_equal("value() no hex digits", {GET_FAIL, 0}, value("#"))
test_equal("value() decimal point only", {GET_FAIL, 0}, value("."))

constant 
	OBJECT = { 1, 2, 3, "foo", {-9},{}},
	TEXT = "some text",
	CHAR = 'f'

integer fn = open( "get.txt", "w" )
print(fn, OBJECT )
printf(fn, "\n\"%s\"\n'%s'\n", { TEXT, CHAR } )

close(fn)

fn = open( "get.txt", "r" )
test_equal( "print / get", { GET_SUCCESS, OBJECT}, get( fn ) )
test_equal( "print / get", { GET_SUCCESS, TEXT}, get( fn ) )
test_equal( "print / get", { GET_SUCCESS, CHAR}, get( fn ) )
test_equal( "print / get", { GET_EOF, 0}, get( fn ) )
close(fn)

delete_file( "get.txt" )

test_report()

