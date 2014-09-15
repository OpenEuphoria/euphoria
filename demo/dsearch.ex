--****
-- === win32/dsearch.exw
-- 
-- search for a .DLL that contains a given routine
-- ==== Usage
-- {{{
-- eui dsearch [routine] 
-- }}}
--
-- If you don't supply a string on the command line you will be prompted 
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

constant TRUE = 1, FALSE = 0

type boolean(integer x)
    return x = FALSE or x = TRUE
end type

type c_routine(integer x)
    return x >= -1 and x <= 1000
end type

sequence cmd, orig_string

integer scanned, no_open
scanned = 0
no_open = 0

ifdef WINDOWS then
    c_routine FreeLibrary, GetProcAddress, OpenLibrary
end ifdef

ifdef LINUX then

enum 
  LH_PIPES,
  LH_DATA

end ifdef

atom string_pointer
sequence routine_name
sequence dll_list
ifdef WINDOWS then
    dll_list = {
        "kernel32.dll",
        "user32.dll",
        "gdi32.dll",
        "winmm.dll",
        "comdlg32.dll",
        "comctl32.dll"
    }
elsedef
    dll_list = {}
end ifdef

sequence file_list = { `c:\windows\system32`, dir(`c:\windows\system32\*.dll`), "/lib",  dir(`/lib/*.so`), "/usr/lib", dir(`/usr/lib/*.so`), "/usr/local/lib", dir("/usr/local/*.so") }

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
            abort(1)
        end if
        GetProcAddress = define_c_func(kernel32, "GetProcAddress", 
                         {C_POINTER, C_POINTER}, C_INT)
        if GetProcAddress = -1 then
            puts(io:STDERR, "Can't find GetProcAddress\n")
            abort(1)
        end if
    elsifdef LINUX then
        if not file_exists("/usr/bin/nm") then
            puts(io:STDERR, "This program requires nm (from the binutils package).\n")
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
        return eu:open_dll(name)
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
    printf(io:STDOUT, "%s: ", {file_name})
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

for i = 1 to length(file_list) by 2 do
    if integer(file_list[i+1]) then
        continue
    end if
    for j = 1 to length(file_list[i+1]) do
	dll_list = append( dll_list, file_list[i] & SLASH & file_list[i+1][j][D_NAME] )
    end for
end for

CSetup()

cmd = command_line()   -- eui dsearch [string]

for cmd_i = 3 to length(cmd) do
    if cmd_i > length(cmd) then
        exit
    end if
    if equal(cmd[cmd_i], "--lib") then
        if cmd_i < length(cmd) then
            dll_list = {cmd[cmd_i+1]}
            cmd = cmd[1..cmd_i-1] & cmd[cmd_i+2..$]
        end if
    end if
end for

if length(cmd) >= 3 then
    orig_string = cmd[$]
else
    puts(io:STDOUT, "C function name:")
    orig_string = delete_trailing_white(gets(io:STDIN))
    puts(io:STDOUT, '\n')
end if

routine_name = orig_string

procedure locate(sequence name)
    routine_name = name
    puts(io:STDOUT, "Looking for " & routine_name & "\n ")
    for i = 1 to length(dll_list) do
	if scan(dll_list[i]) then
	    if getc(0) then
	    end if
	    abort(1)
	end if
    end for
    puts(1, '\n')
end procedure

if length(routine_name) = 0 then
    abort(0)
end if

locate(orig_string)

puts(io:STDOUT, "\nCouldn't find " & orig_string & '\n')
puts(io:STDOUT, "Press Enter\n")

if getc(0) then
end if

