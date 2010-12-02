with define SAFE

include std/unittest.e
include std/machine.e
edges_only = 0


atom addr
addr = #DEADBEEF
poke(addr,"Hello")

test_pass("Should not be able to register a non-extrnal block of memory.")
