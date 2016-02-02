include std/unittest.e
include std/io.e
include std/filesys.e
include std/os.e

with warning
with warning&= {none}
with warning &={resolution}
with warning&={short_circuit}
with warning &= {override}
with warning &= {builtin_chosen}
with warning &= {not_used}
with warning &= {no_value}
with warning &= {custom}
with warning &= {translator}
with warning &= {cmdline}
with warning &= {not_reached}
with warning &= {mixed_profile}
with warning &= {empty_case}
with warning &= {default_case}
with warning &= {all}

with warning &= {none, resolution, short_circuit, override, builtin_chosen, 
                 not_used,no_value, custom, translator, cmdline, not_reached
                 , mixed_profile, empty_case
                 ,
                 default_case, all}

with warning+= {none}
with warning +={resolution}
with warning+={short_circuit}
with warning += {override}
with warning += {builtin_chosen}
with warning += {not_used}
with warning += {no_value}
with warning += {custom}
with warning += {translator}
with warning += {cmdline}
with warning += {not_reached}
with warning += {mixed_profile}
with warning += {empty_case}
with warning += {default_case}
with warning += {all}

without warning
without warning&= {none}
without warning &={resolution}
without warning&={short_circuit}
without warning &= {override}
without warning &= {builtin_chosen}
without warning &= {not_used}
without warning &= {no_value}
without warning &= {custom}
without warning &= {translator}
without warning &= {cmdline}
without warning &= {not_reached}
without warning &= {mixed_profile}
without warning &= {empty_case}
without warning &= {default_case}
without warning &= {all}
without warning &= {none, resolution, short_circuit, override, builtin_chosen, 
                 not_used,no_value, custom, translator, cmdline, not_reached
                 , mixed_profile, empty_case
                 ,
                 default_case, all}

without warning+= {none}
without warning +={resolution}
without warning+={short_circuit}
without warning += {override}
without warning += {builtin_chosen}
without warning += {not_used}
without warning += {no_value}
without warning += {custom}
without warning += {translator}
without warning += {cmdline}
without warning += {not_reached}
without warning += {mixed_profile}
without warning += {empty_case}
without warning += {default_case}
without warning += {all}

with warning= {none}
with warning ={resolution}
with warning={short_circuit}
with warning = {override}
with warning = {builtin_chosen}
with warning = {not_used}
with warning = {no_value}
with warning = {custom}
with warning = {translator}
with warning = {cmdline}
with warning = {not_reached}
with warning = {mixed_profile}
with warning = {empty_case}
with warning = {default_case}
with warning = {all}
with warning = {none, resolution, short_circuit, override, builtin_chosen, 
                 not_used,no_value, custom, translator, cmdline, not_reached
                 , mixed_profile, empty_case
                 ,
                 default_case, all}

without warning= {none}
without warning ={resolution}
without warning={short_circuit}
without warning = {override}
without warning = {builtin_chosen}
without warning = {not_used}
without warning = {no_value}
without warning = {custom}
without warning = {translator}
without warning = {cmdline}
without warning = {not_reached}
without warning = {mixed_profile}
without warning = {empty_case}
without warning = {default_case}
without warning = {all}

without warning = {none, resolution, short_circuit, override, builtin_chosen, 
                 not_used,no_value, custom, translator, cmdline, not_reached
                 , mixed_profile, empty_case
                 ,
                 default_case, all}
with warning save
with warning restore
with warning strict

without warning save
without warning restore
without warning strict
constant warnings_issued = "warnings_issued.txt"

test_pass("Warning syntax")
sequence nul = "NUL"
ifdef UNIX then
	nul = "/dev/null"
end ifdef

constant answers = { "TTTTFT", "TTTTTT" } = 'T'
constant questions = {
{"File wide variables that are used but never assigned a value are warned about", 
	"module variable \'i5\' is never assigned a value"}, -- 226
{"Private variables of routines that are used but never assigned a value are warned about", 
	"private variable \'i4\' of p1 is never assigned a value"}, -- 227
{"File wide constants that are not used are warned about", "module constant \'a6\' is not used"}, -- 228
{"File wide variables that are not used are warned about", "module variable \'i1\' is not used"}, -- 229
{"Parameters of routines that are not used are warned about", "parameter \'i2\' of p1() is not used"}, -- 230
{"Private variables of routines that are never used are warned about", "private variable \'i3\' of p1() is not used"} -- 231
}
constant cl = command_line()
constant eui = cl[1]
ifdef EUI then
	for j = 1 to 2 do
		sequence cmd, decoration, strict
		if j = 1 then
			strict = ""
			decoration = "normal: "
		else
			strict = " -strict"
			decoration = "strict: "
		end if
		cmd = eui & strict & " -batch warning_code.ex > " & nul
		delete_file(warnings_issued)
		system(cmd,2)
		if file_exists(warnings_issued) = 0 then
			test_fail("warning behavior")
		else
			sequence wf = read_file(warnings_issued)
			for i = 1 to length(questions) do
				test_equal(decoration & questions[i][1], 
					answers[j][i], match(questions[i][2], wf) != 0 )
			end for
		end if
	end for -- j

	-- avoid confusion of eutest
	delete_file("ex.err")
end ifdef
test_report()
