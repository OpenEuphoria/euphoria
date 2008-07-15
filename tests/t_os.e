include std/unittest.e

without warning
sequence cmd_line
override function command_line()
    return cmd_line
end function
with warning

include std/os.e

integer verbose, help_called
sequence style_file, count, extras

-- Defaults
help_called = 0
verbose = 0
style_file = ""
count = ""

procedure opt_verbose()
    verbose = 1
end procedure

procedure opt_style(object param)
    style_file = param
end procedure

procedure opt_count(object param)
    count = param
end procedure

procedure opt_help()
    help_called = 1
end procedure

-- Option definition
sequence opts
opts = {
    { "v", "verbose",  "Verbose output",   NO_PARAMETER,  routine_id("opt_verbose") },
    { 0  , "style",    "Style sheet file", HAS_PARAMETER, routine_id("opt_style") },
    { "c", "count",    "Count",            HAS_PARAMETER, routine_id("opt_count") }
}

-- Parse command line

cmd_line = {"exu", "app.ex", "-v", "-c", "50", "--style", "file.css", "input.txt", "output.txt"}
extras = cmd_parse(opts, routine_id("opt_help"), cmd_line )
test_equal("cmd_parse() #1", 1, verbose)
test_equal("cmd_parse() #2", "50", count)
test_equal("cmd_parse() #3", "file.css", style_file)
test_equal("cmd_parse() #4", {"input.txt", "output.txt"}, extras)

test_equal("setenv() new", 1, setenv("EUTEST_EXAMPLE", "1"))
test_equal("getenv() #1", "1", getenv("EUTEST_EXAMPLE"))
test_equal("setenv() overwrite", 1, setenv("EUTEST_EXAMPLE", "2"))
test_equal("getenv() #2", "2", getenv("EUTEST_EXAMPLE"))
test_equal("setenv() no overwrite", 1, setenv("EUTEST_EXAMPLE", "3", 0))
test_equal("getenv() #3", "2", getenv("EUTEST_EXAMPLE"))
test_equal("unsetenv()", 1, unsetenv("EUTEST_EXAMPLE"))
test_equal("getenv() #4", -1, getenv("EUTEST_EXAMPLE"))

test_report()

