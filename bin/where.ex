-- search the PATH for all occurrences of a file
-- usage:  where filename
-- (give complete file name including .exe .bat etc.)

include std/filesys.e
include std/os.e
include std/map.e
include std/text.e

constant TRUE = 1
constant SCREEN = 1, ERROR = 2

sequence path
integer p
map found_files = map:new()

function next_dir()
-- get the next directory name from the path sequence   
    sequence dir
    
    if p > length(path) then
	return -1
    end if
    dir = ""
    while p <= length(path) do
	if path[p] = PATHSEP then
	    p += 1
	    exit
	end if
	dir &= path[p]
	p += 1
    end while
    if length(dir) = 0 then
	return -1
    end if
    return dir
end function


procedure search_path()
-- main routine
    sequence file, cmd, full_path
    object dir_name, dir_info
    sequence exe_name
    
    exe_name = command_line()
    if not equal(exe_name[1], exe_name[2]) then
    	exe_name = "eui " & exe_name[2]
    end if
    
    cmd = command_line()
    if length(cmd) < 3 then
		puts(ERROR, "usage: " & exe_name &" <filename>\n")
		abort(1)
    end if
    
    path = getenv("PATH")
    if atom(path) then
	puts(ERROR, "NO PATH?\n")
	abort(1)
    end if

    if platform() != LINUX then
	path = ".;" & path -- check current directory first
    end if
    
    file = cmd[3]
    p = 1
    while TRUE do
		dir_name = next_dir()
		if atom(dir_name) then
		    exit
		end if
		
		full_path = dir_name & SLASH & file
		dir_info = dir(full_path) 
		if sequence(dir_info) then
			
		    -- file or directory exists
		    if length(dir_info) = 1 then
				sequence new_name = canonical_path(dir_name & SLASH & dir_info[1][D_NAME])
				ifdef DOSFAMILY then
					new_name = lower(new_name)
				end ifdef
				if not map:has(found_files, new_name) then
					-- must be a file
					printf(SCREEN, "%4d-%02d-%02d %2d:%02d",
						  dir_info[1][D_YEAR..D_MINUTE])
					printf(SCREEN, "  %d  %s\n", 
					   {dir_info[1][D_SIZE], new_name})
					map:put(found_files, new_name, 1)
				end if
		    end if
		end if
    end while
end procedure

search_path()

