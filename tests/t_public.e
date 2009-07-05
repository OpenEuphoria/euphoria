include z.e -- FOO_BAR is indirectly included here.
include std/unittest.e

test_equal("Foo bar exists", FOO_BAR, FOO_BAR)

test_report()
