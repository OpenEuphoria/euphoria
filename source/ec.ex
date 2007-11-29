-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Translator main file

without type_check

include mode.e
set_mode("translate", 0 )

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

