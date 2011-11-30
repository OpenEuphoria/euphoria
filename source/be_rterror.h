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
/* Copies the alternative literal for s_ptr into val_string up to max_len characters are copied
 * including the null character, which is appended at the end.  The function returns the number
 * of characters copied.  If there is no alternative literal, it will return 0 for it will not
 * write to the string.  If there is an error while copying it will write a NULL character to the
 * first character of the string and return 1.  If the required space is greater than max_len, it
 * will return max_len and copy that many characters. */
unsigned int CopyLiteral(symtab_ptr s_ptr, char * val_string, unsigned int max_len);
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
