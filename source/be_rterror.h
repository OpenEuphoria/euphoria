#ifndef BE_RTERROR_H_
#define BE_RTERROR_H_

#include <stdint.h>

void RTFatalType(intptr_t *pc)
#ifdef EUNIX
__attribute__ ((noreturn))
#endif
;

extern int traced_lines;
extern int *TraceLineBuff;     /* place to store traced lines */
extern int TraceLineSize;      /* size of buffer */
extern int TraceLineNext;      /* place to put next line */
extern int color_trace;        /* display trace screen in multiple colors */
extern int file_trace;         /* log statements to ctrace.out */
extern int trace_enabled;      /* flag to disable tracing */
extern char *type_error_msg;   /* changeable message */

void InitTraceWindow();
void InitDebug();

void GetViewPort(struct EuViewPort *vp);
void SubsAtomAss();
void SubsNotAtom();
void EraseSymbol(symtab_ptr sym);
void ErasePrivates(symtab_ptr proc_ptr);
void DisplayVar(symtab_ptr s_ptr, int user_requested);
void DebugScreen();
void UpdateGlobals();
void ShowDebug();
object_ptr BiggerStack();
void atom_condition();
void MainScreen();
void RangeReading(object subs, int len);
void BadSubscript(object subs, int length);
void NoValue(symtab_ptr s);

void CleanUpError_va(char *msg, symtab_ptr s_ptr, va_list ap)
#if defined(EUNIX) || defined(EMINGW)
 __attribute__ ((noreturn))
#else
#pragma aux CleanUpError_va aborts;
#endif
;

#endif
