-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- Compile-time Error Handling

include io.e
include global.e
include reswords.e

integer Errors
Errors = 0   -- number of errors detected during compile 

global integer TempErrFile
global sequence TempErrName
global integer display_warnings
global object ThisLine        -- current line of source (or -1)
global integer bp             -- input line index of next character 

global sequence warning_list
warning_list = {}

global procedure screen_output(integer f, sequence msg)
-- output messages to the screen or a file    
	puts(f, msg)
end procedure

global procedure Warning(sequence msg, integer mask, sequence args = {})
-- add a warning message to the list
	integer p
	sequence text, w_name

	if display_warnings=0 then
		return
	end if

	if Lint_is_on then
		mask = 0
	end if

	if mask = 0 or and_bits(OpWarning, mask) then
		p = mask -- =0 for non maskable warnings - none implemented so far
		if p then
			p = find(mask,warning_flags)
		end if

		if p then
			w_name = warning_names[p]
		else
			w_name = "< not named >"
		end if
		if length(args) then
			msg = sprintf(msg,args)
		end if

		text = sprintf("Warning ( %s ):\n\t%s\n", {w_name,msg})
		if find(text, warning_list) then
			return -- duplicate
		end if
		warning_list = append(warning_list, text)
	end if
end procedure

global procedure Log_warnings(object policy)
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

global function ShowWarnings(integer errfile)
-- print the warnings to the screen (or ex.err)
	integer c,last_change, fn

	if errfile=0 then
		if display_warnings = 0 then
			return length(warning_list)
		end if
		if integer(TempWarningName) then
			errfile = STDERR
		else
			errfile = open(TempWarningName,"w")
			if errfile = -1 then
				puts(STDERR,"\nUnable to create warning file " & TempWarningName&'\n')
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
				puts(STDERR, "\nPress Enter to continue, q to quit\n\n")
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

global procedure Cleanup(integer status)
-- clean things up before quitting
	integer w
	
	w = ShowWarnings(status)
	
	if not TRANSLATE and (BIND or EWINDOWS or EUNIX) and (w or Errors) then
		if not batch_job then
			screen_output(STDERR, "\nPress Enter\n")
			if getc(0) then -- prompt
			end if
		end if
	end if
	
	abort(status)
end procedure

global procedure OpenErrFile()
-- open the error diagnostics file - normally "ex.err"
	TempErrFile = open(TempErrName, "w")
	if TempErrFile = -1 then
		if length(TempErrName) > 0 then
			screen_output(STDERR, "Can't create error message file: ")
			screen_output(STDERR, TempErrName)
			screen_output(STDERR, "\n")
		end if
		abort(1) --Cleanup(1)
	end if
end procedure

procedure ShowErr(integer f)
-- Show place where syntax error occurred  
	if length(file_name) = 0 then
		return
	end if
	if ThisLine[1] = END_OF_FILE_CHAR then
		screen_output(f, "<end-of-file>\n")
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

global procedure CompileErr(sequence msg)
-- Handle fatal compilation errors 
	sequence errmsg
	
	Errors += 1
	if length(file_name) then
		errmsg = sprintf("%s:%d\n%s\n", {file_name[current_file_no], 
					 line_number, msg})
	else
		errmsg = msg
	end if
		-- try to open err file *before* displaying diagnostics on screen
	OpenErrFile() -- exits if error filename is ""
	screen_output(STDERR, errmsg)
	ShowErr(STDERR)
	
	puts(TempErrFile, errmsg) 
	
	ShowErr(TempErrFile) 
	
	if ShowWarnings(TempErrFile) then
	end if
	
	puts(TempErrFile, "\n")
	
	close(TempErrFile)
	Cleanup(1)
end procedure

procedure not_supported_compile(sequence feature)
-- report feature not supported
	CompileErr(sprintf("%s is not supported in Euphoria for %s", 
					   {feature, version_name}))
end procedure

global procedure InternalErr(sequence msg)
-- Handles internal compile-time errors
-- see RTInternal() for run-time internal errors
	if TRANSLATE then
		screen_output(STDERR, sprintf("Internal Error: %s\n", {msg}))
	else
		screen_output(STDERR, sprintf("Internal Error at %s:%d - %s\n", 
		   {file_name[current_file_no], line_number, msg}))
	end if
	
	if batch_job = 0 then
		screen_output(STDERR, "\nPress Enter\n")
		if getc(0) then
		end if
	end if
	? 1/0
	--abort(1)
end procedure
