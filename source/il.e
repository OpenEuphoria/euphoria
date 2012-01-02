-- (c) Copyright - See License.txt
--
-- Binder
-- save the Euphoria front-end data structures (IL) to disk

-- Note: be careful not to make changes in the IL format
-- that are not upwardly compatible. Otherwise,
-- change the format number. (IL_VERSION)

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include std/machine.e
include std/text.e
include std/filesys.e
include std/io.e
include euphoria/info.e
include std/cmdline.e
include std/map.e as m

include common.e
include compress.e
include backend.e
include reswords.e
include scanner.e
include cominit.e
include mode.e
include global.e
include pathopen.e
include error.e
include msgtext.e
include intinit.e

ifdef SHROUDER then
	constant OPTIONS = {
		{ "list",        0, GetMsgText(305, 0), { } },
		{ "full_debug",  0, GetMsgText(309, 0), { } },
		{ "out",         0, GetMsgText(310, 0), { HAS_PARAMETER, "file" }  },
		{ "i",           0, GetMsgText(311, 0), { MULTIPLE, HAS_PARAMETER, "file" }  },
		{ "c",           0, GetMsgText(280, 0), { MULTIPLE, HAS_PARAMETER, "filename" } },
		{ "d",           0, GetMsgText(282,0), { MULTIPLE, HAS_PARAMETER, "word" } },
		{ "batch",       0, GetMsgText(279,0), { } },
		{ "quiet",       0, GetMsgText(304, 0), { } },
		{ "copyright",   0, GetMsgText(312, 0), { } },
		{ "eudir",     0, GetMsgText(328,0), { HAS_PARAMETER, "dir" } },
		$
	}
elsedef
	constant OPTIONS = {
		{ "list",        0, GetMsgText(305, 0), { } },
		{ "icon",        0, GetMsgText(307, 0), { HAS_PARAMETER, "file" }  },
		{ "con",         0, GetMsgText(308, 0), { } },
		{ "full_debug",  0, GetMsgText(309, 0), { } },
		{ "out",         0, GetMsgText(310, 0), { HAS_PARAMETER, "file" }  },
		{ "i",           0, GetMsgText(311, 0), { MULTIPLE, HAS_PARAMETER, "file" }  },
		{ "c",           0, GetMsgText(280, 0), { MULTIPLE, HAS_PARAMETER, "filename" } },
		{ "d",           0, GetMsgText(282,0), { MULTIPLE, HAS_PARAMETER, "word" } },
		{ "eub",         0, GetMsgText(345,0), { HAS_PARAMETER, "backend runner" } },
		{ "batch",       0, GetMsgText(279,0), { } },
		{ "quiet",       0, GetMsgText(304, 0), { } },
		{ "copyright",   0, GetMsgText(312, 0), { } },
		{ "eudir",     0, GetMsgText(328,0), { HAS_PARAMETER, "dir" } },
		$
	}	
end ifdef

add_options( OPTIONS )

-- options for BIND
integer list, quiet, full_debug
integer del_routines, del_vars
sequence user_out, icon

list = FALSE
quiet = FALSE
full_debug = FALSE
icon = ""
con = FALSE
user_out = ""
del_routines = 0
del_vars = 0

object eub_path = 0

procedure fatal(sequence msg)
-- fatal error during bind
	puts(2, msg & '\n')
	if not batch_job and not test_only then
		ShowMsg(2, 208)
		getc(0)
	end if

	abort(1)
end procedure

procedure OutputSymTab(file f)
-- BIND only: output the Symbol Table into the IL
	boolean still_changing
	integer fd, r
	sequence reflist, decorate

	-- delete unused symbols (BIND only)

	if list then
		fd = open("deleted.txt", "w")
		if fd = -1 then
			fatal(GetMsgText(243,0))
		end if
		puts(fd, GetMsgText(244, 0))
	end if

	still_changing = TRUE

	while still_changing do
		still_changing = FALSE

		for i = length(SymTab) to 1 by -1 do
			if length(SymTab[i]) >= S_NREFS then
				-- not temp or literal or constant, and not deleted yet
				if SymTab[i][S_MODE] = M_NORMAL and
				   SymTab[i][S_NREFS] = 0 and
				   SymTab[i][S_SCOPE] > SC_PRIVATE then -- tricky to delete privates
					-- delete this symbol
					if find(SymTab[i][S_TOKEN], RTN_TOKS) then
						-- a routine
						reflist = SymTab[i][S_REFLIST]
						for j = 1 to length(reflist) do
							r = reflist[j]
							if SymTab[r][S_SCOPE] <= SC_PRIVATE then
								-- let it be deleted only if its routine is deleted
								-- otherwise we'll have execution-time problems
								SymTab[r][S_SCOPE] = SC_UNDEFINED
							end if
							SymTab[r][S_NREFS] -= 1
							ifdef DEBUG then
							if SymTab[r][S_NREFS] < 0 then
								InternalErr(264, { SymTab[r][S_NAME] })
							end if
							end ifdef

							still_changing = TRUE
						end for
						decorate = "()"
					else
						-- a variable
						decorate = ""
					end if
					if i > TopLevelSub then
						-- only report user-defined
						if list then
							printf(fd, "%s: %s%s [%d]\n",
								  {known_files[SymTab[i][S_FILE_NO]],
								   SymTab[i][S_NAME], decorate, i})
						end if

						if length(decorate) then
							del_routines += 1
						else
							del_vars += 1
						end if
					end if
					SymTab[i] = {0, SymTab[i][S_NEXT]} -- delete it
				end if
			end if
		end for
	end while

	if list then
		close(fd)
		if not quiet then
			ShowMsg(1, 245)
		end if

	end if

	-- strip down to the essential fields
	for i = 1 to length(SymTab) do
		if equal(SymTab[i][S_OBJ], NOVALUE) then
			if SymTab[i][S_MODE] != M_CONSTANT or length(SymTab[i]) >= S_NAME then
				-- only a literal NOVALUE will be retained
				SymTab[i][S_OBJ] = 0 -- saves space, will be set to C "no value"
									 -- by back end
			end if
		end if

		if length(SymTab[i]) < SIZEOF_TEMP_ENTRY or
		   (find(SymTab[i][S_SCOPE], {SC_KEYWORD, SC_PREDEF}) and
		   not equal(SymTab[i][S_NAME], "<TopLevel>")) then
			-- an already deleted symbol, or a keyword or predefined symbol
			SymTab[i] = SymTab[i][S_NEXT] -- store NEXT field as an atom,
										-- to save space

		elsif length(SymTab[i]) = SIZEOF_TEMP_ENTRY then
			SymTab[i] = SymTab[i][1..4] & SymTab[i][S_NEXT_IN_BLOCK]

		else
			if find(SymTab[i][S_TOKEN], RTN_TOKS) then
				-- routine
				if not full_debug then
					SymTab[i][S_LINETAB] = 0
				end if
				SymTab[i] = SymTab[i][1..4] & {SymTab[i][S_NEXT_IN_BLOCK],
							SymTab[i][S_FILE_NO],
							SymTab[i][S_NAME], SymTab[i][S_TOKEN],
							SymTab[i][S_CODE], SymTab[i][S_BLOCK],
							SymTab[i][S_LINETAB],
							SymTab[i][S_TEMPS],  SymTab[i][S_NUM_ARGS],
							SymTab[i][S_FIRSTLINE],
							SymTab[i][S_STACK_SPACE]}

			else
				-- variable
				-- constants are deleted (but there will be an OBJ field
				-- to hold their value at run-time)
				if SymTab[i][S_MODE] = M_CONSTANT and equal( SymTab[i][S_OBJ], NOVALUE ) then
					-- constant
					SymTab[i] = SymTab[i][S_NEXT] -- "deleted"
				else
					-- regular variable (can't delete the namespace name)
					if not full_debug  and SymTab[i][S_TOKEN] != NAMESPACE then
						SymTab[i][S_NAME] = 0
					end if

					SymTab[i] = SymTab[i][1..4] & {SymTab[i][S_NEXT_IN_BLOCK],
								SymTab[i][S_FILE_NO],
								SymTab[i][S_NAME],
								SymTab[i][S_TOKEN],{},
								SymTab[i][S_BLOCK]}
				end if
			end if

		end if
	end for
	fcompress(f, SymTab)

end procedure

procedure OutputSlist(file f)
-- write out slist, minus the source and options fields
	for i = 1 to length(slist) do
		-- remove source code field and options field (no trace/profile)
		if sequence(slist[i]) then
			slist[i] = slist[i][2..3]
		end if
	end for
	fcompress(f, slist)
end procedure

procedure OutputHeader(file f)
-- output header of IL file
	if shroud_only then
		if sequence(shebang) then
			puts(f, shebang)
		else

			ifdef UNIX then
				puts(f, "#!/usr/bin/env eub\n")
			elsedef
				puts(f, "#!" & get_eudir() & SLASH & "bin" & SLASH)
				puts(f, "eubw.exe\n") -- assume Apache CGI
			end ifdef
		end if
	end if
	puts(f, IL_MAGIC)
	puts(f, IL_VERSION)
end procedure

procedure OutputMisc(file f)
-- output miscellaneous variables of IL
	fcompress(f, {max_stack_per_call, AnyTimeProfile, AnyStatementProfile,
			   sample_size, gline_number, known_files})
end procedure

procedure copyrights()
	sequence notices = all_copyrights()
	for i = 1 to length(notices) do
		printf(2, "%s\n%s\n", notices[i])
	end for
end procedure

function extract_options( sequence cl )
	sequence argv = expand_config_options( cl )
	Argv = argv
	Argc = length(Argv)
	
	m:map opts = cmd_parse(OPTIONS, , argv)
	
	handle_options_for_bind( opts )
	finalize_command_line( opts )
	
	return argv
end function

--**
-- process the command line for any options

export procedure handle_options_for_bind( m:map opts )
	sequence option, opt_keys
	integer op
	integer file_supplied = 0

	opt_keys = m:keys(opts)
	op = 1
	while op <= length(opt_keys) do
		option = opt_keys[op]
		object val = m:get(opts, option)

		switch option do
			case "quiet" then
				quiet = TRUE

			case "list" then
				list = TRUE

			case "icon" then
				icon = val

			case "con" then
				con = TRUE

			case "full_debug" then
				full_debug = TRUE

			case "out" then
				user_out = val

			case "i"  then
				for j = 1 to length(val) do
					add_include_directory( val[j] )
				end for

			case "copyright" then
				copyrights()

			case "d" then
				OpDefines &= val

			case "batch" then
				batch_job = 1

			case cmdline:EXTRAS then
				if length(val) != 0 then
					file_supplied = 1
				end if

			case "eub" then
				eub_path = val

			case "eudir" then
				set_eudir( val )
			
			case else
				fatal(GetMsgText(314, , {option}))
		end switch

		op += 1
	end while

	if file_supplied = 0 then
		fatal(GetMsgText(313))
	end if
	
	ifdef WINDOWS then
		OpDefines &= { "GUI" }
		if con then
			OpDefines &= { "CONSOLE" }
		end if
	elsedef
		OpDefines &= { "CONSOLE" }
	end ifdef

	ifdef SHROUDER then
		shroud_only = TRUE
		OpDefines &= { "EUB_SHROUD" }
	end ifdef

	OpDefines &= { "EUB" }

end procedure

integer check_place -- place where size and checksum are stored

function base200(atom x)
-- convert a number to 4 base-200 (+32) characters
	sequence digits

	digits = {}
	for i = 1 to 4 do
		digits = append(digits, remainder(x, 200))
		x = floor(x/200)
	end for
	return digits+32
end function

procedure store_checksum(sequence backend_name)
-- write the size and checksum into the bound file
	integer c, prev_c, bound_file
	atom size
	atom checksum

	bound_file = open(backend_name, "ub") -- update mode

	if seek(bound_file, check_place+8) then
		fatal(GetMsgText(315))
	end if

	checksum = 11352 -- magic starting point
	size = 0
	prev_c = -1
	while TRUE do
		c = getc(bound_file)
		if c = -1 then
			exit
		end if
		if c < 100 then
			if c != 'A' then
				checksum += c
			end if
		else
			checksum += c*2
		end if
		size += 1
		prev_c = c
	end while

	if seek(bound_file, check_place) then
		fatal(GetMsgText(316))
	end if

	puts(bound_file, base200(size))

	checksum = remainder(checksum, 1000000000)
	puts(bound_file, base200(checksum))
end procedure

procedure OutputIL()
-- BIND only: output the IL: symbol table, code, line table, etc.
	integer out, be, m, c, ic, size
	sequence out_name, last6, backend_name, source_dir
	object eu_dir
	if length(user_out) then
		-- user has chosen the name of the output .exe file
		out_name = user_out
	else
		-- we will create the name
		out_name = known_files[1]
		m = length(out_name)
		while m > 0 do
			if out_name[m] = '.' then
				exit
			end if
			m -= 1
		end while
		if m then
			out_name= out_name[1..m-1]
		end if

		if shroud_only then
			out_name &= ".il"
		else
			ifdef not UNIX then
				out_name &= ".exe"
			end ifdef
		end if
	end if

	out = open(out_name, "wb")
	if out = -1 then
		fatal(GetMsgText(301, , {out_name}))
	end if

	if not shroud_only then
		-- binding:
		-- first, copy eub[w].exe
		if sequence( eub_path ) then
			backend_name = eub_path
			be = open( backend_name, "rb" )
		else
			eu_dir = get_eudir()

			source_dir = command_line()
			source_dir = source_dir[2]
			for j = length( source_dir ) to 1 by -1 do
				if source_dir[j] = SLASH then
					source_dir = source_dir[1..j]
					exit
				elsif j = 1 then
					source_dir = current_dir() & SLASH
				end if
			end for

			be = -1
			ifdef WINDOWS then
				if con then
					backend_name = "eub.exe"
				else
					backend_name = "eubw.exe"
				end if
			end ifdef
			ifdef UNIX then
					backend_name = "eub"
					-- try to get the installed backend, if it exists:
					be = open( "/usr/bin/eub", "r" )
					if be = -1 then
						-- try an obvious other path
						be = open( "/usr/local/bin/eub", "r" )
					end if
			end ifdef

			sequence ondisk_name = locate_file( backend_name,
										{ eu_dir & SLASH & "bin", source_dir }
										)
			ifdef UNIX then
				if not equal( backend_name,  ondisk_name) then
					backend_name = ondisk_name
				end if
			elsedef
				-- do case-insensitive check on WIN
				if not equal( lower(backend_name),  lower(ondisk_name)) then
					backend_name = ondisk_name
				end if
			end ifdef
		end if

		if be = -1 then
			be = open(backend_name, "rb")
		end if
		if be = -1 then
			fatal(GetMsgText(301, , {backend_name}))
		end if

		-- copy eub to output file
		size = 0
		ifdef UNIX then
			while 1 do
				c = getc(be)
				if c = -1 then
					exit
				end if
				puts(out, c)
			end while
		end ifdef

		ifdef WINDOWS then
			last6 = repeat(' ', 6)
			while 1 do
				c = getc(be)
				if c = -1 then
					exit
				end if

 				puts(out, c)

				size += 1

				if size > 55000 and length(icon) then
					-- looking for icon to replace
					last6[1..5] = last6[2..6]
					last6[6] = c
					if equal(last6, {'E', 0, 'X', 0, 'W', 0}) then
						-- found icon marker

						-- open icon file
						if not find('.', icon) then
							icon &= ".ico"
						end if
						ic = open(icon, "rb")
						if ic = -1 then
							fatal(GetMsgText(301,, {icon}))
						end if
						-- skip icon file header
						for i = 1 to 22 do
							c = getc(ic)
						end for
						-- insert the custom icon file
						while TRUE do
							c = getc(ic)
							if c = -1 then
								size = 0 -- don't bother looking anymore
								exit
							end if
							puts(out, c)

							c = getc(be) -- skip over our icon
							if c = -1 then
								fatal(GetMsgText(318))
							end if
						end while
						close(ic)
					end if
				end if
			end while
		end ifdef
		close(be)

		-- add marker in .exe
		puts(out, '\n' & IL_START)
	end if

	OutputHeader(out)

	check_place = where(out)
	-- reserve space for size
	puts(out, {0,0,0,0})
	-- reserve space for checksum
	puts(out, {0,0,0,0})

	init_compress()
	OutputMisc(out)
	OutputSymTab(out)
	OutputSlist(out)
	fcompress( out, file_include )
	fcompress( out, get_switches() )
	fcompress( out, include_matrix )
	close(out)

	store_checksum(out_name)

	if not quiet then
		ShowMsg(1, 248, {del_routines, del_vars})
		ifdef UNIX then
			system("chmod +x " & out_name, 2)
		end ifdef

		if shroud_only then
			sequence filename = "eub"
			ifdef WINDOWS then
				if con then
					filename &= ".exe"
				else
					filename &= "w.exe"
				end if
			end ifdef
			ShowMsg(1, 246, {filename, out_name})
		else
			ifdef UNIX then
				out_name = "./" & out_name
			end ifdef

			ShowMsg(1, 247, {out_name})
		end if
	end if
end procedure
set_output_il( routine_id("OutputIL") )
set_extract_options( routine_id("extract_options") )

