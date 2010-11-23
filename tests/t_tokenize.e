include std/unittest.e

include euphoria/tokenize.e

sequence tokens

tokens = tokenize_string("abc+=10")

test_equal("tok_parse id #1",   T_IDENTIFIER, tokens[1][1][TTYPE])
test_equal("tok_parse +=",      T_PLUSEQ,     tokens[1][2][TTYPE])
test_equal("tok_parse integer", T_NUMBER,     tokens[1][3][TTYPE])

tokens = tokenize_string(`abc = "John"`)
test_equal("tok_parse id #2", T_IDENTIFIER, tokens[1][1][TTYPE])
test_equal("tok_parse =",     T_EQ,         tokens[1][2][TTYPE])
test_equal("tok_parse str",   T_STRING,     tokens[1][3][TTYPE])
test_equal("tok_parse str val", "John",     tokens[1][3][TDATA])

-- ticket:429
tokens = tokenize_string("puts(1, `hello`)")
test_equal("tok_parse `hello` (#429)", "hello", tokens[1][5][TDATA])

-- ticket:430
tokens = tokenize_string("`\\n\nHello`")
test_equal("tok_parse `\\nHello` (#430)", "\\n\nHello", tokens[1][1][TDATA])

-- ticket:431
tokenize:keep_newlines()
tokens = tokenize_string("abc=`\\x44Hello`\n? abc")
test_equal("tok_parse (#431) #1", 7, length(tokens[1]))
test_equal("tok_parse (#431) #2", `\x44Hello`, tokens[1][3][TDATA])
test_equal("tok_parse (#431) #3", T_QPRINT, tokens[1][5][TTYPE])

-- ticket:434
tokenize:string_numbers()
tokens = tokenize_string("integer a = #00A, b = 003")
test_equal("tok_parse (#434) #1", "#00A", tokens[1][4][TDATA])
test_equal("tok_parse (#434) #2", "003", tokens[1][8][TDATA])

-- ticket:435
tokenize:string_numbers()
tokens = tokenize_string("0b010, 0t017, 0d019, 0x01F")
test_equal("tok_parse (#435) #1", "0b010", tokens[1][1][TDATA])
test_equal("tok_parse (#435) #2", "0t017", tokens[1][3][TDATA])
test_equal("tok_parse (#435) #3", "0d019", tokens[1][5][TDATA])
test_equal("tok_parse (#435) #4", "0x01F", tokens[1][7][TDATA])


test_report()

