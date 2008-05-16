-- Spell check of a file. The default dictionary (EWORDS.TXT) or your own 
-- dictionary can be used.
-- The dictionary file:
--         - must have one word per line.
--         - must be all upper-case letters.
--         - does not have to be sorted, but performance-wise it helps.
-- You can sort a dictionary file by typing:
--     sort < yourDictionary > sortedDictionary
-- before using spellchk.
--
-- Usage:   ex spellchk yourFileName dictionaryFileName
--       or
--          ex spellchk yourFileName   <-- use default dictionary: WORDS.TXT
--       or
--          ex spellchk                <-- to enter file names as the response
--
-- Spell check is case-insensitive.

-- Written by Junko C. Miura of Rapid Deployment Software
-- Public Domain, use as you wish.

-- How it works:
-- 1. Each unique word in the user's document is stored in a hash table
--    in memory. 
-- 2. Each word of the dictionary is read in and looked up in the hash table.
--    When a word is matched, it is deleted from the hash table.
-- 3. The words that remain in the hash table after reading the whole
--    (51802-word) dictionary are the "bad" words that might be 
--    spelling mistakes.

without type_check

include wildcard.e

constant TRUE = 1
constant EOF = -1
constant KEYB = 0, DISPLAY = 1, ERROR = 2
constant INDEX_APOSTROPHE = 27, INDEX_BOGUS = 28

integer userFile, dictFile
sequence lookUpTable
sequence hashBucket, currentBucket

function delete_trailing_white(sequence name)
-- get rid of blanks, tabs, newlines at end of string
	while length(name) > 0 do
		if find(name[length(name)], "\n\r\t ") then
			name = name[1..length(name)-1]
		else
			exit
		end if
	end while
	return name
end function

function get_response(sequence query)
	-- It displays the query and returns the response after stripping the
	-- trailing white space. 
	sequence s
	
	puts(DISPLAY, query)
	s = gets(KEYB)
	puts(DISPLAY, '\n')
	return delete_trailing_white(s)
end function

sequence command

procedure openFiles()
-- get file names and open them 

	command = command_line()
	if length(command) = 3 then         -- if user typed only one file name
		command = append(command, "EWORDS.TXT")  -- assume default dictionary
	elsif length(command) < 3 then
		command = append(command, 
						 get_response("file name to be spell-checked? "))
		command = append(command,
						 get_response("dictionary name? (hit ENTER for " &
									  "the default (ie, EWORDS.TXT))"))  
		if length(command[4]) = 0 then
			command[4] = "EWORDS.TXT"
		end if
	end if
		
	userFile = open(command[3], "rb")
	if userFile = -1 then
		puts(ERROR, "couldn't open " & command[3] & '\n')
		abort(1)
	end if
	dictFile = open(command[4], "r")
	if dictFile = -1 then
		puts(ERROR, "couldn't open " & command[4] & '\n')
		abort(1)
	end if
end procedure

procedure initLookUpTable()
-- can be indexed with values from -1 to 255
	lookUpTable = repeat(INDEX_BOGUS, 257)
	for i = 'A' to 'Z' do                   -- 'A' to 'Z' map to 1 to 26
		lookUpTable[i + 2] = i - 'A' + 1
	end for
	for i = 'a' to 'z' do                   -- 'a' to 'z' map to 1 to 26
		lookUpTable[i + 2] = i - 'a' + 1
	end for
	lookUpTable['\'' + 2] = INDEX_APOSTROPHE
end procedure

function nextWord(integer fn)
-- read user's document to get the next alphabetic string. It only accepts 
-- letters that are registered as valid in the look-up-table.
	integer c
	sequence word

	word = ""
	while TRUE do
		c = getc(fn)
		if lookUpTable[c + 2] != INDEX_BOGUS then
			word = append(word, c)
		elsif length(word) > 0 then
			return word
		elsif c = EOF then
			return 0
		end if
	end while
end function

function calcHashValue(sequence word)
	-- Hash function based on the first two letters of a word.
	-- This hash function does not distribute the words evenly over
	-- the available buckets, like a good hash function should, but
	-- it has the advantage that the buckets are in sorted order.
	-- This helps when we read in the (hopefully) sorted dictionary. 
	integer i, j
			
	i = lookUpTable[word[1] + 2]
	if length(word) > 1 then
		j = lookUpTable[word[2] + 2]
	else                                -- blank is one of the bogus letters,
		j = INDEX_BOGUS                 -- but there are valid one-letter words
	end if
	return {i, j}
end function

procedure buildUserData()
-- Read words from user's document and insert them into the hash table
	object word 
	sequence bucket
	
	-- in below, 26 for 'A', 'a' to 'Z', 'z'. Plus '\'' and "bogus letters"
	-- including ' '.
	hashBucket = repeat(repeat({}, 28), 28)     
	
	while TRUE do
		word = nextWord(userFile)
		if sequence(word) then      -- not EOF yet
			bucket =calcHashValue(word)
			
			-- either (1)append the word in the list or (2)if the same 
			-- case-sensitive word is already in the list ignore the word
			if not find(word, hashBucket[bucket[1]][bucket[2]]) then
				hashBucket[bucket[1]][bucket[2]]
						= append(hashBucket[bucket[1]][bucket[2]], word)
			end if
		else                        -- EOF reached
			exit
		end if
	end while
end procedure

procedure goThroughDict()
-- read all words from the dictionary and look them up in the hash table
	object word
	sequence bucket, ub
	integer i
	
	currentBucket = {0, 0}          -- initialize to impossible value
	while TRUE do
		word = gets(dictFile)
		if sequence(word) then      -- not EOF yet
			-- word = word[1..length(word)-1]  -- remove \n
			word = delete_trailing_white(word)
			bucket = calcHashValue(word)
			
			-- treat all the same-spelling-but-different-case words as the
			-- same words (ie, case-insensitive) when spell checking
			if length(hashBucket[bucket[1]][bucket[2]]) > 0 then
				-- try to reuse the upper case bucket from last time
				if compare(currentBucket, bucket) != 0  then
					ub = upper(hashBucket[bucket[1]][bucket[2]])
					currentBucket = bucket
				end if
				while TRUE do
					i = find(word, ub)
					if i = 0 then
						exit
					else
						-- word found - mark as "deleted"
						hashBucket[bucket[1]][bucket[2]][i] = 0  
						ub[i] = 0
					end if
				end while
			end if
		else                        -- EOF reached
			exit
		end if
	end while
end procedure

procedure goThroughUserData()
-- Output the remaining words.
-- These "bad" words could not be found in the dictionary.
	integer outFile

	outFile = open("badwords.txt", "a")
	puts(outFile, "\n----------------\n" & "    " & command[3] & '\n')
	if outFile = -1 then
		puts(ERROR, "couldn't open badwords.txt\n")
		abort(1)
	end if
	for i = 1 to length(hashBucket) do
		for j = 1 to length(hashBucket[i]) do
			for k = 1 to length(hashBucket[i][j]) do
				if sequence(hashBucket[i][j][k]) then
					puts(outFile, hashBucket[i][j][k] & '\n')
				end if
			end for
		end for
	end for
	close(outFile)
end procedure

procedure displayHashTable()
-- Debug routine to see how many words hashed to each bucket.
-- Most buckets will be empty.
	for i = 1 to length(hashBucket) do
		for j = 1 to length(hashBucket[i]) do
			printf(1, "bucket (%2d, %2d) has %6d entries\n",
					  {i, j, length(hashBucket[i][j])})
		end for
	end for
end procedure


openFiles()

atom t
t = time()

initLookUpTable()
buildUserData()
-- displayHashTable()
goThroughDict()
goThroughUserData()


