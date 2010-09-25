
include std/unittest.e
include std/error.e
integer fwd_id = routine_id("foo")

procedure bar()
end procedure

procedure foo()

end procedure

integer id = routine_id("foo")
test_equal( "forward, regular routine id same proc", id, fwd_id )


fwd_id = routine_id("baz")
function baz()
	return 0
end function
id = routine_id("baz")
test_equal( "forward, regular routine id same func", id, fwd_id )

test_report()
