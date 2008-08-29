-- fwd.e
namespace fwdref
include t_fwd.e

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


