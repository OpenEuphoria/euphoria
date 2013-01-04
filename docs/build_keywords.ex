include std/math.e
include euphoria/keywords.e

integer fh = open("keywords.txt", "w")

puts(fh, `
== Euphoria Keywords

The **keywords** are part of the Euphoria language and are //reserved// for the exclusive use of the interpreter. 
You can not used them as identifiers for your own variables or routines.


`)

integer x = 1
for i = 1 to length( keywords) do
	if equal(keywords[i], "?") then
		printf(fh, "| ##[[%s -> :q_print]]## ", { keywords[i] })
	else
		printf(fh, "| ##[[:%s]]## ", { keywords[i] })
	end if

	if x = 4 then
		printf(fh, "|\n")
		x = 1
	else
		x += 1
	end if
end for

if x > 1 then
	for i = x - 1 to 4 do
		printf(fh, " | ")
	end for
end if

printf(fh, "\n")

close(fh)
