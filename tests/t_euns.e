include unittest.e

set_test_module_name("eu-internal")
set_test_verbosity(TEST_SHOW_ALL)
without warning
function append(object a, object b)
	return {}
end function

with warning
test_equal("override #1", {}, append({1,2,3}, 4))
test_equal("eu:append", {1,2,3,4}, eu:append({1,2,3}, 4))
test_not_equal("override routine_id #1", routine_id("append"), -1 )
test_equal("routine_id(\"eu:append\")", routine_id("eu:id"), -1 )

include foo_default.e
include bar_default.e as bar
test_equal( "default namespace", "foo", foo:test() )
test_equal( "override default namespace", "bar", bar:test() )

include foo_export.e
test_equal( "export function", "foo", export_test() )
test_equal( "export constant", "foo", EXPORT_CONSTANT )
test_not_equal( "export routine id", -1, routine_id("export_test"))
test_equal( "export include",  "baz", baz() )

