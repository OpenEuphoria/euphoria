-- index script
with trace
include std/regex.e as re
include std/text.e as text
include std/map.e  as map
include std/sequence.e as seq
include std/console.e as con
include std/io.e as io
include std/error.e as error

function extract_slices( sequence s, sequence indicies )
	sequence out
	out = {}
	for i = 1 to length(indicies) do
		out = append(out, slice( s, indicies[i][1], indicies[i][2] ) )
	end for
	return out
end function

-- Example:
--<a href="eu400_0101.html#_5768_map_type">13.6.7.38 MAP_TYPE</a><br />
--<a href="(?<file>eu400_0101.html)#(?P<bookmark>_5768_map_type)">(?P<chatper>13.6.7.38) (?P<clean_id>MAP_TYPE)</a><br />
	
constant id_pattern = re:new( `<a href="(?P<file>eu400_\d+.html)#`&
	`(?P<bookmark>_\d+_[a-zA-Z_:]+)">`&
	`(?P<chapter>[0-9.]+) `&
	`(?P<clean_id>[a-z0-9A-Z_ -]+)</a>`, {ANCHORED,EXTRA} )

enum 
	ENTIRE_MATCH = 1,
	FILE,
	BOOKMARK,
	CHAPTER,
	CLEAN_ID 

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
ifdef DEBUG then
    jsfd = 1
elsedef
    jsfd   = open_or_die(cl[$],"w")
    printf(jsfd,"index=new Array();\nchapter=new Array();",{})
end ifdef
templfd = open_or_die(`../docs/search-template.js`,"r")
line = gets(htmlfd)
count = 0
dictionary = map:new(3000)
while sequence(line) do
    match_data = re:matches( id_pattern, line )
    if sequence(match_data) then
		printf(jsfd,"// %s",{line})
		ifdef DEBUG then
		    count += 1
		elsedef
		    id = match_data[CLEAN_ID]	
		    url = match_data[FILE] & '#' &
			    match_data[BOOKMARK]
		    chapter = match_data[CHAPTER]
		    printf(jsfd,`chapter['%s']='%s';`,
		    {chapter,id})
		    if not eu:find(' ',id) then
			    if not map:has(dictionary,id) then
				    printf(jsfd,`index['%s'] = new Array();%s`, {id,"\n"} )
				    map:put(dictionary,id,0)
			    else
				    map:put(dictionary,id,1,ADD)
			    end if
			    printf(jsfd,`
_____________________________t = new Array();
			     t.url = '%s';
			     t.chapter = '%s';
			     index['%s'][%d] = t;`
			     , 
				    {url, chapter, id, map:get(dictionary,id), url } 
			    )
			    count += 1
		    end if
		end ifdef
    end if
    line = gets(htmlfd)
end while
close(htmlfd)

ifdef not DEBUG then
    -- copy script code to the end of the generated script.
    line = gets(templfd)
    while sequence(line) do
	    puts(jsfd,line)
	    line = gets(templfd)
    end while
    close(templfd)
    close(jsfd)
end ifdef
printf(1, "Matched %d lines\n", { count } )
if count = 0 then
	crash( "index.html format has changed." )
end if
