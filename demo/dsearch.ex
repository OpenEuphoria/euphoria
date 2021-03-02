--****
-- === dsearch.ex
-- 
-- search for a .DLL that contains a given routine
-- ==== Usage
-- {{{
-- eui dsearch [options] [routine] 
-- }}}
--
-- //Options// are any combination of ##-h##, ##-a##. ##-q##. ##-l //library//## 
-- ##--help##, ##--lib  //library//##, ##--all##, and ##--quiet##.
--
-- |Long Option|Short Option|Meaning|
-- |--all      |-a| don't stop at the first occurence of //routine//, find all occurences of //routine//.  This implies the '--quiet' option.|
-- |--recurse  |-r| recurse into library directories|
-- |--help     |-h| show the user help|
-- |--lib //library//     |-l //library//| search only //library// for the routine|
-- |--quiet    |-q| don't print the library filenames that are searched|
--
-- If you don't supply a string on the command line, you will be prompted 
-- for it. 
--

-- Some of the common WIN32 .DLLs. Feel free to add more.
include std/types.e
include std/filesys.e
include std/dll.e
include std/machine.e
include std/pipeio.e as pipeio
include std/error.e
include std/sequence.e as stdseq
include std/io.e
include std/console.e
include std/search.e
include std/text.e

constant TRUE = 1, FALSE = 0

type boolean(integer x)
    return x = FALSE or x = TRUE
end type

type c_routine(integer x)
    return x >= -1 and x <= 1000
end type

-- These types use user defined types inside of them
-- although you shouldn't use these next two as functions to test data with,
-- it can be useful to crash inside a type routine for diagnosing problems.
type string(sequence s)
    for i = 1 to length(s) do
	integer si = s[i]	
        if s[i] < 0 or s[i] > power(2,18) then
            return FALSE
        end if
    end for
    return TRUE
end type

type sequence_of_strings(object x)
    for i = 1 to length(x) do
	string s = x[i]
    end for
    return TRUE
end type


sequence_of_strings cmd
string orig_string

integer scanned, no_open
scanned = 0
no_open = 0

boolean only_first = TRUE, found_at_least_one = FALSE, quiet = FALSE, recursive = FALSE

ifdef WINDOWS then
    c_routine FreeLibrary, GetProcAddress, OpenLibrary
end ifdef

ifdef LINUX then
    enum 
      LH_PIPES,
      LH_DATA
end ifdef

atom string_pointer
string routine_name
sequence_of_strings dll_list
dll_list = {}



sequence_of_strings directory_list = {  `c:\windows`, `c:\windows\system32` }
function process_so_conf(atom fd)
    sequence_of_strings ret = {}
        object line
        while sequence(line) with entry do
	    if search:begins("include ", line) then
		string conf_file_spec = text:trim(line[length("include")+2..$-1])
		string path = filesys:pathname(conf_file_spec)
	        object conf_directories = dir(conf_file_spec)
	        if sequence(conf_directories) then
		    for i = 1 to length(conf_directories) do
			atom tfd = open(path & SLASH & conf_directories[i][D_NAME], "r")
			if tfd = -1 then
			    continue
			end if
			ret &= process_so_conf(tfd)
			close(tfd)
		    end for
	        end if
	    elsif not search:begins("#", line) and not equal(line,"\n") then -- ignore #
	        ret = append(ret, trim(line))
	    end if
	entry
	    line = gets(fd)
        end while
    return ret
end function

procedure CSetup()
-- set up C routines that we need:
    ifdef WINDOWS then
        atom kernel32
    
        kernel32 = open_dll("kernel32.dll")
        if kernel32 = 0 then
            puts(io:STDERR, "Can't open kernel32.dll!\n")
            abort(1)
        end if
        FreeLibrary = define_c_func(kernel32, "FreeLibrary", {C_POINTER}, C_INT)
        if FreeLibrary = -1 then
            puts(io:STDERR, "Can't find FreeLibrary\n")
            console:any_key("Press any key to exit..", io:STDOUT)
            abort(1)
        end if
        GetProcAddress = define_c_func(kernel32, "GetProcAddress", 
                         {C_POINTER, C_POINTER}, C_INT)
        if GetProcAddress = -1 then
            puts(io:STDERR, "Can't find GetProcAddress\n")
            console:any_key("Press any key to exit..", io:STDOUT)
            abort(1)
        end if
    elsifdef LINUX then
        -- Linux version is not done with loading dlls because often when loading many
        -- dlls on Linux a segmentation fault occurs.  Perhaps some libraries conflict 
        -- with each other.  There is no way to use the dlsym, dlopen and dlclose
        -- interface such that the dll's init routine isn't called.  Since we are not
        -- even calling anything from the dlls it is enough to interogate nm for what
        -- routines are dynamically exported.
        -- See: Ticket #869
        
        -- Find where the libraries are to be loaded from
        atom LD_SO_CONF = open("/etc/ld.so.conf","r")
        if LD_SO_CONF = -1 then
            puts(io:STDERR, "Cannot open /etc/ld.so.conf\n")
            abort(1)
        end if
        directory_list &= process_so_conf(LD_SO_CONF)
	close(LD_SO_CONF)
        object LD_LIBRARY_PATH = getenv("LD_LIBRARY_PATH")
        if sequence(LD_LIBRARY_PATH) then
            directory_list = split(LD_LIBRARY_PATH, ":") & directory_list
        end if
        -- remove duplicate entries
        integer i = 1
        while i <= length(directory_list) do
            integer j = i+1
            while j <= length(directory_list) do
                if equal(directory_list[i], directory_list[j]) or equal(directory_list[j], "") then
                    directory_list = remove(directory_list, j)
                    continue
                end if
                j += 1
            end while
            i += 1
        end while
	
        if not file_exists("/usr/bin/nm") then
            puts(io:STDERR, "This program requires nm (from the binutils package).\n")
            console:any_key("Press any key to exit..", io:STDOUT)
            abort(1)
        end if
    end ifdef
end procedure

type dl(object x)
   ifdef WINDOWS then
       return atom(x)
   elsifdef LINUX then
       return sequence(x) and length(x) = 2
   elsedef
       crash("This routine is not yet implemented for your platform")
   end ifdef
end type

function dl_open(sequence name)
    ifdef WINDOWS then
        return open_dll(name)
    elsifdef LINUX then
        atom name_string_pointer = allocate_string(name, TRUE)
        object pipe = pipeio:exec(  "nm -D " & name,   pipeio:create()  )
        if atom(pipe) then
            return 0
        end if
        sequence lib = {}
        sequence buf
        while 1 do
           buf = pipeio:read(pipe[pipeio:STDOUT], 256)
           if equal(buf, {}) then
               exit
           end if
           lib = lib & buf
        end while
        return {pipe, stdseq:split(lib, '\n')}
    elsedef
        crash("Not yet implemented for your platform.\n")
    end ifdef
    return 0
end function

function dl_sym(dl dl_handle, sequence routine_name)
    ifdef WINDOWS then
        boolean ret = FALSE
        string_pointer = allocate(length(routine_name)+4)
        poke(string_pointer, routine_name & 0)
        if c_func(GetProcAddress, {dl_handle, string_pointer}) then
            ret = TRUE
        end if
        poke(string_pointer + length(routine_name), "A" & 0)
        if c_func(GetProcAddress, {dl_handle, string_pointer}) then
            ret = TRUE
        end if
        poke(string_pointer + length(routine_name), "Ex" & 0)
        if c_func(GetProcAddress, {dl_handle, string_pointer}) then
            ret = TRUE
        end if
        poke(string_pointer + length(routine_name), "ExA" & 0)
        if c_func(GetProcAddress, {dl_handle, string_pointer}) then
            ret = TRUE
        end if        
        free(string_pointer)
        return ret
    elsifdef LINUX then
        for i = 1 to length(dl_handle[LH_DATA]) do
            sequence line = dl_handle[LH_DATA][i]
            if equal(line,{}) then
                continue
            end if
            if t_digit(line[1]) then
                integer space_location = find(' ', line)
                space_location = find(' ', line, space_location + 1)
                if equal(routine_name, line[space_location+1..$]) then
                    return TRUE
                end if
            end if
        end for        
    elsedef
        crash("Not yet implemented for your platform.\n")    
    end ifdef
    return FALSE
end function

procedure dl_close(dl dl_handle)
    ifdef WINDOWS then
        atom code = c_func(FreeLibrary, {dl_handle})
    elsifdef LINUX then
        pipeio:kill(dl_handle[LH_PIPES])
    elsedef
        crash("Not yet implemented for your platform.\n")    
    end ifdef
end procedure

function scan(sequence file_name)
-- process an eligible file
    boolean found_in_file
    dl lib
    integer code
 
    lib = dl_open(file_name)
    if equal(lib, 0) then
	no_open += 1
	puts(io:STDERR, file_name & ": Couldn't open.\n")
	return 0
    end if
    if not quiet then
        printf(io:STDOUT, "%s: ", {file_name})
    end if
    scanned += 1
    found_in_file = FALSE
    if dl_sym(lib, routine_name) then
	printf(io:STDOUT, "\n\n%s was FOUND in %s\n", {routine_name, file_name})
	found_in_file = TRUE
    end if
    dl_close(lib)
    return found_in_file
end function

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


procedure locate(sequence name)
    routine_name = name
    puts(io:STDOUT, "Looking for " & routine_name & "\n ")
    for i = 1 to length(dll_list) do
	if scan(dll_list[i]) and only_first then
            console:any_key("Press any key to exit..", io:STDOUT)
	    abort(1)
	end if
    end for
    puts(1, '\n')
end procedure

CSetup()

cmd = command_line()   -- eui dsearch [string]
function add_to_dlls(sequence path)
    sequence_of_strings ret = {}
    object list = dir(path)
    if atom(list) then
        return {}
    end if
    for k = 1 to length(list) do
        sequence file_entry = list[k]
        string name = file_entry[D_NAME]
        string attr = file_entry[D_ATTRIBUTES]
	if not find('d', attr) then
	    if search:ends("dll", name) or match(".so.", name) or search:ends(".so", name) then
		ret = append( ret, path & SLASH & file_entry[D_NAME] )
	    end if
	elsif recursive and name[1] != '.' then -- no hidden and no . or .. directories
	    ret &= add_to_dlls(path & SLASH & name)
	end if
    end for
    return ret
end function

boolean libraries_specified_at_command_line = FALSE
orig_string = ""
integer cmd_i = 3
while cmd_i <= length(cmd) do
    string arg = cmd[cmd_i]
    if search:begins(arg, "--help") then
		puts(io:STDOUT, 
"""eui dsearch.ex [options] c_function_name
			--all        : find all such libraries with the named function (implies -quiet)
			--help       : display this help message
			--lib        : use the argument following lib as the sole library to search
			--quiet      : do not display searched libraries while running. 
			--recursive  : search sub-directories in all library paths
""" )
			abort(0)
	elsif search:begins(arg, "--lib") then
		if cmd_i < length(cmd) then
		    string next = cmd[cmd_i+1]
		    object add_lib = dir(next)
		    if not libraries_specified_at_command_line then
			directory_list = {}
		    end if
		    if atom(add_lib) then
		        puts(io:STDERR, "Library file specified does not exist!\n")
		        abort(1)
		    elsif length(add_lib) > 1 then
		        directory_list = append(directory_list, next)
		    else
			dll_list = append(dll_list, next)
		    end if
		    cmd_i += 1
		    libraries_specified_at_command_line = TRUE
		else
		    puts(io:STDERR, "library not specified at the command line.\n")
		    abort(1)
		end if
	elsif search:begins(arg,"--recursive") then
		recursive = TRUE
	elsif search:begins(arg, "--all") then
			only_first = FALSE
			quiet = TRUE
	elsif search:begins(arg, "--quiet") then
			quiet = TRUE
	elsif length(arg) > 1 and arg[1] = '-' and arg[2] != '-' then
		  	sequence new_arg = {}
		  	for ai = 2 to length(arg) do
				integer c  = arg[ai]
				switch c do
					case 'r' then
					    new_arg = append(new_arg,"--recursive")
					case 'h' then
					  new_arg = append(new_arg, "--help")
					case 'a' then
					  new_arg = append(new_arg, "--all")
					case 'q' then
					  new_arg = append(new_arg, "--quiet")
					case 'l' then
					  new_arg = append(new_arg, "--lib")
					  if length(arg) > ai then
						new_arg = append(new_arg, arg[ai+1..$])
						exit
					  end if
					case else
					printf(io:STDERR, "Unknown option %s\n", {c})
					abort(0)
				 end switch				 
            end for
            -- replace arguments and avoid cmd_i increment.
            cmd = cmd[1..cmd_i-1] & new_arg & cmd[cmd_i+1..$]
            continue
    elsif length(arg) >= 1 and arg[1]= '-' then
			printf(io:STDERR, "Unknown option %s\n", {arg})
			abort(0)
	else 
			orig_string = arg
	end if
    cmd_i += 1
end while

    for i = 1 to length(directory_list) do
	sequence directory = directory_list[i]
	dll_list &= add_to_dlls(directory)
    end for


if equal(orig_string, "") then
    orig_string = delete_trailing_white( console:prompt_string("C function name:") )
end if

routine_name = orig_string

if length(routine_name) = 0 then
    abort(0)
end if

locate(orig_string)

if not found_at_least_one then
    puts(io:STDOUT, "\nCouldn't find " & orig_string & '\n')
end if
console:any_key("Press any key to exit..", io:STDOUT)

