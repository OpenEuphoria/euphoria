-- (c) Copyright 2006 Rapid Deployment Software - See License.txt
--
-- open a file by searching the user's PATH

global function e_path_open(sequence name, sequence mode)
-- follow the search path, if necessary to open the main file
    integer src_file
    object path
    sequence full_name
    integer p
       
    -- try opening directly
    src_file = open(name, mode)
    if src_file != -1 then
	return src_file        
    end if
    
    -- make sure that name is a simple name without '\' in it
    for i = 1 to length(SLASH_CHARS) do
	if find(SLASH_CHARS[i], name) then
	    return -1
	end if
    end for
    
    path = getenv("PATH")
    if atom(path) then
	return -1
    end if
    
    full_name = ""
    p = 1
    path &= PATH_SEPARATOR -- add end marker
    
    while p <= length(path) do
	if (length(full_name) = 0 and path[p] = ' ') or path[p] = '\t' then
	    -- skip

	elsif path[p] = PATH_SEPARATOR then
	    -- end of a directory
	    if length(full_name) then
		while length(full_name) and full_name[$] = ' ' do
		    full_name = full_name[1..$-1]
		end while
		src_file = open(full_name & SLASH & name, mode)
		if src_file != -1 then
		    file_name[1] = full_name & SLASH & name          
		    return src_file
		else 
		    full_name = ""
		end if
	    end if

	else 
	    full_name &= path[p] -- build up the directory name

	end if
	
	p += 1
    end while
    return -1
end function


