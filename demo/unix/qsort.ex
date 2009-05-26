-- Calling a Euphoria routine from a C routine under Linux

-- In this demo, the C qsort() library routine calls the 
-- Euphoria qcompare() routine to compare any two items.

include std/dll.e
include std/machine.e

atom libc
integer qid, nitems, item_size, qsort, ncalls
atom qaddr, array

ncalls = 0

function qcompare(atom pa, atom pb)
-- pa and pb are pointers to the items in memory, passed from qsort()
    ncalls += 1
    return compare(peek(pa), peek(pb)) -- use standard Euphoria compare
end function

libc = open_dll("/lib/libc.so.6") -- standard C library
				  -- if this fails, try simply "libc.so"
if libc = 0 then
    puts(2, "couldn't find /lib/libc.so.6 - try just \"libc.so\"\n")
end if

qid = routine_id("qcompare")
qaddr = call_back(qid)  -- address for the Euphoria routine

qsort = define_c_proc(libc, "qsort", {C_POINTER, C_INT, C_INT, C_POINTER})

-- sort an array of 50 random bytes in memory
array = allocate(50)
poke(array, rand(repeat(255, 50)))
nitems = 50   -- 50 items
item_size = 1 -- one byte each

puts(1, "before sorting:\n")
? peek({array, 50})

c_proc(qsort, {array, nitems, item_size, qaddr})

puts(1, "\nafter sorting:\n")
? peek({array, 50}) -- after sorting

printf(1, "\nThere were %d calls to qcompare()\n", ncalls)

