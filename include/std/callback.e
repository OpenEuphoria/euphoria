-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
--****
-- == Dynamic Linking to external code
--
-- <<LEVELTOC depth=2>>
--
include std/convert.e
include std/machine.e
include std/error.e
include std/math.e

constant M_CALL_BACK = 52
constant EXECUTABLE_ALIGNMENT = 4 -- can we execute on 2 mod 4 or even odd 
                                -- addresses?
constant call_back_size = 92 -- maximum value of C based Euphoria and the 
                             -- Euphoria based Euphoria.
atom page_addr = 0
atom page_offset = 0
--**
-- Get a machine address for an Euphoria procedure.
--
-- Platform:
--      not //DOS//
--
-- Parameters:
--              # ##id##: an object, either the id returned by [[:routine_id]] for the function/procedure, or a pair {'+', id}.
--
-- Returns:
--              An **atom**, the address of the machine code of the routine. It can be
-- used by Windows, or an external C routine in a Windows .dll or Unix-like shared
-- library (.so), as a 32-bit "call-back" address for calling your Euphoria routine. 
--
-- Errors:
-- The length of ##name## should not exceed 1,024 characters.
--
-- Comments:
--      By default, your routine will work with the stdcall convention. On
-- Windows, you can specify its id as {'+', id}, in which case it will work with the cdecl calling
-- convention instead. On non-Microsoft platforms, you
-- should only use simple IDs, as there is just one standard calling convention, i.e. cdecl.
--
--     You can set up as many call-back functions as you like, but they must all be Euphoria
--     functions (or types) with 0 to 9 arguments. If your routine has nothing to return
--     (it should really be a procedure), just return 0 (say), and the calling C routine can
--     ignore the result.
--
--     When your routine is called, the argument values will all be 32-bit unsigned (positive)
--     values. You should declare each parameter of your routine as atom, unless you want to 
--     impose tighter checking. Your routine must return a 32-bit integer value.
--
--     You can also use a call-back address to specify a Euphoria routine as an exception 
--     handler in the Linux/FreeBSD signal() function. For example, you might want to catch
--     the SIGTERM signal, and do a graceful shutdown. Some Web hosts send a SIGTERM to a CGI
--     process that has used too much CPU time.
--
--     A call-back routine that uses the cdecl convention and returns a floating-point result, 
--     might not work with exw. This is because the Watcom C compiler (used to build exw) has 
--     a non-standard way of handling cdecl floating-point return values.
--
-- Example 1: 
-- See: ##demo\win32\window.exw##, ##demo\linux\qsort.exu##
--
-- See Also:
--     [[:routine_id]]
public function call_back(object id)
        
        ifdef !WIN32 then
                -- save speed for OSes that do not have DEP.
                return machine_func(M_CALL_BACK, id)
        elsedef
                sequence s, code, rep
                atom addr, size, repi
                atom z
                s = machine_func(M_CALL_BACK, {id})
                addr = s[1]
                rep =  int_to_bytes( s[2] )
                size = s[3]
                code = peek( {addr, size} )
                repi = match( {#78, #56, #34, #12 }, code[5..$-4] ) + 4
                if repi = 4 then
                        crash("Cannot generate call_back address.")
                end if
                if page_addr = 0 or page_addr + page_offset + call_back_size >= PAGE_SIZE then  
                        page_addr = allocate_protect( code[1..repi-1] & rep & code[repi+4..length(code)], PAGE_EXECUTE_READWRITE )
                        page_offset = 0
                else
                        -- align for execution (need 8-byte?) and put after the previous call back
                        page_offset += EXECUTABLE_ALIGNMENT* ceil( size / EXECUTABLE_ALIGNMENT ) 
                        poke( page_addr + page_offset, code[1..repi-1] & rep & code[repi+4..length(code)] )                             
                end if
                return page_offset + page_addr
        end ifdef
end function

