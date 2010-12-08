#!/usr/bin/eui -i /usr/share/euphoria/source/
-- (c) Copyright - See License.txt
--
-- The Binder
-- uses the Euphoria front-end, plus a special Euphoria-coded back-end

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include mode.e
set_mode( "bind", 0 )

-- BINDER backend:
include il.e

-- main program:
include main.e
