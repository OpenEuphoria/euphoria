function foo(integer x) 
    return and_bits(x, {#C0,#38,#7})/{#40,#08,#1} 
end function 
 
constant b = #AA 
 
sequence s0 = foo(b) 

include std/unittest.e

test_report()
