include get.e 

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

function is_numeric(sequence s)
	for i = 1 to length(s) do
		if atom(s[i]) then
			if not find(s[i], "0123456789") then
				return 0
			end if
		else
			return 0
		end if
	end for
	return 1
end function

sequence g
g = {}
for i = 1 to length(f) do
	while length(f[i]) and f[i][length(f[i])] = '\n' do
		f[i] = f[i][1..length(f[i])-1]
	end while
	while length(f[i]) and f[i][length(f[i])] = '\r' do
		f[i] = f[i][1..length(f[i])-1]
	end while
	--if length(f[i]) = 3 then
	if is_numeric(f[i]) then
		g &= {f[i]}
	end if
end for

if not length(g) then
	? -1
	abort(0)
end if

f = g
for i = 1 to length(g) do
	f[i] = value(g[i])
	f[i] = f[i][2]
end for
integer n
n = f[1]
for i = 2 to length(f) do
	if f[i] > n then
		n = f[i]
	end if
end for

h = open("rev.e", "w")
printf(h, "global constant SVN_REVISION = \"%d\"\n", {n})
close(h)

