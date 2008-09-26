include std/unittest.e

include fwd_constasgn.e

export constant foo = 1

test_fail( "forward assignment to a constant" )
test_report()
