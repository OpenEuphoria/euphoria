-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.1
-- The Interpreter Back-End

-- This back-end is written in Euphoria. It uses the same front-end
-- as the official RDS Euphoria interpreter, and it executes the same IL
-- opcodes. Because it's written in Euphoria, this back-end is very 
-- simple. Much simpler than the back-end used in the official RDS interpreter. 

-- Using the Euphoria to C Translator, or the Binder, you can convert 
-- this 100% Euphoria-coded interpreter into a .exe. The Translator 
-- will boost its speed considerably, though it will still be slower 
-- than the official RDS interpreter. The official interpreter has a 
-- carefully hand-coded back-end written in C.

include std/os.e
include global.e
include opnames.e


-- Note: In several places we omit checking for bad arguments to 
-- built-in routines. Those errors will be caught by the underlying 
-- interpreter or Euphoria run-time system, and an error will be raised 
-- against execute.e. To correct this would require a lot of 
-- extra code, and would slow things down. It is left as an exercise
-- for the reader. :-)
		
-- we handle these operations specially because they refer to routine ids
-- in the user program, not the interpreter itself. We can't just let 
-- Euphoria do the work.

include global.e
include reswords.e as res
include symtab.e
include std/text.e
include scanner.e
include mode.e as mode
include std/pretty.e
include std/io.e

include std/io.e
include std/pretty.e

constant M_CALL_BACK = 52,  
		 M_CRASH_ROUTINE = 66,
		 M_CRASH_MESSAGE = 37,
		 M_CRASH_FILE = 57,
		 M_TICK_RATE = 38,
		 M_WARNING_FILE	= 72
		 
constant C_MY_ROUTINE = 1,
		 C_USER_ROUTINE = 2,
		 C_NUM_ARGS = 3

object crash_msg
crash_msg = 0

sequence call_backs, call_back_code
symtab_index t_id, t_arglist, t_return_val, call_back_routine

sequence crash_list  -- list of routine id's to call if there's a fatal crash
crash_list = {}

integer crash_count
crash_count = 0

-- only need one set of temps for call-backs
t_id = tmp_alloc()
t_arglist = tmp_alloc()
t_return_val = tmp_alloc()

-- dummy call-back routine
call_back_routine = NewEntry("_call_back_", 0, 0, PROC, 0, 0, 0)
SymTab[call_back_routine] = SymTab[call_back_routine] & 
							repeat(0, SIZEOF_ROUTINE_ENTRY - 
							length(SymTab[call_back_routine]))

SymTab[call_back_routine][S_SAVED_PRIVATES] = {}

call_back_code = {CALL_FUNC,
				  t_id,
				  t_arglist,
				  t_return_val,
				  CALL_BACK_RETURN
				 }

SymTab[call_back_routine][S_CODE] = call_back_code

integer TraceOn
TraceOn = FALSE

integer pc, a, b, c, d, target, len, keep_running
integer lhs_seq_index -- index of lhs sequence
sequence lhs_subs -- first n-1 LHS subscripts before final subscript or slice
sequence val

constant TASK_NEVER = 1e300
constant TASK_ID_MAX = 9e15 -- wrap to 0 after this (and avoid in-use ones)
boolean id_wrap             -- have task id's wrapped around? (very rare)
id_wrap = FALSE  

integer current_task  -- internal number of currently-executing task

sequence call_stack   -- active subroutine call stack
-- At each subroutine call we push two items: 
-- 1. the return pc value
-- 2. the current subroutine index

atom next_task_id     -- for multitasking
next_task_id = 1

atom clock_period
if EDOS then
	clock_period = 0.055  -- DOS default (can change)
else
	clock_period = 0.01   -- Windows/Linux/FreeBSD
end if

-- TCB fields
constant TASK_RID = 1,      -- routine id
		 TASK_TID = 2,      -- external task id
		 TASK_TYPE = 3,     -- type of task: T_REAL_TIME or T_TIME_SHARED
		 TASK_STATUS = 4,   -- status: ST_ACTIVE, ST_SUSPENDED, ST_DEAD
		 TASK_START = 5,    -- start time of current run
		 TASK_MIN_INC = 6,  -- time increment for min
		 TASK_MAX_INC = 7,  -- time increment for max 
		 TASK_MIN_TIME = 8, -- minimum activation time
							-- or number of executions remaining before sharing
		 TASK_MAX_TIME = 9, -- maximum activation time (determines task order)
		 TASK_RUNS_LEFT = 10,-- number of executions left in this burst
		 TASK_RUNS_MAX = 11,-- maximum number of executions in one burst
		 TASK_NEXT = 12,    -- points to next task on list
		 TASK_ARGS = 13,    -- args to call task procedure with at startup
		 TASK_PC = 14,      -- program counter for this task
		 TASK_CODE = 15,    -- IL code for this task
		 TASK_STACK = 16    -- call stack for this task

-- status values
constant ST_ACTIVE = 0,
		 ST_SUSPENDED = 1,
		 ST_DEAD = 2

constant T_REAL_TIME = 1,
		 T_TIME_SHARE = 2
		 
sequence tcb    -- task control block for real-time and time-shared tasks
tcb = {
	   -- initial "top-level" task, tid=0
	   {-1, 0, T_TIME_SHARE, ST_ACTIVE, 0,
		 0, 0, 1, 1, 1, 1, 0, {}, 1, {}, {}} 
	  }

integer rt_first, ts_first
rt_first = 0 -- unsorted list of active rt tasks
ts_first = 1 -- unsorted list of active ts tasks (initialized to initial task)

sequence e_routine -- list of routines with a routine id assigned to them
e_routine = {}

integer err_file
sequence err_file_name
err_file_name = "ex.err" 

procedure open_err_file()
-- open ex.err  

	err_file = open(err_file_name, "w")
	if err_file = -1 then
		puts(2, "Can't open " & err_file_name & '\n')
		abort(1)
	end if
end procedure

boolean screen_err_out

procedure both_puts(object s)
-- print to both screen and error file  
	if screen_err_out then
		puts(2, s)
	end if
	puts(err_file, s)
end procedure

procedure both_printf(sequence format, sequence items)
-- print to both screen and error file  
	if screen_err_out then
		printf(2, format, items)
	end if
	printf(err_file, format, items)
end procedure

function find_line(symtab_index sub, integer pc)
-- return the file name and line that matches pc in sub
	sequence linetab
	integer line, gline
	
	linetab = SymTab[sub][S_LINETAB]
	line = 1
	for i = 1 to length(linetab) do
		if linetab[i] >= pc or linetab[i] = -2 then
			line = i-1
			while line > 1 and linetab[line] = -1 do
				line -= 1
			end while
			exit
		end if
	end for
	gline = SymTab[sub][S_FIRSTLINE] + line - 1
	return {file_name[slist[gline][LOCAL_FILE_NO]], slist[gline][LINE]}
end function

procedure show_var(symtab_index x)
-- display a variable name and value
	
	puts(err_file, "    " & SymTab[x][S_NAME] & " = ")
	if equal(val[x], NOVALUE) then
		puts(err_file, "<no value>")
	else
		pretty_print(err_file, val[x], 
		{1, 2, length(SymTab[x][S_NAME]) + 7, 78, "%d", "%.10g", 32, 127, 500})
	end if
	puts(err_file, '\n')
end procedure

-- saved private blocks
constant SP_TASK_NUMBER = 1,
		 SP_TID = 2,
		 SP_BLOCK = 3,
		 SP_NEXT = 4

procedure save_private_block(symtab_index routine, sequence block)
-- save block for resident task on the private list for this routine
-- reuse any empty spot 
-- save in last-in, first-out order
-- We use a linked list to mirror the C-coded backend
	sequence saved, saved_list, eentry
	integer task, spot, tn
	
	task = SymTab[routine][S_RESIDENT_TASK]
	-- save it
	eentry = {task, tcb[task][TASK_TID], block, 0}
	saved = SymTab[routine][S_SAVED_PRIVATES]
	
	if length(saved) = 0 then
		-- first time set up
		saved = {1, -- index of first item
				 {eentry}} -- list of items
	else
		-- look for a free spot to put it
		saved_list = saved[2]
		spot = 0
		for i = 1 to length(saved_list) do
			tn = saved_list[i][SP_TASK_NUMBER]
			if tn = -1 or 
			   saved_list[i][SP_TID] != tcb[tn][TASK_TID] then
				  -- this spot was freed, or task died and was replaced
				spot = i
				exit
			end if
		end for
		
		eentry[SP_NEXT] = saved[1] -- new eentry points to previous first
		if spot = 0 then
			-- no unused spots, must grow
			saved_list = append(saved_list, eentry)
			spot = length(saved_list)
		else
			saved_list[spot] = eentry
		end if
		
		saved[1] = spot -- it becomes the first on the list
		saved[2] = saved_list
	end if
	
	SymTab[routine][S_SAVED_PRIVATES] = saved
end procedure

function load_private_block(symtab_index routine, integer task)
-- retrieve a private block and remove it from the list for this routine
-- (we know that the block must be there)
	sequence saved, saved_list, block
	integer p, prev_p, first
	
	saved = SymTab[routine][S_SAVED_PRIVATES]
	first = saved[1]
	p = first -- won't be 0
	prev_p = -1
	saved_list = saved[2]
	while TRUE do
		if saved_list[p][SP_TASK_NUMBER] = task then
			-- won't be for old dead task, must be current
			block = saved_list[p][SP_BLOCK]
			saved_list[p][SP_TASK_NUMBER] = -1 -- mark it as deleted
			if prev_p = -1 then
				first = saved_list[p][SP_NEXT]
			else    
				saved_list[prev_p][SP_NEXT] = saved_list[p][SP_NEXT]
			end if
			saved[1] = first
			saved[2] = saved_list
			SymTab[routine][S_SAVED_PRIVATES] = saved
			return block
		end if
		prev_p = p
		p = saved_list[p][SP_NEXT]
	end while
end function

procedure restore_privates(symtab_index this_routine)
-- kick out the current private data and
-- restore the private data for the current task
	symtab_index arg
	sequence private_block
	integer base
	
	if SymTab[this_routine][S_RESIDENT_TASK] != current_task then
		-- get new private data
		
		if SymTab[this_routine][S_RESIDENT_TASK] != 0 then 
			-- calling routine was taken over by another task
		
			-- save the other task's private data 

			-- private vars
			arg = SymTab[this_routine][S_NEXT]
			private_block = {}
			while arg != 0 and SymTab[arg][S_SCOPE] <= SC_PRIVATE do
				private_block = append(private_block, val[arg])   
				arg = SymTab[arg][S_NEXT]
			end while
		
			-- temps
			arg = SymTab[this_routine][S_TEMPS]
			while arg != 0 do
				private_block = append(private_block, val[arg])   
				arg = SymTab[arg][S_NEXT]
			end while

			save_private_block(this_routine, private_block)
		end if
		
		-- restore the current task's private data (must be there)
		private_block = load_private_block(this_routine, current_task)

		-- private vars
		base = 1
		arg = SymTab[this_routine][S_NEXT]
		while arg and SymTab[arg][S_SCOPE] <= SC_PRIVATE do
			val[arg] = private_block[base]
			base += 1
			arg = SymTab[arg][S_NEXT]
		end while
			
		-- temps
		arg = SymTab[this_routine][S_TEMPS]
		while arg != 0 do
			val[arg] = private_block[base]
			base += 1
			arg = SymTab[arg][S_NEXT]
		end while
	
		SymTab[this_routine][S_RESIDENT_TASK] = current_task
	end if
end procedure

procedure trace_back(sequence msg)
-- display the call stack and variables after a crash
	symtab_index sub, v
	integer levels, prev_file_no, task, dash_count
	sequence routine_name, title
	boolean show_message
	
	if atom(slist[$]) then
		slist = s_expand(slist)
	end if
	
	-- display call stack for each task,
	-- current task first
	show_message = TRUE
	
	screen_err_out = atom(crash_msg)
	
	while TRUE do
		if length(tcb) > 1 then
			-- multiple tasks were used
			
			if current_task = 1 then
				routine_name = "initial task"
			else
				routine_name = SymTab[e_routine[1+tcb[current_task][TASK_RID]]][S_NAME]
			end if
		
			title = sprintf(" TASK ID %d: %s ", 
						{tcb[current_task][TASK_TID], routine_name})
			dash_count = 60
			if length(title) < dash_count then
				dash_count = 52 - length(title)
			end if
			if dash_count < 1 then
				dash_count = 1
			end if
			both_puts(repeat('-', 22) & title & repeat('-', dash_count) & "\n")
		end if
	
		levels = 1
		
		while length(call_stack) > 0 do
			sub = call_stack[$]
			
			if levels = 1 then
				puts(2, '\n')
			
			elsif sub != call_back_routine then
				both_puts("... called from ")
				-- pc points to statement after the subroutine call
			end if
			
			if sub = call_back_routine then
				if crash_count > 0 then
					both_puts("^^^ called to handle run-time crash\n")
					exit
				else
					both_puts("^^^ call-back from ")
					if EWINDOWS then
						both_puts("Windows\n")
					else    
						both_puts("external program\n")
					end if
				end if
			
			else
				both_printf("%s:%d ", find_line(sub, pc)) 
	
				if not equal(SymTab[sub][S_NAME], "_toplevel_") then
					if SymTab[sub][S_TOKEN] = PROC then
						both_puts("in procedure ")
					elsif SymTab[sub][S_TOKEN] = FUNC then
						both_puts("in function ")
					elsif SymTab[sub][S_TOKEN] = TYPE then
						both_puts("in type ")
					end if
			
					both_printf("%s()", {SymTab[sub][S_NAME]})
				end if
				
				both_puts("\n")
				
				if show_message then
					if sequence(crash_msg) then
						clear_screen()
						puts(2, crash_msg)
					end if
					both_puts(msg & '\n')
					show_message = FALSE
				end if
	
				if length(call_stack) < 2 then
					both_puts('\n')
					exit
				end if
				
				-- display parameters and private vars
				v = SymTab[sub][S_NEXT]

				while v != 0 and 
					(SymTab[v][S_SCOPE] = SC_PRIVATE or 
					SymTab[v][S_SCOPE] = SC_LOOP_VAR) do
					show_var(v)
					v = SymTab[v][S_NEXT]
				end while
				
				if length(SymTab[sub][S_SAVED_PRIVATES]) > 0 and
				   SymTab[sub][S_SAVED_PRIVATES][1] != 0 then
					SymTab[sub][S_RESIDENT_TASK] = 0
					restore_privates(sub)
				end if
			end if
			
			puts(err_file, '\n')
			
			-- stacked pc points to next statement after the call (so subtract 1)
			pc = call_stack[$-1] - 1
			call_stack = call_stack[1..$-2]
			levels += 1
		end while
		
		tcb[current_task][TASK_STATUS] = ST_DEAD -- mark as "deleted"
		
		-- choose next task to display
		task = current_task
		for i = 1 to length(tcb) do
			if tcb[i][TASK_STATUS] != ST_DEAD and 
			   length(tcb[i][TASK_STACK]) > 0 then
				current_task = i
				call_stack = tcb[i][TASK_STACK]
				pc = tcb[i][TASK_PC]
				Code = tcb[i][TASK_CODE]
				screen_err_out = FALSE  -- just show offending task on screen
				exit
			end if
		end for 
		if task = current_task then
			exit
		end if  
		both_puts("\n")
	end while
	
	puts(2, "\n--> see " & err_file_name & '\n')
	
	puts(err_file, "\n\nGlobal & Local Variables\n")
	prev_file_no = -1
	v = SymTab[TopLevelSub][S_NEXT]
	while v do
		if SymTab[v][S_TOKEN] = VARIABLE and 
		   SymTab[v][S_MODE] = M_NORMAL and
		   find(SymTab[v][S_SCOPE], {SC_LOCAL, SC_GLOBAL, SC_GLOOP_VAR}) then
			if SymTab[v][S_FILE_NO] != prev_file_no then
				prev_file_no = SymTab[v][S_FILE_NO]
				puts(err_file, "\n " & file_name[prev_file_no] & ":\n")
			end if
			show_var(v)
		end if
		v = SymTab[v][S_NEXT]
	end while
	puts(err_file, '\n')
	close(err_file)
end procedure

integer forward_general_callback, forward_machine_callback

procedure call_crash_routines()
-- call all the routines in the crash list  
	object quit
	
	if crash_count > 0 then
		return
	end if
	
	crash_count += 1
	
	-- call them in reverse order
	err_file_name = "ex_crash.err"
	
	for i = length(crash_list) to 1 by -1 do
		-- do callback to get addr
		quit = call_func(forward_general_callback, 
						 {{0, crash_list[i], 1}, {0}})
		if not equal(quit, 0) then
			return -- don't call the others
		end if
	end for
end procedure

procedure quit_after_error()
-- final termination    
	if EWINDOWS then
		puts(2, "\nPress Enter...\n")
		if getc(0) then
		end if
	end if
	abort(1)
end procedure

procedure RTFatalType(integer x)
-- handle a fatal run-time type-check error 
	sequence msg, v
	sequence vname

	open_err_file()
	a = Code[x]
	vname = SymTab[a][S_NAME]
	msg = sprintf("type_check error\n%s is ", {vname}) 
	v = sprint(val[a])
	if length(v) > 70 - length(vname) then
		v = v[1..70 - length(vname)]
		while length(v) and not find(v[$], ",}")  do
			v = v[1..$-1]
		end while
		v = v & " ..."
	end if
	trace_back(msg & v)
	call_crash_routines()
	quit_after_error()
end procedure

procedure RTFatal(sequence msg)
-- handle a fatal run-time error    
	open_err_file()
	trace_back(msg)
	call_crash_routines()
	quit_after_error()
end procedure

procedure RTInternal(sequence msg)
-- Internal errors in back-end
	--puts(2, '\n' & msg & '\n')

    -- M_CRASH = 67
	machine_proc(67, msg)
end procedure

-- Multi-tasking operations


procedure wait(atom t)
-- wait for a while 
	atom t1, t2
	
	t1 = floor(t)
	if t1 >= 1 then
		sleep(t1)
		t -= t1
	end if
	
	t2 = time() + t
	while time() < t2 do
	end while
end procedure

boolean clock_stopped
clock_stopped = FALSE

procedure scheduler()
-- pick the next task to run
	atom earliest_time, start_time, now
	boolean ts_found
	sequence tp
	integer p, earliest_task
	
	-- first check the real-time tasks
	
	-- find the task with the earliest MAX_TIME
	earliest_task = rt_first
	
	if clock_stopped or earliest_task = 0 then
		-- no real-time tasks are active
		start_time = 1
		now = -1
	
	else
		-- choose a real-time task
		earliest_time = tcb[earliest_task][TASK_MAX_TIME]
		
		p = tcb[rt_first][TASK_NEXT]
		while p != 0 do
			tp = tcb[p]
			if tp[TASK_MAX_TIME] < earliest_time then
				earliest_task = p
				earliest_time = tp[TASK_MAX_TIME]
			end if
			p = tp[TASK_NEXT]
		end while
		
		-- when can we start? how many runs?
		now = time()
	
		start_time = tcb[earliest_task][TASK_MIN_TIME]
		
		if earliest_task = current_task and 
		   tcb[current_task][TASK_RUNS_LEFT] > 0 then
			-- runs left - continue with the current task
		else
			if tcb[current_task][TASK_TYPE] = T_REAL_TIME then
				tcb[current_task][TASK_RUNS_LEFT] = 0
			end if
			tcb[earliest_task][TASK_RUNS_LEFT] = tcb[earliest_task][TASK_RUNS_MAX]
		end if
	end if
	
	if start_time > now then
		-- No real-time task is ready to run.
		-- Look for a time-share task.
		
		ts_found = FALSE
		p = ts_first
		while p != 0 do
			tp = tcb[p]
			if tp[TASK_RUNS_LEFT] > 0 then
				  earliest_task = p
				  ts_found = TRUE
				  exit
			end if
			p = tp[TASK_NEXT]
		end while
		
		if not ts_found then
			-- all time-share tasks are at zero, recharge them all, 
			-- and choose one to run
			p = ts_first
			while p != 0 do
				tp = tcb[p]
				earliest_task = p
				tcb[p][TASK_RUNS_LEFT] = tp[TASK_RUNS_MAX]
				p = tp[TASK_NEXT]
			end while
		end if
			
		if earliest_task = 0 then
			-- no tasks are active - no task will ever run again
			-- RTFatal("no task to run") ??
			abort(0)
		end if
			
		if tcb[earliest_task][TASK_TYPE] = T_REAL_TIME then
			-- no time-sharing tasks, wait and run this real-time task
			wait(start_time - now)
		end if
		   
	end if

	tcb[earliest_task][TASK_START] = time()
	
	if earliest_task = current_task then
		pc += 1  -- continue with current task
	else    
		-- switch to a new task
		
		-- save old task state
		tcb[current_task][TASK_CODE] = Code
		tcb[current_task][TASK_PC] = pc
		tcb[current_task][TASK_STACK] = call_stack
		
		-- load new task state
		Code = tcb[earliest_task][TASK_CODE]
		pc = tcb[earliest_task][TASK_PC]
		call_stack = tcb[earliest_task][TASK_STACK]
		
		current_task = earliest_task
	
		if tcb[current_task][TASK_PC] = 0 then
			-- first time we are running this task
			-- call its procedure, passing the args from task_create
			pc = 1
			val[t_id] = tcb[current_task][TASK_RID]
			val[t_arglist] = tcb[current_task][TASK_ARGS]
			Code = {CALL_PROC, t_id, t_arglist}
		else
			-- resuming after a task_yield()
			pc += 1
			restore_privates(call_stack[$])
		end if
	end if
end procedure

function task_insert(integer first, integer task)
-- add a task to the appropriate list of tasks
	tcb[task][TASK_NEXT] = first
	return task
end function

function task_delete(integer first, integer task)
-- remove a task from a list of tasks (if it's there)
	integer p, prev_p
	
	prev_p = -1
	p = first
	while p != 0 do
		if p = task then
			if prev_p = -1 then
				-- it was first on list
				return tcb[p][TASK_NEXT]
			else
				-- skip around it
				tcb[prev_p][TASK_NEXT] = tcb[p][TASK_NEXT]
				return first
			end if
		end if
		prev_p = p
		p = tcb[p][TASK_NEXT]
	end while
	-- couldn't find it
	return first
end function

procedure opTASK_YIELD()
-- temporarily stop running this task, and give the scheduler a chance
-- to pick a new task
	atom now
	
	if tcb[current_task][TASK_STATUS] = ST_ACTIVE then
		if tcb[current_task][TASK_RUNS_LEFT] > 0 then
			tcb[current_task][TASK_RUNS_LEFT] -= 1
		end if
		if tcb[current_task][TASK_TYPE] = T_REAL_TIME then
			now = time()
			if tcb[current_task][TASK_RUNS_MAX] > 1 and 
			   tcb[current_task][TASK_START] = now then
				-- quick run of rapid-cycling task - clock hasn't even ticked
				if tcb[current_task][TASK_RUNS_LEFT] = 0 then
					-- avoid excessive number of runs per clock period
					now += clock_period
					tcb[current_task][TASK_RUNS_LEFT] = tcb[current_task][TASK_RUNS_MAX]
					tcb[current_task][TASK_MIN_TIME] = now + 
											   tcb[current_task][TASK_MIN_INC]
					tcb[current_task][TASK_MAX_TIME] = now + 
											   tcb[current_task][TASK_MAX_INC]
				else
					-- let it run multiple times per tick
					
				end if
			else
				tcb[current_task][TASK_MIN_TIME] = now + 
											   tcb[current_task][TASK_MIN_INC]
				tcb[current_task][TASK_MAX_TIME] = now + 
											   tcb[current_task][TASK_MAX_INC]
			end if
		end if
	end if
	scheduler()
end procedure

procedure kill_task(integer task)
-- mark a task for deletion (task is the internal task number)
	if tcb[task][TASK_TYPE] = T_REAL_TIME then
		rt_first = task_delete(rt_first, task)
	else    
		ts_first = task_delete(ts_first, task)
	end if
	tcb[task][TASK_STATUS] = ST_DEAD
	-- its tcb entry will be recycled later
end procedure

function which_task(atom tid)
-- find internal task number, given external task id
	
	for i = 1 to length(tcb) do
		if tcb[i][TASK_TID] = tid then
			return i
		end if
	end for
	RTFatal("invalid task id")
end function

procedure opTASK_STATUS()
-- return task status   
	integer r
	atom tid
	
	a = Code[pc+1]
	target = Code[pc+2]
	tid = val[a]
	r = -1
	for t = 1 to length(tcb) do
		if tcb[t][TASK_TID] = tid then
			if tcb[t][TASK_STATUS] = ST_ACTIVE then
				r = 1
			elsif tcb[t][TASK_STATUS] = ST_SUSPENDED then
				r = 0
			end if
			exit
		end if
	end for
	val[target] = r
	pc += 3
end procedure

procedure opTASK_LIST()
-- return list of active and suspended tasks    
	sequence list
	
	target = Code[pc+1]
	list = {}
	for i = 1 to length(tcb) do
		if tcb[i][TASK_STATUS] != ST_DEAD then
			list = append(list, tcb[i][TASK_TID])
		end if
	end for
	val[target] = list
	pc += 2
end procedure

procedure opTASK_SELF()
-- return current task id   
	target = Code[pc+1]
	val[target] = tcb[current_task][TASK_TID]
	pc += 2
end procedure

atom save_clock
save_clock = -1

procedure opTASK_CLOCK_STOP()
-- stop the scheduler clock 
	if not clock_stopped then
		save_clock = time()
		clock_stopped = TRUE
	end if
	pc += 1
end procedure

procedure opTASK_CLOCK_START()
-- resume the scheduler clock   
	atom shift
	
	if clock_stopped then
		if save_clock >= 0 and save_clock < time() then
			shift = time() - save_clock
			for i = 1 to length(tcb) do
				tcb[i][TASK_MIN_TIME] += shift
				tcb[i][TASK_MAX_TIME] += shift
			end for
		end if
		clock_stopped = FALSE
	end if
	pc += 1
end procedure

procedure opTASK_SUSPEND()
-- suspend a task   
	integer task
	
	a = Code[pc+1]
	task = which_task(val[a])
	tcb[task][TASK_STATUS] = ST_SUSPENDED
	tcb[task][TASK_MAX_TIME] = TASK_NEVER
	if tcb[task][TASK_TYPE] = T_REAL_TIME then
		rt_first = task_delete(rt_first, task)
	else    
		ts_first = task_delete(ts_first, task)
	end if
	pc += 2
end procedure
			
procedure opTASK_CREATE()
-- create a new task    
	symtab_index sub
	sequence new_entry
	boolean recycle
	
	a = Code[pc+1] -- routine id
	if val[a] < 0 or val[a] >= length(e_routine) then
		RTFatal("invalid routine id")
	end if
	sub = e_routine[val[a]+1]
	if SymTab[sub][S_TOKEN] != PROC then
		RTFatal("specify the routine id of a procedure, not a function or type")
	end if
	b = Code[pc+2] -- args
	
	-- initially it's suspended
	new_entry = {val[a], next_task_id, T_REAL_TIME, ST_SUSPENDED, 0, 
				 0, 0, 0, TASK_NEVER, 1, 1, 0, val[b], 0, {}, {}}
	
	recycle = FALSE
	for i = 1 to length(tcb) do
		if tcb[i][TASK_STATUS] = ST_DEAD then
			-- this task is dead, recycle its entry 
			-- (but not its external task id)
			tcb[i] = new_entry
			recycle = TRUE
			exit
		end if
	end for
	
	if not recycle then
		-- expand
		tcb = append(tcb, new_entry)
	end if
	
	target = Code[pc+3]
	val[target] = next_task_id
	if not id_wrap and next_task_id < TASK_ID_MAX then
		next_task_id += 1
	else
		-- extremely rare
		id_wrap = TRUE -- id's have wrapped
		for i = 1 to TASK_ID_MAX do
			next_task_id = i
			for j = 1 to length(tcb) do
				if next_task_id = tcb[j][TASK_TID] then
					next_task_id = 0
					exit -- this id is still in use
				end if
			end for
			if next_task_id then
				exit -- found unused id for next time
			end if
		end for
		-- must have found one - couldn't have trillions of non-dead tasks!
	end if
	pc += 4
end procedure

procedure opTASK_SCHEDULE()
-- schedule a task by linking it into the real-time tcb queue,
-- or the time sharing tcb queue
	
	integer task
	atom now
	object s
	
	a = Code[pc+1]
	task = which_task(val[a])
	b = Code[pc+2]
	s = val[b]
	
	if atom(s) then
		-- time-sharing
		if s <= 0 then
			RTFatal("number of executions must be greater than 0")
		end if
		--tcb[task][TASK_RUNS_LEFT] = s  -- current execution count
		tcb[task][TASK_RUNS_MAX] = s   -- max execution count
		if tcb[task][TASK_TYPE] = T_REAL_TIME then
			rt_first = task_delete(rt_first, task)
		end if
		if tcb[task][TASK_TYPE] = T_REAL_TIME or
			  tcb[task][TASK_STATUS] = ST_SUSPENDED then
			ts_first = task_insert(ts_first, task)
		end if
		tcb[task][TASK_TYPE] = T_TIME_SHARE
		
	else
		-- real-time
		if length(s) != 2 then
			RTFatal("second argument must be {min-time, max-time}")
		end if
		if sequence(s[1]) or sequence(s[2]) then
			RTFatal("min and max times must be atoms")
		end if
		if s[1] < 0 or s[2] < 0 then
			RTFatal("min and max times must be greater than or equal to 0")
		end if
		if s[1] > s[2] then
			RTFatal("task min time must be <= task max time")
		end if
		tcb[task][TASK_MIN_INC] = s[1]
		
		if s[1] < clock_period/2 then
			-- allow multiple runs per clock period
			if s[1] > 1.0e-9 then
				tcb[task][TASK_RUNS_MAX] =  floor(clock_period / s[1])
			else
				-- avoid divide by zero or almost zero
				tcb[task][TASK_RUNS_MAX] =  1000000000 -- arbitrary, large
			end if
		else
			tcb[task][TASK_RUNS_MAX] = 1
		end if
		tcb[task][TASK_MAX_INC] = s[2]
		now = time()
		tcb[task][TASK_MIN_TIME] = now + s[1]
		tcb[task][TASK_MAX_TIME] = now + s[2]
		
		if tcb[task][TASK_TYPE] = T_TIME_SHARE then
			ts_first = task_delete(ts_first, task)
		end if
		if tcb[task][TASK_TYPE] = T_TIME_SHARE or
			  tcb[task][TASK_STATUS] = ST_SUSPENDED then
			rt_first = task_insert(rt_first, task)
		end if
		tcb[task][TASK_TYPE] = T_REAL_TIME
	end if
	tcb[task][TASK_STATUS] = ST_ACTIVE
	pc += 3
end procedure


file trace_file
trace_file = -1

integer trace_line
trace_line = 0

procedure one_trace_line(sequence line)
-- write one fixed-width 79-char line to ctrace.out
	if EUNIX then
		printf(trace_file, "%-78.78s\n", {line})
	else
		printf(trace_file, "%-77.77s\r\n", {line})
	end if
end procedure

procedure opSTARTLINE()
-- Start of a line. Use for diagnostics.
	sequence line
	integer w
	
	if TraceOn then
		if trace_file = -1 then
			trace_file = open("ctrace.out", "wb")
			if trace_file = -1 then
				RTFatal("Couldn't open ctrace.out")
			end if
		end if

		a = Code[pc+1]
		
		if atom(slist[$]) then
			slist = s_expand(slist)
		end if
		line = fetch_line(slist[a][SRC])
		line = sprintf("%s:%d\t%s",
					   {name_ext(file_name[slist[a][LOCAL_FILE_NO]]),
						slist[a][LINE],
						line})
		trace_line += 1
		if trace_line >= 500 then
			-- wrap around to start of file
			trace_line = 0
			one_trace_line("")
			one_trace_line("               ")
			flush(trace_file)
			if seek(trace_file, 0) then
			end if
		end if
		
		one_trace_line(line)
		one_trace_line("")
		one_trace_line("=== THE END ===")
		one_trace_line("")
		one_trace_line("")
		one_trace_line("")
		flush(trace_file)
		w = where(trace_file)
		if seek(trace_file, w-79*5) then -- back up 5 (fixed-width) lines
		end if
	end if
	pc += 2
end procedure
		
procedure opPROC()  
-- Normal subroutine call
	integer n, arg, sub, p
	sequence private_block
	
	-- make a procedure or function/type call
	sub = Code[pc+1] -- subroutine
	arg = SymTab[sub][S_NEXT] 
	n = SymTab[sub][S_NUM_ARGS]
	
	if SymTab[sub][S_RESIDENT_TASK] != 0 then
		-- save the parameters, privates and temps
		
		-- save and set the args
		private_block = repeat(0, SymTab[sub][S_STACK_SPACE])
		p = 1
		for i = 1 to n do
			private_block[p] = val[arg]
			p += 1
			val[arg] = val[Code[pc+1+i]]
			arg = SymTab[arg][S_NEXT]
		end for
		
		-- save privates
		while arg != 0 and SymTab[arg][S_SCOPE] <= SC_PRIVATE do
			private_block[p] = val[arg]
			p += 1
			val[arg] = NOVALUE  -- necessary?
			arg = SymTab[arg][S_NEXT]
		end while
		
		-- save temps
		arg = SymTab[sub][S_TEMPS]
		while arg != 0 do
			private_block[p] = val[arg]
			p += 1
			val[arg] = NOVALUE -- necessary?
			arg = SymTab[arg][S_NEXT]
		end while
	
		-- save this block of private data
		save_private_block(sub, private_block)
	else    
		-- routine is not in use, no need to save 
		-- just set the args 
		for i = 1 to n do
			val[arg] = val[Code[pc+1+i]]
			arg = SymTab[arg][S_NEXT]
		end for
	end if
	
	SymTab[sub][S_RESIDENT_TASK] = current_task
	
	pc = pc + 2 + n
	if SymTab[sub][S_TOKEN] != PROC then
		pc += 1
	end if
	
	call_stack = append(call_stack, pc) 
	call_stack = append(call_stack, sub)
	
	Code = SymTab[sub][S_CODE]
	pc = 1 
end procedure

integer result
result = 0
object result_val

procedure opRETURNP()   
-- return from procedure (or function)
	symtab_index arg, sub, caller
	
	sub = Code[pc+1]
	
	-- set up for caller
	pc = call_stack[$-1]
	call_stack = call_stack[1..$-2]
	
	-- set sub privates to NOVALUE -- necessary? - we do it at routine entry
	arg = SymTab[sub][S_NEXT]
	while arg and SymTab[arg][S_SCOPE] <= SC_PRIVATE do
		val[arg] = NOVALUE
		arg = SymTab[arg][S_NEXT]
	end while

	SymTab[sub][S_RESIDENT_TASK] = 0
	
	if length(call_stack) then
		caller = call_stack[$]
		Code = SymTab[caller][S_CODE]
		restore_privates(caller)
		if result then
			val[Code[result]] = result_val
			result = 0
		end if
	else
		kill_task(current_task)
		scheduler()
	end if
end procedure

procedure opRETURNF()  
-- return from function
	result_val = val[Code[pc+2]]
	result = call_stack[$-1] - 1
	opRETURNP()
end procedure

procedure opCALL_BACK_RETURN()
-- force return from do_exec()
	keep_running = FALSE  
end procedure
				
procedure opBADRETURNF()  
-- shouldn't reach here
	RTFatal("attempt to exit a function without returning a value")  
end procedure

procedure opRETURNT()   
-- return from top-level "procedure"
	pc += 1
	if pc > length(Code) then
		keep_running = FALSE  -- we've reached the end of the code
	end if
end procedure
		
procedure opRHS_SUBS() 
-- subscript a sequence to get the value of the element
-- RHS_SUBS_CHECK, RHS_SUBS, RHS_SUBS_I
	object sub, x
	
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	x = val[a]
	sub = val[b]
	if atom(x) then
		RTFatal("attempt to subscript an atom\n(reading from it)")
	end if
	if sequence(sub) then
		RTFatal("subscript must be an atom\n(reading an element of a sequence)")
	end if
	sub = floor(sub)
	if sub < 1 or sub > length(x) then
		RTFatal(
		sprintf(
		"subscript value %d is out of bounds, reading from a sequence of length %d", 
		{sub, length(x)}))
	end if
	val[target] = x[sub]
	pc += 4
end procedure
		
procedure opGOTO()
	pc = Code[pc+1]
end procedure
procedure opGLABEL()
	pc = Code[pc+1]
end procedure

procedure opIF()
	a = Code[pc+1]
	if val[a] = 0 then
		pc = Code[pc+2]
	else
		pc += 3
	end if
end procedure
			
procedure opINTEGER_CHECK()
	a = Code[pc+1]
	if not integer(val[a]) then
		RTFatalType(pc+1)
	end if
	pc += 2
end procedure
			
procedure opATOM_CHECK()
	a = Code[pc+1]
	if not atom(val[a]) then
		RTFatalType(pc+1)
	end if
	pc += 2
end procedure
			  
procedure opSEQUENCE_CHECK()
	a = Code[pc+1]
	if not sequence(val[a]) then
		RTFatalType(pc+1)
	end if
	pc += 2
end procedure

procedure opASSIGN()  
-- ASSIGN, ASSIGN_I 
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = val[a]
	pc += 3
end procedure
				
procedure opELSE()  
-- ELSE, EXIT, ENDWHILE
	pc = Code[pc+1]
end procedure
			
procedure opRIGHT_BRACE_N()  
-- form a sequence of any length 
	sequence x
	
	len = Code[pc+1]
	x = {}
	for i = pc+len+1 to pc+2 by -1 do
		-- last one comes first
		x = append(x, val[Code[i]])
	end for
	target = Code[pc+len+2]
	val[target] = x
	pc += 3 + len
end procedure

procedure opRIGHT_BRACE_2()   
-- form a sequence of length 2 (slightly faster than above)
	target = Code[pc+3]
	-- the second one comes first
	val[target] = {val[Code[pc+2]], val[Code[pc+1]]}
	pc += 4
end procedure

procedure opPLUS1() 
--PLUS1, PLUS1_I
	a = Code[pc+1]
	-- [2] is not used
	target = Code[pc+3] 
	val[target] = val[a] + 1
	pc += 4
end procedure
		
procedure opGLOBAL_INIT_CHECK()  
-- GLOBAL_INIT_CHECK, PRIVATE_INIT_CHECK 
	a = Code[pc+1]
	if equal(val[a], NOVALUE) then
		RTFatal(SymTab[a][S_NAME] & " has not been initialized")
	end if
	pc += 2
end procedure
			
procedure opWHILE()     
-- sometimes emit.c optimizes this away
	a = Code[pc+1]
	if val[a] = 0 then
		pc = Code[pc+2]
	else
		pc += 3
	end if
end procedure

procedure opSWITCH_SPI()
-- pc+1: switch value
-- pc+2: case values
-- pc+3: jump_table
-- pc+4: else jump
	if integer( val[Code[pc+1]] ) then
		a = val[Code[pc+1]] - val[Code[pc+2]]
		if a > 0 and a <= length( val[Code[pc+3]] ) then
			pc += val[Code[pc+3]][a]
			return
		end if
	end if
	pc = Code[pc+4]
end procedure

procedure opSWITCH()
-- pc+1: switch value
-- pc+2: case values
-- pc+3: jump_table
-- pc+4: else jump

	a = find( val[Code[pc+1]], val[Code[pc+2]] )
	if a then
		pc += val[Code[pc+3]][a]
	else
		pc = Code[pc + 4]
	end if
end procedure

procedure opCASE()

end procedure

procedure opNOPSWITCH()

end procedure

function var_subs(object x, sequence subs)
-- subscript x with the list of subscripts in subs
	object si
	
	if atom(x) then
		RTFatal("attempt to subscript an atom\n(reading from it)")
	end if
	for i = 1 to length(subs) do
		si = subs[i]
		if sequence(si) then
			RTFatal("A subscript must be an atom")
		end if
		si = floor(si)
		if si > length(x) or si < 1 then
			RTFatal(
			sprintf("subscript value %d is out of bounds, reading from a sequence of length %d",
				{si, length(x)}))
		end if
		x = x[subs[i]]
	end for
	return x
end function

procedure opLENGTH()
-- operand should be a sequence 
	a = Code[pc+1]
	target = Code[pc+2]
	if atom(val[a]) then
		RTFatal("length of an atom is not defined")
	end if
	val[target] = length(val[a])
	pc += 3
end procedure

-- Note: Multiple LHS subscripts, and $ within those subscripts,
-- is handled much more efficiently in the hand-coded C interpreter,
-- and in code translated to C, where C pointers can be used effectively.

procedure opPLENGTH()
-- Needed for some LHS uses of $. Operand should be a val index of a sequence,
-- with subscripts. 
	a = Code[pc+1]
	target = Code[pc+2]
	lhs_seq_index = val[a][1]
	lhs_subs = val[a][2..$]
	val[target] = length(var_subs(val[lhs_seq_index], lhs_subs))
	pc += 3
end procedure

procedure opLHS_SUBS() 
-- LHS = "Left Hand Side" of assignment
-- Handle one LHS subscript, when there are multiple LHS subscripts.
	
	a = Code[pc+1] -- base var sequence, or a temp that contains
				   -- {base index, subs1, subs2... so far}
	b = Code[pc+2] -- subscript
	target = Code[pc+3] -- temp for storing result
	
	-- a is a "pointer" to the result of previous subscripting
	val[target] = append(val[a], val[b])
	pc += 5
end procedure

procedure opLHS_SUBS1() 
-- Handle first LHS subscript, when there are multiple LHS subscripts.
	a = Code[pc+1] -- base var sequence, or a temp that contains
				   -- {base index, subs1, subs2... so far}
	b = Code[pc+2] -- subscript
	target = Code[pc+3] -- temp for storing result
	
	-- a is the base var
	val[target] = {a, val[b]}
	pc += 5
end procedure

procedure opLHS_SUBS1_COPY() 
-- Handle first LHS subscript, when there are multiple LHS subscripts.
-- In tricky situations (in the C-coded back-end) a copy of the sequence 
-- is made into a temp. 
	
	a = Code[pc+1] -- base var sequence
				   
	b = Code[pc+2] -- subscript
	
	target = Code[pc+3] -- temp for storing result
	
	c = Code[pc+4] -- temp to hold base sequence while it's manipulated
	
	val[c] = val[a]
	
	-- a is the base var
	val[target] = {c, val[b]}
	
	pc += 5
end procedure

procedure lhs_check_subs(object seq, object subs)
-- see if seq[subs] = ... is legal  
	if atom(seq) then
		RTFatal("attempt to subscript an atom\n(assigning to it)")
	end if
	if sequence(subs) then
		RTFatal(
		sprintf(
		"subscript must be an atom\n(assigning to a sequence of length %d)",
		length(seq)))
	end if
	subs = floor(subs)
	if subs < 1 or subs > length(seq) then
		RTFatal(
		sprintf(
		"subscript value %d is out of bounds, assigning to a sequence of length %d",
		{subs, length(seq)}))
	end if
end procedure

procedure check_slice(object seq, object lower, object upper)
-- check for valid slice indexes
	atom len
	
	if sequence(lower) then
		RTFatal("slice lower index is not an atom")
	end if
	lower = floor(lower)
	if lower < 1 then
		RTFatal("slice lower index is less than 1")
	end if
	
	if sequence(upper) then
		RTFatal("slice upper index is not an atom")
	end if
	upper = floor(upper)
	if upper < 0 then
		RTFatal("slice upper index is less than 0")
	end if
	
	if atom(seq) then
		RTFatal("attempt to slice an atom")
	end if
		
	len = upper - lower + 1
	
	if len < 0 then
		RTFatal("slice length is less than 0")
	end if

	if lower > length(seq) + 1 or (len > 0 and lower > length(seq)) then
		RTFatal("slice starts past end of sequence")
	end if

	if upper > length(seq) then
		RTFatal("slice ends past end of sequence")
	end if
end procedure

procedure lhs_check_slice(object seq, object lower, object upper, object rhs)
-- check for a valid assignment to a slice
	atom len
	
	check_slice(seq, lower, upper)
	
	len = floor(upper) - floor(lower) + 1
	
	if sequence(rhs) and length(rhs) != len then
		RTFatal("lengths do not match on assignment to slice")
	end if
end procedure

function var_slice(object x, sequence subs, atom lower, atom upper)
-- slice x after subscripting a variable number of times
	if atom(x) then
		RTFatal("attempt to subscript an atom\n(reading from it)")
	end if
	for i = 1 to length(subs) do
		if sequence(subs[i]) then
			RTFatal("subscript must be an atom")
		end if
		subs = floor(subs)
		if subs[i] > length(x) or subs[i] < 1 then
			RTFatal(
			sprintf("subscript value %d is out of bounds, reading from a sequence of length %d",
				{subs[i], length(x)}))
		end if
		x = x[subs[i]] 
	end for
	check_slice(x, lower, upper)
	return x[lower..upper]
end function

function assign_subs(sequence x, sequence subs, object rhs_val)
-- assign a value to a subscripted sequence (any number of subscripts >= 1)
	lhs_check_subs(x, subs[1])
	if length(subs) = 1 then
		x[subs[1]] = rhs_val
	else
		x[subs[1]] = assign_subs(x[subs[1]], subs[2..$], rhs_val)
	end if
	return x
end function            

function assign_slice(sequence x, sequence subs, atom lower, atom upper, object rhs_val)
-- assign a value to a subscripted/sliced sequence 
-- (any number of subscripts >= 1, then one slice)
	-- should check slice too
	lhs_check_subs(x, subs[1])
	if length(subs) = 1 then
		lhs_check_slice(x[subs[1]],lower,upper,rhs_val)
		x[subs[1]][lower..upper] = rhs_val
	else
		x[subs[1]] = assign_slice(x[subs[1]], subs[2..$], lower, upper, rhs_val)
	end if
	return x
end function            

procedure opASSIGN_SUBS() -- also ASSIGN_SUBS_CHECK, ASSIGN_SUBS_I
-- LHS single subscript and assignment
	object x, subs
	
	a = Code[pc+1]  -- the sequence
	b = Code[pc+2]  -- the subscript
	if sequence(val[b]) then
		RTFatal("subscript must be an atom\n(assigning to subscript of a sequence)")        
	end if
	c = Code[pc+3]  -- the RHS value
	x = val[a] -- avoid lingering ref count on val[a]
	lhs_check_subs(x, val[b])
	x = val[c]
	subs = val[b]
	val[a][subs] = x  -- single LHS subscript
	pc += 4
end procedure

procedure opPASSIGN_SUBS()
-- final LHS subscript and assignment after a series of subscripts
	a = Code[pc+1]
	b = Code[pc+2]  -- subscript
	if sequence(val[b]) then
		RTFatal("subscript must be an atom\n(assigning to subscript of a sequence)")        
	end if
	c = Code[pc+3]  -- RHS value
	
	-- multiple LHS subscript case
	lhs_seq_index = val[a][1]
	lhs_subs = val[a][2..$]    
	val[lhs_seq_index] = assign_subs(val[lhs_seq_index], 
										 lhs_subs & val[b], 
										 val[c])
	pc += 4
end procedure

procedure opASSIGN_OP_SUBS()  
-- var[subs] op= expr
	object x
	
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	-- var with one subscript
	lhs_subs = {}
	x = val[a]
	val[target] = var_subs(x, lhs_subs & val[b])
	pc += 4
end procedure

procedure opPASSIGN_OP_SUBS()  
-- var[subs] ... [subs] op= expr
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	-- temp with multiple subscripts
	lhs_seq_index = val[a][1]
	lhs_subs = val[a][2..$]
	Code[pc+9] = Code[pc+1] -- patch upcoming op
	val[target] = var_subs(val[lhs_seq_index], lhs_subs & val[b])
	pc += 4
end procedure

procedure opASSIGN_OP_SLICE()  
-- var[i..j] op= expr
	object x

	a = Code[pc+1]
	x = val[a]
	b = Code[pc+2]
	if floor(val[b]) > length(x) or floor(val[b]) < 1 then
		RTFatal(
		sprintf("subscript value %d is out of bounds, reading from a sequence of length %d",
				{val[b], length(x)}))
	end if
	c = Code[pc+3]
	target = Code[pc+4]
	val[target] = var_slice(x, {}, val[b], val[c])
	pc += 5
end procedure

procedure opPASSIGN_OP_SLICE()
-- var[subs] ... [i..j] op= expr
	object x

	a = Code[pc+1]
	x = val[a]
	b = Code[pc+2]
	c = Code[pc+3]
	target = Code[pc+4]
	lhs_seq_index = x[1]
	lhs_subs = x[2..$]
	Code[pc+10] = Code[pc+1]
	val[target] = var_slice(val[lhs_seq_index], lhs_subs, val[b], val[c])
	pc += 5
end procedure
			
procedure opASSIGN_SLICE()   
-- var[i..j] = expr
	object x
	
	a = Code[pc+1]  -- sequence
	b = Code[pc+2]  -- 1st index
	c = Code[pc+3]  -- 2nd index
	d = Code[pc+4]  -- rhs value to assign
	
	x = val[a] -- avoid lingering ref count on val[a]
	lhs_check_slice(x, val[b], val[c], val[d])
	x = val[d]
	val[a][val[b]..val[c]] = x
	pc += 5
end procedure

procedure opPASSIGN_SLICE()   
-- var[x] ... [i..j] = expr
	a = Code[pc+1]  -- sequence
	b = Code[pc+2]  -- 1st index
	c = Code[pc+3]  -- 2nd index
	d = Code[pc+4]  -- rhs value to assign
	
	lhs_seq_index = val[a][1]
	lhs_subs = val[a][2..$]
	val[lhs_seq_index] = assign_slice(val[lhs_seq_index],
									  lhs_subs,
									  val[b], val[c], val[d])
	pc += 5
end procedure

procedure opRHS_SLICE() 
-- rhs slice of a sequence a[i..j] 
	object x
	
	a = Code[pc+1]  -- sequence
	b = Code[pc+2]  -- 1st index
	c = Code[pc+3]  -- 2nd index
	target = Code[pc+4]  
	x = val[a]
	check_slice(x, val[b], val[c])
	val[target] = x[val[b]..val[c]]
	pc += 5
end procedure

procedure opTYPE_CHECK() 
-- type check for a user-defined type
-- this always follows a type-call
	if val[Code[pc-1]] = 0 then
		RTFatalType(pc-2)
	end if
	pc += 1
end procedure
			
procedure opIS_AN_INTEGER()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = integer(val[a])
	pc += 3
end procedure

procedure opIS_AN_ATOM()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = atom(val[a])
	pc += 3
end procedure
				
procedure opIS_A_SEQUENCE() 
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = sequence(val[a])
	pc += 3
end procedure
			
procedure opIS_AN_OBJECT()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = (val[a] != NOVALUE)
	pc += 3
end procedure
				
		
		-- ---------- start of unary ops ----------------- 

procedure opSQRT() 
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = sqrt(val[a])
	pc += 3
end procedure

procedure opSIN()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = sin(val[a])
	pc += 3
end procedure

procedure opCOS()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = cos(val[a])
	pc += 3
end procedure

procedure opTAN()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = tan(val[a])
	pc += 3
end procedure

procedure opARCTAN()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = arctan(val[a])
	pc += 3
end procedure

procedure opLOG()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = log(val[a])
	pc += 3
end procedure

procedure opNOT_BITS()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = not_bits(val[a])
	pc += 3
end procedure

procedure opFLOOR()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = floor(val[a])
	pc += 3
end procedure

procedure opNOT_IFW()
	a = Code[pc+1]
	if val[a] = 0 then
		pc += 3
	else
		pc = Code[pc+2]
	end if
end procedure
			
procedure opNOT()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = not val[a]
	pc += 3
end procedure
			
procedure opUMINUS()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = -val[a]
	pc += 3
end procedure
			
procedure opRAND()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = rand(val[a])
	pc += 3
end procedure
			
procedure opDIV2()  
-- like unary op, but pc+=4
	a = Code[pc+1]
	-- Code[pc+2] not used
	target = Code[pc+3]
	val[target] = val[a] / 2
	pc += 4 
end procedure
			
procedure opFLOOR_DIV2()
	a = Code[pc+1]
	-- Code[pc+2] not used
	target = Code[pc+3]
	val[target] = floor(val[a] / 2)
	pc += 4 
end procedure
				
		----------- start of binary ops ----------
			
procedure opGREATER_IFW()
	a = Code[pc+1]
	b = Code[pc+2]
	if val[a] > val[b] then
		pc += 4
	else
		pc = Code[pc+3]
	end if
end procedure
		
procedure opNOTEQ_IFW()
	a = Code[pc+1]
	b = Code[pc+2]
	if val[a] != val[b] then
		pc += 4
	else
		pc = Code[pc+3]
	end if
end procedure
		
procedure opLESSEQ_IFW()
	a = Code[pc+1]
	b = Code[pc+2]
	if val[a] <= val[b] then
		pc += 4
	else
		pc = Code[pc+3]
	end if
end procedure
		
procedure opGREATEREQ_IFW()
	a = Code[pc+1]
	b = Code[pc+2]
	if val[a] >= val[b] then
		pc += 4
	else
		pc = Code[pc+3]
	end if
end procedure
		
procedure opEQUALS_IFW()
	a = Code[pc+1]
	b = Code[pc+2]
	if val[a] = val[b] then
		pc += 4
	else
		pc = Code[pc+3]
	end if
end procedure
		
procedure opLESS_IFW()
	a = Code[pc+1]
	b = Code[pc+2]
	if val[a] < val[b] then
		pc += 4
	else
		pc = Code[pc+3]
	end if
end procedure
			
		-- other binary ops
		
procedure opMULTIPLY()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = val[a] * val[b]
	pc += 4
end procedure
			
procedure opPLUS() 
-- PLUS, PLUS_I
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = val[a] + val[b]
	pc += 4
end procedure
		
procedure opMINUS() 
-- MINUS, MINUS_I
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = val[a] - val[b]
	pc += 4
end procedure
			
procedure opOR()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = val[a] or val[b]
	pc += 4
end procedure
		
procedure opXOR()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = val[a] xor val[b]
	pc += 4
end procedure
		
procedure opAND()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = val[a] and val[b]
	pc += 4
end procedure
			
procedure opDIVIDE()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	if equal(val[b], 0) then
		RTFatal("attempt to divide by 0")
	end if
	val[target] = val[a] / val[b]
	pc += 4
end procedure

procedure opREMAINDER()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	if equal(val[b], 0) then
		RTFatal("Can't get remainder of a number divided by 0")
	end if
	val[target] = remainder(val[a], val[b])
	pc += 4
end procedure
			
procedure opFLOOR_DIV()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	if equal(val[b], 0) then
		RTFatal("attempt to divide by 0")
	end if
	val[target] = floor(val[a] / val[b])
	pc += 4
end procedure
			
procedure opAND_BITS()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = and_bits(val[a], val[b])
	pc += 4
end procedure
		
procedure opOR_BITS()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = or_bits(val[a], val[b])
	pc += 4
end procedure
		
procedure opXOR_BITS()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = xor_bits(val[a], val[b])
	pc += 4
end procedure
			
procedure opPOWER()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = power(val[a], val[b])
	pc += 4
end procedure
			
procedure opLESS()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = val[a] < val[b]
	pc += 4
end procedure
		
procedure opGREATER()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = val[a] > val[b]
	pc += 4
end procedure
		
procedure opEQUALS()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = val[a] = val[b]
	pc += 4
end procedure
		
procedure opNOTEQ()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = val[a] != val[b]
	pc += 4
end procedure
		
procedure opLESSEQ()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = val[a] <= val[b]
	pc += 4
end procedure
		
procedure opGREATEREQ()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = val[a] >= val[b]
	pc += 4
end procedure
			
-- short-circuit ops 

procedure opSC1_AND()
	a = Code[pc+1]
	b = Code[pc+2]
	if atom(val[a]) then
		if val[a] = 0 then
			val[b] = 0
			pc = Code[pc+3]
			return
		end if
	else
		RTFatal("true/false condition must be an ATOM")
	end if
	pc += 4
end procedure

procedure opSC1_AND_IF() 
-- no need to store 0   
	a = Code[pc+1]
	b = Code[pc+2]
	if atom(val[a]) then
		if val[a] = 0 then
			pc = Code[pc+3]
			return
		end if
	else
		RTFatal("true/false condition must be an ATOM")
	end if
	pc += 4
end procedure

procedure opSC1_OR()
	a = Code[pc+1]
	b = Code[pc+2]
	if atom(val[a]) then
		if val[a] != 0 then
			val[b] = 1
			pc = Code[pc+3]
			return
		end if
	else
		RTFatal("true/false condition must be an ATOM")
	end if
	pc += 4
end procedure
				
procedure opSC1_OR_IF()
-- no need to store 1
	a = Code[pc+1]
	b = Code[pc+2]
	if atom(val[a]) then
		if val[a] != 0 then
			val[b] = 1
			pc = Code[pc+3]
			return
		end if
	else
		RTFatal("true/false condition must be an ATOM")
	end if
	pc += 4
end procedure
				
procedure opSC2_OR() 
-- SC2_OR,  SC2_AND 
-- short-circuit op
	a = Code[pc+1]
	b = Code[pc+2]
	if atom(val[a]) then
		val[b] = val[a] 
	else
		RTFatal("true/false condition must be an ATOM")
	end if
	pc += 3
end procedure

-- for loops 
			
procedure opFOR()  
-- FOR, FOR_I 
-- enter into a for loop    
	integer increment, limit, initial, loopvar, jump
	
	increment = Code[pc+1]
	limit = Code[pc+2]
	initial = Code[pc+3]
	-- ignore current_sub = Code[pc+4] - we don't patch the ENDFOR
	-- so recursion is not a problem
	loopvar = Code[pc+5]
	jump = Code[pc+6]
	
	if sequence(val[initial]) then
		RTFatal("for-loop variable is not an atom")
	end if
	if sequence(val[limit]) then
		RTFatal("for-loop limit is not an atom")
	end if
	if sequence(val[increment]) then
		RTFatal("for-loop increment is not an atom")
	end if
	
	pc += 7 -- to enter into the loop
	
	if val[increment] >= 0 then
		-- going up
		if val[initial] > val[limit] then
			pc = jump -- quit immediately, 0 iterations
		end if
	else
		-- going down
		if val[initial] < val[limit] then
			pc = jump -- quit immediately, 0 iterations
		end if
	end if

	val[loopvar] = val[initial] -- initialize loop var
	
end procedure

procedure opENDFOR_GENERAL() 
-- ENDFOR_INT_UP, ENDFOR_UP, ENDFOR_INT_DOWN1,
-- ENDFOR_INT_DOWN, ENDFOR_DOWN, ENDFOR_GENERAL
-- end of for loop: drop out of the loop, or go back to the top
	integer loopvar
	atom increment, limit, next
	
	limit = val[Code[pc+2]]
	increment = val[Code[pc+4]]
	loopvar = Code[pc+3]
	next = val[loopvar] + increment
	
	if increment >= 0 then
		-- up loop
		if next > limit then
			pc += 5 -- exit loop
		else
			val[loopvar] = next
			pc = Code[pc+1] -- loop again
		end if
	else    
		-- down loop
		if next < limit then
			pc += 5 -- exit loop
		else
			val[loopvar] = next
			pc = Code[pc+1] -- loop again
		end if
	end if
end procedure

procedure opENDFOR_INT_UP1() 
-- ENDFOR_INT_UP1
-- faster: end of for loop with known +1 increment
-- exit or go back to the top
-- (loop var might not be integer, but that doesn't matter here)
	integer loopvar
	atom limit, next
	
	limit = val[Code[pc+2]]
	loopvar = Code[pc+3]
	next = val[loopvar] + 1
	
	-- up loop
	if next > limit then
		pc += 5 -- exit loop
	else
		val[loopvar] = next
		pc = Code[pc+1] -- loop again
	end if
end procedure

function RTLookup(sequence name, integer file, symtab_index proc, integer stlen)
-- Look up a name (routine or var) in the symbol table at runtime.
-- The name must have been defined earlier in the source than
-- where we are currently executing. The name may be a simple "name"
-- or "ns:name". Speed is not too critical. This lookup is only used 
-- in interactive trace mode, and in looking up routine id's, 
-- which should normally only be done once for an indirectly-callable 
-- routine.
	symtab_index s, global_found
	sequence ns
	integer colon
	integer ns_file
	integer found_in_path
	integer found_outside_path
	integer s_in_include_path
	
	colon = find(':', name)
	
	if colon then
		-- look up "ns : name"
		ns = name[1..colon-1]
		name = name[colon+1..$]
		
		-- trim off any trailing whitespace from ns
		while length(ns) and (ns[$] = ' ' or ns[$] = '\t') do
			ns = ns[1..$-1]
		end while
	
		-- trim off any leading whitespace from ns
		while length(ns) and (ns[1] = ' ' or ns[1] = '\t') do
			ns = ns[2..$]
		end while
		
		if length(ns) = 0 or equal( ns, "eu") then
			return 0 -- bad syntax
		end if

		-- step 1: look up NAMESPACE symbol 
		s = SymTab[TopLevelSub][S_NEXT]
		while s != 0 and s <= stlen do
			if file = SymTab[s][S_FILE_NO] and 
				SymTab[s][S_TOKEN] = NAMESPACE and 
				equal(ns, SymTab[s][S_NAME]) then
				exit
			end if
			s = SymTab[s][S_NEXT]
		end while
		
		if s = 0 then
			return 0 -- couldn't find ns
		end if
		
		ns_file = SymTab[s][S_OBJ]
		
		-- trim off any leading whitespace from name
		while length(name) and (name[1] = ' ' or name[1] = '\t') do
			name = name[2..$]
		end while
		
		-- step 2: find global name in ns file 
		s = SymTab[TopLevelSub][S_NEXT]
		while s != 0 and s <= stlen do
			if SymTab[s][S_FILE_NO] = ns_file and 
				SymTab[s][S_SCOPE] = SC_GLOBAL and 
				equal(name, SymTab[s][S_NAME]) then
				return s
			end if
			s = SymTab[s][S_NEXT]
		end while
		
		return 0 -- couldn't find name in ns file
	
	else 
		-- look up simple unqualified routine name

		if proc != TopLevelSub then  
			-- inside a routine - check PRIVATEs and LOOP_VARs
			s = SymTab[proc][S_NEXT]
			while s and (SymTab[s][S_SCOPE] = SC_PRIVATE or 
						 SymTab[s][S_SCOPE] = SC_LOOP_VAR) do
				if equal(name, SymTab[s][S_NAME]) then
					return s           
				end if
				s = SymTab[s][S_NEXT]
			end while
		end if

		-- try to match a LOCAL or GLOBAL routine in the same source file
		s = SymTab[TopLevelSub][S_NEXT]
		found_in_path = 0
		found_outside_path = 0
		while s != 0 and s <= stlen do
			if SymTab[s][S_FILE_NO] = file and 
				(SymTab[s][S_SCOPE] = SC_LOCAL or 
				 SymTab[s][S_SCOPE] = SC_GLOBAL or 
				 SymTab[s][S_SCOPE] = SC_EXPORT or
				(proc = TopLevelSub and SymTab[s][S_SCOPE] = SC_GLOOP_VAR)) and
				equal(name, SymTab[s][S_NAME]) then  
				-- shouldn't really be able to see GLOOP_VARs unless we are
				-- currently inside the loop - only affects interactive var display
				return s
			end if
			s = SymTab[s][S_NEXT]
		end while 

		-- try to match a single earlier GLOBAL or EXPORT symbol
		global_found = FALSE
		s = SymTab[TopLevelSub][S_NEXT]
		while s != 0 and s <= stlen do
			if SymTab[s][S_SCOPE] = SC_GLOBAL and 
			   equal(name, SymTab[s][S_NAME]) then
			
				s_in_include_path = symbol_in_include_path( s, file, {} )
				if s_in_include_path then
					global_found = s
					found_in_path += 1
				else
					if not found_in_path then
						global_found = s
					end if
					found_outside_path += 1
				end if
			elsif SymTab[s][S_SCOPE] = SC_EXPORT and equal( name, SymTab[s][S_NAME] ) then
				if is_direct_include( s, file ) then
					global_found = s
				end if
					found_in_path += 1
			end if
			s = SymTab[s][S_NEXT]
		end while 
		
		if found_in_path != 1 and (( found_in_path + found_outside_path ) != 1 ) then
			return 0
		end if
		return global_found
	
	end if
end function

procedure opCALL_PROC() 
-- CALL_PROC, CALL_FUNC - call via routine id
	integer cf, n, arg, p
	symtab_index sub
	sequence private_block
	
	cf = Code[pc] = CALL_FUNC
	
	a = Code[pc+1]  -- routine id
	if val[a] < 0 or val[a] >= length(e_routine) then
		RTFatal("invalid routine id")
	end if
	
	sub = e_routine[val[a]+1]
	b = Code[pc+2]  -- argument list
	
	if cf then
		if SymTab[sub][S_TOKEN] = PROC then
			RTFatal(sprintf("%s() does not return a value", SymTab[sub][S_NAME]))
		end if
	else
		if SymTab[sub][S_TOKEN] != PROC then
			RTFatal(sprintf("the value returned by %s() must be assigned or used",
							SymTab[sub][S_NAME]))
		end if
	end if
	if atom(val[b]) then
		RTFatal("argument list must be a sequence")
	end if
	
	if SymTab[sub][S_NUM_ARGS] != length(val[b]) then
		RTFatal(sprintf("call to %s() via routine-id should pass %d arguments, not %d",
				{SymTab[sub][S_NAME], SymTab[sub][S_NUM_ARGS], length(val[b])}))
				 
	end if
	
	n = SymTab[sub][S_NUM_ARGS]
	arg = SymTab[sub][S_NEXT]
	
	if SymTab[sub][S_RESIDENT_TASK] != 0 then
		-- save the parameters, privates and temps
		
		-- save and set the args
		private_block = repeat(0, SymTab[sub][S_STACK_SPACE])
		p = 1
		for i = 1 to n do
			private_block[p] = val[arg]
			p += 1
			val[arg] = val[b][i]
			arg = SymTab[arg][S_NEXT]
		end for
	
		-- save the privates
		while arg != 0 and SymTab[arg][S_SCOPE] <= SC_PRIVATE do
			private_block[p] = val[arg]
			p += 1
			val[arg] = NOVALUE -- necessary?
			arg = SymTab[arg][S_NEXT]
		end while
	
		-- save temps
		arg = SymTab[sub][S_TEMPS]
		while arg != 0 do
			private_block[p] = val[arg]
			p += 1
			val[arg] = NOVALUE -- necessary?
			arg = SymTab[arg][S_NEXT]
		end while
	
		-- save this block of private data
		save_private_block(sub, private_block)
	else
		-- routine is not in use, no need to save 
		-- just set the args 
		for i = 1 to n do
			val[arg] = val[b][i]
			arg = SymTab[arg][S_NEXT]
		end for
	end if
	
	SymTab[sub][S_RESIDENT_TASK] = current_task
	
	pc += 3 + cf
	
	call_stack = append(call_stack, pc) 
	call_stack = append(call_stack, sub)
	
	Code = SymTab[sub][S_CODE]
	pc = 1
end procedure
			  
procedure opROUTINE_ID()
-- get the routine id for a routine name    
-- routine id's start at 0 (for compatibility with C-coded back-end)
	integer sub, fn, p, stlen
	object name
	
	sub = Code[pc+1]   -- CurrentSub
	stlen = Code[pc+2]  -- s.t. length
	name = val[Code[pc+3]]  -- routine name sequence
	fn = Code[pc+4]    -- file number
	target = Code[pc+5]
	pc += 6
	if atom(name) then
		val[target] = -1
		return
	end if
	p = RTLookup(name, fn, sub, stlen)
	if p = 0 or not find(SymTab[p][S_TOKEN], {PROC, FUNC, TYPE}) then
		val[target] = -1  -- name is not a routine
		return
	end if
	for i = 1 to length(e_routine) do
		if e_routine[i] = p then
			val[target] = i - 1  -- routine was already assigned an id
			return
		end if
	end for 
	e_routine = append(e_routine, p)
	val[target] = length(e_routine) - 1
end procedure
			
procedure opAPPEND()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = append(val[a], val[b])
	pc += 4
end procedure

procedure opPREPEND() 
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = prepend(val[a], val[b])
	pc += 4
end procedure

procedure opCONCAT()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = val[a] & val[b]
	pc += 4
end procedure
			
procedure opCONCAT_N()
-- concatenate 3 or more items
	integer n
	object x
	
	n = Code[pc+1] -- number of items
	-- operands are in reverse order
	x = val[Code[pc+2]] -- last one
	for i = pc+3 to pc+n+1 do
		x = val[Code[i]] & x
	end for
	target = Code[pc+n+2]
	val[target] = x
	pc += n+3
end procedure
			
procedure opREPEAT()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	if not atom(val[b]) then
		RTFatal("repetition count must be an atom")
	end if
	if val[b] < 0 then
		RTFatal("repetition count must not be negative")
	end if
	if val[b] > 1073741823 then
		RTFatal("repetition count is too large")
	end if
	val[target] = repeat(val[a], val[b])
	pc += 4
end procedure

procedure opDATE()
	target = Code[pc+1]
	val[target] = date()
	pc += 2
end procedure

procedure opTIME()
	target = Code[pc+1]
	val[target] = time()
	pc += 2
end procedure

procedure opSPACE_USED() -- RDS DEBUG only
	pc += 2
end procedure

procedure opNOP2()   
-- space filler
	pc+= 2
end procedure

procedure opPOSITION()
	a = Code[pc+1]
	b = Code[pc+2]
	position(val[a], val[b])  -- error checks
	pc += 3
end procedure
			
procedure opEQUAL()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = equal(val[a], val[b])
	pc += 4
end procedure
				
procedure opHASH()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = hash(val[a], val[b])
	pc += 4
end procedure

procedure opCOMPARE()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = compare(val[a], val[b])
	pc += 4
end procedure

procedure opFIND()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	if not sequence(val[b]) then
		RTFatal("second argument of find() must be a sequence")
	end if
	val[target] = find(val[a], val[b])
	pc += 4
end procedure

procedure opMATCH()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	if not sequence(val[a]) then
		RTFatal("first argument of match() must be a sequence")
	end if
	if not sequence(val[b]) then
		RTFatal("second argument of match() must be a sequence")
	end if
	if length(val[a]) = 0 then
		 RTFatal("first argument of match() must be a non-empty sequence")
	end if
	val[target] = match(val[a], val[b])
	pc += 4
end procedure

procedure opFIND_FROM()
		sequence s

		c = val[Code[pc+3]]
		target = Code[pc+4]
		if not sequence(val[Code[pc+2]]) then
				RTFatal("second argument of find_from() must be a sequence")
				pc += 5
				return
		end if
		s = val[Code[pc+2]][c..$]
		b = find( val[Code[pc+1]], s )
		if b then
				b += c - 1
		end if
		val[target] = b
		pc += 5
end procedure

procedure opMATCH_FROM()
		object s

		c = val[Code[pc+3]]
		target = Code[pc+4]
		s = val[Code[pc+2]]
		a = Code[pc+1]
		if not sequence(val[a]) then
				RTFatal("first argument of match_from() must be a sequence")
				pc += 5
				return
		end if
		if length(val[a]) = 0 then
				RTFatal("first argument of match_from() must be a non-empty sequence")
				pc += 5
				return
		end if
		if not sequence(s) then
				RTFatal("second argument of match_from() must be a sequence")
				pc += 5
				return
		end if
		if c < 1 then
				RTFatal("index out of bounds in match_from()")
				pc += 5
				return
		end if
		if c > length(s) then
				RTFatal("index out of bounds in match_from()")
				pc += 5
				return
		end if
		s = s[c..$]
		b = match( val[Code[pc+1]], s )
		if b then
				b += c - 1
		end if
		val[target] = b
		pc += 5
end procedure

procedure opPEEK2U()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = peek2u(val[a])
	pc += 3
end procedure
		
procedure opPEEK2S()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = peek2s(val[a])
	pc += 3
end procedure

procedure opPEEK4U()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = peek4u(val[a])
	pc += 3
end procedure
		
procedure opPEEK4S()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = peek4s(val[a])
	pc += 3
end procedure

procedure opPEEK_STRING()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = peek_string(val[a])
	pc += 3
end procedure
		
procedure opPEEK()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = peek(val[a])
	pc += 3
end procedure

procedure opPEEKS()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = peeks(val[a])
	pc += 3
end procedure

procedure opPOKE()
	a = Code[pc+1]
	b = Code[pc+2]
	poke(val[a], val[b])
	pc += 3
end procedure
		
procedure opPOKE4()
	a = Code[pc+1]
	b = Code[pc+2]
	poke4(val[a], val[b])
	pc += 3
end procedure

procedure opPOKE2()
	a = Code[pc+1]
	b = Code[pc+2]
	poke2(val[a], val[b])
	pc += 3
end procedure


procedure opMEM_COPY()
	a = Code[pc+1]
	b = Code[pc+2]
	c = Code[pc+3]
	mem_copy(val[a], val[b], val[c])
	pc += 4
end procedure
			
procedure opMEM_SET()
	a = Code[pc+1]
	b = Code[pc+2]
	c = Code[pc+3]
	mem_set(val[a], val[b], val[c])
	pc += 4
end procedure
			
procedure opPIXEL()
	a = Code[pc+1]
	b = Code[pc+2]
	pixel(val[a], val[b])
	pc += 3
end procedure
			
procedure opGET_PIXEL()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = get_pixel(val[a])
	pc += 3
end procedure
		  
procedure opCALL()
	a = Code[pc+1]
	call(val[a])
	pc += 2
end procedure

procedure opSYSTEM()
	a = Code[pc+1]
	b = Code[pc+2]
	if atom(val[a]) then
		RTFatal("first argument of system() must be a sequence")
	end if
	if sequence(val[b]) then
		RTFatal("second argument of system() must be an atom")
	end if
	system(val[a], val[b])
	pc += 3
end procedure
				
procedure opSYSTEM_EXEC()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	if atom(val[a]) then
		RTFatal("first argument of system() must be a sequence")
	end if
	if sequence(val[b]) then
		RTFatal("second argument of system() must be an atom")
	end if
	val[target] = system_exec(val[a], val[b])
	pc += 4
end procedure
				
-- I/O routines

procedure opOPEN()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	
	if atom(val[b]) or length(val[b]) > 2 then
	   RTFatal("invalid open mode")
	end if     
	if atom(val[a]) then
	   RTFatal("device or file name must be a sequence")
	end if         
	val[target] = open(val[a], val[b])
	pc += 4
end procedure

procedure opCLOSE()
	a = Code[pc+1]
	close(val[a])
	pc += 2
end procedure
			  
procedure opABORT()
	abort(val[Code[pc+1]])
end procedure

procedure opGETC()  -- read a character from a file 
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = getc(val[a])
	pc += 3
end procedure
 
procedure opGETS()  
-- read a line from a file
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = gets(val[a])
	pc += 3
end procedure

procedure opGET_KEY() 
-- read an immediate key (if any) from the keyboard 
-- or return -1 
	target = Code[pc+1]
	val[target] = get_key()
	pc += 2
end procedure

procedure opCLEAR_SCREEN()
	clear_screen()
	pc += 1
end procedure

procedure opPUTS()
	a = Code[pc+1]
	b = Code[pc+2]
	puts(val[a], val[b])
	pc += 3
end procedure

procedure opQPRINT()
-- Code[pc+1] not used
	a = Code[pc+2]
--	? val[a]
	pc += 3
end procedure
		
procedure opPRINT()
	a = Code[pc+1]
	b = Code[pc+2]
	print(val[a], val[b])
	pc += 3
end procedure

procedure opPRINTF()
	-- printf 
	a = Code[pc+1]
	b = Code[pc+2]
	c = Code[pc+3]
	printf(val[a], val[b], val[c])
	pc += 4
end procedure

procedure opSPRINTF()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = sprintf(val[a], val[b])
	pc += 4
end procedure

procedure opCOMMAND_LINE()
	sequence cmd
	
	target = Code[pc+1]
	cmd = command_line()
	-- drop second word for better compatibility
	if length(cmd) > 2 then
		cmd = {cmd[1]} & cmd[3..$]
	end if
	val[target] = cmd
	pc += 2
end procedure

procedure opOPTION_SWITCHES()
	sequence cmd
	
	target = Code[pc+1]
	cmd = option_switches()
	val[target] = cmd
	pc += 2
end procedure

procedure opGETENV()
	a = Code[pc+1]
	target = Code[pc+2]
	if atom(val[a]) then
		RTFatal("argument to getenv must be a sequence")
	end if
	val[target] = getenv(val[a])
	pc += 3
end procedure

procedure opC_PROC()
	symtab_index sub
	
	a = Code[pc+1]
	b = Code[pc+2]
	sub = Code[pc+3]
	c_proc(val[a], val[b])  -- callback could happen here
	restore_privates(sub)
	pc += 4
end procedure
		  
procedure opC_FUNC()
	integer target
	symtab_index sub
	object temp
	
	a = Code[pc+1]
	b = Code[pc+2]
	sub = Code[pc+3]
	target = Code[pc+4]
	temp = c_func(val[a], val[b])  -- callback could happen here
	restore_privates(sub)
	val[target] = temp
	pc += 5
end procedure

procedure opTRACE()
	TraceOn = val[Code[pc+1]]
	pc += 2  -- turn on/off tracing
end procedure
			
-- other tracing/profiling ops - ignored
procedure opPROFILE() 
-- PROFILE, DISPLAY_VAR, ERASE_PRIVATE_NAMES, ERASE_SYMBOL
-- ops not implemented, ignore
	pc += 2
end procedure
			
procedure opUPDATE_GLOBALS()
-- for interactive trace
-- not implemented, ignore
	pc += 1
end procedure

sequence operation 


--            Call-backs
--
-- This uses Intel machine code developed by Matthew Lewis.
-- It allows an "infinite" number of call-back routines to be
-- created dynamically.
--
-- Note: If you happen to port Euphoria to a non-Intel machine,
-- or a system with a different calling convention,
-- Matt's machine-code call-backs won't work, but you
-- can easily create call-back routines in Euphoria, something like:
--
--    function callback_001(atom a, atom b, atom c, atom d)
--        return general_callback(call_backs[1], {a,b,c,d})
--    end function
--
-- You can get the address of the above routine using:
--
--    addr = call_back(routine_id("call_back_001"))
--
-- By creating call_back_001, call_back_002 ... you can create
-- as many call-back routines as you like, in a portable way.
-- The only problem is that you can't dynamically create new
-- call_back routines at run-time with this method. Most programs that
-- use call-backs only need a small number of them (less than 10). 
-- 4-argument call-backs are quite common in Windows, so you might
-- need several of them on that system.

integer fwd_do_exec = -1
function general_callback(sequence routine, sequence args)
-- call the user's function from an external source 
-- (interface for Euphoria-coded call-backs)

	val[t_id] = routine[C_USER_ROUTINE]
	val[t_arglist] = args
	
	SymTab[call_back_routine][S_RESIDENT_TASK] = current_task
	
	-- create a stack frame
	call_stack = append(call_stack, pc)
	call_stack = append(call_stack, call_back_routine)

	Code = call_back_code 
	pc = 1 
	 
	call_proc( fwd_do_exec, {} )
	
	-- remove the stack frame
	pc = call_stack[$-1]
	call_stack = call_stack[1..$-2]
	
	-- restore
	Code = SymTab[call_stack[$]][S_CODE]
	
	return val[t_return_val]
end function

forward_general_callback = routine_id("general_callback")

function machine_callback(atom cbx, atom ptr)
-- call the user's function from an external source 
-- (interface for machine-coded call-backs)
	sequence routine, args
	
	routine = call_backs[cbx]
	args = peek4u(ptr & call_backs[cbx][C_NUM_ARGS])
	
	return general_callback(routine, args)
end function

call_backs = {}

constant cb_std = {
	#89,#E0,                --    0: mov eax, esp
	#83,#C0,#04,            --    2: add eax, 4
	#50,                    --    5: push eax
	#68,#00,#00,#00,#00,    --    6: push dword rid (7)
	#FF,#15,#00,#00,#00,#00,--    B: call near dword ptr [pfunc] (13)
	#C2,#00,#00,            --   11: ret bytes (18)
	#00,#00,#00,#00},       --   14: function pointer (20)

cb_cdecl= {
	#89,#E0,                --    0: mov eax, esp
	#83,#C0,#04,            --    2: add eax, 4
	#50,                    --    5: push eax
	#68,#00,#00,#00,#00,    --    6: push dword rid (7)
	#FF,#15,#00,#00,#00,#00,--    B: call near dword ptr [pfunc] (13)
	#83, #C4, #08,          --   11: sub esp, 8
	#C3,#00,#00,            --   14: ret bytes 
		#00,#00,#00,#00}    --   17: function pointer (23)

constant 
	M_ALLOC = 16

procedure do_callback(integer b)
-- handle callback()
	symtab_index r
	atom asm
	integer id, convention
	object x

	-- val[b] is:  routine id or {'+', routine_id}
	x = val[b]
	if atom(x) then
		id = x
		convention = 0
	else
		id = x[2]
		convention = x[1]
	end if
		
	if id < 0 or id >= length(e_routine) then
		RTFatal("Invalid routine id")
	end if
		
	r = e_routine[id+1]

	if platform() = WIN32 and convention = 0 then
		-- stdcall
		asm = machine_func(M_ALLOC, length(cb_std) )
		poke( asm, cb_std ) 
		poke4( asm + 7, length(call_backs) + 1 )
		poke4( asm + 13, asm + 20 )
		poke( asm + 18, SymTab[r][S_NUM_ARGS] * 4 )
		poke4( asm + 20, machine_func(M_CALL_BACK, routine_id("machine_callback") ) )
		
	else
		-- cdecl
		asm = machine_func(M_ALLOC, length(cb_cdecl) )
		poke( asm, cb_cdecl )
		poke4( asm + 7, length(call_backs) + 1 )
		poke4( asm + 13, asm + 23 )
		poke4( asm + 23, machine_func(M_CALL_BACK, ( '+' & routine_id("machine_callback") )))
	end if

	val[target] = asm
	call_backs = append( call_backs, { r, id, SymTab[r][S_NUM_ARGS] })
end procedure        

procedure do_crash_routine(integer b)
-- add a crash routine to the list
	object x
	
	x = val[b]
	if atom(x) and x >= 0 and x < length(e_routine) then
		crash_list = append(crash_list, x)
	else
		RTFatal("crash routine requires a valid routine id")
	end if
end procedure

procedure opHEAD()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = head(val[a],val[b])
	pc += 4
end procedure

procedure opTAIL()
	a = Code[pc+1]
	b = Code[pc+2]
	target = Code[pc+3]
	val[target] = tail(val[a],val[b])
	pc += 4
end procedure

procedure opMACHINE_FUNC()
	a = Code[pc+1]
	b = Code[pc+2] 
	target = Code[pc+3]
	pc += 4
	-- handle CALL_BACK specially
	if val[a] = M_CALL_BACK then
		-- routine id's must be handled at our level
		do_callback(b)  
	else
		val[target] = machine_func(val[a], val[b])
	end if
end procedure

procedure opSPLICE()
	a = Code[pc+1]
	b = Code[pc+2]
	c = Code[pc+3]
	target = Code[pc+4]
	val[target] = splice(val[a],val[b],val[c])
	pc += 5
end procedure

procedure opINSERT()
	a = Code[pc+1]
	b = Code[pc+2]
	c = Code[pc+3]
	target = Code[pc+4]
	val[target] = insert(val[a],val[b],val[c])
	pc += 5
end procedure

procedure opMACHINE_PROC()
	object v
	
	a = Code[pc+1]
	b = Code[pc+2]
	v = val[a]
	-- some things must be handled at our level, not a lower level
	if v = M_CRASH_ROUTINE then
		-- routine id's must be handled at our level
		do_crash_routine(b) 

	elsif v = M_CRASH_MESSAGE then
		crash_msg = val[b]

	elsif v = M_CRASH_FILE and sequence(val[b]) then
		err_file_name = val[b]  
	
	elsif v = M_WARNING_FILE then
		display_warnings = 1
		if sequence(val[b]) then
			TempWarningName = val[b]
		else
			TempWarningName = STDERR
			display_warnings = (val[b] >= 0)
		end if

	elsif EDOS and v = M_TICK_RATE and val[b] > 18 and val[b] < 10000 then
		clock_period = 1 / val[b]
		machine_proc(v, val[b]) 
	
	else
		machine_proc(v, val[b]) 
	end if
	pc += 3
end procedure

ifdef CALLPROC then

procedure do_exec()
-- execute IL code, starting at pc 
	integer op

	keep_running = TRUE
	while keep_running do 
		op = Code[pc]
		call_proc(operation[op], {}) -- opcodes start at 1
	end while
	keep_running = TRUE -- so higher-level do_exec() will keep running
end procedure

else

procedure do_exec()
-- execute IL code, starting at pc 
	keep_running = TRUE
	while keep_running do 
		integer op = Code[pc]
		switch op do
			case ABORT:
				opABORT()
				break
			case AND:
				opAND()
				break
			case AND_BITS:
				opAND_BITS()
				break
			case APPEND:
				opAPPEND()
				break
			case ARCTAN:
				opARCTAN()
				break
			case ASSIGN:
			case ASSIGN_I:
				opASSIGN()
				break
			case ASSIGN_OP_SLICE:
				opASSIGN_OP_SLICE()
				break
			case ASSIGN_OP_SUBS:
				opASSIGN_OP_SUBS()
				break
			case ASSIGN_SLICE:
				opASSIGN_SLICE()
				break
			case ASSIGN_SUBS:
			case ASSIGN_SUBS_CHECK:
			case ASSIGN_SUBS_I:
				opASSIGN_SUBS()
				break
			case ATOM_CHECK:
				opATOM_CHECK()
				break
			case BADRETURNF:
				opBADRETURNF()
				break
			case C_FUNC:
				opC_FUNC()
				break
			case C_PROC:
				opC_PROC()
				break
			case CALL:
				opCALL()
				break
			case CALL_BACK_RETURN:
				opCALL_BACK_RETURN()
				break
			case CALL_PROC:
			case CALL_FUNC:
				opCALL_PROC()
				break
			case CASE:
				opCASE()
				break
			case CLEAR_SCREEN:
				opCLEAR_SCREEN()
				break
			case CLOSE:
				opCLOSE()
				break
			case COMMAND_LINE:
				opCOMMAND_LINE()
				break
			case COMPARE:
				opCOMPARE()
				break
			case CONCAT:
				opCONCAT()
				break
			case CONCAT_N:
				opCONCAT_N()
				break
			case COS:
				opCOS()
				break
			case DATE:
				opDATE()
				break
			case DIV2:
				opDIV2()
				break
			case DIVIDE:
				opDIVIDE()
				break
			case ELSE:
			case EXIT:
			case ENDWHILE:
			case RETRY:
				opELSE()
				break
			case ENDFOR_GENERAL:
			case ENDFOR_UP:
			case ENDFOR_DOWN:
			case ENDFOR_INT_UP:
			case ENDFOR_INT_DOWN:
			case ENDFOR_INT_DOWN1:
				opENDFOR_GENERAL()
				break
			case ENDFOR_INT_UP1:
				opENDFOR_INT_UP1()
				break
			case EQUAL:
				opEQUAL()
				break
			case EQUALS:
				opEQUALS()
				break
			case EQUALS_IFW:
			case EQUALS_IFW_I:
				opEQUALS_IFW()
				break
			case FIND:
				opFIND()
				break
			case FIND_FROM:
				opFIND_FROM()
				break
			case FLOOR:
				opFLOOR()
				break
			case FLOOR_DIV:
				opFLOOR_DIV()
				break
			case FLOOR_DIV2:
				opFLOOR_DIV2()
				break
			case FOR:
			case FOR_I:
				opFOR()
				break
			case GET_KEY:
				opGET_KEY()
				break
			case GET_PIXEL:
				opGET_PIXEL()
				break
			case GETC:
				opGETC()
				break
			case GETENV:
				opGETENV()
				break
			case GETS:
				opGETS()
				break
			case GLABEL:
				opGLABEL()
				break
			case GLOBAL_INIT_CHECK:
			case PRIVATE_INIT_CHECK:
				opGLOBAL_INIT_CHECK()
				break
			case GOTO:
				opGOTO()
				break
			case GREATER:
				opGREATER()
				break
			case GREATER_IFW:
			case GREATER_IFW_I:
				opGREATER_IFW()
				break
			case GREATEREQ:
				opGREATEREQ()
				break
			case GREATEREQ_IFW:
			case GREATEREQ_IFW_I:
				opGREATEREQ_IFW()
				break
			case HASH:
				opHASH()
				break
			case IF:
				opIF()
				break
			case INSERT:
				opINSERT()
				break
			case INTEGER_CHECK:
				opINTEGER_CHECK()
				break
			case IS_A_SEQUENCE:
				opIS_A_SEQUENCE()
				break
			case IS_AN_ATOM:
				opIS_AN_ATOM()
				break
			case IS_AN_INTEGER:
				opIS_AN_INTEGER()
				break
			case IS_AN_OBJECT:
				opIS_AN_OBJECT()
				break
			case LENGTH:
				opLENGTH()
				break
			case LESS:
			case LESS_IFW_I:
				opLESS()
				break
			case LESS_IFW:
				opLESS_IFW()
				break
			case LESSEQ:
				opLESSEQ()
				break
			case LESSEQ_IFW:
			case LESSEQ_IFW_I:
				opLESSEQ_IFW()
				break
			case LHS_SUBS:
				opLHS_SUBS()
				break
			case LHS_SUBS1:
				opLHS_SUBS1()
				break
			case LHS_SUBS1_COPY:
				opLHS_SUBS1_COPY()
				break
			case LOG:
				opLOG()
				break
			case MACHINE_FUNC:
				opMACHINE_FUNC()
				break
			case MACHINE_PROC:
				opMACHINE_PROC()
				break
			case MATCH:
				opMATCH()
				break
			case MATCH_FROM:
				opMATCH_FROM()
				break
			case MEM_COPY:
				opMEM_COPY()
				break
			case MEM_SET:
				opMEM_SET()
				break
			case MINUS:
			case MINUS_I:
				opMINUS()
				break
			case MULTIPLY:
				opMULTIPLY()
				break
			case NOP2:
			case SC2_NULL:
			case ASSIGN_SUBS2:
			case PLATFORM:
			case END_PARAM_CHECK:
			case NOPWHILE:
			case NOP1:
				opNOP2()
				break
			case NOPSWITCH:
				opNOPSWITCH()
				break
			case NOT:
				opNOT()
				break
			case NOT_BITS:
				opNOT_BITS()
				break
			case NOT_IFW:
				opNOT_IFW()
				break
			case NOTEQ:
				opNOTEQ()
				break
			case NOTEQ_IFW:
			case NOTEQ_IFW_I:
				opNOTEQ_IFW()
				break
			case OPEN:
				opOPEN()
				break
			case OPTION_SWITCHES:
				opOPTION_SWITCHES()
				break
			case OR:
				opOR()
				break
			case OR_BITS:
				opOR_BITS()
				break
			case PASSIGN_OP_SLICE:
				opPASSIGN_OP_SLICE()
				break
			case PASSIGN_OP_SUBS:
				opPASSIGN_OP_SUBS()
				break
			case PASSIGN_SLICE:
				opPASSIGN_SLICE()
				break
			case PASSIGN_SUBS:
				opPASSIGN_SUBS()
				break
			case PEEK:
				opPEEK()
				break
			case PEEK_STRING:
				opPEEK_STRING()
				break
			case PEEK2S:
				opPEEK2S()
				break
			case PEEK2U:
				opPEEK2U()
				break
			case PEEK4S:
				opPEEK4S()
				break
			case PEEK4U:
				opPEEK4U()
				break
			case PEEKS:
				opPEEKS()
				break
			case PIXEL:
				opPIXEL()
				break
			case PLENGTH:
				opPLENGTH()
				break
			case PLUS:
				opPLUS()
				break
			case PLUS1:
			case PLUS1_I:
				opPLUS1()
				break
			case POKE:
				opPOKE()
				break
			case POKE2:
				opPOKE2()
				break
			case POKE4:
				opPOKE4()
				break
			case POSITION:
				opPOSITION()
				break
			case POWER:
				opPOWER()
				break
			case PREPEND:
				opPREPEND()
				break
			case PRINT:
				opPRINT()
				break
			case PRINTF:
				opPRINTF()
				break
			case PROC:
				opPROC()
				break
			case PROFILE:
			case DISPLAY_VAR:
			case ERASE_PRIVATE_NAMES:
			case ERASE_SYMBOL:
				opPROFILE()
				break
			case PUTS:
				opPUTS()
				break
			case QPRINT:
				opQPRINT()
				break
			case RAND:
				opRAND()
				break
			case REMAINDER:
				opREMAINDER()
				break
			case REPEAT:
				opREPEAT()
				break
			case RETURNF:
				opRETURNF()
				break
			case RETURNP:
				opRETURNP()
				break
			case RETURNT:
				opRETURNT()
				break
			case RHS_SLICE:
				opRHS_SLICE()
				break
			case RHS_SUBS:
			case RHS_SUBS_CHECK:
			case RHS_SUBS_I:
				opRHS_SUBS()
				break
			case RIGHT_BRACE_2:
				opRIGHT_BRACE_2()
				break
			case RIGHT_BRACE_N:
				opRIGHT_BRACE_N()
				break
			case ROUTINE_ID:
				opROUTINE_ID()
				break
			case SC1_AND:
				opSC1_AND()
				break
			case SC1_AND_IF:
				opSC1_AND_IF()
				break
			case SC1_OR:
				opSC1_OR()
				break
			case SC1_OR_IF:
				opSC1_OR_IF()
				break
			case SC2_OR:
			case SC2_AND:
				opSC2_OR()
				break
			case SEQUENCE_CHECK:
				opSEQUENCE_CHECK()
				break
			case SIN:
				opSIN()
				break
			case SPACE_USED:
				opSPACE_USED()
				break
			case SPLICE:
				opSPLICE()
				break
			case SPRINTF:
				opSPRINTF()
				break
			case SQRT:
				opSQRT()
				break
			case STARTLINE:
				opSTARTLINE()
				break
			case SWITCH:
			case SWITCH_I:
				opSWITCH()
				break
			case SWITCH_SPI:
				opSWITCH_SPI()
				break
			case SYSTEM:
				opSYSTEM()
				break
			case SYSTEM_EXEC:
				opSYSTEM_EXEC()
				break
			case TAN:
				opTAN()
				break
			case TASK_CLOCK_START:
				opTASK_CLOCK_START()
				break
			case TASK_CLOCK_STOP:
				opTASK_CLOCK_STOP()
				break
			case TASK_CREATE:
				opTASK_CREATE()
				break
			case TASK_LIST:
				opTASK_LIST()
				break
			case TASK_SCHEDULE:
				opTASK_SCHEDULE()
				break
			case TASK_SELF:
				opTASK_SELF()
				break
			case res:TASK_STATUS:
				opTASK_STATUS()
				break
			case TASK_SUSPEND:
				opTASK_SUSPEND()
				break
			case TASK_YIELD:
				opTASK_YIELD()
				break
			case TIME:
				opTIME()
				break
			case TRACE:
				opTRACE()
				break
			case TYPE_CHECK:
				opTYPE_CHECK()
				break
			case UMINUS:
				opUMINUS()
				break
			case UPDATE_GLOBALS:
				opUPDATE_GLOBALS()
				break
			case WHILE:
				opWHILE()
				break
			case XOR:
				opXOR()
				break
			case XOR_BITS:
				opXOR_BITS()
				break
			case else
				
				RTFatal( sprintf("Unknown opcode: %d", op ) )
		end switch
	end while
	keep_running = TRUE -- so higher-level do_exec() will keep running
end procedure

end ifdef -- CALLPROC

fwd_do_exec = routine_id("do_exec")

procedure InitBackEnd(integer ignore)
-- initialize Interpreter
-- Some ops are treated exactly the same as other ops.
-- In the hand-coded C back-end, they might be treated differently
-- for extra performance.
	sequence name
	
	-- set up val
	val = repeat(0, length(SymTab))
	for i = 1 to length(SymTab) do
		val[i] = SymTab[i][S_OBJ] -- might be NOVALUE
	end for
ifdef CALLPROC then

	-- set up operations
	operation = repeat(-1, length(opnames))
	
	for i = 1 to length(opnames) do
		name = opnames[i]
		-- some similar ops are handled by a common routine
		if find(name, {"RHS_SUBS_CHECK", "RHS_SUBS_I"}) then
			name = "RHS_SUBS"
		elsif find(name, {"ASSIGN_SUBS_CHECK", "ASSIGN_SUBS_I"}) then
			name = "ASSIGN_SUBS"
		elsif equal(name, "ASSIGN_I") then
			name = "ASSIGN"
		elsif find(name, {"EXIT", "ENDWHILE", "RETRY"}) then
			name = "ELSE"
		elsif equal(name, "PLUS1_I") then
			name = "PLUS1"      
		elsif equal(name, "PRIVATE_INIT_CHECK") then
			name = "GLOBAL_INIT_CHECK"
		elsif equal(name, "PLUS_I") then
			name = "PLUS"
		elsif equal(name, "MINUS_I") then
			name = "MINUS"
		elsif equal(name, "FOR_I") then
			name = "FOR"
		elsif find(name, {"ENDFOR_UP", "ENDFOR_DOWN", 
						  "ENDFOR_INT_UP", "ENDFOR_INT_DOWN",
						  "ENDFOR_INT_DOWN1"}) then
			name = "ENDFOR_GENERAL"
		elsif equal(name, "CALL_FUNC") then
			name = "CALL_PROC"
		elsif find(name, {"DISPLAY_VAR", "ERASE_PRIVATE_NAMES", 
						  "ERASE_SYMBOL"}) then
			name = "PROFILE"
		elsif equal(name, "SC2_AND") then
			name = "SC2_OR"
		elsif find(name, {"SC2_NULL", "ASSIGN_SUBS2", "PLATFORM",
						  "END_PARAM_CHECK", "NOPWHILE", "NOP1",
						  "PROC_FORWARD", "FUNC_FORWARD",
						  "TRANSGOTO"}) then 
			-- never emitted
			name = "NOP2" 
		elsif equal(name, "GREATER_IFW_I") then
			name = "GREATER_IFW"
		elsif equal(name, "LESS_IFW_I") then
			name = "LESS_IFW"
		elsif equal(name, "EQUALS_IFW_I") then
			name = "EQUALS_IFW"
		elsif equal(name, "NOTEQ_IFW_I") then
			name = "NOTEQ_IFW"
		elsif equal(name, "GREATEREQ_IFW_I") then
			name = "GREATEREQ_IFW"
		elsif equal(name, "LESSEQ_IFW_I") then
			name = "LESSEQ_IFW"
		elsif equal(name, "SWITCH_I") then
			name = "SWITCH"
		end if
		
		operation[i] = routine_id("op" & name)
		if operation[i] = -1 then
			RTInternal("no routine id for op" & name)
		end if
	end for
end ifdef
end procedure

procedure fake_init( integer ignore )
end procedure
mode:set_init_backend( routine_id("fake_init") )

global procedure Execute(symtab_index proc, integer start_index)
-- top level executor 
	InitBackEnd( 0 )
	current_task = 1
	call_stack = {proc}
	pc = start_index
	do_exec()
end procedure

Execute_id = routine_id("Execute")

without warning
procedure BackEnd(atom ignore)
-- The Interpreter back end
	Execute(TopLevelSub, 1)
end procedure
set_backend( routine_id("BackEnd") )

-- dummy routines, not used
global procedure OutputIL()
end procedure

global function extract_options(sequence s)
-- dummy routine, not used by interpreter
	return s
end function

