include std/math.e
include euphoria/keywords.e

integer fh = open("builtins.txt", "w")

puts(fh, `
== Built-in Methods

These methods are built into Euphoria and require no includes.


`)

integer x = 1
for i = 1 to length(builtins) do
	printf(fh, "* [[:%s]]\n", { builtins[i] })
end for

printf(fh, "\n")

close(fh)
