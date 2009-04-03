include std/unittest.e
include std/net/common.e
include std/net/dns.e as dns


ifdef not NO_INET then
	object _
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

test_report()
