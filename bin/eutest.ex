#!/usr/bin/exu

-- Specify -exe <path to interpreter> to use a specific interpreter for tests

include std/pretty.e
include std/sequence.e
include std/sort.e
include std/filesys.e
include std/io.e
include std/get.e
include std/os.e as ut
include std/text.e 
include std/math.e

without trace

ifdef DOS32 then
	include std/text.e
end ifdef

integer translator_platform
integer interpreter_platform
integer verbose_switch = 0

integer ctcfh = 0
sequence error_list = repeat({},4)
enum E_INTERPRET, E_TRANSLATE, E_COMPILE, E_EXECUTE, E_EUTEST
type error_class( integer i )
	return i > 0 and i <= E_EUTEST
end type
procedure error( sequence file, error_class e, sequence message, sequence vals, object error_file = 0 )
	integer dp
	dp = find( '.', file )
	file = file[1..dp-1] & ".e"
	object lines
	if sequence( error_file ) then
		lines = read_lines( error_file )
	else
		lines = 0
	end if
	
	error_list = { append( error_list[1], file ), append( error_list[2], sprintf( message, vals ) ), append( error_list[3], e ), append( error_list[4], lines ) }
end procedure

function dos_lower(sequence s)
	ifdef DOS32 then
		return lower(s)
	elsedef
	return s
	end ifdef
end function

function run_emake()
	integer emake
ifdef UNIX then
	emake = open( "emake", "r" )
elsedef
	emake = open( "emake.bat", "r" )
end ifdef

	if emake = -1 then
		return 1
	end if
	sequence file = read_lines( emake )
	close(emake)
	for i = 1 to length( file ) do
		sequence line = file[i]
		if length( line ) < 4
		or equal( "echo", line[1..4] )
		or equal( "if", line[1..2] )
		or match( "@echo", line ) = 1
		or equal( "goto", line[1..4] )
		or line[1] = ':' then
			
		
		elsif equal( "move", line[1..4] ) or
		       equal( "del", line[1..3] ) then
		       system( line, 2 )
		else
			integer fnptr = match( "t_", lower(line) )
			integer extptr = match( ".c", lower(line[fnptr+1..$]) )

			integer status = system_exec( line, 2 )
			if status then
			    return sprintf( "Error %d executing:%s", { status, line } )
			end if
		end if
	end for
	return 0
end function

-- runs cmd using system exec tests for returned error values
-- and error files.  Before the command is run, the error files
-- are deleted and just before the functions exits the error 
-- files are deleted.
-- returns 0 iff no errors were raised
function invoke( integer status, sequence cmd, sequence filename, integer err, sequence stage )
	if delete_file("cw.err") then end if
	if delete_file("ex.err") then end if	
	status = system_exec(cmd, 2)
	sleep( 0.1 )
	if status != 0 or file_exists( "cw.err" ) or file_exists( "ex.err" ) then
		if file_exists( "cw.err" ) then
			error( filename, err, "Causeway error with status %d", {status}, "cw.err" )
		elsif file_exists( "ex.err" ) then
			error( filename, err, "EUPHORIA error with status %d", {status}, "ex.err" )
		elsif status then
			error( filename, err, "program died with status %d", {status} )
		end if
		status = 1
		if delete_file("cw.err") then end if
		if delete_file("ex.err") then end if			
	else
		status = 0
	end if
	return status
end function

procedure do_test(sequence cmds)
	atom score
	integer failed = 0, total, status, comparison
	object rfiles, before_emake, emake_outcome
	sequence files = {}, filename, dexe, executable, cmd, cmd_opts = "", options, switches
	sequence translator = "", library = "", compiler = "", con = ""
	sequence directory
	sequence control_err, ex_err, interpreter_os_name
	integer log_where = 0 -- keep track of unittest.log
	integer log_fd = 0
	integer expected_status 

	ifdef UNIX then
		executable = "exu"
		dexe = ""
	elsifdef WIN32 then
		executable = "exwc"
		dexe = ".exe"
	elsedef
		executable = "ex"
		dexe = ".exe"
	end ifdef

	integer log = find("-log", cmds)

	integer ex
	while ex and ex < length(cmds) entry do
		executable = cmds[ex+1]
		cmds = cmds[1..ex-1] & cmds[ex+2..$]
	entry
		ex = find("-exe", cmds)
	end while


	integer ec
	while ec and ec < length(cmds) entry do
		translator = cmds[ec+1]
		cmds = cmds[1..ec-1] & cmds[ec+2..$]
	entry
		ec = find("-ec", cmds)
	end while

	
	if (length(translator) >= 7 and match( upper("ecw.exe"), upper(translator) ) != 0)
		or ( length(translator) = 0 and platform() = WIN32 ) then
		translator_platform = WIN32
		con = "-CON"
	else
		con = ""
		if ( match( upper("ecu"), upper(translator) ) != 0 )
			or ( length(translator) = 0 and find( platform(), { LINUX, FREEBSD, OSX } ) ) then
			translator_platform = LINUX -- means FREEBSD or OSX too
		elsif ( length(translator) = 0 and platform() = DOS32 ) or 
			match( upper("ec.exe"), upper(translator) ) != 0 then
			translator_platform = DOS32
		else
			printf( 2, "Cannot determine translator\'s platform.", {} )
			abort(1)
		end if                                  
	end if
	
	if match( upper("exwc.exe"), upper(executable) ) != 0 then
		interpreter_os_name = "WIN32"		
	else
		if match( upper("exu"), upper(executable) ) != 0 then
			interpreter_os_name = "UNIX"
		elsif match( upper("ex.exe"), upper(executable) ) != 0 then
			interpreter_os_name = "DOS32"
		elsif platform() = WIN32 then
			interpreter_os_name = "WIN32"		
		elsif find( platform(), { LINUX, OSX, FREEBSD } ) then
			interpreter_os_name = "UNIX"
		elsif platform() = DOS32
			interpreter_os_name = "DOS32"
		else
			printf( 2, "Cannot determine executable\'s operating system.", {} )
			abort(1)
		end if                                  
	end if


	integer lib
	while lib and lib < length(cmds) entry do
		library = "-lib " & cmds[lib+1]
		cmds = cmds[1..lib-1] & cmds[lib+2..$]
	entry
		lib = find("-lib", cmds)
	end while       

	integer cci
	
	compiler = ""
	while cci and cci < length(cmds) entry do
		if cmds[cci+1][1] != '-' then
			compiler = "-" & cmds[cci+1]
		else
			compiler = cmds[cci+1]
		end if
		cmds = cmds[1..cci-1] & cmds[cci+2..$]
	entry
		cci = find( "-cc", cmds )               
	end while

	for i = 3 to length(cmds) do
		if cmds[i][1] != '-' then
			files &= {{cmds[i]}}
		else
			cmd_opts &= cmds[i] & " "
		end if
	end for
	
	-- for some illogical reason '-log' is mandatory now.
	cmd_opts &= "-log "
	

	if length(files) = 0 then
		files = sort(dir("t_*.e"))
	end if

	total = length(files)

	switches = option_switches()
	options = join(switches)

	sequence fail_list = {}
	if log and atom(
	 delete_file("unittest.dat") 
	  + delete_file("unittest.log") + delete_file("ctc.log") ) then
		ctcfh = open( "ctc.log", "w" )
	end if
	
	for i = 1 to total do
		filename = files[i][D_NAME]
		if delete_file( "ex.err" ) then
		end if
		if delete_file( "cw.err" ) then
		end if
		printf(1, "%s:\n", {filename})
		cmd = sprintf("%s -i ..%sinclude %s -D UNITTEST -batch %s %s", {executable, SLASH, options, filename, cmd_opts})
		if verbose_switch != 0 then
			printf(1, "CMD '%s'\n", {cmd})
		end if
		
		if match("t_c_", dos_lower(filename)) = 1 then
			expected_status = 1
			status = system_exec( cmd, 2 )
		else
			status = invoke( 0, cmd, filename, E_INTERPRET, "interpreted" )
			expected_status = 0
			if status then
				failed += 1
				fail_list = append(fail_list, filename )
				continue
			end if
		end if

		if expected_status then
			directory = filename[1..find('.',filename)-1] & SLASH & interpreter_os_name
			if sequence( dir( directory ) ) then
				if sequence( dir( directory & SLASH & "control.err" ) ) then
					control_err = read_lines( directory & SLASH & "control.err" )
					ex_err = read_lines( "ex.err" )
					if length(ex_err) > 4 then
						ex_err = ex_err[1..4]
					end if
					if length(control_err) > 4 then
						control_err = control_err[1..4]
					end if 
					comparison = compare( ex_err, control_err )
					if comparison then
						failed += 1
						fail_list = append( fail_list, filename )
						if length( ex_err ) >=4  and length( control_err ) >= 4 then
							error( filename, E_INTERPRET, "Unexpected ex.err expected: \'%s\n%s\n%s\n%s\' but got \'%s\n%s\n%s\n%s\'\n", control_err & ex_err, "ex.err" )
						elsif length( ex_err ) then
							error( filename, E_INTERPRET, "Unexpected ex.err got: \'%s\'\n", ex_err )
						else
							error( filename, E_INTERPRET, "Unexpected empty ex.err", {} )
						end if
						continue
					end if

				elsif atom( dir( "ex.err" ) ) then
					error( filename, E_INTERPRET, "ex.err not generated.", {} )
					continue
				end if
				
			end if
			ifdef REC then
				if create_directory( filename[1..find('.',filename)-1] )
				and create_directory( directory ) 
				and move_file( "ex.err", directory & SLASH & "control.err" ) then 
				end if
			end ifdef
		end if

		if status xor expected_status then
			failed += 1
			fail_list = append( fail_list, filename )
			if not file_exists("ex.err") then
				error( filename , E_INTERPRET, "program closed with status %d", {status} )
			else
				error( filename, E_INTERPRET, "program closed with status %d", {status}, "ex.err" )

			end if
			continue
		elsif expected_status = 0 then
			for j = 1 to 5 do
				if file_exists("unittest.log") then
					exit
				end if
				sleep(0.1)
			end for
			log_fd = open( "unittest.log", "a" )
			if log_fd = -1  then
				error( filename, E_INTERPRET, "couldn't generate unittest.log", {}, "ex.err" )
				failed += 1
				fail_list = append( fail_list, filename )
				close( log_fd )
				continue
			elsif log_where = where( log_fd ) then
				error( filename, E_INTERPRET, "couldn't add to unittest.log", {}, "ex.err" )
				failed += 1
				fail_list = append( fail_list, filename )
				close( log_fd )
				continue
			end if
			log_where = where( log_fd )
			close( log_fd )
			log_fd = 0
			
		end if
		
		if length(translator) and expected_status = 0 then
			printf(1, "translating %s:\n", {filename})
			-- translator for windows                       

			cmd = sprintf("%s %s %s %s -D UNITTEST %s -D EC -batch %s", {translator, library, compiler, options, con, filename})
			status = system_exec( cmd, 0 )

			if status = expected_status and expected_status = 0 then
				lib = find('.', filename)
				if lib then
					filename = filename[1..lib-1]
				end if
				if delete_file(filename&dexe) then end if
				if delete_file( "cw.err" ) then end if
				emake_outcome = run_emake()
				if compare(emake_outcome,0) = 0 then
					cmd = sprintf("./%s %s", {filename&dexe, cmd_opts})
					status = invoke( status, cmd, filename&dexe,  E_EXECUTE, "translated " ) 
					if status then
						failed += 1
						fail_list = append(fail_list, "translated" & " " & filename&dexe )
					end if
					if delete_file(filename & dexe) then end if
				else
					failed += 1
					fail_list = append(fail_list, "translate " & filename )
					if sequence( emake_outcome ) then
						error( filename& dexe, E_COMPILE, 
							"program could not be compiled.  %s", {emake_outcome} )
					else
						error( filename& dexe, E_COMPILE, 
							"program could not be compiled. Compilation process exited with status %d", {emake_outcome} )
					end if
				end if
			elsif expected_status = 0 then
				failed += 1
				fail_list = append(fail_list, "translate " & filename )
				error( filename & ".e", E_TRANSLATE, "program translation terminated with a bad status %d", {status} )                               
			end if
		end if -- length( translator )
	end for
	
	if log then
		print( ctcfh, error_list )
		puts( ctcfh, 10 )
		if length(translator) > 0 then
			print( ctcfh, total )
		else
			print( ctcfh, 0 )
		end if
		close( ctcfh )
	end if
	ctcfh = 0
	
	if length(translator) > 0 then
		total *= 2 -- also account for translated tests
	end if

	
	if total = 0 then
		score = 100
	else
		score = ((total - failed) / total) * 100
	end if

	puts(1, "\nTest results summary:\n")
	for i = 1 to length(fail_list) do
		printf(1, "    FAIL: %s\n", {fail_list[i]})
	end for
	printf(1, "Files run: %d, failed: %d (%.1f%% success)\n", {total, failed, score})

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
		printf(1, "Tests run: %d, failed: %d (%.1f%% success)\n", {total, failed, score})

	end if

	abort(failed > 0)
end procedure

sequence unsummarized_files = {}

procedure ascii_out(sequence data)
	switch data[1] do
		case "file":
			unsummarized_files = append( unsummarized_files, data[2] )
			printf(1, "%s\n", { data[2] })
			puts(1, "===========================================================================\n")
			if find( data[2], error_list[1] ) then
				printf(1,"%s\n",
				{ error_list[2][find(data[2],error_list[1])] })
			end if
			break

		case "failed":
			printf(1, "  Failed: %s (%f) expected ", { data[2], data[5] })
			pretty_print(1, data[3], {2, 2, 12, 78, "%d", "%.15g"})
			puts(1, " got ")
			pretty_print(1, data[4], {2, 2, 12, 78, "%d", "%.15g"})
			puts(1, "\n")
			break

		case "passed":
			sequence anum
			if data[3] = 0 then
				anum = "0"
			else
				anum = sprintf("%f", data[3])
			end if
			printf(1, "  Passed: %s (%s)\n", { data[2], anum })
			break

		case "summary":
			puts(1, "---------------------------------------------------------------------------\n")
			sequence status
			if find( data[2], unsummarized_files ) then
				unsummarized_files = unsummarized_files[1..find( data[2], unsummarized_files )-1] 
					& unsummarized_files[find( data[2], unsummarized_files )+1..$]
			end if
			if data[3] > 0 then
				status = "bad"
			else
				status = "ok"
			end if
			printf(1, "  Tests: %04d Status: %3s Failed: %04d Passed: %04d Time: %f\n\n", {
				data[2], status, data[3], data[4], data[5]
			})
			break
	end switch
end procedure

function text2html(sequence t)
	integer f
	f = length(t)
	while f do
		if t[f] = '<' then
			t = t[1..f-1] & "&lt;" & t[f+1..$]
		elsif t[f] = '>' then
			t = t[1..f-1] & "&gt;" & t[f+1..$]
		elsif t[f] > 127 then
			t = t[1..f-1] & sprintf("&#%x;", t[f..f] ) & t[f+1..$]
		elsif t[f] = 10 then
			t = t[1..f-1] & "<br>" & t[f+1..$]
		end if
		f = f - 1
	end while
	return t
end function

procedure html_out(sequence data)
	integer err

	switch data[1] do
		case "file":
			unsummarized_files = append( unsummarized_files, data[2] )
			puts( 1, "<a href='#summary'>summary</a><br>\n" )
			printf( 1, "<table width=100%%><tr bgcolor=#dddddd><th colspan=4 align=left><a name='%s'>%s</a></th></tr>\n", { data[2], data[2] } )
			err = find( data[2], error_list[1] ) 
			if err then
				printf(1,"<tr bgcolor=\"#ffaaaa\"><th align=left width=50%%>%s</th><td colspan=3>%s</td></tr>\n",
				{ data[2], error_list[2][err] })
				
				if sequence( error_list[4][err] ) then
					printf(1,"<tr bgcolor=\"ffaaaa\"><th colspan=4 align=left width=50%%>Error file contents follows:</th></tr>\n", {} )
					printf( 1,"<tr bgcolor=\"ffaaaa\"><td colspan=4 align=left width=100%%><pre>", {} )
					for i = 1 to length( error_list[4][err] ) do
						printf(1,"%s\n", {text2html(error_list[4][err][i])} )
					end for
					puts( 1,"</pre></td></tr>" )
				end if
					
						
			end if
			break

		case "failed":
			printf(1, "<tr bgcolor=\"#ffaaaa\"><th align=left width=50%%>%s</th><td>%f</td><td>%s</td><td>%s</td></tr>\n",
				{ data[2], pretty_sprint(data[5]), pretty_sprint(data[3]), data[4] })

			break

		case "passed":
			sequence anum
			if data[3] = 0 then
				anum = "0"
			else
				anum = sprintf("%f", data[3])
			end if
			printf(1, "<tr bgcolor=\"#aaffaa\"><th align=left width=50%%>%s</th><td>%s</td><td>&nbsp;</td><td>&nbsp;</td></tr>\n",
				{ data[2], anum })
			break

		case "summary":
			if length(unsummarized_files) then
				unsummarized_files = unsummarized_files[1..$-1] 
			end if
			puts(1, "</table><p>\n")

			printf(1, "<strong>Tests:</strong> %04d\n", { data[2] })
			printf(1, "<strong>Failed:</strong> %04d\n", { data[3] })
			printf(1, "<strong>Passed:</strong> %04d\n", { data[4] })
			printf(1, "<strong>Time:</strong> %f</p>\n", { data[5] })
			break
	end switch
end procedure


procedure summarize_error( sequence message, error_class e, integer html )
	if find( e, error_list[3] ) then
		if html then
			printf(1,message & "<br>\nThese were:\n", {sum(error_list[3] = e)} )
		else
			printf(1,message & "\nThese were:\n", {sum(error_list[3] = e)} )
		end if
		for i = 1 to length( error_list[1] ) do
				if error_list[3][i] = e then
					if html then
						printf( 1, "<a href='#%s'>%s</a>, ", repeat(error_list[1][i],2) )
					else
						printf( 1, "%s, ", repeat(error_list[1][i],1) )
					end if
				end if
		end for
		if html then
			puts(1, "<p>")
		end if
		puts(1, "\n" )
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
		out_r = routine_id( "html_out" )
	else
		out_r = routine_id( "ascii_out" )
	end if
	
	other_files = dir( "t_*.e" )
	if atom(other_files) then
		other_files = {}
	end if
	for i = 1 to length( other_files ) do
		other_files[i] = other_files[i][D_NAME]
	end for
	
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
		close( ctcfh )
	else
		ctc = 0
		ctcfh = 0
	end if
	
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
				
				case "failed":
					total_failed += 1
					total_time += data[5]
					break
	
				case "passed":
					total_passed += 1
					total_time += data[3]
					break
				
				case "file":
					integer ofi = find( data[2], other_files )
					if ofi != 0 then
						other_files = other_files[1..ofi-1] & other_files[ofi+1..$]
					end if
					while length(unsummarized_files)>=1 and compare(data[2],unsummarized_files[1])!=0 do
						call_proc( out_r, {{"summary",0,0,0,0}})
					end while

					break
					
			end switch

	
			call_proc( out_r, {data} )
			
			
		end for
	end if -- sequence(content)

	while length(unsummarized_files) do
		call_proc( out_r, {{"summary",0,0,0,0}})
	end while

	
	for i = 1 to length(other_files) do
		if find( other_files[i], error_list[1] ) then
			call_proc( out_r, {{"file",other_files[i]}} )
			call_proc( out_r, {{"summary",0,0,0,0}} )
		end if
	end for
	
	summarize_error( "%d interpreted tests failed unexpectedly", E_INTERPRET, html )
	summarize_error( "%d tests could not be translated", E_TRANSLATE, html )
	summarize_error( "%d translated tests could not be compiled", E_COMPILE, html )
	summarize_error( "%d compiled tests failed unexpectedly", E_EXECUTE, html )
	
	if html then
		if find(1, error_list[3] = E_EUTEST ) then
			printf(1, "There was an internal error to the testing system involving %s<br>",
			 				{error_list[1][find( E_EUTEST, error_list[3] )]} )
		end if
		puts(1, "<a name='summary'>\n" )
		puts(1, "<table style=\"font-size: 1.5em\"><tr><th colspan=2 align=left>Overall</th></tr>\n")
		printf(1, "<tr><th align=left>Total Tests:</th><td>%04d</td></tr>\n", { total_passed + total_failed })
		printf(1, "<tr><th align=left>Total Failed:</th><td>%04d</td></tr>\n", { total_failed })
		printf(1, "<tr><th align=left>Total Passed:</th><td>%04d</td></tr>\n", { total_passed })		
		printf(1, "<tr><th align=left>Total Time:</th><td>%f</td></tr>\n", { total_time })
		puts(1, "</table>\n")
		puts(1, "</body></html>\n")
	else
		puts(1, "***************************************************************************\n\n")
		printf(1, "Overall: Total Tests: %04d  Failed: %04d  Passed: %04d Time: %f\n\n", {
			total_passed + total_failed, total_failed, total_passed, total_time })
		puts(1, "***************************************************************************\n")
	end if
end procedure

procedure main(sequence cmds = command_line())
	if find("-help", cmds) or find("--help",cmds) or find("/?", cmds) then
		puts(2, "USAGE:\n" & cmds[1] & " eutest.ex [[-process-log] [-html]]\n"
		&"\t[-exe interpreter-path-and-filename]\n"
		&"\t[-ec translator-path-and-filename]\n"
		&"\t[-lib library-path-and-filename-relative-to-%EUDIR%\\bin]\n"
		&"\t[-cc [-wat|wat|some-other-compiler-name-to-pass-to-translator]]\n"
		&"\t[-log]\n"
		&"\t[-verbose]\n"
		&"\t[unit test files]\n")
		abort(0)
	end if  
	verbose_switch = (find("-verbose", cmds) != 0)
	
	if find("-process-log", cmds) then
		do_process_log(cmds)
	else
		do_test(cmds)
	end if
end procedure

main()
