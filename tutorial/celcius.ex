include get.e -- so we can use the prompt_number() function

-- Tutorial - Convert Fahrenheit to Celcius

-- In this tutorial we will:
--          1. Ask the user to enter a Fahrenheit temperature
--          2. Read a number from the user
--          3. Convert the number to Celcius
--          4. Print the result on the screen

-- Some variables:
atom ftemp     -- holds Fahrenheit temperature
atom ctemp     -- holds Celcius temperature

-- Prompt the user to enter a number:
-- We included the file "get.e", so we can use prompt_number().
ftemp = prompt_number("Enter a Fahrenheit temperature: ", {})
-- {} means the user can enter any number. 
-- If we said {10,20} he would have to enter a number from 10 to 20.

-- Now, using the magic formula, convert it to Celcius:
ctemp = 5/9 * (ftemp - 32)

-- Now print the Celcius temperature:
? ctemp

-- To be neat, we can print exactly 2 decimal places
-- by calling printf() - formatted print
printf(1, "with two decimal places: %.2f\n", ctemp)

