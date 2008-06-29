-- search the PATH for all occurrences of a file
-- usage:  where filename
-- (give complete file name including .exe .bat etc.)

include filesys.e
include os.e
include os.e

constant TRUE = 1
constant SCREEN = 1, ERROR = 2

sequence path
integer p

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

ifdef DOS32 then
   	constant exe_name ="ex"
elsifdef WIN32 then
   	constant exe_name ="exwc"
else
	constant exe_name ="exu"
end ifdef

procedure search_path()
-- main routine
    sequence file, cmd, full_path
    object dir_name, dir_info
    
    cmd = command_line()
    if length(cmd) < 3 then
		puts(ERROR, "usage: " & exe_name &"where file\n")
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
		-- must be a file
		printf(SCREEN, "%4d-%02d-%02d %2d:%02d",
			  dir_info[1][D_YEAR..D_MINUTE])
		printf(SCREEN, "  %d  %s\n", 
		   {dir_info[1][D_SIZE], dir_name & SLASH & dir_info[1][D_NAME]})
	    end if
	end if
    end while
end procedure

search_path()

