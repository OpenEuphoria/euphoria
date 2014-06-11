#ifndef TASK_H_
#define TASK_H_

#include "execute.h"

extern int tcb_size;
extern int current_task;
extern double clock_period;

enum task_mode {
	INTERPRETED_TASK,
	TRANSLATED_TASK
};

#define T_REAL_TIME 1
#define T_TIME_SHARE 2
#define TASK_NEVER 1e300
#define TASK_ID_MAX 9e15 // wrap to 0 after this (and avoid in-use ones)

#ifdef EWINDOWS
#include <windows.h>

// Address to a fiber:
#define TASK_HANDLE LPVOID

#else

#include <pthread.h>

// PThread handle:
#define TASK_HANDLE pthread_t

#endif

struct interpreted_task{
	intptr_t *pc;         // program counter for this task
	object_ptr expr_stack; // call stack for this task
	object_ptr expr_max;   // current top limit of stack
	object_ptr expr_limit; // don't start a new routine above this
	object_ptr expr_top;   // stack pointer
	int stack_size;        // current size of stack
};

struct translated_task{
	TASK_HANDLE task;
	
};

// Task Control Block - sync with euphoria\include\euphoria.h
struct tcb {
	object rid;         // routine id
	double tid;      // external task id
	int type;        // type of task: T_REAL_TIME or T_TIME_SHARED
	int status;      // status: ST_ACTIVE, ST_SUSPENDED, ST_DEAD
	double start;    // start time of current run
	double min_inc;  // time increment for min
	double max_inc;  // time increment for max 
	double min_time; // minimum activation time
					 // or number of executions remaining before sharing
	double max_time; // maximum activation time (determines task order)
	int runs_left;   // number of executions left in this burst
	int runs_max;    // maximum number of executions in one burst
	int next;        // index of next task of the same kind
	object args;     // args to call task procedure with at startup
	
	int mode;  // TRANSLATED_TASK or INTERPRETED_TASK
	union task_impl {
		struct interpreted_task interpreted;
		struct translated_task translated;
	} impl;
	
};

extern struct tcb *tcb;

// TASK API:
void task_yield();
void task_schedule(object task, object sparams);
void task_suspend(object a);
object task_list();
object task_status(object a);
void task_clock_stop();
void task_clock_start();
object task_create(object r_id, object args);
void InitTask();
void terminate_task(int task);
void scheduler(double now);
void restore_privates(symtab_ptr this_routine);
double Wait(double t);
#endif
