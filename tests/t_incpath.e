include std/unittest.e

test_equal( "include_paths(0) doesn't crash and returns a sequence", 1, sequence( include_paths( 0 ) ) )
test_equal( "include_paths(1) doesn't crash and returns a sequence", 1, sequence( include_paths( 1 ) ) )

test_report()
