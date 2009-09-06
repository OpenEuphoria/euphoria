include std/map.e
include std/unittest.e
include std/net/url.e

object o = parse_querystring("name=John&age=18&location=Small+Town%20Ohio")
test_equal("parse_querystring #1", "John", map:get(o, "name"))
test_equal("parse_querystring #2", "18", map:get(o, "age"))
test_equal("parse_querystring #3", "Small Town Ohio", map:get(o, "location"))

test_equal("encode 1", "Hello+%26+World", url:encode("Hello & World"))
test_equal("encode 2", "Hello%20%26%20World", url:encode("Hello & World", "%20"))

test_equal("decode #1", "Hello & World", url:decode("Hello+%26+World"))
test_equal("decode #2", "Hello & World", url:decode("Hello%20%26%20World"))

test_equal("parse #1", { 
    	"http", 
    	"www.debian.org", 
    	80, 
    	"/index.html", 
    	"user", 
    	"pass", 
    	"name=John&age=39" 
    },
    parse("http://user:pass@www.debian.org:80/index.html?name=John&age=39"))

test_equal("parse #2", {
        "ftp",
        "ftp.debian.org",
        0,
        0,
        0,
        0,
        0
    },
    parse("ftp://ftp.debian.org"))

test_equal("parse #3", {
    	"mailto",
    	"spam.com",
    	0,
    	0,
    	"john",
    	0,
    	"subject=Hello+World"
    },
    parse("mailto:john@spam.com?subject=Hello+World"))

test_equal("parse #4", {
    	"ftp",
    	"ftp.debian.org",
    	33,
    	"/file.txt",
    	"anonymous",
    	0,
    	0
	},
    parse("ftp://anonymous@ftp.debian.org:33/file.txt"))

test_equal("parse #5", {
		"mysql",
		"localhost",
		0,
		"/listfilt",
		0,
		0,
		"user=hello&password=goodbye"
	},
	parse("mysql://localhost/listfilt?user=hello&password=goodbye"))

o = parse("http://example.com?name=John&age=18", 1)
test_equal("parse #5", "John", map:get(o[URL_QUERY_STRING], "name"))
test_equal("parse #6", "18", map:get(o[URL_QUERY_STRING], "age"))

test_report()
