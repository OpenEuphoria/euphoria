-- (c) Copyright - See License.txt
-- std.ex: Tool for helping with standard library migration.
--
-- Useful for finding where symbols may have changed from
-- global to export.  This tool can help with other libraries,
-- too.  In each file, a special include file "euphoria/stddebug.e"
-- is added.  This includes all of the standard library functionality,
-- but none of the symbols are exported.  The parser looks
-- for matching export symbols that wouldn't normally be 
-- visible to the code, and if that's the only option,
-- it will issue a warning indicating which file needs
-- to be included.
--
-- No code is executed.  This tool exists simply to parse and
-- identify missing include statements.

with define STDDEBUG
include eui.ex

