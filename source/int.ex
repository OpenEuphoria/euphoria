-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- the official C back-end interpreter

without type_check

global constant TRUE = 1, FALSE = 0

global constant TRANSLATE = FALSE,  
		INTERPRET = TRUE,
		BIND = FALSE
		
global constant EXTRA_CHECK = FALSE 

-- standard Euphoria includes
include misc.e
include wildcard.e

include global.e
include reswords.e
include error.e
include keylist.e
include c_out.e    -- Translator output (leave in for now)
include symtab.e
include scanner.e
include emit.e
include parser.e

-- INTERPRETER C-backend interface:
include compress.e
include backend.e

global procedure OutputIL()
-- dummy routine
end procedure

global function extract_options(sequence s)
-- dummy routine    
    return s
end function

-- main program:
include main.e

