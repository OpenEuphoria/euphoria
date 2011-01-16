#ifndef BE_SYMTAB_H
#define BE_SYMTAB_H

#include "symtab.h"
#include <stdint.h>

extern symtab_ptr TopLevelSub; /* symbol table pointer of top level procedure. */
						/* All user-defined symbols come after this */

extern symtab_ptr *e_routine;  /* array of symbol table pointers */
extern cleanup_ptr *e_cleanup; /* array of cleanup_ptr pointers */ 
extern intptr_t e_routine_next;     /* index of next available element */
symtab_ptr Locate(intptr_t *pc);
symtab_ptr RTLookup(char *name, int file, intptr_t *pc, symtab_ptr routine, int stlen, unsigned long current_line);
int FindLine(intptr_t *pc, symtab_ptr proc);
int RoutineId(symtab_ptr current_sub, object name, int file_no);
int PrivateName(char *name, symtab_ptr proc);
int ValidPrivate(symtab_ptr sym, symtab_ptr proc);

#endif
