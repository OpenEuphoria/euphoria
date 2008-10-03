-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- the official C back-end interpreter
without type_check

include mode.e
set_mode( "interpret", 0 )

-- standard Euphoria includes
include std/wildcard.e

include global.e
include reswords.e
include std/error.e
include keylist.e
include c_out.e    -- Translator output (leave in for now)
include symtab.e
include scanner.e
include emit.e
include parser.e
include intinit.e

-- INTERPRETER C-backend interface:
include compress.e
include backend.e

global procedure OutputIL()
-- dummy routine
end procedure

-- main program:
include main.e
