include std/unittest.e
include std/net/http.e
include std/search.e
include std/math.e
include std/os.e

ifdef not NOINET_TESTS then
	sequence content = get_url("http://example.com")
	test_true("get_url 1", length(content))
	test_true("get_url 2", match("HTTP/", "" & content[1]) = 1)
	test_true("get_url 3", match("<TITLE>Example Web Page</TITLE>", "" & content[2]))

	content = get_url("http://example.com:80/")
	test_true("get_url 4", length(content))
	test_true("get_url 5", match("HTTP/", "" & content[1]) = 1)
	test_true("get_url 6", match("<TITLE>Example Web Page</TITLE>", "" & content[2]))

    sequence data = sprintf("%d", { rand_range(1000,10000) })

    content = get_url("http://openeuphoria.org/tests/post_test.cgi", "data=" & data)
	if length(content)>1 and sequence(content[2]) and
		match("oe.cowgar.com", content[2]) then
		-- main EUPHORIA site still down
		-- let's not report misleading results.
		test_report()
		abort(0)
	end if
	test_true("get_url post 1", length(content))
	test_equal("get_url post 2", "success", content[2])
	
	set_sendheader("Cache-Control", "no-cache" )
    content = get_url("http://openeuphoria.org/tests/post_test.txt")
	test_true("get_url post 3", length(content))
	test_equal("get_url post 4", data, content[2])
	
elsedef
    puts(2, " WARNING: URL tests were not run\n")
end ifdef

test_report()
