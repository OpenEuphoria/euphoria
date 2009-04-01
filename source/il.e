-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Binder
-- save the Euphoria front-end data structures (IL) to disk 

-- Note: be careful not to make changes in the IL format 
-- that are not upwardly compatible. Otherwise, 
-- change the format number. (IL_VERSION)

include std/machine.e
include std/text.e
include std/filesys.e
include std/io.e
include common.e
include compress.e
include backend.e
include reswords.e
include scanner.e
include cominit.e

-- options for BIND - see also w32 in emit.e
integer list, quiet, full_debug, con
integer del_routines, del_vars
sequence user_out, icon

w32 = FALSE
list = FALSE
quiet = FALSE
full_debug = FALSE
icon = ""
con = FALSE
user_out = ""
del_routines = 0
del_vars = 0

procedure fatal(sequence msg)
-- fatal error during bind
	puts(2, msg & '\n')
	ifdef not UNIX then
		-- TODO: Should we check for batch_job?
		-- we run bind and bindw using backendw.exe, so this is needed
		puts(2, "\nPress Enter\n")
		if getc(0) then
		end if
	end ifdef

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
			fatal("Couldn't open deleted.txt")
		end if
		puts(fd, "Deleted Symbols\n")
		puts(fd, "---------------\n\n")
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
					if find(SymTab[i][S_TOKEN], {PROC, FUNC, TYPE}) then
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
							if SymTab[r][S_NREFS] < 0 then
								InternalErr("negative ref count for " & 
											 SymTab[r][S_NAME])
							end if
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
							printf(fd, "%s: %s%s\n", 
								  {file_name[SymTab[i][S_FILE_NO]], 
								   SymTab[i][S_NAME], decorate})
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
		   not equal(SymTab[i][S_NAME], "_toplevel_")) then
			-- an already deleted symbol, or a keyword or predefined symbol
			SymTab[i] = SymTab[i][S_NEXT] -- store NEXT field as an atom, 
										-- to save space
		
		elsif length(SymTab[i]) = SIZEOF_TEMP_ENTRY then
			SymTab[i] = SymTab[i][1..4]
		
		else
			if find(SymTab[i][S_TOKEN], {PROC, FUNC, TYPE}) then
				-- routine
				if not full_debug then
					SymTab[i][S_LINETAB] = 0
				end if
				SymTab[i] = SymTab[i][1..4] & {SymTab[i][S_FILE_NO], 
							SymTab[i][S_NAME], SymTab[i][S_TOKEN], 
							SymTab[i][S_CODE], SymTab[i][S_LINETAB], 
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
					-- regular variable
					if not full_debug then
						SymTab[i][S_NAME] = 0
					end if
					
					SymTab[i] = SymTab[i][1..4] & {SymTab[i][S_FILE_NO], 
								SymTab[i][S_NAME], 
								SymTab[i][S_TOKEN]} 
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
			puts(f, "#!" & eudir & SLASH & "bin" & SLASH)
			ifdef UNIX then
				puts(f, "backendu\n")
			elsedef
				puts(f, "backendw.exe\n") -- assume Apache CGI
			end ifdef
		end if
	end if
	puts(f, IL_MAGIC)
	puts(f, IL_VERSION)
end procedure

procedure OutputMisc(file f)
-- output miscellaneous variables of IL
	fcompress(f, {max_stack_per_call, AnyTimeProfile, AnyStatementProfile,
			   sample_size, gline_number, file_name})
end procedure

procedure usage()
	puts(2, "usage 1:  bind[w|u] [-full_debug] [-con] [-list] [-quiet]\n")
	puts(2, "          [-out executable_file] [-icon iconfile[.ico]] filename\n\n")
	puts(2, "usage 2:  shroud [-full_debug] [-con] [-list] [-quiet]\n") 
	fatal(  "          [-out shrouded_file] filename")
end procedure

function extract_options(sequence cl)
-- process the command line for any options 
	sequence option
	integer op

	cl &= GetDefaultArgs()
	
	if length(cl) < 3 then
		usage()
	end if
	
	op = 3
	while op <= length(cl) do
		option = upper(cl[op])
		
		if length(option) > 1 and option[1] = '-' then
			option = option[2..$]
			
			if match("SHROUD_ONLY", option) then
				shroud_only = TRUE
				cl = cl[1..op-1] & cl[op+1..$]
			
			elsif match("QUIET", option) = 1 then
				quiet = TRUE
				cl = cl[1..op-1] & cl[op+1..$]
			
			elsif match("LIST", option) = 1 then
				list = TRUE
				cl = cl[1..op-1] & cl[op+1..$]
			
			elsif match("W32", option) = 1 then
				w32 = TRUE
				cl = cl[1..op-1] & cl[op+1..$]
			
			-- do before "CON"
			elsif match("ICON", option) = 1 and op < length(cl) then
				icon = cl[op+1]
				cl = cl[1..op-1] & cl[op+2..$]
			
			elsif match("CON", option) = 1 then
				con = TRUE
				cl = cl[1..op-1] & cl[op+1..$]
				
			elsif match("FULL_DEBUG", option) then
				full_debug = TRUE
				cl = cl[1..op-1] & cl[op+1..$]
			
			elsif match("OUT", option) = 1 and op < length(cl) then
				user_out = cl[op+1]
				cl = cl[1..op-1] & cl[op+2..$]
			
			elsif match("I", option) = 1 and op < length(cl) then
				add_switch( "-i", 0 )
				add_switch( cl[op+1], 0 )
				add_include_directory( cl[op+1] )
				cl = cl[1..op-1] & cl[op+2..$]
				
			elsif match("C", option ) = 1 and op < length(cl) then
				add_switch( "-c", 0 )
				add_switch( cl[op+1], 0 )
				cl = cl[1..op-1] & load_euinc_conf( cl[op+1] ) & cl[op+2..$]
				
			else
				fatal("Invalid option: " & cl[op])
			end if
		else
			op += 1
		end if
	end while
	return cl
end function
set_extract_options( routine_id("extract_options") )

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
		fatal("seek failed!")
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
		fatal("seek failed!")
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
		out_name = file_name[1]
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
		fatal("couldn't open " & out_name & "!")
	end if

	if not shroud_only then
		-- binding:
		-- first, copy backend[w].exe
		
		eu_dir = getenv("EUDIR")
		if atom(eu_dir) then
			eu_dir = SLASH & "euphoria" -- Unix?
		end if

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
		if w32 then
			backend_name = "backendw.exe"
		else
			ifdef UNIX then
				backend_name = "backendu"
				-- try to get the installed eubackend, if it exists:
				be = open( "/usr/bin/eubackend", "r" )
			elsedef
				backend_name = "backendd.exe"
			end ifdef
		end if
		if compare( backend_name, locate_file( backend_name, { 
			eu_dir & SLASH & "bin", source_dir }
			) ) then
			backend_name = locate_file( backend_name, { 
			eu_dir & SLASH & "bin", source_dir }
			)
		end if
		if be = -1 then
			be = open(backend_name, "rb")
		end if
		if be = -1 then
			fatal("couldn't open " & backend_name & "!")
		end if
	
		-- copy backend[w].exe to output .exe file
		-- w32: replace the icon with user's icon file if any
		--      con: replace 2 with 3 in header at #DC
		last6 = repeat(' ', 6)
		size = 0
		while 1 do
			c = getc(be)
			if c = -1 then
				exit
			end if
			
			if w32 and con and size = #DC then
				puts(out, 3)
			else
				puts(out, c)
			end if
			
			size += 1
			
			if w32 and size > 55000 and length(icon) then
				-- looking for icon to replace
				last6[1..5] = last6[2..6]
				last6[6] = c
				if equal(last6, {'E', 0, 'X', 0, 'W', 0}) then
					-- found icon marker
					for i = 1 to 4 do
						puts(out, getc(be))
					end for
					-- open icon file
					if not find('.', icon) then
						icon &= ".ico"
					end if
					ic = open(icon, "rb")
					if ic = -1 then
						fatal("Couldn't open icon file: " & icon)
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
							fatal("Your custom icon file is too large.\n")
						end if
					end while
					close(ic)
				end if
			end if
		end while
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
	close(out)
	
	store_checksum(out_name)
	
	if not quiet then
		printf(1, "deleted %d unused routines and %d unused variables.\n",
				{del_routines, del_vars})
		ifdef UNIX then
			system("chmod +x " & out_name, 2)
		end ifdef
		if shroud_only then
			puts(1, "You may now use backend")
			ifdef UNIX then
				puts(1, "u")
			elsedef
				if w32 then
					puts(1, "w.exe")
				else
					puts(1, ".exe")
				end if
			end ifdef
			printf(1, " to run %s\n", {out_name})        
		else
			ifdef UNIX then
				out_name = "./" & out_name
			end ifdef
			puts(1, "You may now run " & out_name & '\n')
		end if
		-- TODO: Should this be checking batch_job?
		puts(1, "\nPress Enter\n")
		if getc(0) then
		end if
	end if
end procedure
set_output_il( routine_id("OutputIL") )
