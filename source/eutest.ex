#!/usr/bin/env eui
-- (c) Copyright - See License.txt

-- TODO: Replace all command line handling with cmd_parse
-- TODO: Extract log parsing code into it's own file
-- TODO: Use templates (with defaults supplied) for HTML reports, thus
--       users will be able to theme the unit test reports to fit into
--       their own project pages. Further, it will simplify the output
--       code quite a bit

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

constant USER_BREAK_EXIT_CODES = {255,-1073741510}
integer verbose_switch = 0
object void
integer ctcfh = 0
sequence error_list = repeat({},4)

-- moved from do_test:
integer log = 0
integer failed = 0
integer total
sequence dexe, executable

enum E_NOERROR, E_INTERPRET, E_TRANSLATE, E_COMPILE, E_EXECUTE, E_EUTEST

type error_class(object i)
	return integer(i) and i >= 1 and i <= E_EUTEST
end type

procedure error(sequence file, error_class e, sequence message, sequence vals, object error_file = 0)
	object lines

	if sequence(error_file) then
		lines = read_lines(error_file)
	else
		lines = 0
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

function run_emake()
	-- parse and run the commands in emake.bat.
	object file

	ifdef UNIX then
		file = read_lines("emake")
	elsedef
		file = read_lines("emake.bat")
	end ifdef

	if atom(file) then
		return 1
	end if

	for i = 1 to length(file) do
		sequence line = file[i]

		if length(line) < 4 or
			match("rem ", line) = 1 or
			match("echo ", line) or
			equal("if ", line[1..3]) or
			match("@echo", line) = 1 or
			match("goto ", line) or
			line[1] = '#' or
			line[1] = ':'
		then

			-- Do nothing with these lines
		
		elsif match("set ", line) = 1 then 
			sequence pair
			pair = split(line[5..$], "=")
			pair = {setenv(pair[1], pair[2])}

		elsif match("move ", line) = 1 or
			equal("del ", line[1..4]) then
			system(line, 2)

		else
			integer status = system_exec(line, 2)

			if status then
				sequence source = ""
				integer dl = match(".c", line)

				for ws = dl to 1 by -1 do
					if line[ws] = ' ' then
						source = line[ws+1..dl-1]
						exit
					end if
				end for

				return { E_COMPILE,  "program could not be compiled.  Error %d executing:%s",
					{ status, line }, source & ".err" }
			end if
		end if

		puts(1,'.')
	end for

	puts(1,"\n")

	return 0
end function

-- runs cmd using system exec tests for returned error values
-- and error files.  Before the command is run, the error files
-- are deleted and just before the functions exits the error 
-- files are deleted unless REC is defined.
-- returns 0 iff no errors were raised
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
					
	if log_fd = -1  then
		return "couldn't generate unittest.log"
	elsif log_where = where(log_fd) then
		close(log_fd)
		return  "couldn't add to unittest.log"
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

function strip_path_junk(sequence path)
	for i = 1 to length(path) do
		if not find(path[i], "./\\") then
			return path[i..$]
		end if
	end for

	return ""
end function

function check_errors( sequence filename, sequence control_error_file, sequence fail_list )
	object control_err = read_lines(control_error_file)
	object ex_err = read_lines("ex.err")
	if sequence(ex_err) then
		if length(ex_err) > 4 then
			ex_err = ex_err[1..4]
		end if
		for i = 1 to length(ex_err) do
			if equal(ex_err[i], "--- Defined Words ---") then
				ex_err = ex_err[1 .. i-1]
				exit
			end if
		end for

		if length(control_err) > 4 then
			control_err = control_err[1..4]
		end if
		for i = 1 to length(control_err) do
			if equal(control_err[i], "--- Defined Words ---") then
				control_err = control_err[1 .. i-1]
				exit
			end if
		end for

		ex_err[1] = strip_path_junk(ex_err[1])
		control_err[1] = strip_path_junk(control_err[1])

		for j = 1 to length(ex_err) do
			integer mde = match(".e:", ex_err[j]) 

			if mde then
				integer sl = mde
				while sl > 1 and ex_err[j][sl] != SLASH do
					sl -= 1
				end while

				ex_err[j] = ex_err[j][sl..$]

				if sl > 1 then
					ex_err[j] = "..." & ex_err[j]
				end if
			end if

		end for

		for j = 1 to length(control_err) do
			integer mde = match(".e:", control_err[j])

			if mde then
				integer sl = mde
				while sl > 1 and control_err[j][sl] != SLASH do
					sl -= 1
				end while

				control_err[j] = control_err[j][sl..$]
				if sl > 1 then
					control_err[j] = "..." & control_err[j]
				end if
			end if

		end for
	end if -- sequence(ex_err)
			
	integer comparison = compare(ex_err, control_err)
	if comparison then
		failed += 1
		fail_list = append(fail_list, filename)

		if atom(ex_err) then
			error(filename, E_INTERPRET, "No ex.err has been generated.", {})
		elsif length(ex_err) >=4  and length(control_err) >= 4 then
			error(filename, E_INTERPRET, "Unexpected ex.err expected: " &
				"\'%s\n%s\n%s\n%s\' but got \'%s\n%s\n%s\n%s\'\n",
				control_err & ex_err, "ex.err")
		elsif length(ex_err) then
			error(filename, E_INTERPRET, "Unexpected ex.err got: \'%s\'\n", ex_err)
		else
			error(filename, E_INTERPRET, "Unexpected empty ex.err", {})
		end if
	end if
	return fail_list
end function

function open_error_file( sequence filename )
	object control_error_file
	-- try tests/t_test.d/interpreter/UNIX/control.err
	control_error_file =  filename[1..find('.',filename&'.')-1] & ".d" & SLASH & "interpreter" &
		SLASH & interpreter_os_name & SLASH & "control.err"

	if not file_exists(control_error_file) then
		-- try tests/t_test/UNIX/control.err
		control_error_file =  filename[1..find('.',filename&'.')-1] & ".d" & SLASH &
			interpreter_os_name & SLASH & "control.err"
	end if

	if not file_exists(control_error_file) then
		-- try tests/t_test/control.err
		control_error_file = filename[1..find('.',filename&'.')-1] & ".d" & SLASH & "control.err"
	end if

	if not file_exists(control_error_file) then
		-- don't try anything
		control_error_file = 0
	end if
	return control_error_file
end function

function interpret_fail( sequence cmd, sequence filename, object control_error_file, sequence fail_list )
	integer status = system_exec(cmd, 2)
	integer comparison
	
	if sequence(control_error_file) then 
		-- Now we will compare the control error file to the newly created 
		-- eui.exe.  If ex.err doesn't exist or there is no match error()
		-- is called and we add to the failed list.
		comparison = length( fail_list )
		fail_list = check_errors( filename, control_error_file, fail_list )
		comparison = comparison != length( fail_list )
	else	
		-- no control_error_file. thus, there is nothing to compare to we go on as
		-- if the files matched.
		comparison = 0
	end if  -- sequence(control_error_file)

	if comparison = 0 then
		if status = 0 then
			-- Here, we were expecting the test to fail.  Yet, we recieved a 0
			-- error status. This is a failure for we should get some other number
			-- for errors.
			failed += 1
			fail_list = append(fail_list, filename)
			error(filename, E_INTERPRET,
				"The unit test exited with 0 while we expected a failure.", {})
		else						
			error(filename, E_NOERROR, "The unit test failed in the expected manner. " &
				"Error status %d.", {status})
		end if
	else
		-- error() has been called in the previous block if comparsion != 0
	end if
	return fail_list
end function

function translate( sequence filename, sequence fail_list )
	printf(1, "translating, compiling, and executing executable: %s\n", {filename})
	total += 1
	sequence cmd = sprintf("%s %s %s %s -D UNITTEST -D EC -batch %s",
		{ translator, library, compiler, translator_options, filename })
	verbose_printf(1, "CMD '%s'\n", {cmd})
	integer status = system_exec(cmd, 0)

	filename = filebase(filename)
	integer log_where = 0
	if status = 0 then
		sequence exename = filename & dexe

		void = delete_file(exename)
		void = delete_file("cw.err")
		verbose_printf(1, "compiling %s%s\n", {filename, ".c"})

		object emake_outcome = run_emake()
		if equal(emake_outcome, 0) then
			verbose_printf(1, "executing %s:\n", {exename})
			cmd = sprintf("./%s %s", {exename, test_options})
			status = invoke(cmd, exename,  E_EXECUTE) 
			if status then
				failed += 1
				fail_list = append(fail_list, "translated" & " " & exename)
			else
				object token
				if log then
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
			end if
			
			void = delete_file(exename)
		else
			failed += 1
			fail_list = append(fail_list, "compiling " & filename)					
			if sequence(emake_outcome) then
				error(exename, E_COMPILE, emake_outcome[2], emake_outcome[3], emake_outcome[4])
				status = emake_outcome[3][1]
			else
				error(exename, E_COMPILE, 
					"program could not be compiled. Compilation process exited with status %d", {emake_outcome})
			end if
		end if
	else
		failed += 1
		fail_list = append(fail_list, "translating " & filename)
		error(filename, E_TRANSLATE, "program translation terminated with a bad status %d", {status})                               
	end if
	report_last_error(filename)
	return fail_list
end function

function test_file( sequence filename, sequence fail_list )

	integer log_where = 0 -- keep track of unittest.log
	integer status
	void = delete_file("ex.err")
	void = delete_file("cw.err")
	
	object control_error_file = open_error_file( filename )
	sequence crash_option = ""
	if match("t_c_", filename) = 1 or sequence(control_error_file) then
		crash_option = " -D CRASH "
	end if
	
	printf(1, "interpreting %s:\n", {filename})
	sequence cmd = sprintf("%s %s -D UNITTEST -batch %s%s %s",
		{ executable, interpreter_options, crash_option, filename, test_options })

	verbose_printf(1, "CMD '%s'\n", {cmd})
	
	integer expected_status = 0
	if match("t_c_", filename) = 1 or sequence(control_error_file) then
		-- We expect this test to fail
		expected_status = 1
		fail_list = interpret_fail( cmd, filename, control_error_file, fail_list )
		
	else -- not match(t_c_*.e)
		-- in this branch error() is called once and only once in all sub-branches
		status = invoke(cmd, filename, E_INTERPRET) -- error() called if status != 0
		expected_status = 0

		if status then
			failed += 1
			fail_list = append(fail_list, filename)
			-- error() called in invoke()
		else
			object token
			if log then
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

	ifdef REC then
		if status then
			if match("t_c_", filename) != 1 then
				directory = filename[1..find('.',filename&'.')] & "d" & SLASH & interpreter_os_name
			else
				directory = filename[1..find('.',filename&'.')] & "d"
			end if

			create_directory(filename[1..find('.',filename&'.')] & "d")
			create_directory(directory)

			if not move_file("ex.err", directory & SLASH & "control.err") then
				e:crash("Could not move 'ex.err' to %s", { directory & SLASH & "control.err" })
			end if
		end if
	end ifdef
	
	report_last_error(filename)
	
	if length(translator) and expected_status = 0 then
		fail_list = translate( filename, fail_list )
	end if
	
	return fail_list
end function

sequence interpreter_options = ""
sequence translator_options = "-emake "
sequence test_options = ""
sequence translator = "", library = "", compiler = ""
sequence interpreter_os_name
function parse_options( sequence cmds  )
	-- pass options with arguments passed to eutest to the 
	-- interpreter or translator...
	integer outstanding_argument_count = 0
	integer cci
	compiler = ""
	while cci and cci < length(cmds) with entry do
		if cmds[cci+1][1] != '-' then
			compiler = "-" & cmds[cci+1]
		else
			compiler = cmds[cci+1]
		end if

		cmds = cmds[1..cci-1] & cmds[cci+2..$]
	entry
		cci = find("-cc", cmds)               
	end while
	
	sequence files = {}
	for i = 3 to length(cmds) do
		if outstanding_argument_count > 0 then
			outstanding_argument_count -= 1
			continue

		elsif cmds[i][1] != '-' then			
			files = append(files,repeat(0,8))
			files[$][D_NAME] = cmds[i]

		-- put the options that take arguments in the sequence argument
		-- to find below.
		elsif find(cmds[i],{"-i","-D"}) and i < length(cmds) then
			-- for both interpreter and translator but not test
			outstanding_argument_count = 1 -- an argument to skip
			interpreter_options &= " " & cmds[i] & " " & cmds[i+1]
			translator_options &= " " & cmds[i] & " " & cmds[i+1]

		elsif find(cmds[i],{"-lib"}) and i < length(cmds) then
			-- for translator only
			outstanding_argument_count = 1
			translator_options &= " " & cmds[i] & " " & cmds[i+1]

		else
			-- for test 
			test_options &= " " & cmds[i] & " "
		end if
	end for
	
	
	
	if length(files) = 0 then
		files = dir("t_*.e")
		if atom(files) then
			puts(2,"No unit tests supplied or found.\n")
			abort(1)
		end if

		files = sort(files)
	end if
	
	return files
end function

function platform_init( sequence cmds )
	ifdef UNIX then
		executable = "eui"
		dexe = ""
		
	elsifdef WIN32 then
		executable = "eui"
		dexe = ".exe"		
	end ifdef
	integer eui
	while eui and eui < length(cmds) with entry do
		executable = cmds[eui+1]
		cmds = cmds[1..eui-1] & cmds[eui+2..$]
	entry
		eui = find("-exe", cmds)
	end while

	integer ec
	while ec and ec <= length(cmds) with entry do
		if ec < length(cmds) then
			if cmds[ec+1][1] != '-' then
				translator = cmds[ec+1]
				cmds = cmds[1..ec-1] & cmds[ec+2..$]
			else
				translator = "-"
				cmds = cmds[1..ec-1] & cmds[ec+1..$]
			end if
		else
			translator = "-"
			cmds = cmds[1..ec-1] & cmds[ec+1..$]
		end if
	entry
		ec = find("-ec", cmds)
	end while
	
	if equal(translator, "-") then
		ifdef UNIX then
			translator = "euc"
		
		elsifdef WIN32 then
			translator = "euc.exe"
		end ifdef
	end if	

	-- Check for various executable names to see if we need -CON or not
	
	-- lower for Windows or DOS, lower for all.  K.I.S.S.

	ifdef UNIX then
		interpreter_os_name = "UNIX"

	elsifdef WIN32 then
		if length(translator) > 0 then
			translator_options &= " -CON"
		end if
		
		interpreter_os_name = "WIN32"

	elsedef
		puts(2, "eutest is only supported on Unix and Windows.\n")
		abort(1)
	end ifdef
	return cmds
end function

procedure do_test( sequence cmds )
	atom score
	object files = {}
	
	integer log_fd = 0
	sequence silent = ""
	
	log    = find("-log", cmds)
	verbose_switch = find("-verbose", cmds)
	
	files = parse_options( cmds )
	
	total = length(files)

	if verbose_switch <= 0 then
		translator_options &= " -silent"
	end if

	sequence fail_list = {}
	if log then
		void = delete_file("unittest.dat")
		void = delete_file("unittest.log")
		void = delete_file("ctc.log")
		ctcfh = open("ctc.log", "w")
	end if

	for i = 1 to length(files) do
		fail_list = test_file( files[i][D_NAME], fail_list )		
	end for
	
	if log and ctcfh != -1 then
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

	printf(1, "Files (run: %d) (failed: %d) (%.1f%% success)\n", {total, failed, score})

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

		printf(1, "Tests (run: %d) (failed: %d) (%.1f%% success)\n", {total, failed, score})
	end if

	abort(failed > 0)
end procedure

sequence unsummarized_files = {}

procedure ascii_out(sequence data)
	switch data[1] do
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

			if find(data[2], unsummarized_files) then
				unsummarized_files = unsummarized_files[1..find(data[2], unsummarized_files)-1] 
					& unsummarized_files[find(data[2], unsummarized_files)+1..$]
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

sequence html_table_head = `
<table width=100%%>
<tr bgcolor=#dddddd>
<th colspan=3 align=left><a name='%s'>%s</a></th>
<td><a href='#summary'>all file summary</a></th>
</tr>
<tr><th>test name</th>
<th>test time</th>
<th>expected</th>
<th>outcome</th>
</tr>`

sequence html_table_error_row = `
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
			unsummarized_files = append(unsummarized_files, data[2])
			printf(1, html_table_head, { data[2], data[2] })

			integer err = find(data[2], error_list[1])
			if err then
				sequence color
				if error_list[3][err] = E_NOERROR then
					color = "#aaffaa"
				else
					color = "#ffaaaa"
				end if

				printf(1, html_table_error_row, { color, data[2], error_list[2][err] })
				
				if sequence(error_list[4][err]) then
					puts(1, html_table_error_content_begin)

					for i = 1 to length(error_list[4][err]) do
						printf(1,"%s\n", { text2html(error_list[4][err][i]) })
					end for

					puts(1, html_table_error_content_end)
				end if
			end if

		case "failed" then
			printf(1, html_table_failed_row, {
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

			printf(1, html_table_passed_row, { data[2], anum })

		case "summary" then
			if length(unsummarized_files) then
				unsummarized_files = unsummarized_files[1..$-1] 
			end if

			printf(1, html_table_summary, {
				data[2],
				data[3],
				data[4],
				data[5]
			})
	end switch
end procedure

procedure summarize_error(sequence message, error_class e, integer html)
	if find(e, error_list[3]) then
		if html then
			printf(1,message & "<br>\nThese were:\n", {sum(error_list[3] = e)})
		else
			printf(1,message & "\nThese were:\n", {sum(error_list[3] = e)})
		end if

		for i = 1 to length(error_list[1]) do
			if error_list[3][i] = e then
				if html then
					printf(1, "<a href='#%s'>%s</a>, ", repeat(error_list[1][i],2))
				else
					printf(1, "%s, ", repeat(error_list[1][i],1))
				end if
			end if
		end for

		if html then
			puts(1, "<p>")
		end if

		puts(1, "\n")
	end if
end procedure

procedure do_process_log(sequence cmds)
	sequence summary = {}
	object other_files = {}
	integer total_failed=0, total_passed=0
	integer test_files=0
	integer html = find("-html", cmds)
	integer out_r
	atom total_time = 0
	object ctc
	sequence messages
	
	if html then
		out_r = routine_id("html_out")
	else
		out_r = routine_id("ascii_out")
	end if

	ctcfh = open("ctc.log","r")
	if ctcfh != -1 then
		ctc = get(ctcfh)

		if ctc[1] = GET_SUCCESS then
			ctc = ctc[2]
			error_list = ctc

			ctc = get(ctcfh)
			if ctc[1] = GET_SUCCESS then
				test_files = ctc[2]
			else
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

	if html then
		puts(1, "<html><body>\n")
	end if

	object content = read_file("unittest.log")
	if atom(content) then
		puts(1, "unittest.log could not be read\n")
	else    
		messages = split(content, "entry = ")
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
	
	summarize_error("Interpreted test files failed unexpectedly.: %d", E_INTERPRET, html)
	summarize_error("Test files could not be translated.........: %d", E_TRANSLATE, html)
	summarize_error("Translated test files could not be compiled: %d", E_COMPILE, html)
	summarize_error("Compiled test files failed unexpectedly....: %d", E_EXECUTE, html)
	summarize_error("Test files run successfully................: %d", E_NOERROR, html)
	
	if html then
		if find(1, error_list[3] = E_EUTEST) then
			printf(1, "There was an internal error to the testing system involving %s<br>",
				{ error_list[1][find(E_EUTEST, error_list[3])] })
		end if

		printf(1, html_table_final_summary, {
			total_passed + total_failed,
			total_failed,
			total_passed,
			total_time
		})
	else
		puts(1, repeat('*', 76) & "\n\n")
		printf(1, "Overall: Total Tests: %04d  Failed: %04d  Passed: %04d Time: %f\n\n", {
			total_passed + total_failed, total_failed, total_passed, total_time })
		puts(1, repeat('*', 76) & "\n\n")
	end if
end procedure

procedure main(sequence cmds = command_line())
	integer i = 3, sl
	object buf

	while i <= length(cmds) do
		if find('-',cmds[i]) = 1 then
			if not find(upper(cmds[i]), {"-LOG","-VERBOSE"}) then
				i += 2
				continue
			end if
		end if

		buf = dir(cmds[i])

		if sequence(buf) and length(buf) > 1 then
			sl = length(cmds[i])
			while sl >= 1 and cmds[i][sl] != SLASH do
				sl -= 1
			end while

			for j = 1 to length(buf) do
				if sl then
					buf[j] = cmds[i][1..sl] & buf[j][D_NAME]
				else
					buf[j] = buf[j][D_NAME]
				end if
			end for

			cmds = cmds[1..i-1] & buf & cmds[i+1..$]
			i += length(buf)
		else	
			i = i + 1
		end if
	end while

	if find("-help", cmds) or find("--help",cmds) or find("/?", cmds) then
		puts(2, "Usage:\n" & cmds[1] & " eutest.ex [[-process-log] [-html]]\n" &
			"  [-exe interpreter-path-and-filename]\n" &
			"  [-ec translator-path-and-filename] [-i include directory]\n" &
			"  [-lib library-path-and-filename-relative-to-%EUDIR%\\bin]\n" &
			"  [-cc [-wat|wat|some-other-compiler-name-to-pass-to-translator]]\n" &
			"  [-log]\n" &
			"  [-verbose]\n" &
			"  [unit test files]\n")
		abort(0)
	end if

	if find("-process-log", cmds) then
		do_process_log(cmds)
	else
		cmds = platform_init( cmds )
		do_test(cmds)
	end if
end procedure

main()
