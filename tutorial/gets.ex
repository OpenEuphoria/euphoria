with trace
trace(1)
-- Tutorial - Read a File: One line at a time
-- To run this tutorial, 
--        Press Enter to execute the highlighted Euphoria statement.
--        Press F1 / F2 to flip to the main output screen.
--        Press down-arrow to execute quickly to the end of a loop

-- We will:
--        1. open the "tutorial.doc" file in this directory
--        2. See how many lines contain the word "Euphoria"
--        3. print the number of lines containing "Euphoria"
--        4. close the file

integer fn    -- the file number
integer e     -- the number of lines that contain "Euphoria"
object line   -- the next line from the file

-- First, we try to open the file called "tutorial.doc"
fn = open("tutorial.doc", "r")
if fn = -1 then
	puts(1, "Can't open tutorial.doc\n")
	abort(1)
end if
-- By successfully opening the file we have established that 
-- the file exists, and open() gives us a file number (or "handle") 
-- that we can use to perform operations on the file.

e = 0
while sequence(line) entry do   -- this is always true - apparently an "infinite" loop
	if match("Euphoria", line) then
		e = e + 1 
	end if
  entry
	line = gets(fn)
	-- When you get bored, 
	-- Press down-arrow until you are out of the loop
end while

-- Print the total number of lines containing "Euphoria".
-- We need \" to get a double-quote within a string.
-- %d formats for an integer value in base 10 (decimal)
-- 1 prints to the screen (standard output)
printf(1, "%d lines contain \"Euphoria\"\n", e)

-- close the tutorial.doc file 
-- This is not really necessary, but you can only have 
-- 25 files open at any one time.
close(fn)

