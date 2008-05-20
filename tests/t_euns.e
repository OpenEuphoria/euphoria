include unittest.e

set_test_module_name("eu-internal")

without warning
function append(object a, object b)
	return {}
end function

with warning
test_equal("override #1", {}, append({1,2,3}, 4))
test_equal("eu:append", {1,2,3,4}, eu:append({1,2,3}, 4))
test_not_equal("override routine_id #1", routine_id("append"), -1 )
test_equal("routine_id(\"eu:append\")", routine_id("eu:id"), -1 )
