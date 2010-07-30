#ifndef BE_EXECUTE_H_
#define BE_EXECUTE_H_

#include "execute.h"

/**********************/
/* Exported variables */
/**********************/
extern object_ptr expr_stack;  // runtime call stack
extern object_ptr expr_max;    // top limit of call stack
extern object_ptr expr_limit;  // don't start a new routine above this
extern long stack_size;         // current size of call stack
extern object_ptr expr_top;    // expression stack pointer
extern long SymTabLen;          // avoid > 3 args
extern long start_line;         // line number set by STARTLINE
extern long TraceBeyond;        // continue tracing after this line
extern long TraceStack;         // stack level when down-arrow was pressed
extern long Executing;          // TRUE if user program is executing
extern long ProfileOn;          // TRUE if profile/profile_time is turned on
extern char **file_name;
extern long max_stack_per_call;
extern long AnyTimeProfile;
extern long AnyStatementProfile;
extern long sample_size;

extern struct sline *slist;
extern struct IL fe;

extern long gline_number;  /* last global line number in program */
extern long il_file;       /* we are processing a separate .il file */

/* Euphoria program counter needed for traceback */
extern long *tpc;

#ifndef INT_CODES
#if defined(EUNIX) || defined(EMINGW) || defined(EWATCOM)
extern long **jumptab; // initialized in do_exec() 
#else
#ifdef EWATCOM
/* Jump table location is determined by another program. */
// extern long ** jumptab;
#else
#error Not supported use INT_CODES?
#endif
#endif // not GNU-C
#endif //not INT_CODES

void do_exec(long *start_pc);
void fe_set_pointers();
void Execute(long *start_index);
void InitStack(long size, long toplevel);
void InitExecute();

#endif
