-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Translator main file

without type_check

global constant TRUE = 1, FALSE = 0

global constant TRANSLATE = TRUE,  
		INTERPRET = FALSE,
		BIND = FALSE
		
global constant EXTRA_CHECK = FALSE

-- standard Euphoria includes
include misc.e
include wildcard.e

-- front-end
include global.e
include reswords.e
include error.e
include keylist.e
include c_out.e
include symtab.e
include scanner.e
include emit.e
include parser.e

-- TRANSLATOR backend
include c_decl.e
include opnames.e
include compile.e  
include traninit.e

-- main program:
include main.e

