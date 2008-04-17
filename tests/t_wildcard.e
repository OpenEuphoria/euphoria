include wildcard.e
include unittest.e

setTestModuleName("wildcard.e")

testEqual("lower()", "john", lower("JoHN"))
testEqual("upper()", "JOHN", upper("joHn"))

testEqual("wildcard_match()", 1, wildcard_match("A?B*", "AQBXXYY"))
testEqual("wildcard_match()", 0, wildcard_match("A?BZ*", "AQBXXYY"))
testEqual("wildcard_match()", 0, wildcard_match("A*B*C", "a111b222c"))

-- TODO: test the case sensitivity based on platform
testEqual("wildcard_file()", 1, wildcard_file("AB*CD.?", "AB123CD.e"))
testEqual("wildcard_file()", 0, wildcard_file("AB*CD.?", "abcd.ex"))
