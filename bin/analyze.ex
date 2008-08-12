--
-- Program to parse a file and report possible include file locations
--

include euphoria/tokenize.e
include euphoria/keywords.e
include std/map.e as m
include std/eds.e
include std/search.e
include std/sequence.e
include std/filesys.e
include std/pretty.e

sequence exts = { ".e", ".eu", ".ew", ".ed"}
sequence inc_files = {}
m:map inc_funcs = m:new()

procedure usage()
	puts(1, "includes file1 [file2 file3 ...]\n")
	abort(1)
end procedure

function normalize_inc(sequence fname)
	return find_replace('\\', fname, '/')
end function

procedure add_include(sequence fname)
	sequence incs = include_paths(1)

	for a = 1 to length(incs) do
		if sequence(dir(incs[a] & SLASH & fname)) then
			sequence inc_file = find_replace('\\', incs[a] & SLASH & fname, '/')
			inc_files &= { normalize_inc(incs[a] & SLASH & fname) }
			exit
		end if
	end for
end procedure

procedure parse_include(sequence path_name, sequence item)
	sequence fname = path_name & SLASH & item
	ifdef VERBOSE then
		printf(1, "processing file %s\n", { fname })
	end ifdef

	integer keep = 0, idx = 1
	object tokens = et_tokenize_file(fname)
	tokens = tokens[1]

	while idx <= length(tokens) do
		if find(tokens[idx][TDATA], { "global", "export" }) then
			idx += 1
			if find(tokens[idx][TDATA], { "procedure", "function", "type" }) then
				idx += 1
				inc_funcs = m:put(inc_funcs, tokens[idx][TDATA], { normalize_inc(fname) }, m:CONCAT)
				ifdef VERBOSE then
					printf(1, "... item: %s\n", { tokens[idx][TDATA] })
				end ifdef
			end if
		end if
		idx += 1
	end while
end procedure

function find_includes(sequence path_name, sequence item)
	sequence fname = path_name & SLASH & item[1]

	for a = 1 to length(exts) do
		if ends(exts[a], fname) = 1 and match(".svn", fname) = 0 then
			parse_include(path_name, item[1])
			exit
		end if
	end for

	return 0
end function

procedure main(sequence args=command_line())
	if length(args) = 2 then
		usage()
	end if

	sequence paths = include_paths(1)
	for a = 1 to length(paths) do
		integer exit_code = walk_dir(paths[a], routine_id("find_includes"), 1)
	end for

	for file_idx = 3 to length(args) do
		integer ok = 1
		sequence fname = args[file_idx], locals = {}
		printf(1, "Processing file: %s\n", { fname })
		object file_tokens = et_tokenize_file(fname)
		file_tokens = file_tokens[1]

		integer a = 1
		while a <= length(file_tokens) label "top" do
			sequence tok = file_tokens[a]
			if tok[TTYPE] = T_IDENTIFIER then
				if file_tokens[a+1][TTYPE] != T_LPAREN then
					a += 1
					continue
				elsif find(tok[TDATA], builtins) then
					a += 1
					continue
				elsif find(tok[TDATA], locals) then
					a += 1
					continue
				elsif m:has(inc_funcs, tok[TDATA]) then
					sequence incs = m:get(inc_funcs, tok[TDATA], {})
					for b = 1 to length(incs) do
						if find(incs[b], inc_files) then
							a += 1
							continue "top"
						end if
					end for

					printf(1, "  %s was not included but found in:\n", { tok[TDATA] })
					sequence finds = m:get(inc_funcs, tok[TDATA], {})
					for b = 1 to length(finds) do
						printf(1, "        * %s\n", { finds[b] })
					end for

					ok = 0

					a += 1
					continue
				else
					printf(1, "  %s was not include and not found anywhere.\n", { tok[TDATA] })
				end if
			elsif tok[TTYPE] = T_KEYWORD then
				if equal(tok[TDATA], "include") then
					a += 1
					add_include(file_tokens[a][TDATA])
				elsif find(tok[TDATA], { "function", "procedure", "type" }) then
					a += 1
					locals &= { file_tokens[a][TDATA] }
				end if
			end if

			a += 1
		end while

		if ok = 1 then
			puts(1, "  ok\n")
		end if
		puts(1, "\n")
	end for
end procedure

main()
