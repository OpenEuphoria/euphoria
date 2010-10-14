-- index script

include std/regex.e as re
include std/text.e as text
include std/map.e  as map
include std/sequence.e as seq
include std/console.e as con
include std/io.e as io
include std/filesys.e
include std/sort.e
include std/search.e

function extract_slices( sequence s, sequence indicies )
	sequence out
	out = {}
	for i = 1 to length(indicies) do
		out = append(out, slice( s, indicies[i][1], indicies[i][2] ) )
	end for
	return out
end function

-- Example:
-- <a href="eu400_0102.html#_5747_map_type">MAP_TYPE (Memory Management - Low-Level)</a>
sequence id_pattern = re:new( `<a href="(.+\.html)#(.+)">([A-Za-z0-9_]+) \(([^']+)\)</a>`, EXTRA )

enum
	ENTIRE_MATCH = 1,
	FILE,
	BOOKMARK,
	CLEAN_ID,
	CHAPTER

sequence id, url, /*section,*/ chapter
map:map dictionary
object match_data
object line
integer count, jsfd, templfd

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
	sequence files = sort( dir( path ) )
	sequence fname
	integer fn
	object fdata

	for i = 1 to length( files ) do
		-- Only look at files
		if not find('d', files[i][D_ATTRIBUTES]) then
			-- only look at HTML files
			if begins("HTM", upper(fileext(files[i][D_NAME]))) then
				fname = path & SLASH & files[i][D_NAME]
				fdata = read_file( fname, TEXT_MODE )
				if sequence(fdata) then
					if match( "Subject and Routine Index", fdata ) then
						return seq:split(fdata, '\n')
					end if
				end if
			end if
		end if
	end for
	printf(STDERR, "Could not locate the index in %s\n", { path })
	abort(1)
end function

sequence cl = command_line()

sequence htmltext = find_index( cl[$-1] )
jsfd   = open_or_die(cl[$],"w")
templfd = open_or_die(`../docs/search-template.js`,"r")

integer linep = 0
count = 0
dictionary = map:new(3000)
printf(jsfd,"index=new Array();\nchapter=new Array();\n",{})
while linep < length(htmltext) do
	linep += 1
	line = htmltext[linep]
    match_data = re:matches( id_pattern, line )
    if sequence(match_data) then
		printf(jsfd,"// %s\n",{line})
		id = match_data[CLEAN_ID]	
		url = match_data[FILE] & '#' &
			match_data[BOOKMARK]
		chapter = match_data[CHAPTER]
		printf(jsfd,"chapter['%s']='%s';\n",
		{chapter,id})
		if not eu:find(' ',id) then
			if not map:has(dictionary,id) then
				printf(jsfd,"index['%s'] = new Array();\n", {id} )
				map:put(dictionary,id,0)
			else
				map:put(dictionary,id,1,ADD)
			end if
			printf(jsfd,`
____________t = new Array();
			t.url = '%s';
			t.chapter = '%s';
			index['%s'][%d] = t;
			`, 
				{url, chapter, id, map:get(dictionary,id), url } 
			)
			count += 1
		end if
    end if

end while


line = gets(templfd)
while sequence(line) do
	puts(jsfd,line)
	line = gets(templfd)
end while
close(templfd)
close(jsfd)

printf(1, "Matched %d lines\n", { count } )

