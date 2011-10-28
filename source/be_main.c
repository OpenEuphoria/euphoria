/*****************************************************************************/
/*      (c) Copyright - See License.txt       */
/*****************************************************************************/
/*                                                                           */
/*                       BACKEND MAIN PROGRAM                                */
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
#include <time.h>
#ifdef EWINDOWS
#  include <windows.h>
#  include <limits.h>
#endif
#ifdef EUNIX
#  include <unistd.h>
#  ifdef EBSD
#    include <limits.h>
#  else
#    include <linux/limits.h>
#  endif
#  include <sys/types.h>
#  include <sys/stat.h>
#else
#  ifdef EMINGW
#    include <sys/types.h>
#    include <sys/stat.h>
#  else
#    include <sys\types.h>
#    include <sys\stat.h>
#  endif
#  if !defined(EMINGW)
#    include <i86.h>
#    include <bios.h>
#    include <graph.h>
#  endif
#endif
#include <fcntl.h>
#include <string.h>

#include "alldefs.h"
#include "be_runtime.h"
#include "be_execute.h"
#include "be_alloc.h"
#include "be_rterror.h"
#include "be_w.h"

/**********************/
/* Exported variables */
/**********************/
int bound = FALSE;     /* TRUE if Euphoria program is bound to interpreter */
void *Backlink = NULL; /* DLL back pointer */
char *eudir;           /* path to Euphoria directory */
char main_path[PATH_MAX+1]; /* path of main file being executed */

/*********************/
/* Defined functions */
/*********************/

void be_init()
/* Main routine for Interpreter back end */
{
	char *p;

	EuConsole = (getenv("EUCONS") != NULL && atoi(getenv("EUCONS")) == 1);
	clocks_per_sec = CLOCKS_PER_SEC;
#ifdef CLK_TCK
	clk_tck = CLK_TCK;
#else
	clk_tck = sysconf(_SC_CLK_TCK);
#endif

#define TempErrName_len (30)
	TempErrName = (char *)EMalloc(TempErrName_len);
	copy_string(TempErrName, "ex.err", TempErrName_len); // can change
	
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
			p = (char *)EMalloc(p_size + 1);
			snprintf(p, p_size+1, "%s/euphoria", eudir);
			p[p_size] = 0; // ensure NULL
			eudir = p;
		}
#else // EUNIX
		eudir = "\\EUPHORIA";
#endif // EUNIX
	}
	
#if defined(EUNIX) || defined(EMINGW)
	copy_string(main_path, file_name[1], PATH_MAX); // FOR NOW!
#else
	(void)_fullpath(main_path, file_name[1], PATH_MAX+1); 
#endif
	for (p = main_path+strlen(main_path)-1; 
		 *p != '\\' && *p != '/' && p >= main_path; 
		 p--)
		;
	*(p+1) = '\0'; /* keep the path, truncate off the final name */    

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

