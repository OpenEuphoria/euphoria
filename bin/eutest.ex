#!/usr/bin/exu

-- Specify -exe <path to interpreter> to use a specific interpreter for tests

include sequence.e
include sort.e
include filesys.e

atom score
integer failed, total, status
sequence files, filename, executable, cmd, cmds, cmd_opts, options, switches

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

for i = 1 to total do
	filename = files[i][D_NAME]
	printf(1, "%s:\n", {filename})
	cmd = sprintf("%s %s -D UNITTEST -batch %s %s", {executable, options, filename, cmd_opts})
	status = system_exec(cmd, 2)
	if match("t_c_", filename) = 1 then
		status = not status
	end if
	failed += status > 0
end for

if total = 0 then
	score = 100
else
	score = ((total - failed) / total) * 100
end if

printf(1, "\n%d file(s) run %d file(s) failed, %.1f%% success\n", {total, failed, score})

abort(failed > 0)
