--
-- sample data taken from:
-- http://json.org/example
--

include std/console.e
include std/error.e
include std/io.e
include std/json.e
include std/net/http.e
include std/net/url.e
include std/map.e
include std/sequence.e
include std/text.e
include std/types.e
include std/unittest.e

procedure test_json( sequence filename )

	sequence js1

	if match( "http://", filename ) = 1 then

		-- fetch content via HTTP
		object result = http_get( filename )
		if atom( result ) then
			error:crash( "http_get() error: %d", {result} )
		end if

		-- get the hostname from the URL
		sequence url = url:parse( filename )
		printf( 2, "testing %s:\n", {url[URL_HOSTNAME]} )

		-- check the HTTP status code
		if not equal( result[1][1][2], "200" ) then
			-- sometimes the service can be unavailable
			printf( 2, "%s\n", {stdseq:join(result[1][1][2..$],' ')} )
			return
		end if

		js1 = result[2]

	else

		printf( 2, "testing %s:\n", {filename} )
		js1 = read_file( filename )

	end if

	object tokens1 = json:parse( js1 )
	test_true( "parse() returns a sequence of tokens", sequence_array(tokens1) )

	object result1 = json:value( js1, tokens1 )
	test_true( "value() returns a sequence", sequence(result1) )
	test_true( "result[J_VALUE] is a map", map(result1[J_VALUE]) )
	test_equal( "result[J_TYPE] is JSON_OBJECT", result1[J_TYPE], JSON_OBJECT )

	sequence js2 = json:sprint( result1 )

	object tokens2 = json:parse( js2 )
	test_true( "parse() returns a sequence of tokens", sequence_array(tokens2) )

	object result2 = json:value( js2, tokens2 )
	test_true( "value() returns a sequence", sequence(result2) )
	test_true( "result[J_VALUE] is a map", map(result2[J_VALUE]) )
	test_equal( "result[J_TYPE] is JSON_OBJECT", result2[J_TYPE], JSON_OBJECT )

end procedure

-- Test to ensure json.e is parsed correctly
test_pass( "std/json.e parses correctly" )

-- Test various JSON files for compatability
test_json( "glossary.json" )
test_json( "menu1.json" )
test_json( "menu2.json" )
test_json( "web-app.json" )
test_json( "widget.json" )

-- Test unknown sources retrieved via HTTP
test_json( "http://ip.jsontest.com/ ")
test_json( "http://headers.jsontest.com/ ")
test_json( "http://date.jsontest.com/ ")
test_json( "http://echo.jsontest.com/key/hello/value/world ")
test_json( "http://validate.jsontest.com/?json=" &
	"%7B%22key%22%3A%22hello%22%7D%2C%22value%22%3A%22world%22 ")
test_json( "http://cookie.jsontest.com/ ")
test_json( "http://md5.jsontest.com/?text=jasmine_test" )

-- Test creating objects manually
printf( 2, "testing creating objects:\n" )

object key = json:new( JSON_STRING, "hello" )
test_equal( "key[J_TYPE] = JSON_STRING", key[J_TYPE], JSON_STRING )

object value = json:new( JSON_STRING, "world" )
test_equal( "value[J_TYPE] = JSON_STRING", value[J_TYPE], JSON_STRING )

object item = json:new( JSON_OBJECT, { {"key",key}, {"value", value} } )
test_equal( "item[J_TYPE] = JSON_OBJECT", item[J_TYPE], JSON_OBJECT )

object array = json:new( JSON_ARRAY, {
	json:new( JSON_OBJECT, { {"id","one"},   {"value",1} } ),
	json:new( JSON_OBJECT, { {"id","two"},   {"value",2} } ),
	json:new( JSON_OBJECT, { {"id","three"}, {"value",3} } ),
	json:new( JSON_OBJECT, { {"id","four"},  {"value",4} } ),
	json:new( JSON_OBJECT, { {"id","five"},  {"value",5} } )
} )
test_equal( "array[J_TYPE] = JSON_ARRAY", array[J_TYPE], JSON_ARRAY )
test_equal( "array[1][J_TYPE] = JSON_OBJECT", array[J_VALUE][1][J_TYPE], JSON_OBJECT )
test_equal( "array[2][J_TYPE] = JSON_OBJECT", array[J_VALUE][2][J_TYPE], JSON_OBJECT )
test_equal( "array[3][J_TYPE] = JSON_OBJECT", array[J_VALUE][3][J_TYPE], JSON_OBJECT )
test_equal( "array[4][J_TYPE] = JSON_OBJECT", array[J_VALUE][4][J_TYPE], JSON_OBJECT )
test_equal( "array[5][J_TYPE] = JSON_OBJECT", array[J_VALUE][5][J_TYPE], JSON_OBJECT )

object obj = json:new( JSON_OBJECT )
test_equal( "obj[J_TYPE] = JSON_OBJECT", obj[J_TYPE], JSON_OBJECT )

object true = json:new( JSON_PRIMITIVE, "true" )
test_equal( "true[J_TYPE] = JSON_PRIMITIVE", true[J_TYPE], JSON_PRIMITIVE )

object false = json:new( JSON_PRIMITIVE, "false" )
test_equal( "false[J_TYPE] = JSON_PRIMITIVE", false[J_TYPE], JSON_PRIMITIVE )

object null = json:new( JSON_PRIMITIVE, "null" )
test_equal( "null[J_TYPE] = JSON_PRIMITIVE", null[J_TYPE], JSON_PRIMITIVE )

object pi = json:new( JSON_PRIMITIVE, 3.1415926535 )
test_equal( "pi[J_TYPE] = JSON_PRIMITIVE", pi[J_TYPE], JSON_PRIMITIVE )

object e = json:new( JSON_PRIMITIVE, 2.7182818284 )
test_equal( "e[J_TYPE] = JSON_PRIMITIVE", e[J_TYPE], JSON_PRIMITIVE )

map:put( obj[J_VALUE], "array", array )
map:put( obj[J_VALUE], "item",  item )
map:put( obj[J_VALUE], "true",  true )
map:put( obj[J_VALUE], "false", false )
map:put( obj[J_VALUE], "null",  null )
map:put( obj[J_VALUE], "pi",    pi )
map:put( obj[J_VALUE], "e",     e )

sequence js3 = json:sprint( obj )

object tokens3 = json:parse( js3 )
test_true( "parse() returns a sequence of tokens", sequence_array(tokens3) )

object result3 = json:value( js3, tokens3 )
test_true( "value() returns a sequence", sequence(result3) )
test_true( "result[J_VALUE] is a map", map(result3[J_VALUE]) )
test_equal( "result[J_TYPE] is JSON_OBJECT", result3[J_TYPE], JSON_OBJECT )

test_report()
