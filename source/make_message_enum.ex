-- replace all magic numbers in the source files in the current directory passed to GetMsgText, CompileErr, and ShowMsg 
-- replace the constant declarations with an enum type statement in msgtext.e

include std/io.e as io
include std/regex.e as pcre
include std/search.e as tre
include std/get.e as euparse
include std/text.e as text
include std/math.e as math
include std/map.e as map
include std/sort.e
include std/types.e
include std/filesys.e

constant MAX_LENGTH_LIMIT = 45
constant message_pattern = pcre:new("{ *([A-Z_0-9]+) *, ?([`\"].*[`\"]) *},")
constant euphoria_constant_pattern = pcre:new("[A-Z][A-Z_0-9]+")
constant eol_messages_pattern = pcre:new(` +\$$`, pcre:ANCHORED)
constant euphoria_assignment = pcre:new("([A-Z][A-Z0-9_]+) *= *([0-9]+)")
constant vals = map:new()
constant syms = map:new()
constant message_fn = pcre:new(`(ShowMsg\([^,]+,|GetMsgText\(|CompileErr\() *([^,)]+)[,)]`)

if atom(euphoria_constant_pattern) then
    printf(io:STDERR, "Pattern could not be created: %s\n", {pcre:error_message(euphoria_constant_pattern)} )
    abort(1)
end if

constant msgtext = open("msgtext.e", "r")
constant new_msgtext = open("new_msgtext.e", "w")

type ualpha(integer c)
    return ('A' <= c) and (c <= 'Z')
end type

integer call_count = 0
-- create a name out of a message
function create_name(sequence message)
        sequence new_name = text:upper(    tre:find_replace(' ',  tre:match_replace("\\n", message[2..$-1], ""),  '_')    )
        
        trace(not call_count)
        call_count += 1
        if length(new_name) and not ualpha(new_name[1]) then
            new_name = "MSG_" & new_name
        end if
        integer i = 1      
        while i <= length(new_name) do
            integer c = new_name[i]
            if not t_alnum(c) and c != '_' then
                new_name = remove(new_name, i)
            else
                i = i + 1
            end if
        end while
        
        integer old_length
        loop do
            old_length = length(new_name) 
            new_name = tre:match_replace("___", new_name, "__")
        until old_length = length(new_name)
        end loop
        
        while length(new_name) and new_name[$] = '_' do
            new_name = remove(new_name, length(new_name))
        end while
        
        return new_name
end function
 
-- replace magic number in the third member of group with that of a enumerated symbol
-- also replace the magic number contained in groups[1] with that same enumarted symbol
function replace_with_enumed(sequence groups)
    sequence buffer = euparse:value(groups[3])
    if buffer[1] != GET_SUCCESS or sequence(buffer[2]) then
        -- return unchanged.
        return groups[1]
    end if
    integer i = eu:match(groups[3], groups[1])
    sequence symbol = map:get(syms, buffer[2], 0)
    return groups[1][1..i-1] & symbol & groups[1][i+length(groups[3])..$]
end function

-- replace all magic numbers in the source files in the current directory passed to GetMsgText, CompileErr, and ShowMsg 
function search_replace_file(sequence directory, sequence item)
    if file_exists(directory & SLASH & item[D_NAME]) = 0 then
        printf(io:STDERR, "Cannot open %s/%s\n.", { directory, item[D_NAME]})
        return 1
    end if
    if find('d',item[D_ATTRIBUTES]) or (not ends(".e", item[D_NAME])) then
        return 0
    end if
    write_file(directory & SLASH & item[D_NAME], pcre:find_replace_callback(message_fn, read_file(directory & SLASH & item[D_NAME]), routine_id("replace_with_enumed")))
    return 0
end function






if msgtext = -1 then
    puts(io:STDERR, "Cannot open msgtext.e\n")
    abort(1)
end if

integer line_number = 0
object line
while sequence(line) and not (tre:begins("export enum", line) or tre:begins("public type enum", line)) with entry do
    puts(new_msgtext, line)
entry
    line = gets(msgtext)
    line_number += 1
end while

if atom(line) then
    puts(io:STDERR,  "Unexpected EOF reading msgtext.e: didn't find export enum\n")
    abort(1)
end if

if tre:begins("public type enum", line) then
    puts(io:STDERR, "The file has already been converted to use a type enum.\n")
    abort(1)
end if
-- parse the enum lines
integer counter = -999999
while sequence(line) and not tre:ends("$\n", line) with entry do
    object ass_groups = pcre:matches( euphoria_assignment, line )
    if sequence(ass_groups) then
        sequence buffer = euparse:value(ass_groups[3])
        if buffer[1] = GET_SUCCESS then
            map:put(syms, buffer[2], ass_groups[2])
            map:put(vals, ass_groups[2], buffer[2])
            counter = buffer[2] + 1
        else
            printf(io:STDERR, "Cannot parse number line %d : '%s'\n", { line_number, line })
            abort(1)
        end if
    else
        object constant_groups = pcre:matches( euphoria_constant_pattern, line )
        if sequence(constant_groups) then
            if counter = -999999 then
                counter = 1
            end if
            map:put(vals, constant_groups[1], counter )
            map:put(syms, counter, constant_groups[1] )
            counter += 1
        else
            printf(io:STDERR, "Cannot parse line %d :'%s'\n",{line_number, line} )
            abort(1)
        end if
    end if
entry
    line = gets(msgtext)
    line_number += 1
end while

if atom(line) then
    puts(io:STDERR,  "Unexpected EOF reading msgtext.e: didn't find constant StdErrMsgs\n")
    abort(1)
end if

-- pass through lines leading up to the StrErrMsgs line
while sequence(line) and not tre:begins("constant StdErrMsgs", line) with entry do
    puts(new_msgtext, line)
entry
    line = gets(msgtext)
    line_number += 1
end while

integer dummy_message_char = 'A'
sequence saved_line = line
sequence saved_text = line
sequence message_data = {}
sequence enum_values = {}
while sequence(line) with entry do
    object message_groups = pcre:matches( message_pattern, line )
    if atom(message_groups) then
        if length(line) > 2 and line[$-1] = '$' and line[$] = '\n' then
            exit
        end if
        printf(io:STDERR, "Unexpected pattern in the message texts:  The line %d is '%s'\n", {line_number, line})
        abort(1)
    end if
    sequence buffer = euparse:value(message_groups[2])
    sequence original_message_group2 = message_groups[2]
    if buffer[1] = euparse:GET_SUCCESS then
        sequence new_name = create_name(message_groups[3])
        if length(new_name) = 0 then
            message_groups[2] = sprintf("MSG_%s", {dummy_message_char})
            dummy_message_char += 1
        end if
        if not map:has(vals, new_name)  then
            message_groups[2] = new_name
        else 
            for l = 'A' to 'Z' do
                message_groups[2] = sprintf("%s_%s", {new_name, l})
                if not map:has(vals, message_groups[2]) then
                    exit
                end if
            end for
            if message_groups[2][$] = 'Z' then
                printf(io:STDERR, "Too many duplicate symbols.  Last symbol %s\n", message_groups[2..2])
            end if
        end if
        if not map:has(syms, buffer[2]) then
            map:put(syms, buffer[2], message_groups[2], map:PUT )
            map:put(vals, message_groups[2], buffer[2], map:PUT )
        end if
        saved_text &= sprintf("{ %s, %s},\n", message_groups[2..3])
        enum_values &= {buffer[2], message_groups[2]}
    else
        object symbol = map:get(vals, message_groups[2], {})
        if atom(symbol) then
            enum_values &= { symbol, message_groups[2] }
        else
            printf(io:STDERR, "Cannot determine the value of %s\n", { message_groups[2] } )
            abort(1)
        end if
        saved_text &= line
    end if
    message_data = append( message_data, message_groups[2..3])
entry
    line_number += 1
    line = gets(msgtext)
end while


-- output type enum now
printf(new_msgtext, "public type enum message_index\n", {})

constant sym_keys = stdsort:sort(map:keys(syms))
for counter_i = 1 to length(sym_keys) do
    counter = sym_keys[counter_i]
    object symbol = map:get(syms, counter, 0) 
    if atom(symbol) then
        exit
    end if
    if map:has(syms, counter-1) then
        printf(new_msgtext, "    %s,\n", {symbol})
    else
        printf(new_msgtext, "    %s=%d,\n", {symbol, counter})
    end if
end for
puts(new_msgtext, "    $\n")
puts(new_msgtext, "end type\n\n" & saved_line)
integer max_length  = 0
for i = 1 to length(message_data) do
    sequence dat = message_data[i]
    if length(dat[1]) <= MAX_LENGTH_LIMIT then
        max_length = max({length(dat[1]), max_length})
    end if
end for
sequence our_format = sprintf("    { %%-%ds, %%s },\n", {max_length})
message_data = stdsort:sort(message_data)
for i = 1 to length(message_data) do
    sequence dat = message_data[i]
    printf(new_msgtext, our_format, dat)
end for
puts(new_msgtext, "    $\n")

while sequence(line) with entry do
    integer gmt = eu:match("GetMsgText( integer MsgNum", line)
    if gmt then
        gmt = eu:match("integer", line, gmt)
    end if
    if gmt then
        line = line[1..gmt-1] & "message_index" & line[gmt+length("integer")..$]
    end if
    puts(new_msgtext, line)
entry
    line = gets(msgtext)
end while

close(new_msgtext)
close(msgtext)

ifdef not TEST then
    if walk_dir(current_dir(), routine_id("search_replace_file")) != 0 or not move_file("new_msgtext.e", "msgtext.e", 1) then
        puts(io:STDERR, "An error occured in processing the files!\n")
        abort(1)
    end if
end ifdef
