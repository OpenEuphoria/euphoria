include std/unittest.e
integer gb

procedure foo(integer a)
   gb = a
end procedure

function bar(integer a)
   return gb + a
end function

integer r_foo = routine_id("foo")
integer r_bar = routine_id("bar")

call_proc(r_foo, {5})
test_equal("procedure call", 5, gb)
test_equal("function call", 15, call_func(r_bar, {10}))


test_report()

