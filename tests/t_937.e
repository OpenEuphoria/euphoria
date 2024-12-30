include std/io.e 
include std/error.e 
include std/unittest.e 
with trace
trace(1)


type enum boolean T,F=0 end type 
type file_number(integer x)
  return x >= -1
end type

boolean enable_my_close = F 
 
procedure my_close(integer fh) 
    if fh > io:STDERR then 
    	-- Closing file 
    	if not enable_my_close then 
    		test_fail("premature file closing") 
    	end if 
        close(fh) 
    end if 
    test_pass("dstor called")
end procedure

procedure do_nothing(integer bool)
end procedure
 
-- Make sure a user defined type that is integer based can have routine_ids too.
procedure use_integer_with_dtor()
  file_number f_debug = open("example.log", "w") 
  if f_debug =-1 then 
      f_debug = open("/dev/null", "w") 
      puts(io:STDERR, "Unable to create log file.") 
  else 
      f_debug = delete_routine(f_debug, routine_id("my_close")) 
  end if
end procedure
 
enable_my_close = T

-- dtor will be called when this routine exits.
use_integer_with_dtor()


enable_my_close = F
file_number f_debug = open("example.log", "w") 
if f_debug =-1 then 
    f_debug = open("/dev/null", "w") 
    puts(io:STDERR, "Unable to create log file.") 
else 
    f_debug = delete_routine(f_debug, routine_id("my_close")) 
end if

enable_my_close = T
-- dtor will be executed by changing its value to a new one.
f_debug = -1


enable_my_close = F
f_debug = open("example.log", "w") 
if f_debug =-1 then 
    f_debug = open("/dev/null", "w") 
    puts(io:STDERR, "Unable to create log file.") 
else 
    f_debug = delete_routine(f_debug, routine_id("my_close")) 
end if

enable_my_close = T
-- dtor will be executed by changing its value to a new one.
f_debug += 1

test_report() 
