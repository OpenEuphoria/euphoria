with trace
-- (c) Copyright - See License.txt
--
-- A Read-Eval-Print-Loop Euphoria Interpreter written 100% in Euphoria
--
-- usage:
--        eui repl.ex

with define EU_EX

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include mode.e
set_mode( "interpret", 1 )		

-- standard Euphoria includes
include std/os.e
include std/pretty.e
include std/wildcard.e

-- INTERPRETER front-end
include global.e
repl = 1 -- activate REPL mode
include reswords.e
include std/error.e
include keylist.e

include c_out.e    -- Translator output (leave in for now)

include symtab.e
include scanner.e
include emit.e
include parser.e

-- INTERPRETER back-end, written in Euphoria
include execute.e   
   
-- main program:
include main.e
