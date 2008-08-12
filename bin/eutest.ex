#!/usr/bin/exu

-- Specify -exe <path to interpreter> to use a specific interpreter for tests

include std/pretty.e
include std/sequence.e
include std/sort.e
include std/filesys.e
include std/io.e
include std/get.e

procedure do_test(sequence cmds)
	atom score
	integer failed = 0, total, status
	sequence files = {}, filename, executable, cmd, cmd_opts = "", options, switches
	sequence translator = "", library = ""

	ifdef UNIX then
		executable = "exu"
	elsifdef WIN32 then
		executable = "exwc"
	else
		executable = "ex"
	end ifdef

	integer log = find("-log", cmds)

	integer ex = find("-exe", cmds)
	if ex and ex < length(cmds) then
		executable = cmds[ex+1]
		cmds = cmds[1..ex-1] & cmds[ex+2..$]
	end if

	integer ec = find("-ec", cmds)
	if ec and ec < length(cmds) then
		translator = cmds[ec+1]
		cmds = cmds[1..ec-1] & cmds[ec+2..$]
	end if

	integer lib = find("-lib", cmds)
	if lib and lib < length(cmds) then
		library = "-lib " & cmds[lib+1]
		cmds = cmds[1..lib-1] & cmds[lib+2..$]
	end if

	if length(cmds) > 2 then
		cmd_opts = join(cmds[3..$])
	end if

	for i = 3 to length(cmds) do
		if cmds[i][1] != '-' then
			files &= {{cmds[i]}}
		end if
	end for

	if length(files) = 0 then
		files = sort(dir("t_*.e"))
	end if

	total = length(files)

	switches = option_switches()
	options = join(switches)

	sequence fail_list = {}
	if delete_file("unittest.dat") then end if
	if delete_file("unittest.log") then end if

	for i = 1 to total do
		filename = files[i][D_NAME]
		printf(1, "%s:\n", {filename})
		cmd = sprintf("%s %s -D UNITTEST -batch %s %s", {executable, options, filename, cmd_opts})
		status = system_exec(cmd, 2)
		if match("t_c_", filename) = 1 then
			status = not status
		end if
		if status > 0 then
			failed += status > 0
			fail_list = append(fail_list, filename)
		end if

		if length(translator) then
			printf(1, "translate %s:\n", {filename})
			cmd = sprintf("%s %s %s -D UNITTEST -D EC -batch %s", {translator, library, options, filename})
			status = system_exec(cmd, 2)
			if match("t_c_", filename) = 1 then
				status = not status

			elsif not status then
				lib = find('.', filename)
				if lib then
					filename = filename[1..lib-1]
				end if
				if delete_file(filename) then end if
				ifdef UNIX then
					status = system_exec("./emake", 2)
				else
					status = system_exec("emake.bat", 2)
				end ifdef
				if not status then
					cmd = sprintf("./%s %s", {filename, cmd_opts})
					status = system_exec(cmd, 2)
					if match("t_c_", filename) = 1 then
						status = not status
					end if

					ifdef UNIX then
						if delete_file(filename) then end if
					else
						if delete_file(filename & ".exe") then end if
					end ifdef
				end if
			end if
			if status > 0 then
				failed += status > 0
				fail_list = append(fail_list, "translated " & filename)
			end if

		end if
	end for

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

procedure ascii_out(sequence data)
	switch data[1] do
		case "file":
			printf(1, "%s\n", { data[2] })
			puts(1, "===========================================================================\n")
			break

		case "failed":
			printf(1, "  Failed: %s (%f) expected ", { data[2], data[5] })
			pretty_print(1, data[3], {2, 2, 12, 78, "%d", "%.15g"})
			puts(1, " got ")
			pretty_print(1, data[4], {2, 2, 12, 78, "%d", "%.15g"})
			puts(1, "\n")
			break

		case "passed":
			printf(1, "  Passed: %s (%f)\n", { data[2], data[3] })
			break

		case "summary":
			puts(1, "---------------------------------------------------------------------------\n")
				sequence status
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

procedure html_out(sequence data)
	switch data[1] do
		case "file":
			printf(1, "<table width=100%%><tr bgcolor=#dddddd><th colspan=4 align=left>%s</th></tr>\n", { data[2] })
			break

		case "failed":
			printf(1, "<tr bgcolor=\"#ffaaaa\"><th align=left>%s</th><td>%f</td><td>%s</td><td>%s</td></tr>\n",
				{ data[2], pretty_sprint(data[5]), pretty_sprint(data[3]), data[4] })

			break

		case "passed":
			printf(1, "<tr bgcolor=\"#aaffaa\"><th align=left>%s</th><td>%f</td><td>-</td><td>-</td></tr>\n",
				{ data[2], data[3] })
			break

		case "summary":
			puts(1, "</table><p>\n")
			printf(1, "<strong>Tests:</strong> %04d\n", { data[2] })
			printf(1, "<strong>Failed:</strong> %04d\n", { data[3] })
			printf(1, "<strong>Passed:</strong> %04d\n", { data[4] })
			printf(1, "<strong>Time:</strong> %f</p>\n", { data[5] })
			break
	end switch
end procedure

procedure do_process_log(sequence cmds)
	integer total_failed=0, total_passed=0
	integer html = find("-html", cmds)
	atom total_time = 0

	object content = read_file("unittest.log")
	if atom(content) then
		puts(1, "unittest.log could not be read\n")
		abort(1)
	end if

	if html then
		puts(1, "<html><body>\n")
	end if

	sequence messages = split(content, "entry = ")
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
		end switch

		if html then
			html_out(data)
		else
			ascii_out(data)
		end if
	end for

	if html then
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
	if find("-process-log", cmds) then
		do_process_log(cmds)
	else
		do_test(cmds)
	end if
end procedure

main()
