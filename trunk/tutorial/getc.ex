with trace
trace(1)

-- Tutorial - Read a File: One character at a time
-- To run this tutorial, 
--        Press Enter to execute the highlighted Euphoria statement.
--        Press F1 / F2 to flip to the main output screen.
--        Press down-arrow to execute quickly to the end of a loop

-- We will:
--        1. open the "tutorial.doc" file in this directory
--        2. count the number of new-line, '\n', characters
--        3. print the number of new-lines
--        4. close the file

integer fn    -- the file number
integer lines -- the number of lines ('\n' characters)
integer c     -- the next character from the file

-- First, we try to open the file called "tutorial.doc"
fn = open("tutorial.doc", "r")
if fn = -1 then
    puts(1, "Can't open tutorial.doc\n")
    abort(1)
end if
-- By successfully opening the file we have established that 
-- the file exists, and open() gives us a file number (or "handle") 
-- that we can use to perform operations on the file.

lines = 0
while 1 do   -- this is always true - apparently an "infinite" loop
    c = getc(fn)
    if c = -1 then
	exit -- no more characters, end of file, 
	     -- this is how we quit the loop
    end if
    if c = '\n' then
	lines = lines + 1  -- assume one \n per line in the file
    end if
    -- When you get bored, 
    -- Press down-arrow until you are out of the loop
end while

-- print the total number of lines
? lines

-- close the tutorial.doc file 
-- This is not really necessary, but you can only have 
-- 25 files open at any one time.
close(fn)

