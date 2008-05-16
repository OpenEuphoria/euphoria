include file.e
include wildcard.e

integer status, file_check_id

function file_check(sequence path, sequence dir_entry)
-- spell check one file
	if match(".htx", lower(dir_entry[D_NAME])) then
		system("ex spellchk " & dir_entry[D_NAME], 2)
	end if
	return 0
end function

system("del badwords.txt", 2)

file_check_id = routine_id("file_check")

status = walk_dir(".", file_check_id, 0)

puts(1, "\nSee badwords.txt\n")
