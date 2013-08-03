-- Program generates a PKGBUILD file for you.
-- Just run with the interpreter that has the same version as your package
-- without arguments.

-- This currently gets stuck after running tar.  Run it twice for now.
include std/pipeio.e
include euphoria/info.e
include std/io.e
include std/search.e
include std/filesys.e
include std/os.e

-- the maximum size we expect for the archive: Slackware's package is 11M but includes all of the binaries.
constant archive_limit = 10_000_000 


constant BUILD_DIR = "../../build"
constant tar_ball = BUILD_DIR & "/euphoria-" & info:version_string_short() & ".tar.gz"
object line = ""

puts(1, "Program should be run by the version of the EUPHORIA you wish to create an installer for.\nPress ENTER")
gets(0)

ifdef not LINUX then
	printf(1, "This should be used under Linux.  You have been warned.\n",{})
end ifdef

puts(1,"Generating PKGBUILD for " & info:version_string_short() & "...")
constant SIMPLE_RUN = 2 -- for use with system: run without clearing the screen or waiting for ENTER
system(sprintf("rm -fr euphoria-%s", repeat(info:version_string_short(),1)), SIMPLE_RUN)
if file_exists("../win32/cleanbranch") then
	-- get up to date
	system(sprintf("hg -R ../win32/cleanbranch pull", {}), SIMPLE_RUN)
	-- update to the branch
	system(sprintf("hg -R ../win32/cleanbranch update -r %s --clean", repeat(info:version_string_short(),1)), SIMPLE_RUN)
	create_directory(sprintf("euphoria-%s", repeat(info:version_string_short(),1)), 0t755)
	system("ln -sf `pwd`/../win32/cleanbranch/{source,include,bin,demo,docs,tests,tutorial,file_id.diz,License.txt} euphoria-" & info:version_string_short(), SIMPLE_RUN)
	create_directory(sprintf("euphoria-%s/source/build", repeat(info:version_string_short(),1)))
	delete_file("euphoria-" & info:version_string_short() & "/source/build/html")
	system(sprintf("ln -sf `pwd`/../../source/build/html euphoria-%s/source/build/html", repeat(info:version_string_short(),1)), SIMPLE_RUN)
	system(sprintf("ln -sf `pwd`/../../source/build/euphoria.pdf euphoria-%s/source/build/euphoria.pdf", repeat(info:version_string_short(),1)), SIMPLE_RUN)
else
	puts(1, "Please clone this into ../win32/cleanbranch first")
	abort(1)
end if


process md5sum_p,
		awk_p    = pipeio:exec("gawk '{ print $1; }'", pipeio:create())
puts(1,"archiving, compressing and creating md5sum...")
integer tar_ball_fd = open(tar_ball,"wb")
process tarz_p = pipeio:exec("tar -czh -O " &  
	" euphoria-" & info:version_string_short(), pipeio:create())
md5sum_p = pipeio:exec("md5sum", pipeio:create())
integer size = 0
while sequence(line) and length(line) and size < archive_limit entry do
	puts(tar_ball_fd, line)
	pipeio:write(md5sum_p[pipeio:STDIN], line)
	puts(1,'.')
entry
	line = pipeio:read(tarz_p[pipeio:STDOUT], 10240)
	size += 10240
end while
pipeio:close(tarz_p[pipeio:STDIN])
close(tar_ball_fd)
pipeio:close(md5sum_p[pipeio:STDIN])

if size >= archive_limit then
	puts(1, "Error!  Runaway archiving with tar: archive reached 40MB. (shouldn\'t happen)")
        abort(1)
end if

sequence sum = ""
while length(line) = 0 or find('\n',line)=0 entry do
	if length(line) = 0 then
		sleep(0.10)
	else
		pipeio:write(awk_p[pipeio:STDIN], line)
		puts(1,'o')
	end if
entry
	line = pipeio:read(md5sum_p[pipeio:STDOUT], 10)
end while
pipeio:close(md5sum_p[pipeio:STDOUT])
pipeio:write(awk_p[pipeio:STDIN], line & 10)
pipeio:close(awk_p[pipeio:STDIN])

while compare(line,"")=0 or (sequence(line) and line[$] != '\n') entry do
	if length(line) then
		sum = sum & line
		puts(1,'*')
	else
		sleep(0.10)
	end if
entry
	line = pipeio:read(awk_p[pipeio:STDOUT], 1)
end while
pipeio:close(awk_p[pipeio:STDOUT])
pipeio:close(awk_p[pipeio:STDIN])

if sum[$] = '\n' then
	sum = sum[1..$-1]
end if
sequence pkgbuild = read_file("PKGBUILD.fmt", TEXT_MODE)
pkgbuild = search:match_replace("VERSION", pkgbuild, info:version_string_short())
pkgbuild = search:match_replace("SUM", pkgbuild, sum)
write_file("PKGBUILD", pkgbuild, TEXT_MODE)
printf(1, "...done.\n", {})

