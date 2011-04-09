include std/unittest.e
with trace 
trace(0)

test_pass("trace(0)")

--improve unittest.e coverage
assert(1, "trace(0)") 
assert("trace(0)", 1)
set_wait_on_summary(0)

test_report()
