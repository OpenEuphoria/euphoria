-- datesub.ex
include std/cmdline.e  -- command line parsing 
include std/datetime.e -- now() and format()
include std/io.e       -- read_file() and write_file()
include std/map.e      -- map accessor functions (get())
include std/search.e   -- find_replace()

sequence cmdopts = {
    { "f", 0, "Date format", { NO_CASE, HAS_PARAMETER, "format" } }
}

public function preprocess(sequence inFileName, sequence outFileName,
        sequence options={})
	map opts = cmd_parse(cmdopts, {}, {0,0} & parse_commandline(options))
    sequence content = read_file(inFileName)

    content = find_replace("@DATE@", content, format(now(), map:get(opts, "f")))

    write_file(outFileName, content)
    
    return 0
end function

ifdef not EUC_DLL then
	sequence c = {
        { "i", 0, "Input filename", { NO_CASE, MANDATORY, HAS_PARAMETER, "filename"} },
        { "o", 0, "Output filename", { NO_CASE, MANDATORY, HAS_PARAMETER, "filename"} }
	} & cmdopts
	
    map opts = cmd_parse(c)
    preprocess(map:get(opts, "i"), map:get(opts, "o"),
 		"-f " & map:get(opts, "f", "%Y-%m-%d"))
end ifdef
