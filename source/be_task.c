/*****************************************************************************/
/*      (c) Copyright 2007 Rapid Deployment Software - See License.txt       */
/*****************************************************************************/
/*                                                                           */
/*                            Multitasking                                   */
/*                                                                           */
/*****************************************************************************/

/******************/
/* Included files */
/******************/
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#ifdef ELCC
#include <io.h>
#endif
#ifdef EWINDOWS
#include <windows.h> /* for Sleep() */
#endif
#if defined(ESIMPLE_MALLOC) && defined(EWINDOWS)
#include <windows.h>
#endif
#include "global.h"
#include "execute.h"
#include "symtab.h"
#include "reswords.h"

/*********************/
/* Local definitions */
/*********************/
#define T_REAL_TIME 1
#define T_TIME_SHARE 2
#define TASK_NEVER 1e300
#define TASK_ID_MAX 9e15 // wrap to 0 after this (and avoid in-use ones)
#ifdef ERUNTIME
#define STACK_MARKER 0x0F1D2A3F // so we'll know if stack boundary was crossed
#endif

// !!! Special machine code is inserted into scheduler() and task_create() !!!

// The stack offsets below have to be adjusted from time to time
// as the source code changes. You need to generate an assembly listing of
// be_task.obj to see what's going on. We are trying to copy the value of the
// hardware stack pointer to/from a C variable called "stack_top". 
// To do this we need to know the offset where the "stack_top" variable 
// is kept on the stack. The C compiler can sometimes change this offset for
// reasons known only to itself.

// For Watcom, run watlib.bat (or watlibw.bat as appropriate).
// This will create be_task.obj. Then run:
//    wdis be_task.obj > be_task.asm
// (use "wdisasm" on older versions of Watcom)
// Look at the code for scheduler() and task_create(). That's where the
// machine code is inserted. In task_create() there's a C statement that
// sets stack_top to zero. Find that place in the asm code.
// (xor ebx,ebx creates the zero). Make sure
// that the C compiler's offset for stack_top matches the one used in
// the read_esp_tc() macro. If not, fix the macro. Then move on to scheduler
// and check that the C compiler's offset for "stack_top" matches the macros.

// For Borland, you can run borelib.bat to create be_task.asm, but first edit
// borelib.bat, adding the -S option to the bcc32 command that compiles 
// be_task.c. Remember to remove the -S when you are done.
// To avoid a Borland bug, you must also comment out the "#pragma codeseg"
// statements temporarily while you create the asm file. Put them back in
// when you are done. be_task.asm will be created for you.

// For Lcc, run lccelib.bat, but first edit the line that compiles be_task.c,
// adding the -S flag. Then look at the be_task.asm file that results.
// Remember to remove the -S flag when you are done.

// For GNU C (Linux, FreeBSD), use the -S flag in gnulib (or bsdlib) 
// when compiling be_task.c. That will give you an assembly listing .s file 
// instead of a .obj file. Look for the #APP ... #NO_APP sections in the 
// .s file. See if the %esp stack offsets match what the C compiler uses 
// in the surrounding sections of code for the "stack_top" variable. 
// Remove the -S flag when you are done.

// Note: after a PUSH or POP, the stack pointer ESP points at the top element

#ifdef EUNIX
#define push_regs() asm("pushal")
#define pop_regs() asm("popal")
#define set_esp() asm volatile("movl %0, %%esp" : /* no out */ : "r"(stack_top) )
#define read_esp() asm volatile("movl %%esp, %0" : "=r"(stack_top)  )
// this strictly speaking isnt needed anymore but is here for historical reasons ("hysterical raisins", anyone?)
#define read_esp_tc() asm("movl %%esp, %0" : "=r"(stack_top) : /* no in */ : "%esp" )
#endif

#ifdef ELCC
#ifdef EMSVC
#define push_regs() __asm { PUSHA } 1 == 1
#define pop_regs() __asm { POPA } 1 == 1
#define set_esp() __asm { MOV esp, stack_top } 1 == 1
#define read_esp() __asm { MOV stack_top, esp } 1 == 1
// this strictly speaking isnt needed anymore but is here for historical reasons ("hysterical raisins", anyone?)
#define read_esp_tc() __asm { MOV stack_top, esp } 1 == 1
#else
#define push_regs() _asm("pushal")
#define pop_regs() _asm("popal")
#define set_esp() _asm("movl -20(%ebp), %esp")
#define read_esp() _asm("movl %esp, -20(%ebp)")
#define read_esp_tc() _asm("movl %esp, -52(%ebp)")
#endif
#endif

#ifdef EBORLAND
// This is just dummy code. It will be searched and replaced at start-up.
// See PatchCallc() in be_callc.c 
#define push_regs() stack_top = 99999;   // 99999 = hex 00 01 86 9F
#define pop_regs() stack_top = 88888;    // 88888 = hex 00 01 5B 38
#define set_esp() stack_top = 77777;     // 77777 = hex 00 01 2F D1
#define read_esp() stack_top = 66666;    // 66666 = hex 00 01 04 6A
#define read_esp_tc() stack_top = 55555; // 55555 = hex 00 00 d9 03
#endif

#ifdef EDJGPP
#define push_regs() asm("pushal")
#define pop_regs() asm("popal")
#define set_esp() asm("movl 60(%esp), %esp")
#define read_esp() asm("movl %esp, 60(%esp)")
#define read_esp_tc() asm("movl %esp, 36(%esp)")
#endif

#ifdef EWATCOM
#pragma aux push_regs = \
		"PUSHAD" \
		modify[ESP];

#pragma aux pop_regs = \
		"POPAD" \
		modify[ESP];

#define set_esp() wset_esp(stack_top)
void wset_esp(long);
#pragma aux wset_esp = \
		"MOV ESP, ECX" \
		parm [ECX] \
		modify[ESP];

#define read_esp() stack_top = wread_esp()
long wread_esp(void);
#pragma aux wread_esp = \
		"MOV ECX, ESP" \
		value [ECX] \
		modify[ESP];

// this strictly speaking isnt needed anymore but is here for historical reasons ("hysterical raisins", anyone?)
#define read_esp_tc() stack_top = wread_esp()
#endif


/**********************/
/* Exported variables */
/**********************/
struct tcb *tcb;
int tcb_size;
int current_task;
#ifdef EDOS
double clock_period = 0.055; // DOS default - tick_rate() can change this
#else
// Windows/Linux/FreeBSD
double clock_period = 0.01;  // should check this at run-time
#endif

/**********************/
/* Imported variables */
/**********************/
extern unsigned char TempBuff[];
#ifdef ERUNTIME
extern struct routine_list *rt00;
extern char *stack_base;
#else
extern object_ptr expr_stack;
extern object_ptr expr_max;  
extern object_ptr expr_limit;
extern int stack_size;
extern object_ptr expr_top;
extern int *tpc;
extern symtab_ptr TopLevelSub;
extern int **jumptab;
extern int e_routine_next;
extern symtab_ptr *e_routine;
#endif

/*******************/
/* Local variables */
/*******************/
static int rt_first, ts_first;
static int clock_stopped = FALSE;
static int id_wrap = FALSE; // have task id's wrapped around? (very rare)
static double next_task_id = 1.0;

extern int total_stack_size; // total amount of stack available 
							 // OPTION STACK will be 8k higher than this)


/*********************/
/* Declared functions */
/*********************/
extern double current_time();
#ifndef ESIMPLE_MALLOC
extern char *EMalloc();
#else
#include "alloc.h"
#ifdef EWINDOWS
extern unsigned default_heap;
#endif
#endif
extern void debug_dbl(double);
void scheduler(double);
#ifdef ERUNTIME
extern struct routine_list _00[]; 
#endif

/*********************/
/* Defined functions */
/*********************/
#ifdef ERUNTIME
#ifdef EUNIX
#ifndef EBSD
static void grow_stack(int x)
// we need this because there seems to be no way to commit stack space
{
	volatile char a[1024];
	a[1] = x;
	if (x == 1)
		return;
	else
		grow_stack(x-1);

	a[10] = &a; // gcc 4.1 seems to need this to avoid segfaulting
}
#endif
#endif
#endif

void InitTask()
// initialize the first (top-level) task - task id 0
{   
	object_ptr word;
	
	tcb = (struct tcb *)EMalloc(sizeof(struct tcb)); // allocate one entry
	tcb[0].rid = -1;
	tcb[0].tid = 0.0;
	tcb[0].type = T_TIME_SHARE;
	tcb[0].status = ST_ACTIVE;
	tcb[0].start = 0.0;
	tcb[0].min_inc = 0.0;
	tcb[0].max_inc = 0.0;
	tcb[0].min_time = 1.0;
	tcb[0].max_time = 1.0;
	tcb[0].runs_left = 1;
	tcb[0].runs_max = 1;
	tcb[0].next = -1; // end marker
	tcb[0].args = 0;
	
	// these things will be set when task 0 yields for the first time
	tcb[0].pc = (int *)1; 
	tcb[0].expr_max = NULL;
	tcb[0].expr_limit = NULL;
#ifdef ERUNTIME 
#ifdef EUNIX   
#ifndef EBSD    
	grow_stack(total_stack_size / 1024);
#endif
#endif  
	total_stack_size -= 8192; // some is reserved for top-level start-up
		
	tcb[0].expr_stack = (object_ptr)(stack_base - total_stack_size);
	tcb[0].stack_size = total_stack_size;
	
	//debug_msg("about to store STACK_MARKER");
	*(tcb[0].expr_stack) = STACK_MARKER;
	//debug_msg("finished storing STACK_MARKER");
	
	word = (object_ptr)
		   (((char *)(tcb[0].expr_stack)) + tcb[0].stack_size/2);

	*word = (object)STACK_MARKER; // mid marker 
	
	tcb[0].expr_top = (object_ptr)stack_base;
#else
	tcb[0].expr_top = NULL;
	tcb[0].expr_stack = NULL;
	tcb[0].stack_size = 0; 
#endif  
	tcb_size = 1;
	
	ts_first = 0;    // this ts task only
	rt_first = -1;   // no rt tasks
	
	current_task = 0;
}

static int task_delete(int first, int task)
// Remove a task from a list of tasks (if it's there).
// Return the new first element of the list.    
{
	int p, prev_p;
	
	prev_p = -1;
	p = first;
	while (p != -1) {
		if (p == task) {
			if (prev_p == -1) {
				// it was first on list
				return tcb[p].next;
			}
			else {
				// skip around it
				tcb[prev_p].next = tcb[p].next;
				return first;
			}
		}
		prev_p = p;
		p = tcb[p].next;
	}
	// couldn't find it
	return first;
}

void terminate_task(int task)
// mark a task for deletion (task is the internal task number)
{
	if (tcb[task].type == T_REAL_TIME) {
		rt_first = task_delete(rt_first, task);
	}
	else {    
		ts_first = task_delete(ts_first, task);
	}
	tcb[task].status = ST_DEAD; // its tcb entry will be recycled later
}

extern double Wait(double t);
double Wait(double t)
// Wait for a while 
{   
	double t1, t2, now;
	int it;
#ifdef EUNIX
	double t3;
	long itsme;
	struct timespec req;
#endif
	
#ifdef EWINDOWS
	t1 = floor(1000.0 * t);
	t2 = t1 / 1000.0;
#else
	t1 = floor(t);
#endif
#ifdef EUNIX
	t2 = t - t1;
	t3 = floor(1000000000.0 * t2);
#endif
	if (t1 >= 1.0) {
		it = t1; // overflow?
#ifdef EWINDOWS
		Sleep(it);
		t -= t2;
#else
#ifdef EUNIX
		itsme = (long)t3;
		req.tv_sec = it;
		req.tv_nsec = itsme;
		nanosleep(&req, NULL);
		t3 = t3 / 1000000000.0;
		t = t2 - t3;
#else
		sleep(it);
		t -= t1;
#endif  // EUNIX
#endif  // ELCC
	}
	
	// busy Wait for the last bit, < 1 sec
	now = current_time();
	t2 = now + t;
	while (now < t2) {
		now = current_time();
	}
	return now;
}

#ifdef ERUNTIME
static void call_task(int rid, object args) 
/* translated code: call a task for the first time, passing its arguments */
{
	s1_ptr args_ptr;
	object_ptr base_ptr;
	int *proc_addr;
	int num_args, i;
	
	// call_proc(p, args) 
	args_ptr = SEQ_PTR(args);
	base_ptr = args_ptr->base;
	proc_addr = (int *)_00[rid].addr;
	num_args = args_ptr->length;
	
	for (i = 1; i <= num_args; i++) {
		// Ref each argument
		Ref(*(base_ptr+i));
	}
	
	switch(num_args) {
		case 0:
			(*(int (*)())proc_addr)(
							);
			break;
		
		case 1:
			(*(int (*)())proc_addr)(
							*(base_ptr+1)
							);
			break;
		
		case 2:
			(*(int (*)())proc_addr)(
							*(base_ptr+1), 
							*(base_ptr+2)
							);
			break;
		
		case 3:
			(*(int (*)())proc_addr)(
							*(base_ptr+1), 
							*(base_ptr+2), 
							*(base_ptr+3)
							);
			break;
	
		case 4:
			(*(int (*)())proc_addr)(
							*(base_ptr+1), 
							*(base_ptr+2), 
							*(base_ptr+3), 
							*(base_ptr+4)
							);
			break;
	
		case 5:
			(*(int (*)())proc_addr)(
							*(base_ptr+1), 
							*(base_ptr+2), 
							*(base_ptr+3), 
							*(base_ptr+4), 
							*(base_ptr+5)
							);
			break;
	
		case 6:
			(*(int (*)())proc_addr)(
							*(base_ptr+1), 
							*(base_ptr+2), 
							*(base_ptr+3), 
							*(base_ptr+4), 
							*(base_ptr+5), 
							*(base_ptr+6)
							);
			break;
	
		case 7:
			(*(int (*)())proc_addr)(
							*(base_ptr+1), 
							*(base_ptr+2), 
							*(base_ptr+3), 
							*(base_ptr+4), 
							*(base_ptr+5), 
							*(base_ptr+6), 
							*(base_ptr+7)
							);
			break;
	
		case 8:
			(*(int (*)())proc_addr)(
							*(base_ptr+1), 
							*(base_ptr+2), 
							*(base_ptr+3), 
							*(base_ptr+4), 
							*(base_ptr+5), 
							*(base_ptr+6), 
							*(base_ptr+7), 
							*(base_ptr+8)
							);
			break;
	
		case 9:
			(*(int (*)())proc_addr)(
							*(base_ptr+1), 
							*(base_ptr+2), 
							*(base_ptr+3), 
							*(base_ptr+4), 
							*(base_ptr+5), 
							*(base_ptr+6), 
							*(base_ptr+7), 
							*(base_ptr+8), 
							*(base_ptr+9)
							);
			break;
		
		case 10:
			(*(int (*)())proc_addr)(
							*(base_ptr+1), 
							*(base_ptr+2), 
							*(base_ptr+3), 
							*(base_ptr+4), 
							*(base_ptr+5), 
							*(base_ptr+6), 
							*(base_ptr+7), 
							*(base_ptr+8), 
							*(base_ptr+9), 
							*(base_ptr+10)
							);
			break;
	
		case 11:
			(*(int (*)())proc_addr)(
							*(base_ptr+1), 
							*(base_ptr+2), 
							*(base_ptr+3), 
							*(base_ptr+4), 
							*(base_ptr+5), 
							*(base_ptr+6), 
							*(base_ptr+7), 
							*(base_ptr+8), 
							*(base_ptr+9), 
							*(base_ptr+10),
							*(base_ptr+11)
							);
			break;
	
		case 12:
			(*(int (*)())proc_addr)(
							*(base_ptr+1), 
							*(base_ptr+2), 
							*(base_ptr+3), 
							*(base_ptr+4), 
							*(base_ptr+5), 
							*(base_ptr+6), 
							*(base_ptr+7), 
							*(base_ptr+8), 
							*(base_ptr+9), 
							*(base_ptr+10),
							*(base_ptr+11),
							*(base_ptr+12)
							);
			break;
	
		
		default:
			RTFatal("the Translator supports a maximum of 12 arguments for tasks"); 
	}
	
	
	// task returns (i.e. it's finished and should now be terminated)
	terminate_task(current_task);
	
	scheduler(current_time()); // this call stack is going to die soon
}
#endif


void task_yield()
// temporarily stop running this task, and give the scheduler a chance
// to pick a new task
{   
	double now;
	
	now = current_time();
	if (tcb[current_task].status == ST_ACTIVE) {
		if (tcb[current_task].runs_left > 0) {
			tcb[current_task].runs_left -= 1;
		}
		
		if (tcb[current_task].type == T_REAL_TIME) {
			if (tcb[current_task].runs_max > 1 && 
				fabs(tcb[current_task].start - now) < 1e-6) {
				// Quick run of rapid-cycling task - clock hasn't even ticked.
				// N.B. due to f.p. fuzz, "equal" numbers might differ
				// in the 15th or so decimal digit.
				
				if (tcb[current_task].runs_left == 0) {
					// avoid excessive number of runs per clock period
					
					tcb[current_task].runs_left = tcb[current_task].runs_max;
					
					tcb[current_task].min_time = now + 
												 tcb[current_task].min_inc;
					tcb[current_task].max_time = now + 
												 tcb[current_task].max_inc;
				}
				else {
					// let it run multiple times per tick
				}
			}
			else {
				tcb[current_task].min_time = now + 
											 tcb[current_task].min_inc;
				tcb[current_task].max_time = now + 
											 tcb[current_task].max_inc;
			}
		}
	}
	scheduler(now);
}

static int task_insert(int first, int task)
// add a task to the appropriate list of tasks
{   
	tcb[task].next = first;
	return task;
}

static int which_task(double tid)
// find internal task number, given external task id
{   
	int i;
	char buff[40];
	
	for (i = 0; i < tcb_size; i++) {
		if (tcb[i].tid == tid) {
			return i;
		}
	}
	sprintf(buff, "Invalid task id: %10.3g", tid);
	RTFatal(buff);
}


void task_schedule(object task, object sparams)
// schedule a task by linking it into the real-time tcb queue,
// or the time sharing tcb queue
{
	
	double now, d;
	int repeats;
	object min, max;
	double min_dbl, max_dbl, dtask;
	
	if (IS_ATOM_INT(task))
		dtask = (double)task;
	else if (IS_ATOM_DBL(task))
		dtask = DBL_PTR(task)->dbl;
	else
		RTFatal("task id must not be a sequence");
	
	task = (object)which_task(dtask);
	
	if IS_ATOM(sparams) {
		// time-sharing
		if (IS_ATOM_INT(sparams)) {
			repeats = sparams;
		}
		else {
			d = DBL_PTR(sparams)->dbl;
			if (d <= 0.0 || d > MAXINT_DBL) {
				repeats = -1;
			}
			else {
				repeats = (int)d;
			}
		}
		if (repeats <= 0) {
			RTFatal("number of executions must be an integer value greater than 0");
		}
			
		//tcb[task].runs_left = repeats;  // current execution count
		tcb[task].runs_max = repeats;   // max execution count
		if (tcb[task].type == T_REAL_TIME) {
			rt_first = task_delete(rt_first, task);
		}
		if (tcb[task].type == T_REAL_TIME ||
			tcb[task].status == ST_SUSPENDED) {
			ts_first = task_insert(ts_first, task);
		}
		tcb[task].type = T_TIME_SHARE;
	}
	else {
		// real-time
		sparams = (object)SEQ_PTR(sparams);
			
		if (((s1_ptr)sparams)->length != 2) {
			RTFatal("second argument must be {min-time, max-time}");
		}
		min = *(((s1_ptr)sparams)->base+1);
		max = *(((s1_ptr)sparams)->base+2);
		if (IS_SEQUENCE(min) || IS_SEQUENCE(max)) {
			RTFatal("min and max times must be atoms");
		}
		if (IS_ATOM_INT(min))
			min_dbl = (double)min;
		else
			min_dbl = DBL_PTR(min)->dbl;
		if (IS_ATOM_INT(max))
			max_dbl = (double)max;
		else
			max_dbl = DBL_PTR(max)->dbl;
		if (min_dbl < 0.0 || max_dbl < 0.0) {
			RTFatal("min and max times must be greater than or equal to 0");
		}
		if (min_dbl > max_dbl) {
			RTFatal("task min time must be <= task max time");
		}
		tcb[task].min_inc = min_dbl;
		
		if (min_dbl < clock_period / 2.0) {
			// allow multiple runs per clock period
			if (min_dbl > 1.0e-9) {
				tcb[task].runs_max =  floor(clock_period / min_dbl);
			}
			else {
				// avoid divide by zero or almost zero
				tcb[task].runs_max = 1000000000;  // arbitrary, large
			}
		}
		else {
			tcb[task].runs_max = 1;
		}
		tcb[task].max_inc = max_dbl;
			
		now = current_time();
		tcb[task].min_time = now + min_dbl;
		tcb[task].max_time = now + max_dbl;
		tcb[task].start = now; // not exact
			
		if (tcb[task].type == T_TIME_SHARE) {
			ts_first = task_delete(ts_first, task);
		}
		if (tcb[task].type == T_TIME_SHARE ||
			   tcb[task].status == ST_SUSPENDED) {
			rt_first = task_insert(rt_first, task);
		}
		tcb[task].type = T_REAL_TIME;
	}
	tcb[task].status = ST_ACTIVE;
}

void task_suspend(object a)
// suspend a task
{
	double tid; // external task id
	int task;   // internal task number
	
	if (IS_ATOM_INT(a)) {
		tid = (double)a;
	}
	else if (IS_ATOM(a)) {
		tid = DBL_PTR(a)->dbl;
	}
	else {
		RTFatal("a task id must be an atom");
	}

	task = which_task(tid);
	
	tcb[task].status = ST_SUSPENDED;
	tcb[task].max_time = TASK_NEVER;
	
	if (tcb[task].type == T_REAL_TIME) {
		rt_first = task_delete(rt_first, task);
	}    
	else {  
		ts_first = task_delete(ts_first, task);
	}
}

object task_list()
// Make a sequence of the tid's of all non-dead tasks.
// Translator assumes they are all doubles.
{
	s1_ptr s;
	object ss;
	int i;
	
	s = (s1_ptr)NewS1(0);  // start with empty sequence
	ss = MAKE_SEQ(s);
	
	for (i = 0; i < tcb_size; i++) {
		if (tcb[i].status != ST_DEAD) {
			Append((object_ptr)&ss, ss, NewDouble(tcb[i].tid));
		}
	}
	
	return ss;
}

object task_status(object a)
{
	int r, t;
	double tid;
	
	if (IS_ATOM_INT(a)) {
		tid = (double)a;
	}
	else if (IS_ATOM(a)) {
		tid = DBL_PTR(a)->dbl;
	}
	else {
		RTFatal("a task id must be an atom");
	}
	r = -1;
	
	for (t = 0; t < tcb_size; t++) {
		if (tcb[t].tid == tid) {
			if (tcb[t].status == ST_ACTIVE) {
				r = 1;
			}
			else if (tcb[t].status == ST_SUSPENDED) {
				r = 0;
			}
			break;
		}
	}
	
	return r;
}

static double save_clock = -1.0;

void task_clock_stop()
// stop the scheduler clock 
{
	if (!clock_stopped) {
		save_clock = current_time();
		clock_stopped = TRUE;
	}
}

void task_clock_start()
// resume the scheduler clock   
{
	int i;
	double shift;
	
	if (clock_stopped) {
		if (save_clock >= 0 && save_clock < current_time()) {
			shift = current_time() - save_clock;
			for (i = 0; i < tcb_size; i++) {
				tcb[i].min_time += shift;
				tcb[i].max_time += shift;
			}
		}
		clock_stopped = FALSE;
	}
}

#ifdef EBORLAND
#pragma codeseg _DATA
// put task_create() and scheduler() into the DATA segment 
// so I can patch them at run-time
#endif

object task_create(object r_id, object args)
// Create a new task - return a double task id - assumed by Translator
{
	volatile int stack_top;  // magic variable set/read via ASM code
							 // force it to not be kept in a register
	symtab_ptr sub;
	struct tcb *new_entry;
	int recycle, recycle_size, i, j, proc_args;
	double id, t;
	int biggest, biggest_size, size;
	object_ptr word;
	
	r_id = (object)get_pos_int("task_create", r_id);

#ifdef ERUNTIME
	if ((unsigned)(r_id) >= 0xFFFFFF00) // small negatives will be caught
		RTFatal("invalid routine id");
#else   
	if ((unsigned)(r_id) >= e_routine_next)
		RTFatal("invalid routine id");
	sub = e_routine[r_id];
	
	if (sub->token != PROC) {
		RTFatal("specify the routine id of a procedure, not a function or type");
	}
#endif  
	
	if (!IS_SEQUENCE(args))
		RTFatal("Argument list must be a sequence");

#ifdef ERUNTIME
	proc_args = _00[r_id].num_args;
#else
	proc_args = sub->u.subp.num_args;
#endif  
	
	if (SEQ_PTR(args)->length != proc_args) {
		sprintf(TempBuff, 
		"Incorrect number of arguments (passing %d where %d are expected)",
		SEQ_PTR(args)->length, proc_args);
		RTFatal(TempBuff);
	}
	
	recycle = -1;
	recycle_size = -1;
#ifdef ERUNTIME 
	biggest = -1;
	biggest_size = -1;
#endif  
	for (i = 0; i < tcb_size; i++) { 
#ifdef ERUNTIME 
		if (tcb[i].status == ST_DEAD) {
			size = tcb[i].stack_size;
		}
		else {
			size = tcb[i].expr_top - tcb[i].expr_stack;
			word = (object_ptr)
				   (((char *)(tcb[i].expr_stack)) + tcb[i].stack_size/2);
			if (*word != STACK_MARKER) { 
				// high-water mark exceeds half its space
				// dangerous to split in half
				size = tcb[i].stack_size / 16; // try hard to avoid this block
			}
		}
		
		if (size > biggest_size) {
			biggest = i;
			biggest_size = size; // not real size
		}
#endif      
		if (tcb[i].status == ST_DEAD) {
			// this task is dead, can recycle its entry 
			// (but not its external task id)
			// try to pick ST_DEAD task with biggest stack space
			// (this mainly helps translated code, but also helps interpeter)
			if (tcb[i].stack_size > recycle_size) {
				recycle_size = tcb[i].stack_size;
				recycle = i;
			}
		}
	}
	
	if (recycle == -1) {
		// nothing is ST_DEAD, must expand the tcb
		tcb_size++;
		// n.b. tcb could get moved because of this:
		tcb = (struct tcb *)ERealloc(tcb, sizeof(struct tcb) * tcb_size);
		new_entry = &tcb[tcb_size-1];
	}
	else {
		// found a ST_DEAD task
#ifndef ERUNTIME
		// free the call stack 
		if (tcb[recycle].expr_stack != NULL) {
			EFree(tcb[recycle].expr_stack);
		}
#endif          
		DeRef(tcb[recycle].args);
		new_entry = &tcb[recycle];
	}
	
	// initially it's suspended
	new_entry->rid = r_id;  // always an integer - no Ref()
	
	new_entry->tid = next_task_id;
	new_entry->type = T_REAL_TIME;
	new_entry->status = ST_SUSPENDED;
	new_entry->start = 0.0;
	new_entry->min_inc = 0.0;
	new_entry->max_inc = 0.0;
	new_entry->min_time = 0.0;
	new_entry->max_time = TASK_NEVER;
	new_entry->runs_left = 1;
	new_entry->runs_max = 1;
	new_entry->next = -1; 
	
	new_entry->args = args;
	Ref(args);
	
	// interpreter sets these things when the task executes for the first time
	new_entry->pc = NULL;

#ifdef ERUNTIME
	if (recycle != -1) {
		// take over an existing tcb entry and its stack space
		// reset the mid-point stack marker, and stack top
		// full stack marker will have been checked even when task terminates
		word = (object_ptr)
			   (((char *)(tcb[recycle].expr_stack)) + tcb[recycle].stack_size/2);
		*word = (object)STACK_MARKER;
		tcb[recycle].expr_top = (object_ptr)
								(((char *)(tcb[recycle].expr_stack)) + 
										   tcb[recycle].stack_size);
	}
	else {  
		// we expanded the tcb, need a new stack space, 
		// take half of "biggest" space among ST_DEAD or not
		size = tcb[biggest].stack_size >> 3;
		size <<= 2; // half size, rounded down, 4-byte aligned

		new_entry->expr_stack = tcb[biggest].expr_stack; 
		// STACK_MARKER will still be there
		
		new_entry->stack_size = size;
		
		new_entry->expr_top = (object_ptr)
							  (((char *)(new_entry->expr_stack)) + size);
		
		word = (object_ptr)
			   (((char *)(new_entry->expr_stack)) + size/2);
		
		*word = (object)STACK_MARKER; // mid-point marker
		
		tcb[biggest].expr_stack = (object_ptr)
								(((char *)tcb[biggest].expr_stack) + size);
		
		*(tcb[biggest].expr_stack) = (object)STACK_MARKER; 
		
		tcb[biggest].stack_size = size; 
		
		word = (object_ptr)
			   (((char *)(tcb[biggest].expr_stack)) + size/2);
		
		
		// make sure current stack pointer is up-to-date for next two if's
		stack_top = 0; // try to force error if read_esp_tc is not right
		
		read_esp_tc(); // *** machine code *** 
		
		tcb[current_task].expr_top = (object_ptr)stack_top; 
		
		// will be updated again when current task yields
		
		if (tcb[biggest].expr_stack > tcb[biggest].expr_top) {
			sprintf(TempBuff, 
					"Task %.0f (%.40s) no longer has enough stack space (%d bytes)",
					tcb[biggest].tid, 
					(tcb[biggest].tid == 0.0) ? "initial task" : 
											  _00[tcb[biggest].rid].name,
					size);
			RTFatal(TempBuff);
		}
		
		if (tcb[biggest].expr_top > word) // don't overwrite live stack data
			*word = (object)STACK_MARKER; // mid-point marker
		
		// we might lose a word of high-memory stack due to rounding,
		// but I don't think it will matter
	}
#else
	new_entry->expr_max = NULL;
	new_entry->expr_limit = NULL;
	new_entry->expr_top = NULL;
	new_entry->expr_stack = NULL;
	new_entry->stack_size = 0;
#endif  
	
	id = next_task_id;
	
	// choose task id for next time
	if (!id_wrap && next_task_id < TASK_ID_MAX) {
		next_task_id += 1.0;
	}
	else {
		// extremely rare
		id_wrap = TRUE;  // id's have wrapped
		for (t = 1.0; t <= TASK_ID_MAX; t += 1.0) { 
			next_task_id = t;
			for (j = 0; j < tcb_size; j++) {
				if (next_task_id == tcb[j].tid) {
					next_task_id = 0.0;
					break;  // this id is still in use
				}
			}
			if (next_task_id > 0) {
				break;   // found unused id for next time
			}
		}
		// must have found one - couldn't have trillions of non-dead tasks!
	}
	
	return NewDouble(id);
}

// put these scheduler vars here for translated code, to avoid register 
// and/or stack corruption complications
static int earliest_task; 

void scheduler(double now)
// pick the next task to run
{
	volatile int stack_top;  // magic variable set/read via ASM code
							 // force it to not be kept in a register
	double earliest_time, start_time;
	int ts_found;
	struct tcb *tp;
	int p;
#ifndef ERUNTIME    
	static int **code[3];
	int stack_size;
#endif  
	// first check the real-time tasks
	
	// find the task with the earliest MAX_TIME
	earliest_task = rt_first;
	
	if (clock_stopped || earliest_task == -1) {
		// no real-time tasks are active
		start_time = 1.0;
		now = -1.0;
	}
	else {
		// choose a real-time task
		earliest_time = tcb[earliest_task].max_time;
		
		p = tcb[rt_first].next;
		while (p != -1) {
			tp = &tcb[p];
			if (tp->max_time < earliest_time) {
				earliest_task = p;
				earliest_time = tp->max_time;
			}
			p = tp->next;
		}
		
		// when can we start? how many runs?
		start_time = tcb[earliest_task].min_time;
		
		if (earliest_task == current_task && 
			tcb[current_task].runs_left > 0) {
			// runs left - continue with the current task
		}
		else {
			if (tcb[current_task].type == T_REAL_TIME) {
				tcb[current_task].runs_left = 0;
			}
			tcb[earliest_task].runs_left = tcb[earliest_task].runs_max;
		}
	}

	if (start_time > now) {
		// No real-time task is ready to run.
		// Look for a time-share task.
		
		ts_found = FALSE;
		p = ts_first;

		while (p != -1) {
			tp = &tcb[p];
			if (tp->runs_left > 0) {
				  earliest_task = p;
				  ts_found = TRUE;
				  break;
			}
			p = tp->next;
		}
		
		if (!ts_found) {
			// all time-share tasks are at zero, recharge them all, 
			// and choose one to run
			p = ts_first;
			while (p != -1) {
				tp = &tcb[p];
				earliest_task = p;
				tcb[p].runs_left = tp->runs_max;
				p = tp->next;
			}
		}
			
		if (earliest_task == -1) {
			// no tasks are active - no task will ever run again
			// RTFatal("no task to run") ??
			Cleanup(0);
		}
			
		if (tcb[earliest_task].type == T_REAL_TIME) {
			// no time-sharing tasks, Wait and run this real-time task
			now = Wait(start_time - now);
		}
	}

	/* we've chosen the task - now switch to it */

	tcb[earliest_task].start = now; //current_time(); 
	
	if (earliest_task == current_task) {
#ifndef ERUNTIME         
		 tpc += 1;  // continue with current task
#endif  
	}
	else {
#ifdef ERUNTIME     
		// switch to a new task
		//debug_msg("switching from");
		//if (tcb[current_task].rid == -1)
			//debug_msg("top_level");
		//else
			//debug_msg(_00[tcb[current_task].rid].name);
		//debug_msg("to");
		//if (tcb[earliest_task].rid == -1)
			//debug_msg("top_level");
		//else
			//debug_msg(_00[tcb[earliest_task].rid].name);
#endif      
		// save old task state
		
		//tp = &tcb[current_task];
		
#ifdef ERUNTIME     
		// save regs and current stack top
		push_regs(); // save regs onto stack
		read_esp();  // sets stack_top var
		
		tcb[current_task].expr_top = (object_ptr)stack_top;
		
		if ((object_ptr)stack_top < tcb[current_task].expr_stack ||
			*(tcb[current_task].expr_stack) != (object)STACK_MARKER) {
			sprintf(TempBuff,
					"Task %.0f (%.40s) exceeded its stack size limit of %d bytes",
					tcb[current_task].tid, 
					(tcb[current_task].tid == 0.0) ? "initial task" :
					 _00[tcb[current_task].rid].name,
					tcb[current_task].stack_size);
			RTFatal(TempBuff);
		}
#else       
		// save current stack info
		tp = &tcb[current_task];
		tp->pc = tpc; 
		tp->expr_stack = expr_stack;
		tp->expr_max = expr_max; 
		tp->expr_limit = expr_limit;
		tp->expr_top = expr_top;   
		tp->stack_size = stack_size;
#endif      
		
		// load new task 
		
		current_task = earliest_task;
	
		if (tcb[current_task].pc == NULL) {
			// first time we are running this task - no stack to restore
			// call its procedure, passing the args from task_create
#ifdef ERUNTIME
			// 1. Set the stack pointer to the task base level
			// 2. call the task routine, passing any number of args

			tcb[current_task].pc = (int *)1;  // i.e. not NULL
			
			stack_top = (int)(((char *)tcb[current_task].expr_stack) + 
									  (tcb[current_task].stack_size));
			// first word pushed by call will go at first word below the
			// next stack in memory
			set_esp(); 
			
			call_task(tcb[current_task].rid, tcb[current_task].args);
			// won't return here

#else
			InitStack(EXPR_SIZE, 0); // create its call stack
			
			// re-entrant? - ok, we use code right away
			// infinite calls to scheduler?
			code[0] = (int **)opcode(CALL_PROC);
			code[1] = (int **)&tcb[current_task].rid;
			code[2] = (int **)&tcb[current_task].args;
			tpc = (int *)&code;
#endif      
		}
		else {
			// Resuming an already-started task after a task_yield().
			// Must restore its stack.
#ifdef ERUNTIME
			// set stack top
			stack_top = (int)tcb[earliest_task].expr_top;
			set_esp(); // reads stack_top var
			
			pop_regs(); // restore saved regs (especially EBP)
			
#else
			// set up stack
			tp = &tcb[earliest_task];
			tpc = tp->pc;
			expr_stack = tp->expr_stack;
			expr_max = tp->expr_max;
			expr_limit = tp->expr_limit;
			expr_top = tp->expr_top;
			stack_size = tp->stack_size;
			restore_privates((symtab_ptr)expr_top[-1]);
			tpc += 1; 
#endif      
		}
	}
}

#ifdef EBORLAND
#pragma codeseg _DATA
void end_of_scheduler()
/* end marker */
{
}
#pragma codeseg
#endif

