-- (c) Copyright - See License.txt
--
--****
-- == error.e: Compile-time Error Handling

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

ifdef CRASH_ON_ERROR then
	include std/error.e
end ifdef

include std/io.e
include std/text.e

include global.e
include reswords.e
include msgtext.e
include coverage.e
include scanner.e

integer Errors = 0 -- number of errors detected during compile

export integer TempErrFile = -2
export sequence TempErrName
export integer display_warnings
export object ThisLine = ""             -- current line of source (or -1)
export object ForwardLine = ""          -- remember the line when a possible forward reference occurs
export object putback_ForwardLine = ""  -- remember the line when a possible forward reference occurs
export object last_ForwardLine = ""     -- remember the line when a possible forward reference occurs
export integer bp = 0                   -- input line index of next character
export integer forward_bp = 0           -- cached line index for a possible forward reference
export integer putback_forward_bp = 0   -- cached line index for a possible forward reference
export integer last_forward_bp = 0      -- cached line index for a possible forward reference
export sequence warning_list = {}

--**
-- output messages to the screen or a file

export procedure screen_output(integer f, sequence msg)
	puts(f, msg)
end procedure

--**
-- add a warning message to the list

export procedure Warning(object msg, integer mask, sequence args = {})
	integer orig_mask
	sequence text, w_name

	if display_warnings = 0 then
		return
	end if
	
	if not Strict_is_on or Strict_Override then
		if find(mask, strict_only_warnings) then
			return
		end if
	end if

	orig_mask = mask -- =0 for non maskable warnings - none implemented so far
	if Strict_is_on and Strict_Override = 0 then
		mask = 0
	end if

	if mask = 0 or and_bits(OpWarning, mask) then
		if orig_mask != 0 then
			orig_mask = find(orig_mask,warning_flags)
		end if

		if orig_mask != 0 then
			w_name = "{ " & warning_names[orig_mask] & " }"
		else
			w_name = "" -- not maskable
		end if

		if atom(msg) then
			msg = GetMsgText(msg, 1, args)
		end if
		
		text = GetMsgText(204, 0, {w_name, msg})
		if find(text, warning_list) then
			return -- duplicate
		end if

		warning_list = append(warning_list, text)
	end if
end procedure

export procedure Log_warnings(object policy)
	display_warnings = 1

	if sequence(policy) then
		if length(policy)=0 then
			policy = STDERR
		end if
	else
		if policy >= 0 and policy < STDERR+1 then
			policy  = STDERR
		elsif policy < 0 then
			display_warnings = 0
		end if
	end if
end procedure

--**
-- print the warnings to the screen (or ex.err)

export function ShowWarnings()
	integer c
	integer errfile
	integer twf

	if display_warnings = 0 or length(warning_list) = 0 then
		return length(warning_list)
	end if

	if TempErrFile > 0 then
		errfile = TempErrFile
	else
		errfile = STDERR
	end if

	if not integer(TempWarningName) then
		twf = open(TempWarningName,"w")
		if twf = -1 then
			ShowMsg(errfile, 205, {TempWarningName})
			if errfile != STDERR then
				ShowMsg(STDERR, 205, {TempWarningName})
			end if
		else
			for i = 1 to length(warning_list) do
				puts(twf, warning_list[i])
			end for
		    close(twf)
		end if
		TempWarningName = 99 -- Flag that we have done this already.
	end if

	if batch_job = 0 or errfile != STDERR then
		for i = 1 to length(warning_list) do
			puts(errfile, warning_list[i])
			if errfile = STDERR then
				if remainder(i, 20) = 0 and batch_job = 0 and test_only = 0 then
					ShowMsg(errfile, 206)
					c = getc(0)
					if c = 'q' then
						exit
					end if
				end if
			end if
		end for
	end if

	return length(warning_list)
end function

export procedure ShowDefines(integer errfile)
	integer c

	if errfile=0 then
		errfile = STDERR
	end if

	puts(errfile, format("\n--- [1] ---\n", {GetMsgText(207,0)}))

	for i = 1 to length(OpDefines) do
		if find(OpDefines[i], {"_PLAT_START", "_PLAT_STOP"}) = 0 then
			printf(errfile, "%s\n", {OpDefines[i]})
		end if
	end for
	puts(errfile, "-------------------\n")

end procedure

--**
-- clean things up before quitting
export procedure Cleanup(integer status)
	integer w, show_error = 0

	ifdef EU_EX then
		-- normally the backend calls this, but execute.e needs us to call
		-- it here:
		write_coverage_db()
	end ifdef
	
	show_error = 1

	-- Sometimes (such as in the pre-processor), Cleanup can be called when
	-- src_file has not been assigned a value. object() will return 0 if the
	-- variable has never been assigned.

	if object(src_file) = 0 then
		src_file = -1
	elsif src_file >= 0 and (src_file != repl_file or not repl) then
		close(src_file)
		src_file = -1
	end if
	
	w = ShowWarnings()
	if not TRANSLATE and (BIND or show_error) and (w or Errors) then
		if not batch_job and not test_only then
			screen_output(STDERR, GetMsgText(208,0))
			getc(0) -- wait
		end if
	end if

	-- Close all files now.	
	cleanup_open_includes()
	abort(status)
end procedure

--**
-- open the error diagnostics file - normally "ex.err"
export procedure OpenErrFile()
    if TempErrFile != -1 then
		TempErrFile = open(TempErrName, "w")
	end if

	if TempErrFile = -1 then
		if length(TempErrName) > 0 then
			screen_output(STDERR, GetMsgText(209, 0, {TempErrName}))
		end if
		abort(1) -- with no clean up
	end if
end procedure

--**
-- Show place where syntax error occurred
procedure ShowErr(integer f)
	if length(known_files) = 0 then
		return
	end if

	if ThisLine[1] = END_OF_FILE_CHAR then
		screen_output(f, GetMsgText(210,0))
	else
		screen_output(f, ThisLine)
	end if

	for i = 1 to bp-2 do -- bp-1 points to last character read
		if ThisLine[i] = '\t' then
			screen_output(f, "\t")
		else
			screen_output(f, " ")
		end if
	end for

	screen_output(f, "^\n\n")
end procedure

--**
-- Handle fatal compilation errors
export procedure CompileErr(object msg, object args = {}, integer preproc = 0 )
	sequence errmsg

	if integer(msg) then
		msg = GetMsgText(msg)
	end if

	msg = format(msg, args)

	Errors += 1
	if not preproc and length(known_files) then
		errmsg = sprintf("%s:%d\n%s\n", {known_files[current_file_no],
					 line_number, msg})
	else
		errmsg = msg
		if length(msg) > 0 and msg[$] != '\n' then
			errmsg &= '\n'
		end if
	end if
	
	if not preproc then
		-- try to open err file *before* displaying diagnostics on screen
		OpenErrFile() -- exits if error filename is ""
	end if
	screen_output(STDERR, errmsg)
	
	if not preproc then
		ShowErr(STDERR)

		puts(TempErrFile, errmsg)

		ShowErr(TempErrFile)

		ShowWarnings()

		ShowDefines(TempErrFile)

		close(TempErrFile)
		TempErrFile = -2
		ifdef CRASH_ON_ERROR then
			crash("Crashing on compiler error for internal traceback")
		end ifdef
		Cleanup(1)
	end if
	
end procedure

--**
-- report feature not supported
procedure not_supported_compile(sequence feature)
	CompileErr(5, {feature, version_name})
end procedure

--**
-- Handles internal compile-time errors
-- see RTInternal() for run-time internal errors
export procedure InternalErr(object  msgno, object args = {})

	sequence msg
	if atom(args) then
		args = {args}
	end if
	
	if atom( msgno ) then
		msg = GetMsgText(msgno, 1, args)
	else
		msg = format(msgno, args)
	end if
	
	if TRANSLATE then
		screen_output(STDERR, GetMsgText(211, 1, {msg}))
	else
		screen_output(STDERR, GetMsgText(212, 1, {known_files[current_file_no], line_number, msg}))
	end if

	if not batch_job and not test_only then
		screen_output(STDERR, GetMsgText(208, 0))
		getc(0)
	end if

    -- M_CRASH = 67
	machine_proc(67, GetMsgText(213))
end procedure

