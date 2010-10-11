-- index script
with trace
include std/regex.e as re
include std/text.e as text
include std/map.e  as map
include std/sequence.e as seq
include std/console.e as con
include std/io.e as io
include std/search.e as search

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
	NAMED_ID = 7

constant pattern_fragments = {
	0,
	`([a-z_0-9]+\.html)`, -- FILE_NAME
	`(_\d+_[A-Za-z_0-9]+)`, -- BOOK_MARK
	`((\d+)(\.\d+)+)`, -- NUMERIC_ID
	0,
	0,
	`([a-zA-Z][^<]+)`, -- NAMED_ID
	$
}


-- Example:
-- <a href="eu400_0102.html#_5747_map_type">MAP_TYPE (Memory Management - Low-Level)</a>
--sequence id_pattern = re:new( `<a href="([a-z_0-9]+\.html)#(_\d+_[A-Za-z_0-9]+)">([a-xA-Z0-9_]+) \(([a-z_0-9A-Z -]+)\)`, EXTRA )

constant id_pattern = re:new( 
	sprintf(`<a href="%s#%s">%s %s</a><br />`, 
		{ pattern_fragments[FILE_NAME], 
		  pattern_fragments[BOOK_MARK],
		  pattern_fragments[NUMERIC_ID],
		  pattern_fragments[NAMED_ID] 
		} 
	)
)

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

sequence cl = command_line()
htmlfd = open_or_die(cl[$-1],"r")
jsfd   = open_or_die(cl[$],"w")
templfd = open_or_die(`../docs/search-template.js`,"r")
line = gets(htmlfd)
count = 0
dictionary = map:new(3000)
printf(jsfd,"index=new Array();\nchapter=new Array();",{})
while sequence(line) do
    integer dloc
    match_data = re:matches( id_pattern, line )
    if sequence(match_data) then
		printf(jsfd,"// %s",{line})
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
			count += 1
		end if
    end if
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
	puts( 1, "Someone has broken the javascript search engine.\n" )
	puts( 1, "Please thank him with a boot to the head.\n" )
end if
abort(not count)


