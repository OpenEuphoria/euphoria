--****
-- === eused.ex
--
-- A sed-like utility for Euphoria.
--
-- ==== Usage
-- 
-- {{{
-- eui eused.ex <pattern> <replacement> [input file]
-- eui eused.ex -e <pattern 1> <replacement 1> \
--     [-e <pattern n> <replacement n>...] [input file]
-- }}}
---

include std/regex.e
include std/cmdline.e
include std/map.e

sequence regexes
sequence replacements
atom in = - 1

sequence infiles = {}

constant USAGE =
`eused.ex -- a sed-like utility for euphoria
    Usage:
           eui eused.ex <pattern> <replacement> [input file]
           eui eused.ex -e <pattern 1> <replacement 1> [-e <pattern n> <replacement n>...] [input file]
`

procedure parse_regex(sequence pattern)
	regex r = regex:new(pattern)
	if not regex(r) then
		printf(2, "Error parsing regex: %s\n", { pattern })
		abort(1)
	end if
	regexes = append(regexes, r)
end procedure

procedure cmdline()
	sequence cmd = command_line()
	cmd = cmd[3 .. $]
	regexes = {}
	replacements = {}
	
	if length(cmd) < 2 then
		puts(1, USAGE)
		abort(0)
		
	elsif length(cmd) = 2 then
		in = 1
		regexes = append(regexes, regex:new(cmd[1]))
		replacements = append(replacements, cmd[2])
		return
		
	end if
	
	integer ix = 1
	while ix <= length(cmd) do
		if not length(regexes) and compare("-e", cmd[ix]) then
			parse_regex(cmd[ix])
			
		elsif equal("-e", cmd[ix]) then
			if ix = length(cmd) then
				puts(2, "Missing expression\n")
				abort(1)
			end if
			ix += 1
			parse_regex(cmd[ix])
			
			if ix = length(cmd) then
				puts(2, "Missing replacement\n")
				abort(1)
			end if
			ix += 1
			replacements = append(replacements, cmd[ix])
		else
			infiles = append(infiles, cmd[ix])
		end if
		ix += 1
	end while
end procedure

procedure process_file(atom fin)
	object in
	while sequence(in) with entry do
		for i = 1 to length(regexes) do
			in = find_replace(regexes[i], in, replacements[i])
		end for
		puts(1, in)
	entry
		in = gets(fin)
	end while
end procedure

procedure main()
	cmdline()
	
	if length(infiles) then
		for i = 1 to length(infiles) do
			process_file(open(infiles[i], "r", 1))
		end for
	else
		process_file(1)
	end if
end procedure

main()

