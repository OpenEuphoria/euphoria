-- (c) Copyright - See License.txt
--****
-- == error.e: Compile-time Error Handling
ifdef ETYPE_CHECK then
with type_check
elsedef
without type_check
end ifdef

include std/io.e
include std/text.e

include global.e
include reswords.e
include msgtext.e

integer Errors = 0 -- number of errors detected during compile

export integer TempErrFile = -2
export sequence TempErrName
export integer display_warnings
export object ThisLine = ""   -- current line of source (or -1)
export object ForwardLine     -- remember the line when a possible forward reference occurs
export integer bp = 0         -- input line index of next character
export integer forward_bp     -- cached line index for a possible forward reference   
export sequence warning_list = {}

--**
-- output messages to the screen or a file
export procedure screen_output(integer f, sequence msg)
	puts(f, msg)
end procedure

--**
-- add a warning message to the list
export procedure Warning(object msg, integer mask, sequence args = {})
	integer p
	sequence text, w_name

	if display_warnings=0 then
		return
	end if
	if not Strict_is_on or Strict_Override then
		if find(mask, strict_only_warnings) then
			return
		end if
	end if
	
	p = mask -- =0 for non maskable warnings - none implemented so far
	if Strict_is_on and Strict_Override = 0 then
		mask = 0
	end if

	if mask = 0 or and_bits(OpWarning, mask) then
		if p then
			p = find(p,warning_flags)
		end if

		if p then
			w_name = "( " & warning_names[p] & " )"
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
export function ShowWarnings(integer errfile)
	integer c

	if errfile=0 then
		if display_warnings = 0 then
			return length(warning_list)
		end if

		if integer(TempWarningName) then
			errfile = STDERR
		else
			errfile = open(TempWarningName,"w")
			if errfile = -1 then
				ShowMsg(STDERR, 205, {TempWarningName})
				return length(warning_list)
			end if
		end if
	else
		errfile = STDERR
	end if

	for i = 1 to length(warning_list) do
		if errfile = STDERR then
			screen_output(STDERR, warning_list[i])
			if remainder(i, 20) = 0 and batch_job = 0 then
				ShowMsg(STDERR, 206)
				c = getc(0)
				if c = 'q' then
					exit
				end if
			end if
		else
			puts(errfile, warning_list[i])
		end if
	end for

	if errfile > STDERR then
	    close(errfile)
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

	ifdef WIN32 or UNIX then
		show_error = 1
	end ifdef

	w = ShowWarnings(status)
	if not TRANSLATE and (BIND or show_error) and (w or Errors) then
		if not batch_job then
			screen_output(STDERR, GetMsgText(208,0))
			getc(0) -- wait
		end if
	end if

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
		abort(1) --Cleanup(1)
	end if
end procedure

--**
-- Show place where syntax error occurred
procedure ShowErr(integer f)
	if length(file_name) = 0 then
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
export procedure CompileErr(object msg, object args = {})
	sequence errmsg

	if integer(msg) then
		msg = GetMsgText(msg)
	end if
	
	msg = format(msg, args)
	
	Errors += 1
	if length(file_name) then
		errmsg = sprintf("%s:%d\n%s\n", {file_name[current_file_no],
					 line_number, msg})
	else
		errmsg = msg
		if length(msg) > 0 and msg[$] != '\n' then
			errmsg &= '\n'
		end if
	end if

	-- try to open err file *before* displaying diagnostics on screen
	OpenErrFile() -- exits if error filename is ""
	screen_output(STDERR, errmsg)
	ShowErr(STDERR)

	puts(TempErrFile, errmsg)

	ShowErr(TempErrFile)

	ShowWarnings(TempErrFile)

	ShowDefines(TempErrFile)
	
	close(TempErrFile)
	Cleanup(1)
end procedure

--**
-- report feature not supported
procedure not_supported_compile(sequence feature)
	CompileErr(5, {feature, version_name})
end procedure

--**
-- Handles internal compile-time errors
-- see RTInternal() for run-time internal errors
export procedure InternalErr(integer  msgno, object args = {})

	sequence msg
	if atom(args) then
		args = {args}
	end if
	
	msg = GetMsgText(msgno, 1, args)
	if TRANSLATE then
		screen_output(STDERR, GetMsgText(211, 1, {msg}))
	else
		screen_output(STDERR, GetMsgText(212, 1, {file_name[current_file_no], line_number, msg}))
	end if

	if not batch_job then
		screen_output(STDERR, GetMsgText(208, 0))
		getc(0)
	end if
	
    -- M_CRASH = 67
	machine_proc(67, GetMsgText(213))
end procedure

