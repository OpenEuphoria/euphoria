include std/unittest.e
include std/socket.e        -- is_inetaddr
include std/net/dns.e as dns

object _

ifdef not NO_INET then
	object check_ip = 0

	_ = gethostbyname("www.google.com")
	if sequence(_) then
		test_equal("gethostbyname #1", 4, length(_))
		test_true("gethostbyname #2", sequence(_[HOST_OFFICIAL_NAME]))
		test_true("gethostbyname #3", sequence(_[HOST_ALIASES]))
		test_true("gethostbyname #4", sequence(_[HOST_IPS]))
		test_true("gethostbyname #5", length(_[HOST_IPS]) > 0)
		test_true("gethostbyname #6", atom(_[HOST_TYPE]))

		for i = 1 to length(_[HOST_IPS]) do
			test_true("gethostbyname ipcheck", is_inetaddr(_[HOST_IPS][i]))

			-- get a valid ip for a later test on gethostbyaddr
			check_ip = _[HOST_IPS][i]
		end for
	else
		test_fail("gethostbyname #1")
	end if

	if sequence(check_ip) then
		_ = gethostbyaddr(check_ip)
		test_equal("gethostbyaddr #1", 4, length(_))
		test_true("gethostbyaddr #2", sequence(_[HOST_OFFICIAL_NAME]))
		test_true("gethostbyaddr #3", sequence(_[HOST_ALIASES]))
		test_true("gethostbyaddr #4", sequence(_[HOST_IPS]))
		test_true("gethostbyaddr #5", length(_[HOST_IPS]) > 0)
		test_true("gethostbyaddr #6", atom(_[HOST_TYPE]))

		for i = 1 to length(_[HOST_IPS]) do
			test_true("gethostbyaddr ipcheck", is_inetaddr(_[HOST_IPS][i]))
		end for
	else
		test_fail("gethostbyaddr not run due to failing gethostbyname")
	end if

elsedef
    puts(2, " WARNING: DNS tests were not run\n")
end ifdef


/*
object _

object addrinfo = dns:getaddrinfo("localhost", "http", 0)
--if sequence(addrinfo) then
--	test_equal("getaddrinfo localhost, http", "127.0.0.1:80", addrinfo[1][5])
--else
--	test_fail(sprintf("getaddrinfo returned error %d", addrinfo ))
--end if

--
-- dns functions
--

_ = dnsquery("yahoo.com", NS_T_MX, 0)
if atom(_) then
	test_fail("dnsquery 1")
else
	test_true("dnsquery 1", length(_) > 0)
	test_true("dnsquery 2", length(_[1]) = 3)
	test_true("dnsquery 3", sequence(_[1][1]))
	test_true("dnsquery 4", integer(_[1][2]))
	test_true("dnsquery 5", integer(_[1][2]))
end if

_ = dns:getmxrr("yahoo.com", 0)
if atom(_) then
	test_fail("getmxrr yahoo.com")
else
	test_true("getmxrr yahoo.com", sequence(_) and length(_) > 0)
end if

_ = dns:getnsrr("yahoo.com", 0)
if atom(_) then
	test_fail("getnsrr yahoo.com")
else
	test_true("getnsrr yahoo.com 1", sequence(_) and length(_) > 0)
	test_true("getnsrr yahoo.com 2", length(_[1]) = 3)
	test_true("getnsrr yahoo.com 3", sequence(_[1][1]))
	test_true("getnsrr yahoo.com 4", integer(_[1][2]))
	test_true("getnsrr yahoo.com 5", integer(_[1][3]))
end if

_ = getaddrinfo("yahoo.com", "http", 0)
if atom(_) or length(_) = 0 then
	test_fail("getaddrinfo yahoo.com")
else
	test_true("getaddrinfo yahoo.com 1", integer(_[1][ADDR_FLAGS]))
	test_true("getaddrinfo yahoo.com 2", integer(_[1][ADDR_FAMILY]))
	test_true("getaddrinfo yahoo.com 3", integer(_[1][ADDR_TYPE]))
	test_true("getaddrinfo yahoo.com 4", integer(_[1][ADDR_PROTOCOL]))
	test_true("getaddrinfo yahoo.com 5", sequence(_[1][ADDR_ADDRESS]))
end if
*/

test_report()
