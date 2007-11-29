-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- The Binder
-- uses the Euphoria front-end, plus a special Euphoria-coded back-end

without type_check

include mode.e
set_mode( "bind", 0 )

global constant TRUE = 1, FALSE = 0

global constant TRANSLATE = FALSE,  
		INTERPRET = TRUE,
		BIND = TRUE
		
global constant EXTRA_CHECK = FALSE 

-- standard Euphoria includes
include misc.e
include wildcard.e

-- front-end
include global.e
include reswords.e
include error.e
include keylist.e
include c_out.e     -- Translator output (leave in for now)
include symtab.e
include scanner.e
include emit.e
include parser.e

-- BINDER backend:
include il.e
   
-- main program:
include main.e

