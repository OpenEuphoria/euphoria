
include std/unittest.e
include safe.e

edges_only = 0


atom addr
addr = #DEADBEEF
poke(addr,"Hello")

test_pass("Should not be able to register a non-extrnal block of memory.")
