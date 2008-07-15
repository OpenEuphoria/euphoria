-- Outputs IL code and symbol table
-- To generate doxygen-like html output use option:
--   --html
-- To modify the output:
-- { "d", "dir", "output directory", HAS_PARAMETER, routine_id("set_out_dir") },
-- { "p", "dep", "suppress dependencies", NO_PARAMETER, routine_id("suppress_dependencies") },
-- { "s", "std", "show standard library information", NO_PARAMETER, routine_id("suppress_stdlib") },
-- { "f", "file", "include this file", HAS_PARAMETER, routine_id("document_file") },
-- { "g", "graphs", "suppress call graphs", NO_PARAMETER, routine_id("suppress_callgraphs") }
-- default output dir: eudox
-- stdlib suppressed by default
without type_check
include mode.e
sequence cmd = command_line()
if find( "-t", cmd ) then
	set_mode( "translate", 0 )
else
	set_mode( "interpret", 0 )
end if

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

-- Disassembler:
include dis.e

-- global procedure OutputIL()
-- -- dummy routine
-- end procedure
-- 
-- global function extract_options(sequence s)
-- -- dummy routine    
-- 	return s
-- end function

-- main program:
include main.e

