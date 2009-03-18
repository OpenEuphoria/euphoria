with trace
trace(1)

-- Tutorial - Sequences

-- To run this tutorial, keep pressing the Enter key 
-- to execute the next statement, and the F1 and F2
-- keys to flip between the main screen and this trace screen.

-- The most important feature of Euphoria is the "sequence".
-- Once you learn how sequences work, everything else is easy.

-- A sequence is just a collection of numbers, sort of like the
-- "array" in other programming languages, but much more flexible.
-- Here's an example of a simple sequence:
--               {5, 1, 9}
-- It's a collection of 3 numbers. The order is important.
-- {5,1,9} is certainly *not* equivalent to {1,9,5}.

-- Let's try some calculations:
? {5, 1, 9}
? {5, 1, 9} * 2
? {5, 1, 9} + {5, 1, 9}
-- Euphoria lets you perform arithmetic calculations on sequences.
-- The rules are fairly intuitive. You can also store a sequence
-- into a variable. First you have to declare a variable that
-- is allowed to hold a sequence:
sequence fred

fred = {5,1,9}
? fred
? fred * 2
? fred + fred



