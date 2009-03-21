#!/usr/bin/exu -i /usr/share/euphoria/source/
-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- The Binder
-- uses the Euphoria front-end, plus a special Euphoria-coded back-end

without type_check
-- Disable SVN Revision banner
with define EU_FULL_RELEASE


include mode.e
set_mode( "bind", 0 )

-- BINDER backend:
include il.e
   
-- main program:
include main.e

