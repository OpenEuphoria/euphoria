include std/search.e
include std/unittest.e

test_equal("rmatch() #7", 0, rmatch("", "EEEDDDABC"))

test_report()
