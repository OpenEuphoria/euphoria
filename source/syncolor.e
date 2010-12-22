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
	syncolor:set_colors({{"STRING_COLOR", string_color}})
	line = syncolor:SyntaxColor(pline, synstate)
	for i = 1 to length(line) do
		--graphics:text_color(line[i][1])
		machine_proc(9, line[i][1])
		puts(2, line[i][2])
	end for
	return 0
end function

-- just to ensure that the translator doesn't get rid of 
-- these routines...they're only called from the back end,
-- so they look unused...
if routine_id("DisplayColorLine") = -1 then
	puts(2, "error: missing FrontEnd syncolor routines\n")
end if

constant M_SET_SYNCOLOR = 21
--machine_proc(M_SET_SYNCOLOR, {routine_id("DisplayColorLine")})
