include std/unittest.e
include std/cmdline.e
include std/map.e as map
include std/io.e
include std/filesys.e

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
constant extra_data = `
# Some 'extra' arguments
1  2 3
4 5
              
# The style argument and its file
--STYLE
"file.css"

"# not a comment"
'-i \abc\def\ghi'
`
constant optional_data = `
# Verbose on
-v
`
-- Deliberately using DOS line endings to test Unix's ability to process them correctly.
write_file("extra.txt", extra_data, DOS_TEXT)
write_file("optional.txt", optional_data, DOS_TEXT)
delete_file("nofile.txt") -- Ensure that this does not exist.
map:map opts = cmd_parse(option_defs, routine_id("opt_help"), 
				{"eui", 
				 "app.ex", 
				 "-d", 
				 "@@nofile.txt",
				 "-c:50", 
				 "@@optional.txt",
				 "-!d", 
				 "@extra.txt", 
				 "\\usr\\input.txt", 
				 "output.txt"
				} ) 
delete_file("extra.txt")
delete_file("optional.txt")

test_equal("cmd_parse() #1", 1, map:get(opts, "verbose"))
test_equal("cmd_parse() #2", "50", map:get(opts, "count"))
test_equal("cmd_parse() #3", "file.css", map:get(opts, "style"))
test_equal("cmd_parse() #4", {"1  2 3", "4 5", "# not a comment", "\\usr\\input.txt", "output.txt"}, map:get(opts, "extras"))
test_equal("cmd_parse() #5", 0, map:get(opts, "not_set"))
test_equal("cmd_parse() #6", 0, map:get(opts, "dummy"))
test_equal("cmd_parse() #7", 21, dummy)

test_equal("build_commandline #1", "abc def ghi", build_commandline({"abc", "def", "ghi"}))
test_equal("build_commandline #2", "abc \"def ghi\"", build_commandline({"abc", "def ghi"}))

test_equal("parse_commandline #1", { "-v", "-f", "%Y-%m-%d %H:%M" }, parse_commandline("-v -f '%Y-%m-%d %H:%M'"))

-- Reported bugs:
cmd_parse({}, {}, { "eui", "prog.ex", "bug", "-h" })
test_pass("cmd_parse bug #2790825")

-- Bug #2792895
integer bug_help_called = 0
procedure bug_help()
	bug_help_called = 1
end procedure

sequence validation_types = { VALIDATE_ALL, NO_VALIDATION, NO_VALIDATION_AFTER_FIRST_EXTRA }
sequence validation_type_names = { "VALIDATE_ALL", "NO_VALIDATION", "NO_VALIDATION_AFTER_FIRST_EXTRA" }
sequence help_strings = { "-h", "-?", "--help" }
sequence calls_help_rid_cmdl = { "bug", "-h" }
object map
for validate_i = 1 to length(validation_types) do
	for help_i = 1 to length(help_strings) do
		calls_help_rid_cmdl[2] = help_strings[help_i]
		for order_i = 1 to 2 do
			bug_help_called = 0
			-- here the help routine should get called that will set the flag.
			map = cmd_parse({{"v", "verbose", "Verbose output", {}}}, 
				{ HELP_RID, routine_id("bug_help"), 
				validation_types[validate_i] }, { "eui", "prog.ex" } &
				{calls_help_rid_cmdl[order_i],calls_help_rid_cmdl[3-order_i]})			
			-- However, if these parameters are set the help routine should
			-- not be called.
			if order_i = 1 and 
			validation_types[validate_i] = NO_VALIDATION_AFTER_FIRST_EXTRA then
				continue
			else
				
				test_true(
					sprintf("cmd_parse calls help routine " &
					" cmd_parse( ..., { HELP_RID, help_r_id, %s }, "&
					"{ \"eui\", \"prog.ex\", %s, %s } )",
						{
						validation_type_names[validate_i],
						calls_help_rid_cmdl[order_i],calls_help_rid_cmdl[3-order_i]}
						), -- end sprintf
						bug_help_called 
				) -- test_true
			end if
		end for
	end for
end for

-- For these next two calls the help routine should NOT get called.
bug_help_called = 0
map = cmd_parse({{"v", "verbose", "Verbose output", {}}}, { NO_VALIDATION_AFTER_FIRST_EXTRA ,
    HELP_RID, routine_id("bug_help")}, { "eui", "prog.ex", "bug", "-h" })
test_false("cmd_parse bug #2792895 ( NO_VAILDATION_AFTER_FIRST_EXTRA, { eui, bug, -h }) calls help",
	bug_help_called)

bug_help_called = 0
map = cmd_parse({{"v", "verbose", "Verbose output", {}}}, { NO_VALIDATION_AFTER_FIRST_EXTRA , 
    HELP_RID, routine_id("bug_help")}, { "eui", "prog.ex", "bug", "-?" })
test_false("cmd_parse bug #2792895 ( NO_VAILDATION_AFTER_FIRST_EXTRA, { eui, bug, -? }) calls help",
	bug_help_called)

cmd_parse( {{ 0, "html", "html output", { NO_PARAMETER }}}, -1, { "eui", "bug", "--html" })
test_pass("cmd_parse bug #2792287")

cmd_parse( {{ "i", 0, "include dir", { HAS_PARAMETER }}}, -1, { "eui", "eui", "-i",
	"/usr/euphoria", "bug.ex" })
test_pass("cmd_parse bug #2789982")

test_report()
