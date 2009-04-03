include std/unittest.e
include std/net/common.e

test_true( "is_inetaddr #1", is_inetaddr("127.0.0.1"))
test_true( "is_inetaddr #2", is_inetaddr("0.0.0.0"))
test_true( "is_inetaddr #3", is_inetaddr("127.0.0.1:100"))
test_true( "is_inetaddr #3", is_inetaddr("155.212.244.8"))
test_false("is_inetaddr #4", is_inetaddr("john doe"))
test_false("is_inetaddr #5", is_inetaddr("127.0.0.1:100.5"))
test_false("is_inetaddr #6", is_inetaddr("327.0.0.1"))
test_false("is_inetaddr #7", is_inetaddr("1.256.0.1"))
test_false("is_inetaddr #8", is_inetaddr("1.-18.0.1"))

test_equal("parse_ip_address #1", {"1.2.3.4", 80}, parse_ip_address("1.2.3.4"))
test_equal("parse_ip_address #2", {"1.2.3.4", 80}, parse_ip_address("1.2.3.4:"))
test_equal("parse_ip_address #3", {"1.2.3.4", 10}, parse_ip_address("1.2.3.4:10"))
test_equal("parse_ip_address #4", {"1.2.3.4", 20}, parse_ip_address("1.2.3.4", 20))
test_equal("parse_ip_address #4", {"1.2.3.4", 20}, parse_ip_address("1.2.3.4:10", 20))

object url_data = parse_url("http://john.com/index.html?name=jeff")
test_equal("parse_url (http) #1", {
		"http://john.com/index.html?name=jeff", -- URL_ENTIRE
		"http",          -- URL_PROTOCOL
		"john.com",      -- URL_DOMAIN
		"/index.html",   -- URL_PATH
		"?name=jeff"     -- URL_QUERY
	}, url_data)
test_equal("parse_url constant values #1", "http://john.com/index.html?name=jeff", url_data[URL_ENTIRE])
test_equal("parse_url constant values #2", "http", url_data[URL_PROTOCOL])
test_equal("parse_url constant values #3", "john.com", url_data[URL_HTTP_DOMAIN])
test_equal("parse_url constant values #4", "/index.html", url_data[URL_HTTP_PATH])
test_equal("parse_url constant values #5", "?name=jeff", url_data[URL_HTTP_QUERY])

url_data = parse_url("mailto:john@mail.doe.com?subject=Hello%20John%20Doe")
test_equal("parse_url (mailto) #1", {
		"mailto:john@mail.doe.com?subject=Hello%20John%20Doe",
		"mailto",
		"john@mail.doe.com",
		"john",
		"mail.doe.com",
		"?subject=Hello%20John%20Doe"
	}, url_data)
test_equal("parse_url (mailto) constant values #1",
	"mailto:john@mail.doe.com?subject=Hello%20John%20Doe", url_data[URL_ENTIRE])
test_equal("parse_url (mailto) constant values #1", "mailto", url_data[URL_PROTOCOL])
test_equal("parse_url (mailto) constant values #1", "john@mail.doe.com", url_data[URL_MAIL_ADDRESS])
test_equal("parse_url (mailto) constant values #1", "john", url_data[URL_MAIL_USER])
test_equal("parse_url (mailto) constant values #1", "mail.doe.com", url_data[URL_MAIL_DOMAIN])
test_equal("parse_url (mailto) constant values #1", "?subject=Hello%20John%20Doe", url_data[URL_MAIL_QUERY])

test_equal("parse_url invalid", -1, parse_url("john.com"))

test_report()
