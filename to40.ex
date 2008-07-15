include std/io.e
include std/filesys.e
include std/search.e
include std/pretty.e
include std/console.e

puts(1, "You should have a backup of *ALL* files in the current directory\n")
puts(1, "before continuing. This program will change source code with no\n")
puts(1, "backup!\n\n")

sequence yn = prompt_string("Are you sure (YES to continue, any other key to exit)? ")
if not equal(yn, "YES") then
	abort(0)
end if

sequence std_incs = {
	"console.e", 
	"convert.e", 
	"database.e", 
	"datetime.e", 
	"dll.e", 
	"error.e", 
	"file.e", 
	"filesys.e", 
	"get.e", 
	"graphics.e", 
	"image.e", 
	"io.e", 
	"lcid.e", 
	"locale.e", 
	"localeconv.e", 
	"machine.e", 
	"map.e", 
	"math.e", 
	"mouse.e", 
	"msgbox.e", 
	"os.e", 
	"pretty.e", 
	"primes.e", 
	"regex.e", 
	"safe.e", 
	"search.e", 
	"sequence.e", 
	"sets.e", 
	"socket.e", 
	"sort.e", 
	"stack.e", 
	"stats.e", 
	"task.e", 
	"text.e", 
	"types.e", 
	"unicode.e", 
	"unittest.e", 
	"wildcard.e"
}

sequence exts = { "e", "eu", "ew", "ex", "exu", "exw" }
sequence files = {}
sequence lines
integer idx

for a = 1 to length(exts) do
	files &= dir("*." & exts[a])
end for

for file_idx = 1 to length(files) label "file_loop" do
	if atom(files[file_idx]) then 
		continue "file_loop"
	end if

	printf(1, "Processing file %s...", {files[file_idx][1]})
	lines = read_lines(files[file_idx][1])

	for line_idx = 1 to length(lines) label "line_loop" do
		if begins("include", lines[line_idx]) then
			for inc_idx = 1 to length(std_incs) label "inc_loop" do
				idx = match(std_incs[inc_idx], lines[line_idx])
				if idx and lines[line_idx][idx-1] = ' ' then
					lines[line_idx] = splice(lines[line_idx], "std/", idx)
					exit "inc_loop"
				end if
			end for
		end if
	end for

	printf(1, "%d\n", {
		write_lines(files[file_idx][1], lines)
	})
end for

