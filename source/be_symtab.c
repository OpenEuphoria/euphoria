/*****************************************************************************/
/*      (c) Copyright 2007 Rapid Deployment Software - See License.txt       */
/*****************************************************************************/
/*                                                                           */
/*                BACK-END SYMBOL TABLE ACCESS ROUTINES                      */
/*                                                                           */
/*****************************************************************************/

/******************/
/* Included files */
/******************/
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#ifdef EWINDOWS
#include <windows.h>
#endif
#include "alldefs.h"

/******************/
/* Local defines  */
/******************/

/**********************/
/* Imported variables */
/**********************/
extern struct sline *slist;
extern unsigned char TempBuff[];
extern int gline_number;
extern struct IL fe;
extern int SymTabLen; // avoid > 3 args
extern unsigned default_heap;

/**********************/
/* Exported variables */
/**********************/
symtab_ptr TopLevelSub;   /* symbol table pointer of top level procedure. */
			  /* All user-defined symbols come after this */

symtab_ptr *e_routine = NULL; /* array of symbol table pointers */
int e_routine_next = 0;       /* index of next available element */

/*******************/
/* Local variables */
/*******************/
static int e_routine_size = 0;   /* number of symbol table pointers allocated */

/**********************/
/* Declared functions */
/**********************/
#ifndef ESIMPLE_MALLOC
char *EMalloc();
#else
#include "alloc.h"
#endif
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

int FindLine(int *pc, symtab_ptr proc)
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
int *last_start;
int *last_end;

symtab_ptr Locate(int *pc)
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
	    last_end = last_start + *(unsigned *)(last_start - 1); 
	    if (pc >= last_start && pc <= last_end) {
		last_s = s;
		return s;
	    }
	}
    }
    return NULL; 
}

int symbol_in_include_path( symtab_ptr sym, int check_file, char * checked_file )
/* Determines if sym is in the include path of file #check_file */
{
    int i;
    int node_file;
    int file_no = sym->file_no;
    char * files;
    struct include_node * node;
    
    
    if( file_no == check_file ) return 1;
    
    node = fe.includes->nodes + check_file;
    files = NULL;
    if( checked_file == NULL ){
    	files = malloc( fe.misc[0] +1 );
    	memset( files, 0, fe.misc[0] + 1 );
    	checked_file = files;
    }
    else if( checked_file[check_file] ) return 0;
    checked_file[check_file] = 1;
    
    for( i = 0; i < node->size; i++ ){
	node_file = *( node->file_no + i);
	if( file_no == node_file || symbol_in_include_path( sym, node_file, checked_file ) ){
	    free(files);
	    return 1;
	}
    }
    free(files);
    return 0;
}

symtab_ptr RTLookup(char *name, int file, int *pc, symtab_ptr routine, int stlen)
/* Look up a name (routine or var) in the symbol table at runtime.
   The name must have been defined earlier in the source than
   where we are currently executing. The name may be a simple "name"
   or "ns:name". Speed is not too critical. This lookup is only used 
   in interactive trace mode, and in looking up routine id's, 
   which should normally only be done once for an indirectly-callable 
   routine. */
{
    symtab_ptr proc, s, global_found, stop, current_s;
    char *colon;
    char *p;
    char *ns;
    int ns_file;
    int found_in_path;
    int found_outside_path;
    int s_in_include_path;

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
	
	if (*ns == 0) {
	    return NULL;
	}

	/* step 1: look up NAMESPACE symbol */
	for (s = TopLevelSub->next; s != NULL && s <= stop; s = s->next) {
	    if (file == s->file_no && 
		s->token == NAMESPACE && strcmp(ns, s->name) == 0) {
		break;
	    }
	}
	
	if (s == NULL)
	    return NULL;

	ns_file = s->obj;
	
	name = colon + 1;
	
	/* trim off any leading whitespace from name */
	while (*name == ' ' || *name == '\t')
	    name++;
	
	/* find global name in ns file */
	for (s = TopLevelSub->next; s != NULL && s <= stop; s = s->next) {
	    if ((s->file_no == ns_file || symbol_in_include_path( s, ns_file, NULL) ) && 
		s->scope == S_GLOBAL && strcmp(name, s->name) == 0) {
		return s;
	    }
	}
	return NULL;
    }
    
    else {
	/* look up simple unqualified name */
        current_s = 0;
	if (proc != TopLevelSub) {
	    /* inside a routine - check PRIVATEs and LOOP_VARs */
	    for (s = proc->next; 
		 s != NULL && 
		 (s->scope == S_PRIVATE || s->scope == S_LOOP_VAR);
		s = s->next) {
		if (strcmp(name, s->name) == 0)
                    current_s = s;
	    }
            if (current_s != 0) return current_s;
	}

	/* try to match a LOCAL or GLOBAL symbol in the same source file */
	for (s = TopLevelSub->next; s != NULL && s <= stop; s = s->next) {
	    if (s->file_no == file && 
	      (s->scope == S_LOCAL || s->scope == S_GLOBAL ||
	      (proc == TopLevelSub && s->scope == S_GLOOP_VAR)) &&
	      strcmp(name, s->name) == 0) {
		// shouldn't really be able to see GLOOP_VARs unless we are
		// currently inside the loop - only affects interactive var display
		current_s = s;
	    }
	}
        if (current_s != 0) return current_s;

	/* try to match a single earlier GLOBAL symbol */
	global_found = NULL;
	found_in_path = 0;
	found_outside_path = 0;
	for (s = TopLevelSub->next; s != NULL && s <= stop; s = s->next) {
	    if (s->scope == S_GLOBAL && strcmp(name, s->name) == 0) {  
		
		s_in_include_path = symbol_in_include_path( s, routine->file_no, NULL );
		if ( s_in_include_path){
		    global_found = s;
		    found_in_path++;
		}
		else{
		    if(!found_in_path) global_found = s;
		    found_outside_path;
		}
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
    MakeCString(routine_string, name);

    p = RTLookup(routine_string, file_no, NULL, current_sub, SymTabLen); 

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
	}
	else {
	    e_routine_size += 20;
	    e_routine = (symtab_ptr *)ERealloc((char *)e_routine, 
				 e_routine_size * sizeof(symtab_ptr));
	}
    }
    
    e_routine[e_routine_next] = p; // save the symtab_ptr
     
    return e_routine_next++;
}

