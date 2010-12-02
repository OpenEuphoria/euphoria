-- (c) Copyright - See License.txt
--
-- the official C back-end interpreter

with define INTERPRETER

ifdef ETYPE_CHECK then
    with type_check
elsedef
    without type_check
end ifdef

include mode.e
set_mode( "interpret", 0 )

-- standard Euphoria includes
include std/error.e
include std/wildcard.e

include global.e
include reswords.e
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
