with trace
trace(1)

-- Tutorial - Append and Prepend to a Sequence

-- To run this tutorial, 
--        Press Enter to execute the highlighted Euphoria statement.
--        Press F1 to flip to the main output screen.
--        Press F2 to flip back to this trace screen.
--        Read the comments as you go.

-- We will:
--        1. make a sequence of 15 random numbers
--        2. append() all the even numbers into a variable called "even"
--        3. prepend() all the odd numbers into a variable called "odd"

sequence even, odd, random
even = {} -- it's a sequence, but it contains 0 elements

odd = {}  -- the same

random = repeat(30, 15) -- 30 repeated 15 times

random = rand(random)    -- 15 random numbers between 1 and 30

integer num -- convenient place to put the next number

-- Now we'll put the even numbers into even using append()
for i = 1 to length(random) do
    num = random[i]  -- the next random number
    -- if the remainder after dividing by 2 is 0, the number is even
    if remainder(num, 2) = 0 then
	even = append(even, num) -- add number at the end
    else
	odd = prepend(odd, num) -- add number on at the beginning
    end if
end for

-- display the even numbers
puts(1, "The even numbers are:\n")
? even  -- check it with F1/F2

-- display the odd numbers
puts(1, "The odd numbers are:\n")
? odd

