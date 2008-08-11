-- multitasking sorting demo

-- (for some unknown reason, XP runs this faster when you move 
-- your mouse back and forth, or when "with profile_time" or tick_rate()
-- is in effect. In these cases the interpreter handles hardware interrupts.)

-- with profile_time

without type_check

include std\graphics.e
include std/graphcst.e
include std/graphcst.e
include std\file.e
include std\os.e

if graphics_mode(18) then
end if

constant COLOR = {WHITE, RED, BLUE, GREEN}
constant TRUE = 1
constant STARTX = 1, STARTY = 18
constant MAXVAL = 150
constant SPACE = 8

integer t_bubble, t_insertion, t_shell, t_quick 

procedure show_element(integer column, integer i, integer val)
-- show one line, color/black   
    integer x, y
    
    x = STARTX + (column-1) * (MAXVAL+SPACE)
    y = STARTY+i-1
    
    pixel(repeat(COLOR[column], val) & 
	  repeat(BLACK, MAXVAL-val),
	  {x, y})
end procedure


procedure show_sequence(integer column, sequence data)
-- show lines for a whole sequence  
    for i = 1 to length(data) do
	show_element(column, i, data[i])
    end for
end procedure


function bubble_sort(sequence x)
-- put x into ascending order
-- using bubble sort
object temp
integer flip, limit

    flip = length(x)
    while flip > 0 do
	limit = flip
	flip = 0
	for i = 1 to limit - 1 do
	    if compare(x[i+1], x[i]) < 0 then
		temp = x[i+1]
		x[i+1] = x[i]
		show_element(1, i+1, x[i+1])
		x[i] = temp
		show_element(1, i, x[i])
		flip = i
		task_yield()
	    end if
	end for
    end while
    return x
end function

function shell_sort(sequence x)
-- Shell sort based on insertion sort

    integer gap, j, first, last
    object tempi, tempj

    last = length(x)
    gap = floor(last / 10) + 1
    while TRUE do
	first = gap + 1
	for i = first to last do
	    task_yield()
	    tempi = x[i]
	    j = i - gap
	    while TRUE do
		tempj = x[j]
		if compare(tempi, tempj) >= 0 then
		    j += gap
		    exit
		end if
		x[j+gap] = tempj
		show_element(3, j+gap, x[j+gap])
		if j <= gap then
		    exit
		end if
		j -= gap
		task_yield()
	    end while
	    x[j] = tempi
	    show_element(3, j, x[j])
	end for
	if gap = 1 then
	    return x
	else
	    gap = floor(gap / 3.5) + 1
	end if
    end while
end function


function insertion_sort(sequence x)
-- put x into ascending order
-- using insertion sort
    object temp
    integer final

    for i = 2 to length(x) do
	temp = x[i]
	final = 1
	for j = i-1 to 1 by -1 do
	    task_yield()
	    if compare(temp, x[j]) < 0 then
		x[j+1] = x[j]
		show_element(2, j+1, x[j+1])
	    else
		final = j + 1
		exit
	    end if
	end for
	x[final] = temp
	show_element(2, final, x[final])
    end for
    return x
end function


sequence x

procedure best_sort(integer m, integer n)
-- put x[m..n] into (roughly) ascending order
-- using recursive quick sort 
    integer last, mid
    object midval, temp

    if m > n then 
	return
    end if
    mid = floor((m + n) / 2)
    midval = x[mid]
    x[mid] = x[m]
    show_element(4, mid, x[mid])

    last = m
    for i = m+1 to n do
	if compare(x[i], midval) < 0 then
	    last += 1
	    temp = x[last]  
	    x[last] = x[i]  
	    show_element(4, last, x[last])
	    x[i] = temp
	    show_element(4, i, x[i])
	end if
	task_yield()
    end for
    x[m] = x[last]
    show_element(4, m, x[m])
    x[last] = midval
    show_element(4, last, x[last])
    best_sort(m, last-1)
    best_sort(last+1, n)
end procedure

global function quick_sort(sequence a)
-- Avoids dynamic storage allocation - just passes indexes into
-- a global sequence.
    x = a
    best_sort(1, length(x))
    return x
end function


sequence data, data1, data2, data3, data4

procedure init()
    clear_screen()

    for i=1 to 4 do
	show_sequence(i, data)
    end for

    position(1,1)

    text_color(COLOR[1])
    puts(1, "  Bubble Sort")
    
    text_color(COLOR[2])
    puts(1, "        Insertion Sort")
    
    text_color(COLOR[3])
    puts(1, "         Shell Sort")
    
    text_color(COLOR[4])
    puts(1, "          Quick Sort")
end procedure


procedure beep(integer x)
-- make a beep sound (without causing a delay)
    sound(x)
    task_schedule(task_self(), {.1, .1})
    task_yield()
    sound(0)
end procedure

procedure run_bubble(sequence data)
    data1 = bubble_sort(data)
    beep(1000)
end procedure

procedure run_insertion(sequence data)
    data2 = insertion_sort(data)
    beep(2000)
end procedure

procedure run_shell(sequence data)
    data3 = shell_sort(data)
    beep(3000)
end procedure

procedure run_quick(sequence data)
    data4 = quick_sort(data)
    beep(4000)
end procedure

data = rand(repeat(MAXVAL, 455))

init()

-- create tasks
t_bubble = task_create(routine_id("run_bubble"), {data})
t_insertion = task_create(routine_id("run_insertion"), {data})
t_shell = task_create(routine_id("run_shell"), {data})
t_quick = task_create(routine_id("run_quick"), {data})
 
-- schedule 5 tasks
-- To make it more interesting, Bubble and Insertion get scheduled 8x as often 

task_schedule(t_bubble, 8)
task_schedule(t_insertion, 8)
task_schedule(t_shell, 1)
task_schedule(t_quick, 1)
task_schedule(0, {1, 1}) -- initial, top-level task checks keyboard every second

while get_key() = -1 do
    task_yield()
end while

if graphics_mode(-1) then
end if

