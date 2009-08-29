include std/unittest.e
include std/net/url.e

test_equal("encode 1", "Hello+%26+World", url:encode("Hello & World"))
test_equal("encode 2", "Hello%20%26%20World", url:encode("Hello & World", "%20"))

test_equal("decode #1", "Hello & World", url:decode("Hello+%26+World"))
test_equal("decode #2", "Hello & World", url:decode("Hello%20%26%20World"))

test_report()
