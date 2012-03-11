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
constant BUILD_DIR = search:find_replace("/","../../build",SLASH)
constant tar_ball = search:find_replace("/",BUILD_DIR & "/euphoria-" & info:version_string_short() & ".tar.gz",SLASH)
object line = ""

ifdef not LINUX then
	printf(1, "This should be used under Linux.  You have been warned.\n",{})
end ifdef

puts(1,"Generating PKGBUILD for " & info:version_string_short() & "...")
with trace
process md5sum_p,
		awk_p    = pipeio:exec("gawk '{ print $1; }'", pipeio:create())
if not file_exists(tar_ball) then
	puts(1,"running tar...")
	integer tar_ball_fd = open(tar_ball,"wb")
	process tar_p = pipeio:exec(search:find_replace("/","tar  -cz -O ../win32/cleanbranch/{source,include,docs,bin,demo,tests,tutorial,file_id.diz,license.txt}",SLASH), pipeio:create())
	md5sum_p = pipeio:exec("md5sum", pipeio:create())
	while sequence(line) and length(line) entry do
		puts(tar_ball_fd, line)
		pipeio:write(md5sum_p[pipeio:STDIN], line)
		puts(1,'.')
	entry
		line = pipeio:read(tar_p[pipeio:STDOUT], 10240)
	end while
	pipeio:close(tar_p[pipeio:STDIN])
	close(tar_ball_fd)
else
	md5sum_p = pipeio:exec("md5sum " & tar_ball, pipeio:create())
end if

pipeio:close(md5sum_p[pipeio:STDIN])

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

