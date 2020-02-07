include std/unittest.e
include std/filesys.e
include std/io.e
include std/utils.e

constant full_cl = command_line()
constant test_file = full_cl[2]
ifdef WINDOWS then
    constant ext = ".exe"
elsedef
    constant ext = ""
end ifdef
constant naiive_dir = dirname(test_file)
constant testfile_dir = iif( equal(naiive_dir, ""), ".", naiive_dir)
constant return15_program = testfile_dir & SLASH & "return15" & ext
test_true(return15_program & " was found", file_exists( return15_program ) )
constant return15exe = return15_program
test_equal("Program that returns 15", 15, system_exec( return15_program, 2 ))

test_report()