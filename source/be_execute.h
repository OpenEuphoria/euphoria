#ifndef BE_EXECUTE_H_
#define BE_EXECUTE_H_

#include "execute.h"

/**********************/
/* Exported variables */
/**********************/
extern object_ptr expr_stack;  // runtime call stack
extern object_ptr expr_max;    // top limit of call stack
extern object_ptr expr_limit;  // don't start a new routine above this
extern int stack_size;         // current size of call stack
extern object_ptr expr_top;    // expression stack pointer
extern int SymTabLen;          // avoid > 3 args
extern int start_line;         // line number set by STARTLINE
extern int TraceBeyond;        // continue tracing after this line
extern int TraceStack;         // stack level when down-arrow was pressed
extern int Executing;          // TRUE if user program is executing
extern int ProfileOn;          // TRUE if profile/profile_time is turned on
extern char **file_name;
extern int max_stack_per_call;
extern int AnyTimeProfile;
extern int AnyStatementProfile;
extern int sample_size;

extern struct sline *slist;
extern struct IL fe;

extern int gline_number;  /* last global line number in program */
extern int il_file;       /* we are processing a separate .il file */

/* Euphoria program counter needed for traceback */
extern intptr_t *tpc;

#ifndef INT_CODES
#if defined(EUNIX) || defined(EMINGW) || defined(EWATCOM)
extern intptr_t **jumptab; // initialized in do_exec() 
#else
#ifdef EWATCOM
/* Jump table location is determined by another program. */
// extern int ** jumptab;
#else
#error Not supported use INT_CODES?
#endif
#endif // not GNU-C
#endif //not INT_CODES

void do_exec(intptr_t *start_pc);
void fe_set_pointers( void );
void Execute(intptr_t *start_index);
void InitStack(int size, int toplevel);
void InitExecute( void );

extern int map_new;
extern int map_put;
extern int map_get;

#endif
