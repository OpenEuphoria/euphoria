-- (c) Copyright - See License.txt
--
ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include euphoria/syncolor.e

atom synstate = syncolor:new()

public function DisplayColorLine(sequence pline, integer string_color)
	sequence line
	syncolor:set_colors({{"STRING", string_color}})
	line = syncolor:SyntaxColor(pline, synstate)
	for i = 1 to length(line) do
		--graphics:text_color(line[i][1])
		machine_proc(9, line[i][1])
		puts(2, line[i][2]&"\n")
	end for
	return 0
end function
