-- Normally, this test should simply create it's own ex.err by copying control.err but if the Interpreter was compiled in debug mode and matherr was available for compilation this should fail and the interpreter will create the ex.err file matching the control.err file.  As long as this test works as designed other bugs in the interpreter involving failing to check invalid values for math functions will be caught by this backup mechanism.  

include std/io.e
include std/machine.e
include std/dll.e
include std/utils.e
include std/filesys.e
constant cmds = command_line()
constant unit_test_name = cmds[2]
constant unit_test_directory = dirname(unit_test_name, 1)
constant control_file = unit_test_directory & SLASH & "t_c_singularity.d" & SLASH & "control.err"


-- Euphoria assert
type truth_type(object x)
    return not equal(x,0)
end type
truth_type truth

-- Returns zero on my machine.  Weird eh?
constant libc = open_dll("libc.so")
-- Used to return function offsets from the EUI binary
constant this_binary = 0

-- -1 on failure
constant logp = define_c_func(libc, "log", {C_DOUBLE}, C_DOUBLE)
truth = logp != -1

-- -1 on failure
constant matherrp = define_c_func(this_binary, "matherr", {C_DOUBLE}, C_DOUBLE)

constant _LIB_VERSION = define_c_var(this_binary, "_LIB_VERSION")
constant _SVID_ = 0

if _LIB_VERSION != -1 and matherrp != -1 and peek4u(_LIB_VERSION) = _SVID_ then
    printf(io:STDERR, "Note: Calling log()\n", {})
    -- May cause an error depending on the implementation of Euphoria
    atom inf = c_func(logp, {0})
    abort(0)
else

    -- fake an ex.err because we no longer have matherr
    atom err_fn = open(init_curdir() & SLASH & "ex.err", "w")
    atom control_err_fn = open(control_file, "r")
    object line
    while sequence(line) with entry do
        puts(err_fn, line)
    entry
        line = gets(control_err_fn)
    end while
    
    abort(1)
end if