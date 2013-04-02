
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

include std/unittest.e


object line

sequence test_message = ""
function bad_failure(object x)
	if compare( test_message, "" ) = 0 then
		return 0
	end if
	if fs:delete_file( "ex.err" ) then
	end if
	test_fail( test_message )
	test_report()
	abort(0)
end function

integer calling_dmemfunction
calling_dmemfunction = 0
-- This will be called if an exception is raised in calling read-write-only memory.
-- This is what DEP is susposed to do, so we get an ugly message from the
-- interpreter.  We want an exception to be raised.
function dep_is_enabled(object x)
	if calling_dmemfunction then
		if fs:delete_file( "ex.err" ) then
			puts(1, "The file ex.err has been deleted.\n\n" )
		end if
		puts(1, "DEP is enabled for this process\n")
		test_report()
		abort(0)
	end if
	return 0
end function


atom code_space, data_space, r_space, rw_space, rwx_space, n_space, w_space
sequence multiply_code
atom rexec, rdata
atom x,y
object void

integer use_stdcall
ifdef UNIX then
	use_stdcall = 0
elsedef
	use_stdcall = 1
end ifdef

ifdef ARM then
	-- ARM hard float
	multiply_code = {
		0x04,0xB0,0x2D,0xE5, -- 591
		0x00,0xB0,0x8D,0xE2, -- 595
		0x14,0xD0,0x4D,0xE2, -- 599
		0x08,0x00,0x0B,0xE5, -- 59D
		0x05,0x0B,0x0B,0xED, -- 5A1
		0x08,0x30,0x1B,0xE5, -- 5A5
		0x90,0x3A,0x07,0xEE, -- 5A9
		0xE7,0x6B,0xB8,0xEE, -- 5AD
		0x05,0x7B,0x1B,0xED, -- 5B1
		0x07,0x7B,0x26,0xEE, -- 5B5
		0x47,0x0B,0xB0,0xEE, -- 5B9
		0x00,0xD0,0x8B,0xE2, -- 5BD
		0x00,0x08,0xBD,0xE8, -- 5C1
		0x1E,0xFF,0x2F,0xE1, -- 5C5
		$ }
elsifdef BITS32 then
	-- machine code taken from callmach.ex
	multiply_code = {
	-- int argument is at stack offset +4, double is at +8 
	#DB, #44, #24, #04,        -- fild  dword ptr +4[esp]
	#DC, #4C, #24, #08,        -- fmul  qword ptr +8[esp]
	#C2, #0C * use_stdcall, #00  -- ret C -- pop 12 (or 0) bytes 
						-- off the stack
	}
elsedef
	multiply_code = { 
			#55,                     --  push   %rbp
			#48, #89, #e5,           --  mov    %rsp,%rbp
			#89, #7d, #fc,           --  mov    %edi,-0x4(%rbp)
			#f2, #0f, #11, #45, #f0, --  movsd  %xmm0,-0x10(%rbp)
			#f2, #0f, #2a, #45, #fc, --  cvtsi2sdl -0x4(%rbp),%xmm0
			#f2, #0f, #59, #45, #f0, --  mulsd  -0x10(%rbp),%xmm0
			#c9,                     --  leaveq 
			#c3,                     --  retq   
			$
		}
end ifdef

crash_routine(routine_id("bad_failure"))
crash_routine(routine_id("dep_is_enabled"))

test_message = "allocate code memory"
code_space = allocate_code(multiply_code)
test_not_equal( "allocate code memory", 0, code_space )

data_space = allocate(length(multiply_code))
test_not_equal( "allocate data memory", 0, data_space )
if code_space = 0 or data_space = 0 then
	test_report()
	abort(0)
end if
poke( data_space, multiply_code )
rexec = define_c_func("", code_space, {C_INT, C_DOUBLE}, C_DOUBLE)
rdata = define_c_func("", data_space, {C_INT, C_DOUBLE}, C_DOUBLE ) 

x = 7
y = 8.5

function five( atom x ) 
	return 5 + x
end function 

test_message = "Is memory allocated by allocate_code() executable?"
void = c_func(rexec, {x, y})
test_pass( "Is memory allocated by allocate_code() executable?" )
test_message = ""


atom five_cb_cdecl = call_back( '+' & routine_id("five") )
test_not_equal( "create forced cdecl callback", 0, five_cb_cdecl )

atom five_cb = call_back( routine_id("five") )
test_not_equal( "create regular callback", 0, five_cb )

integer cb_cdecl = define_c_func("", {'+', five_cb_cdecl}, {C_INT}, C_INT)
integer cb = define_c_func("", five_cb, {C_INT}, C_INT)

integer result

test_not_equal( "define_c callback (forced cdecl)", -1, cb_cdecl )
test_not_equal( "define_c callback", -1, cb )

test_message = "call regular callback"
result = c_func( cb, {1})
test_equal( "call regular callback", 6, result )

test_message = "call forced cdecl callback"
result = c_func( cb_cdecl, {2})
test_equal( "call forced cdecl callback", 7, c_func( cb_cdecl, {2}) )

test_message = "call_back() called many times"
for i = 1 to 60 do
	void = call_back( routine_id("allocate_protect") )
	void = call_back( routine_id("allocate") )
	void = call_back( routine_id("allocate_code") )
end for
five_cb = call_back( routine_id("five") )
void = call_back( routine_id("allocate_protect") )

test_message = "call declared cdecl callback after many calls"
cb_cdecl = define_c_func("", {'+', five_cb_cdecl}, {C_INT}, C_INT)
test_message = "call forced cdecl callback after many calls"
result = c_func( cb_cdecl, {2})
test_equal( "call forced cdecl callback", 10, c_func( cb_cdecl, {5}) )
test_message = ""

test_message = "allocate readonly memory"
r_space = allocate_protect( { 5,6,7,8}, 1, PAGE_READONLY )
test_not_equal( test_message, 0, r_space )
test_message = "reading from readonly memory"
test_equal( test_message, {5,6,7,8}, peek( { r_space, 4 } ) )
test_message = "free readonly memory"
free_code( r_space, 4 )

test_message = "allocate read and write memory" -- use allocate() for this
rw_space = allocate_protect( {1,2,3,4}, 1, PAGE_READWRITE )
test_not_equal( test_message, 0, rw_space )
test_message = "read from readonly memory"
test_equal( test_message, {1,2,3,4}, peek( { rw_space, 4 } ) )	
test_message = "write to readonly memory"
poke( rw_space, 5 )
poke( rw_space+1, {6,7,8} )
test_message = "read from readonly memory"
test_equal( test_message, {5,6,7,8}, peek( { rw_space, 4 } ) )	
test_pass( test_message )
free_code( rw_space, 4 )

test_message = "allocate read write and execute memory"
rwx_space = allocate_protect( multiply_code, 1, PAGE_EXECUTE_READWRITE )
test_not_equal( test_message, 0, rwx_space )
test_message = ""
rexec = define_c_func("", rwx_space, {C_INT, C_DOUBLE}, C_DOUBLE)
test_message = "execute using read write and execute memory"
void = c_func(rexec, {x, y})
test_pass( test_message )
test_message = "write to read write and execute memory"
poke( rwx_space, 5 )
test_pass( test_message )
test_message = "read from read write and execute memory"
test_equal( test_message, 5 & multiply_code[2..4], peek( { rwx_space, 4 } ) )
free_code( rwx_space, 4 )

test_message = "allocate no access memory"
n_space = allocate_protect( multiply_code, 1, PAGE_NOACCESS )
test_not_equal( test_message, 0, n_space )
free_code( n_space, length( multiply_code ) )
-- do nothing
test_message = ""

-- Regression test for Euphoria 3 Std Library callbacks:
without indirect_includes
include dep3.e

test_report()
