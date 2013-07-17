#ifndef BE_MACHINE_H_
#define BE_MACHINE_H_

#include "global.h"
#include "execute.h"
#include "symtab.h"
#include <stdint.h>

#ifndef ERUNTIME
object start_backend(object x);
extern int in_backend;
#endif

#ifdef EWINDOWS
#define DLL_PTR_TYPE HINSTANCE
#else
#define DLL_PTR_TYPE void*
#endif

extern DLL_PTR_TYPE *open_dll_list;
extern int open_dll_size;
extern int open_dll_count;

#ifdef EWINDOWS
extern HINSTANCE *open_dll_list;
extern int open_dll_size;
extern int open_dll_count;
#endif

extern int c_routine_next;         /* index of next available element */
extern int c_routine_size;         /* number of c_routine structs allocated */
extern struct arg_info *c_routine; /* array of c_routine structs */

extern char TempBuff[TEMP_SIZE]; /* buffer for error messages */

extern struct videoconfig config;
extern struct videoconfigEx configEx;

extern int allow_break;
extern int control_c_count;

extern unsigned current_fg_color;
extern unsigned current_bg_color;

extern char *crash_msg;
extern int *crash_list;       // list of routines to call when there's a crash
extern int crash_routines;    // number of routines
extern int crash_size;        // space allocated for crash_list

extern intptr_t *profile_sample;
extern volatile int sample_next;

extern int first_mouse;

extern int line_max; /* current number of text lines on screen */
extern int col_max;  /* current number of text columns on screen */

#ifdef EUNIX
int consize_ioctl;	/* 1 if line_max or col_max came from ioctl */
#endif

int use_prompt( void );
void EndGraphics( void );
void InitGraphics( void );
object SetTColor(object x);
object SetBColor(object x);

object machine(object opcode, object x);
void noecho(int wait);
void blank_lines(int line, int n);
void RestoreConfig();
char *name_ext(char *s);
void echo_wait();
object memory_copy(object d, object s, object n);
object memory_set(object d, object v, object n);
uintptr_t get_pos_int(char *where, object x);
object ATOM_TO_ATOM_INT( object X );
object get_int(object x);

void NewConfig(int raise_console);
double current_time( void );
#ifdef EWINDOWS
long __stdcall Win_Machine_Handler(LPEXCEPTION_POINTERS p);
#endif
void Machine_Handler(int sig_no);

object Wrap(object x);

IFILE long_iopen(char *name, char *mode);

object internal_general_call_back(
		  intptr_t cb_routine,
						   uintptr_t arg1, uintptr_t arg2, uintptr_t arg3,
						   uintptr_t arg4, uintptr_t arg5, uintptr_t arg6,
						   uintptr_t arg7, uintptr_t arg8, uintptr_t arg9);
#endif
