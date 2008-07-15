	----------------------------------------------------------
	-- file sort - a tutorial example of a Euphoria program --
	----------------------------------------------------------

-- Alphabetically sorts the lines in a text file.
-- usage: 
--          ex filesort < source > dest
-- If you read from the keyboard, use control-Z (on DOS) to quit

include std/sort.e  -- This pulls in the standard Euphoria generic sort routine. It 
		-- will sort any type of data. e.g. sort({5, 1, 8, 9, 4}) or
		-- sort({1.5, 9, 0, -999.9e5}) or sort({"ABC", "FRED", "XX"})
		-- etc. see include\sort.e

constant TRUE = 1

procedure file_sort()   -- this is the main procedure
    sequence buffer,    -- these variables can be assigned sequence values
	     sorted_buffer  
    object line         -- this variable can be assigned *any* value, atom or
			-- sequence

    buffer = {}         -- initialize buffer to the empty sequence (0 lines)

    while TRUE do       -- "infinite loop"
	line = gets(0)  -- read a line (sequence of chars) from standard input 
			-- Type: control-Z (on DOS) to indicate end of file
	if atom(line) then -- gets(0) returns atom -1 on end of file
	    exit        -- quit the while loop
	end if
	
	buffer = append(buffer, line) -- add the line to the buffer of lines
				      -- buffer is a sequence of sequences
				      -- where each (sub)sequence represents
    end while                         -- one line of text

    sorted_buffer = sort(buffer) -- call the sort routine, it will compare
				 -- the lines against each other 
				 -- alphabetically and return a new, sorted
				 -- sequence of lines as a result

    for i = 1 to length(sorted_buffer) do
	puts(1, sorted_buffer[i]&'\n') -- write out the lines of text to 
    end for                       -- the standard output
end procedure

file_sort() -- execution starts here

   -- What are the good points about this program?
 
-- 1. The sizes of data structures are not declared.
--    In most languages, such as C, you would have to declare a somewhat
--    arbitrary maximum size for line and for buffer, or you would have to set
--    up a complicated system of allocating storage using malloc and free.

-- 2. gets() does not require you to specify the maximum length of line 
--    that can be read in. It will automatically create a sequence of 
--    characters of the appropriate length to hold each incoming line.

-- 3. The sort routine is very simple. It takes a sequence as an argument,
--    and returns a sequence as a result. In C, you might set up a 
--    complicated call to a quicksort routine, requiring you to pass in
--    a pointer to a compare function. You'd have to consult a manual to
--    figure out how to do this.

-- 4. You did not overspecify the loop counter, i, by declaring it
--    as a 16 or 32-bit integer. Its job is to count from 1 to the length
--    of the buffer - who cares how many bits should be allocated for it?

-- 5. Extended memory will automatically be used to let buffer grow
--    to a very large size. No 640K DOS limit.

-- 6. The program executes with full runtime safety checking for bad
--    subscripts, uninitialized variables etc.

-- 7. You can edit the program and immediately rerun it, without fussing
--    with compiler options, linker options, makefiles etc.

-- 8. This program is FAST! It will easily outperform the MS-DOS sort command
--    (machine language) and can handle much larger files. [see bench.doc]


