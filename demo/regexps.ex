include std/regex.e as re

procedure show_matches(sequence matches, sequence str)
	for i = 1 to length(matches)  do
		printf(1, "%d: %d-%d = '%s'\n", {i, matches[i][1][1], matches[i][1][2],
		str[matches[i][1][1]..matches[i][1][2]]})
	end for
end procedure

sequence str
re:regex r

str = "Fido, the dog, ran to Jimmy."
printf(1, "Getting the first names from '%s'\n", { str })
r = re:new("[A-Z][a-z]+")
show_matches(re:find_all(r, str), str)

str = "The two love birds, John Doe and Sally Smith, are to be married by Rev. Matt Parker."
printf(1, "\nGetting the first and last names from '%s'\n", { str })
r = re:new("([A-Z][a-z]+) ([A-Z][a-z]+)")
show_matches(re:find_all(r, str), str)
printf(1, "\nConverting First Name Last Name to Last, First in:\n%s\n", { str })

puts(1, re:find_replace(r, str, `\2, \1`) & "\n")

