-- A similar counter test file is t_c_qualpredef.e
-- A similar counter test file is t_c_scope_local_include.e
include std/unittest.e as ut

ut:puts( 1, "This should crash\n" )

test_pass("This should never happen")
test_report()
