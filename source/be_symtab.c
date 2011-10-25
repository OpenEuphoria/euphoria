/*****************************************************************************/
/*      (c) Copyright - See License.txt       */
/*****************************************************************************/
/*                                                                           */
/*                BACK-END SYMBOL TABLE ACCESS ROUTINES                      */
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
#include <string.h>
#include <ctype.h>

#ifdef EWINDOWS
#include <windows.h>
#endif
#include "alldefs.h"
#include "be_execute.h"
#include "be_alloc.h"
#include "be_machine.h"
#include "be_runtime.h"

/**********************/
/* Exported variables */
/**********************/
symtab_ptr TopLevelSub;   /* symbol table pointer of top level procedure. */
						  /* All user-defined symbols come after this */

symtab_ptr *e_routine = NULL;  /* array of symbol table pointers */
cleanup_ptr *e_cleanup = NULL; /* array of cleanup_ptr pointers */ 
int e_routine_next = 0;       /* index of next available element */

/*******************/
/* Local variables */
/*******************/
static int e_routine_size = 0;   /* number of symbol table pointers allocated */

/**********************/
/* Declared functions */
/**********************/
#include "be_alloc.h"
/*********************/
/* Defined functions */
/*********************/

int PrivateName(char *name, symtab_ptr proc)
// does name match that of a private in the current active proc?
{
	symtab_ptr s;
	
	s = proc->next;
	while (s && s->scope <= S_PRIVATE) {
		if (strcmp(name, s->name) == 0)
			return TRUE;
		s = s->next;
	}
	return FALSE;
}


int ValidPrivate(symtab_ptr sym, symtab_ptr proc)
/* Is sym <= S_PRIVATE, a currently-valid PRIVATE or 
   LOOP_VAR for the trace screen? */
{
	symtab_ptr s;
	
	if (proc == TopLevelSub)
		return sym->scope == S_GLOOP_VAR;
	
	// does sym belong to the current active proc?
	s = proc->next;
	while (s && s->scope <= S_PRIVATE) {
		if (s == sym)
			return TRUE;
		s = s->next;
	}
	
	// does sym match the name of a global? 
	// If so, we should clear sym from screen just in case global
	// is in scope at this place in the code
	for (s = TopLevelSub->next; s != NULL; s = s->next) {
		if (s->scope > S_PRIVATE && strcmp(sym->name, s->name) == 0)
			return FALSE; // the global might be the active name at this moment
	}
	
	return sym->obj != NOVALUE; 
}

int FindLine(intptr_t *pc, symtab_ptr proc)
/* determine the global source line number for pc within proc */
{
	int pc_offset, code_offset;
	int lt, code_line;
	
	code_line = 0;
	if (proc->u.subp.linetab != NULL) {
		pc_offset = (pc - proc->u.subp.code) + 1;
		lt = 0;
		while (proc->u.subp.linetab[lt] != -2) {
			code_offset = proc->u.subp.linetab[lt];
			if (pc_offset <= code_offset) {
				break;
			}
			if (code_offset != -1)
				code_line = lt;  // ignore 0's in code offsets 
			lt++;
		}
	}
	return proc->u.subp.firstline + code_line; 
}

symtab_ptr last_s = NULL;
intptr_t *last_start;
intptr_t *last_end;

symtab_ptr Locate(intptr_t *pc)
/* find out which routine pc is in */
{
	symtab_ptr s;

	/* It helps profile report-generation performance if we remember 
	   the last routine that was found and it's code range. */
	
	if (last_s != NULL && pc >= last_start && pc <= last_end) {
		return last_s;
	}
	
	for (s = TopLevelSub; s != NULL; s = s->next) {
		if (s->token == PROC || s->token == FUNC || s->token == TYPE) {
			last_start = s->u.subp.code; // address of first word of IL
			last_end = last_start + *(uintptr_t *)(last_start - 1); 
			if (pc >= last_start && pc <= last_end) {
				last_s = s;
				return s;
			}
		}
	}
	return NULL; 
}

long block_contains_line( symtab_ptr block, unsigned long line){
// Make sure the line is inside of the block
	return (block == 0) || ((block->u.block.first_line <= line) && (block->u.block.last_line >= line));
}

symtab_ptr RTLookup(char *name, int file, intptr_t *pc, symtab_ptr routine, int stlen, unsigned long current_line )
/* Look up a name (routine or var) in the symbol table at runtime.
   The name must have been defined earlier in the source than
   where we are currently executing. The name may be a simple "name"
   or "ns:name". Speed is not too critical. This lookup is only used 
   in interactive trace mode, and in looking up routine id's, 
   which should normally only be done once for an indirectly-callable 
   routine. */
{
	symtab_ptr proc, s, global_found, stop;
	char *colon;
	char *p;
	char *ns;
	int ns_file;
	int found_in_path;
	int found_outside_path;
	int s_in_include_path;
	int did_find = 0;
	
	if (pc == NULL) {
		proc = routine;
	}
	else {
		proc = Locate(pc);
	}
	
	if (proc == NULL)
		return NULL;

	stop = &fe.st[stlen];
		
	colon = strchr(name, ':');
	
	if (colon != NULL) {
		/* look up "ns : name" */
		
		/* trim off any trailing whitespace from ns */
		p = colon-1;
		while ((*p == ' ' || *p == '\t') && p >= name) {
			p--;
		}
		*(p+1) = 0; 
	
		ns = name;
		
		/* trim off any leading whitespace from ns */
		while (*ns == ' ' || *ns == '\t')
			ns++;
		
		if (*ns == 0 || !strcmp( ns, "eu")) {
			return NULL;
		}

		/* step 1: look up NAMESPACE symbol */
		for (s = TopLevelSub->next; s != NULL; s = s->next) {
			if ( (fe.includes[file][s->file_no] & DIRECT_OR_PUBLIC_INCLUDE) && 
				s->token == NAMESPACE && strcmp(ns, s->name) == 0) {
				did_find = 1;
				break;
			}
			else if( s > stop && s->scope != S_PRIVATE ){
				break;
			}
		}
		
		if (!did_find)
			return NULL;

		if (s == NULL)
			return NULL;

		ns_file = s->obj;
		
		name = colon + 1;
		
		/* trim off any leading whitespace from name */
		while (*name == ' ' || *name == '\t')
			name++;
		
		/* find name in ns file */
		for (s = TopLevelSub->next; s != NULL && ( s <= stop || s->scope == S_PRIVATE); s = s->next) {
			if( (( s->scope == S_PUBLIC
					&& ( (s->file_no == ns_file && fe.includes[file][ns_file] & DIRECT_OR_PUBLIC_INCLUDE ) || 
						(fe.includes[ns_file][s->file_no] & PUBLIC_INCLUDE &&
						 fe.includes[file][ns_file] & DIRECT_OR_PUBLIC_INCLUDE)))
				||
				( s->scope == S_EXPORT
					&& s->file_no == ns_file && fe.includes[file][ns_file] & DIRECT_INCLUDE)
				||
				( s->scope == S_GLOBAL
					&& ( (s->file_no == ns_file  && fe.includes[file][ns_file] ) || 
						(fe.includes[ns_file][s->file_no] && fe.includes[file][ns_file] & DIRECT_OR_PUBLIC_INCLUDE)) )
				||
				( s->scope == S_LOCAL && ns_file == file && ns_file == s->file_no))
				&& strcmp(name, s->name) == 0) {
				return s;
			}
		}
		return NULL;
	}
	
	else {
		/* look up simple unqualified name */
				
		if (proc != TopLevelSub) {  
			/* inside a routine - check PRIVATEs and LOOP_VARs */
			for (s = proc->next; 
				 s != NULL && 
				 (s->scope == S_PRIVATE || s->scope == S_LOOP_VAR);
				s = s->next) {
				if ( (strcmp(name, s->name) == 0) && block_contains_line( s->u.var.declared_in, current_line) )
					return s;           
			}    
		}
		
		/* try to match a LOCAL, EXPORT or GLOBAL symbol in the same source file */
		for (s = TopLevelSub->next; s != NULL && ( s <= stop || s->scope == S_PRIVATE); s = s->next) {
			
			if (s->file_no == file ){
				
				switch( s->scope ){
					case S_GLOOP_VAR:
						if( proc != TopLevelSub ){
							// should only be able to see these at top level
							continue;
						}
					case S_LOCAL:
						if( !(s->token == PROC ||
								s->token == FUNC || 
								s->token == TYPE) &&
							!block_contains_line( s->u.var.declared_in, current_line ) ){
							// locals and loop vars should only be visible inside their blocks
							continue;
						}
					case S_GLOBAL:
					case S_PUBLIC:
					case S_EXPORT:
						if( strcmp(name, s->name) == 0) {  
							// shouldn't really be able to see GLOOP_VARs unless we are
							// currently inside the loop - only affects interactive var display
							return s;
						}
						break;
					
				}
			}
		} 
				
		/* try to match a single earlier GLOBAL or EXPORT symbol */
		global_found = NULL;
		found_in_path = 0;
		found_outside_path = 0;
		for (s = TopLevelSub->next; s != NULL && ( s <= stop || s->scope == S_PRIVATE); s = s->next) {
			if (s->scope == S_GLOBAL && strcmp(name, s->name) == 0) {
			
				s_in_include_path = fe.includes[file][s->file_no] != NOT_INCLUDED; // symbol_in_include_path( s, file, NULL );
				if ( s_in_include_path){
					global_found = s;
					found_in_path++;
				}
				else{
					if(!found_in_path) global_found = s;
					found_outside_path++;
				}
			}
			else if( ((s->scope == S_EXPORT && (fe.includes[file][s->file_no] & DIRECT_INCLUDE)) 
				|| (s->scope == S_PUBLIC && (fe.includes[file][s->file_no] & DIRECT_OR_PUBLIC_INCLUDE) ) ) 
				&& strcmp(name, s->name) == 0){
					global_found = s;
					found_in_path++;
			}

		} 
		
		if(found_in_path != 1 && ((found_in_path + found_outside_path) != 1) ){
				return NULL;
		}
		return global_found;
	}
}

int RoutineId(symtab_ptr current_sub, object name, int file_no)
/* Look up routine name in symbol table.
   The routine must be defined before the currently executing line. */
{
	char *routine_string;
	s1_ptr routine_ptr;
	symtab_ptr p;
	int i;
	
	if (IS_ATOM(name))
		return ATOM_M1;

	routine_ptr = SEQ_PTR(name);
	
	if (routine_ptr->length >= TEMP_SIZE)
		return ATOM_M1;

	routine_string = (char *)&TempBuff;
	MakeCString(routine_string, name, TEMP_SIZE);

	p = RTLookup(routine_string, file_no, NULL, current_sub, *(int*)fe.st, 0); 

	if (p == NULL || (p->token != PROC && 
					  p->token != FUNC &&
					  p->token != TYPE))
		return ATOM_M1;

	for (i = 0; i < e_routine_next; i++) {
		if (e_routine[i] == p)
			return i;  // routine was already assigned an id
	}
	
	if (e_routine_next >= e_routine_size) {
		if (e_routine == NULL) {
			e_routine_size = 20;
			e_routine = (symtab_ptr *)EMalloc(e_routine_size * sizeof(symtab_ptr));
			e_cleanup = (cleanup_ptr*) EMalloc( e_routine_size * sizeof(cleanup_ptr) );
			for( i = e_routine_size - 20; i < e_routine_size; ++i ){
				e_cleanup[i] = 0;
			}
		}
		else {
			e_routine_size += 20;
			e_routine = (symtab_ptr *)ERealloc((char *)e_routine, 
								 e_routine_size * sizeof(symtab_ptr));
			e_cleanup = (cleanup_ptr*) ERealloc( (char *)e_cleanup, e_routine_size * sizeof(cleanup_ptr) );
			for( i = e_routine_size - 20; i < e_routine_size; ++i ){
				e_cleanup[i] = 0;
			}
			
		}
	}
	
	e_routine[e_routine_next] = p; // save the symtab_ptr
	 
	return e_routine_next++;
}

