-- (c) Copyright - See License.txt
--
-- Euphoria
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

ifdef ETYPE_CHECK then
	with type_check
elsedef
	without type_check
end ifdef

include std/convert.e
include std/dll.e
include std/io.e
include std/os.e
include std/pretty.e
include std/text.e
include std/types.e

include global.e
include opnames.e
include error.e
include reswords.e as res
include symtab.e
include scanner.e
include mode.e as mode
include intinit.e
include coverage.e
include emit.e

include std/machine.e as dep
without inline
-- Note: In several places we omit checking for bad arguments to
-- built-in routines. Those errors will be caught by the underlying
-- interpreter or Euphoria run-time system, and an error will be raised
-- against execute.e. To correct this would require a lot of
-- extra code, and would slow things down. It is left as an exercise
-- for the reader. :-)

-- we handle these operations specially because they refer to routine ids
-- in the user program, not the interpreter itself. We can't just let
-- Euphoria do the work.

constant M_CALL_BACK = 52,
		 M_CRASH_ROUTINE = 66,
		 M_CRASH_MESSAGE = 37,
		 M_CRASH_FILE = 57,
		 M_TICK_RATE = 38,
		 M_WARNING_FILE	= 72

constant C_MY_ROUTINE = 1,
		 C_USER_ROUTINE = 2,
		 C_NUM_ARGS = 3

object crash_msg = 0

sequence call_backs, call_back_code, delete_code
symtab_index t_id, t_arglist, t_return_val,
	call_back_routine, delete_code_routine

sequence crash_list = {} -- list of routine id's to call if there's a fatal crash

integer crash_count = 0

-- only need one set of temps for call-backs
t_id = tmp_alloc()
t_arglist = tmp_alloc()
t_return_val = tmp_alloc()

atom arg_assign = 0
function new_arg_assign()
	arg_assign += 1
	return arg_assign
end function

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


delete_code_routine = NewEntry("_delete_object_", 0, 0, PROC, 0, 0, 0)
SymTab[delete_code_routine] = SymTab[delete_code_routine] &
							repeat(0, SIZEOF_ROUTINE_ENTRY -
							length(SymTab[delete_code_routine]))

SymTab[delete_code_routine][S_SAVED_PRIVATES] = {}

delete_code = {CALL_PROC,
				  t_id,
				  t_arglist,

				  CALL_BACK_RETURN
				 }

SymTab[delete_code_routine][S_CODE] = delete_code

integer TraceOn
TraceOn = FALSE

integer pc=-1, a, b, c, d, target, len, keep_running
integer lhs_seq_index -- index of lhs sequence
sequence lhs_subs -- first n-1 LHS subscripts before final subscript or slice
sequence val=""

constant TASK_NEVER = 1e300
constant TASK_ID_MAX = 9e15 -- wrap to 0 after this (and avoid in-use ones)
boolean id_wrap = FALSE     -- have task id's wrapped around? (very rare)

integer current_task=-1  -- internal number of currently-executing task
sequence call_stack=""   -- active subroutine call stack
-- At each subroutine call we push two items:
-- 1. the return pc value
-- 2. the current subroutine index

atom next_task_id = 1 -- for multitasking
next_task_id = 1

atom clock_period = 0.01 -- Non DOS
-- TCB fields
constant TASK_RID = 1,      -- routine id
		 TASK_TID = 2,      -- external task id
		 TASK_TYPE = 3,     -- type of task: T_REAL_TIME or T_TIME_SHARED
		 TASK_STATE = 4,   -- status: ST_ACTIVE, ST_SUSPENDED, ST_DEAD
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

-- task control block for real-time and time-shared task
sequence tcb = {
	-- initial "top-level" task, tid=0
	{
		-1, 0, T_TIME_SHARE, ST_ACTIVE, 0, 0, 0, 1, 1, 1, 1, 0, {}, 1, {}, {}
	}
}

integer
	rt_first = 0, -- unsorted list of active rt tasks
	ts_first = 1  -- unsorted list of active ts tasks (initialized to initial task)

sequence e_routine = {} -- list of routines with a routine id assigned to them
integer err_file
sequence err_file_name = "ex.err"


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
	return {known_files[slist[gline][LOCAL_FILE_NO]], slist[gline][LINE]}
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

procedure save_private_block(symtab_index rtn_idx, sequence block)
-- save block for resident task on the private list for this routine
-- reuse any empty spot
-- save in last-in, first-out order
-- We use a linked list to mirror the C-coded backend
	sequence saved, saved_list, eentry
	integer task, spot, tn

	task = SymTab[rtn_idx][S_RESIDENT_TASK]
	-- save it
	eentry = {task, tcb[task][TASK_TID], block, 0}
	saved = SymTab[rtn_idx][S_SAVED_PRIVATES]

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

	SymTab[rtn_idx][S_SAVED_PRIVATES] = saved
end procedure

function load_private_block(symtab_index rtn_idx, integer task)
-- retrieve a private block and remove it from the list for this routine
-- (we know that the block must be there)
	sequence saved, saved_list, block
	integer p, prev_p, first

	saved = SymTab[rtn_idx][S_SAVED_PRIVATES]
	first = saved[1]
	p = first -- won't be 0
	prev_p = -1
	saved_list = saved[2]
	while TRUE do
		if saved_list[p][SP_TASK_NUMBER] = task then
			-- won't be for old dead task, must be current
			block = saved_list[p][SP_BLOCK]
			saved_list[p][SP_TASK_NUMBER] = -1 -- mark it as deleted
			saved_list[p][SP_BLOCK] = {}
			if prev_p = -1 then
				first = saved_list[p][SP_NEXT]
			else
				saved_list[prev_p][SP_NEXT] = saved_list[p][SP_NEXT]
			end if
			saved[1] = first
			saved[2] = saved_list
			SymTab[rtn_idx][S_SAVED_PRIVATES] = saved
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
			-- save privates
			while arg != 0 
			and (SymTab[arg][S_SCOPE] <= SC_PRIVATE 
				or SymTab[arg][S_SCOPE] = SC_LOOP_VAR
				or SymTab[arg][S_SCOPE] = SC_UNDEFINED) do
				
				if SymTab[arg][S_SCOPE] != SC_UNDEFINED then
					private_block = append(private_block, val[arg])
				end if
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
		while arg != 0 
		and (SymTab[arg][S_SCOPE] <= SC_PRIVATE 
			or SymTab[arg][S_SCOPE] = SC_LOOP_VAR
			or SymTab[arg][S_SCOPE] = SC_UNDEFINED) do
			
			if SymTab[arg][S_SCOPE] != SC_UNDEFINED then
				val[arg] = private_block[base]
				base += 1
			end if
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

			elsif sub != call_back_routine and sub != delete_code_routine then
				both_puts("... called from ")
				-- pc points to statement after the subroutine call
			end if

			if sub = call_back_routine then
				if crash_count > 0 then
					both_puts("^^^ called to handle run-time crash\n")
					exit
				else
					both_puts("^^^ call-back from ")
					ifdef WINDOWS then
						both_puts("Windows\n")
					elsedef
						both_puts("external program\n")
					end ifdef
				end if
			elsif sub = delete_code_routine then
				both_puts("^^^ delete routine\n")

			else
				both_printf("%s:%d", find_line(sub, pc))

				if not equal(SymTab[sub][S_NAME], "<TopLevel>") then
					switch SymTab[sub][S_TOKEN] do
						case PROC then
							both_puts(" in procedure ")

						case FUNC then
							both_puts(" in function ")

						case TYPE then
							both_puts(" in type ")

						case else
							RTInternal("SymTab[sub][S_TOKEN] is not a routine")

					end switch

					both_printf("%s()", {SymTab[sub][S_NAME]})
				end if

				both_puts("\n")

				if show_message then
					if sequence(crash_msg) then
						clear_screen()
						puts(2, crash_msg)
					end if
					both_puts(msg & " \n")
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
					SymTab[v][S_SCOPE] = SC_LOOP_VAR or
					SymTab[v][S_SCOPE] = SC_UNDEFINED) do
					if SymTab[v][S_SCOPE] != SC_UNDEFINED then
						show_var(v)
					end if

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

		tcb[current_task][TASK_STATE] = ST_DEAD -- mark as "deleted"

		-- choose next task to display
		task = current_task
		for i = 1 to length(tcb) do
			if tcb[i][TASK_STATE] != ST_DEAD and
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
				puts(err_file, "\n " & known_files[prev_file_no] & ":\n")
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
	write_coverage_db()
	
	ifdef WINDOWS then
		if not batch_job and not test_only then
			puts(2, "\nPress Enter...\n")
			getc(0)
		end if
	end ifdef

	abort(1)
end procedure

procedure RTFatalType(integer x, integer member = 0 )
-- handle a fatal run-time type-check error
	sequence msg, v
	sequence vname

	open_err_file()
	a = Code[x]
	if length(SymTab[a]) >= S_NAME then
		vname = SymTab[a][S_NAME]

	else
		vname = "inlined variable"
	end if
	msg = sprintf("type_check failure, %s is ", {vname})
	if member then
		a = member
	end if
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
			new_arg_assign()
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

	if tcb[current_task][TASK_STATE] = ST_ACTIVE then
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
	tcb[task][TASK_STATE] = ST_DEAD
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
			if tcb[t][TASK_STATE] = ST_ACTIVE then
				r = 1
			elsif tcb[t][TASK_STATE] = ST_SUSPENDED then
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
		if tcb[i][TASK_STATE] != ST_DEAD then
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
	tcb[task][TASK_STATE] = ST_SUSPENDED
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
		if tcb[i][TASK_STATE] = ST_DEAD then
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
			  tcb[task][TASK_STATE] = ST_SUSPENDED then
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
			  tcb[task][TASK_STATE] = ST_SUSPENDED then
			rt_first = task_insert(rt_first, task)
		end if
		tcb[task][TASK_TYPE] = T_REAL_TIME
	end if
	tcb[task][TASK_STATE] = ST_ACTIVE
	pc += 3
end procedure


file trace_file
trace_file = -1

integer trace_line
trace_line = 0

procedure one_trace_line(sequence line)
-- write one fixed-width 79-char line to ctrace.out
	ifdef UNIX then
		printf(trace_file, "%-78.78s\n", {line})
	elsedef
		printf(trace_file, "%-77.77s\r\n", {line})
	end ifdef
end procedure

procedure opCOVERAGE_LINE()
	cover_line( Code[pc+1] )
	pc += 2
end procedure

procedure opCOVERAGE_ROUTINE()
	cover_routine( Code[pc+1] )
	pc += 2
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
					   {name_ext(known_files[slist[a][LOCAL_FILE_NO]]),
						slist[a][LINE],
						line})
		trace_line += 1
		if trace_line >= 5000 then
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

procedure opPROC_TAIL()
	integer arg, sub

	sub = Code[pc+1] -- subroutine
	arg = SymTab[sub][S_NEXT]

	-- set the param values
	for i = 1 to SymTab[sub][S_NUM_ARGS] do
		val[arg] = val[Code[pc+1+i]]
		arg = SymTab[arg][S_NEXT]
	end for

	-- free the temps
	while arg and SymTab[arg][S_SCOPE] <= SC_PRIVATE do
		val[arg] = NOVALUE
		arg = SymTab[arg][S_NEXT]
	end while

	-- start over!
	pc = 1
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
		while arg != 0 
		and (SymTab[arg][S_SCOPE] <= SC_PRIVATE 
			or SymTab[arg][S_SCOPE] = SC_LOOP_VAR
			or SymTab[arg][S_SCOPE] = SC_UNDEFINED) do
			
			if SymTab[arg][S_SCOPE] != SC_UNDEFINED then
				private_block[p] = val[arg]
				p += 1
				val[arg] = NOVALUE  -- necessary?
			end if
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

procedure exit_block( symtab_index block )
	integer a = SymTab[block][S_NEXT_IN_BLOCK]
	while a do

		ifdef DEBUG then
			sequence name
			if length( SymTab[a] ) >= S_NAME then
				name = sym_name( a )
			else
				name = "temp"
			end if
-- 			printf(2, "\tEXIT_BLOCK[%s] resetting [%d][%s][%s]\n", {sym_name( block ), a, name, pretty_sprint( val[a] )})
		end ifdef
		val[a] = NOVALUE

		a = SymTab[a][S_NEXT_IN_BLOCK]
	end while
end procedure

procedure opEXIT_BLOCK()
	exit_block( Code[pc+1] )
	pc += 2
end procedure

procedure opRETURNP()
-- return from procedure (or function)
	symtab_index arg, sub, caller
	integer op = Code[pc]
	sub = Code[pc+1]

	-- set sub privates to NOVALUE -- necessary? - we do it at routine entry
	symtab_index block = Code[pc+2]
	symtab_index sub_block = SymTab[sub][S_BLOCK]

	integer local_result = result
	object local_result_val
	if local_result then
		result = 0
		local_result_val = result_val
		result_val = NOVALUE
	end if

	while block != sub_block do
		if local_result then
			exit_block( block )
		end if
		block = SymTab[block][S_BLOCK]
	end while

	exit_block( sub_block )
-- 	if local_result or op = RETURNP then
-- 		exit_block( block )
-- 	elsif Code[pc] = RETURNP then
-- 		printf( 1, "not exiting RETURNP block for %s\n", { sym_name(sub) })
-- 	end if

	-- set up for caller
	pc = call_stack[$-1]
	call_stack = call_stack[1..$-2]

	SymTab[sub][S_RESIDENT_TASK] = 0

	if length(call_stack) then
		caller = call_stack[$]
		Code = SymTab[caller][S_CODE]
		restore_privates(caller)
		if local_result then
			val[Code[local_result]] = local_result_val
		end if
	else
		kill_task(current_task)
		scheduler()
	end if


end procedure

procedure opRETURNF()
-- return from function
	result_val = val[Code[pc+3]]
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
	integer a = Code[pc+1]
	target = Code[pc+2]
	val[target] = val[a]
	if sym_mode( a ) = M_TEMP then
		val[a] = NOVALUE
	end if
	pc += 3
end procedure

procedure opMEMSTRUCT_ASSIGN()
	atom pointer = val[Code[pc+1]]
	integer struct_sym = Code[pc+2]
	object source_val = val[Code[pc+3]]
	integer tok
	if SymTab[struct_sym][S_MEM_POINTER] then
		tok = MS_MEMBER
	else
		tok = sym_token( struct_sym )
	end if
	
	switch tok do
		case MEMSTRUCT then
			write_memstruct( pointer, struct_sym, source_val )
		case MEMUNION then
			poke( pointer, source_val & repeat( 0, SymTab[struct_sym][S_MEM_SIZE] - length( source_val ) ) )
		case else
			poke_member( pointer, struct_sym, source_val )
	end switch
	pc += 4
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
		if sym_mode( Code[i] ) = M_TEMP then
			val[Code[i]] = NOVALUE
		end if
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
	if sym_mode( Code[pc+2] ) = M_TEMP then
		val[Code[pc+2]] = NOVALUE
	end if
	if sym_mode( Code[pc+1] ) = M_TEMP then
		val[Code[pc+1]] = NOVALUE
	end if
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
		RTFatal("variable " & SymTab[a][S_NAME] & " has not been assigned a value")
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
		a = val[Code[pc+1]] - Code[pc+2]
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

procedure opSWITCH_RT()
-- Analyze the values, and update to the appropriate type of switch
-- Then call it

-- pc+1: switch value
-- pc+2: case values
-- pc+3: jump_table
-- pc+4: else jump

	sequence values = val[Code[pc+2]]
	integer all_ints = 1
	integer max = MININT
	integer min = MAXINT
	for i = 1 to length( values ) do
		integer sym = values[i]
		integer sign = 1
		if sym < 0 then
			sign = -1
			sym = -sym
		end if
		if equal(val[sym], NOVALUE) then
			RTFatal( sprintf( "'%s' has not been assigned a value", {SymTab[sym][S_NAME]} ) )
		end if
		object new_value = sign * val[sym]
		values[i] = new_value
		if not integer( new_value ) then
			all_ints = 0

		elsif all_ints then
			if new_value < min then
				min = new_value
			end if

			if new_value > max then
				max = new_value
			end if
		end if
	end for

	if all_ints and max - min < 1024 then
		Code[pc] = SWITCH_SPI

		sequence jump = val[Code[pc+3]]
		sequence switch_table = repeat( Code[pc+4] - pc, max - min + 1 )
		integer offset = min - 1
		for i = 1 to length( values ) do
			switch_table[values[i] - offset] = jump[i]
		end for
		Code[pc+2] = offset

		val = append( val, switch_table )
		Code[pc+3] = length(val)

		SymTab[call_stack[$]][S_CODE] = Code
		opSWITCH_SPI()
	else
		Code[pc] = SWITCH
		val = append( val, values )
		Code[pc+2] = length(val)

		SymTab[call_stack[$]][S_CODE] = Code
		opSWITCH()
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
	lhs_subs = {}
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
	if upper > #FFFF_FFFF then
		upper = -2147483645
	end if
	if upper < 0 then
		RTFatal(sprintf("slice upper index is less than 0 (%d)", upper ) )
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
	lhs_subs = {}
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
	lhs_subs = {}
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
	lhs_subs = {}
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
	lhs_subs = {}
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

procedure opMEM_TYPE_CHECK()
-- type check for a user-defined type
-- this always follows a type-call
	if val[Code[pc-1]] = 0 then
		RTFatalType(pc + 1, Code[pc - 2])
	end if
	pc += 2
end procedure


procedure kill_temp( symtab_index sym )
	if sym_mode( sym ) = M_TEMP then
		val[sym] = NOVALUE
	end if
end procedure

procedure opIS_AN_INTEGER()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = integer(val[a])
	kill_temp( a )
	pc += 3
end procedure

procedure opIS_AN_ATOM()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = atom(val[a])
	kill_temp( a )
	pc += 3
end procedure

procedure opIS_A_SEQUENCE()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = sequence(val[a])
	kill_temp( a )
	pc += 3
end procedure

procedure opIS_AN_OBJECT()
	a = Code[pc+1]
	target = Code[pc+2]
	if equal( val[a], NOVALUE ) then
		val[target] = 0
	else
		val[target] = object( val[a] )
	end if

	kill_temp( a )
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

	if sequence( val[a] ) or sequence( val[b] ) then
		RTFatal("true/false condition must be an ATOM")
	end if
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

procedure opMEMSTRUCT_ASSIGN_OP()
	atom pointer = val[Code[pc+1]]
	atom v = peek_member( pointer, Code[pc+2] )
	atom x = val[Code[pc+3]]
	switch Code[pc] do
		case MEMSTRUCT_PLUS then
			v += x
		case MEMSTRUCT_MINUS then
			v -= x
		case MEMSTRUCT_DIVIDE then
			v /= x
		case MEMSTRUCT_MULTIPLY then
			v *= x
	end switch
	poke_member( pointer, Code[pc+2], v )
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

function RTLookup(sequence name, integer file, symtab_index proc, integer stlen )
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

	stlen = length( SymTab )
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
		while s != 0 do
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

		ns_file = val[s]

		-- trim off any leading whitespace from name
		while length(name) and (name[1] = ' ' or name[1] = '\t') do
			name = name[2..$]
		end while

		-- step 2: find global name in ns file
		s = SymTab[TopLevelSub][S_NEXT]
		while s != 0 and (s <= stlen or SymTab[s][S_SCOPE] = SC_PRIVATE) do
			integer scope = SymTab[s][S_SCOPE]
			if (((scope = SC_PUBLIC) and
					(SymTab[s][S_FILE_NO] = ns_file
					 or ( and_bits( PUBLIC_INCLUDE, include_matrix[ns_file][SymTab[s][S_FILE_NO]] ) and
					      and_bits( DIRECT_OR_PUBLIC_INCLUDE, include_matrix[file][ns_file] ) ) ))
				or
				(scope = SC_EXPORT and SymTab[s][S_FILE_NO] = ns_file
				    and and_bits( DIRECT_INCLUDE, include_matrix[file][ns_file]) )
				or
				(scope = SC_GLOBAL) and
					(SymTab[s][S_FILE_NO] = ns_file
					 or ( include_matrix[ns_file][SymTab[s][S_FILE_NO]] and
					      and_bits( DIRECT_OR_PUBLIC_INCLUDE, include_matrix[file][ns_file] ) ) )
				or
				(scope = SC_LOCAL and ns_file = file))
			and equal( SymTab[s][S_NAME], name )
			then
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

		while s != 0 and (s <= stlen or SymTab[s][S_SCOPE] = SC_PRIVATE) do

			if SymTab[s][S_FILE_NO] = file and
				(SymTab[s][S_SCOPE] = SC_LOCAL or
				 SymTab[s][S_SCOPE] = SC_GLOBAL or
				 SymTab[s][S_SCOPE] = SC_EXPORT or
				(proc = TopLevelSub and SymTab[s][S_SCOPE] = SC_GLOOP_VAR)) and
				equal(name, SymTab[s][S_NAME])
				then
				-- shouldn't really be able to see GLOOP_VARs unless we are
				-- currently inside the loop - only affects interactive var display
				return s
			end if
			s = SymTab[s][S_NEXT]
		end while
		-- try to match a single earlier GLOBAL or EXPORT symbol
		global_found = FALSE
		s = SymTab[TopLevelSub][S_NEXT]
		while s != 0 and (s <= stlen or SymTab[s][S_SCOPE] = SC_PRIVATE) do
			if SymTab[s][S_SCOPE] = SC_GLOBAL and
			   equal(name, SymTab[s][S_NAME]) then

				s_in_include_path = include_matrix[file][SymTab[s][S_FILE_NO]] != 0
				if s_in_include_path then
					global_found = s
					found_in_path += 1
				else
					if not found_in_path then
						global_found = s
					end if
					found_outside_path += 1
				end if
			elsif (sym_scope( s ) = SC_PUBLIC and equal( name, SymTab[s][S_NAME] ) and
			and_bits( DIRECT_OR_PUBLIC_INCLUDE, include_matrix[file][SymTab[s][S_FILE_NO]] )) or
			(sym_scope( s ) = SC_EXPORT and equal( name, SymTab[s][S_NAME] ) and
			and_bits( DIRECT_INCLUDE, include_matrix[file][SymTab[s][S_FILE_NO]] ) ) then

				global_found = s
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

procedure do_call_proc( symtab_index sub, sequence args, integer advance )
	integer n, arg

	n = SymTab[sub][S_NUM_ARGS]
	arg = SymTab[sub][S_NEXT]
	if SymTab[sub][S_RESIDENT_TASK] != 0 then
		-- save the parameters, privates and temps

		-- save and set the args
		sequence private_block = repeat(0, SymTab[sub][S_STACK_SPACE])
		integer p = 1
		for i = 1 to n do
			private_block[p] = val[arg]
			p += 1
			val[arg] = args[i]
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
			val[arg] = args[i]
			arg = SymTab[arg][S_NEXT]
		end for
	end if

	SymTab[sub][S_RESIDENT_TASK] = current_task

	pc += advance

	call_stack = append(call_stack, pc)
	call_stack = append(call_stack, sub)

	Code = SymTab[sub][S_CODE]
	pc = 1
end procedure

procedure opCALL_PROC()
-- CALL_PROC, CALL_FUNC - call via routine id
	integer cf
	symtab_index sub

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

	do_call_proc( sub, val[b], 3 + cf )
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
	if p = 0 or not find(SymTab[p][S_TOKEN], RTN_TOKS) then
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
				RTFatal(sprintf("index (%d) out of bounds in match_from()", c ))
				pc += 5
				return
		end if
		if not (length(s) = 0 and c = 1) and c > length(s) + 1 then
				RTFatal(sprintf("index (%d) out of bounds in match_from()", c ))
				pc += 5
				return
		end if
		val[target] = match( val[a], s, c )
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

procedure opPEEK8U()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = peek8u(val[a])
	pc += 3
end procedure

procedure opPEEK8S()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = peek8s(val[a])
	pc += 3
end procedure

procedure opPEEK_POINTER()
	a = Code[pc+1]
	target = Code[pc+2]
	val[target] = peek_pointer(val[a])
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

procedure opSIZEOF()
	a = Code[pc+1]
	b = Code[pc+2]
	integer id = sym_token( a )
	switch id do
		case MEMSTRUCT, MEMUNION, MS_MEMBER, MEMTYPE then
			val[b] = SymTab[a][S_MEM_SIZE]
		case MS_CHAR       then val[b] = sizeof( char )
		case MS_SHORT      then val[b] = sizeof( short )
		case MS_INT        then val[b] = sizeof( int )
		case MS_LONG       then val[b] = sizeof( long )
		case MS_LONGLONG   then val[b] = sizeof( long long )
		case MS_OBJECT     then val[b] = sizeof( object ) 
		case MS_FLOAT      then val[b] = sizeof( float )
		case MS_DOUBLE     then val[b] = sizeof( double )
		case MS_LONGDOUBLE then val[b] = sizeof( long double )
		case MS_EUDOUBLE   then val[b] = sizeof( eudouble )
		case else
			val[b] = sizeof( val[a] )
	end switch
	
	pc += 3
end procedure

procedure opOFFSETOF()
	a = Code[pc+1]
	b = Code[pc+2]
	val[b] = SymTab[a][S_MEM_OFFSET]
	pc += 3
end procedure

procedure opADDRESSOF()
	a = Code[pc+1]
	b = Code[pc+2]
	val[b] = val[a]
	pc += 3
end procedure

procedure opMEMSTRUCT_ACCESS()
	-- pc+1 number of accesses
	-- pc+2 pointer to memstruct
	-- pc+2 .. pc+n+1 member syms for access
	-- pc+n+2 target for pointer
	
	a = Code[pc + 1]
	b = pc + 2 + a -- the last member
	
	atom ptr = val[Code[pc+2]]
	for i = pc+3 to b do
		ptr += SymTab[Code[i]][S_MEM_OFFSET]
		if SymTab[Code[i]][S_MEM_POINTER] and i < b then
			ptr = peek_pointer( ptr )
		end if
	end for
	val[Code[b+1]] = ptr
	pc = b + 2
end procedure

procedure opMEMSTRUCT_ARRAY()
	-- pc+1 pointer
	-- pc+2 member sym
	-- pc+3 subscript
	-- pc+4 target
	atom    ptr  = val[Code[pc+1]]
	integer size = SymTab[Code[pc+2]][S_MEM_SIZE]
	ptr += val[Code[pc+3]] * size
	val[Code[pc+4]] = ptr
	pc += 5
end procedure

procedure opPEEK_ARRAY()
	-- pc+1 pointer
	-- pc+2 member sym
	-- pc+3 subscript
	-- pc+4 target
	atom 
		ptr        = val[Code[pc+1]],
		member_sym = Code[pc+2],
		subscript  = val[Code[pc+3]]
	
	val[Code[pc+4]] = peek_member( ptr, member_sym, subscript )
	pc += 5
end procedure

procedure poke_member_value( atom pointer, integer data_type, object value )
	switch data_type do
		case MS_CHAR then
			poke( pointer, value )
		case MS_SHORT then
			poke2( pointer, value )
		case MS_INT then
			poke4( pointer, value )
		case MS_LONG then
			ifdef WINDOWS then
				poke4( pointer )
			elsedef
				poke_pointer( pointer, value )
			end ifdef
		case MS_LONGLONG then
			poke8( pointer, value )
		case MS_OBJECT then
			poke_pointer( pointer, value )
		case MS_FLOAT then
			poke( pointer, atom_to_float32( value ) )
		case MS_DOUBLE then
			poke( pointer, atom_to_float64( value ) )
		case MS_LONGDOUBLE then
			poke( pointer, atom_to_float80( value ) )
		case MS_EUDOUBLE then
			if sizeof( C_POINTER ) = 4 then
				poke( pointer, atom_to_float64( value ) )
			else
				poke( pointer, atom_to_float80( value ) )
			end if
		case else
			-- just return the struct in bytes
			RTFatal( "Error assigning to a memstruct -- can only assign primitive data members" )
	end switch
end procedure

procedure poke_member( atom pointer, integer sym, object value )
	integer data_type = SymTab[sym][S_TOKEN]
	integer signed    = SymTab[sym][S_MEM_SIGNED]
	
	if SymTab[sym][S_MEM_POINTER] then
		data_type = MS_OBJECT
		signed    = 0
	end if
	
	if SymTab[sym][S_MEM_ARRAY] then
		integer array_length = SymTab[sym][S_MEM_ARRAY]
		integer max = array_length
		integer size = SymTab[sym][S_MEM_SIZE] / array_length
		if array_length < length( value ) then
			max = length( value )
		end if
		for i = 1 to max do
			poke_member_value( pointer, data_type, value[i] )
			pointer += size
		end for
		for i = max + 1 to array_length do
			poke_member_value( pointer, data_type, 0 )
			pointer += size
		end for
	else
		poke_member_value( pointer, data_type, value )
	end if
	
end procedure

procedure write_memstruct( atom pointer, integer sym, object value )
	if atom( value ) then
		value = {value}
	end if
	
	integer member = SymTab[sym][S_MEM_NEXT]
	
	for i = 1 to length( value ) do
		
		if not member then
			exit
		end if
		poke_member( pointer + SymTab[member][S_MEM_OFFSET], member, value[i] )
		
		member = SymTab[member][S_MEM_NEXT]
		
	end for
	
	-- zero out the rest
	integer ix = length( value ) + 1
	while member do
		poke_member( pointer + SymTab[member][S_MEM_OFFSET], member, 0 )
		
		member = SymTab[member][S_MEM_NEXT]
	end while
end procedure

function peek_member( atom pointer, integer sym, integer array_index = -1 )
	integer data_type = SymTab[sym][S_TOKEN]
	integer signed    = SymTab[sym][S_MEM_SIGNED]
	
	if SymTab[sym][S_MEM_POINTER] then
		data_type = MS_OBJECT
		signed    = 0
	
	elsif array_index != -1 then
		integer element_size = SymTab[sym][S_MEM_SIZE] / SymTab[sym][S_MEM_ARRAY]
		pointer += element_size * array_index
	
	elsif SymTab[sym][S_MEM_ARRAY] then
		sequence s = repeat( 0, SymTab[sym][S_MEM_ARRAY] )
		for i = 1 to SymTab[sym][S_MEM_ARRAY] do
			s[i] = peek_member( pointer, sym, i-1)
		end for
		return s
	end if
	
	switch data_type do
		case MS_CHAR then
			if signed then
				return peeks( pointer )
			else
				return peek( pointer )
			end if
		case MS_SHORT then
			if signed then
				return peek2s( pointer )
			else
				return peek2u( pointer )
			end if
		case MS_INT then
			if signed then
				return peek4s( pointer )
			else
				return peek4u( pointer )
			end if
		case MS_LONG then
			ifdef WINDOWS then
				if signed then
					return peek4s( pointer )
				else
					return peek4u( pointer )
				end if
			elsedef
				if sizeof( C_LONG ) = 4 then
					if signed then
						return peek4s( pointer )
					else
						return peek4u( pointer )
					end if
				else
					if signed then
						return peek8s( pointer )
					else
						return peek8u( pointer )
					end if
				end if
			end ifdef
		case MS_LONGLONG then
			if signed then
				return peek8s( pointer )
			else
				return peek8u( pointer )
			end if
		case MS_OBJECT then
			if sizeof( C_POINTER ) = 4 then
				if signed then
					return peek4s( pointer )
				else
					return peek4u( pointer )
				end if
			else
				if signed then
					return peek8s( pointer )
				else
					return peek8u( pointer )
				end if
			end if
		case MS_FLOAT then
			return float32_to_atom( peek( { pointer, 4 } ) )
		case MS_DOUBLE then
			return float64_to_atom( peek( { pointer, 8 } ) )
		case MS_LONGDOUBLE then
			return float80_to_atom( peek( { pointer, 10 } ) )
		case MS_EUDOUBLE then
			if sizeof( C_POINTER ) = 4 then
				return float64_to_atom( peek( { pointer, 8 } ) )
			else
				return float80_to_atom( peek( { pointer, 10 } ) )
			end if
		case else
			-- just return the struct in bytes
			return read_member( pointer, sym )
	end switch
end function

function read_memstruct( atom pointer, symtab_pointer member_sym )
	sequence s = {}
	if sym_token( member_sym ) != MEMSTRUCT then
		-- we want to walk the actual struct
		member_sym = SymTab[member_sym][S_MEM_STRUCT]
	end if
	while member_sym with entry do
		s = append( s, peek_member( pointer + SymTab[member_sym][S_MEM_OFFSET], member_sym ) )
	entry
		member_sym = SymTab[member_sym][S_MEM_NEXT]
	end while
	return s
end function

function read_memunion( atom pointer, symtab_pointer member_sym )
	return peek( { pointer, SymTab[member_sym][S_MEM_SIZE] } )
end function

function read_member( atom pointer, symtab_index sym )

	symtab_pointer member_sym = sym
	integer tid = sym_token( sym )
	if tid >= MS_SIGNED and tid <= MS_OBJECT then
		-- simple serialization of primitives...
		return peek_member( pointer, sym )
	end if
	
	integer member_token = sym_token( member_sym )
	if member_token = MEMSTRUCT then
		return read_memstruct( pointer, member_sym )
	
	elsif member_token = MEMUNION then
		return read_memunion( pointer, member_sym )
	
	else
		member_token = SymTab[SymTab[member_sym][S_MEM_STRUCT]][S_TOKEN]
		if member_token = MEMSTRUCT then
			return read_memstruct( pointer, member_sym )
		
		elsif member_token = MEMUNION then
			return read_memunion( pointer, member_sym )
		else
			RTFatal( "Cannot serialize a: " & LexName( member_token ) )
		end if
	end if
end function

procedure opMEMSTRUCT_READ()
	atom pointer = val[Code[pc+1]]
	val[Code[pc+3]] = read_member( pointer, Code[pc+2] )
	pc += 4
end procedure

procedure opPEEK_MEMBER()
	-- pc+1 pointer
	-- pc+2 member
	-- pc+3 target
	
	atom pointer = val[Code[pc+1]]
	a = Code[pc+2]
	target = Code[pc+3]
	
	val[target] = peek_member( pointer, a )
	
	pc += 4
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

procedure opPOKE8()
	a = Code[pc+1]
	b = Code[pc+2]
	poke8(val[a], val[b])
	pc += 3
end procedure

procedure opPOKE_POINTER()
	a = Code[pc+1]
	b = Code[pc+2]
	poke_pointer(val[a], val[b])
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
	c = Code[pc+3]
	target = Code[pc+4]

	if atom(val[b]) or length(val[b]) > 2 then
	   RTFatal("invalid open mode")
	end if
	if atom(val[a]) then
	   RTFatal("device or file name must be a sequence")
	end if
	if not atom(val[c]) then
		RTFatal("cleanup must be an atom")
	end if
	val[target] = open(val[a], val[b], val[c])
	pc += 5
end procedure

procedure opCLOSE()
	a = Code[pc+1]
	close(val[a])
	pc += 2
end procedure

procedure opABORT()
	Cleanup(val[Code[pc+1]])
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
	? val[a]
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

function general_callback(sequence rtn_def, sequence args)
-- call the user's function from an external source
-- (interface for Euphoria-coded call-backs)

	val[t_id] = rtn_def[C_USER_ROUTINE]
	val[t_arglist] = args
	atom arglist_assign = new_arg_assign()

	SymTab[call_back_routine][S_RESIDENT_TASK] = current_task

	-- create a stack frame
	call_stack = append(call_stack, pc)
	call_stack = append(call_stack, call_back_routine)

	Code = call_back_code
	pc = 1

	do_exec()

	-- remove the stack frame
	pc = call_stack[$-1]
	call_stack = call_stack[1..$-2]

	if arglist_assign = arg_assign then
		val[t_arglist] = NOVALUE
	end if
	-- restore
	Code = SymTab[call_stack[$]][S_CODE]

	return val[t_return_val]
end function

forward_general_callback = routine_id("general_callback")

function machine_callback(atom cbx, atom ptr)
-- call the user's function from an external source
-- (interface for machine-coded call-backs)
	sequence rtn_def, args

	rtn_def = call_backs[cbx]
	args = peek4u(ptr & call_backs[cbx][C_NUM_ARGS])

	return general_callback(rtn_def, args)
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

-- osx_cdecl assembly
-- output generated by otool
/*
00000000	pushl	%ebp
00000001	movl	%esp,%ebp
00000003	subl	$0x48,%esp
00000006	movl	$0xf001f001,0xf4(%ebp)
0000000d	movl	0x08(%ebp),%eax
00000010	movl	%eax,0xcc(%ebp)
00000013	movl	0x0c(%ebp),%eax
00000016	movl	%eax,0xd0(%ebp)
00000019	movl	0x10(%ebp),%eax
0000001c	movl	%eax,0xd4(%ebp)
0000001f	movl	0x14(%ebp),%eax
00000022	movl	%eax,0xd8(%ebp)
00000025	movl	0x18(%ebp),%eax
00000028	movl	%eax,0xdc(%ebp)
0000002b	movl	0x1c(%ebp),%eax
0000002e	movl	%eax,0xe0(%ebp)
00000031	movl	0x20(%ebp),%eax
00000034	movl	%eax,0xe4(%ebp)
00000037	movl	0x24(%ebp),%eax
0000003a	movl	%eax,0xe8(%ebp)
0000003d	movl	0x28(%ebp),%eax
00000040	movl	%eax,0xec(%ebp)
00000043	leal	0xcc(%ebp),%eax
00000046	movl	%eax,0x04(%esp)
0000004a	movl	$0x12345678,(%esp)
00000051	movl	0xf4(%ebp),%eax
00000054	call	*%eax
00000056	movl	%eax,0xf0(%ebp)
00000059	movl	0xf0(%ebp),%eax
0000005c	leave
0000005d	ret
*/
-- osx_cdecl original c code
/*
unsigned osx_cdecl_call_back(unsigned arg1, unsigned arg2, unsigned arg3,
						unsigned arg4, unsigned arg5, unsigned arg6,
						unsigned arg7, unsigned arg8, unsigned arg9)
{
	// a dummy where CallBack will later assign the value of general_ptr
	// this saves us the trouble of trying to calculate the offset of
	// the callback copy from general_ptr and stuffing that into a LEA
	// calculation
	unsigned ret;
	unsigned (*f)(unsigned, unsigned)
	= (unsigned (*)(unsigned, unsigned)) 0xF001F001;
	unsigned j[9];
	j[0] = arg1;
	j[1] = arg2;
	j[2] = arg3;
	j[3] = arg4;
	j[4] = arg5;
	j[5] = arg6;
	j[6] = arg7;
	j[7] = arg8;
	j[8] = arg9;
	ret = (f)((unsigned)0x12345678,j);
	return ret;
}
*/
constant osx_cdecl =
{#55, #89, #e5, #83, #ec, #48, #c7, #45, #f4, #01, #f0, #01, #f0, #8b, #45, #08,
#89, #45, #cc, #8b, #45, #0c, #89, #45, #d0, #8b, #45, #10, #89, #45, #d4, #8b,
#45, #14, #89, #45, #d8, #8b, #45, #18, #89, #45, #dc, #8b, #45, #1c, #89, #45,
#e0, #8b, #45, #20, #89, #45, #e4, #8b, #45, #24, #89, #45, #e8, #8b, #45, #28,
#89, #45, #ec, #8d, #45, #cc, #89, #44, #24, #04, #c7, #04, #24, #78, #56, #34,
#12, #8b, #45, #f4, #ff, #d0, #89, #45, #f0, #8b, #45, #f0, #c9, #c3}

function callback(object a)
	return machine_func(M_CALL_BACK, a)
end function
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
		asm = dep:allocate_protect(length(cb_std), 1, PAGE_EXECUTE_READWRITE)
		poke( asm, cb_std )
		poke4( asm + 7, length(call_backs) + 1 )
		poke4( asm + 13, asm + 20 )
		poke( asm + 18, SymTab[r][S_NUM_ARGS] * 4 )
		poke4( asm + 20, callback( routine_id("machine_callback") ) )
	elsif platform() = OSX then
		asm = dep:allocate_protect(length(osx_cdecl), 1, PAGE_EXECUTE_READWRITE)
		poke(asm, osx_cdecl)
		-- the more complex machine code handles passing the arguments
		-- on the stack for us, we just need to tell it the machine
		-- callback address and the routine id
		if match({#78, #56, #34, #12}, osx_cdecl) then
			poke4(asm + match({#78, #56, #34, #12}, osx_cdecl) - 1,
			length(call_backs) + 1 )
		end if
		if match({#01, #f0, #01, #f0}, osx_cdecl) then
			poke4(asm + match({#01, #f0, #01, #f0}, osx_cdecl) - 1,
			callback( ( '+' & routine_id("machine_callback") ) ) )
		end if
	else
		-- cdecl
		asm = dep:allocate_protect(length(cb_cdecl), 1, PAGE_EXECUTE_READWRITE)
		poke( asm, cb_cdecl )
		poke4( asm + 7, length(call_backs) + 1 )
		poke4( asm + 13, asm + 23 )
		poke4( asm + 23, callback( ( '+' & routine_id("machine_callback") ) ) )
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

procedure opREMOVE()
 	a = Code[pc+1]
 	b = Code[pc+2]
 	c = Code[pc+3]
 	target = Code[pc+4]
 	val[target] = remove(val[a],val[b],val[c])
 	pc += 5
end procedure

procedure opREPLACE()
 	a = Code[pc+1]
 	b = Code[pc+2]
 	c = Code[pc+3]
 	d = Code[pc+4]
 	target = Code[pc+5]
 	val[target] = replace(val[a],val[b],val[c],val[d])
 	pc += 6
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

constant M_CRASH = 67
procedure opMACHINE_PROC()
	object v

	a = Code[pc+1]
	b = Code[pc+2]
	v = val[a]
	-- some things must be handled at our level, not a lower level
	switch v do
		case M_CRASH_ROUTINE then
		-- routine id's must be handled at our level
			do_crash_routine(b)

		case M_CRASH_MESSAGE then
			crash_msg = val[b]

		case M_CRASH_FILE then
			if sequence(val[b]) then
				err_file_name = val[b]
			end if

		case M_WARNING_FILE then
			display_warnings = 1
			if sequence(val[b]) then
				TempWarningName = val[b]
			else
				TempWarningName = STDERR
				display_warnings = (val[b] >= 0)
			end if

		case M_CRASH then

			RTFatal( val[b] )


		case else
			machine_proc(v, val[b])
	end switch
	pc += 3
end procedure

procedure opDEREF_TEMP()
	val[Code[pc+1]] = NOVALUE
	pc += 2
end procedure

constant MAX_USER_DELETE = 20

sequence
	eu_delete_rid   = repeat( -1, MAX_USER_DELETE ),
	user_delete_rid = repeat( -1, MAX_USER_DELETE )

integer delete_advance = 0
symtab_index delete_sym = 0

procedure do_delete_routine( integer dx, object o )

	val[t_id] = user_delete_rid[dx]
	val[t_arglist] = {o}
	atom arglist_assign = new_arg_assign()

	SymTab[delete_code_routine][S_RESIDENT_TASK] = current_task

	-- create a stack frame
	call_stack = append(call_stack, pc)
	call_stack = append(call_stack, delete_code_routine)

	Code = delete_code
	pc = 1

	do_exec()

	if arglist_assign = arg_assign then
		-- free up the dangling reference if it's still there...
		val[t_arglist] = NOVALUE
	end if
	o = 0

	-- remove the stack frame
	pc = call_stack[$-1]
	call_stack = call_stack[1..$-2]

	restore_privates( call_stack[$] )

	-- restore
	Code = SymTab[call_stack[$]][S_CODE]
end procedure

procedure user_delete_01( object o )
	do_delete_routine( 1, o )
end procedure
eu_delete_rid[1] = routine_id("user_delete_01")

procedure user_delete_02( object o )
	do_delete_routine( 2, o )
end procedure
eu_delete_rid[2] = routine_id("user_delete_02")

procedure user_delete_03( object o )
	do_delete_routine( 3, o )
end procedure
eu_delete_rid[3] = routine_id("user_delete_03")

procedure user_delete_04( object o )
	do_delete_routine( 4, o )
end procedure
eu_delete_rid[4] = routine_id("user_delete_04")

procedure user_delete_05( object o )
	do_delete_routine( 5, o )
end procedure
eu_delete_rid[5] = routine_id("user_delete_05")

procedure user_delete_06( object o )
	do_delete_routine( 6, o )
end procedure
eu_delete_rid[6] = routine_id("user_delete_06")

procedure user_delete_07( object o )
	do_delete_routine( 7, o )
end procedure
eu_delete_rid[7] = routine_id("user_delete_07")

procedure user_delete_08( object o )
	do_delete_routine( 8, o )
end procedure
eu_delete_rid[8] = routine_id("user_delete_08")

procedure user_delete_09( object o )
	do_delete_routine( 9, o )
end procedure
eu_delete_rid[9] = routine_id("user_delete_09")

procedure user_delete_10( object o )
	do_delete_routine( 10, o )
end procedure
eu_delete_rid[10] = routine_id("user_delete_10")

procedure user_delete_11( object o )
	do_delete_routine( 11, o )
end procedure
eu_delete_rid[11] = routine_id("user_delete_11")

procedure user_delete_12( object o )
	do_delete_routine( 12, o )
end procedure
eu_delete_rid[12] = routine_id("user_delete_12")

procedure user_delete_13( object o )
	do_delete_routine( 13, o )
end procedure
eu_delete_rid[13] = routine_id("user_delete_13")

procedure user_delete_14( object o )
	do_delete_routine( 14, o )
end procedure
eu_delete_rid[14] = routine_id("user_delete_14")

procedure user_delete_15( object o )
	do_delete_routine( 15, o )
end procedure
eu_delete_rid[15] = routine_id("user_delete_15")

procedure user_delete_16( object o )
	do_delete_routine( 16, o )
end procedure
eu_delete_rid[16] = routine_id("user_delete_16")

procedure user_delete_17( object o )
	do_delete_routine( 17, o )
end procedure
eu_delete_rid[17] = routine_id("user_delete_17")

procedure user_delete_18( object o )
	do_delete_routine( 18, o )
end procedure
eu_delete_rid[18] = routine_id("user_delete_18")

procedure user_delete_19( object o )
	do_delete_routine( 19, o )
end procedure
eu_delete_rid[19] = routine_id("user_delete_19")

procedure user_delete_20( object o )
	do_delete_routine( 20, o )
end procedure
eu_delete_rid[20] = routine_id("user_delete_20")


procedure opDELETE_ROUTINE()
	a = Code[pc+1]

	integer rid = val[Code[pc+2]]
	b = find( rid, user_delete_rid )
	if not b then
		b = find( -1, user_delete_rid )
		if not b then
			RTFatal("Maximum of 20 user defined delete routines exceeded.")
		end if
		user_delete_rid[b] = rid
	end if
	val[Code[pc+3]] = delete_routine( val[a], eu_delete_rid[b] )
	if sym_mode( a ) = M_TEMP then
		val[a] = NOVALUE
	end if

	pc += 4
end procedure

procedure opDELETE_OBJECT()
	delete( val[Code[pc+1]] )
	pc += 2
end procedure

procedure do_exec()
-- execute IL code, starting at pc
	keep_running = TRUE
	while keep_running do
		integer op = Code[pc]
		ifdef DEBUG then
			if op > 0 and op <= length(opnames) then
				printf(2,"[%s]:[%d] '%d:%s'\n", {SymTab[call_stack[$]][S_NAME], pc, op, opnames[op]})
			else
				printf(2,"[%s]:[%d] %d\n", {SymTab[call_stack[$]][S_NAME], pc, op})
			end if
		end ifdef
		switch op do
			case ABORT then
				opABORT()

			case AND then
				opAND()

			case AND_BITS then
				opAND_BITS()

			case APPEND then
				opAPPEND()

			case ARCTAN then
				opARCTAN()

			case ASSIGN, ASSIGN_I then
				opASSIGN()

			case ASSIGN_OP_SLICE then
				opASSIGN_OP_SLICE()

			case ASSIGN_OP_SUBS then
				opASSIGN_OP_SUBS()

			case ASSIGN_SLICE then
				opASSIGN_SLICE()

			case ASSIGN_SUBS, ASSIGN_SUBS_CHECK, ASSIGN_SUBS_I then
				opASSIGN_SUBS()

			case ATOM_CHECK then
				opATOM_CHECK()

			case BADRETURNF then
				opBADRETURNF()

			case C_FUNC then
				opC_FUNC()

			case C_PROC then
				opC_PROC()

			case CALL then
				opCALL()

			case CALL_BACK_RETURN then
				opCALL_BACK_RETURN()

			case CALL_PROC, CALL_FUNC then
				opCALL_PROC()

			case CASE then
				opCASE()

			case CLEAR_SCREEN then
				opCLEAR_SCREEN()

			case CLOSE then
				opCLOSE()

			case COMMAND_LINE then
				opCOMMAND_LINE()

			case COMPARE then
				opCOMPARE()

			case CONCAT then
				opCONCAT()

			case CONCAT_N then
				opCONCAT_N()

			case COS then
				opCOS()

			case DATE then
				opDATE()

			case DIV2 then
				opDIV2()

			case DIVIDE then
				opDIVIDE()

			case ELSE, EXIT, ENDWHILE, RETRY then
				opELSE()

			case ENDFOR_GENERAL, ENDFOR_UP, ENDFOR_DOWN, ENDFOR_INT_UP,
					ENDFOR_INT_DOWN, ENDFOR_INT_DOWN1 then
				opENDFOR_GENERAL()

			case ENDFOR_INT_UP1 then
				opENDFOR_INT_UP1()

			case EQUAL then
				opEQUAL()

			case EQUALS then
				opEQUALS()
			
			case EQUALS_IFW, EQUALS_IFW_I then
				opEQUALS_IFW()

			case EXIT_BLOCK then
				opEXIT_BLOCK()

			case FIND then
				opFIND()

			case FIND_FROM then
				opFIND_FROM()

			case FLOOR then
				opFLOOR()

			case FLOOR_DIV then
				opFLOOR_DIV()

			case FLOOR_DIV2 then
				opFLOOR_DIV2()

			case FOR, FOR_I then
				opFOR()

			case GET_KEY then
				opGET_KEY()

			case GETC then
				opGETC()

			case GETENV then
				opGETENV()

			case GETS then
				opGETS()

			case GLABEL then
				opGLABEL()

			case GLOBAL_INIT_CHECK, PRIVATE_INIT_CHECK then
				opGLOBAL_INIT_CHECK()

			case GOTO then
				opGOTO()

			case GREATER then
				opGREATER()

			case GREATER_IFW, GREATER_IFW_I then
				opGREATER_IFW()

			case GREATEREQ then
				opGREATEREQ()

			case GREATEREQ_IFW, GREATEREQ_IFW_I then
				opGREATEREQ_IFW()

			case HASH then
				opHASH()

			case HEAD then
				opHEAD()

			case IF then
				opIF()

			case INSERT then
				opINSERT()

			case INTEGER_CHECK then
				opINTEGER_CHECK()

			case IS_A_SEQUENCE then
				opIS_A_SEQUENCE()

			case IS_AN_ATOM then
				opIS_AN_ATOM()

			case IS_AN_INTEGER then
				opIS_AN_INTEGER()

			case IS_AN_OBJECT then
				opIS_AN_OBJECT()

			case LENGTH then
				opLENGTH()

			case LESS then
				opLESS()

			case LESS_IFW_I, LESS_IFW then
				opLESS_IFW()

			case LESSEQ then
				opLESSEQ()

			case LESSEQ_IFW, LESSEQ_IFW_I then
				opLESSEQ_IFW()

			case LHS_SUBS then
				opLHS_SUBS()

			case LHS_SUBS1 then
				opLHS_SUBS1()

			case LHS_SUBS1_COPY then
				opLHS_SUBS1_COPY()

			case LOG then
				opLOG()

			case MACHINE_FUNC then
				opMACHINE_FUNC()

			case MACHINE_PROC then
				opMACHINE_PROC()

			case MATCH then
				opMATCH()

			case MATCH_FROM then
				opMATCH_FROM()

			case MEM_COPY then
				opMEM_COPY()

			case MEM_SET then
				opMEM_SET()

			case MINUS, MINUS_I then
				opMINUS()

			case MULTIPLY then
				opMULTIPLY()

			case NOP2, SC2_NULL, ASSIGN_SUBS2, PLATFORM, END_PARAM_CHECK,
					NOPWHILE, NOP1 then
				opNOP2()

			case NOPSWITCH then
				opNOPSWITCH()

			case NOT then
				opNOT()

			case NOT_BITS then
				opNOT_BITS()

			case NOT_IFW then
				opNOT_IFW()

			case NOTEQ then
				opNOTEQ()

			case NOTEQ_IFW, NOTEQ_IFW_I then
				opNOTEQ_IFW()

			case OPEN then
				opOPEN()

			case OPTION_SWITCHES then
				opOPTION_SWITCHES()

			case OR then
				opOR()

			case OR_BITS then
				opOR_BITS()

			case PASSIGN_OP_SLICE then
				opPASSIGN_OP_SLICE()

			case PASSIGN_OP_SUBS then
				opPASSIGN_OP_SUBS()

			case PASSIGN_SLICE then
				opPASSIGN_SLICE()

			case PASSIGN_SUBS then
				opPASSIGN_SUBS()

			case PEEK then
				opPEEK()

			case PEEK_STRING then
				opPEEK_STRING()

			case PEEK2S then
				opPEEK2S()

			case PEEK2U then
				opPEEK2U()

			case PEEK4S then
				opPEEK4S()

			case PEEK4U then
				opPEEK4U()

			case PEEK8S then
				opPEEK8S()

			case PEEK8U then
				opPEEK8U()
				
			case PEEKS then
				opPEEKS()

			case PLENGTH then
				opPLENGTH()

			case PLUS, PLUS_I then
				opPLUS()

			case PLUS1, PLUS1_I then
				opPLUS1()

			case POKE then
				opPOKE()

			case POKE2 then
				opPOKE2()

			case POKE4 then
				opPOKE4()

			case POKE8 then
				opPOKE8()
			
			case POKE_POINTER then
				opPOKE_POINTER()
			
			case PEEK_POINTER then
				opPEEK_POINTER()
				
			case POSITION then
				opPOSITION()

			case POWER then
				opPOWER()

			case PREPEND then
				opPREPEND()

			case PRINT then
				opPRINT()

			case PRINTF then
				opPRINTF()

			case PROC_TAIL then
				opPROC_TAIL()

			case PROC then
				opPROC()

			case PROFILE, DISPLAY_VAR, ERASE_PRIVATE_NAMES, ERASE_SYMBOL then
				opPROFILE()

			case PUTS then
				opPUTS()

			case QPRINT then
				opQPRINT()

			case RAND then
				opRAND()

			case REMAINDER then
				opREMAINDER()

			case REMOVE then
				opREMOVE()

			case REPEAT then
				opREPEAT()

			case REPLACE then
				opREPLACE()

			case RETURNF then
				opRETURNF()

			case RETURNP then
				opRETURNP()

			case RETURNT then
				opRETURNT()

			case RHS_SLICE then
				opRHS_SLICE()

			case RHS_SUBS, RHS_SUBS_CHECK, RHS_SUBS_I then
				opRHS_SUBS()

			case RIGHT_BRACE_2 then
				opRIGHT_BRACE_2()

			case RIGHT_BRACE_N then
				opRIGHT_BRACE_N()

			case ROUTINE_ID then
				opROUTINE_ID()

			case SC1_AND then
				opSC1_AND()

			case SC1_AND_IF then
				opSC1_AND_IF()

			case SC1_OR then
				opSC1_OR()

			case SC1_OR_IF then
				opSC1_OR_IF()

			case SC2_OR, SC2_AND then
				opSC2_OR()

			case SEQUENCE_CHECK then
				opSEQUENCE_CHECK()

			case SIN then
				opSIN()

			case SPACE_USED then
				opSPACE_USED()

			case SPLICE then
				opSPLICE()

			case SPRINTF then
				opSPRINTF()

			case SQRT then
				opSQRT()

			case STARTLINE then
				opSTARTLINE()

			case SWITCH, SWITCH_I then
				opSWITCH()

			case SWITCH_SPI then
				opSWITCH_SPI()

			case SWITCH_RT then
				opSWITCH_RT()

			case SYSTEM then
				opSYSTEM()

			case SYSTEM_EXEC then
				opSYSTEM_EXEC()

			case TAIL then
				opTAIL()

			case TAN then
				opTAN()

			case TASK_CLOCK_START then
				opTASK_CLOCK_START()

			case TASK_CLOCK_STOP then
				opTASK_CLOCK_STOP()

			case TASK_CREATE then
				opTASK_CREATE()

			case TASK_LIST then
				opTASK_LIST()

			case TASK_SCHEDULE then
				opTASK_SCHEDULE()

			case TASK_SELF then
				opTASK_SELF()

			case TASK_STATUS then
				opTASK_STATUS()

			case TASK_SUSPEND then
				opTASK_SUSPEND()

			case TASK_YIELD then
				opTASK_YIELD()

			case TIME then
				opTIME()

			case TRACE then
				opTRACE()

			case TYPE_CHECK then
				opTYPE_CHECK()
				
			case MEM_TYPE_CHECK then
				opMEM_TYPE_CHECK()

			case UMINUS then
				opUMINUS()

			case UPDATE_GLOBALS then
				opUPDATE_GLOBALS()

			case WHILE then
				opWHILE()

			case XOR then
				opXOR()

			case XOR_BITS then
				opXOR_BITS()

			case DELETE_ROUTINE then
				opDELETE_ROUTINE()

			case DELETE_OBJECT then
				opDELETE_OBJECT()

			case REF_TEMP then
				pc += 2
			case DEREF_TEMP, NOVALUE_TEMP then
				opDEREF_TEMP()

			case COVERAGE_LINE then
				opCOVERAGE_LINE()

			case COVERAGE_ROUTINE then
				opCOVERAGE_ROUTINE()
				
			case SIZEOF then
				opSIZEOF()
				
			case MEMSTRUCT_ACCESS then
				opMEMSTRUCT_ACCESS()
			
			case MEMSTRUCT_ARRAY then
				opMEMSTRUCT_ARRAY()
			
			case PEEK_ARRAY then
				opPEEK_ARRAY()
			case PEEK_MEMBER then
				opPEEK_MEMBER()
			
			case MEMSTRUCT_READ then
				opMEMSTRUCT_READ()
			
			case MEMSTRUCT_ASSIGN then
				opMEMSTRUCT_ASSIGN()
			
			case MEMSTRUCT_PLUS, MEMSTRUCT_MINUS, MEMSTRUCT_MULTIPLY, MEMSTRUCT_DIVIDE then
				opMEMSTRUCT_ASSIGN_OP()
			
			case ADDRESSOF then
				opADDRESSOF()
			
			case OFFSETOF then
				opOFFSETOF()

			case else
				RTFatal( sprintf("Unknown opcode: %d", op ) )
		end switch
	end while
	keep_running = TRUE -- so higher-level do_exec() will keep running
end procedure

procedure InitBackEnd()
-- initialize Interpreter
-- Some ops are treated exactly the same as other ops.
-- In the hand-coded C back-end, they might be treated differently
-- for extra performance.
	sequence name

	-- set up val
	integer len = length(val)
	val = val & repeat(0, length(SymTab)-length(val))
	for i = len + 1 to length(SymTab) do
		val[i] = SymTab[i][S_OBJ] -- might be NOVALUE
		SymTab[i][S_OBJ] = 0
	end for
end procedure

procedure fake_init( integer ignore )
	intoptions()
end procedure
mode:set_init_backend( routine_id("fake_init") )

export procedure Execute(symtab_index proc, integer start_index)
-- top level executor
	InitBackEnd()
	if current_task = -1 then
	current_task = 1
	end if
	if not length(call_stack) then
	call_stack = {proc}
	end if
	if pc = -1 then
	pc = start_index
	end if
	Code = SymTab[proc][S_CODE]
	do_exec()
	if repl then
		reset_repl_line_read()
	end if
end procedure

Execute_id = routine_id("Execute")

--**
-- The Interpreter back end
procedure BackEnd(atom ignore)
	Execute(TopLevelSub, 1)
end procedure
set_backend( routine_id("BackEnd") )

-- dummy routines, not used
export procedure OutputIL()
end procedure

--**
-- dummy routine, not used by interpreter
export function extract_options(sequence s)
	return s
end function

