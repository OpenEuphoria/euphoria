-- index script

-- Each public symbol in the index file is listed in the following format: 
-- <a href="eu400_0079.html#_3370_newline_cr">10.2.3.17 NEWLINE_CR</a><br />
-- 
-- Here we can easily extract the filename, the bookmark, an numerical index
-- showing where the identifier is in its tree structure and the identifier
-- itself. In this case of this input line, NEWLINE_CR becomes an index in a
-- Javascript array which points to an array of structures. Each structure
-- consists of the bookmark, "_3370_newline_cr", the file, "eu400_0079.html",
-- and in what this entry is from, 10.2.3. We truncate off the last number in
-- the number - dot pattern for this.
-- 
-- Now the chapter[] array simply points numbers to their identifiers
-- chapter['10.2'] might equal 'Regular Expressions'.
-- 
-- The Javascript accesses this array and if the array points to an array of
-- size one it jumps immediately to the url in the structure, if there is more
-- than one and there is for 'new' and 'find' then it will present you with a
-- list. The chapter array is used to give to the places where the id name is
-- declared. chapter[ '10.2.7' ] may be 'Matching' and chapter[ '10.2'] may be
-- 'Regular expressions.' For each structure, the numbers are sequentially
-- peeled off to give you a list of where the id comes from, from the most
-- general to the most specific.  For example:
--
-- Searching(9.3)/Finding(9.3.2) : find.
-- 
-- For typing find in the search engine in my older copy I get this: 
-- find:
-- Regular Expressions(10.2)/ Match(10.2.7) : find 
-- Searching(9.3)/ Finding(9.3.2) : find
-- 
-- Then the user can click on which find() he or she wants to see.
--
-- This version of getindices requires:
-- EUPHORIA INTERPRETER:     3491
-- EUDOC: with version:      3319+
-- CREOLEHTML: with version: 3345

include std/regex.e as re
include std/text.e as text
include std/map.e  as map
include std/sequence.e as seq
include std/console.e as con
include std/io.e as io
include std/search.e as search
include std/filesys.e
include std/sort.e

function extract_slices( sequence s, sequence indicies )
	sequence out
	out = {}
	for i = 1 to length(indicies) do
		out = append(out, slice( s, indicies[i][1], indicies[i][2] ) )
	end for
	return out
end function

enum
	ENTIRE_MATCH = 1,
	FILE_NAME,
	BOOK_MARK,
	NUMERIC_ID,
	NAMED_ID

constant pattern_fragments = {
	0,
	`(?P<file_name>[a-z_0-9]+\.html)`, -- FILE_NAME
	`(?<book_mark>_\d+_[A-Za-z_0-9]+)`, -- BOOK_MARK
	`(?<numeric_id>(\d+)(\.\d+)+)`, -- NUMERIC_ID
	`(?<named_id>[a-zA-Z][^<]+)`, -- NAMED_ID
	$
}

/*constant id_pattern = re:new( 
	sprintf(`<a href="%s#%s">%s %s</a><br />`, 
		{ pattern_fragments[FILE_NAME], 
		  pattern_fragments[BOOK_MARK],
		  pattern_fragments[NUMERIC_ID],
		  pattern_fragments[NAMED_ID] 
		}
	), {re:ANCHORED, re:EXTRA, re:NO_AUTO_CAPTURE}
)*/

constant id_pattern = re:new( sprintf(`<a href="%s#%s">%s %s</a>`,  
		{ pattern_fragments[FILE_NAME], pattern_fragments[BOOK_MARK],
		  pattern_fragments[NUMERIC_ID],
		  pattern_fragments[NAMED_ID] } ), {re:ANCHORED, re:EXTRA, re:NO_AUTO_CAPTURE} )

sequence id, url, /*section,*/ chapter
map:map dictionary
object match_data
object line
integer htmlfd, count, jsfd, templfd

function open_or_die(sequence name, sequence mode )
    integer fd
    fd = open(name,mode)
    if fd = -1 then
    	switch mode do
	    case "w" then
	    	printf(STDERR,"Cannot open \'%s\' for writing.",{name})
	    case "r" then
		printf(STDERR,"Cannot open \'%s\' for reading.",{name})
	    case else
		printf(STDERR,"Cannot open \'%s\'.",{name})
	end switch
	abort(1)
   end if
   return fd
end function


function find_index( sequence path )
	object file_data
	if path[$] = SLASH then
		path = path[1..$-1]
	end if
	sequence files = sort( dir( path ) )
	for i = length( files ) to 1 by -1 do
		file_data = read_file( path & SLASH & files[i][D_NAME], TEXT_MODE )
		if atom(file_data) then
			continue
		end if
		if match( "Subject and Routine Index", file_data ) then
			return open_or_die( path & files[i][D_NAME], "r" )
		end if
	end for
	
	-- assume a version of creolehtml with no such magic phrase as 'Subject and Routine Index'
	return open_or_die( path & SLASH & "index.html", "r" )
end function

sequence cl = command_line()

htmlfd = find_index( cl[$-1] )
jsfd   = open_or_die(cl[$],"w")
templfd = open_or_die(`../docs/search-template.js`,"r")
line = gets(htmlfd)
count = 0
dictionary = map:new(3000)
printf(jsfd,"index=new Array();\nchapter=new Array();",{})
while sequence(line) do
    integer dloc
    match_data = re:matches( id_pattern, line )
    if sequence(match_data)  then
		printf(jsfd,"// %s",{line})
		count += 1
		id = match_data[NAMED_ID]
		url = match_data[FILE_NAME] & '#' &
			match_data[BOOK_MARK]
		chapter = match_data[NUMERIC_ID]
		printf(jsfd,"chapter[\'%s\']=\"%s\";\n",{text:escape(chapter),text:escape(id)})
		dloc = search:rfind('.',chapter)
		if dloc = 0 then
			dloc = length(chapter) + 1
		end if
		if not eu:find(' ',id) then
			if not map:has(dictionary,id) then
				printf(jsfd,`index['%s'] = new Array();%s`, {id,"\n"} )
				map:put(dictionary,id,0)
			else
				map:put(dictionary,id,1,ADD)
			end if
			printf(jsfd,`
________________________t = new Array();
			t.url = '%s';
			t.chapter = '%s';
			index["%s"][%d] = t;
			
			`, 
				{url, remove(chapter,dloc,length(chapter)), 
					text:escape(id), map:get(dictionary,id), url } 
			)
		end if
    end if
    label "get_line"
    line = gets(htmlfd)
end while
close(htmlfd)

line = gets(templfd)
while sequence(line) do
	puts(jsfd,line)
	line = gets(templfd)
end while
close(templfd)
close(jsfd)

printf(1, "Matched %d lines\n", { count } )
if count = 0 then
	puts( 1, "No lines were matched.  This probably means you are using a bad version of some depenency.")
	puts( 1, `
__________________You must use:
		  1. EUPHORIA interpreter (like 3491)
		  2. EUDOC 3319-3500 or *possibly* later
		  3. CREOLEHTML 3345 but *not* later
		  `)		  
	puts( 1, ".\n" )
end if
abort(count!=2004)


