/*****************************************************************************/
/*      (c) Copyright 2007 Rapid Deployment Software - See License.txt       */
/*****************************************************************************/
/*                                                                           */
/*                       BACKEND MAIN PROGRAM                                */
/*                                                                           */
/*****************************************************************************/

/******************/
/* Included files */
/******************/
#include <stdio.h>
#include <time.h>
#ifdef EWINDOWS
#include <windows.h>
#include <limits.h>
#endif
#ifdef EUNIX
#include <unistd.h>
#ifdef EBSD
#include <limits.h>
#else
#include <linux/limits.h>
#endif
#include <sys/types.h>
#include <sys/stat.h>
#else
#ifdef EBORLAND
#include <float.h>
#else
#ifdef EMINGW
#include <sys/types.h>
#include <sys/stat.h>
#else
#include <sys\types.h>
#include <sys\stat.h>
#endif
#if !defined(ELCC) && !defined(EDJGPP) && !defined(EMINGW)
#include <i86.h>
#include <bios.h>
#include <graph.h>
#endif
#endif
#endif
#include <fcntl.h>
#include <string.h>
#include "alldefs.h"

/**********************/
/* Imported variables */
/**********************/
extern int clocks_per_sec;
extern int clk_tck;
#ifdef EWINDOWS
//extern HINSTANCE winInstance;
extern unsigned default_heap;
#endif
extern int have_console;
extern struct videoconfig config;
extern int gameover;
#ifdef EXTRA_STATS
extern int mouse_ints;
extern unsigned recycles;
extern long a_miss;
extern long a_hit; 
extern long a_too_big;
extern long funny_expand;
extern long funny_align;
extern int bad_samples;
#endif
extern char show_cursor[];
extern char hide_cursor[];
extern char wrap[];
extern long bytes_allocated;
extern long max_bytes_allocated;
extern char **file_name;
extern unsigned char TempBuff[];
extern char *TempErrName;

/**********************/
/* Exported variables */
/**********************/
int bound = FALSE;     /* TRUE if Euphoria program is bound to interpreter */
void *Backlink = NULL; /* DLL back pointer */
char *eudir;           /* path to Euphoria directory */
char main_path[PATH_MAX+1]; /* path of main file being executed */

/*******************/
/* Local variables */
/*******************/
static int src_file;

/**********************/
/* Declared functions */
/**********************/
extern char *getenv();
#ifndef ESIMPLE_MALLOC
extern char *EMalloc();
#else
#include "alloc.h"
#endif
#ifndef EWINDOWS // !defined(EBORLAND) && !defined(ELCC)
extern void *malloc();
#endif

/*********************/
/* Defined functions */
/*********************/

static int e_path_open(char *name, int mode)
/* follow the search path, if necessary to open the main file */
{
	int src_file, fn;
#ifdef EWINDOWS
	int accents;
#endif
	char *path;
	char *full_name;
	char *p;
	   
	file_name[1] = name;
	src_file = long_open(name, mode);        
	if (src_file > -1) {
		return src_file;        
	}
	/* first make sure that name is a simple name without '\' in it */
	for (p = name; *p != 0; p++) {
		if (*p == '\\' || *p == '/')   // should add ':' too - but doesn't matter
			return -1;
	}     
	path = getenv("PATH");
	if (path == NULL)
		return -1;
	full_name = EMalloc(PATH_MAX+1);
	fn = 0;
#ifdef EWINDOWS
	accents = 0;
#endif
	for (p = path; ; p++) {
		if (*p == ' ' || *p == '\t')
			continue;
		else if (*p == PATH_SEPARATOR || *p == '\0') {
			/* end of a directory */
			if (fn > 0) {
				full_name[fn++] = SLASH;
				strlcpy(full_name + fn, name, PATH_MAX);
				src_file = long_open(full_name, mode);
				if (src_file > -1) {
					file_name[1] = full_name;           
					return src_file;
				}
				else {
#ifdef EWINDOWS                         
					if (accents) {
						accents = OemToCharBuffA(full_name,full_name,fn);
				src_file = long_open(full_name, mode);
				if (src_file > -1) {
					file_name[1] = full_name;           
					return src_file;
				}
					}
#endif
					fn = 0;
				}
			}
			if (*p == '\0')
				break;
#ifdef EWINDOWS
			accents = 0;
#endif
		}
		else {
			full_name[fn++] = *p;
#ifdef EWINDOWS
			if (*p >= 128) accents = 1;
#endif
		}
	}
	return -1;
}

void be_init()
/* Main routine for Interpreter back end */
{
	char *p;
	int i;
	long c;
	char *temp;

	clocks_per_sec = CLOCKS_PER_SEC;
#ifdef ELCC 
	clk_tck = CLOCKS_PER_SEC;
#else   
#ifdef CLK_TCK
	clk_tck = CLK_TCK;
#else
	clk_tck = sysconf(_SC_CLK_TCK);
#endif
#endif

#ifdef EWINDOWS
	
#ifdef EBORLAND
	_control87(MCW_EM,MCW_EM);
#endif
#endif
#define TempErrName_len (30)
	TempErrName = (char *)malloc(TempErrName_len); // uses malloc, not EMalloc
	strlcpy(TempErrName, "ex.err", TempErrName_len); // can change
	
	eudir = getenv("EUDIR");
	if (eudir == NULL) {
#ifdef EUNIX
		// should check search PATH for euphoria/bin ?
		eudir = getenv("HOME");
		if (eudir == NULL) {
			eudir = "euphoria";  
		}
		else {
			int p_size = strlen(eudir) + 12;
			p = (char *)malloc(p_size + 1);
			snprintf(p, p_size+1, "%s/euphoria", eudir);
			p[p_size] = 0; // ensure NULL
			eudir = p;
		}
#else
		eudir = "\\EUPHORIA";
#endif
	}
	
#if defined(EUNIX) || defined(EDJGPP) || defined(EMINGW)
	strlcpy(main_path, file_name[1], PATH_MAX); // FOR NOW!
#else
	(void)_fullpath(main_path, file_name[1], PATH_MAX+1); 
#endif
	for (p = main_path+strlen(main_path)-1; 
		 *p != '\\' && *p != '/' && p >= main_path; 
		 p--)
		;
	*(p+1) = '\0'; /* keep the path, truncate off the final name */    

#ifdef EBORLAND
	PatchCallc();  // ? translator init does this
#endif
	
	InitExecute();
	InitDebug();
	InitTraceWindow();
}


#ifdef EXTRA_STATS
void Stats()
/* print execution statistics */
{
	int i;
	IFILE opfile;

	StorageStats(); 
	printf("bytes of extra storage allocated\n");
	printf("   maximum: %d\n", max_bytes_allocated);
	printf("   current: %d\n", bytes_allocated);
	printf("storage cache  hits: %d\n", a_hit);
	printf("             misses: %d\n", a_miss);
	printf("            too big: %d\n", a_too_big); 
	printf("           recycles: %d\n", recycles);
	printf("unused mouse interrupts: %d\n", mouse_ints);
	printf("funny _expands: %d\n", funny_expand);
	printf("funny aligns: %d\n", funny_align);
	printf("bad time-profile samples: %d\n", bad_samples);
}
#endif

