include std/unittest.e
include std/net/common.e
include std/net/dns.e as dns

ifdef not NO_INET then
	object _
	object check_ip = 0
	sequence check_ip_name

	_ = host_by_name("localhost")
	if sequence(_) then
		test_equal("host_by_name #1", 4, length(_))
		test_true("host_by_name #2", sequence(_[HOST_OFFICIAL_NAME]))
		test_true("host_by_name #3", sequence(_[HOST_ALIASES]))
		test_true("host_by_name #4", sequence(_[HOST_IPS]))
		test_true("host_by_name #5", length(_[HOST_IPS]) > 0)
		test_true("host_by_name #6", atom(_[HOST_TYPE]))

		check_ip_name = _[HOST_OFFICIAL_NAME]
		for i = 1 to length(_[HOST_IPS]) do
			test_true("host_by_name ipcheck", is_inetaddr(_[HOST_IPS][i]))

			-- get a valid ip for a later test on host_by_addr
			check_ip = _[HOST_IPS][i]
		end for
	else
		test_fail("host_by_name #1")
	end if

	if sequence(check_ip) then
		_ = host_by_addr(check_ip)
		if atom(_) then
			test_fail(sprintf("host_by_addr failed for '%s' - '%s'", {check_ip, check_ip_name}))
		else
			test_equal("host_by_addr #1", 4, length(_))
			test_true("host_by_addr #2", sequence(_[HOST_OFFICIAL_NAME]))
			test_true("host_by_addr #3", sequence(_[HOST_ALIASES]))
			test_true("host_by_addr #4", sequence(_[HOST_IPS]))
			test_true("host_by_addr #5", length(_[HOST_IPS]) > 0)
			test_true("host_by_addr #6", atom(_[HOST_TYPE]))
	
			for i = 1 to length(_[HOST_IPS]) do
				test_true("host_by_addr ipcheck", is_inetaddr(_[HOST_IPS][i]))
			end for
		end if
	else
		test_fail("host_by_addr not run due to failing host_by_name")
	end if

elsedef
    puts(2, " WARNING: DNS tests were not run\n")
end ifdef

test_report()
