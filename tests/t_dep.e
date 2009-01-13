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

ifdef UNITTEST then
	include std/unittest.e
end ifdef

object line


procedure PETC()
	ifdef !UNITTEST then
		puts(1,"Press Enter to Continue")
		line = gets(0)
		puts(1,10)
	end ifdef
end procedure

function fPETC()
	ifdef !UNITTEST then
		puts(1,"Press Enter to Continue")
		line = gets(0)
		puts(1,10)
		return line
	elsedef
		return "test\n"
	end ifdef
end function

integer calling_memfunction
calling_memfunction = 0
function print_failure(object x)
    if calling_memfunction then
	ifdef UNITTEST then
		test_fail( "Is memory allocated by allocate_code() executable?" )
		test_report()
	elsedef
		puts( 1, "  We have found that the xalloc.e routines do not really make memory executable.\n" )
		puts( 1, "This conclusively tells us that there is a bug in the allocate_code() function.  Please let me know about this:  Email me at shawn.pringle@gmail.com" )
		puts( 1, "Test result for allocate_code: FAILURE\n" )
		PETC()
	end ifdef
        abort(0)
    end if
    return 0
end function

integer calling_dmemfunction
calling_dmemfunction = 0
function dep_is_enabled(object x)
    if calling_dmemfunction then
	if fs:delete_file( "ex.err" ) then
		puts(1, "The file ex.err has been deleted.\n" )
	end if
	ifdef UNITTEST then
		test_pass( "Is memory allocated by allocate_code() executable?" )
		test_pass( "Can we call functions returned by call_back?" )
		test_report()
	elsedef
        	puts(1, "The code allocated with allocate(), however raised an exception and it SHOULD.  Therefore D.E.P. is enabled for the interpreter you used for this test on your system.  This means, your system is configured correctly to test allocate_code() and that allocate_code() and call_back() work properly.\n" )
		puts(1, "Test result for allocate_code: SUCCESS!\n" )
	end ifdef
        PETC()
	abort(0)
    end if
    return 0
end function

integer calling_call_back = 0
function when_callback_call_fails( object x )
    if calling_call_back then
	if fs:delete_file( "ex.err" ) then
	end if
	ifdef UNITTEST then
		test_pass( "Is memory allocated by allocate_code() executable?" )
		test_fail( "Can we call functions returned by call_back?" )
		test_report()
	end ifdef
	puts( 1, "Executing from an address returned by callback caused an exception.\n" )
	PETC()
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
   #C2, #0C - 4 * (platform()=LINUX), #00  -- ret C -- pop 12 (or 8) bytes 
					   -- off the stack
    }

crash_routine(routine_id("print_failure"))
crash_routine(routine_id("dep_is_enabled"))
crash_routine(routine_id("when_callback_call_fails"))
code_space = allocate_code(multiply_code)
data_space = allocate(length(multiply_code))
if data_space = 0 then
    puts(  1, "Could not allocate memory!" )
    PETC()
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

function five() 
	return 5 
end function 
 
atom five_cb = call_back(routine_id("five"))  
integer cb = define_c_func("", {'+', five_cb}, {}, C_INT) 

calling_call_back = 1
void = c_func(cb, {}) 
calling_call_back = 0

calling_dmemfunction = 1
void = c_func(rdata, {x,y})
calling_dmemfunction = 0
    
ifdef UNITTEST then
	test_report()
end ifdef