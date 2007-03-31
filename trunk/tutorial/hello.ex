with trace
trace(1)

-- Tutorial - Print Hello World on the Screen

-- To run this tutorial, 
--        Press Enter to execute the highlighted Euphoria statement.
--        Press F1 to flip to the main output screen.
--        Press F2 to flip back to this trace screen.
--        Read the comments as you go.

-- Step 1: Just to be neat - we'll clear the screen.
-- First, press F1 then F2.
-- Then press Enter:
clear_screen() 
-- Check again with F1/F2 - was the screen cleared?

-- Step 2: Let's position the cursor at line 10, column 30
position(10, 30)  
-- Is the cursor now at 10,30? Press F1/F2

-- Step 3: Display the text:
puts(1, "Hello World")  
-- Is the text there? Press F1/F2

-- Step 4 Output 2 blank lines and we're done
puts(1, "\n\n")



