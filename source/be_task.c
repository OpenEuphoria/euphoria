/*****************************************************************************/
/*      (c) Copyright - See License.txt       */
/*****************************************************************************/
/*                                                                           */
/*                            Multitasking                                   */
/*                                                                           */
/*****************************************************************************/

/******************/
/* Included files */
/******************/
#include <stdint.h>
#if defined(EWINDOWS) && INTPTR_MAX == INT64_MAX
// MSVCRT doesn't handle long double output correctly
#define __USE_MINGW_ANSI_STDIO 1
#endif
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#ifdef EWINDOWS
#include <windows.h> /* for Sleep(), Fibers */
#endif

#include "global.h"
#include "execute.h"
#include "symtab.h"
#include "reswords.h"
#include "be_runtime.h"
#include "be_task.h"
#include "be_alloc.h"
#include "be_machine.h"

#ifndef ERUNTIME
#include "be_execute.h"
#include "be_symtab.h"
#endif
/*********************/
/* Local definitions */
/*********************/
#ifndef EWINDOWS

pthread_mutex_t task_mutex;
pthread_cond_t  task_condition;
pthread_t       task_thread;
#endif

/**********************/
/* Exported variables */
/**********************/
struct tcb *tcb;
int tcb_size;
int current_task;
// Windows/Linux/FreeBSD
double clock_period = 0.01;  // should check this at run-time

/*******************/
/* Local variables */
/*******************/
static int rt_first, ts_first;
static int clock_stopped = FALSE;
static int id_wrap = FALSE; // have task id's wrapped around? (very rare)
static double next_task_id = 1.0;


/*********************/
/* Declared functions */
/*********************/

#include "alldefs.h"
static void init_task( intptr_t tx );
static void run_current_task( int task );

/*********************/
/* Defined functions */
/*********************/

void InitTask()
// initialize the first (top-level) task - task id 0
{   
	
	
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
	
#ifdef ERUNTIME 
	tcb[0].mode = TRANSLATED_TASK;
#ifdef EWINDOWS
	tcb[0].impl.translated.task = ConvertThreadToFiber( 0 );
#else
	tcb[0].impl.translated.task = pthread_self();
	pthread_mutex_init( &task_mutex, NULL );
	pthread_cond_init(  &task_condition, NULL );
	task_thread = 0;
#endif
#else
	// I don't think this is correct (unless we're assuming this for the front end to use).
	// I'm trying to leave this prospect open, but not worrying too much about it right now.
	//tcb[0].impl.translated.task = pthread_self();
	//pthread_mutex_init(&global_mutex, NULL); // TODO error handling
	//pthread_mutex_lock(&global_mutex);

	tcb[0].mode = INTERPRETED_TASK;
	// these things will be set when task 0 yields for the first time
	tcb[0].impl.interpreted.pc = (intptr_t *)1; 
	tcb[0].impl.interpreted.expr_max = NULL;
	tcb[0].impl.interpreted.expr_limit = NULL;
	tcb[0].impl.interpreted.expr_top = NULL;
	tcb[0].impl.interpreted.expr_stack = NULL;
	tcb[0].impl.interpreted.stack_size = 0; 
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
	if( tcb[task].mode == TRANSLATED_TASK ){
		tcb[task].impl.translated.task = (TASK_HANDLE) 0;
	}
}

double Wait(double t)
// Wait for a while 
{   
#ifdef EWINDOWS

	Sleep( floor(1000.0 * t) );
	
#else // EWINDOWS
	
	double t_int, t_frac;
	int it;
	long itsme;
	struct timespec req;

	t_int  = floor(t);
	it     = (int) t_int;
	t_frac = t - t_int;
	itsme  = (long) floor(1000000000.0 * t_frac);

	req.tv_sec  = it;
	req.tv_nsec = itsme;
	nanosleep(&req, NULL);
	
#endif // EUNIX
	return current_time();
}

// Created by the translator:
extern struct routine_list _00[];
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
			(*(object (*)())proc_addr)(
							);
			break;
		
		case 1:
			(*(object (*)())proc_addr)(
							*(base_ptr+1)
							);
			break;
		
		case 2:
			(*(object (*)())proc_addr)(
							*(base_ptr+1), 
							*(base_ptr+2)
							);
			break;
		
		case 3:
			(*(object (*)())proc_addr)(
							*(base_ptr+1), 
							*(base_ptr+2), 
							*(base_ptr+3)
							);
			break;
	
		case 4:
			(*(object (*)())proc_addr)(
							*(base_ptr+1), 
							*(base_ptr+2), 
							*(base_ptr+3), 
							*(base_ptr+4)
							);
			break;
	
		case 5:
			(*(object (*)())proc_addr)(
							*(base_ptr+1), 
							*(base_ptr+2), 
							*(base_ptr+3), 
							*(base_ptr+4), 
							*(base_ptr+5)
							);
			break;
	
		case 6:
			(*(object (*)())proc_addr)(
							*(base_ptr+1), 
							*(base_ptr+2), 
							*(base_ptr+3), 
							*(base_ptr+4), 
							*(base_ptr+5), 
							*(base_ptr+6)
							);
			break;
	
		case 7:
			(*(object (*)())proc_addr)(
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
			(*(object (*)())proc_addr)(
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
			(*(object (*)())proc_addr)(
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
			(*(object (*)())proc_addr)(
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
			(*(object (*)())proc_addr)(
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
			(*(object (*)())proc_addr)(
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

	
	for (i = 0; i < tcb_size; i++) {
		if (tcb[i].tid == tid) {
			return i;
		}
	}
	RTFatal("Invalid task id: %10.3g", tid);
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
				tcb[task].runs_max =  EUFLOOR(clock_period / min_dbl);
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

#ifndef ERUNTIME
object task_create(object r_id, object args)
// Create a new task for the interpreter - return a double task id - assumed by Translator
{
	symtab_ptr sub;
	struct tcb *new_entry;
	int recycle, recycle_size, i, j, proc_args;
	double id, t;
	
	
	
	r_id = (object)get_pos_int("task_create", r_id);

  
	if ( r_id >= e_routine_next)
		RTFatal("invalid routine id");
	sub = e_routine[r_id];
	
	if (sub->token != PROC) {
		RTFatal("specify the routine id of a procedure, not a function or type");
	} 
	
	if (!IS_SEQUENCE(args))
		RTFatal("Argument list must be a sequence");

	proc_args = sub->u.subp.num_args; 
	
	if (SEQ_PTR(args)->length != proc_args) {
		RTFatal("Incorrect number of arguments (passing %d where %d are expected)",
				SEQ_PTR(args)->length, proc_args);
	}
	
	recycle = -1;
	recycle_size = -1;
 
	for (i = 0; i < tcb_size; i++) {  
		if (tcb[i].status == ST_DEAD) {
			// this task is dead, can recycle its entry 
			// (but not its external task id)
			// try to pick ST_DEAD task with biggest stack space
			// (this mainly helps translated code, but also helps interpeter)
			if (tcb[i].impl.interpreted.stack_size > recycle_size) {
				recycle_size = tcb[i].impl.interpreted.stack_size;
				recycle = i;
			}
		}
	}
	
	if (recycle == -1) {
		// nothing is ST_DEAD, must expand the tcb
		tcb_size++;
		// n.b. tcb could get moved because of this:
		tcb = (struct tcb *)ERealloc((char *)tcb, sizeof(struct tcb) * tcb_size);
		new_entry = &tcb[tcb_size-1];
	}
	else {
		// found a ST_DEAD task
		// release the call stack 
		if (tcb[recycle].impl.interpreted.expr_stack != NULL) {
			EFree((char *)tcb[recycle].impl.interpreted.expr_stack);
		}
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
	new_entry->mode = INTERPRETED_TASK;
	
	new_entry->args = args;
	Ref(args);
	
	// interpreter sets these things when the task executes for the first time
	new_entry->impl.interpreted.pc = NULL;


	new_entry->impl.interpreted.expr_max = NULL;
	new_entry->impl.interpreted.expr_limit = NULL;
	new_entry->impl.interpreted.expr_top = NULL;
	new_entry->impl.interpreted.expr_stack = NULL;
	new_entry->impl.interpreted.stack_size = 0;
	
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
#endif

TASK_HANDLE stale_task = 0;

void release_task( TASK_HANDLE task ){
	#ifdef EWINDOWS
	DeleteFiber( task );
	#else
	pthread_cancel( task );
	#endif
}

void release_task_later( TASK_HANDLE task ){
	if( stale_task != 0 ){
		release_task( stale_task );
	}
	stale_task = task;
}

object ctask_create(object r_id, object args)
// Create a new task for translated code - return a double task id - assumed by Translator
{
	
	
	struct tcb *new_entry;
	int recycle, i, j, proc_args;
	double id, t;
	
	
	r_id = (object)get_pos_int("task_create", r_id);

	if ((unsigned)(r_id) >= 0xFFFFFF00) // small negatives will be caught
		RTFatal("invalid routine id");

	if (!IS_SEQUENCE(args))
		RTFatal("Argument list must be a sequence");

	proc_args = _00[r_id].num_args;

	
	if (SEQ_PTR(args)->length != proc_args) {
		RTFatal("Incorrect number of arguments (passing %d where %d are expected)",
				SEQ_PTR(args)->length, proc_args);
	}
	
	recycle = -1;

	for (i = 0; i < tcb_size; i++) { 
    
		if (tcb[i].status == ST_DEAD) {
			// this task is dead, can recycle its entry 
			// (but not its external task id)
			recycle = i;
			break;
		}
	}
	
	if (recycle == -1) {
		// nothing is ST_DEAD, must expand the tcb
		tcb_size++;
		// n.b. tcb could get moved because of this:
		tcb = (struct tcb *)ERealloc((char *)tcb, sizeof(struct tcb) * tcb_size);
		new_entry = &tcb[tcb_size-1];
		recycle = tcb_size-1;
	}
	else {
		// found a ST_DEAD task
		DeRef(tcb[recycle].args);
		new_entry = &tcb[recycle];
		if( new_entry->mode == TRANSLATED_TASK && new_entry->impl.translated.task != 0 ){
			if( recycle == current_task ){
				// we can't release it from itself, or the entire proces would die
				release_task_later( new_entry->impl.translated.task );
			}
			else{
				release_task( new_entry->impl.translated.task );
			}
		}
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
	new_entry->mode = TRANSLATED_TASK;
	
	new_entry->args = args;
	Ref(args);
	
	// interpreter sets these things when the task executes for the first time
	new_entry->impl.translated.task = (TASK_HANDLE) NULL;

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
	init_task( recycle );
	return NewDouble(id);
}

// put these scheduler vars here for translated code, to avoid register 
// and/or stack corruption complications
static int earliest_task; 

void run_task( int tx ){
#ifndef ERUNTIME
	static intptr_t **code[3];
	if( tcb[tx].mode == INTERPRETED_TASK ){
		struct tcb *tp;
		
		// save current stack info
		tp = &tcb[current_task];
		tp->impl.interpreted.pc = tpc; 
		tp->impl.interpreted.expr_stack = expr_stack;
		tp->impl.interpreted.expr_max   = expr_max; 
		tp->impl.interpreted.expr_limit = expr_limit;
		tp->impl.interpreted.expr_top   = expr_top;   
		tp->impl.interpreted.stack_size = stack_size;
		
		// load new task 
		
		current_task = earliest_task;
	
		if (tcb[current_task].impl.interpreted.pc == NULL) {
			// first time we are running this task - no stack to restore
			// call its procedure, passing the args from task_create

			InitStack(EXPR_SIZE, 0); // create its call stack
			
			// re-entrant? - ok, we use code right away
			// infinite calls to scheduler?
			code[0] = (intptr_t **)opcode(CALL_PROC);
			code[1] = (intptr_t **)&tcb[current_task].rid;
			code[2] = (intptr_t **)&tcb[current_task].args;
			tpc = (intptr_t *)&code;
		}
		else {
			// Resuming an already-started task after a task_yield().
			// Must restore its stack.
			// set up stack
			tp = &tcb[earliest_task];
			tpc = tp->impl.interpreted.pc;
			expr_stack = tp->impl.interpreted.expr_stack;
			expr_max = tp->impl.interpreted.expr_max;
			expr_limit = tp->impl.interpreted.expr_limit;
			expr_top = tp->impl.interpreted.expr_top;
			stack_size = tp->impl.interpreted.stack_size;
			restore_privates((symtab_ptr)expr_top[-1]);
			tpc += 1;    
		}
	}
	else
#endif // !ERUNTIME 
	{ // TRANSLATED_TASK
		
		if ( (tcb[earliest_task].impl.translated.task == (TASK_HANDLE)NULL) ){
			// first time we are running this task
			init_task( earliest_task );
			
		}
		
		run_current_task( earliest_task );
	}
}



#ifdef EWINDOWS

static void run_current_task( int task ){
	current_task = task;
	SwitchToFiber( tcb[current_task].impl.translated.task );
}

void WINAPI exec_task( void *task ){
	struct tcb *t = &tcb[(intptr_t)task];

	call_task( t->rid, t->args );
}

static void init_task( intptr_t tx ){
	// fibers...
	tcb[tx].impl.translated.task = (TASK_HANDLE) CreateFiber( 0, exec_task, (void *)tx );
}

#else

/**
 * Only allows the current thread to continue if it belongs to the current task.
 */
void wait_for_task( int task ){
	pthread_mutex_lock( &task_mutex );
	while( current_task != task ){
		pthread_cond_wait( &task_condition, &task_mutex );
	}
}

/**
 * This is where a new thread/task starts.  It waits for its turn before
 * calling the task's procedure.
 */
void *start_task( void *task ){
	wait_for_task( (intptr_t) task );
	call_task( tcb[(intptr_t)task].rid, tcb[(intptr_t)task].args );
	return task;
}

/**
 * Creates the thread where the new task will run.
 */


static void init_task( intptr_t tx ){
	pthread_create( &tcb[tx].impl.translated.task, NULL, &start_task, (void*)tx );
	// TODO error handling
}

/**
 * Changes the value of the current_task to @task, then signals the waiting 
 * threads to see if they should be running, after which it calls wait_for_task().
 */
static void run_current_task( int task ){
	int this_task = current_task;
	current_task = task;
	pthread_cond_broadcast( &task_condition );
	pthread_mutex_unlock( &task_mutex );
	wait_for_task( this_task );
}
#endif

void scheduler(double now)
// pick the next task to run
{
	double earliest_time, start_time;
	int ts_found;
	struct tcb *tp;
	int p;

	
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
		run_task( earliest_task );
	}
}
