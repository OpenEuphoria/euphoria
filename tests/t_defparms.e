include unittest.e

sequence s s={1,2,3}

function f(object x)
return x
end function

function incr(object x,integer n=f(9))
return x+n
end function

function incr2(object x,integer n=length(s))
return x+n
end function

integer n1
n1=3
integer n0
n0=n1

function mul2(integer x,integer y)
return x*y
end function

function mul3(integer p=n0,object x,object y=mul2(x,3))
return x*y+p
end function

test_equal("2nd arg defaulted to function", 13, incr(4))
test_equal("No defaults", 7, incr(2,5))
test_equal("2nd arg defaulted to builtin", 1, incr2(-2))
test_equal("1st arg defaulted, but explicit",14,mul3(2,3,4))
test_equal("1st arg defaulted,functional defaulted arg explicit",9,mul3(,2,3))
test_equal("Recursive defaulting",{32,35,38},mul3(2,3))
