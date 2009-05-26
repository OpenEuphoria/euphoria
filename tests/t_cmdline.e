include std/unittest.e
include std/cmdline.e
include std/map.e as map

integer dummy = 0
function got_dummy(sequence data)
	test_equal("cmd_parse() #7a", 5, data[OPT_IDX])
	test_equal("cmd_parse() #7b", 1, data[OPT_VAL])
	test_true("cmd_parse() #7c", data[OPT_CNT] <= 2)
	if data[OPT_CNT] = 1 then
		test_true("cmd_parse() #7d", data[OPT_REV] = 0)
	else
		test_true("cmd_parse() #7e", data[OPT_REV] = 1)
	end if
	dummy += 10 + data[OPT_REV]
	return 1
end function

-- Option definition
sequence option_defs = {
    { "v", "verbose",  "Verbose output",   {MANDATORY,NO_PARAMETER} },
    { 0  , "style",    "Style sheet file", {HAS_PARAMETER,"filename",NO_CASE} },
    { "c", "count",    "Count",            HAS_PARAMETER },
    { "i", 0,    "Include",            {HAS_PARAMETER,NO_CASE} },
    { "d", "dummy",    "Dummy Test",       {ONCE}, routine_id("got_dummy") },
    { 0,    0,         "At least one file name is also required.", {MANDATORY}}
    
}

-- Parse command line

map:map opts = cmd_parse(option_defs, routine_id("opt_help"), {"exu", "app.ex", "-i", "\\abc\\def\\ghi","-d", "/v", "-c:50", "--STYLE", "file.css", "-!d", "\\usr\\input.txt", "output.txt"} ) 
test_equal("cmd_parse() #1", 1, map:get(opts, "verbose"))
test_equal("cmd_parse() #2", "50", map:get(opts, "count"))
test_equal("cmd_parse() #3", "file.css", map:get(opts, "style"))
test_equal("cmd_parse() #4", {"\\usr\\input.txt", "output.txt"}, map:get(opts, "extras"))
test_equal("cmd_parse() #5", 0, map:get(opts, "not_set"))
test_equal("cmd_parse() #6", 0, map:get(opts, "dummy"))
test_equal("cmd_parse() #7", 21, dummy)

test_equal("build_commandline #1", "abc def ghi", build_commandline({"abc", "def", "ghi"}))
test_equal("build_commandline #2", "abc \"def ghi\"", build_commandline({"abc", "def ghi"}))

-- Reported bugs:
cmd_parse({}, {}, { "eui", "bug", "-h" })
test_pass("cmd_parse bug #2790825")

-- Bug #2792895
integer bug_help_called = 0
procedure bug_help()
	bug_help_called = 1
end procedure

cmd_parse({{"v", "verbose", "Verbose output", {}}}, routine_id("bug_help"), { "eui", "bug", "-h" })
test_false("cmd_parse bug #2792895", bug_help_called)

test_report()
