/*****************************************************************************/
/*                                                                           */
/*                   RUN-TIME SYMBOL TABLE INCLUDE FILE                      */
/*                                                                           */
/*****************************************************************************/

#ifndef _SYMTAB_H_
#define _SYMTAB_H_ 1

#include <stdint.h>

// N.B.!!! fields and size of backend symtab_entry is assumed in backend.e 

// for literal constants and temporaries 
struct temp_entry { // must match symtab_entry 
	object obj;     // initialized for literal values, NOVALUE for temps 
	struct temp_entry *next;  // pointer to next temp, or NULL 
	struct symtab_entry *next_in_block; // next entry in the same scope
	char mode;    // M_TEMP or M_CONSTANT 
	char scope;   // compile time: FREE or IN_USE or DELETED (Compiler-only) 
	unsigned char file_no; // don't care 
	unsigned char dummy;   // not used 
	
};

struct symtab_entry {
	object obj;   // initialized for literal constants, 
				  // NOVALUE for other temps 
				  // run time object (vars)  
				  // must be first field 
	struct symtab_entry *next;  // pointer to next symbol, or NULL
	struct symtab_entry *next_in_block; // next entry in the same scope
	char mode;      
#define M_NORMAL   1      // all variables      
#define M_CONSTANT 2      // literals and declared constants 
#define M_TEMP     3      // temporaries 
#define M_BLOCK    4      // blocks

	char scope;         // scope as below: 
#define S_LOOP_VAR  2   // "private" loop vars known within a single loop 
#define S_PRIVATE   3   // private within subprogram 
#define S_GLOOP_VAR 4   // "global" loop var  
#define S_LOCAL     5   // local to the file 
#define S_GLOBAL    6   // global across all files 
#define S_PREDEF    7   // predefined symbol - could be overriden 
#define S_KEYWORD   8   // a keyword 
#define S_UNDEFINED 9   // new undefined symbol 
#define S_MULTIPLY_DEFINED 10  // global symbol defined in 2 or more other files 
#define S_EXPORT   11   // visible to any file that includes it
#define S_OVERRIDE 12   // overrides a built in
#define S_PUBLIC   13   // visible to any file that includes it (or through "export public"

	unsigned char file_no; // file number symbol defined in 

	unsigned char dummy;  // not used - extend file_no? 
	
	int token;      // parsing token - could be just 2 bytes 
	char *name;     // name string 
	
	union {
		struct {
			// for variables only: 
		   struct symtab_entry *declared_in;
		} var;
		struct {
			// for subprograms only: 
			intptr_t *code;          // start of proc/func/type 
			struct symtab_entry *temps;  // pointer to list of temps, or NULL 
			struct private_block *saved_privates;  // pointer to list of private blocks 
			struct symtab_entry *block; // the scope for the routine
			int *linetab;       // line table for traceback 
			unsigned firstline; // global line number of start of routine 
			unsigned num_args; // number of arguments - could be just 1 byte 
			int resident_task; // task that's currently executing in this routine or -1
			unsigned int stack_space; // set by fe - stack required 
		} subp;
		struct {
			// for blocks only:
			unsigned int first_line;
			unsigned int last_line;
		} block;
		
	} u;
	
	
};  /* size=60 bytes assumed in backend.e */ 

typedef struct symtab_entry *symtab_ptr; 
typedef struct temp_entry *temp_ptr;

#endif // _SYMTAB_H_
