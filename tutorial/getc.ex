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
integer last_c -- the last character read

constant EOF = -1       -- Give the 'end-of-file' marker a name.
constant NEWLINE = '\n' -- Give the 'new line' marker a name

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
last_c = NEWLINE       -- initialize this in case the file is actually empty.
c = getc(fn)       -- get the first character from the file
while c != EOF do   -- begin loop and continue until we get an 'EOF' marker.
	if c = NEWLINE then
		lines = lines + 1  -- count the number of new line markers in the file.
	end if
	
	last_c = c  -- save the character just read so we can tell what was the 
	            -- last character in the file when the loop ends.
	
	c = getc(fn)  -- get the next character
	
	-- When you get bored, 
	-- Press down-arrow until you are out of the loop
end while

if last_c != NEWLINE then
    -- The last character was not a new line sp we better count it too.
	lines += 1	-- Note. This is a short cut for adding something to a variable.
	            --       It is the same as lines = lines + 1
end if
-- print the total number of lines
? lines

-- close the tutorial.doc file 
-- This is not really necessary, but you can only have 
-- 25 files open at any one time.
close(fn)

