constant rev = "revision=\""
sequence c
integer h
sequence f
object x

c = command_line()
if length(c) != 3 then
	puts(2, "Incorrect usage.\n")
	abort(1)
end if

h = open(c[3], "r")
if h = -1 then
	puts(2, "Unable to open.\n")
	abort(1)
end if

x = gets(h)
f = ""
while not atom(x) do
	f &= {x}
	x = gets(h)
end while
close(h)

for i = 1 to length(f) do
	h = match(rev, f[i])
	if h then
		f = f[i]
		f = f[h+length(rev)..length(f)]
		exit
	end if
end for

if not length(f) or not atom(f[1]) then
	-- newer subversion 1.4 client wc isn't in xml format
	-- use different parser to guess
	c[2] = "revget4.ex"
	system("\""&c[1]&"\" \""&c[2]&"\" \""&c[3]&"\"", 2)
	abort(0)
end if

f = f[1..find('"', f)-1]
--puts(1, f)

h = open("rev.e", "w")
printf(h, "global constant SVN_REVISION = \"%s\"\n", {f})
close(h)

