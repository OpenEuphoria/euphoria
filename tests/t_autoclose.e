include std/unittest.e

type enum boolean
  FALSE=0,TRUE
end type

boolean cleanedup = FALSE

procedure cleanup_now(object in_put)
  cleanedup = TRUE
end procedure

integer fd = open("t_autoclose.e", "r", 1)

test_pass( "able to assign integers to integer with destructors" )

function wrapper()
  return delete_routine(4, routine_id("cleanup_now"))
end function

integer other = wrapper()

other = 3

test_equal("Cleaned up called", TRUE, cleanedup)
test_report()