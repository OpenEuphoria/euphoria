include std/unittest.e
include std/cmdline.e
include std/map.e as map

without warning

override function command_line()
	return {"exu", "app.ex", "-v", "-c", "50", "--style", "file.css", "input.txt", "output.txt"}
end function
with warning

-- Option definition
sequence option_defs = {
    { "v", "verbose",  "Verbose output",   NO_PARAMETER },
    { 0  , "style",    "Style sheet file", HAS_PARAMETER },
    { "c", "count",    "Count",            HAS_PARAMETER }
}

-- Parse command line

map:map opts = cmd_parse(option_defs, routine_id("opt_help"), command_line() )
test_equal("cmd_parse() #1", 1, map:get(opts, "verbose"))
test_equal("cmd_parse() #2", "50", map:get(opts, "count"))
test_equal("cmd_parse() #3", "file.css", map:get(opts, "style"))
test_equal("cmd_parse() #4", {"input.txt", "output.txt"}, map:get(opts, "extras"))
test_equal("cmd_parse() #4", 0, map:get(opts, "not_set"))

test_equal("build_commandline #1", "abc def ghi", build_commandline({"abc", "def", "ghi"}))
test_equal("build_commandline #2", "abc \"def ghi\"", build_commandline({"abc", "def ghi"}))

test_report()
