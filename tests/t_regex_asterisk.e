include std/types.e
include std/regex.e as regex
include std/unittest.e

cstring argument_name = regex:find_replace(regex:new("\\*"), "*", "")
test_pass("Can find replace a asterisk from a asterisk")
test_report()