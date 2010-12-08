include std/utils.e
include std/unittest.e

test_equal("iif() false", 9, iif(0,4,9))
test_equal("iif() true",  4, iif(1,4,9))

test_equal("deprecated iff() false", 9, iff(0,4,9))
test_equal("deprecated iff() true",  4, iff(1,4,9))

test_report()

