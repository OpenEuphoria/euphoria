include std/error.e 
 
type enum boolean T,F=0 end type 
 
boolean enable_my_close = F 

procedure destroy_this_thing(atom fh) 
    if not enable_my_close then 
    	crash("Premature destruction of thing.")
    else
    	crash("Thing gets destroyed after all lines terminate")
    end if 
end procedure 

integer f_debug = 100
f_debug = delete_routine(f_debug, routine_id("destroy_this_thing")) 
enable_my_close = T 