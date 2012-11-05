#!/usr/bin/env eui
-- (c) Copyright - See License.txt

-- TODO: Extract log parsing code into it's own file
-- TODO: Use templates (with defaults supplied) for HTML reports, thus
--       users will be able to theme the unit test reports to fit into
--       their own project pages. Further, it will simplify the output
--       code quite a bit.
--
--       Why not use style sheets instead?

-- Increment version number with each release, not really with each change
-- in the SCM

constant APP_VERSION = "1.1.0"

include std/pretty.e
include std/sequence.e
include std/sort.e
include std/filesys.e as fs
include std/io.e
include std/get.e
include std/os.e as ut
include std/text.e 
include std/math.e
include std/search.e  as search
include std/error.e as e
include std/types.e as types
include std/map.e
include std/cmdline.e
include std/eds.e
include std/regex.e

ifdef UNIX then
	constant dexe = ""
elsifdef WINDOWS then
	constant dexe = ".exe"
end ifdef

constant cmdopts = {
	{ "eui",              0, "Interpreter command", { HAS_PARAMETER, "command" } },
	{ "eubin",            0, "Euphoria binary directory", { HAS_PARAMETER, "directory" } },
	{ "eubind",           0, "Binder command", { HAS_PARAMETER, "command" } },
	{ "eub",              0, "Path to backend runner", { HAS_PARAMETER, "command" } },
	{ "euc",              0, "Translator command", { HAS_PARAMETER, "command" } },
	{ "trans",            0, "Translate using default translator", { } },
	{ "cc",               0, "C compiler (wat or gcc)", { HAS_PARAMETER, "compiler name" } },
	{ "lib",              0, "Runtime library path", { HAS_PARAMETER, "library" } },
	{ "i",                0, "Include directory", { MULTIPLE, HAS_PARAMETER, "directory" }},
	{ "d",                0, "Define a preprocessor word", { MULTIPLE, HAS_PARAMETER, "word" }},
	{ "testopt",          0, "Option for tester", { HAS_PARAMETER, "test-opt"} },
	{ "retest",           0, "Option to run the tests again on all that failed on the last run",
								{ } },
	{ HEADER,                "Control the output" },
	{ "all",              0, "Show tests that pass and fail", {} },
	{ "failed",           0, "Show tests that fail only", {} },
	{ "accumulate",       0, "Count the individual tests in each file", {} },
	{ "wait",             0, "Wait on summary", {} },
	{ HEADER,                "Logging" },
	{ "log",              0, "Enable logging", { } },
	{ "process-log",      0, "Process log instead of running tests", { } },
	{ "html",             0, "Enable HTML output mode", { } },
	{ "html-file",        0, "Output file for html log output", { HAS_PARAMETER, "filename" } },
	{ HEADER,                "Test Coverage" },
	{ "coverage",         0, "Indicate files or directories for which to gather coverage statistics", 
	                         { MULTIPLE, HAS_PARAMETER, "dir|file" } },
	{ "coverage-db",      0, "Specify the filename for the coverage database.", 
	                         { HAS_PARAMETER, "file" } },
	{ "coverage-erase",   0, "Erase an existing coverage database and start a new coverage analysis.", 
	                         { } },
	{ "coverage-pp",      0, "Coverage post-processor (eucoverage?)", { HAS_PARAMETER, "filename"} },
	{ "coverage-exclude", 0, "Pattern for files to exclude from coverage", { MULTIPLE, HAS_PARAMETER, "pattern"}},
	{ HEADER,                "Deprecated options (will be removed in 1.1.0)" },
	{ "exe",              0, "Interpreter path", { HAS_PARAMETER, "command" } },
	{ "bind",             0, "Path to eubind", { HAS_PARAMETER, "command"} },
	{ "ec",               0, "Translator path",  { HAS_PARAMETER, "command" } },
	{ HEADER,                "Miscellaneous" },
	{ "verbose",          0, "Verbose output", { } },
	{ "n",        "nocheck", "Don't check the supplied interpreter, translator, binder", {} },
	{ "v",        "version", "Display the version number", { VERSIONING, "eutest v" & APP_VERSION } },
	$
}

constant USER_BREAK_EXIT_CODES = {255,-1073741510}
integer verbose_switch = 0
object void
integer ctcfh = 0
sequence error_list = repeat({},4)
sequence eub_path = ""
sequence exclude_patterns = {}
integer no_check = 0
object html_filename = 0 

-- moved from do_test:
integer logging_activated = 0
integer failed = 0
integer total
sequence 
	executable = ""

integer html_fn = 1

enum E_NOERROR, E_INTERPRET, E_TRANSLATE, E_COMPILE, E_EXECUTE, E_BIND, E_BOUND, E_EUTEST

type error_class(object i)
	return integer(i) and i >= 1 and i <= E_EUTEST
end type

procedure error(sequence file, error_class e, sequence message, sequence vals, object error_file = 0)
	object lines
	integer bad_string_flag = 0
	if sequence(error_file) then
		lines = read_lines(error_file)
	else
		lines = 0
	end if

	for i = 1 to length(vals) do
		-- assume only nested sequences of vals[i] to be bad.
		if not atom(vals[i]) and not ascii_string(vals[i]) then
			bad_string_flag = 1
		end if
	end for
	if bad_string_flag then
	    for i = 1 to length(vals) do
	    	vals[i] = pretty_sprint(vals[i], {2} )
	    end for
	end if
	
	error_list = {
		append(error_list[1], file),
		append(error_list[2], sprintf(message, vals)),
		append(error_list[3], e),
		append(error_list[4], lines)
	}
end procedure

procedure verbose_printf(integer fh, sequence fmt, sequence data={})
	if verbose_switch then
		printf(fh, fmt, data)
	end if
end procedure

-- runs cmd using system exec tests for returned error values
-- and error files.  Before the command is run, the error files
-- are deleted and just before the functions exits the error 
-- files are deleted unless REC is defined.
-- returns 0 if no errors were raised
function invoke(sequence cmd, sequence filename, integer err)
	integer status
	
	delete_file("cw.err")
	delete_file("ex.err")

	status = system_exec(cmd, 2)
	if find(status, USER_BREAK_EXIT_CODES) > 0 then
		-- user break
		abort(status)
	end if

	sleep(0.1)
	
	if file_exists("cw.err") then
		error(filename, err, "Causeway error with status %d", {status}, "cw.err")

		if not status then
			status = 1
		end if

		ifdef not REC then
			delete_file("cw.err")
		end ifdef

	elsif file_exists("ex.err") then
		error(filename, err, "EUPHORIA error with status %d", {status}, "ex.err")

		if not status then
			status = 1
		end if

		ifdef not REC then
			delete_file("ex.err")
		end ifdef

	elsif status then
		error(filename, err, "program died with status %d", {status})
	end if
	
	return status
end function

-- returns the location in the log file if there has been
-- writing to the log or or a string indicating which error 
function check_log(integer log_where)

	integer log_fd = open("unittest.log", "a")
	atom pos
					
	if log_fd = -1  then
		return "couldn't generate unittest.log"
	else
		pos = where(log_fd)
		if log_where = pos then
			close(log_fd)
			return  "couldn't add to unittest.log"
		end if
	end if	

	log_where = where(log_fd)
	close(log_fd)

	return log_where
end function

procedure report_last_error(sequence filename)
	if length(error_list) and length(error_list[3])  then
		if error_list[3][$] = E_NOERROR then
			verbose_printf(1, "SUCCESS: %s %s\n", {filename, error_list[2][length(error_list[1])]})
		else
			printf(1, "FAILURE: %s %s\n", {filename, error_list[2][length(error_list[1])]})
		end if
	end if
end procedure

function prepare_error_file(object file_name)
	integer pos
	object file_data
	
	file_data = read_lines(file_name)
	
	if atom(file_data) then
		return file_data
	end if
	
	if length(file_data) > 4 then
		file_data = file_data[1..4]
	end if
	for i = 1 to length(file_data) do
		pos = find('=', file_data[i])
		if pos then
			if length(file_data[i]) >= 6 then
				if equal(file_data[i][1..4], "    ") then
					file_data = file_data[1 .. i-1]
					exit
				end if
			end if
		end if
		if find(file_data[i], {"Global & Local Variables","Public & Export & Global & Local Variables", "--- Defined Words ---"}) then
			file_data = file_data[1 .. i-1]
			exit
		end if
	end for
	
    sequence path, base_path
    if length(file_data) >= 2 then
    	path = "\\/" & file_data[1]
    	base_path = path[3..max(rfind('/', path) & rfind('\\', path))]
    	path = path[max(rfind('/', path) & rfind('\\', path))+1..$]
    	file_data[1] = path
    else
    	-- Malformed error file
    	file_data = 0
    end if
    
    if not equal(base_path,"") then
	    for i = 1 to length(file_data) do
    		file_data[i] = search:match_replace(base_path, file_data[i], "", 1000)
		end for
	end if
    
    return file_data
end function

function check_errors( sequence filename, sequence fail_list )
	object expected_err
	object actual_err
	integer some_error = 0
	
	expected_err = prepare_error_file( find_error_file( filename ) )
	if atom(expected_err) then
		error(filename, E_INTERPRET, No_valid_control_file_was_supplied, {})
		some_error = 1
	elsif length(expected_err) = 0 then
		error(filename, E_INTERPRET, Unexpected_empty_control_file, {})
		some_error = 1
	end if
	
	if not some_error then
		actual_err = prepare_error_file("ex.err")
		if atom(actual_err) then
			error(filename, E_INTERPRET, No_valid_exerr_has_been_generated, {})
			some_error = 1
		elsif length(actual_err) = 0 then
			error(filename, E_INTERPRET, Unexpected_empty_exerr, {})
			some_error = 1
		end if
	
		if not some_error then
			-- N.B. Do not compare the first line as it contains PATH 
			-- information which can vary from system to system.			
			if not equal(actual_err[2..$], expected_err[2..$]) then
				error(filename, E_INTERPRET, differing_ex_err_format,
						{join(expected_err,"\n"), join(actual_err, "\n")}, "ex.err")
				some_error = 1
			end if
		end if
	end if
	
	if some_error then	
		failed += 1
		fail_list = append(fail_list, filename)
	end if
	return fail_list
end function

function find_error_file( sequence filename )
	sequence control_error_file
	sequence base_filename
	
	base_filename = filename[1 .. find('.', filename & '.') - 1] & ".d" & SLASH
	
	-- try tests/t_test.d/interpreter/UNIX/control.err
	control_error_file =  base_filename & "interpreter" & SLASH & interpreter_os_name & SLASH & "control.err"
	if file_exists(control_error_file) then
		return control_error_file
	end if
	
	-- try tests/t_test/UNIX/control.err
	control_error_file =  base_filename & interpreter_os_name & SLASH & "control.err"
	if file_exists(control_error_file) then
		return control_error_file
	end if

	-- try tests/t_test/control.err
	control_error_file = base_filename & "control.err"
	if file_exists(control_error_file) then
		return control_error_file
	end if

	return -1
end function

-- execute cmd and using the control file that corresponds to the test file //filename//, 
-- check that the results match the newly generated ex.err and that there is one generated.
-- Unless both of these conditions are met, an error is recorded.
function interpret_fail( sequence cmd, sequence filename,  sequence fail_list )
	integer status = system_exec(cmd, 2)
	integer old_length
	
	-- Now we will compare the control error file to the newly created 
	-- ex.err.  If ex.err doesn't exist or there is no match error()
	-- is called and we add to the failed list.
	old_length = length( fail_list )
	fail_list = check_errors( filename, fail_list )

	if old_length = length( fail_list ) then
		-- No new errors found.
		if status = 0 then
			-- We were expecting the test program to crash, but it didn't.
			failed += 1
			fail_list = append(fail_list, filename)
			error(filename, E_INTERPRET,
				"The unit test did not crash, which was unexpected.", {})
		else						
			error(filename, E_NOERROR, "The unit test crashed in the expected manner. " &
				"Error status %d.", {status})
		end if
	end if
	return fail_list
end function

function translate( sequence filename, sequence fail_list )
	printf(1, "\ntranslating %s:", {filename})
	total += 1
	sequence exename = filebase(filename) & "-translated" & dexe
	sequence cmd
	if ends(".ex", translator) then
		cmd = sprintf("eui -batch \"%s\" %s %s %s -d UNITTEST -d EC -batch %s -o %s",
		{ translator, library, compiler, translator_options, filename, exename })
	else
		cmd = sprintf("%s %s %s %s -d UNITTEST -d EC -batch %s -o %s",
		{ translator, library, compiler, translator_options, filename, exename })
	end if
	verbose_printf(1, "CMD '%s'\n", {cmd})
	integer status = system_exec(cmd, 0)

	filename = filebase(filename)

	integer log_where = 0
	if status = 0 then
		void = delete_file("cw.err")
		verbose_printf(1, "executing %s:\n", {exename})
		cmd = sprintf("./%s %s", {exename, test_options})
		status = invoke(cmd, exename,  E_EXECUTE) 
		if status then
			failed += 1
			fail_list = append(fail_list, "translated" & " " & exename)
		else
			object token
			if logging_activated then
				token = check_log(log_where)
			else
				token = 0
			end if

			if sequence(token) then
				failed += 1
				fail_list = append(fail_list, "translated" & " " & exename)					
				error(exename, E_EXECUTE, token, {}, "ex.err")
			else
				log_where = token
				error(exename, E_NOERROR, "all tests successful", {})
			end if -- sequence(token)

			puts(1, "\n")
		end if
		
		void = delete_file(exename)
	else
		failed += 1
		fail_list = append(fail_list, "translating " & filename)
		error(filename, E_TRANSLATE, "program translation terminated with a bad status %d", {status})                               
	end if
	report_last_error(filename)
	return fail_list
end function

function bind( sequence filename, sequence fail_list )
	printf(1, "\nbinding %s:\n", {filename})
	sequence exename = fs:filebase(filename) & "-bound" & dexe
	sequence cmd
	if ends(".ex", binder) then
		cmd = sprintf("eui -batch \"%s\" %s %s -batch -d UNITTEST %s -out %s",
		{ binder, eub_path, interpreter_options, filename, exename } )
	else
		cmd = sprintf("\"%s\" %s %s -batch -d UNITTEST %s -out %s",
		{ binder, eub_path, interpreter_options, filename, exename } )
	end if
	total += 1
	verbose_printf(1, "CMD '%s'\n", {cmd})
	integer status = system_exec(cmd, 0)

	filename = filebase(filename)
	integer log_where = 0
	if status = 0 then
		verbose_printf(1, "executing %s:\n", {exename})
		cmd = sprintf("./%s %s", {exename, test_options})
		status = invoke(cmd, exename,  E_EXECUTE) 
		if status then
			failed += 1
			fail_list = append(fail_list, "bound" & " " & exename)
		else
			object token
			if logging_activated then
				token = check_log(log_where)
			else
				token = 0
			end if

			if sequence(token) then
				failed += 1
				fail_list = append(fail_list, "bound" & " " & exename)					
				error(exename, E_BOUND, token, {}, "ex.err")
			else
				log_where = token
				error(exename, E_NOERROR, "all tests successful", {})
			end if -- sequence(token)
		end if
			
		void = delete_file(exename)
		
	else
		failed += 1
		fail_list = append(fail_list, "binding " & filename)
		error(filename, E_BIND, "program binding terminated with a bad status %d", {status})                               
	end if
	report_last_error(filename)
	return fail_list
end function

function test_file( sequence filename, sequence fail_list )

	integer log_where = 0 -- keep track of unittest.log
	integer status
	void = delete_file("ex.err")
	void = delete_file("cw.err")
	
	sequence crash_option = ""
	if match("t_c_", filename) = 1 then
		crash_option = " -d CRASH "
	end if
	
	printf(1, "\ninterpreting %s:\n", {filename})
	sequence cmd = sprintf("%s %s %s -d UNITTEST -batch %s%s %s",
		{ executable, interpreter_options, coverage_erase, crash_option, filename, test_options })

	verbose_printf(1, "CMD '%s'\n", {cmd})
	
	integer expected_status
	if match("t_c_", filename) = 1 then
		-- We expect this test to fail
		expected_status = 1
		sequence old_fail_list = fail_list
		fail_list = interpret_fail( cmd, filename, fail_list )
		
		ifdef REC then
			if compare(old_fail_list, fail_list) then
				sequence directory = filename[1..find('.',filename&'.')] & "d" & SLASH & interpreter_os_name
				
				create_directory(directory)
				
				if not move_file("ex.err", directory & SLASH & "control.err") then
						e:crash("Could not move 'ex.err' to %s", { directory & SLASH & "control.err" })
				end if
			end if
		end ifdef
		
	else -- not match(t_c_*.e)
		-- in this branch error() is called once and only once in all sub-branches
		expected_status = 0
		status = invoke(cmd, filename, E_INTERPRET) -- error() called if status != 0

		if status then
			failed += 1
			fail_list = append(fail_list, filename)
			-- error() called in invoke()
		else
			object token
			if logging_activated then
				token = check_log(log_where)
			else
				token = 0
			end if

			if sequence(token) then
				failed += 1
				fail_list = append(fail_list, filename)					
				error(filename, E_INTERPRET, token, {}, "ex.err")
			else
				log_where = token
				error(filename, E_NOERROR, "all tests successful", {})
			end if
		end if
	end if

	report_last_error(filename)
	
	if length(binder) and expected_status = 0 then
		fail_list = bind( filename, fail_list )
	end if
	
	if length(translator) and expected_status = 0 then
		fail_list = translate( filename, fail_list )
	end if
	
	return fail_list
end function

sequence interpreter_options = ""
sequence translator_options = ""
sequence test_options = ""
sequence translator = "", library = "", compiler = ""
sequence interpreter_os_name

sequence binder = ""
sequence coverage_db    = ""
sequence coverage_pp    = ""
sequence coverage_erase = ""

procedure ensure_coverage()
	-- ensure that everything was at least included
	if DB_OK != db_open( coverage_db ) then
		printf( 2, "Error reading coverage database: %s\n", {coverage_db} )
		return
	end if
	
	sequence tables = db_table_list()
	integer ix = 1
	while ix <= length(tables) do
		sequence table_name = tables[ix]
		if table_name[1] = 'l' 
		and db_table_size( table_name ) = 0 then
			ix += 1
		else
			tables = remove( tables, ix )
		end if
	end while
	db_close()
	interpreter_options &= " -test"
	for tx = 1 to length( tables ) do
		
		sequence table_name = tables[tx]
		if not is_excluded( table_name[2..$] ) then
			test_file( table_name[2..$], {} )
		end if
	end for
end procedure

function is_excluded( sequence file )
	for i = 1 to length( exclude_patterns ) do
		if regex:has_match( exclude_patterns[i], file ) then
			return 1
		end if
	end for
	return 0
end function

procedure process_coverage()
	if not length( coverage_db ) then
		return
	end if
	
	ensure_coverage()
	
	if not length( coverage_pp ) then
		return
	end if
	
	-- post process the database
	if system_exec( sprintf(`%s "%s"`, { coverage_pp, coverage_db }), 2 ) then
		puts( 2, "Error running coverage postprocessor\n" )
		printf(2,`CMD: %s "%s"`, { coverage_pp, coverage_db })
	end if
end procedure

procedure do_test( sequence files )
	atom score
	integer first_counter = length(files)+1
	integer log_fd = 0
	sequence respc
	
	total = length(files)

	if verbose_switch <= 0 then
		translator_options &= " -silent"
	end if

	sequence fail_list = {}
	if logging_activated then
		void = delete_file("unittest.dat")
		void = delete_file("unittest.log")
		void = delete_file("ctc.log")
		ctcfh = open("ctc.log", "w")
	end if

	for i = 1 to length(files) do
		fail_list = test_file( files[i], fail_list )
		coverage_erase = ""
	end for
	
	if logging_activated and ctcfh != -1 then
		print(ctcfh, error_list)
		puts(ctcfh, 10)

		if length(translator) > 0 then
			print(ctcfh, total)
		else
			print(ctcfh, 0)
		end if

		close(ctcfh)
	end if

	ctcfh = 0
	
	if total = 0 then
		score = 100
	else
		score = ((total - failed) / total) * 100
	end if

	puts(1, "\nTest results summary:\n")

	for i = 1 to length(fail_list) do
		printf(1, "    FAIL: %s\n", {fail_list[i]})
	end for

	if failed != 0 then
		respc = sprintf("%1.f%%", score)
		if equal(respc, "100%") then
			-- this can happen when the number of files is huge and the number of fails is tiny.
			respc = "99.99%"
		end if
		printf(1, "Files (run: %d) (failed: %d) (%s success)\n", {total, failed, respc})
	else
		printf(1, "Files (run: %d) (failed: 0) (100%% success)\n", total)
	end if

	object temps, ln = read_lines("unittest.dat")
	if sequence(ln) then
		total = 0
		failed = 0

		for i = 1 to length(ln) do
			temps = value(ln[i])
			if temps[1] = GET_SUCCESS then
				total += temps[2][1]
				failed += temps[2][2]
			end if
		end for

		if total = 0 then
			score = 100
		else
			score = ((total - failed) / total) * 100
		end if

		if failed != 0 then
			respc = sprintf("%1.f%%", score)
			if equal(respc, "100%") then
				-- this can happen when the number of tests is huge and the number of fails is tiny.
				respc = "99.99%"
			end if
			printf(1, "Tests (run: %d) (failed: %d) (%s success)\n", {total, failed, respc})
		else
			printf(1, "Tests (run: %d) (failed: 0) (100%% success)\n", total)
		end if
	end if
	
	process_coverage()
	
	abort(failed > 0)
end procedure

sequence unsummarized_files = {}

constant ascii_table_final_summary =  repeat('*', 76) & "\n\n" & "Overall: Total Tests: %04d  Failed: %04d  Passed: %04d Time: %f\n\n" & repeat('*', 76) & "\n\n"

procedure ascii_out(sequence data)
	switch data[1] do
		case "open" then
			-- do nothing.
		case "file" then
			unsummarized_files = append(unsummarized_files, data[2])
			printf(1, "%s\n", { data[2] })
			puts(1, repeat('=', 76) & "\n")

			if find(data[2], error_list[1]) then
				printf(1,"%s\n",
				{ error_list[2][find(data[2],error_list[1])] })
			end if

		case "failed" then
			printf(1, "  Failed: %s (%f) expected ", { data[2], data[5] })
			pretty_print(1, data[3], {2, 2, 12, 78, "%d", "%.15g"})
			puts(1, " got ")
			pretty_print(1, data[4], {2, 2, 12, 78, "%d", "%.15g"})
			puts(1, "\n")

		case "passed" then
			sequence anum
			if data[3] = 0 then
				anum = "0"
			else
				anum = sprintf("%f", data[3])
			end if
			printf(1, "  Passed: %s (%s)\n", { data[2], anum })

		case "summary" then
			puts(1, repeat('-', 76) & "\n")

			if length(unsummarized_files) then
				unsummarized_files = unsummarized_files[1..$-1]
			end if

			sequence status
			if data[3] > 0 then
				status = "bad"
			else
				status = "ok"
			end if

			printf(1, "  (Tests: %04d) (Status: %3s) (Failed: %04d) (Passed: %04d) (Time: %f)\n\n", {
				data[2], status, data[3], data[4], data[5]
			})
	end switch
end procedure

procedure ascii_close()
	if html_fn != 1 then
		close(html_fn)
	end if
end procedure

procedure ascii_open()
	if sequence(html_filename) then
		html_fn = open(html_filename, "w")
	end if
end procedure

function ascii_new_line()
	return "\n"
end function

function ascii_link(sequence link, sequence text)
	return text
end function

type sequence_of_non_empty_strings(sequence s)
	for i = 1 to length(s) do
		 t_bytearray si = s[i]
	end for
	return 1
end type
			
sequence_of_non_empty_strings retest_files = {}
procedure prepare_retest(sequence data)
	switch data[1] do
		case "file" then
			unsummarized_files = append(unsummarized_files, data[2])

		case "failed" then

		case "passed" then

		case "summary" then
			if length(unsummarized_files) then
				if data[3] > 0 then
					retest_files = append(retest_files,unsummarized_files[$])
				end if
				unsummarized_files = unsummarized_files[1..$-1]
			end if
	end switch
end procedure

procedure do_nothing1(object x1)
end procedure

function empty_string() -- for DOCUMENT_NL, DOCUMENT_P
	return ""
end function

function retest_link(sequence link, sequence text) -- for DOCUMENT_LINK
	return ""
end function

procedure retest_open()
	ifdef UNIX then
		html_fn = open("/dev/null", "w")
	elsedef
		html_fn = open("NUL", "w")
	end ifdef
end procedure

procedure retest_close()
	close(html_fn)
	html_fn = 1
end procedure

function text2html(sequence t)
	integer f = length(t)

	while f do
		if t[f] = '<' then
			t = t[1..f-1] & "&lt;" & t[f+1..$]
		elsif t[f] = '>' then
			t = t[1..f-1] & "&gt;" & t[f+1..$]
		elsif t[f] > 127 then
			t = t[1..f-1] & sprintf("&#%x;", t[f..f]) & t[f+1..$]
		elsif t[f] = 10 then
			t = t[1..f-1] & "<br>" & t[f+1..$]
		end if

		f = f - 1
	end while

	return t
end function

constant no_error_color = "#aaffaa"
constant error_color =  "#ffaaaa"
sequence html_table_head = `
<table width=100%%>
<tr bgcolor=#dddddd>
<th colspan=3 align=left><a name='%s'>%s</a></th>
<td><a href='#summary'>all file summary</a></th>
</tr>`

constant html_table_headers = `<tr bgcolor=#dddddd><th>test name</th>
<th>test time</th>
<th>expected</th>
<th>outcome</th>
</tr>`

constant html_error_table_begin = `
</DOCUMENT_P><table width='100%%'>
<tr bgcolor="` & error_color & `">
<th width='78%%' align='left'><a name='%s'>%s</a></th>
<td bgcolor="` & no_error_color & `" align='left'><a href='#summary'>all file summary</a></td></tr>
</table>
<table width='100%%'>`

constant No_valid_control_file_was_supplied = "No valid control file was supplied."
constant Unexpected_empty_control_file = "Unexpected empty control file."
constant No_valid_exerr_has_been_generated = "No valid ex.err has been generated."
constant Unexpected_empty_exerr = "Unexpected empty ex.err."
constant differing_ex_err_format = "Unexpected ex.err.  Expected:\n----\n%s\n----\nbut got\n----\n%s\n----\n"
constant differing_ex_err_pattern = regex:new(sprintf(differing_ex_err_format,{"(.*)","(.*)"}), regex:DOTALL)
constant html_unexpected_exerr_table_begin = 
html_error_table_begin &
`
<tr><th width="50%%" colspan='1' bgcolor="#dddddd">expected ex.err</th><th colspan='1' bgcolor="` & error_color & `">outcome ex.err</th></tr>`
constant html_unexpected_exerr_row_format = "<tr><td bgcolor=\"#dddddd\" colspan='1' ><pre>%s</pre></td><td bgcolor=\"" & error_color & "\" bcolspan='1' ><pre>%s</pre></td></tr>"

constant html_unexpected_exerr_table_end = `
</table>
`

constant html_error_table_end = html_unexpected_exerr_table_end
constant html_table_error_row = `
<tr bgcolor="%s">
<th align="left" width="50%%">%s</td>
<td colspan="3">%s</td>
</tr>`

sequence html_table_error_content_begin = `
<tr bgcolor="#ffaaaa">
  <th colspan="4" align="left" width="50%">
    Error file contents follows below
  </th>
</tr>
<tr bgcolor="#ffaaaa">
  <td colspan="4" align="left" width="100%">
    <pre>
`

sequence html_table_error_content_end = `
	</pre>
  </td>
</tr>
`

sequence html_table_failed_row = `
<tr bgcolor="#ffaaaa">
  <th align=left width=50%%>%s</th>
  <td>%f</td>
  <td>%s</td>
  <td>%s</td>
</tr>
`

sequence html_table_passed_row = `
<tr bgcolor="#aaffaa">
  <th align=left width=50%%>%s</th>
  <td>%s</td>
  <td>&nbsp;</td>
  <td>&nbsp;</td>
</tr>
`

sequence html_table_summary = `
</table>
<p>
<strong>Tests:</strong> %04d
<strong>Failed:</strong> %04d
<strong>Passed:</strong> %04d
<strong>Time:</strong> %f
</p>`

sequence html_table_final_summary = `
<a name="summary"></a>
<table style="font-size: 1.5em">
  <tr>
	<th colspan="2" align="left">Overall</th>
  </tr>
  <tr>
	<th align="left">Total Tests:</th>
	<td>%04d</td>
  </tr>
  <tr>
	<th align="left">Total Failed:</th>
	<td>%04d</td>
  </tr>
  <tr>
	<th align="left">Total Passed:</th>
	<td>%04d</td>
  </tr>
  <tr>
	<th align="left">Total Time:</th>
	<td>%f</td>
  </tr>
</table>
</body>
</html>`

procedure html_out(sequence data)
	switch data[1] do
		case "file" then

			integer err = find(data[2], error_list[1])
			if err then
				sequence color
				if error_list[3][err] = E_NOERROR then
					color = no_error_color
				else
					color = error_color
				end if
				
				object ex_err = regex:matches(differing_ex_err_pattern, error_list[2][err])
				if sequence(ex_err) then
					printf(html_fn, html_unexpected_exerr_table_begin, {data[2], data[2]} )
					printf(html_fn, html_unexpected_exerr_row_format, ex_err[2..3])
					printf(html_fn, html_unexpected_exerr_table_end, {} )			
				elsif find(error_list[2][err], {No_valid_control_file_was_supplied, Unexpected_empty_control_file, No_valid_exerr_has_been_generated, Unexpected_empty_exerr}) then
					printf(html_fn, html_error_table_begin, {data[2], data[2]} )
					printf(html_fn, html_table_error_row, {color, "", error_list[2][err]} )
					printf(html_fn, html_error_table_end, {} )
					unsummarized_files = append(unsummarized_files, data[2])
				else
					printf(html_fn, html_table_head, { data[2], data[2] })
					printf(html_fn, html_table_error_row, { color, "", error_list[2][err] })
					puts(html_fn, html_table_headers )
					
					if sequence(error_list[4][err]) then
						puts(html_fn, html_table_error_content_begin)
	
						for i = 1 to length(error_list[4][err]) do
							printf(html_fn,"%s\n", { text2html(error_list[4][err][i]) })
						end for
	
						puts(html_fn, html_table_error_content_end)
					end if
					unsummarized_files = append(unsummarized_files, data[2])

				end if
				
			else
				printf(html_fn, html_table_head, { data[2], data[2] })
				unsummarized_files = append(unsummarized_files, data[2])

			end if

		case "failed" then
			printf(html_fn, html_table_failed_row, {
				data[2],
				sprint(data[5]),
				sprint(data[3]),
				sprint(data[4])
			})

		case "passed" then
			sequence anum

			if data[3] = 0 then
				anum = "0"
			else
				anum = sprintf("%f", data[3])
			end if

			printf(html_fn, html_table_passed_row, { data[2], anum })

		case "summary" then
			if length(unsummarized_files) then
				unsummarized_files = unsummarized_files[1..$-1] 
			end if
			
			printf(html_fn, html_table_summary, {
				data[2],
				data[3],
				data[4],
				data[5]
			})
						
	end switch
end procedure

procedure html_open()
	if sequence(html_filename) then
		html_fn = open(html_filename, "w")
	end if
	puts(html_fn, "<html><body>\n")
end procedure

procedure html_close()
	puts(html_fn, "</html></body>\n")
	if html_fn != 1 then
		close(html_fn)
	end if
end procedure

function html_new_line()
	return "<br>\n"
end function

function html_link(sequence link, sequence text)
	return sprintf("<a href='%s'>%s</a>", {link,text})
end function

function html_p()
	return "<p>\n"
end function



procedure summarize_error(sequence output_class, sequence message, error_class e)
	if find(e, error_list[3]) then
		printf(html_fn,message & call_func(output_class[DOCUMENT_NL],{}) & "These were:\n", {sum(error_list[3] = e)})

		for i = 1 to length(error_list[1]) do
			if error_list[3][i] = e then
				printf(html_fn, "%s ", {call_func(output_class[DOCUMENT_LINK],{ "#" & error_list[1][i], error_list[1][i] })})
			end if
		end for

		puts(html_fn, call_func(output_class[DOCUMENT_P],{}))
	end if
end procedure

procedure do_process_log( sequence cmds, sequence output_class)
	object other_files = {}
	integer total_failed=0, total_passed=0
	integer out_r
	atom total_time = 0
	object ctc
	sequence messages
	
	out_r = output_class[DOCUMENT_PROCESS]
	call_proc(output_class[DOCUMENT_OPEN],{})

	ctcfh = open("ctc.log","r")
	if ctcfh != -1 then
		ctc = stdget:get(ctcfh)

		if ctc[1] = GET_SUCCESS then
			ctc = ctc[2]
			error_list = ctc

			ctc = stdget:get(ctcfh)
			if ctc[1] != GET_SUCCESS then
				ctc = 0
			end if
		else
			ctc = 0
		end if

		close(ctcfh)
	else
		ctc = 0
		ctcfh = 0
	end if
	
	other_files = error_list[1]

	object content = read_file("unittest.log")
	if atom(content) then
		puts(1, "unittest.log could not be read\n")
	else 
   
		messages = stdseq:split( content,"entry = ")
		for a = 1 to length(messages) do
			if sequence(messages[a]) and equal(messages[a], "") then
				continue
			end if
	
			sequence data = value(messages[a])
			if data[1] = GET_SUCCESS then
				data = data[2]
			else
				puts(1, "unittest.log could not parse:\n")
				pretty_print(1, messages[a], {3})
				abort(1)
			end if
	
			switch data[1] do
				case "failed" then
					total_failed += 1
					total_time += data[5]
	
				case "passed" then
					total_passed += 1
					total_time += data[3]
				
				case "file" then
					integer ofi = find(data[2], other_files)
					if ofi != 0 then
						other_files = other_files[1..ofi-1] & other_files[ofi+1..$]
					end if

					while length(unsummarized_files)>=1 and compare(data[2],unsummarized_files[1])!=0 do
						call_proc(out_r, {{"summary",0,0,0,0}})
					end while
			end switch
	
			call_proc(out_r, {data})
		end for
	end if

	while length(unsummarized_files) do
		call_proc(out_r, {{"summary",0,0,0,0}})
	end while
	
	for i = 1 to length(other_files) do
		if find(other_files[i], error_list[1]) then
			call_proc(out_r, {{"file",other_files[i]}})
			call_proc(out_r, {{"summary",0,0,0,0}})
		end if
	end for
	
	summarize_error(output_class, "Interpreted test files failed unexpectedly.: %d", E_INTERPRET)
	summarize_error(output_class, "Test files could not be translated.........: %d", E_TRANSLATE)
	summarize_error(output_class, "Translated test files could not be compiled: %d", E_COMPILE)  
	summarize_error(output_class, "Compiled test files failed unexpectedly....: %d", E_EXECUTE)  
	summarize_error(output_class, "Test files could not be bound..............: %d", E_BIND)    
	summarize_error(output_class, "Bound test files failed unexpectedly.......: %d", E_BOUND)   
	summarize_error(output_class, "Test files run successfully................: %d", E_NOERROR)  
	
	if find(1, error_list[3] = E_EUTEST) then
		printf(html_fn, "There was an internal error to the testing system involving %s%s",
			{ error_list[1][find(E_EUTEST, error_list[3])], call_func(output_class[DOCUMENT_NL],{}) })
	end if

	if sequence(output_class[DOCUMENT_ENDING]) then
		printf(html_fn, output_class[DOCUMENT_ENDING], {
			total_passed + total_failed,
			total_failed,
			total_passed,
			total_time
		})
	end if
	
	call_proc(output_class[DOCUMENT_CLOSE], {})
end procedure

procedure platform_init()
	if equal( executable, "" ) then
		executable = "eui"
	end if
	
	if equal(translator, "-") then
		translator = "euc" & dexe
	end if	

	-- Check for various executable names to see if we need -CON or not
	
	-- lower for Windows or DOS, lower for all.  K.I.S.S.

	ifdef UNIX then
		interpreter_os_name = "UNIX"

	elsifdef WINDOWS then
		if length(translator) > 0 then
			translator_options &= " -CON"
		end if
		
		interpreter_os_name = "WINDOWS"

	elsedef
		puts(2, "eutest is only supported on Unix and Windows.\n")
		abort(1)
	end ifdef
	
end procedure

function build_file_list( sequence list )
	sequence files = {}

	for j = 1 to length( list ) do
		
		if file_type( list[j] ) = FILETYPE_DIRECTORY then
			object dirlist = dir( list[j] )
		
			if sequence( dirlist ) then
				sequence basedir = canonical_path( list[j] )
				if basedir[$] != SLASH then
					basedir &= SLASH
				end if
					
				for k = 1 to length( dirlist ) do
					files = append( files, basedir & dirlist[k][D_NAME] )
					printf( 1, "adding test file: %s\n", { files[$] })
				end for
			end if
		else
			files = append( files, list[j] )
		end if
	end for
	return files
end function

function change_if_exists(sequence default, sequence new_path)
	if file_exists( new_path ) then
		return new_path
	else
		return default
	end if
end function

procedure main()

	object files = {}
	map opts = cmd_parse( cmdopts )
	sequence keys = map:keys( opts )
	sequence output_format = ASCII_output
	no_check = map:has( opts, "n") or map:has( opts, "nocheck" )
	
	-- need to check this because it affects the behavior of the option below. 
	if map:has(opts, "verbose") then
		verbose_switch = 1
	end if				

	-- Because the "eubin" option sets several parameters at once, there is utility in allowing this option to be processed before the other options.   For in this case, after setting several parameters with this option we can change one or two with less typing than setting all of them with other options.  Because the order of keys is not related to the order they appear on the command line, we must always process this option first before the loop.
	if map:has(opts, "eubin") then
		sequence val = canonical_path(map:get(opts, "eubin"),1=1)
		if not file_exists(val) then
			printf(1, "Specified binary directory via -eubin parameter was not found\n")
			if not no_check then
				abort(1)
			end if
		end if
		executable = change_if_exists(executable, val & "eui" & dexe)
		binder = change_if_exists(binder, val & "eubind" & dexe)
		if file_exists(val & SLASH & "eub" & dexe) then
			eub_path = "-eub " & val & "eub" & dexe
		end if
		translator = change_if_exists(translator,val & "euc" & dexe)
		sequence tmp = val & "eudbg.a"
		if file_exists(tmp) then
			library = "-lib " & tmp
		else
			tmp = val & "eu.a"
			if file_exists(tmp) then
				library = "-lib " & tmp
			end if
		end if
		verbose_printf(1, "Setting new parameters: executable = %s, binder = %s, translator = %s, backend %s, library %s\n", { executable, binder, translator, eub_path, library } )
	end if
	for i = 1 to length( keys ) do
		sequence param = keys[i]
		object val = map:get(opts, param)
		
		switch param do
			case "all","failed","wait","accumulate" then
				test_options &= " -" & param		
		
			case "html" then
				output_format = HTML_output
				
			case "retest" then
				output_format = PREPARE_RETEST_output
				
			case "log" then
				logging_activated = 1
				test_options &= " -log "
				
			case "eubin" then
				-- do nothing
			case "verbose" then
				-- do nothing
				
			case "eui", "exe" then
				executable = canonical_path(val)
				if not file_exists(executable) then
					printf(1, "Specified interpreter via -eui parameter was not found\n")
					if not no_check then
						abort(1)
					end if
				end if
				
			case "eubind", "bind" then
				binder = canonical_path(val)
				verbose_printf(1, "Setting eubind to \'%s\'\n", {binder})
				if not file_exists(binder) then
					printf(1, "Specified binder via -eubind parameter was not found\n")
					if not no_check then
						abort(1)
					end if
				end if
				
			case "eub" then
				sequence tmp = canonical_path(val)
				if not file_exists(tmp) then
					printf(1, "Specified backend via -eub parameter was not found\n")
					if not no_check then
						abort(1)
					end if
				end if

				eub_path = "-eub " & tmp
			
			case "euc", "ec" then
				translator = canonical_path(val)
				if not file_exists(translator) then
					printf(1, "Specified translator via -euc parameter was not found\n")
					if not no_check then
						abort(1)
					end if
				end if
				
			case "trans" then
				if not length( translator ) then
					translator = "-"
				end if
				
			case "cc" then
				compiler = "-" & val
				
			case "lib" then
				sequence tmp = canonical_path(val)
				if not file_exists(tmp) then
					printf(1, "Specified library via -lib parameter was not found\n")
					if not no_check then
						abort(1)
					end if
				end if

				library = "-lib " & tmp
				
			case "i", "d" then
				for j = 1 to length(val) do
					sequence option = sprintf( " -%s %s", {param, val[j] })
					interpreter_options &= option
					translator_options &= option
				end for
			
			case "coverage" then
				for j = 1 to length( val ) do
					interpreter_options &= sprintf( " -coverage %s", {val[j]} )
				end for

				if not length( coverage_db ) then
					coverage_db = "-"
				end if
			
			case "coverage-db" then
				coverage_db = val
				interpreter_options &= " -coverage-db " & val
			
			case "coverage-erase" then
				coverage_erase = "-coverage-erase"
			
			case "coverage-pp" then
				coverage_pp = val
			
			case "coverage-exclude" then
				for j = 1 to length( val ) do
					interpreter_options &= sprintf(` -coverage-exclude "%s"`, {val[j]} )
					object pattern = regex:new( val[j] )
					if regex( pattern ) then
						exclude_patterns = append( exclude_patterns, regex:new( val[j] ) )
					else
						printf(2, "invalid exclude pattern: [%s]\n", { val[j] } )
					end if
				end for

			case "testopt" then
				test_options &= " -" & val & " "
				
			case "html-file" then
				html_filename = val
				
			case cmdline:EXTRAS then
				if length( val ) then
					files = build_file_list( val )
				else
					files = dir("t_*.e" )
					if atom(files) then
						files = {}
					end if
					for f = 1 to length( files ) do
						files[f] = files[f][D_NAME]
					end for
					files = sort( files )
					-- put the counter tests last to do
					integer first_counter
					integer last_counter
					-- default values are chosen such that 
					-- files are left alone if there are no 
					-- counter tests.
					first_counter = length(files)+1
					last_counter = length(files)
					for f = 1 to length(files) do
						if match("t_c_", files[f])=1 then
							first_counter = f
							exit
						end if
					end for
					for f = first_counter to length(files) do
						if match("t_c_", files[f])!=1 then
							last_counter = f-1
							exit
						end if
					end for
					files = remove(files,first_counter,last_counter) 
						& files[first_counter..last_counter]
				end if
			case "n", "nocheck" then
				no_check = 1
		end switch
	end for
	
	if equal( coverage_db, "-" ) then
		coverage_db = "eutest-cvg.edb"
	end if
	
	if map:has( opts, "process-log") then
		do_process_log( files, output_format )
		if map:has( opts, "retest" ) then
			platform_init()
			do_test( retest_files )
		end if
	else
		if map:has( opts, "retest" ) then
			do_process_log( files, PREPARE_RETEST_output )
			files = retest_files
		end if
		platform_init()
		do_test( files )
	end if
end procedure

enum DOCUMENT_OPEN, -- a procedure that takes no parameters and opens the html-file if not stdout
DOCUMENT_CLOSE, --  a procrocedure that takes no parameters and [closes the html-file if not stdout]
DOCUMENT_PROCESS, -- a procedure takes a single parameter see html_out and ascii_out 
DOCUMENT_NL, -- a function no parameters that outputs a new-line 
DOCUMENT_LINK, --  a function no parameters that outputs a link
DOCUMENT_ENDING, -- a printf format string for the document's ending or 0.
DOCUMENT_P -- a routine that outputs something to indicate a new paragraph is starting



constant HTML_output = { routine_id("html_open"), routine_id("html_close"), routine_id("html_out"), routine_id("html_new_line"), routine_id("html_link"), html_table_final_summary, routine_id("html_p") }

constant ASCII_output = { routine_id("ascii_open"), routine_id("ascii_close"), routine_id("ascii_out"),
routine_id("ascii_new_line"), routine_id("ascii_link"), ascii_table_final_summary, routine_id("ascii_new_line")}

constant PREPARE_RETEST_output = { routine_id("retest_open"), routine_id("retest_close"), routine_id("prepare_retest"), routine_id("empty_string"), routine_id("retest_link"), 0, routine_id("empty_string")}
main()

