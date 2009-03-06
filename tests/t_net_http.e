include std/unittest.e
include std/net/http.e
include std/search.e

object _ = 0

-- TODO: Test HTTP stuff

test_equal("urlencode 1", "Hello%20%26%20World", urlencode("Hello & World"))

ifdef SOCKET_TESTS then
	sequence google_content = get_url("http://google.com")
	test_true("get_url 1", length(google_content))
	test_true("get_url 2", match("google.com", google_content[1]))
	test_true("get_url 3", match("google.com", google_content[2]))
end ifdef

test_report()
