namespace fwdref2

include std/unittest.e

include t_fwd.e as t_fwd
include fwd.e as fwd

procedure ticket684()
	test_equal( "qualified forward resolution when multiple matching names exist 1", t_fwd:FOO, "t_fwd" )
	test_equal( "qualified forward resolution when multiple matching names exist 2", fwd:FOO, "fwd" )
end procedure
ticket684()
