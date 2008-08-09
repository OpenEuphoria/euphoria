include std/search.e
include std/unittest.e
test_equal("rmatch() #5", 0, rmatch("ABC", "ABCDABCABC", -50))
test_report()




