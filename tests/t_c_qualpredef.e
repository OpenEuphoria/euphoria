namespace fail
include std/unittest.e

fail:puts(1, 1)

test_fail("resolved file-qualified procedure to predefined routine")
test_report()
