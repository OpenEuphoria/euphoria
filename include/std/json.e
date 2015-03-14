--****
-- == JSON Parser
--
-- <<LEVELTOC level=2 depth=4>>
--
-- === Introduction
--
-- JSON parsing in Euphoria is based on [[JSMN -> http://zserge.com/jsmn.html]] (pronounced like
-- 'jasmine') library by Serge, which is a minimalistic JSON parser in C. According to the author,
-- "It can be easily integrated into the resource-limited projects or embedded systems."
--
-- === About JSON
--
-- [[JSON -> http://json.org/]] (**JavaScript Object Notation**) is a lightweight data-interchange
-- format. It is easy for humans to read and write. It is easy for machines to parse and generate.
-- It is based on a subset of the [[JavaScript Programming Language -> http://javascript.crockford.com/]]
-- [[Standard ECMA-262 3rd Edition - December 1999 -> http://www.ecma-international.org/publications/files/ecma-st/ECMA-262.pdf]].
-- JSON is a text format that is completely language independent but uses conventions that are
-- familiar to programmers of the C-family of languages, including C, C++, C#, Java, JavaScript,
-- Perl, Python, and many others. These properties make JSON an ideal data-interchange language.
--
-- JSON is built on two structures:
--
-- * A collection of name/value pairs. In various languages, this is realized as an //object//,
--   record, struct, dictionary, hash table, keyed list, or associative array (a.k.a. //map//).
-- * An ordered list of values. In most languages, this is realized as an array, vector, list,
--   or //sequence//.
--
-- These are universal data structures. Virtually all modern programming languages support them in
-- one form or another. It makes sense that a data format that is interchangeable with programming
-- languages also be based on these structures.
--

namespace json

include std/get.e
include std/io.e
include std/map.e
include std/text.e
include std/types.e
include std/utils.e
with trace

enum
	M_JSON_PARSE = 106,
$

--****
-- === JSON Error Constants
--

--**
-- An integer representing a JSON error.
--
public constant
	--** Not enough memory was available.
	JSON_ERROR_LOW_MEMORY = (-1),
	--** Invalid character inside JSON string.
	JSON_ERROR_INVALID    = (-2),
	--** The string is not a full JSON packet, more data expected.
	JSON_ERROR_PARTIAL    = (-3),
	--** Not enough tokens were provided to parse the JSON string.
	JSON_ERROR_NOT_ENOUGH = (-4),
$

--****
-- === JSON Type Constants
--

--**
-- An integer representing a JSON type.
--
public constant
	--** An **object** is an unordered set of name/value pairs (specifically, a //map//). An object
	-- begins with ##{## (left brace) and ends with ##}## (right brace). Each name is followed by
	-- ##:## (colon) and the name/value pairs are separated by ##,## (comma).
	JSON_OBJECT    = 1,
	--** An **array** is an ordered collection of //values//. An array begins with ##[## (left
	-- bracket) and ends with ##]## (right bracket). Values are separated by ##,## (comma).
	JSON_ARRAY     = 2,
	--** A **string** is a sequence of zero or more Unicode characters, wrapped in double quotes,
	-- using backslash escapes, very much like a C or Euphoria string.
	JSON_STRING    = 3,
	--** A **primitive** can be a //number//, or ##true## or ##false## or ##null##.
	JSON_PRIMITIVE = 0,
$

--****
-- === JSON Token Constants
--
public constant
	--** The type of JSON value in this token (see [[Value Types]]).
	J_TYPE   = 1,
	--** The start position of the token in the string.
	J_START  = 2,
	--** The end position of the token in the string.
	J_END    = 3,
	--** The number of sub-tokens contained in this one.
	J_SIZE   = 4,
	--** The index of this token's parent token.
	J_PARENT = 5,
$

--****
-- === JSON Object Constants
--

--**
-- Signature:
-- constant J_TYPE = 1
--
-- Description:
-- The JSON type of this object (see [[Value Types]]).
--

public constant
	--** The actual value of this object.
	J_VALUE = 2,
	--** The number of tokens processed by [[:value]].
	J_COUNT = 3,
$

--****
-- === Return Types
--

--**
-- Parses a raw JSON string into a sequence of tokens.
--
-- Parameters:
--   # ##js## : a string containing raw JSON data
--
-- Returns:
--   A sequence of objects contains five elements:
--   * **J_TYPE** - the type of token found (see [[Value Types]])
--   * **J_START** - the start position of the token
--   * **J_END** - the end position of the token
--   * **J_SIZE** - the number of tokens contained in this token
--   * **J_PARENT** - index of this token's parent
--
-- Comments:
--   The tokens returned should be passed to [[:value]] to retrieve a usable Euphoria object.
--
-- Example 1:
-- <eucode>
-- include std/console.e
-- include std/json.e
--
-- sequence js = `{"key": "hello", "value": "world"}`
--
-- object tokens = json:parse( js )
-- if atom( tokens ) then
--     -- token is an error number
-- end if
--
-- for i = 1 to length( tokens ) do
--
--     sequence t = tokens[i]
--
--     integer j_type   = t[J_TYPE]
--     integer j_start  = t[J_START]
--     integer j_end    = t[J_END]
--     integer j_size   = t[J_SIZE]
--     integer j_parent = t[J_PARENT]
--     sequence j_value = js[j_start..j_end]
--
--     display( "token [1]", {i} )
--     display( "  j_type   = [1]", {j_type} )
--     display( "  j_start  = [1]", {j_start} )
--     display( "  j_end    = [1]", {j_end} )
--     display( "  j_size   = [1]", {j_size} )
--     display( "  j_parent = [1]", {j_parent} )
--     display( "  j_value  = [1]", {j_value} )
--
-- end for
-- </eucode>
-- Output~:
-- {{{
-- token 1
--   j_type   = 1
--   j_start  = 1
--   j_end    = 34
--   j_size   = 2
--   j_parent = 0
--   j_value  = {"key": "hello", "value": "world"}
-- token 2
--   j_type   = 3
--   j_start  = 3
--   j_end    = 5
--   j_size   = 1
--   j_parent = 1
--   j_value  = key
-- ...
-- }}}
--
-- See Also:
--   [[:value]]
--
public function parse( string js )
	return machine_func( M_JSON_PARSE, text:trim(js) )
end function

--**
-- Parse a sequence of JSON tokens into a Euphoria object.
--
-- Parameters:
--   # ##js## : a string containing raw JSON data
--   # ##tokens## : a sequence of tokens returned by [[:parse]]
--   # ##start## : the position in //tokens// to start parsing
--
-- Returns:
--   An object containing three elements:
--   * **J_TYPE** - the type of object (see [[Value Types]])
--   * **J_VALUE** - the actual value parsed from the tokens
--   * **J_COUNT** - the number of tokens parsed to get this value
--
-- Comments:
--   If ##tokens## is an empty sequence, ##js## will be passed through [[:parse]] automatically.
--
-- Example 1:
-- <eucode>
-- include std/console.e
-- include std/json.e
-- include std/map.e
--
-- object result = json:value( `{"key": "hello", "value": "world"}` )
-- if atom( result ) then
--     -- result is an error number
-- end if
--
-- map m = result[J_VALUE]
--
-- object key   = map:get( m, "key" )
-- object value = map:get( m, "value" )
--
-- display( `key = "[1]", value = "[2]"`,
--     {key[J_VALUE],value[J_VALUE]} )
-- </eucode>
-- Output~:
-- {{{
-- key = "hello", value = "world"
-- }}}
--
-- See Also:
--   [[:parse]]
--
public function value( string js, sequence tokens = {}, integer start = 1 )

	if length( tokens ) = 0 then

		-- parse string for tokens
		object temp = json:parse( js )

		if atom( temp ) then
			-- return the error
			return temp
		end if

		tokens = temp

	end if

	if length( tokens ) < start then
		-- not enough tokens provided
		return JSON_ERROR_NOT_ENOUGH
	end if

	sequence t = tokens[start]

    switch t[J_TYPE] do

        case JSON_PRIMITIVE then
            -- a JSON primitive is a numeric value or
			-- literal value (i.e. true/false/null)

            -- get the string offsets
            integer j_start = t[J_START]
            integer j_end   = t[J_END]

            -- get the string value
            object p = js[j_start..j_end]

			-- is this a literal value?
            if not find( p, {"true","false","null"} ) then
				-- no, convert it to a number
                sequence val = stdget:value( p )
                p = val[2]
            end if

            return {JSON_PRIMITIVE,p,1}

        case JSON_OBJECT then
            -- a JSON object is a key/object map
            map m = map:new()

            integer i = start + 1
            for n = 1 to t[J_SIZE] do

                -- get the key and update the offset
                object key = json:value( js, tokens, i )
				if atom( key ) then
					-- error
					return key
				end if
                i += key[J_COUNT]

                -- get the object and update the offset
                object obj = json:value( js, tokens, i )
				if atom( obj ) then
					-- error
					return obj
				end if
                i += obj[J_COUNT]

                -- store the key/object pair in the map
                map:put( m, key[2], obj )

                if i > length( tokens ) then
                    -- no more tokens here
                    exit
                end if

            end for

            return {JSON_OBJECT,m,i-start}

        case JSON_ARRAY then
            -- a JSON array is a sequence of object
            sequence s = repeat( 0, t[J_SIZE] )

            integer i = start + 1
            for n = 1 to t[J_SIZE] do

                -- get the value and update the offset
                object val = json:value( js, tokens, i )
				if atom( val ) then
					-- error
					return val
				end if
				i += val[J_COUNT]

                -- add the item to the array
                s[n] = val

                if i > length( tokens ) then
                    -- no more tokens here
					s = s[1..n]
                    exit
                end if

            end for

            return {JSON_ARRAY,s,i-start}

        case JSON_STRING then
            -- a JSON string is just a literal string

            -- get the string offsets
            integer j_start = t[J_START]
            integer j_end   = t[J_END]

            -- get the string value
            sequence s = js[j_start..j_end]

            return {JSON_STRING,s,1}

	end switch

	return 0
end function

type json_value( object x )

	if not sequence( x ) then
		return 0
	end if

	if not length( x ) = 3 then
		return 0
	end if

	if not find( x[1], {JSON_OBJECT,JSON_ARRAY,
			JSON_STRING,JSON_PRIMITIVE} ) then
		return 0
	end if

	return 1
end type

function json_object( object x )
	return map( x )
end function

function json_array( object x )
	return sequence( x )
end function

function json_string( object x )
	return string( x )
end function

function json_primitive( object x )
	return atom( x ) or find( x, {"true","false","null"} )
end function

--**
-- Create a new JSON object.
--
-- Parameters:
--   # ##j_type## : the type of JSON object (see [[Value Types]])
--   # ##j_value## : the intial value for the object
--
-- Returns:
--   An object containing three elements:
--   * **J_TYPE** - the type of object (see [[Value Types]])
--   * **J_VALUE** - the actual value parsed from the tokens
--   * **J_COUNT** - the number of tokens parsed to get this value
--
-- Comments:
--   * This funciton will return 0 if the object is not valid.
--   * Raw values will be passed through [[:new]] to create a JSON object automatically.
--
-- Example 1:
-- <eucode>
-- -- a JSON_OBJECT is a map of key/value pairs
-- object test = json:new(JSON_OBJECT, {
--     -- a JSON_OBJECT is a map of key/value pairs
--     -- values get converted to JSON_STRING automatically
--     {"key", "hello"},
--     {"value", "world"}
-- })
-- 
-- json:write(1, test)
-- </eucode>
-- Output~:
-- {{{
-- {
--     "key": "hello",
--     "value": "world"
-- }
-- }}}
--
-- Example 2:
-- <eucode>
-- object test = json:new(JSON_OBJECT, {
--     -- a JSON_OBJECT is a map of key/value pairs
--     {"array", json:new(JSON_ARRAY, {
--         -- JSON_ARRAY is a sequence of values, which can be nested JSON_OBJECTs
--         json:new( JSON_OBJECT, { {"name","one"}, {"value",1} } ),
--         json:new( JSON_OBJECT, { {"name","two"}, {"value",2} } ),
--         json:new( JSON_OBJECT, { {"name","three"}, {"value",3} } ),
--         json:new( JSON_OBJECT, { {"name","four"}, {"value",4} } ),
--         json:new( JSON_OBJECT, { {"name","five"}, {"value",5} } )
--     })}
-- })
-- 
-- json:write(1, test)
-- </eucode>
-- Output~:
-- {{{
-- {
--     "array": [
--         {
--             "value": 1,
--             "name": "one"
--         },
--         {
--             "value": 2,
--             "name": "two"
--         },
--         {
--             "value": 3,
--             "name": "three"
--         },
--         {
--             "value": 4,
--             "name": "four"
--         },
--         {
--             "value": 5,
--             "name": "five"
--         }
--     ]
-- }
-- }}}
--
public function new( integer j_type, object j_value = 0 )

	switch j_type do

		case JSON_OBJECT then

			if equal( j_value, 0 ) then
				-- default value
				j_value = map:new()

			elsif sequence_array( j_value ) then

				-- create a new map of key/value pairs
				/* j_value = map:new_from_kvpairs( j_value ) */

				-- N.B. need to process kvpairs manually to verify contents

				map m = map:new()

				for i = 1 to length( j_value ) do

					if length( j_value[i] ) != 2 then
						-- not a key/value pair
						return 0

					elsif not string( j_value[i][1] ) then
						-- key is not a string
						return 0

					end if

					-- convert raw values into json values
					if not json_value( j_value[i][2] ) then

						integer item_type = JSON_PRIMITIVE
						if json_string( j_value[i][2] ) and not json_primitive( j_value[i][2] ) then
							item_type = JSON_STRING
						end if

						j_value[i][2] = json:new( item_type, j_value[i][2] )

					end if

					map:put( m, j_value[i][1], j_value[i][2] )

				end for

				j_value = m

			end if

			if not json_object( j_value ) then
				-- invalid type
				return 0
			end if

		case JSON_ARRAY then

			if atom( j_value ) then
				-- default value
				j_value = {}
			end if

			for i = 1 to length( j_value ) do

				-- convert raw values into json values
				if not json_value( j_value[i] ) then

					integer item_type = JSON_PRIMITIVE
					if json_string( j_value[i] ) and not json_primitive( j_value[i] ) then
						item_type = JSON_STRING
					end if

					j_value[i] = json:new( item_type, j_value[i] )

				end if

			end for

			if not json_array( j_value ) then
				-- invalid type
				return 0
			end if

		case JSON_STRING then

			if equal( j_value, 0 ) then
				-- default value
				j_value = ""

			elsif not json_string( j_value ) then
				-- invalid type
				return 0

			end if

		case JSON_PRIMITIVE then

			if not json_primitive( j_value ) then
				-- invalid ype
				return 0
			end if

	end switch

	return {j_type,j_value,0}
end function


--**
-- Print a JSON object to a string.
--
-- Parameters:
--   # ##obj## : the JSON object to output
--   # ##white_space## : TRUE to output white space formatting (spaces and new lines)
--   # ##tab_width## : the number of spaces to use for each indent
--   # ##column## : the column to start at when formatting
--
-- Returns:
--   A string containing raw JSON data.
--
-- Example 1:
-- <eucode>
-- include std/console.e
-- include std/json.e
--
-- object result = json:value( `{"key": "hello", "value": "world"}` )
-- if atom( result ) then
--     -- result is an error number
-- end if
--
-- sequence js = json:sprint( result )
-- display( js )
-- </eucode>
-- Output~:
-- {{{
-- {
--     "key": "hello",
--     "value": "world"
-- }
-- }}}
--
-- See Also:
--   [[:write]]
--
public function sprint( sequence obj, integer white_space = 1, integer tab_width = 4, integer column = 0 )

	sequence pad1, pad2, eol

	if white_space then
		pad1 = repeat( ' ', (column+0) * tab_width )
		pad2 = repeat( ' ', (column+1) * tab_width )
		eol = "\n"
	else
		pad1 = ""
		pad2 = ""
		eol = ""
	end if

	sequence buffer = ""

	switch obj[J_TYPE] do

		case JSON_PRIMITIVE then
			-- obj[J_VALUE] is a numeric value or
            -- literal value (i.e. true/false/null)

			-- convert atoms to strings
			if atom( obj[J_VALUE] ) then
				obj[J_VALUE] = text:sprint( obj[J_VALUE] )
			end if

			-- print the value
			buffer &= sprintf( "%s", {obj[J_VALUE]} )

		case JSON_OBJECT then
			-- obj[J_VALUE] is a key/object map

			-- get the object keys
			sequence keys = map:keys( obj[J_VALUE] )

			-- print the start character
			buffer &= "{" & eol

			-- loop through the keys
			for i = 1 to length( keys ) do

				-- print the padding and key name
				buffer &= pad2 & sprintf( `"%s": `, {keys[i]} )

				-- print the key object
				buffer &= json:sprint( map:get(obj[J_VALUE], keys[i]), white_space, tab_width, column+1 )

				-- print a comma and/or new line
				buffer &= iff(i < length(keys), ",", "") & eol

			end for

			-- print padding the end character
			buffer &= pad1 & "}"

		case JSON_ARRAY then
			-- obj[J_VALUE] is a sequence of objects

			-- get the array items
			sequence items = obj[J_VALUE]

			-- print the start character
			buffer &= "[" & eol

			-- loop through the items
			for i = 1 to length( items ) do

				-- print the padding
				buffer &= pad2

				-- print the item value
				buffer &= json:sprint( items[i], white_space, tab_width, column+1 )

				-- print a comma and/or new line
				buffer &= iff(i < length(items), ",", "") & eol

			end for

			-- print the padding and end character
			buffer &= pad1 & "]"

		case JSON_STRING then
			-- obj[J_VALUE] is a literal string

			-- print the string
			buffer &= sprintf( `"%s"`, {obj[J_VALUE]} )

	end switch

	return buffer
end function

--**
-- Print a JSON object to a file.
--
-- Parameters:
--   # ##fn## : a file name or open file number
--   # ##obj## : the JSON object to output
--   # ##white_space## : output white space formatting (spaces and new lines)
--   # ##tab_width## : the number of spaces to use for each indent
--   # ##column## : the column to start at when formatting
--
-- See Also:
--   [[:print]]
--
public procedure write( object fn, sequence obj, integer white_space = 1, integer tab_width = 4, integer column = 0 )

	if sequence( fn ) then
		-- open the file for writing
		fn = open( fn, "w", 1 )
	end if

	sequence pad1, pad2, eol

	if white_space then
		pad1 = repeat( ' ', (column+0) * tab_width )
		pad2 = repeat( ' ', (column+1) * tab_width )
		eol = "\n"
	else
		pad1 = ""
		pad2 = ""
		eol = ""
	end if

	switch obj[J_TYPE] do

		case JSON_PRIMITIVE then
			-- obj[J_VALUE] is a numeric value or
            -- literal value (i.e. true/false/null)

			-- convert atoms to strings
			if atom( obj[J_VALUE] ) then
				obj[J_VALUE] = text:sprint( obj[J_VALUE] )
			end if

			-- print the value
			printf( fn, "%s", {obj[J_VALUE]} )

		case JSON_OBJECT then
			-- obj[J_VALUE] is a key/object map

			-- get the object keys
			sequence keys = map:keys( obj[J_VALUE] )

			-- print the start character
			printf( fn, "{" & eol )

			-- loop through the keys
			for i = 1 to length( keys ) do

				-- print the padding and key name
				printf( fn, pad2 & `"%s": `, {keys[i]} )

				-- print the key object
				json:write( fn, map:get(obj[J_VALUE], keys[i]), white_space, tab_width, column+1 )

				-- print a comma and/or new line
				printf( fn, iff(i < length(keys), ",", "") & eol )

			end for

			-- print the end character
			printf( fn, pad1 & "}" )

		case JSON_ARRAY then
			-- obj[J_VALUE] is a sequence of objects

			-- get the array items
			sequence items = obj[J_VALUE]

			-- print the start character
			printf( fn, "[" & eol )

			-- loop through the items
			for i = 1 to length( items ) do

				-- print the padding
				printf( fn, pad2 )

				-- print the item value
				json:write( fn, items[i], white_space, tab_width, column+1 )

				-- print a comma and/or new line
				printf( fn, iff(i < length(items), ",", "") & eol )

			end for

			-- print the padding and end character
			printf( fn, pad1 & "]" )

		case JSON_STRING then
			-- obj[J_VALUE] is a literal string

			-- print the string
			printf( fn, `"%s"`, {obj[J_VALUE]} )

	end switch

end procedure

