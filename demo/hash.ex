-- Hash Table Demo
-- written by Junko C. Miura, RDS
-- This reads standard input and builds a hash table containing all of 
-- the unique words plus a count of how many times each word occurred.
-- It outputs the words to standard output and writes a bunch of hash table 
-- statistics to "hash.out".

-- example: 
--          ex hash < \euphoria\doc\library.doc
--
-- You can direct standard output to a file with '>'
-- hash.ex (hash table) is faster than tree.ex (binary tree),
-- but does not produce a sorted list of words.

-- How it Works:
-- * hashing is generally much faster than searching a long linear list for a 
--   word. Instead of searching one big list, we create hundreds of small
--   lists, and then use a "hash function" to tell us which small list (or
--   "bucket") to search. For each word, the hash function will return an 
--   integer. For a given word, the hash function must always return the same 
--   integer. That integer is used as the index into a sequence of small 
--   word-lists. We can quickly search the selected small list for the word.

without type_check

constant EOF = -1
constant STANDARD_IN = 0, STANDARD_OUT = 1, SCREEN = 2 
constant TRUE = 1
constant STRING = 1, COUNT = 2 -- fields for one hash table entry

constant HASH_BUCKETS = 1009  -- prime
    -- With the hash function below, it helps (a little bit) 
    -- to have a prime number here. Don't use a power of 2.
    -- You'll get better performance by using a
    -- bigger size of table, but it wastes space.

-- Initialize the hash table to a sequence of empty "buckets"
sequence hash_table
hash_table = repeat({}, HASH_BUCKETS)

integer compares
compares = 0

function hash_function(sequence string)
-- This function works well for English words.
-- It's fast to calculate and it gives a pretty even distribution.
-- These are the two properties that you want in a hash function.
    integer len
    atom val
    
    len = length(string)
    val = string[len] * 2 + len
    if len > 4 then
	len = 4
    end if
    for i = 1 to len - 1 do
	val = val * 64 + string[i]  -- shift 6 bits and add
    end for
    return remainder(val, HASH_BUCKETS) + 1
end function

procedure hash_add(sequence string)
-- If string is not in the table already, add it, with a count of 1, 
-- otherwise just increment its count.
    integer hash_val, found
    sequence bucket
    
    -- which bucket to search?
    hash_val = hash_function(string) 
    bucket = hash_table[hash_val]
    found = 0
    -- search this bucket for the string
    for i = 1 to length(bucket) do
	compares += 1
	if equal(string, bucket[i][STRING]) then
	    -- found it
	    found = i
	    exit
	end if
    end for
    if found then
	-- increment count
	bucket[found][COUNT] += 1
    else
	-- add new string with count 1:
	bucket = append(bucket, {string, 1})
    end if
    hash_table[hash_val] = bucket
end procedure

integer last_word = 0
function next_word()
-- Read standard input to get the next "word".
    integer c
    sequence word

    word = ""
    while TRUE do
	c = getc(STANDARD_IN)
	if (c >= 'a' and c <= 'z') then
	    word &= c
	elsif (c >= 'A' and c <= 'Z') then
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

procedure build_table()
-- build a hash table containing all unique words in standard input
    object word

    while not last_word do
		word = next_word()
		if atom(word) then
		    exit
		else
		    hash_add(word)
		end if
    end while
end procedure

puts(SCREEN, "terminate typed input with: control-Z Enter\n")

atom t
t = time()         -- Time the table-building process only
build_table() 
t = time() - t     -- stop timer


---------------- Statistics ------------------
integer numZeroBucket, max, items, len, stats, total_words

stats = open("hash.out", "w")
if stats = -1 then
    puts(SCREEN, "Couldn't open output file\n")
    abort(1)
end if
printf(stats, "time: %.2f\n", t)
numZeroBucket = 0
items = 0
max = 0
total_words = 0
for i = 1 to length(hash_table) do
    len = length(hash_table[i])
    items += len
    if len = 0 then
	numZeroBucket += 1
    else
	-- calculate total compares required to lookup all words again
	for j = 1 to length(hash_table[i]) do
	    total_words +=  hash_table[i][j][COUNT]
	end for
	if len > max then
	    max = len
	end if
    end if
end for

printf(stats, "number of hash table buckets     : %d\n", HASH_BUCKETS)
printf(stats, "number of words in input stream  : %d\n", total_words)
printf(stats, "number of items in hash table    : %d\n", items)
printf(stats, "number of empty buckets          : %d\n", numZeroBucket)
printf(stats, "largest bucket                   : %d\n", max)
if total_words then
    printf(stats, "compares per lookup              : %.2f\n", 
	       compares/total_words)
end if
puts(STANDARD_OUT,"\n\n")
for i = 1 to length(hash_table) do
    printf(stats, "\nbucket#%d: ", i)
    for j = 1 to length(hash_table[i]) do
	printf(stats, "%s:%d ", hash_table[i][j])
	printf(STANDARD_OUT, "%s:%d\n", hash_table[i][j])
	if remainder(j,5) = 0 then
	    puts(stats, '\n')
	end if
    end for
    if remainder(length(hash_table[i]), 5) then
	puts(stats, '\n')
    end if
end for

printf(SCREEN, "\n%.2f seconds\n", t)


