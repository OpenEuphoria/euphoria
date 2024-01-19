-- docs.ex
-- print a list of file names would be created by eudoc / creole

include std/io.e
include std/filesys.e
include std/search.e
include std/sequence.e
include std/text.e

sequence cmd = command_line()
sequence file_names = {}

if length( cmd ) < 3 then
	puts(2, "usage: eui docs.ex path/to/manual.af\n")
	abort(1)
end if

sequence manual_file = canonical_path(cmd[3])
sequence manual_path = dirname(manual_file) & SLASH
sequence manual_lines = read_lines(manual_file)

for i = 1 to length(manual_lines) do
	manual_lines[i] = trim_head(manual_lines[i])

	if begins(":%%output=", manual_lines[i]) then
		file_names = append(file_names, manual_lines[i][11..$])

	elsif begins("../", manual_lines[i]) then

		if ends(" <nowiki", manual_lines[i]) != 0 then
			manual_lines[i] = manual_lines[i][1..$-8]
		end if

		sequence parts = split(manual_lines[i], SLASH)
		parts[$] = find_replace('.', filebase(parts[$]), '_')
		sequence name = join(parts[3..$], '_')

		if length(name) != 0 then
			file_names = append(file_names, name)
		end if

		if equal(fileext(manual_lines[i]), "txt") then
			object text_lines = read_lines(canonical_path(manual_path & manual_lines[i]))
			if atom(text_lines) then
				text_lines = {}
			end if
			for j = 1 to length(text_lines) do
				text_lines[j] = trim_head(text_lines[j])
				if begins("%%output=", text_lines[j]) then
					file_names = append(file_names, text_lines[j][10..$])
				end if
			end for
		end if

	end if

end for

for i = 1 to length(file_names) do
	printf(1, "%s.html\n", {file_names[i]})
end for

