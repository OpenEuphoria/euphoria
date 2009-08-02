include std/io.e
include std/text.e

sequence cmds = command_line()

sequence in = read_file(cmds[3])
integer next_tag, pos = 1
sequence out = """
include std/map.e as m

public function template(m:map data)
	sequence result = ""

"""

while next_tag > 0 with entry do
	if next_tag > pos then
		out &= "\tresult &= \"\"\"" & in[pos..next_tag-1] & "\"\"\"\n"
	end if

	pos = match_from("%>", in, next_tag) + 2
	
	sequence tag = trim(in[next_tag+2..pos-3])
	
	switch tag[1] do
		case '=' then
			out &= "\tresult &= m:get(data, \"" & trim(tag[2..$]) & "\")\n"
		
		case '@' then
			out = trim(tag[2..$]) & "\n" & out
			
		case else
			out &= trim(tag) & "\n"
	end switch

entry
	next_tag = match_from("<%", in, pos)
end while

out &= "\tresult &= \"\"\"" & in[pos..$] & "\"\"\"\n"

out &= """
	return result
end function
"""

write_file(cmds[4], out)
