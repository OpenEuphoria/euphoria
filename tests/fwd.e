-- fwd.e
namespace fwdref
include std/unittest.e

include t_fwd.e as t_fwd
include fwd2.e as fwd2

export constant EXPORT_CONSTANT = 1
export constant FOO = "fwd"

export procedure foo2(integer a)
	result2 = 123
end procedure

public function foo3(integer a)
	for i = 1 to 3 do
		result3[i] = i
	end for
	return a + 3
end function

global function foo4(integer a)
	for i = 1 to 4 do
		result4[i] = i
	end for
	return a + 4
end function

fwd_var = 1
if fwd_var = 0 then

end if
test_pass("emit:IsInteger check on forward reference")

public procedure foo5()
	var2 = 3
end procedure


