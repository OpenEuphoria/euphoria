include unittest.e
include error.e

with warning "short_circuit_warning"

integer n=3,n0
sequence s0="Useless code"

function f(sequence s="abcd")
	if n<0 then ?0 end if
	return length(s)
end function

if n and f()=7 then end if

with warning &= "not_used_warning" "custom_warning"

function foo()
	integer n=n+f()
	return n
end function

test_equal("Assign on declare 1",s0,"Useless code")
test_equal("Assign on declare 1",n,3)
test_equal("Use default params in initial value",7,foo())
warning("Useless code")

without warning &= "short_circuit_warning"
if n and f()=7 then end if

warning_file("warning.lst")

test_report()