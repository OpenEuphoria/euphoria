include std/utils.e
include std/unittest.e

test_equal("iff() false", 9, iff(0,4,9))
test_equal("iff() true",  4, iff(1,4,9))

test_report()

