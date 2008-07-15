-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.1 
--
-- A Euphoria Interpreter written 100% in Euphoria
--
-- usage:
--        ex eu.ex prog.ex     -- run a Euphoria program for DOS
--        exw eu.ex prog.exw   -- run a Euphoria program for Windows
--        exu eu.ex prog.exu   -- run a Euphoria program for Linux/FreeBSD

-- You can make this into a stand-alone .exe using the binder or the
-- Euphoria To C Translator. When translated/compiled it will run
-- much faster, but not as fast as the official RDS interpreter
-- which uses the same Euphoria-coded front-end, combined 
-- with a high-performance back-end carefully hand-coded in C.

without type_check -- FASTER



include mode.e
set_mode( "interpret", 1 )		


-- standard Euphoria includes
include std/os.e
include std/pretty.e
include std/wildcard.e

-- INTERPRETER front-end
include global.e
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

