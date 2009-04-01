include std/unittest.e

ifdef NON_FUNCTIONAL_TESTS then

include std/net/http.e
include std/search.e
include std/math.e

-- TODO: Test HTTP stuff

test_equal("urlencode 1", "Hello+%26+World", urlencode("Hello & World"))
test_equal("urlencode 2", "Hello%20%26%20World", urlencode("Hello & World", "%20"))

ifdef URL_TESTS then
	sequence content = get_url("http://google.com")
	test_true("get_url 1", length(content))
	test_true("get_url 2", match("google.com", content[1]))
	test_true("get_url 3", match("google.com", content[2]))

    sequence data = sprintf("%d", { rand_range(1000,10000) })

    set_sendheader_useragent_msie()
    set_sendheader("POSTDATA","data=" & data)
    content = get_url("http://openeuphoria.org/tests/post_test.cgi")
	test_true("get_url post 1", length(content))
	test_equal("get_url post 2", "success", content[2])

    content = get_url("http://openeuphoria.org/tests/post_test.txt")
	test_true("get_url post 3", length(content))
	test_equal("get_url post 4", data, content[2])
elsedef
    puts(2, " WARNING: URL tests were not run, use -D URL_TESTS for full test\n")
end ifdef

end ifdef

test_report()
