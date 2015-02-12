include std/get.e
include std/unittest.e
include std/filesys.e


test_equal("value() no data supplied", {GET_EOF, 0}, value(""))
test_equal("value() integer", {GET_SUCCESS, 10}, value("10"))
test_equal("value() bad integer", {GET_FAIL, 0}, value("John"))
test_equal("value() float", {GET_SUCCESS, 10.5}, value("10.5"))
test_equal("value() sequence", {GET_SUCCESS, {1,2}}, value("{1,2}"))
test_equal("value_from() integer", {GET_SUCCESS, 10, 2, 0}, value("Data: 10", 7,GET_LONG_ANSWER))
test_equal("value_from() integer with leading whitespace",
    {GET_SUCCESS, 10, 3, 1}, value("Data: 10", 6,GET_LONG_ANSWER))

test_equal("defaulted_value() #1", 0, defaulted_value("abc", 0))
test_equal("defaulted_value() #2", 10, defaulted_value("10", 0))
test_equal("defaulted_value() #3", 10.5, defaulted_value("10.5", 0))
test_equal("defaulted_value() #4", 0, defaulted_value(10.5, 0))
test_equal("defaulted_value() #5", {1,2,3}, defaulted_value("123={1,2,3}", 0, 5))
test_equal("defaulted_value() #6", 0, defaulted_value("123={1,2,3}", 0, 4))

test_equal("value() scientific notation #1", {GET_SUCCESS, 3.14e2}, value("3.14e2"))
test_equal("value() scientific notation #2", {GET_SUCCESS, 3.14e-12}, value("3.14E-12"))
test_equal("value() scientific notation #3", {GET_SUCCESS, 3.14e+12}, value("+3.14e+12"))
test_equal("value() scientific notation #4 no exponent", {GET_FAIL, 0}, value("+3.14e"))

test_equal("value() no hex digits", {GET_FAIL, 0}, value("#"))
test_equal("value() decimal point only", {GET_FAIL, 0}, value("."))

constant
	BACKTICK = `
\12\t\b\ns sdf " sdflkj sdf
`,
	TRIPLE = """
\ sdf\ ` ' " sdfs "

"""

test_equal("value() backtick", { GET_SUCCESS, BACKTICK }, value( '`' & BACKTICK & '`' ) )
test_equal("value() triple quote", { GET_SUCCESS, TRIPLE }, value( `"""` & TRIPLE & `"""` ) )

test_equal("value() below subnormal number (scientific notation)", {GET_SUCCESS, 0}, value("1e-380"))
test_equal("value() ridiculously below subnormal number (scientific notation)", {GET_SUCCESS, 0}, value("1e-50_000"))
test_equal("value() below subnormal number (standard decimal notation)", {GET_SUCCESS, 0}, value("0." & repeat('0',380) & '1'))
test_equal("value() subnormal number (scientific notation)", {GET_SUCCESS, 1e-310}, value("1e-310"))
test_equal("value() subnormal number (standard decimal notation)", {GET_SUCCESS, 1e-310}, value("0." & repeat('0',310) & '1'))

ifdef BITS32 then
	constant
		BIGGER = "1e380",
		RIDICULOUS = "1e200000",
		DECIMAL = 380,
		$
elsedef
	constant
		BIGGER = "1e5000",
		RIDICULOUS = "1e200000",
		DECIMAL = 5000,
		$
end ifdef

test_equal("value() bigger than maximum positive number (scientific notation)", {GET_SUCCESS, PINF}, value(BIGGER))
test_equal("value() bigger than maximum negative number (scientific notation)", {GET_SUCCESS, MINF}, value("-" & BIGGER))
test_equal("value() ridiculously bigger than maximum positive number (scientific notation)", {GET_SUCCESS, PINF}, value(RIDICULOUS))
test_equal("value() ridiculously bigger than maximum negative number (scientific notation)", {GET_SUCCESS, MINF}, value("-" & RIDICULOUS))


test_equal("value() bigger than maximum positive number (standard decimal notation)", {GET_SUCCESS, PINF}, value("1" & repeat('0', DECIMAL)))
-- The docs do not say that it supports non-decimal numbers.  So, don't test for that.  Don't try to read non-decimal numbers
-- in code you write using value() or get().
-- test_equal("value() bigger than maximum positive number (standard hexadecimal notation)", {GET_SUCCESS, PINF}, value("#1" & repeat('0', 315)))
-- test_equal("value() bigger than maximum positive number (standard octal notation)", {GET_SUCCESS, PINF}, value("0q1" & repeat('0', 420)))
-- test_equal("value() bigger than maximum positive number (standard binary notation)", {GET_SUCCESS, PINF}, value("0b1" & repeat('0', 1260)))



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

