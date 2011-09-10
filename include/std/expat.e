--****
-- == Expat XML Parsing
--
-- <<LEVELTOC level=2 depth=4>>
--
-- === Introduction
--
-- Expat is a fast C XML parser built into Euphoria.
--
-- === Creation

namespace expat

include std/machine.e
include std/dll.e
include std/map.e

enum
    M_EXPAT_CREATE_PARSER = 105,
    M_EXPAT_RESET_PARSER,
    M_EXPAT_FREE_PARSER,
    M_EXPAT_PARSE,
    M_EXPAT_SET_CALLBACK,
    M_EXPAT_GET_CALLBACK

enum
    START_ELEMENT_CALLBACK = 1,
    END_ELEMENT_CALLBACK,
    CHAR_DATA_CALLBACK,
    DEFAULT_CALLBACK,
    COMMENT_CALLBACK

------------------------------------------------------------------------------
--
-- Internal Callbacks
--
------------------------------------------------------------------------------

function start_element_handler(object userdata, object name, object atts)
    integer rid = get_start_element_callback(userdata)
    
    if rid >= 0 then
        object attrs_m = 0
        sequence attrs = peek_string_pointer_array(atts)
        
        if length(attrs) > 0 then
            attrs_m = map:new(length(attrs) / 2)
            
            for i = 1 to length(attrs) by 2 do
                map:put(attrs_m, attrs[i], attrs[i+1])
            end for
        end if
        
        call_proc(rid, { peek_string(name), attrs_m })
    end if
    
    return 0
end function

function end_element_handler(object userdata, object name)
    integer rid = get_end_element_callback(userdata)
    
    if rid >= 0 then
        call_proc(rid, { peek_string(name) })
    end if
    
    return 0
end function

function char_data_handler(object userdata, object s, object len)
    integer rid = get_char_data_callback(userdata)
    
    if rid >= 0 then
        call_proc(rid, { peek({ s, len }) })
    end if
    
    return 0
end function

function default_handler(object userdata, object s, object len)
    integer rid = get_default_callback(userdata)
    
    if rid >= 0 then
        call_proc(rid, { peek({ s, len }) })
    end if
    
    return 0
end function

function comment_handler(object userdata, object data)
    integer rid = get_comment_callback(userdata)
    
    if rid >= 0 then
        call_proc(rid, { peek_string(data) })
    end if
    
    return 0
end function

--**
-- Create a new parser.
--

public function create(sequence encoding)
    object o = machine_func(M_EXPAT_CREATE_PARSER, {
        encoding,
        call_back({'+', routine_id("start_element_handler")}),
        call_back({'+', routine_id("end_element_handler")}),
        call_back({'+', routine_id("char_data_handler")}),
        call_back({'+', routine_id("default_handler")}),
        call_back({'+', routine_id("comment_handler")})
    })
    
    delete_routine(o, routine_id("free"))
    
    return o
end function

--**
-- Reset an existing parser
--

public function reset(object parser, sequence encoding)
    return machine_func(M_EXPAT_RESET_PARSER, { parser, encoding })
end function

--**
-- Free a parser
--

public function free(object parser)
    return machine_func(M_EXPAT_FREE_PARSER, { parser })
end function

--****
-- === Parsing

--**
-- Parse an XML string
--

public function parse(object parser, sequence buffer)
    return machine_func(M_EXPAT_PARSE, { parser, buffer })
end function

--****
-- ==== Callbacks
--

--**
-- Set the start element callback routine.

public procedure set_start_element_callback(object parser, integer rid)
    machine_func(M_EXPAT_SET_CALLBACK, { parser, START_ELEMENT_CALLBACK, rid })
end procedure

--**
-- Set the end element callback routine.

public procedure set_end_element_callback(object parser, integer rid)
    machine_func(M_EXPAT_SET_CALLBACK, { parser, END_ELEMENT_CALLBACK, rid })
end procedure

--**
-- Set the character data callback routine.

public procedure set_char_data_callback(object parser, integer rid)
    machine_func(M_EXPAT_SET_CALLBACK, { parser, CHAR_DATA_CALLBACK, rid })
end procedure

--**
-- Set the default callback routine.

public procedure set_default_callback(object parser, integer rid)
    machine_func(M_EXPAT_SET_CALLBACK, { parser, DEFAULT_CALLBACK, rid })
end procedure

--**
-- Set the comment callback routine.

public procedure set_comment_callback(object parser, integer rid)
    machine_func(M_EXPAT_SET_CALLBACK, { parser, COMMENT_CALLBACK, rid })
end procedure

--**
-- Get the start element callback routine.

public function get_start_element_callback(object parser)
    return machine_func(M_EXPAT_GET_CALLBACK, { parser, START_ELEMENT_CALLBACK})
end function

--**
-- Get the end element callback routine.

public function get_end_element_callback(object parser)
    return machine_func(M_EXPAT_GET_CALLBACK, { parser, END_ELEMENT_CALLBACK })
end function

--**
-- Get the character data callback routine.

public function get_char_data_callback(object parser)
    return machine_func(M_EXPAT_GET_CALLBACK, { parser, CHAR_DATA_CALLBACK })
end function

--**
-- Get the default callback routine.

public function get_default_callback(object parser)
    return machine_func(M_EXPAT_GET_CALLBACK, { parser, DEFAULT_CALLBACK })
end function

--**
-- Get the comment callback routine.

public function get_comment_callback(object parser)
    return machine_func(M_EXPAT_GET_CALLBACK, { parser, COMMENT_CALLBACK })
end function
