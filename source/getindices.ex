-- index script
with trace
include std/regex.e as re
include std/text.e as text
include std/map.e  as map
include std/sequence.e as seq
include std/console.e as con
include std/io.e as io

function extract_slices( sequence s, sequence indicies )
	sequence out
	out = {}
	for i = 1 to length(indicies) do
		out = append(out, slice( s, indicies[i][1], indicies[i][2] ) )
	end for
	return out
end function

sequence id_pattern = re:new( `^<a href="([a-z_0-9]+\.html)#(_\d+_[A-Za-z_0-9]+)">(\d+\.\d+)((\.\d+)*) ([^<]+)<`, EXTRA )
constant CLEAN_ID = 7
constant SUBSECTION = 6
constant CHAPTER = 4
constant BOOKMARK = 3
constant FILE = 2


sequence id, url, section, chapter
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
    match_data = re:matches( id_pattern, line )
    if sequence(match_data) then
	printf(jsfd,"// %s",{line})
	id = match_data[CLEAN_ID]	
	url = match_data[FILE] & '#' &
		match_data[BOOKMARK]
	section = match_data[SUBSECTION]
	chapter = match_data[CHAPTER]
	if equal(section,{}) then
	     printf(jsfd,`chapter['%s']='%s';`,
	     {chapter,id})
	end if
	if not eu:find(' ',id) then
	    if not map:has(dictionary,id) then
		printf(jsfd,`index['%s'] = new Array();%s`, {id,"\n"} )
		map:put(dictionary,id,0)
	    else
		map:put(dictionary,id,1,ADD)
	    end if
	    printf(jsfd,
	    `t = new Array();
	     t.url = '%s';
	     t.chapter = '%s';
	     index['%s'][%d] = t;
	     `, 
		    {url, chapter, id, map:get(dictionary,id), url } 
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

