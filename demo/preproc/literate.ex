--** 
-- Literate Programming for Euphoria
-- 
-- http://www.literateprogramming.com/
-- 

include std/io.e

constant 
	BEGIN_TAG = "<eucode>",
	END_TAG = "</eucode>"

sequence cmds = command_line()

sequence in = read_file(cmds[3])
integer next_tag, pos = 1
sequence out = ""

while next_tag > 0 with entry do
	if next_tag > pos then
		out &= "/*\n" & in[pos..next_tag-1] & "*/\n"
	end if

	pos = match_from(END_TAG, in, next_tag) + length(END_TAG) 

	out &= in[next_tag + length(BEGIN_TAG)..pos - length(END_TAG) - 1] & "\n"
entry
	next_tag = match_from(BEGIN_TAG, in, pos)
end while

out &= "/*\n" & in[pos..$] & "\n*/\n"

write_file(cmds[4], out)
