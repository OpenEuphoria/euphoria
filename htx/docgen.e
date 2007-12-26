-- (c) Copyright 2007 Rapid Deployment Software - See License.txt

-- written by: Junko C. Miura of Rapid Deployment Software (JCMiura@aol.com)
include get.e
include wildcard.e
global sequence current_file
current_file = ""
global integer current_line
current_line = 0
global constant SCREEN = 1
global constant TRUE = 1, FALSE = 0, EOF = -1
global sequence out_type
global integer inPre, inEuCode, inTable
inPre    = FALSE
inEuCode = FALSE
inTable  = FALSE   -- used for inEuCode

global integer in_file, out_file

global procedure quit(sequence msg)
    puts(SCREEN, "DOC GEN ABORTED: " & msg & '\n')
    printf(SCREEN, "Inside file: %s:%d\n", {current_file, current_line})
    puts(SCREEN, "Contact Rapid Deployment Software - rds@RapidEuphoria.com\n")
    if getc(0) then
    end if
    abort(1/0)
end procedure

global function whitespace(integer c)
-- is c a whitespace character?
    return find(c, " \n\t\r")
end function

global function all_white(sequence s)
    for i = 1 to length(s) do
	if not whitespace(s[i]) then
	    return FALSE
	end if
    end for
    return TRUE
end function

global function pval(sequence pname, sequence plist)
-- find a parameter in the list and return the value string or 
-- TRUE / FALSE if there's no associated value.
-- if a parameter is absent in the list, then return FALSE.

    for i = 1 to length(plist) do
	if atom(plist[i][1]) then
	    -- just one word, not a pair
	    if compare(pname, plist[i]) = 0 then
		return TRUE
	    end if
	else
	    if compare(pname, plist[i][1]) = 0 then
		return plist[i][2]
	    end if
	end if
    end for
    return FALSE
end function

global sequence handler_name, handler_id
handler_name = {}
handler_id = {}

global procedure add_handler(sequence tag_name, integer routine)
-- add a new tag handler
    handler_name = prepend(handler_name, lower(tag_name))
    handler_id = prepend(handler_id, routine)
end procedure

global procedure write(object text)
-- write a series of characters to the output file
    puts(out_file, text)
end procedure


