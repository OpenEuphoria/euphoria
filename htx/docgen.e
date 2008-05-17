-- (c) Copyright 2007 Rapid Deployment Software - See License.txt

-- written by: Junko C. Miura of Rapid Deployment Software (JCMiura@aol.com)
include machine.e
include get.e
include wildcard.e
include map.e as m

global sequence current_file
global integer current_line
current_file = ""
current_line = 0

global constant SCREEN = 1
global constant TRUE = 1, FALSE = 0, EOF = -1
global sequence out_type
global integer in_file, out_file, combined_file, file_header
file_header = 0

-- .htx and .e files are pre-processed and read into this global
-- functions sequence. There, they are sorted and categorized.
global sequence functions
functions = {}

global constant FILE_NAME = 1, SECT_NUM = 2, SECTION_NAME = 3
global sequence sec_nums, sections
sec_nums = {0,0,0,0,0,0} -- h1-h6
sections = {}

global procedure quit(sequence msg)
	crash("DOC GEN ABORTED: %s\n" &
		  "Inside file: %s:%d\n", {msg, current_file, current_line})
end procedure

global function secnum_seq(sequence sec_nums)
	sequence result

	result = ""
	
	for i = 6 to 1 by -1 do
		if sec_nums[i] > 0 then
			for b = 1 to i  do
				result = append(result, sprintf("%d", {sec_nums[b]}))
			end for
			return result
		end if
	end for
	
	return {}
end function

global function secnum_tag()
	return join(secnum_seq(sec_nums), "_")
end function

global function secnum_text()
	return join(secnum_seq(sec_nums), ".") & ". "
end function

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
	if file_header = 0 then
		puts(combined_file, text)
	end if
end procedure

global procedure process_include(sequence filename)
	sequence lines, line
	object cat_name, sec_name, sec_data, func
	integer parse

	parse = 0 -- Are we reading a comment that should be parsed?
	cat_name = 0
	sec_name = 0
	sec_data = ""
	func = 0

	lines = read_lines(filename)
	for i = 1 to length(lines) do
		line = lines[i]
		if match("--**", line) then
			if parse then 
				parse = 0 
				if sequence(sec_name) and length(sec_data) > 0 then
					func = m:put(func, sec_name, sec_data)
					if equal(sec_name, "category") then
						cat_name = sec_data
					end if
				end if
				if map(func) and m:has(func, "signature") then
					functions = append(functions, func)
					func = 0
				end if
			else
				parse = 1
				func = m:new()
				sec_name = "description"
				sec_data = ""
				if sequence(cat_name) then
					func = m:put(func, "category", cat_name)
				end if
			end if
		elsif parse and match("--", line) then
			-- Trim in two calls in order to keep comments w/in examples
			-- contained in the comments. i.e.
			-- Example:
			--   a = 10 * 2
			--   -- a is 20

			line = trim(line, "-")
			line = trim(line, " \t")

			if length(line) = 0 then
				sec_data &= "\n"
			elsif line[$] = ':' then
				-- a new section
				if sequence(sec_name) and length(sec_data) > 0 then
					if equal(sec_name, "category") then
						cat_name = sec_data
					end if
					-- save old section
					func = m:put(func, sec_name, sec_data)
				end if

				sec_name = lower(line[1..$-1])
				sec_data = ""
			else
				sec_data &= line
			end if
		elsif parse and (match("global function", line) 
			             or match("global procedure", line))
		then
			sec_name = "signature"
			sec_data = trim(line, 0)
			if sec_data[$] = ')' then
				func = m:put(func, sec_name, sec_data)
				sec_name = 0
				sec_data = ""
			end if
		elsif parse and equal(sec_name, "signature") then
			-- Function signature did not fit on one line, append
			sec_data &= ' ' & trim(line, 0)
			if sec_data[$] = ')' then
				func = m:put(func, sec_name, sec_data)
				sec_name = 0
				sec_data = ""
			end if
		end if
	end for
end procedure

