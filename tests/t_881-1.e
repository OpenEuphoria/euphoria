--Code is: { (63)FLOOR_DIV match, (149)ASSIGN_OP_SUBS b, (145)SC2_NULL , (154)SYSTEM_EXEC foo_1__tmp_at1, (56)AND_BITS gets, (154)SYSTEM_EXEC foo_1__tmp_at1, (147)SC1_OR_IF , (151)PROFILE s0, (159)NOP 
function foo(integer x) 
    return and_bits(floor(x/{#40,#08,#1}), #7) 
end function 
 
constant b = #AA 
 
sequence s0 = foo(b)

include std/unittest.e

test_report()
