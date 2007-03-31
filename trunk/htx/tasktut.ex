constant TRUE = 1, FALSE = 0

type boolean(integer x)
    return x = 0 or x = 1
end type

boolean t1_running, t2_running

procedure task1(sequence message)
    for i = 1 to 10 do
	printf(1, "task1 (%d) %s\n", {i, message})
	task_yield()
    end for
    t1_running = FALSE
end procedure

procedure task2(sequence message)
    for i = 1 to 10 do
	printf(1, "task2 (%d) %s\n", {i, message})
	task_yield()
    end for
    t2_running = FALSE
end procedure

puts(1, "main task: start\n")

atom t1, t2

t1 = task_create(routine_id("task1"), {"Hello"})
t2 = task_create(routine_id("task2"), {"Goodbye"})

task_schedule(t1, {2.5, 3})
task_schedule(t2, {5, 5.1})

t1_running = TRUE
t2_running = TRUE

while t1_running or t2_running do
    if get_key() = 'q' then
	exit
    end if  
    task_yield()
end while

puts(1, "main task: stop\n")
-- program ends when main task is finished

