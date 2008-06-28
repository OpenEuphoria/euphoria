include regex.e as re

sequence str, matches
re:regex r

str = "Fido the dog ran to Jimmy."
r = re:new("[A-Z][a-z]+")
matches = re:search_all(r, str)
for i = 1 to length(matches)  do
    printf(1, "%d: %d-%d = '%s'\n", {i, matches[i][1][1], matches[i][1][2],
	str[matches[i][1][1]..matches[i][1][2]]})
end for

