include std/unittest.e
include std/task.e
include std/filesys.e
include std/io.e
include std/math.e

sequence vResults
sequence xResults
integer fc = 0

function calchash(integer ch, atom prevhash)
	ch += 1
	prevhash = xor_bits(prevhash * 3, ch * (ch + 1) * 5) + ch
	prevhash += rotate_bits(prevhash, remainder(ch, 32) )
	prevhash = and_bits(prevhash, 0xFFFFFFFF)
	return prevhash
end function

procedure file_counter( sequence filename, integer resultpos)
	integer fh
	integer ch
	atom hashval
	atom savepos
	integer ctr
	
	hashval = 0x6094F41E
	savepos = 0
	fh = open(filename, "rb")
	ctr = 0
	while ch != -1 with entry do
		hashval = calchash(ch, hashval)
		if ctr >= 300 and ch = 'e' then
			-- Time to give another task a go.
			ctr = 0
			
			-- Do this so I don't have too many simultaneous opened files.
			savepos = where(fh) 
			close(fh)
			
			-- Yield to the next ready task
			task_yield()
			
			-- Restore my place in the file.
			fh = open(filename, "rb")
			seek(fh, savepos)
		end if
	entry
		ch = getc(fh)
		ctr += 1
	end while
	close(fh)

--	writefln("[:25] [Xz:8] [2]",{filename, hashval})
	vResults[resultpos] = {filename, hashval}
	
end procedure


procedure xfile_counter( sequence filename, integer resultpos)
	integer fh
	integer ch
	atom hashval
	
	hashval = 0x6094F41E
	fh = open(filename, "rb")
	while ch != -1 with entry do
		hashval = calchash(ch, hashval)
	entry
		ch = getc(fh)
	end while
	close(fh)

	xResults[resultpos] = {filename, hashval}
	
end procedure

integer ef = 1

procedure monitor()
	
	sequence tlist
	
	while length(tlist) > 2 with entry do
		task_yield()
	entry
		tlist = task_list()
	end while

	ef = 0
end procedure
task_schedule(task_create( routine_id("monitor"), {}), 1)

object dirlist

dirlist = dir("*.*")
if length(dirlist) > 5 then
	dirlist = dirlist[1..5]
end if

vResults = {}
for i = 1 to length(dirlist) do
	if not find('d', dirlist[i][D_ATTRIBUTES]) then
		if dirlist[i][D_NAME][1] = 't' then
			vResults &= 0
			task_schedule(task_create( routine_id("file_counter"), {dirlist[i][D_NAME], length(vResults)}), {0,0})
		end if
	end if
end for

include std/os.e
include std/sort.e

while ef do
	task_yield()
end while
xResults = {}
for i = 1 to length(dirlist) do
	if not find('d', dirlist[i][D_ATTRIBUTES]) then
		if dirlist[i][D_NAME][1] = 't' then
			xResults &= 0
			xfile_counter( dirlist[i][D_NAME], length(xResults))
		end if
	end if
end for

if task_self() = 0 then
	test_pass( "task self evaluated as atom" )
else
	test_fail( "task self evaluated as integer" )
end if

test_equal("Tasks dir hash", xResults, vResults)
test_report()

