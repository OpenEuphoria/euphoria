include std/cmdline.e
include std/io.e
include std/map.e
include std/text.e
include std/console.e

constant cmd_params = {
	{ "i", 0, "Input filename", { NO_CASE, HAS_PARAMETER } },
	{ "o", 0, "Output filename", { NO_CASE, HAS_PARAMETER } }
}

map:map params = cmd_parse(cmd_params)

object input_filename=map:get(params, "i"), 
	output_filename=map:get(params, "o")

if atom(input_filename) or atom(output_filename) then
	ifdef WINDOWS and GUI then
		puts(1, "This program must be run from the command-line:\n\n")
	end ifdef
	puts(1, "Usage: eui etml.ex -i input_file -o output_file\n")
	maybe_any_key()
	abort(1)
end if

sequence in = read_file(input_filename)
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

	pos = match("%>", in, next_tag) + 2
	
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
	next_tag = match("<%", in, pos)
end while

out &= "\tresult &= \"\"\"" & in[pos..$] & "\"\"\"\n"

out &= """
	return result
end function
"""

write_file(output_filename, out)
