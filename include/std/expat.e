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

enum
    M_EXPAT_CREATE_PARSER = 105,
    M_EXPAT_RESET_PARSER,
    M_EXPAT_FREE_PARSER

--**
-- Create a new parser.
--

public function create(sequence encoding)
    return machine_func(M_EXPAT_CREATE_PARSER, { encoding })
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
