#!/usr/bin/exu

-- Specify -exe <path to interpreter> to use a specific interpreter for tests

include std/sequence.e
include std/sort.e
include std/filesys.e

atom score
integer failed, total, status
sequence files, filename, executable, cmd, cmds, cmd_opts, options, switches
sequence 
	translator = "", 
	library = ""

files = {}
failed = 0
cmd_opts = ""

ifdef UNIX then
	executable = "exu"
elsifdef WIN32 then
	executable = "exwc"
else
	executable = "ex"
end ifdef

cmds = command_line()

integer ex = find( "-exe", cmds )
if ex and ex < length( cmds ) then
	executable = cmds[ex+1]
	cmds = cmds[1..ex-1] & cmds[ex+2..$]
end if

integer ec = find( "-ec", cmds )
if ec and ec < length( cmds ) then
	translator = cmds[ec+1]
	cmds = cmds[1..ec-1] & cmds[ec+2..$]
end if

integer lib = find( "-lib", cmds )
if lib and lib < length( cmds ) then
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
	files = sort( dir("t_*.e") )
end if

total = length(files)

switches = option_switches()
options = join( switches )

sequence fail_list = {}

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
		fail_list = append( fail_list, filename )
	end if
	
	if length( translator ) then
		printf(1, "translate %s:\n", {filename})
		cmd = sprintf("%s %s %s -D UNITTEST -D EC -batch %s", {translator, library, options, filename})
		status = system_exec( cmd, 2 )
		if match( "t_c_", filename ) = 1 then
			status = not status
			
		elsif not status then
			lib = find( '.', filename )
			if lib then
				filename = filename[1..lib-1]
			end if
			if delete_file( filename ) then end if
			status = system_exec( "./emake", 2 )
			
			if not status then
				cmd = sprintf("./%s %s", {filename, cmd_opts})
				status = system_exec( cmd, 2 )
				if match( "t_c_", filename ) = 1 then
					status = not status
				end if
			end if
		end if
		if status > 0 then
			failed += status > 0
			fail_list = append( fail_list, "translated " & filename )
		end if
	
	end if
	
end for
total *= 2 -- also account for translated tests
if total = 0 then
	score = 100
else
	score = ((total - failed) / total) * 100
end if

puts(1, "\nTest failure summary:\n")
for i = 1 to length( fail_list ) do
	printf(1, "    FAIL: %s\n", {fail_list[i]})
end for
printf(1, "\n%d file(s) run %d file(s) failed, %.1f%% success\n", {total, failed, score})

abort(failed > 0)
