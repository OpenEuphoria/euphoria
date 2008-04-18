include wildcard.e
include unittest.e

setTestModuleName("wildcard.e")

testEqual("lower() letters only", "john", lower("JoHN"))
testEqual("lower() mixed text", "john 55 &%.", lower("JoHN 55 &%."))
testEqual("upper() letters only", "JOHN", upper("joHn"))
testEqual("upper() mixed text", "JOHN 50 &%.", upper("joHn 50 &%."))

testEqual("wildcard_match()", 1, wildcard_match("A?B*", "AQBXXYY"))
testEqual("wildcard_match()", 0, wildcard_match("A?BZ*", "AQBXXYY"))
testEqual("wildcard_match()", 0, wildcard_match("A*B*C", "a111b222c"))

-- TODO: test the case sensitivity based on platform
testEqual("wildcard_file()", 1, wildcard_file("AB*CD.?", "AB123CD.e"))
testEqual("wildcard_file()", 0, wildcard_file("AB*CD.?", "abcd.ex"))
