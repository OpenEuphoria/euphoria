
integer fwd_id = routine_id("test_equal")
include std/unittest.e
integer id = routine_id("test_equal")
test_equal( "forward, regular routine id include", id, fwd_id )


fwd_id = routine_id("foo")

procedure bar()
end procedure

procedure foo()
end procedure

id = routine_id("foo")
test_equal( "forward, regular routine id same proc", id, fwd_id )

fwd_id = routine_id("baz")
function baz()
	return 0
end function
id = routine_id("baz")
test_equal( "forward, regular routine id same func", id, fwd_id )

without inline
function retname(sequence a, sequence b)
	return routine_id(a & b)
end function

fwd_id = retname("cra", "sh")
include std/error.e
id = routine_id("crash")
test_equal( "forward, computed routine id included", id, fwd_id )

include routine_id.e

test_report()
