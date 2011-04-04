include std/wildcard.e
include std/unittest.e

test_equal("is_match()", 1, is_match("A?B*", "AQBXXYY"))
test_equal("is_match()", 0, is_match("A?BZ*", "AQBXXYY"))
test_equal("is_match()", 0, is_match("A*B*C", "a111b222c"))
test_equal("is_match()", 1, is_match("HelloWorld*", "HelloWorld"))
test_report()
