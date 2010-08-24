#ifndef BE_EXECUTE_H_
#define BE_EXECUTE_H_

#include "execute.h"

/**********************/
/* Exported variables */
/**********************/
extern object_ptr expr_stack;  // runtime call stack
extern object_ptr expr_max;    // top limit of call stack
extern object_ptr expr_limit;  // don't start a new routine above this
extern eulong stack_size;         // current size of call stack
extern object_ptr expr_top;    // expression stack pointer
extern eulong SymTabLen;          // avoid > 3 args
extern eulong start_line;         // line number set by STARTLINE
extern eulong TraceBeyond;        // continue tracing after this line
extern eulong TraceStack;         // stack level when down-arrow was pressed
extern eulong Executing;          // TRUE if user program is executing
extern eulong ProfileOn;          // TRUE if profile/profile_time is turned on
extern char **file_name;
extern eulong max_stack_per_call;
extern eulong AnyTimeProfile;
extern eulong AnyStatementProfile;
extern eulong sample_size;

extern struct sline *slist;
extern struct IL fe;

extern eulong gline_number;  /* last global line number in program */
extern eulong il_file;       /* we are processing a separate .il file */

/* Euphoria program counter needed for traceback */
extern eulong *tpc;

#ifndef INT_CODES
#if defined(EUNIX) || defined(EMINGW) || defined(EWATCOM)
extern eulong **jumptab; // initialized in do_exec() 
#else
#ifdef EWATCOM
/* Jump table location is determined by another program. */
// extern eulong ** jumptab;
#else
#error Not supported use INT_CODES?
#endif
#endif // not GNU-C
#endif //not INT_CODES

void do_exec(eulong *start_pc);
void fe_set_pointers();
void Execute(eulong *start_index);
void InitStack(eulong size, long toplevel);
void InitExecute();

#endif
