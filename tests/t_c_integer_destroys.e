include std/io.e 
include std/error.e 
include std/unittest.e 
 
type enum boolean T,F=0 end type 
 
boolean enable_my_close = F 
 
procedure my_close(integer fh) 
    if fh > io:STDERR then 
    	printf(io:STDERR, "Closing file %d\n", {fh}) 
    	if not enable_my_close then 
    		crash("premature file closing") 
    	end if 
        close(fh) 
    end if 
end procedure 
 
integer f_debug = open("example.log", "w") 
if f_debug =-1 then 
	f_debug = open("/dev/null", "w") 
  	puts(io:STDERR, "Unable to create log file.") 
else 
    f_debug = delete_routine(f_debug, routine_id("my_close")) 
end if 
 
enable_my_close = T 
 
test_report()
