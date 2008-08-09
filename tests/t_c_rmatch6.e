include std/search.e
include std/unittest.e
test_equal("rmatch() #6", 0, rmatch("ABC", "EEEDDDABC", 50))
test_report()




