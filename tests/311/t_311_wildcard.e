include std/unittest.e

include wildcard.e

test_equal("lower() zero", 0, lower(0))
test_equal("lower() atom", 'a', lower('A'))
test_equal("lower() letters only", "john", lower("JoHN"))
test_equal("lower() mixed text", "john 55 &%.", lower("JoHN 55 &%."))
test_equal("lower() with \\0", "abc\0def", lower("abc" & 0 & "DEF"))
test_equal("lower() nested", {'a', "bcd", 'e', "fg"}, lower({'A', "BcD", 'e', "fG"}))

test_equal("upper() atom", 'A', upper('a'))
test_equal("upper() letters only", "JOHN", upper("joHn"))
test_equal("upper() mixed text", "JOHN 50 &%.", upper("joHn 50 &%."))
test_equal("upper() with \\0", "ABC\0DEF", upper("abc" & 0 & "DEF"))

test_equal("wildcard_file()", 1, wildcard_file("AB*CD.?", "AB123CD.e"))
test_equal("wildcard_file()", 0, wildcard_file("AB*CD.?", "abcd.ex"))


test_report()
