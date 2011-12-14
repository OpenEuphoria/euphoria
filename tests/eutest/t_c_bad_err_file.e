include std/unittest.e

integer i1
i1 = match("", "Hello World")

test_fail("match with "" should fail the program.")
test_report()
