include std/unittest.e
include std/socket.e as sock

-- TODO: add more tests. This at least checks to make sure socket.e is
-- compiling and at least partly functions.

sequence addrinfo = sock:getaddrinfo("localhost", "http", 0)
test_equal("getaddrinfo localhost, http", "127.0.0.1:80", addrinfo[1][5])

object dns = sock:getmxrr("yahoo.com",0)
test_true("getmxrr yahoo.com", sequence(dns) and length(dns) > 0)

test_report()

