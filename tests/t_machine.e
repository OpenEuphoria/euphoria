include machine.e
include unittest.e

set_test_module_name("machine.e")

ustring s1, s2, s3
s1 = "abcd"
s2 = ""
s3 = {#FFFF, #0001, #1000, #8080}

test_equal("peek_ustring and allocate_ustring#1", s1, peek_ustring(allocate_ustring(s1)))
test_equal("peek_ustring and allocate_ustring#2", s2, peek_ustring(allocate_ustring(s2)))
test_equal("peek_ustring and allocate_ustring#3", s3, peek_ustring(allocate_ustring(s3)))
