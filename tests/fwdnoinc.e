include std/unittest.e

test_equal( "non-include global type resolution", UDT(0), 1 )
test_equal( "non-include global constant", FORWARD_GLOBAL, 1 )

ifdef EC then
fwd_object = 0
test_equal( "non-include global variable survives translation", 0, fwd_object )
end ifdef

with type_check
UDT u
u = 0
test_pass( "forward UDT type check doesn't hang execution" )
