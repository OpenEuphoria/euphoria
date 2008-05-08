-- (c) Copyright 2007 Rapid Deployment Software - See License.txt

-- Handlers for HTML output format
-- Special Enhanced HTML tags (ie, HTMX tags) that we created are processed.
-- Comments are deleted.
-- All other HTML is passed through unchanged.
-- All <_4clist>, <_3clist> and <_2clist> tags can contain any htmL (NOT htmX)
-- tag inside their fields. They will be all processed as usual.
-- rules about <_eucode>:
--   </_eucode> must appear on a new line, ie, not with the last line of eucode.
--   Also when <_eucode>.. </_eucode> appears in between <table>.. </table>, 
--   it cannot be the first row entry. And the table must be with <_2clist>,
--   <_3clist> or <_4clist> entries. 
-- written by: Junko C. Miura of Rapid Deployment Software (JCMiura@aol.com)

include wildcard.e
include sequence.e

-- constants for colors necessary for syncolor.e
global constant NORMAL_COLOR  = #330033,
		COMMENT_COLOR = #FF0055,
		KEYWORD_COLOR = #0000FF,
		BUILTIN_COLOR = #FF00FF,
		STRING_COLOR  = #00A033,
		BRACKET_COLOR = {NORMAL_COLOR, #993333,
				 #0000FF, #5500FF, #00FF00}

-- from euphoria\bin
include keywords.e
include syncolor.e

constant YEAR_DELIMITER = 90, SINCE_YEAR = 1900
integer blank
blank = FALSE
sequence line, colorLine                -- both for <_eucode>... </_eucode>
integer firstLine, in2clist, in3clist   -- both for <_eucode>... </_eucode>

-- helper functions

procedure sdiv(sequence class)
-- start a div tag
    write(sprintf("<div class=\"%s\">", {class}))
end procedure

procedure ediv()
-- end a div tag
    write("</div>\n")
end procedure

procedure sspan(sequence class)
-- start a span tag
    write(sprintf("<span class=\"%s\">", {class}))
end procedure

procedure espan()
-- end a span tag
    write("</span>")
end procedure

procedure tag_default(object raw_text, object param_list)
-- default handler - let most html pass through unchanged
    write(raw_text)
end procedure

procedure tag_eucode(sequence raw_text, sequence plist)
    object title
    title = pval("title", plist)
    
    if sequence(title) then
	sdiv("example-title")
	write(title)
	ediv()
    end if
    
    inEuCode = TRUE
    firstLine = TRUE
    line = ""
    -- note: write("<pre>") must be delayed until just before actual first line
end procedure

procedure tag_end_eucode(sequence raw_text, sequence plist)
    inEuCode = FALSE
    blank = FALSE
    write("</pre>")
end procedure

procedure tag_doc(sequence raw_text, sequence plist)
    object title
    
    title = pval("title", plist)
    if atom(title) then
	quit("doc tag must have a title attribute")
    end if
    
    write("<html>\n")
    write("<head>\n")
    write(sprintf("<title>%s</title>\n", {title}))
    write("<link rel=\"stylesheet\" media=\"screen\" href=\"display.css\">")
    write("</head>\n")
    write("<body>\n")
end procedure

procedure tag_end_doc(sequence raw_text, sequence plist)
    write("</body></html>\n")
end procedure

procedure tag_funcref(sequence raw_text, sequence plist)
    object name, inc, params, ret
    name   = pval("name", plist)
    inc    = pval("inc", plist)
    params = pval("params", plist)
    ret    = pval("ret", plist)
    
    sdiv("funcref")
    write(sprintf("<a name=\"%s\"></a>", {name}))
    write(sprintf("<div><strong>Function:</strong> %s(%s)</div>\n", {name, params}))
    write("<div><strong>Location:</strong> ")
    if atom(inc) then
	write("internal")
    else
	write(inc)
    end if
    ediv()
    write("<div><strong>Usage:</strong></div>")
    write("<pre>\n")
    if atom(inc) then
	write(sprintf("%s = %s(%s)", {ret, name, params}))
    else
	write(sprintf("include %s\n%s = %s(%s)", {inc, ret, name, params}))
    end if
    write("</pre>\n")
    ediv()
end procedure

procedure tag_end_funcref(sequence raw_text, sequence plist)
    ediv()
end procedure

procedure tag_gpre(sequence raw_text, sequence plist)
    write(sprintf("<pre class=\"%s\">", {trim(raw_text, "<>\\")}))
end procedure

procedure tag_end_gpre(sequence raw_text, sequence plist)
    write("</pre>")
end procedure

procedure tag_gdiv(sequence raw_text, sequence plist)
    sdiv(trim(raw_text, "<>\\"))
end procedure

procedure tag_end_gdiv(sequence raw_text, sequence plist)
    ediv()
end procedure

procedure tag_gspan(sequence raw_text, sequence plist)
-- being a generic span
    sspan(trim(raw_text, "<>\\"))
end procedure

procedure tag_end_gspan(sequence raw_text, sequence plist)
-- end a generic span
    espan()
end procedure

global procedure html_init()
-- set up handlers for html output
    add_handler("_default",  routine_id("tag_default"))
    add_handler("_eucode",   routine_id("tag_eucode"))
    add_handler("/_eucode",  routine_id("tag_end_eucode"))
    add_handler("doc",       routine_id("tag_doc"))
    add_handler("/doc",      routine_id("tag_end_doc"))
    add_handler("funcref",   routine_id("tag_funcref"))
    add_handler("/funcref",  routine_id("tag_end_funcref"))
    add_handler("path",      routine_id("tag_gspan"))
    add_handler("/path",     routine_id("tag_end_gspan"))
    add_handler("env",       routine_id("tag_gspan"))
    add_handler("/env",      routine_id("tag_end_gspan"))
    add_handler("program",   routine_id("tag_gspan"))
    add_handler("/program",  routine_id("tag_end_gspan"))
    add_handler("console",   routine_id("tag_gpre"))
    add_handler("/console",  routine_id("tag_end_gpre"))
    add_handler("gui",       routine_id("tag_gspan"))
    add_handler("/gui",      routine_id("tag_end_gspan"))
    
    out_type = "htm"

    init_class()     -- defined in syncolor.e
end procedure

