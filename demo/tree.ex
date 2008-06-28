-- Count frequencies of words in standard input.
-- Uses a binary tree to speed lookups and write
-- an alphabetic listing to standard output.

-- usage: 
--        ex tree < file1 
--
-- You can direct standard output to a file with '>'

-- How it Works:
-- * tree.ex reads in words from a text file and inserts them
--   alphabetically into a Euphoria sequence that is being used
--   as a "tree". The tree data structure is created by nesting
--   sequences inside one another to whatever depth is required.
--   Looking up a word in a tree is generally faster than searching
--   through a linear list, since unless the tree is very lop-sided,
--   we should have fewer comparisons to make.

without type_check

constant EOF = -1
constant TRUE = 1

constant STANDARD_IN = 0,
	 STANDARD_OUT = 1,
	 SCREEN = 2

constant NAME = 1,
	 COUNT = 2,
	 LEFT = 3,
	 RIGHT = 4

integer last_word = 0
function next_word()
-- read standard input to get next alphabetic string 
    integer c
    sequence word

    word = ""
    while TRUE do
	c = getc(STANDARD_IN)
	if (c >= 'A' and c <= 'Z') or
	   (c >= 'a' and c <= 'z') then
	    word &= c
	else
		last_word = (c = EOF)
		if length(word) > 0 then
		    return word
		elsif c = EOF then
			return 0
		end if
    end if
	end while
end function

function insert(sequence node, sequence word)
-- Insert new word into tree or increment existing word count by 1.
-- Return modified node.
-- This is quite fast since internally Euphoria is copying
-- pointers to subtrees, *not* all the data as it might appear. 
    integer x

    if length(node) = 0 then
	-- couldn't find it - create new node
	node = {word, 1, {}, {}}
    else 
	x = compare(word, node[NAME])
	if x = 0 then
	    node[COUNT] += 1                       -- found it, increment count 
	elsif x < 0 then
	    node[LEFT] = insert(node[LEFT], word)  -- insert it on the left
	else
	    node[RIGHT] = insert(node[RIGHT], word)-- insert it on the right
	end if
    end if
    return node
end function

procedure printTree(sequence node)
-- recursively print tree information
-- in alphabetical order
    if length(node) = 0 then
	return
    end if
    printTree(node[LEFT])
    printf(STANDARD_OUT, "%s:%d\n", {node[NAME], node[COUNT]})
    printTree(node[RIGHT])
end procedure

-- root of the whole tree
sequence root 
root = {}

procedure word_count()
-- build a binary tree containing words in standard input
    object word

    while not last_word do
		word = next_word()
		if atom(word) then
		    exit
		end if
		root = insert(root, word)
    end while
end procedure

puts(SCREEN, "terminate typed input with: control-Z Enter\n")

atom t
t = time()         -- Time the table-building process only
word_count() 
t = time() -t      -- Stop timer
puts(STANDARD_OUT,"\n\n")
printTree(root)
printf(2, "\n%.2f seconds\n\n", t)

