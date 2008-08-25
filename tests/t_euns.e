include std/unittest.e

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
include foo_default.e
include bar_default.e as bar
test_equal( "default namespace", "foo", foo:test() )
test_equal( "override default namespace", "bar", bar:test() )

include foo_export.e
test_equal( "public function", "foo", export_test() )
test_equal( "public constant", "foo", EXPORT_CONSTANT )
test_not_equal( "public routine id", -1, routine_id("export_test"))
test_equal( "public include",  "baz", baz() )
test_not_equal( "routine id public visible through public include", -1, routine_id("baz") )
test_equal( "routine id export not visible through public include", -1, routine_id("baz_export") )
test_report()

