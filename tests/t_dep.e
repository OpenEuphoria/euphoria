-- Test routines to see whether code returned by 
-- allocate_code() and call_back() crash.  They should never crash.
--
-- code called into memory returned by allocate() will crash if
-- DEP is enabled.
--
-- Now, if calling code using memory returned by allocate() doesn't
-- crash the process we consider the test inconclusive.

-- Flow control
-- 
-- The idea is we try to do things that might cause the program
-- to crash and then the crash handler puts test_fail() for each
-- thing we tried.  In the case of running code from memory returned
-- by allocate() we know the other things did not crash so we
-- call test_pass there.

include std/filesys.e as fs
include std/machine.e as mach 
include std/dll.e as dll
include std/os.e as os
include std/error.e as error
include std/callback.e as callback

include std/unittest.e

object line

integer calling_memfunction
calling_memfunction = 0
function print_failure(object x)
    if calling_memfunction then
		test_fail( "Is memory allocated by allocate_code() executable?" )
		test_report()
        abort(0)
    end if
    return 0
end function

integer calling_dmemfunction
calling_dmemfunction = 0
-- This will be called if an exception is raised in calling read-write-only memory.
function dep_is_enabled(object x)
    if calling_dmemfunction then
	if fs:delete_file( "ex.err" ) then
		puts(1, "The file ex.err has been deleted.\n" )
	end if
	test_pass( "Is memory allocated by allocate_code() executable?" )
	ifdef !DOS32 then
		test_pass( "Can we call functions returned by call_back?" )
	end ifdef
	test_report()
	abort(0)
    end if
    return 0
end function

integer calling_call_back = 0
function when_callback_call_fails( object x )
    if calling_call_back then
	if fs:delete_file( "ex.err" ) then
	end if
	test_pass( "Is memory allocated by allocate_code() executable?" )
	test_fail( "Can we call functions returned by call_back?" )
	test_report()
	puts( 1, "Executing from an address returned by callback caused an exception.\n" )
	abort(0)
    end if
    return 0
end function

atom code_space, data_space
sequence multiply_code
atom rexec, rdata
atom x,y
object void


-- machine code taken from callmach.ex
multiply_code = {
   -- int argument is at stack offset +4, double is at +8 
   #DB, #44, #24, #04,        -- fild  dword ptr +4[esp]
   #DC, #4C, #24, #08,        -- fmul  qword ptr +8[esp]
   #C2, #0C * (platform() != LINUX), #00  -- ret C -- pop 12 (or 0) bytes 
					   -- off the stack
    }

crash_routine(routine_id("print_failure"))
crash_routine(routine_id("dep_is_enabled"))
crash_routine(routine_id("when_callback_call_fails"))
code_space = allocate_code(multiply_code)
data_space = allocate(length(multiply_code))
if data_space = 0 then
    puts(  1, "Could not allocate memory!" )
    abort(0)
end if
poke( data_space, multiply_code )
rexec = define_c_func("", code_space, {C_INT, C_DOUBLE}, C_DOUBLE)
rdata = define_c_func("", data_space, {C_INT, C_DOUBLE}, C_DOUBLE ) 

x = 7
y = 8.5

calling_memfunction = 1
void = c_func(rexec, {x, y})
calling_memfunction = 0

function ifthenelse( integer condition, sequence s1, object x2 )
	if condition then return s1 else return x2 end if
end function

function five( atom x ) 
	return 5 + x
end function 
 
ifdef !DOS32 then
	atom five_cb_cdecl = call_back( '+' & routine_id("five") )
	test_not_equal( "create forced cdecl callback", 0, five_cb_cdecl )
	
	atom five_cb = call_back( routine_id("five") )
	test_not_equal( "create regular callback", 0, five_cb )
	
	integer cb_cdecl = define_c_func("", {'+', five_cb}, {C_INT}, C_INT)
	integer cb = define_c_func("", five_cb, {C_INT}, C_INT)
	
	integer result
	
	test_not_equal( "define_c callback (forced cdecl)", -1, cb_cdecl )
	test_not_equal( "define_c callback", -1, cb )
	
	calling_call_back = 1
	result = c_func( cb, {1})
	test_equal( "call regular callback", 6, result )
	calling_call_back = 0
	
	calling_call_back = 1
	result = c_func( cb_cdecl, {2})
	test_equal( "call forced cdecl callback", 7, c_func( cb_cdecl, {2}) )
	calling_call_back = 0
end ifdef

calling_dmemfunction = 1
void = c_func(rdata, {x,y})
calling_dmemfunction = 0
    
test_report()
