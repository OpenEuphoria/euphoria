include std/get.e
include std/filesys.e
include std/os.e

constant rev = "revision=\""


procedure update_rev_e( object f )
	integer h
	puts(1,"updating be_rev.c\n")
	if atom(f) then
	    f = sprintf( "%d", { f } )
	end if
	h = open("be_rev.c", "w")
	printf(h, "extern char* get_svn_revision();\nchar * get_svn_revision() {\nreturn \"%s\";\n}\n", {f})
	close(h)
	h = open("rev.dat","w")
	printf(h,"%s",{f})
	close(h)
end procedure

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


-- Returns true iff the value SVN_REVISION in rev.e is set
-- to is equal to the value of rev passed here.
function is_current( object rev )
	integer fn
	integer current
	integer ix, jx
	object line
	fn = open( "be_rev.c", "r" )
	if fn = -1 then
		return 0
	end if

	if atom( rev ) then
		rev = sprintf( "%d", {rev} )
	end if

	current = 0
	while sequence( line ) with entry do
		ix = match( "return \"", line )
		if ix then
			ix += length("return \"")
			jx = find_from( '"', line, ix)
			if jx then
				if equal( line[ix..jx-1], rev ) then
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

-- function attemps to retrieve svnversion program
-- if the svnversion program is not on the system
-- or doesn't produce any output it returns 0.  If
-- svnversion does produce some string and this
-- string differs from what is already in rev.e, it
-- updates the rev.e file and returns 1

function rev_with_svnversion()
	integer x
	object line, path
	sequence n, dexe
	path = getenv( "PATH" )
	if atom(path) then
		return 0
	end if
	ifdef UNIX then
		dexe = ""
	elsedef
		dexe = ".exe"
	end ifdef

	line = locate_file( "svnversion"&dexe, path )
	if compare( line, "svnversion"&dexe ) = 0 then
		return 0
	else
		-- avoid having the rev.e string change from NNNNM to NNNN.

		-- If svnversion is found under DOS it will not be able to run
		-- it successfully if there is a space in its path.
		ifdef DOS32 then
			if find(' ',line) then
				puts(2,"This program must be interpreted using exwc.exe.")
				abort(0)
			end if
		end ifdef
	end if
	-- run svnversion with .. argument to include support directories
	system( "svnversion ..>rev.tmp", 0 )
	x = open( "rev.tmp", "r" )
	if x > -1 then
	  line = gets(x)
	  close(x)
	  if sequence( line ) and length(line) then
	  	n = line[1..$-1]
		if not is_current( n ) then
			update_rev_e( n )
		end if
		x += 0 * delete_file("rev.tmp")
		return 1
	  end if
	  close(x)
	end if
	x += 0 * delete_file("rev.tmp")
	return 0
end function

procedure unknown_rev()
	update_rev_e( "(unknown revision)" )
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
	unknown_rev()
	abort(1)
end if

if tryst then
	h = open("../.svn/entries", "r")
	if h = -1 then
		h = open("../svn~1/entries", "r")
	end if
else
	h = open(c[3], "r")
end if
if h = -1 then
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
	if is_numeric(f[i]) and i+1 < length(f)+1 then
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
	update_rev_e( n )
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
	unknown_rev()
	abort(1)
end if

if tryst then
	h = open("../.svn/entries", "r")
	if h = -1 then
		h = open("../svn~1/entries", "r")
	end if
else
	h = open(c[3], "r")
end if
if h = -1 then
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
        update_rev_e( f )
end if
end procedure


object djpc = command_line()


if not rev_with_svnversion() then
	rev_1_3()
end if

