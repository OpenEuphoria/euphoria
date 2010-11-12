include std/unittest.e
include std/net/http.e
include std/search.e
include std/math.e
include std/os.e

ifdef not NOINET_TESTS then
	sequence content

	content = http_get("http://example.com")
	test_true("get_url 1", length(content) = 2)
	test_true("get_url 2", match("<TITLE>Example Web Page</TITLE>", "" & content[2]))

	content = http_get("http://example.com:80/")
	test_true("get_url 3", length(content) = 2)
	test_true("get_url 4", match("<TITLE>Example Web Page</TITLE>", "" & content[2]))

    sequence num = sprintf("%d", { rand_range(1000,10000) })
	sequence data = {
		{ "data", num }
	}
    content = http_post("http://test.openeuphoria.org/post_test.ex", data)
	test_true("get_url post 1", length(content))
	test_equal("get_url post 2", "success", content[2])

	sequence headers = {
		{ "Cache-Control", "no-cache" }
	}
    content = http_get("http://test.openeuphoria.org/post_test.txt", headers)
	test_true("get_url post 3", length(content))
	test_equal("get_url post 4", "data=" & num, content[2])

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
	test_equal("multipart form file upload", data[1][2] & "\n" & file_content, content[2])
elsedef
    puts(2, " WARNING: URL tests were not run\n")
end ifdef

test_report()
