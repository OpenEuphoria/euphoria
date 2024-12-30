include std/unittest.e
include std/os.e 
 
enum KEYBOARD = 0, SCREEN 

type enum boolean FALSE = 0, TRUE
end type

boolean cleaned = FALSE

procedure bad_cleanup_routine() 
    cleaned = TRUE
end procedure 
 
function new_object_with_cleanup() 
	return delete_routine(1, routine_id("bad_cleanup_routine")) 
end function 
 
integer x = new_object_with_cleanup() 

-- should clean up x here 
x = 4 
 
while x do
    x = x - 1 
end while 

test_pass("Able to operate with a destructor assigned to integer\n")
test_true("cleanup_routine_called", cleaned) 

test_report()