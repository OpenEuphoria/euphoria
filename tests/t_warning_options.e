include std/unittest.e
include std/io.e
include std/filesys.e
include std/os.e
include std/regex.e as regex
include std/sequence.e
include std/sort.e
include std/utils.e
include std/text.e

constant warnings_issued = "warnings_issued.txt"
constant nul = iif(platform() = WINDOWS,"NUL","/dev/null")

constant warn_regex = regex:new("Warning +{ *([a-z_]+) *}:")

function warning_parse(sequence file_name)
    sequence warnings = {}
    integer fn = open(file_name, "r")
    object line
    while sequence(line) with entry do
        object results = regex:find(warn_regex, line)
        if sequence(results) then
            sequence warning_string = line[results[2][1]..results[2][2]]
            warnings = append(warnings, warning_string)
        end if
    entry
        line = gets(fn)
    end while
    warnings = sort(warnings)
    integer i = 1
    while i < length(warnings) do
        if equal(warnings[i], warnings[i+1]) then
            warnings = remove(warnings, i)
            continue
        end if
        i += 1
    end while
    return warnings
end function

constant cl = command_line()
constant eui = cl[1]

enum M_NORMAL=0, M_STRICT=1

enum M_ALL=1, M_DEFAULT=3, M_NONE=5   

enum P_NAME, P_PARAM, P_WARNINGS

constant 
       configs = { 
       -- M_ALL
       {"all", "-w all", sort({"resolution", "short_circuit", "translator", "override", "builtin_chosen", "not_used", "no_value", "custom", "not_reached", "mixed_profile", "empty_case", "default_case"})},
       -- M_ALL + M_STRICT
       {"all+strict", "-w all -strict", sort({"resolution", "short_circuit", "translator", "override", "builtin_chosen", "not_used", "no_value", "custom", "not_reached", "mixed_profile", "empty_case", "default_case"})},
       -- M_DEFAULT,
       {"normal", "", sort({"resolution", "override", "translator", "builtin_chosen", "custom", "not_reached", "mixed_profile"})},
       -- M_DEFAULT + M_STRICT
       {"strict", "-strict", sort({"resolution", "short_circuit", "translator", "override", "builtin_chosen", "not_used", "no_value", "custom", "not_reached", "mixed_profile", "empty_case", "default_case"})},
       -- M_NONE
       {"none", "-x all", {}},
       -- M_NONE + M_STRICT
       {"none+strict", "-x all -strict", sort({"resolution", "short_circuit", "translator", "override", "builtin_chosen", "not_used", "no_value", "custom", "not_reached", "mixed_profile", "empty_case", "default_case"})}
       }
       
       
       
ifdef EUI then
        if find(match("eui", lower(eui)), length(eui)-{2,6}) = 0 then
            test_fail("Interpreter could not be determined.")
        end if
        for j = 1 to length(configs) do
            sequence config = configs[j]
            sequence cwf = config[P_WARNINGS]

	    sequence cmd = eui & ' ' & config[P_PARAM] & " -test -batch -wf " & warnings_issued & " t_warning_options.d" & SLASH & "make_warnings.ex > " & nul
        delete_file(warnings_issued)
	    system(cmd,2)
	    sequence wf = {}
		if file_exists(warnings_issued) > 0 then
			wf = warning_parse(warnings_issued)
        end if
        integer ti  = find("translator", wf)
        if ti then
            wf = remove(wf, ti)
        end if
        ti = find("translator", cwf)
        if ti then
            cwf = remove(cwf, ti)
        end if
        
        ifdef LINUX then
            -- impossible on Linux because with profile_time is an error            
            integer xpi = find("mixed_profile", cwf)
            if xpi then
                cwf = remove(cwf, xpi)
            end if
        end ifdef

        for c = 1 to length(cwf) do
            test_true(config[P_NAME] & " warning enabled: " & cwf[c], find(cwf[c], wf) != 0)
        end for
        for c = 1 to length(cwf) do
            integer t = find(cwf[c], wf)
            wf = remove(wf, t)
        end for
        for t = 1 to length(wf) do
            test_false(config[P_NAME] & " warning enabled: " & wf[t], 1)
        end for
	end for -- j

	-- avoid confusion of eutest
	delete_file("ex.err")
end ifdef
test_report()
