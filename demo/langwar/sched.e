-- sched.e
-- Task Scheduler

-- This is perhaps the most interesting source file since it shows a
-- simple technique of task scheduling that could be used in any action 
-- game or simulation program. 

-- We have implemented a form of cooperative multitasking to manage 10 
-- independent tasks. There is a task that moves the Euphoria, another task 
-- that checks the keyboard for input, a task that makes enemy ships fire, 
-- another that counts down the damage report, etc. The sequence "tcb" records
-- the time at which each task wants to be activated next. When the time comes 
-- to run a given task, the scheduler will return to the main program, telling
-- it which task to run. When the task is finished it can tell the scheduler 
-- when it would like to be activated next. 

-- For example, the task that moves the Euphoria will ask to be activated 
-- again in 20 seconds if the Euphoria is moving at warp 1, or much less at 
-- higher warps. The keyboard checking task is activated very frequently, but 
-- usually returns quickly (no key pressed). 

-- Some tasks require very precise activation times to make things look 
-- realistic, e.g. Euphoria moving at warp 5. Others do not, for example the 
-- BASIC TRUCE/HOSTILE/CLOAKING task which is activated after a lengthy and 
-- random amount of time. In recognition of this we have the "eat" (early 
-- activation tolerance) variable. After choosing the next task to run, and 
-- before entering into a delay loop to wait for the activation time to come,
-- the scheduler will check the eat to see if it can activate the task a bit
-- early. This will get this task out of the way a bit earlier and
-- reduce the chance of a timing conflict with the next task.

-- Having said all this, the code is actually quite simple:

include vars.e

global constant HUGE_TIME = 1e30
global constant INACTIVE = 0

global procedure sched(task t, positive_atom wait)
-- schedule a task to be reactivated in wait seconds

    if wait = INACTIVE then
	-- deactivate
	tcb[t] = HUGE_TIME
    else
	-- activate in wait seconds from now
	tcb[t] = time() + wait
    end if
end procedure


global function next_task()
-- choose the next task to be executed

    positive_atom mintime
    task mintask

    -- find task with minimum time
    mintask = 1
    mintime = tcb[1]
    for i = 2 to NTASKS do
	if tcb[i] < mintime then
	    mintask = i
	    mintime = tcb[i]
	end if
    end for

    -- subtract it's early-activation tolerance
    tcb[mintask] = tcb[mintask] - eat[mintask]

    -- wait until it is time to activate it
    while time() < tcb[mintask] do
    end while

    return mintask
end function


-- below we have some code that lets us perform short accurate time delays
-- with better resolution than the usual 18.2 ticks per second under MS-DOS
constant sample_interval = 1.0
atom sample_count

type reasonable_delay(atom x)
    return x > 0 and x < 30
end type

global procedure init_delay()
-- since time() does not have fine enough
-- resolution for small delays, we see how many for-loop iterations
-- we can complete over a small sample period

    atom t

    t = time() + sample_interval
    for i = 1 to 999999999 do
	if time() < t then
	else
	    sample_count = i
	    exit
	end if
    end for
end procedure

global procedure delay(reasonable_delay t)
-- delay for t seconds
    atom stop
    if t > sample_interval then
	-- time() should be precise enough
	stop = time() + t
	while time() < stop do
	end while
    else
	-- loop a certain number of times
	stop = time() + sample_interval
	for i = 1 to floor(t / sample_interval * sample_count) do
	    if time() < stop then
	    else
	    end if
	end for
    end if
end procedure

