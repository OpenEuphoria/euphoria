include get.e 
constant rev = "revision=\""

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

procedure rev_1_4()

sequence c
integer h
sequence f
object x
sequence g
integer n

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

n = f[1]
for i = 2 to length(f) do
	if f[i] > n then
		n = f[i]
	end if
end for

h = open("rev.e", "w")
printf(h, "global constant SVN_REVISION = \"%d\"\n", {n})
close(h)
end procedure

procedure rev_1_3()
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
	rev_1_4()
	return
end if

f = f[1..find('"', f)-1]
--puts(1, f)

h = open("rev.e", "w")
printf(h, "global constant SVN_REVISION = \"%s\"\n", {f})
close(h)
end procedure

rev_1_3()
