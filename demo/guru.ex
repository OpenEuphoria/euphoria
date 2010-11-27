--****
-- === guru.ex
--
-- Searches for the best articles that contain the words that you type.
-- Each word can contain * and ? wildcard characters.
-- The articles are given a score and presented to you sorted by score.
-- The scoring system strongly favors articles that contain several of 
-- your words, rather than just several occurrences of one of your words.
-- Some very common words are ignored (see noise_words).
-- e.g.
-- {{{
-- guru sequence* atom *pend g?r?
-- }}}
--
-- Results are displayed on screen and also saved in "c:\guru.out"
-- or $HOME/guru.out (Linux).
--
-- ==== Hints
-- * remember to add * to words that can be pluralized or have many different endings.
-- * enter an important word twice to double the value of that word  
-- * If you get a "Critical Error", type 'i' for ignore. It just
--   means that a file is currently locked by another application.
--
-- ==== Usage
--
-- to search EUPHORIA directories:
-- {{{
-- guru word1 word2 word3 ...
-- }}}
--
-- Euphoria .doc and other files are searched. .htm files are skipped.
--
-- To search the current directory and all subdirectories:
-- {{{
-- cdguru word1 word2 word3 ...
-- }}}
--

without type_check

include std/filesys.e
include std/wildcard.e
include std/graphics.e as g
include std/sort.e
include std/sequence.e
include std/text.e

-------- some user-modifiable parameters: 

sequence log_name, log_path, home

log_name = "guru.out"
-- place to store results
ifdef UNIX then
	home = getenv("HOME")
	if sequence(home) then
		log_path = home & '/' & log_name -- put in home dir if possible
	else
		log_path = log_name
	end if
elsedef
	log_path = getenv("EUDIR")
	if equal(log_path, -1) then
		log_path = "C:"
	end if
	log_path &= "\\" & log_name -- put at top of C drive
end ifdef

-- some files to skip:
sequence skip_list
ifdef UNIX then
	skip_list = {
		"*.so", "*.lib", "*.o",
		"*.tar", "*.zip", "*.gz", "*.dylib"
	}
elsedef
	skip_list = {
		"*.EXE", "*.DLL", "*.LIB", "*.OBJ",
		"*.SWP", "*.PAR", "*.ZIP", "*.BMP",
		"*.GIF", "*.JPG", "*.WAV"
	}
end ifdef

-- ignore these extremely common words when searching
sequence noise_words
noise_words = {
	"a", "an", "the", "to", "and", "of", "is", "or", "by", "as", "in",
	"you", "are", "be", "if", "?", "*"
}
constant separator_line = repeat('-', 5)

constant MAX_CHUNKS = 20 -- maximum number of chunks to display

-- desired size for a chunk of text:
constant MIN_CHUNK_SIZE = 10, -- minimum number of lines
	MAX_CHUNK_SIZE = 20 -- maximum number of lines

constant LEFT_HIGHLIGHT = 17, -- highlight markers for matched words
	RIGHT_HIGHLIGHT = 16 -- (assume LEFT_HIGHLIGHT > RIGHT_HIGHLIGHT)

constant HIGHLIGHT_COLOR = BRIGHT_WHITE

-------- end of user-modifiable parameters 

constant SCREEN = 1, ERR = 2

constant TRUE = 1, FALSE = 0
constant EOF = -1

type boolean(integer x)
	return x = 0 or x = 1
end type

sequence word_list, word_count, file_spec

boolean euphoria

integer count_line

integer log_file

constant LINE_WIDTH = 83
constant TO_LOWER = 'a' - 'A'

function fast_lower(sequence s)
	-- Faster than the standard lower().
	-- Speed of lower() is important here.
	integer c
	
	for i = 1 to length(s) do
		c = s[i]
		if c <= 'Z' then
			if c >= 'A' then
				s[i] = c + TO_LOWER
			end if
		end if
	end for
	return s
end function

function clean(sequence line)
	-- replace any funny control characters 
	-- and put in \n's to help break up long lines
	sequence new_line
	integer c, col
	
	new_line = ""
	col = 1
	for i = 1 to length(line) do
		if col > LINE_WIDTH then
			new_line = append(new_line, '\n')
			col = 1
		end if
		c = line[i]
		col += 1
		if c < 14 then
			if c = '\n' then
				col = 1
			elsif c = '\r' then
				c = ' '
			elsif c != '\t' then
				c = '.'
			end if
		end if
		new_line = append(new_line, c)
	end for
	return new_line
end function

boolean display
display = TRUE

procedure both_puts(object text)
	puts(log_file, text)
	if display then
		puts(SCREEN, text)
	end if
end procedure

procedure both_printf(sequence format, object values)
	printf(log_file, format, values)
	if display then
		printf(SCREEN, format, values)
	end if
end procedure

constant MAX_LINE = 100

-- space for largest line
sequence buff
buff = repeat(0, MAX_LINE)

function safe_gets(integer fn)
	-- Return the next line of text - always with \n on the end.
	-- Lines are split at MAX_LINE to prevent
	-- "out of memory" problems on humongous lines
	-- and to reduce the amount of extraneous output.
	integer c
	
	for b = 1 to MAX_LINE - 1 do
		c = getc(fn)
		if c <= LEFT_HIGHLIGHT then
			if c = '\n' then
				buff[b] = c
				return buff[1 .. b]
			elsif c = EOF then
				if b = 1 then
					return EOF
				else
					buff[b] = '\n'
					return buff[1 .. b]
				end if
			elsif c >= RIGHT_HIGHLIGHT or c = 0 then
				c = '.'
			end if
		end if
		buff[b] = c
	end for
	buff[MAX_LINE] = '\n'
	return buff[1 .. MAX_LINE]
end function

function sum(sequence s)
	-- sum of a sequence
	atom sum
	
	sum = 0
	for i = 1 to length(s) do
		sum += s[i]
	end for
	return sum
end function

object line
integer line_next
boolean words_on_line

sequence char_class
--    0 means not legitimate
--    1 means legitimate char
--  > 1 means possible first char of matching word
char_class = repeat(0, 255)
char_class['A' .. 'Z'] = 1
char_class['a' .. 'z'] = 1
char_class['0' .. '9'] = 1
char_class['_'] = 1

function has_punctuation(sequence word)
	-- TRUE if word contains any punctuation characters 
	integer c
	for i = 1 to length(word) do
		c = word[i]
		if char_class[c] = 0 and c != '?' and c != '*' then
			return TRUE
		end if
	end for
	return FALSE
end function

function next_word()
	-- Return next possible matching word from line
	-- based on first letter of the word.
	sequence word
	integer c
	
	while TRUE do
		-- skip white space:
		while TRUE do
			c = line[line_next]
			line_next += 1
			if char_class[c] > 0 then
				exit
			elsif c = '\n' then -- there's always a '\n' at end of line 
				return -1
			end if
		end while
		
		words_on_line = TRUE
		
		-- check first letter in word:
		if char_class[c] > 1 then
			-- possible matching word
			word = { c }
			-- read rest of word
			while TRUE do
				c = line[line_next]
				if char_class[c] = 0 then
					return word
				end if
				line_next += 1
				word &= c
			end while
		else
			-- not a possible matching word -skip it
			while TRUE do
				c = line[line_next]
				if char_class[c] = 0 then
					exit
				end if
				line_next += 1
			end while
		end if
	end while
end function

sequence chunk_list
chunk_list = { { -1, {}, {} } }

procedure highlight(sequence text)
	-- print a line with highlighted words in color
	integer c
	
	if not display then
		return
	end if
	for i = 1 to length(text) do
		c = text[i]
		if c = LEFT_HIGHLIGHT then
			text_color(HIGHLIGHT_COLOR)
		elsif c = RIGHT_HIGHLIGHT then
			text_color(WHITE)
		else
			puts(SCREEN, c)
		end if
	end for
end procedure

procedure print_chunk_list()
	-- print the best chunks found
	sequence chunk, line
	
	position(count_line, 1)
	for i = 1 to length(word_list) do
		both_printf("%s:%d ", { word_list[i], word_count[i] })
	end for
	position(count_line + 1, 1)
	puts(SCREEN, repeat(' ', 80))
	puts(log_file, '\n')
	
	for i = 1 to length(chunk_list) - 1 do
		if i > 1 and display then
			text_color(BRIGHT_GREEN)
			puts(SCREEN, "\nPress q to quit, Enter for more:")
			text_color(WHITE)
			puts(SCREEN, " ")
			if getc(0) = 'q' then
				display = FALSE
			end if
		end if
		text_color(RED)
		both_printf("\n#%d of %d ------ %s --- score: %d ------\n",
			 { i, length(chunk_list) - 1,
				chunk_list[i][2], 100 * chunk_list[i][1] + 0.5 })
		text_color(WHITE)
		chunk = chunk_list[i][3]
		g:wrap(FALSE)
		for j = 1 to length(chunk) do
			line = clean(chunk[j])
			highlight(line)
			puts(log_file, line)
		end for
		g:wrap(TRUE)
	end for
	if length(chunk_list) > 1 then
		text_color(GREEN)
		puts(SCREEN, "\nSee " & log_path & '\n')
	end if
	text_color(WHITE)
	puts(SCREEN, " \n")
end procedure

procedure save_chunk(sequence file_name, sequence chunk, atom score)
	-- record an interesting chunk on the chunk list 
	
	score /= 10 + sqrt(length(chunk)) -- reduce slightly for larger chunks
	for i = 1 to length(chunk_list) do
		if score > chunk_list[i][1] then
			-- insert chunk into list at proper position
			chunk_list = append(chunk_list[1 .. i - 1], { score, file_name, chunk })
			 & chunk_list[i .. length(chunk_list)]
			if length(chunk_list) > MAX_CHUNKS + 1 then
				-- drop the worst chunk on the list
				chunk_list = chunk_list[1 .. length(chunk_list) - 1]
			end if
			exit
		end if
	end for
end procedure

sequence wild_word

procedure scan(sequence file_name)
	-- read next file 
	integer fileNum, first_hit, last_hit, new_chunk
	sequence lword, chunk, word_value
	object word
	atom chunk_total, line_total
	boolean doc_file, matched, first_match
	
	-- SKIP .svn dir
	if match(".svn", file_name) then
		return
	end if
	
	fileNum = open(file_name, "rb")
	if fileNum = -1 then
		return
	end if
	
	-- is it a Euphoria .doc file?
	doc_file = euphoria and match(".doc", fast_lower(file_name))
	
	-- update display
	g:wrap(FALSE)
	position(count_line, 1)
	for i = 1 to length(word_list) do
		printf(SCREEN, "%s:%d ", { word_list[i], word_count[i] })
	end for
	position(count_line + 1, 1)
	puts(SCREEN, "searching: " & file_name & repeat(' ', 80) & '\r')
	g:wrap(TRUE)
	
	new_chunk = TRUE
	while TRUE do
		-- initialize
		if new_chunk then
			chunk = {}
			chunk_total = 0
			first_hit = 0
			last_hit = 0
			new_chunk = FALSE
			word_value = repeat(1, length(word_list))
		end if
		line_next = 1
		line_total = 0
		
		-- read next line
		line = safe_gets(fileNum)
		if atom(line) then
			exit -- end of file
		end if
		
		if get_key() = 'q' then
			close(fileNum)
			print_chunk_list()
			abort(1)
		end if
		
		words_on_line = FALSE
		
		while TRUE do
			-- read next word in line
			word = next_word()
			if atom(word) then
				exit
			end if
			lword = fast_lower(word)
			first_match = TRUE
			for i = 1 to length(word_list) do
				if wild_word[i] then
					-- slow
					matched = wildcard:is_match(word_list[i], lword)
				else
					-- fast
					matched = equal(word_list[i], lword)
				end if
				if matched then
					-- score a bit higher for matching a non-wildcard word
					line_total += word_value[i] * (1
					 + 0.5 * (match(separator_line, line) != 0)
					 + 0.3 * ( not wild_word[i])
					 + 0.3 * doc_file)
				word_count[i] += 1
				word_value[i] /= 2
				if first_match then
					first_match = FALSE
					line = line[1 .. line_next - length(word) - 1] &
						LEFT_HIGHLIGHT &
						word &
						RIGHT_HIGHLIGHT &
						line[line_next .. length(line)]
					line_next += 2
				end if
			end if
		end for
	end while
	chunk = append(chunk, line)
	
	-- decide chunk boundaries
	if words_on_line then
		if line_total > 0 then
			chunk_total += line_total
			last_hit = length(chunk)
			if first_hit = 0 then
				first_hit = last_hit
			end if
		end if
		if chunk_total > 0 then
			if (line_total = 0 and
				last_hit < length(chunk) - MIN_CHUNK_SIZE / 2 and
				length(chunk) >= MIN_CHUNK_SIZE) or
			length(chunk) >= MAX_CHUNK_SIZE then
			
			if length(chunk) <= MIN_CHUNK_SIZE then
				first_hit = 1
				last_hit = length(chunk)
			else
				-- trim off some context, but not all
				first_hit = floor((first_hit + 1) / 2)
				last_hit = floor((last_hit + length(chunk)) / 2)
			end if
			
			save_chunk(file_name,
				chunk[first_hit .. last_hit],
				chunk_total)
			new_chunk = TRUE
		end if
	elsif length(chunk) >= MIN_CHUNK_SIZE then
		new_chunk = TRUE
	end if
elsif chunk_total = 0 and length(chunk) > MIN_CHUNK_SIZE / 2 then
	new_chunk = TRUE
end if
end while
if chunk_total > 0 then
	save_chunk(file_name, chunk, chunk_total)
end if
close(fileNum)
return
end procedure

function look_at(sequence path_name, sequence direntry)
	-- see if a file name qualifies for searching
	sequence file_name
	
	if find('d', direntry[D_ATTRIBUTES]) then
		return 0 -- a directory
	end if
	file_name = direntry[D_NAME]
	if equal(file_name, log_name) then
		return 0 -- avoid circularity
	end if
	-- check skip list
	for i = 1 to length(skip_list) do
		if wildcard_file(skip_list[i], file_name) then
			return 0
		end if
	end for
	path_name &= SLASH
	if equal(path_name[1 .. 2], '.' & SLASH) then
		path_name = path_name[3 .. length(path_name)]
	end if
	path_name &= file_name
	scan(path_name)
	return 0
end function

procedure usage(sequence g)
	text_color(MAGENTA)
	puts(SCREEN, "\n\t\t" & g & " Guru\n\n")
	text_color(WHITE)
	puts(SCREEN,
		"Enter keywords that will define the subject you are interested in. \n")
	puts(SCREEN,
		" - Upper/lower case is not important.\n")
	puts(SCREEN,
		" - Words may contain * and ? wildcard characters,\n")
	puts(SCREEN,
		" - example ---> get? input *routine*\n\n")
	puts(SCREEN, "---> ")
end procedure

function blank_delim(sequence s)
	-- break up a blank-delimited string
	sequence list, segment
	integer i
	list = {}
	i = 1
	while i < length(s) do
		while find(s[i], " \t") do
			i += 1
		end while
		if s[i] = '\n' then
			exit
		end if
		segment = ""
		while not find(s[i], " \t\n") do
			segment = segment & s[i]
			i += 1
		end while
		list = append(list, segment)
	end while
	return list
end function

ifdef not UNIX then
	log_name = upper(log_name)
end ifdef

clear_screen()

sequence cmd
cmd = command_line() -- eui guru.ex words...

euphoria = FALSE
if length(cmd) < 3 then
	usage("Current Directory")
	cmd = blank_delim(gets(0))
	puts(SCREEN, '\n')
elsif equal(cmd[3], "E!") then
	-- search Euphoria directories
	euphoria = TRUE
	if length(cmd) <= 3 then
		usage("Euphoria")
		cmd = blank_delim(gets(0))
		puts(SCREEN, '\n')
	else
		cmd = cmd[4 .. length(cmd)]
	end if
else
	cmd = cmd[3 .. length(cmd)]
end if

log_file = open(log_path, "w")
if log_file = -1 then
	puts(ERR, "Couldn't open " & log_path & '\n')
	abort(1)
end if

word_list = {}
wild_word = {}
for i = 1 to length(cmd) do
	cmd[i] = lower(cmd[i])
	if find(cmd[i], noise_words) then
		puts(SCREEN, "ignoring: " & cmd[i] & "   (too common)\n")
	elsif has_punctuation(cmd[i]) then
		puts(SCREEN, "ignoring: " & cmd[i] &
			"   (contains punctuation character)\n")
	else
		word_list = append(word_list, cmd[i])
		wild_word = append(wild_word, find('*', cmd[i]) or find('?', cmd[i]))
	end if
end for

if length(word_list) = 0 then
	abort(1)
end if
word_count = repeat(0, length(word_list))

integer first_char
-- prepare char_class[] for efficient detection of a 
-- possible first letter in one of the words
for i = 1 to length(word_list) do
	first_char = word_list[i][1]
	if first_char = '*' or first_char = '?' then
		char_class *= 2 -- select all allowed chars
		exit
	elsif char_class[first_char] > 0 then
		char_class[first_char] = 2
		-- select upper or lower case
		if first_char >= 'A' and first_char <= 'Z' then
			char_class[first_char - 'A' + 'a'] = 2
		elsif first_char >= 'a' and first_char <= 'z' then
			char_class[first_char - 'a' + 'A'] = 2
		end if
	end if
end for

file_spec = { "*.*" }

-- quits after finishing current file
puts(SCREEN, "Press q to quit\n\n\n")

sequence gp
gp = get_position()
count_line = gp[1] - 1

object d

if euphoria then
	d = getenv("EUDIR")
	if atom(d) then
		ifdef UNIX then
			puts(ERR, "EUDIR not set\n")
			abort(1)
		elsedef
			d = "C:\\EUPHORIA"
		end ifdef
	end if
	if sequence(dir(d)) then
		-- reduce noise in Euphoria Help
		skip_list &= { "*.HTM", "*.HTX", "*.DAT", "*.BAS", "*.BAT", "*.PRO",
			"LW.DOC", "BIND.EX", "EX.ERR" }
		ifdef UNIX then
			skip_list = lower(skip_list)
		end ifdef
		
		if walk_dir(d, routine_id("look_at"), TRUE) then
		end if
		print_chunk_list()
		abort(0)
	end if
end if

puts(log_file, "Searching " & current_dir() & "\n\n")
sequence top_dir
if sequence(dir(".")) then
	top_dir = "."
else
	top_dir = current_dir()
end if

if walk_dir(top_dir, routine_id("look_at"), TRUE) then
end if

print_chunk_list()

