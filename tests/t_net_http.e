include std/unittest.e
include std/net/http.e
include std/search.e
include std/math.e
include std/os.e

ifdef not NOINET_TESTS then
	object content

	content = http_get("http://www.iana.org/")
	assert("http_get content readable with http_get slash only path", length(content) > 1)
	test_not_equal("http_get content non-empty with http_get slash only path", length(content[2]), 0)

	content = http_get("http://www.iana.org")
	assert("content readable http_get no path", length(content) > 1)
	test_not_equal("content non-empty with http_get no path", length(content[2]), 0)

	content = http_get("http://www.iana.org/domains/example/")
	if atom(content) then
		test_fail("content readable from http_get with a path")
	else
		assert("content readable from http_get with a path", length(content) = 2)
		test_true("content correct form from http_get with a path", match("<title>", "" & content[2]))
	end if

	content = http_get("http://www.iana.org:80/domains/example/")
	if atom(content) then
		test_fail("content readable from http_get with port and path")
	else
		assert("content readable from http_get with port and path", length(content)=2)
		test_true("content correct from http_get with port and path", match("<title>", "" & content[2]))
	end if

	-- Test nested sequence post data
    sequence num = sprintf("%d", { rand_range(1000,10000) })
	sequence data = {
		{ "data", num }
	}
    content = http_post("http://test.openeuphoria.org/post_test.ex", data)
	if atom(content) or length(content) < 2 then
		test_fail("http_post post #1")
	else
		test_equal("http_post post #1", "success", content[2])
	end if

	sequence headers = {
		{ "Cache-Control", "no-cache" }
	}
    content = http_get("http://test.openeuphoria.org/post_test.txt", headers)
	if atom(content) or length(content) < 2 then
		test_true("http_get with headers #2", sequence(content))
		test_fail("http_get with headers #3")
		test_fail("http_get with headers #4")
		test_fail("http_get with headers #5")
		test_fail("http_get with headers #6")
		test_fail("http_get with headers #7")
		test_fail("http_get with headers #8")
	else
		test_pass("http_get with headers #2")
		assert("http_get with headers #3", length(content) = 2)
		test_equal("http_get with headers #4", "data=" & num, content[2])

		-- Test already encoded string
		num = sprintf("%d", { rand_range(1000,10000) })
		data = sprintf("data=%s", { num })
		content = http_post("http://test.openeuphoria.org/post_test.ex", data)
		assert("http_get with headers #5", length(content) = 2)
		test_equal("http_get with headers #6", "success", content[2])

		content = http_get("http://test.openeuphoria.org/post_test.txt", headers)
		assert("http_get with headers #7", length(content) = 2)
		test_equal("http_get with headers #8", "data=" & num, content[2])
	end if

	-- multipart form data
	sequence file_content = "Hello, World. This is an icon. I hope that this really works. I am not really sure but we will see"
	data = {
		{ "size", sprintf("%d", length(file_content)) },
		{ "file",  file_content, "example.txt", "text/plain", ENCODE_BASE64 }
	}

	-- post file script gets size and file parameters, calls decode_base64, and sends
	-- back SIZE\nDECODED_FILE_CONTENTS. The test script is written in Perl to test against
	-- modules we did not code, i.e. CGI and Base64 in this case.
	content = http_post("http://test.openeuphoria.org/post_file.cgi", { MULTIPART_FORM_DATA, data })
	if atom(content) or length(content) < 2 then
		test_fail("multipart form file upload")
	else
		test_equal("multipart form file upload", data[1][2] & "\n" & file_content, content[2])
	end if
elsedef
    puts(2, " WARNING: URL tests were not run\n")
end ifdef

test_report()
