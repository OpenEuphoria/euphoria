include std/unittest.e

with define FOO

function foo()
	return 1
end function

function bar( object bat )
	object foo = 0
	ifdef FOO then
		foo = foo()
	end ifdef
	return foo
end function

test_pass("fake pass...this file should fail")

test_report()
