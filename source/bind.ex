#!/usr/bin/exu -i /usr/share/euphoria/source/
-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- The Binder
-- uses the Euphoria front-end, plus a special Euphoria-coded back-end

without type_check

include std/filesys.e

include mode.e
set_mode( "bind", 0 )


-- standard Euphoria includes
include std/wildcard.e

-- front-end
include global.e
include reswords.e
include std/error.e
include keylist.e
include c_out.e     -- Translator output (leave in for now)
include symtab.e
include scanner.e
include emit.e
include parser.e

-- BINDER backend:
include il.e
   
-- Disable SVN Revision banner
with define EU_FULL_RELEASE

-- main program:
include main.e

