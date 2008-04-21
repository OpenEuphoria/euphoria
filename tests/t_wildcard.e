include wildcard.e
include unittest.e

set_test_module_name("wildcard.e")

test_equal("lower() letters only", "john", lower("JoHN"))
test_equal("lower() mixed text", "john 55 &%.", lower("JoHN 55 &%."))
test_equal("upper() letters only", "JOHN", upper("joHn"))
test_equal("upper() mixed text", "JOHN 50 &%.", upper("joHn 50 &%."))

test_equal("wildcard_match()", 1, wildcard_match("A?B*", "AQBXXYY"))
test_equal("wildcard_match()", 0, wildcard_match("A?BZ*", "AQBXXYY"))
test_equal("wildcard_match()", 0, wildcard_match("A*B*C", "a111b222c"))

-- TODO: test the case sensitivity based on platform
test_equal("wildcard_file()", 1, wildcard_file("AB*CD.?", "AB123CD.e"))
test_equal("wildcard_file()", 0, wildcard_file("AB*CD.?", "abcd.ex"))
