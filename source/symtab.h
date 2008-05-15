/*****************************************************************************/
/*                                                                           */
/*                   RUN-TIME SYMBOL TABLE INCLUDE FILE                      */
/*                                                                           */
/*****************************************************************************/

// N.B.!!! fields and size of backend symtab_entry is assumed in backend.e 

// for literal constants and temporaries 
struct temp_entry { // must match symtab_entry 
	object obj;     // initialized for literal values, NOVALUE for temps 
	struct temp_entry *next;  // pointer to next temp, or NULL 
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
	char mode;      
#define M_NORMAL   1      // all variables      
#define M_CONSTANT 2      // literals and declared constants 
#define M_TEMP     3      // temporaries 

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

	unsigned char file_no; // file number symbol defined in 

	unsigned char dummy;  // not used - extend file_no? 
	
	char *name;     // name string 
	int token;      // parsing token - could be just 2 bytes 
	
	union {
		struct {
			// for variables only: 
		   char dummy;
		} var;
		struct {
			// for subprograms only: 
			int *code;          // start of proc/func/type 
			int *linetab;       // line table for traceback 
			unsigned firstline; // global line number of start of routine 
			struct symtab_entry *temps;  // pointer to list of temps, or NULL 
			unsigned num_args; // number of arguments - could be just 1 byte 
			int resident_task; // task that's currently executing in this routine or -1
			struct private_block *saved_privates;  // pointer to list of private blocks 
			unsigned int stack_space; // set by fe - stack required 
		} subp;
	} u;
};  /* size=52 bytes assumed in backend.e */ 

typedef struct symtab_entry *symtab_ptr; 
typedef struct temp_entry *temp_ptr;

