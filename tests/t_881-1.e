function foo(integer x) 
    return and_bits(floor(x/{#40,#08,#1}), #7) 
end function 
 
constant b = #AA 
 
sequence s0 = foo(b) 

include std/unittest.e

test_report()
