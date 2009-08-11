-- (c) Copyright - See License.txt
-- Translator main file

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include mode.e
set_mode("translate", 0 )

include traninit.e
include main.e

