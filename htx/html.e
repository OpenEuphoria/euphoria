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
include docgen.e

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
sequence line, colorLine -- <_eucode>... </_eucode>
integer firstLine        -- <_eucode>... </_eucode>

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

procedure write_secnum_a()
	write(sprintf("<a name=\"#%s\"></a>", {secnum_tag()}))
end procedure

procedure tag_h1(object raw_text, object param_list)
	line = ""
	
	sec_nums = (sec_nums[1] + 1) & {0,0,0,0,0}
	write_secnum_a()
	write(raw_text)
	write(secnum_text())
end procedure

procedure tag_h2(object raw_text, object param_list)
	line = ""
	
	sec_nums = sec_nums[1] & (sec_nums[2] + 1) & {0,0,0,0}
	write_secnum_a()
	write(raw_text)
	write(secnum_text())
end procedure

procedure tag_h3(object raw_text, object param_list)
	line = ""
	
	sec_nums = sec_nums[1..2] & (sec_nums[3] + 1) & {0,0,0}
	write_secnum_a()
	write(raw_text)
	write(secnum_text())
end procedure

procedure tag_h4(object raw_text, object param_list)
	line = ""
	
	sec_nums = sec_nums[1..3] & (sec_nums[4] + 1) & {0,0}
	write_secnum_a()
	write(raw_text)
	write(secnum_text())
end procedure

procedure tag_h5(object raw_text, object param_list)
	line = ""
	
	sec_nums = sec_nums[1..4] & (sec_nums[5] + 1) & 0
	write_secnum_a()
	write(raw_text)
	write(secnum_text())
end procedure

procedure tag_h6(object raw_text, object param_list)
	line = ""
	
	sec_nums = sec_nums[1..5] & sec_nums[6] + 1
	write_secnum_a()
	write(raw_text)
	write(secnum_text())
end procedure

procedure tag_end_header(object raw_text, object param_list)
	sections = append(sections, {current_file, sec_nums, line})
	write(line)
	write(raw_text)

	line = ""
end procedure

procedure tag_default(object raw_text, object param_list)
-- default handler - let most html pass through unchanged
	if in_tag("eucode") then
		line = line & raw_text
		if atom(raw_text) and raw_text = '\n' then
			if firstLine = TRUE then
				firstLine = FALSE
				write("<pre>")
				if all_white(line) then
					line = ""
					return
				end if
			end if
			colorLine = SyntaxColor(line)
			for i = 1 to length(colorLine) do
				write(sprintf("<font color=\"#%06x\">%s</font>", {
					colorLine[i][1], colorLine[i][2]}))
			end for
			write("\n")
			line = ""
		end if
	elsif in_tag("h1") or in_tag("h2") or in_tag("h3") or in_tag("h4") or in_tag("h5") or in_tag("h6") then
		line &= raw_text
	else
		write(raw_text)
	end if
end procedure

procedure tag_eucode(sequence raw_text, sequence plist)
	object title
	title = pval("title", plist)
	
	if sequence(title) then
		if in_tag("funcref") then
			write(sprintf("<tr><th>%s:</th><td>", {title}))
		else
			sdiv("example-title")
			write(title)
			ediv()
		end if
	end if

	firstLine = TRUE
	line = ""
end procedure

procedure tag_end_eucode(sequence raw_text, sequence plist)
	write("</pre>\n")
	if in_tag("funcref") then
		write("</td></tr>\n")
	end if 
end procedure

procedure tag_doc(sequence raw_text, sequence plist)
	object title, sect
	
	title = pval("title", plist)
	if atom(title) then
		quit("doc tag must have a title attribute")
	end if

	file_header = 1
	write("<html>\n")
	write("<head>\n")
	write(sprintf("<title>%s</title>\n", {title}))
	write("<link rel=\"stylesheet\" media=\"screen\" href=\"display.css\">")
	write("</head>\n")
	write("<body>\n")
	file_header = 0
end procedure

procedure tag_end_doc(sequence raw_text, sequence plist)
	file_header = 1
	write("</body></html>\n")
	file_header = 0
end procedure

procedure tag_funcref(sequence raw_text, sequence plist)
	object name, inc, params, ret, typ
	name   = pval("name", plist)
	inc    = pval("inc", plist)
	params = pval("params", plist)
	typ    = pval("type", plist)

	write(sprintf("<a name=\"%s\"></a>", {name}))
	write(sprintf("<h3 class=\"funcref\">%s</h3>", {name}))

	write("<table class=\"func\">\n")
	write(sprintf("<tr><th>Type:</th><td>%s</td></tr>\n", {typ}))
	write(sprintf("<tr><th>Parameters:</th><td>%s</td></tr>\n", {params}))
end procedure

procedure tag_end_funcref(sequence raw_text, sequence plist)
	write("</table>")
end procedure

procedure tag_funcdescr(sequence raw_text, sequence plist)
	write("<tr><th>Description:</th>\n<td>\n")
end procedure

procedure tag_end_funcdescr(sequence raw_text, sequence plist)
	write("</td>\n</tr>\n")
end procedure

procedure tag_funccomments(sequence raw_text, sequence plist)
	write("<tr><th>Comments:</th>\n<td>\n")
end procedure

procedure tag_end_funccomments(sequence raw_text, sequence plist)
	write("</td>\n</tr>\n")
end procedure

procedure tag_funcseealso(sequence raw_text, sequence plist)
	write("<tr><th>See Also:</th>\n<td>\n")
end procedure

procedure tag_end_funcseealso(sequence raw_text, sequence plist)
	write("</td>\n</tr>\n")
end procedure

procedure tag_funcreturns(sequence raw_text, sequence plist)
	write("<tr><th>Returns:</th>\n<td>\n")
end procedure

procedure tag_end_funcreturns(sequence raw_text, sequence plist)
	write("</td>\n</tr>\n")
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
	add_handler("eucode",    routine_id("tag_eucode"))
	add_handler("/eucode",   routine_id("tag_end_eucode"))
	add_handler("doc",       routine_id("tag_doc"))
	add_handler("/doc",      routine_id("tag_end_doc"))
	add_handler("funcref",   routine_id("tag_funcref"))
	add_handler("/funcref",  routine_id("tag_end_funcref"))
	add_handler("funcdescr", routine_id("tag_funcdescr"))
	add_handler("/funcdescr",routine_id("tag_end_funcdescr"))
	add_handler("funccomments", routine_id("tag_funccomments"))
	add_handler("/funccomments",routine_id("tag_end_funccomments"))
	add_handler("funcseealso", routine_id("tag_funcseealso"))
	add_handler("/funcseealso",routine_id("tag_end_funcseealso"))
	add_handler("funcreturns", routine_id("tag_funcreturns"))
	add_handler("/funcreturns",routine_id("tag_end_funcreturns"))
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
	add_handler("h1",        routine_id("tag_h1"))
	add_handler("/h1",       routine_id("tag_end_header"))
	add_handler("h2",        routine_id("tag_h2"))
	add_handler("/h2",       routine_id("tag_end_header"))
	add_handler("h3",        routine_id("tag_h3"))
	add_handler("/h3",       routine_id("tag_end_header"))
	add_handler("h4",        routine_id("tag_h4"))
	add_handler("/h4",       routine_id("tag_end_header"))
	add_handler("h5",        routine_id("tag_h5"))
	add_handler("/h5",       routine_id("tag_end_header"))
	add_handler("h6",        routine_id("tag_h6"))
	add_handler("/h6",       routine_id("tag_end_header"))
	out_type = "htm"

	init_class()     -- defined in syncolor.e
end procedure

