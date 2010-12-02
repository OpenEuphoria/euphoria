-- (c) Copyright - See License.txt
-- Translator main file

with define TRANSLATOR

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

ifdef EPROFILE then
	with profile
end ifdef

include mode.e
set_mode("translate", 0 )

include traninit.e
include main.e

