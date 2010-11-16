--** 
-- Literate Programming for Euphoria
-- 
-- http://www.literateprogramming.com/
-- 

include std/cmdline.e
include std/io.e
include std/map.e
include std/console.e

constant 
	BEGIN_TAG = "<eucode>",
	END_TAG = "</eucode>"

constant cmd_params = {
	{ "i", 0, "Input filename", { NO_CASE, HAS_PARAMETER } },
	{ "o", 0, "Output filename", { NO_CASE, HAS_PARAMETER } }
}

map:map params = cmd_parse(cmd_params)

object input_filename=map:get(params, "i"), 
	output_filename=map:get(params, "o")

if atom(input_filename) or atom(output_filename) then
	ifdef WIN32_GUI then
	    puts(1, "This program must be run from the command-line:\n\n")
	end ifdef
	puts(1, "Usage: eui literate.ex -i input_file -o output_file\n")
	maybe_any_key()
	abort(1)
end if

sequence in = read_file(input_filename)
integer next_tag, pos = 1
sequence out = ""

while next_tag > 0 with entry do
	if next_tag > pos then
		out &= "/*\n" & in[pos..next_tag-1] & "*/\n"
	end if

	pos = match(END_TAG, in, next_tag) + length(END_TAG) 

	out &= in[next_tag + length(BEGIN_TAG)..pos - length(END_TAG) - 1] & "\n"
entry
	next_tag = match(BEGIN_TAG, in, pos)
end while

out &= "/*\n" & in[pos..$] & "\n*/\n"

write_file(output_filename, out)
