
ifdef WINDOWS then
with define SAFE
include std/unittest.e
include std/machine.e
include std/dll.e
include std/os.e


constant add_code = {
       -- first int argument is at stack offset +4, 2nd int is at +8 
       #8B, #44, #24, #04,        -- mov   eax, +4[esp]
       #03, #44, #24, #08,        -- add   eax, +8[esp]
       #C2, #00, #08 * platform() = WIN32 -- ret 8  -- pop 8 bytes off the stack
}
integer r
atom code_space
code_space = allocate(length(add_code))
poke(code_space,add_code) 
r = define_c_func("", code_space, {C_INT, C_INT}, C_INT)

test_pass("Should not be able to define a c function in non-executable memory")

elsedef

-- this test is Windows only, so it won't break on *nix.  Since it
-- has a control.err file, we'll just fake it.
include std/filesys.e
copy_file( "t_c_safe_c_func_nodep.d/control.err", "ex.err", 1 )
abort(1)
end ifdef
