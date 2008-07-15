include std/get.e 

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

function is_current( object rev )
	integer fn
	integer current
	integer ix, jx
	object line
	fn = open( "rev.e", "r" )
	if fn = -1 then
		return 0
	end if
	
	if sequence( rev ) then
		rev = value( rev )
		rev = rev[2]
	end if
	
	
	current = 0
	while sequence( line ) entry do
		ix = match( "SVN_REVISION = \"", line )
		if ix then
			jx = find_from( '"', line, ix + 17 )
			if jx then
				line = value( line[ix+16..jx-1] )
				if line[2] >= rev then
					current = 1
				end if
				exit
			end if
		end if
	entry
		line = gets( fn )
	end while
	
	return current
end function

procedure unknown_rev()
	integer fn
	fn = open( "rev.e", "r" )
	if fn != -1 then
		return
	end if
	fn = open( "rev.e", "w" )
	puts(fn, "global constant SVN_REVISION = \"???\"\n")
	close(fn)
end procedure

procedure rev_1_4()

sequence c
integer h
sequence f
object x
sequence g
integer n
integer tryst
tryst = 0

c = command_line()
if length(c) = 2 then
	tryst = 1
elsif length(c) != 3 then
	puts(2, "Incorrect usage.\n")
	abort(1)
end if

if tryst then
	h = open(".svn/entries", "r")
	if h = -1 then
		h = open("svn~1/entries", "r")
	end if
else
	h = open(c[3], "r")
end if
if h = -1 then
	puts(2, "Unable to open.\n")
	unknown_rev()
	abort(0)
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
	-- ^L is 12, apparently
	if is_numeric(f[i]) then
		if not equal(f[i+1], {12,10}) then
			g &= {f[i]}
		end if
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
if not is_current( n ) then
	h = open("rev.e", "w")
	printf(h, "global constant SVN_REVISION = \"%d\"\n", {n})
	close(h)
end if
end procedure

procedure rev_1_3()
sequence c
integer h
sequence f
object x
integer tryst
tryst = 0

c = command_line()
if length(c) = 2 then
	tryst = 1
elsif length(c) != 3 then
	puts(2, "Incorrect usage.\n")
	abort(1)
end if

if tryst then
	h = open(".svn/entries", "r")
	if h = -1 then
		h = open("svn~1/entries", "r")
	end if
else
	h = open(c[3], "r")
end if
if h = -1 then
	puts(2, "Unable to open.\n")
	unknown_rev()
	abort(0)
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
if not is_current( f ) then
puts(1,"updating rev.e\n")
	h = open("rev.e", "w")
	printf(h, "global constant SVN_REVISION = \"%s\"\n", {f})
	close(h)
end if
end procedure

rev_1_3()
