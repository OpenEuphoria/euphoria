include unittest.e
with warning
integer n=3,n0
sequence s0="Useless code"
function f(sequence s="abcd")
return length(s)
end function

function foo()
integer n=n+f()
return n
end function
test_equal("Assign on declare 1",s0,"Useless code")
test_equal("Assign on declare 1",n,3)
test_equal("Use default params in initial value",7,foo())
warning("Useless code")

