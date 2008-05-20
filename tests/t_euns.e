include unittest.e

set_test_module_name("eu-internal")

without warning
function append(object a, object b)
	return {}
end function

with warning
test_equal("override #1", {}, append({1,2,3}, 4))
test_equal("eu:append", {1,2,3,4}, eu:append({1,2,3}, 4))

