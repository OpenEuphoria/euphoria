-- (c) Copyright 2006 Rapid Deployment Software - See License.txt


-- handlers for plain text output format
-- assumptions:
--   The usage of <_dul> and <_sul> is rather limited:
--   1) *in .htx file*, <_dul>, <_sul> are mutually exclusive with <center>, 
--      <_eucode>, and <pre>. Not because of technical difficulty to implement
--      it, but because it does not make much sense to allow the combination.
--      Might change my mind later and implement it.
--   2) Neither <_dul> nor <_sul> can spread over more than one lines in the
--      output file. This includes the case of starting at overflow line break.
--   3) Only one <_dul> set is allowed for one output line. Only one <_sul>
--      set is allowed for one output line also. This means that both of them
--      with one each set for one output line is allowed.
-- inside <_2clist>, <_3clist> and <_4clist> tags:
--   Both name and description fields can contain any htmL tag (NOT htmX tag),
--   although all the htmL tags except <p> and <br> will be ignored.
-- <_eucode> mixed with <_2clist>, <_3clist> or <_4clist> in a table may not be
--   the first entry in the table (ie, at least one of <_Nclist> must precede
--   <_eucode> if this <_eucode> is a part of the table).
-- written by: Junko C. Miura of Rapid Deployment Software (JCMiura@aol.com)

constant WIDTH = 80, UL_INDENT = 7, DL_INDENT = 7, BLQ_INDENT = 4
constant NOT_IN_DL = 0, FIRST_DL_LEVEL = 1, FIRST_UL_LEVEL = 1

integer in_ampersand, in_whitespace
integer inTitle, inCenter, ulLevel
integer dlLevel
integer dulFound, sulFound, dulStart, dulEnd, sulStart, sulEnd

integer column, indent, rememberIndent
-- rememberPos below is equivalent to rememberIndent, but for <_eucode> mixed
-- in <_Nclist> (N is 2 to 4). This way, we can intermix them with <dl> block.
integer rememberPos, firstEucodeLine 
sequence word, line           -- both for every output (not like html.e)

function delete_trailing_white(sequence text)
-- remove any whitespace at end of text
    while length(text) > 0 and whitespace(text[length(text)]) do
	text = text[1..length(text)-1]
    end while
    return text
end function

procedure underline()
    if dulFound and sulFound then
	if dulStart < sulStart then
	    write(repeat(' ', dulStart - 1) & 
		  repeat('=', dulEnd - dulStart + 1) &
		  repeat(' ', sulStart - dulEnd - 1) &
		  repeat('-', sulEnd - sulStart + 1))
	else
	    write(repeat(' ', sulStart - 1) & 
		  repeat('=', sulEnd - sulStart + 1) &
		  repeat(' ', dulStart - sulEnd - 1) &
		  repeat('-', dulEnd - dulStart + 1))
	end if
	write('\n')
	dulFound = FALSE
	sulFound = FALSE
    elsif dulFound then
	write(repeat(' ', dulStart - 1) & 
	      repeat('=', dulEnd - dulStart + 1))
	write('\n')
	dulFound = FALSE
    elsif sulFound then
	write(repeat(' ', sulStart - 1) &
	      repeat('-', sulEnd - sulStart + 1))
	write('\n')
	sulFound = FALSE
    end if
end procedure

procedure resetLineAndWord()
    line = repeat(' ', indent - 1)
    column = indent
    word = ""
    -- all whitespaces before a non-whitespace char will be ignored
    in_whitespace = TRUE 
end procedure

procedure getReadyNewLine()
    write(delete_trailing_white(line) & '\n')
    underline()
    line = repeat(' ', indent - 1)
    column = indent
    -- all whitespaces before a non-whitespace char will be ignored
    in_whitespace = TRUE 
end procedure

procedure writeText(sequence text)
    integer len
    
    len = length(word)
    if column + len > WIDTH then
	getReadyNewLine()
    end if
    line &= word
    column += len
    word = ""
    
    for i = 1 to length(text) do
	line &= text[i]
	column += 1
	if text[i] = '\n' then
	    getReadyNewLine()
	end if
    end for
end procedure

procedure tag_literal(integer raw_text, sequence param_list)
-- handle one character of literal text 
-- (i.e. text that is not inside a tag or comment)
    
    if inTitle then      -- don't print anything
	return
    end if
    if inPre or (inEuCode and not inTable) then
	write(raw_text)
	return
    end if
    if inEuCode then      -- and inTable
	if raw_text = '\n' then
	    if firstEucodeLine and all_white(line) then
		firstEucodeLine = FALSE
		write(repeat(' ', rememberPos - 1))
	    else
		write("\n" & repeat(' ', rememberPos - 1))
	    end if
	else 
	    write(raw_text)
	end if      
	return
    end if
    
    if whitespace(raw_text) then
	raw_text = ' '
    end if
    if inCenter then
	write(raw_text)
	return
    end if
    
    if in_ampersand then 
	if whitespace(raw_text) or raw_text = '\'' then
	    -- ampersand must be treated as a literal
	    in_ampersand = FALSE
	    writeText({raw_text})
	    if whitespace(raw_text) then
		in_whitespace = TRUE
	    end if
	elsif raw_text = ';' then
	    in_ampersand = FALSE
	    word = " "
	    writeText("")
	else
	    word &= raw_text
	end if
	return
    
    elsif raw_text = '&' then
	in_ampersand = TRUE
	-- add the word accumulated until now to the line
	writeText("")
	word = "&"
	return
    end if
    
    if whitespace(raw_text) then
	if in_whitespace then
	    return
	end if
	in_whitespace = TRUE
	writeText({raw_text})
    else
	in_whitespace = FALSE
	word &= raw_text
    end if
end procedure

procedure tag_dul(sequence raw_text, sequence param_list)
    dulFound = TRUE
    dulStart = column
end procedure

procedure tag_end_dul(sequence raw_text, sequence param_list)
    writeText("")
    dulEnd   = column - 1
end procedure

procedure tag_sul(sequence raw_text, sequence param_list)
    sulFound = TRUE
    sulStart = column
end procedure

procedure tag_end_sul(sequence raw_text, sequence param_list)
    writeText("")
    sulEnd = column - 1
end procedure

procedure tag_comment(sequence raw_text, sequence param_list)
-- comment handler - do nothing - don't have any comments in plain text output 
-- file
end procedure

procedure tag_default(sequence raw_text, sequence param_list)
-- default handler - remove any unknown htmL and htmX tags
end procedure

procedure outputString(sequence str)
    integer firstCharFound, i
    sequence tempStr
    
    firstCharFound = FALSE
    i = 1
    while i <= length(str) do
	-- an htmL tag? (note: htmX tags are NOT allowed. only htmL tags ok.)
	-- All htmL tags except <p> and <br> will be ignored in text output 
	-- format.
	if str[i] = '<' then 
	    if str[i + 1] != '=' and not whitespace(str[i + 1]) then
		-- htmL tag. Honor <p> and <br>, but eat all the other tags.
		tempStr = "<"
		i += 1
		while i <= length(str) and str[i] != '>' do
		    tempStr &= str[i]
		    i += 1
		end while
		if i > length(str) then
		    quit("closing '>'for a tag is missing inside <_Nclist> tag")
		else
		    i += 1
		end if
		tempStr = lower(tempStr)
		if equal(tempStr, "<p") then
		    -- <p> tag
		    if column = indent then
			writeText("\n")
		    else
			writeText("\n\n")
		    end if
		    firstCharFound = FALSE
		elsif equal(tempStr, "<br") then
		    -- <br> tag
		    writeText("\n")
		    firstCharFound = FALSE
		end if
	    else
		-- '<' is a normal literal
		word &= str[i]
		i += 1
		firstCharFound = TRUE
	    end if
	elsif whitespace(str[i]) then
	    if firstCharFound then
		writeText(" ")
	    end if
	    while i <= length(str) and whitespace(str[i]) do
		i += 1
	    end while
	else
	    word &= str[i]
	    i += 1
	    firstCharFound = TRUE
	end if
    end while
end procedure

procedure tag_rowEntry(sequence raw_text, sequence param_list, 
		       sequence str, integer colnum)
-- routine shared between 2-column, 3-column and 4-column tables. Note that
-- the parameter colnum is for the default that may be overridden by pos field
-- value. Anyway, an appropriate indentation will be computed if necessary.
    object s
    integer j
    
    -- avoid outputing an extra blank line (see the end of this routine) 
    if all_white(line) then
	resetLineAndWord()
    else
	writeText("\n")
    end if
    
    outputString(pval("name", param_list))
    writeText("")

    s = pval("pos", param_list)
    if atom(s) then
	-- take a default pos value passed as a parameter
	rememberPos = colnum
    else
	s = value(s)
	if s[1] != GET_SUCCESS then
	    quit("invalid pos information in <_Nclist>, where N is 2 to 4")
	end if
	rememberPos = s[2]
    end if
    if rememberPos < column + length(str) then
	rememberPos = column + length(str)
    end if
    writeText(repeat(' ', rememberPos - length(str) - column) & str)

    j = indent
    indent = rememberPos
    outputString(pval("description", param_list))

    -- note that next lines are NOT (writeText("\n\n") followed by indent = j)
    writeText("\n")
    -- don't forget to restore indent 
    indent = j
    -- the following extra "\n" works together with code at the beginning
    -- of this routine
    writeText("\n")
end procedure

procedure tag_4clist(sequence raw_text, sequence param_list)
-- special handler for a list entry in a 4 column table
    object temp
    
    temp = pval("col3", param_list)
    if atom(temp) then
	-- take a default column 3 value "- ". It means that this tag entry
	-- will be treated exactly same as tag_3clist.
	tag_rowEntry(raw_text, param_list, "- ", 20)
    else
	-- string value in col3 field will fill the column 3 of this row
	tag_rowEntry(raw_text, param_list, temp, 20)
    end if
end procedure

procedure tag_3clist(sequence raw_text, sequence param_list)
-- special handler for a list entry in a 3 column table
    tag_rowEntry(raw_text, param_list, "- ", 20)
end procedure

procedure tag_2clist(sequence raw_text, sequence param_list)
-- special handler for a list entry in a 2 column table
    tag_rowEntry(raw_text, param_list, " ", 15)
end procedure

procedure tag_routine(sequence raw_text, sequence param_list)
-- special handler for an entry to be centered with enclosing "---<" and 
-- ">---". This tag is used in the library.doc for each routine/function title 
-- entry.
    sequence name       -- our policy: mandatory field won't be error checked
    integer len1, len2, j
    
    name = pval("name", param_list)
    len1 = length(name) + 2 + 1  -- 2 for '<' and '>', 1 for blank first column
    len2 = floor((WIDTH - len1) / 2)
    -- temporary reset indent to the initial stage
    j = indent
    indent = 2
    writeText("\n")
    writeText(repeat('-', len2) & "<" & name & ">" & 
	      repeat('-', WIDTH - len2 - len1))
    -- restore original value of indent 
    indent = j
    writeText("\n")
end procedure

procedure tag_table(sequence raw_text, sequence param_list)
    -- prepare for <_eucode>... </_eucode>
    inTable = TRUE
end procedure
    
procedure tag_end_table(sequence raw_text, sequence param_list)
    -- prepare for <_eucode>... </_eucode>
    inTable = FALSE
end procedure
    
procedure tag_p(sequence raw_text, sequence param_list)
-- start new paragraph. Don't forget to flush out the current line, though. 
    -- if we are at the new line with no actual characters printed, no
    -- extra blank line.
    if column = indent then
	writeText("\n")
    else
	writeText("\n\n")
    end if
end procedure
    
procedure tag_br(sequence raw_text, sequence param_list)
-- start new line after flushing out the existing line
    writeText("\n")
end procedure
    
procedure tag_pre(sequence raw_text, sequence param_list)
    writeText("\n")
    inPre = TRUE
end procedure

procedure tag_end_pre(sequence raw_text, sequence param_list)
    inPre = FALSE
    getReadyNewLine()
end procedure
    
procedure tag_eucode(sequence raw_text, sequence param_list)
    if inTable and all_white(line)then
	resetLineAndWord()
	firstEucodeLine = TRUE
    else
	writeText("\n")
    end if
    inEuCode = TRUE
end procedure

procedure tag_end_eucode(sequence raw_text, sequence param_list)
    inEuCode = FALSE
    getReadyNewLine()
end procedure

procedure tag_title(sequence raw_text, sequence param_list)
    -- set inTitle flag ON
    inTitle = TRUE
end procedure

procedure tag_end_title(sequence raw_text, sequence param_list)
-- set inTitle flag OFF. Note that we should not set in_whitespace ON here.
    inTitle = FALSE
end procedure

procedure tag_center(sequence raw_text, sequence param_list)
--  writeText("")
    inCenter = TRUE
    -- for the readability, give one blank line at start
    write("\n")
end procedure

procedure tag_end_center(sequence raw_text, sequence param_list)
    inCenter = FALSE
    getReadyNewLine()
end procedure

procedure tag_ul(sequence raw_text, sequence param_list)
    ulLevel += 1
    indent += UL_INDENT

    if ulLevel = FIRST_UL_LEVEL then
	writeText("\n\n")
    else
	writeText("\n")
    end if
end procedure

procedure tag_end_ul(sequence raw_text, sequence param_list)
    writeText("") 
    ulLevel -= 1
    indent -= UL_INDENT
    getReadyNewLine()
end procedure

procedure tag_li(sequence raw_text, sequence param_list)
    indent -= 2
    if all_white(line) then
	resetLineAndWord()
	writeText("* ")
    else
	writeText("\n* ")
    end if
    -- all whitespaces before a non-whitespace char will be ignored
    indent += 2
    in_whitespace = TRUE
end procedure

procedure tag_dl(sequence raw_text, sequence param_list)
    writeText("")
    dlLevel += 1
    -- for the first level <dl>, (1) no indentation occurs and (2) one blank
    -- line is given.
    if dlLevel = FIRST_DL_LEVEL then
	rememberIndent = indent
	getReadyNewLine()
    end if
end procedure

procedure tag_end_dl(sequence raw_text, sequence param_list)
    writeText("")
    dlLevel -= 1
    -- when the <dl> level becomes zero (ie, no longer in any <dl>), we must
    -- process differently.
    if dlLevel = NOT_IN_DL then
	indent = rememberIndent
	writeText("\n\n")
    end if
end procedure

procedure tag_dt(sequence raw_text, sequence param_list)
    writeText("")
    indent = rememberIndent + (dlLevel - FIRST_DL_LEVEL) * DL_INDENT
    getReadyNewLine()
end procedure

procedure tag_dd(sequence raw_text, sequence param_list)
    writeText("")
    indent = rememberIndent + (dlLevel - FIRST_DL_LEVEL) * DL_INDENT 
	     + DL_INDENT
    getReadyNewLine()
end procedure

procedure tag_bq(sequence raw_text, sequence param_list)
    tag_literal('"', "")
end procedure

procedure tag_end_bq(sequence raw_text, sequence param_list)
    tag_literal('"', "")
end procedure

procedure tag_bsq(sequence raw_text, sequence param_list)
    tag_literal('\'', "")
end procedure

procedure tag_end_bsq(sequence raw_text, sequence param_list)
    tag_literal('\'', "")
end procedure

procedure tag_ba(sequence raw_text, sequence param_list)
    tag_literal('*', "")
end procedure

procedure tag_end_ba(sequence raw_text, sequence param_list)
    tag_literal('*', "")
end procedure

procedure tag_blockquote(sequence raw_text, sequence param_list)
    indent += BLQ_INDENT
    getReadyNewLine()
end procedure

procedure tag_end_blockquote(sequence raw_text, sequence param_list)
    indent -= BLQ_INDENT
    getReadyNewLine()
end procedure

global procedure text_init()
-- set up handlers for text output
    add_handler("!--",      routine_id("tag_comment"))
    add_handler("title",    routine_id("tag_title"))
    add_handler("/title",   routine_id("tag_end_title"))
    add_handler("blockquote",  routine_id("tag_blockquote"))
    add_handler("/blockquote", routine_id("tag_end_blockquote"))
    add_handler("pre",      routine_id("tag_pre"))
    add_handler("/pre",     routine_id("tag_end_pre"))
    add_handler("_center",  routine_id("tag_center"))
    add_handler("/_center", routine_id("tag_end_center"))
    add_handler("_bsq",     routine_id("tag_bsq"))
    add_handler("/_bsq",    routine_id("tag_end_bsq"))
    add_handler("_dul",     routine_id("tag_dul"))
    add_handler("/_dul",    routine_id("tag_end_dul"))
    add_handler("_sul",     routine_id("tag_sul"))
    add_handler("/_sul",    routine_id("tag_end_sul"))
    add_handler("_routine", routine_id("tag_routine"))
    add_handler("br",       routine_id("tag_br"))
    add_handler("_ba",      routine_id("tag_ba"))
    add_handler("/_ba",     routine_id("tag_end_ba"))
    add_handler("_bq",      routine_id("tag_bq"))
    add_handler("/_bq",     routine_id("tag_end_bq"))
    add_handler("dl",       routine_id("tag_dl"))
    add_handler("/dl",      routine_id("tag_end_dl"))
    add_handler("dt",       routine_id("tag_dt"))
    add_handler("dd",       routine_id("tag_dd"))
    add_handler("table",    routine_id("tag_table"))
    add_handler("/table",   routine_id("tag_end_table"))
    add_handler("ul",       routine_id("tag_ul"))
    add_handler("/ul",      routine_id("tag_end_ul"))
    add_handler("li",       routine_id("tag_li"))
    add_handler("_eucode",  routine_id("tag_eucode"))
    add_handler("/_eucode", routine_id("tag_end_eucode"))
    add_handler("_4clist",  routine_id("tag_4clist"))
    add_handler("_3clist",  routine_id("tag_3clist"))
    add_handler("_2clist",  routine_id("tag_2clist"))
    add_handler("p",        routine_id("tag_p"))
    add_handler("_default", routine_id("tag_default"))
    add_handler("_literal", routine_id("tag_literal"))
    out_type = "doc"
    
    in_ampersand  = FALSE
    in_whitespace = TRUE
    inTitle       = FALSE
    inCenter      = FALSE
    ulLevel       = 0
    dlLevel       = NOT_IN_DL
    dulFound      = FALSE
    sulFound      = FALSE

    indent = 2
    column = indent
    word = ""
    line = " "
end procedure

global procedure text_end()
-- flush out the line
    writeText("\n\n")
end procedure

