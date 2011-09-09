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

enum
    M_EXPAT_CREATE_PARSER = 105,
    M_EXPAT_RESET_PARSER,
    M_EXPAT_FREE_PARSER,
    M_EXPAT_PARSE

------------------------------------------------------------------------------
--
-- Internal Callbacks
--
------------------------------------------------------------------------------

function start_element_handler(object userdata, object name, object atts)
    printf(1, "start_element\n")
    return 0
end function

function end_element_handler(object userdata, object name)
    printf(1, "end_element\n")
    return 0
end function

function char_data_handler(object userdata, object s, object len)
    printf(1, "char_data\n")
    return 0
end function

function default_handler(object userdata, object s, object len)
    printf(1, "default handler\n")
    return 0
end function

function comment_handler(object userdata, object data)
    printf(1, "comment handler\n")
    return 0
end function

--**
-- Create a new parser.
--

public function create(sequence encoding)
    return machine_func(M_EXPAT_CREATE_PARSER, {
        encoding,
        call_back({'+', routine_id("start_element_handler")}),
        call_back({'+', routine_id("end_element_handler")}),
        call_back({'+', routine_id("char_data_handler")}),
        call_back({'+', routine_id("default_handler")}),
        call_back({'+', routine_id("comment_handler")})
    })
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

public function parse(object parser, sequence buffer)
    return machine_func(M_EXPAT_PARSE, { parser, buffer })
end function
