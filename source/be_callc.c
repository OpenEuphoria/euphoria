/*****************************************************************************/
/*      (c) Copyright 2007 Rapid Deployment Software - See License.txt       */
/*****************************************************************************/
/*                                                                           */
/*                           CALLS TO C ROUTINES                             */
/*                                                                           */
/*****************************************************************************/

/* DIRTY CODE! Modify this to push values onto the call stack 
 * N.B.!!! stack offset for variables "arg", and "argsize"
 * below must be correct! - make a .asm file to be sure.
 *
 * C Calling Conventions (there are many #define synonyms for these):
 * __cdecl: The caller must pop the arguments off the stack after the call.
 *          (i.e. increment the stack pointer, ESP). This allows a 
 *          variable number of arguments to be passed.
 *          This is the default.
 *
 * __stdcall: The subroutine must pop the arguments off the stack.
 *            It assumes a fixed number of arguments are passed.
 *            The WIN32 API is like this.
 *
 * Both conventions return floating-point results on the top of
 * the hardware floating-point stack, except that Watcom is non-standard 
 * for __cdecl, since it returns a pointer to the floating-point result 
 * in EAX, (although the final result could also be on the top of the
 * f.p. stack just by chance).
 *
 * Watcom restores the stack pointer ESP at the end of call_c() below, 
 * just after making the call to the C routine, so it doesn't matter 
 * if it neglects to increment the stack pointer. This means that
 * Watcom can call __cdecl (of other compilers but not it's own!)
 * and __stdcall routines, using the *same* __stdcall convention.
 */           

#include <stdio.h>
#ifdef EWINDOWS
#include <windows.h>
#endif
#include "alldefs.h"

/**********************/
/* Imported variables */
/**********************/
extern unsigned char TempBuff[];
extern int c_routine_next;         /* index of next available element */
extern struct arg_info *c_routine; /* array of c_routine structs */

/*******************/
/* Local variables */
/*******************/

#if defined(EUNIX) || defined(EMINGW)
#define push() asm("movl %0,%%ecx; pushl (%%ecx);" : /* no out */ : "r"(last_offset) : "%ecx" )
#define  pop() asm( "movl %0,%%ecx; addl (%%ecx),%%esp;" : /* no out */ : "r"(as_offset) : "%ecx" )
#endif  // EUNIX

#ifdef ELCC
#ifdef EMSVC
#define push() __asm { PUSH [last_offset] } do { } while (0)
#define  pop() __asm { ADD esp,[as_offset] } do { } while (0)
#else
#endif
#endif

#ifdef EDJGPP
#define push() asm("pushl -4(%ebp)")
#define pop() 
#endif

#ifdef EBORLAND
// dummy code - will be replaced at run-time with: ff 75 fc 90 90 90 90
// 90 is NOP instruction, 
// 99999 = hex 00 01 86 9F
#define push() arg = 99999;   

// dummy code - will be replaced at run-time with: 03 65 f8 90 90 90 90
// 88888 = hex 00 01 5B 38
#define pop() argsize = 88888;   

//...if tasm32.exe were available:
//#define push() _asm {
//                     push [ebp-4]
//                    }
//#define pop()  _asm {
//                     add esp,[ebp-8]
//                    }

object call_c();
void end_of_call_c();
object task_create();
void scheduler();
void end_of_scheduler();

#define NO_OP 0x90

void PatchCallc()
/* insert push/pop instructions into call_c() and special stack instructions
   into scheduler() and task_create().
   This is necessary because the free Borland compiler doesn't support
   machine code insertions in the C source code. */
{
	unsigned char *start;
	unsigned char *stop;
	int patched, patch_count;
	
	// callc insertions
	
	start = (unsigned char *)call_c;
	stop = (unsigned char *)end_of_call_c;

	patched = 0;
	patch_count = 0;
	while (start < stop-7) {
		if (start[0] == 0xC7 &&
			start[1] == 0x45) {
		
			if (start[2] == 0xFC &&
				start[3] == 0x9F &&
				start[4] == 0x86 &&
				start[5] == 0x01 &&
				start[6] == 0x00) {

				start[0] = 0xFF;
				start[1] = 0x75;
				start[2] = 0xFC;
				patched = 1;
			}
			else if (
				 start[2] == 0xF8 && 
				 start[3] == 0x38 &&
				 start[4] == 0x5B &&
				 start[5] == 0x01 &&
				 start[6] == 0x00) {

				start[0] = 0x03;
				start[1] = 0x65;
				start[2] = 0xF8;
				patched = 1;
			}
			if (patched) {
				start[3] = NO_OP;
				start[4] = NO_OP;
				start[5] = NO_OP;
				start[6] = NO_OP;
				patched = 0;
				patch_count++;
				start += 6;
			}
		}
		start++;
	}
	if (patch_count != 9)
		debug_msg("BORLAND PATCH ERROR! - callc");
	
	// task_create() insertion - 1 patch to make - read_esp_tc()
	
	start = (unsigned char *)task_create;
	stop = (unsigned char *)scheduler;
	patch_count = 0;
	while (start < stop-7) {
		if (start[0] == 0xC7 && // read_esp_tc()
			start[1] == 0x45 &&
			start[2] == 0xFC &&
			start[3] == 0x03 &&
			start[4] == 0xD9 &&
			start[5] == 0x00 &&
			start[6] == 0x00) {

			start[0] = 0x89;
			start[1] = 0x65;
			start[2] = 0xFC; // [EBP-4]
			start[3] = NO_OP;
			start[4] = NO_OP;
			start[5] = NO_OP;
			start[6] = NO_OP;
			start += 6;
			patch_count++;
		}
		start++;
	}
	if (patch_count != 1)
		debug_msg("BORLAND PATCH ERROR! - task_create");
	
	// scheduler() insertions - 5 patches, 
	// push_regs(), pop_regs(), set_esp()x2, read_esp()
	
	start = (unsigned char *)scheduler;
	stop = (unsigned char *)end_of_scheduler;
	patch_count = 0;
	patched = 0;
	while (start < stop-7) {
		
		if (start[0] == 0xC7 &&
			start[1] == 0x45 &&
			start[2] == 0xFC) {
			
			if (start[3] == 0x9F &&  // push_regs() 
				start[4] == 0x86 &&
				start[5] == 0x01 &&
				start[6] == 0x00) {
				
				start[0] = 0x60;  // PUSHAD
				start[1] = NO_OP;
				start[2] = NO_OP;
				patched = 1;
			}
			
			else if (
				start[3] == 0x38 && // pop_regs()
				start[4] == 0x5B &&
				start[5] == 0x01 &&
				start[6] == 0x00) {
		
				start[0] = 0x61;  // POPAD
				start[1] = NO_OP;
				start[2] = NO_OP;
				patched = 1;
			}
			else if (
				start[3] == 0xD1 && // set_esp()
				start[4] == 0x2F &&
				start[5] == 0x01 &&
				start[6] == 0x00) {

				start[0] = 0x8B; // MOV
				start[1] = 0x65; // memory
				start[2] = 0xFC; // ESP
				patched = 1;
			}
			else if (
				start[3] == 0x6A && // read_esp()
				start[4] == 0x04 &&
				start[5] == 0x01 &&
				start[6] == 0x00) {

				start[0] = 0x89; // MOV
				start[1] = 0x65; // ESP
				start[2] = 0xFC; // memory
				patched = 1;
			}
			
			if (patched) {
				start[3] = NO_OP;
				start[4] = NO_OP;
				start[5] = NO_OP;
				start[6] = NO_OP;
				patched = 0;
				patch_count++;
				start += 6;
			}
		}
		start++;
	}
	if (patch_count != 5)
		debug_msg("BORLAND PATCH ERROR! - scheduler");

}

#pragma codeseg _DATA
// put call_c() into the Borland DATA segment so I can modify it at run-time

#endif // EBORLAND

#ifdef EWATCOM
void wcpush(long X);
#define push() wcpush(last_offset);
#define pop()
#pragma aux wcpush = \
                "PUSH [EAX]" \
                modify [ESP] \
                parm [EAX];
#endif // EWATCOM

#ifdef EMSVC

/* for c_proc */
typedef void __stdcall (*proc0)();
typedef void __stdcall (*proc1)(int);
typedef void __stdcall (*proc2)(int,int);
typedef void __stdcall (*proc3)(int,int,int);
typedef void __stdcall (*proc4)(int,int,int,int);
typedef void __stdcall (*proc5)(int,int,int,int,int);
typedef void __stdcall (*proc6)(int,int,int,int,int,int);
typedef void __stdcall (*proc7)(int,int,int,int,int,int,int);
typedef void __stdcall (*proc8)(int,int,int,int,int,int,int,int);
typedef void __stdcall (*proc9)(int,int,int,int,int,int,int,int,int);
typedef void __stdcall (*procA)(int,int,int,int,int,int,int,int,int,int);
typedef void __stdcall (*procB)(int,int,int,int,int,int,int,int,int,int,int);
typedef void __stdcall (*procC)(int,int,int,int,int,int,int,int,int,int,int,int);
typedef void __stdcall (*procD)(int,int,int,int,int,int,int,int,int,int,int,int,int);
typedef void __stdcall (*procE)(int,int,int,int,int,int,int,int,int,int,int,int,int,int);
typedef void __stdcall (*procF)(int,int,int,int,int,int,int,int,int,int,int,int,int,int,int);

/* for c_func */
typedef int __stdcall (*func0)();
typedef int __stdcall (*func1)(int);
typedef int __stdcall (*func2)(int,int);
typedef int __stdcall (*func3)(int,int,int);
typedef int __stdcall (*func4)(int,int,int,int);
typedef int __stdcall (*func5)(int,int,int,int,int);
typedef int __stdcall (*func6)(int,int,int,int,int,int);
typedef int __stdcall (*func7)(int,int,int,int,int,int,int);
typedef int __stdcall (*func8)(int,int,int,int,int,int,int,int);
typedef int __stdcall (*func9)(int,int,int,int,int,int,int,int,int);
typedef int __stdcall (*funcA)(int,int,int,int,int,int,int,int,int,int);
typedef int __stdcall (*funcB)(int,int,int,int,int,int,int,int,int,int,int);
typedef int __stdcall (*funcC)(int,int,int,int,int,int,int,int,int,int,int,int);
typedef int __stdcall (*funcD)(int,int,int,int,int,int,int,int,int,int,int,int,int);
typedef int __stdcall (*funcE)(int,int,int,int,int,int,int,int,int,int,int,int,int,int);
typedef int __stdcall (*funcF)(int,int,int,int,int,int,int,int,int,int,int,int,int,int,int);

/* for c_proc */
typedef void __cdecl (*cdproc0)();
typedef void __cdecl (*cdproc1)(int);
typedef void __cdecl (*cdproc2)(int,int);
typedef void __cdecl (*cdproc3)(int,int,int);
typedef void __cdecl (*cdproc4)(int,int,int,int);
typedef void __cdecl (*cdproc5)(int,int,int,int,int);
typedef void __cdecl (*cdproc6)(int,int,int,int,int,int);
typedef void __cdecl (*cdproc7)(int,int,int,int,int,int,int);
typedef void __cdecl (*cdproc8)(int,int,int,int,int,int,int,int);
typedef void __cdecl (*cdproc9)(int,int,int,int,int,int,int,int,int);
typedef void __cdecl (*cdprocA)(int,int,int,int,int,int,int,int,int,int);
typedef void __cdecl (*cdprocB)(int,int,int,int,int,int,int,int,int,int,int);
typedef void __cdecl (*cdprocC)(int,int,int,int,int,int,int,int,int,int,int,int);
typedef void __cdecl (*cdprocD)(int,int,int,int,int,int,int,int,int,int,int,int,int);
typedef void __cdecl (*cdprocE)(int,int,int,int,int,int,int,int,int,int,int,int,int,int);
typedef void __cdecl (*cdprocF)(int,int,int,int,int,int,int,int,int,int,int,int,int,int,int);

/* for c_func */
typedef int __cdecl (*cdfunc0)();
typedef int __cdecl (*cdfunc1)(int);
typedef int __cdecl (*cdfunc2)(int,int);
typedef int __cdecl (*cdfunc3)(int,int,int);
typedef int __cdecl (*cdfunc4)(int,int,int,int);
typedef int __cdecl (*cdfunc5)(int,int,int,int,int);
typedef int __cdecl (*cdfunc6)(int,int,int,int,int,int);
typedef int __cdecl (*cdfunc7)(int,int,int,int,int,int,int);
typedef int __cdecl (*cdfunc8)(int,int,int,int,int,int,int,int);
typedef int __cdecl (*cdfunc9)(int,int,int,int,int,int,int,int,int);
typedef int __cdecl (*cdfuncA)(int,int,int,int,int,int,int,int,int,int);
typedef int __cdecl (*cdfuncB)(int,int,int,int,int,int,int,int,int,int,int);
typedef int __cdecl (*cdfuncC)(int,int,int,int,int,int,int,int,int,int,int,int);
typedef int __cdecl (*cdfuncD)(int,int,int,int,int,int,int,int,int,int,int,int,int);
typedef int __cdecl (*cdfuncE)(int,int,int,int,int,int,int,int,int,int,int,int,int,int);
typedef int __cdecl (*cdfuncF)(int,int,int,int,int,int,int,int,int,int,int,int,int,int,int);

/* for c_func */
typedef float __stdcall (*ffunc0)();
typedef float __stdcall (*ffunc1)(int);
typedef float __stdcall (*ffunc2)(int,int);
typedef float __stdcall (*ffunc3)(int,int,int);
typedef float __stdcall (*ffunc4)(int,int,int,int);
typedef float __stdcall (*ffunc5)(int,int,int,int,int);
typedef float __stdcall (*ffunc6)(int,int,int,int,int,int);
typedef float __stdcall (*ffunc7)(int,int,int,int,int,int,int);
typedef float __stdcall (*ffunc8)(int,int,int,int,int,int,int,int);
typedef float __stdcall (*ffunc9)(int,int,int,int,int,int,int,int,int);
typedef float __stdcall (*ffuncA)(int,int,int,int,int,int,int,int,int,int);
typedef float __stdcall (*ffuncB)(int,int,int,int,int,int,int,int,int,int,int);
typedef float __stdcall (*ffuncC)(int,int,int,int,int,int,int,int,int,int,int,int);
typedef float __stdcall (*ffuncD)(int,int,int,int,int,int,int,int,int,int,int,int,int);
typedef float __stdcall (*ffuncE)(int,int,int,int,int,int,int,int,int,int,int,int,int,int);
typedef float __stdcall (*ffuncF)(int,int,int,int,int,int,int,int,int,int,int,int,int,int,int);

/* for c_func */
typedef float __cdecl (*cdffunc0)();
typedef float __cdecl (*cdffunc1)(int);
typedef float __cdecl (*cdffunc2)(int,int);
typedef float __cdecl (*cdffunc3)(int,int,int);
typedef float __cdecl (*cdffunc4)(int,int,int,int);
typedef float __cdecl (*cdffunc5)(int,int,int,int,int);
typedef float __cdecl (*cdffunc6)(int,int,int,int,int,int);
typedef float __cdecl (*cdffunc7)(int,int,int,int,int,int,int);
typedef float __cdecl (*cdffunc8)(int,int,int,int,int,int,int,int);
typedef float __cdecl (*cdffunc9)(int,int,int,int,int,int,int,int,int);
typedef float __cdecl (*cdffuncA)(int,int,int,int,int,int,int,int,int,int);
typedef float __cdecl (*cdffuncB)(int,int,int,int,int,int,int,int,int,int,int);
typedef float __cdecl (*cdffuncC)(int,int,int,int,int,int,int,int,int,int,int,int);
typedef float __cdecl (*cdffuncD)(int,int,int,int,int,int,int,int,int,int,int,int,int);
typedef float __cdecl (*cdffuncE)(int,int,int,int,int,int,int,int,int,int,int,int,int,int);
typedef float __cdecl (*cdffuncF)(int,int,int,int,int,int,int,int,int,int,int,int,int,int,int);

/* for c_func */
typedef double __stdcall (*dfunc0)();
typedef double __stdcall (*dfunc1)(int);
typedef double __stdcall (*dfunc2)(int,int);
typedef double __stdcall (*dfunc3)(int,int,int);
typedef double __stdcall (*dfunc4)(int,int,int,int);
typedef double __stdcall (*dfunc5)(int,int,int,int,int);
typedef double __stdcall (*dfunc6)(int,int,int,int,int,int);
typedef double __stdcall (*dfunc7)(int,int,int,int,int,int,int);
typedef double __stdcall (*dfunc8)(int,int,int,int,int,int,int,int);
typedef double __stdcall (*dfunc9)(int,int,int,int,int,int,int,int,int);
typedef double __stdcall (*dfuncA)(int,int,int,int,int,int,int,int,int,int);
typedef double __stdcall (*dfuncB)(int,int,int,int,int,int,int,int,int,int,int);
typedef double __stdcall (*dfuncC)(int,int,int,int,int,int,int,int,int,int,int,int);
typedef double __stdcall (*dfuncD)(int,int,int,int,int,int,int,int,int,int,int,int,int);
typedef double __stdcall (*dfuncE)(int,int,int,int,int,int,int,int,int,int,int,int,int,int);
typedef double __stdcall (*dfuncF)(int,int,int,int,int,int,int,int,int,int,int,int,int,int,int);

/* for c_func */
typedef double __cdecl (*cddfunc0)();
typedef double __cdecl (*cddfunc1)(int);
typedef double __cdecl (*cddfunc2)(int,int);
typedef double __cdecl (*cddfunc3)(int,int,int);
typedef double __cdecl (*cddfunc4)(int,int,int,int);
typedef double __cdecl (*cddfunc5)(int,int,int,int,int);
typedef double __cdecl (*cddfunc6)(int,int,int,int,int,int);
typedef double __cdecl (*cddfunc7)(int,int,int,int,int,int,int);
typedef double __cdecl (*cddfunc8)(int,int,int,int,int,int,int,int);
typedef double __cdecl (*cddfunc9)(int,int,int,int,int,int,int,int,int);
typedef double __cdecl (*cddfuncA)(int,int,int,int,int,int,int,int,int,int);
typedef double __cdecl (*cddfuncB)(int,int,int,int,int,int,int,int,int,int,int);
typedef double __cdecl (*cddfuncC)(int,int,int,int,int,int,int,int,int,int,int,int);
typedef double __cdecl (*cddfuncD)(int,int,int,int,int,int,int,int,int,int,int,int,int);
typedef double __cdecl (*cddfuncE)(int,int,int,int,int,int,int,int,int,int,int,int,int,int);
typedef double __cdecl (*cddfuncF)(int,int,int,int,int,int,int,int,int,int,int,int,int,int,int);

float float_std_func(int i, int * op, int len) {
    
	switch(len) {
	    case 0: return ((ffunc0)i)();
	    case 1: return ((ffunc1)i)(op[0]);
	    case 2: return ((ffunc2)i)(op[0],op[1]);
	    case 3: return ((ffunc3)i)(op[0],op[1],op[2]);
	    case 4: return ((ffunc4)i)(op[0],op[1],op[2],op[3]);
	    case 5: return ((ffunc5)i)(op[0],op[1],op[2],op[3],op[4]);
	    case 6: return ((ffunc6)i)(op[0],op[1],op[2],op[3],op[4],op[5]); case 7: return ((func7)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6]);
	    case 8: return ((ffunc8)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7]);
	    case 9: return ((ffunc9)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8]);
	    case 10: return ((ffuncA)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9]);
	    case 11: return ((ffuncB)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10]);
	    case 12: return ((ffuncC)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11]);
	    case 13: return ((ffuncD)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12]);
	    case 14: return ((ffuncE)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12],op[13]);
	    case 15: return ((ffuncF)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12],op[13],op[14]);
	}
    return 0.0;
}

float float_cdecl_func(int i, int * op, int len) {
    
	switch(len) {
	    case 0: return ((cdffunc0)i)();
	    case 1: return ((cdffunc1)i)(op[0]);
	    case 2: return ((cdffunc2)i)(op[0],op[1]);
	    case 3: return ((cdffunc3)i)(op[0],op[1],op[2]);
	    case 4: return ((cdffunc4)i)(op[0],op[1],op[2],op[3]);
	    case 5: return ((cdffunc5)i)(op[0],op[1],op[2],op[3],op[4]);
	    case 6: return ((cdffunc6)i)(op[0],op[1],op[2],op[3],op[4],op[5]);
	    case 7: return ((cdffunc7)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6]);
	    case 8: return ((cdffunc8)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7]);
	    case 9: return ((cdffunc9)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8]);
	    case 10: return ((cdffuncA)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9]);
	    case 11: return ((cdffuncB)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10]);
	    case 12: return ((cdffuncC)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11]);
	    case 13: return ((cdffuncD)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12]);
	    case 14: return ((cdffuncE)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12],op[13]);
	    case 15: return ((cdffuncF)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12],op[13],op[14]);
	}
    return 0.0;
}

double double_std_func(int i, int * op, int len) {
    
	switch(len) {
	    case 0: return ((dfunc0)i)();
	    case 1: return ((dfunc1)i)(op[0]);
	    case 2: return ((dfunc2)i)(op[0],op[1]);
	    case 3: return ((dfunc3)i)(op[0],op[1],op[2]);
	    case 4: return ((dfunc4)i)(op[0],op[1],op[2],op[3]);
	    case 5: return ((dfunc5)i)(op[0],op[1],op[2],op[3],op[4]);
	    case 6: return ((dfunc6)i)(op[0],op[1],op[2],op[3],op[4],op[5]); case 7: return ((func7)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6]);
	    case 8: return ((dfunc8)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7]);
	    case 9: return ((dfunc9)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8]);
	    case 10: return ((dfuncA)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9]);
	    case 11: return ((dfuncB)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10]);
	    case 12: return ((dfuncC)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11]);
	    case 13: return ((dfuncD)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12]);
	    case 14: return ((dfuncE)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12],op[13]);
	    case 15: return ((dfuncF)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12],op[13],op[14]);
	}
    return 0.0;
}

double double_cdecl_func(int i, int * op, int len) {
    
	switch(len) {
	    case 0: return ((cddfunc0)i)();
	    case 1: return ((cddfunc1)i)(op[0]);
	    case 2: return ((cddfunc2)i)(op[0],op[1]);
	    case 3: return ((cddfunc3)i)(op[0],op[1],op[2]);
	    case 4: return ((cddfunc4)i)(op[0],op[1],op[2],op[3]);
	    case 5: return ((cddfunc5)i)(op[0],op[1],op[2],op[3],op[4]);
	    case 6: return ((cddfunc6)i)(op[0],op[1],op[2],op[3],op[4],op[5]);
	    case 7: return ((cddfunc7)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6]);
	    case 8: return ((cddfunc8)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7]);
	    case 9: return ((cddfunc9)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8]);
	    case 10: return ((cddfuncA)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9]);
	    case 11: return ((cddfuncB)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10]);
	    case 12: return ((cddfuncC)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11]);
	    case 13: return ((cddfuncD)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12]);
	    case 14: return ((cddfuncE)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12],op[13]);
	    case 15: return ((cddfuncF)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12],op[13],op[14]);
	}
    return 0.0;
}

void call_std_proc(int i, int * op, int len) {
    
	switch(len) {
	    case 0: ((proc0)i)(); return;
	    case 1: ((proc1)i)(op[0]); return;
	    case 2: ((proc2)i)(op[0],op[1]); return;
	    case 3: ((proc3)i)(op[0],op[1],op[2]); return;
	    case 4: ((proc4)i)(op[0],op[1],op[2],op[3]); return;
	    case 5: ((proc5)i)(op[0],op[1],op[2],op[3],op[4]); return;
	    case 6: ((proc6)i)(op[0],op[1],op[2],op[3],op[4],op[5]); return;
	    case 7: ((proc7)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6]); return;
	    case 8: ((proc8)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7]); return;
	    case 9: ((proc9)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8]); return;
	    case 10: ((procA)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9]); return;
	    case 11: ((procB)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10]); return;
	    case 12: ((procC)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11]); return;
	    case 13: ((procD)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12]); return;
	    case 14: ((procE)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12],op[13]); return;
	    case 15: ((procF)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12],op[13],op[14]); return;
	}
}

int call_std_func(int i, int * op, int len) {
    
	switch(len) {
	    case 0: return ((func0)i)();
	    case 1: return ((func1)i)(op[0]);
	    case 2: return ((func2)i)(op[0],op[1]);
	    case 3: return ((func3)i)(op[0],op[1],op[2]);
	    case 4: return ((func4)i)(op[0],op[1],op[2],op[3]);
	    case 5: return ((func5)i)(op[0],op[1],op[2],op[3],op[4]);
	    case 6: return ((func6)i)(op[0],op[1],op[2],op[3],op[4],op[5]);
	    case 7: return ((func7)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6]);
	    case 8: return ((func8)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7]);
	    case 9: return ((func9)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8]);
	    case 10: return ((funcA)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9]);
	    case 11: return ((funcB)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10]);
	    case 12: return ((funcC)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11]);
	    case 13: return ((funcD)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12]);
	    case 14: return ((funcE)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12],op[13]);
	    case 15: return ((funcF)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12],op[13],op[14]);
	}
    return 0;
}

void call_cdecl_proc(int i, int * op, int len) {
    
	switch(len) {
	    case 0: ((cdproc0)i)(); return;
	    case 1: ((cdproc1)i)(op[0]); return;
	    case 2: ((cdproc2)i)(op[0],op[1]); return;
	    case 3: ((cdproc3)i)(op[0],op[1],op[2]); return;
	    case 4: ((cdproc4)i)(op[0],op[1],op[2],op[3]); return;
	    case 5: ((cdproc5)i)(op[0],op[1],op[2],op[3],op[4]); return;
	    case 6: ((cdproc6)i)(op[0],op[1],op[2],op[3],op[4],op[5]); return;
	    case 7: ((cdproc7)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6]); return;
	    case 8: ((cdproc8)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7]); return;
	    case 9: ((cdproc9)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8]); return;
	    case 10: ((cdprocA)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9]); return;
	    case 11: ((cdprocB)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10]); return;
	    case 12: ((cdprocC)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11]); return;
	    case 13: ((cdprocD)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12]); return;
	    case 14: ((cdprocE)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12],op[13]); return;
	    case 15: ((cdprocF)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12],op[13],op[14]); return;
	}
}

int call_cdecl_func(int i, int * op, int len) {
    
	switch(len) {
	    case 0: return ((cdfunc0)i)();
	    case 1: return ((cdfunc1)i)(op[0]);
	    case 2: return ((cdfunc2)i)(op[0],op[1]);
	    case 3: return ((cdfunc3)i)(op[0],op[1],op[2]);
	    case 4: return ((cdfunc4)i)(op[0],op[1],op[2],op[3]);
	    case 5: return ((cdfunc5)i)(op[0],op[1],op[2],op[3],op[4]);
	    case 6: return ((cdfunc6)i)(op[0],op[1],op[2],op[3],op[4],op[5]);
	    case 7: return ((cdfunc7)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6]);
	    case 8: return ((cdfunc8)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7]);
	    case 9: return ((cdfunc9)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8]);
	    case 10: return ((cdfuncA)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9]);
	    case 11: return ((cdfuncB)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10]);
	    case 12: return ((cdfuncC)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11]);
	    case 13: return ((cdfuncD)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12]);
	    case 14: return ((cdfuncE)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12],op[13]);
	    case 15: return ((cdfuncF)i)(op[0],op[1],op[2],op[3],op[4],op[5],op[6],op[7],op[8],op[9],op[10],op[11],op[12],op[13],op[14]);
	}
    return 0;
}

object call_c(int func, object proc_ad, object arg_list)
/* Call a WIN32 or Linux C function in a DLL or shared library. 
   Alternatively, call a machine-code routine at a given address. */
{
	s1_ptr arg_list_ptr, arg_size_ptr;
	object_ptr next_arg_ptr, next_size_ptr;
	object next_arg, next_size;
	int iresult, i;
	double dbl_arg, dresult;
	float flt_arg, fresult;
	unsigned long size;
	int proc_index;
	int cdecl_call;
	int int_proc_address;
	unsigned return_type;
	char NameBuff[100];
	unsigned long arg;

	int arg_op[16];
	int arg_len;
	int arg_i = 0;
	int is_double, is_float;

	// Setup and Check for Errors
	
	proc_index = get_pos_int("c_proc/c_func", proc_ad); 
	if ((unsigned)proc_index >= c_routine_next) {
		sprintf(TempBuff, "c_proc/c_func: bad routine number (%d)", proc_index);
		RTFatal(TempBuff);
	}
	
	int_proc_address = (int)(c_routine[proc_index].address);
#if defined(EWINDOWS) && !defined(EWATCOM)
	cdecl_call = c_routine[proc_index].convention;
#endif
	if (IS_ATOM(arg_list)) {
		RTFatal("c_proc/c_func: argument list must be a sequence");
	}
	
	arg_list_ptr = SEQ_PTR(arg_list);
	next_arg_ptr = arg_list_ptr->base + arg_list_ptr->length;
	
	// only look at length of arg size sequence for now
	arg_size_ptr = c_routine[proc_index].arg_size;
	next_size_ptr = arg_size_ptr->base + arg_size_ptr->length;
	
	return_type = c_routine[proc_index].return_size; // will be INT

	arg_len = arg_list_ptr->length;
	
	if (func && return_type == 0 || !func && return_type != 0) {
		if (c_routine[proc_index].name->length < 100)
			MakeCString(NameBuff, MAKE_SEQ(c_routine[proc_index].name));
		else
			NameBuff[0] = '\0';
		sprintf(TempBuff, func ? "%s does not return a value" :
								 "%s returns a value",
								 NameBuff);
		RTFatal(TempBuff);
	}
		
	if (arg_list_ptr->length != arg_size_ptr->length) {
		if (c_routine[proc_index].name->length < 100)
			MakeCString(NameBuff, MAKE_SEQ(c_routine[proc_index].name));
		else
			NameBuff[0] = '\0';
		sprintf(TempBuff, "C routine %s() needs %d argument%s, not %d",
						  NameBuff,
						  arg_size_ptr->length,
						  (arg_size_ptr->length == 1) ? "" : "s",
						  arg_list_ptr->length);
		RTFatal(TempBuff);
	}
	
	// Push the Arguments
	
	for (i = 1; i <= arg_list_ptr->length; i++) {
	
		next_arg = *next_arg_ptr--;
		next_size = *next_size_ptr--;
		
		if (IS_ATOM_INT(next_size))
			size = INT_VAL(next_size);
		else if (IS_ATOM(next_size))
			size = (unsigned long)DBL_PTR(next_size)->dbl;
		else 
			RTFatal("This C routine was defined using an invalid argument type");

		if (size == C_DOUBLE || size == C_FLOAT) {
			/* push 8-byte double or 4-byte float */
			if (IS_ATOM_INT(next_arg))
				dbl_arg = (double)next_arg;
			else if (IS_ATOM(next_arg))
				dbl_arg = DBL_PTR(next_arg)->dbl;
			else { 
				RTFatal("arguments to C routines must be atoms");
			}

			if (size == C_DOUBLE) {
				arg = *(1+(unsigned long *)&dbl_arg);

				arg_op[arg_i++] = arg;
				arg = *(unsigned long *)&dbl_arg;
				arg_op[arg_i++] = arg;
			}
			else {
				/* C_FLOAT */
				flt_arg = (float)dbl_arg;
				arg = *(unsigned long *)&flt_arg;
				arg_op[arg_i++] = arg;
			}
		}
		else {
			/* push 4-byte integer */
			if (size >= E_INTEGER) {
				if (IS_ATOM_INT(next_arg)) {
					if (size == E_SEQUENCE)
						RTFatal("passing an integer where a sequence is required");
				}
				else {
					if (IS_SEQUENCE(next_arg)) {
						if (size != E_SEQUENCE && size != E_OBJECT)
							RTFatal("passing a sequence where an atom is required");
					}
					else {
						if (size == E_SEQUENCE)
							RTFatal("passing an atom where a sequence is required");
					}
					RefDS(next_arg);
				}
				arg = next_arg;
				arg_op[arg_i++] = arg;
			} 
			else if (IS_ATOM_INT(next_arg)) {
				arg = next_arg;
				arg_op[arg_i++] = arg;
			}
			else if (IS_ATOM(next_arg)) {
				// atoms are rounded to integers
				
				arg = (unsigned long)DBL_PTR(next_arg)->dbl; //correct
				// if it's a -ve f.p. number, Watcom converts it to int and
				// then to unsigned int. This is exactly what we want.
				// Works with the others too. 
				arg_op[arg_i++] = arg;
			}
			else {
				RTFatal("arguments to C routines must be atoms");
			}
		}
	}    

	// Make the Call - The C compiler thinks it's a 0-argument call
	
	// might be VOID C routine, but shouldn't crash
	
	is_double = (return_type == C_DOUBLE);
	is_float = (return_type == C_FLOAT);

	if (func) {
		if (cdecl_call && is_double) {
			dresult = double_cdecl_func(int_proc_address, arg_op, arg_len);
		} else if (cdecl_call && is_float) {
			fresult = float_cdecl_func(int_proc_address, arg_op, arg_len);
		} else if (is_double) {
			dresult = double_std_func(int_proc_address, arg_op, arg_len);
		} else if (is_float) {
			fresult = float_std_func(int_proc_address, arg_op, arg_len);
		} else if (cdecl_call) {
			iresult = call_cdecl_func(int_proc_address, arg_op, arg_len);
		} else {
			iresult = call_std_func(int_proc_address, arg_op, arg_len);
		}
	} else {
		if (cdecl_call) {
			call_cdecl_proc(int_proc_address, arg_op, arg_len);
			iresult = 0;
		} else {
			call_std_proc(int_proc_address, arg_op, arg_len);
			iresult = 0;
		}
	}

	if (return_type == C_DOUBLE) {
		return NewDouble(dresult);
	}
	
	else if (return_type == C_FLOAT) {
		return NewDouble((double)fresult);
	}
	
	else {
		// expect integer to be returned
		if ((return_type & 0x000000FF) == 04) {
			/* 4-byte integer - usual case */
			// check if unsigned result is required 
			if ((return_type & C_TYPE) == 0x02000000) {
				// unsigned integer result
				if ((unsigned)iresult <= (unsigned)MAXINT) {
					return iresult;
				}
				else
					return NewDouble((double)(unsigned)iresult);
			}
			else {
				// signed integer result
				if (return_type >= E_INTEGER ||
					(iresult >= MININT && iresult <= MAXINT)) {
					return iresult;
				}
				else
					return NewDouble((double)iresult);
			}
		}
		else if (return_type == 0) {
			return 0; /* void - procedure */
		}
		/* less common cases */
		else if (return_type == C_UCHAR) {
			return (unsigned char)iresult;
		}
		else if (return_type == C_CHAR) {
			return (signed char)iresult;
		}
		else if (return_type == C_USHORT) {
			return (unsigned short)iresult;
		}
		else if (return_type == C_SHORT) {
			return (short)iresult;
		}
		else
			return 0; // unknown function return type
	}
}

#else // ifdef EMSVC

object call_c(int func, object proc_ad, object arg_list)
/* Call a WIN32 or Linux C function in a DLL or shared library. 
   Alternatively, call a machine-code routine at a given address. */
{
	volatile unsigned long arg;  // !!!! magic var to push values on the stack
	volatile int argsize;        // !!!! number of bytes to pop 
	
	s1_ptr arg_list_ptr, arg_size_ptr;
	object_ptr next_arg_ptr, next_size_ptr;
	object next_arg, next_size;
	int iresult, i;
	double dbl_arg, dresult;
	float flt_arg, fresult;
	unsigned long size;
	int proc_index;
	int cdecl_call;
	int (*int_proc_address)();
	unsigned return_type;
	char NameBuff[100];
	unsigned long as_offset;
	unsigned long last_offset;

	// this code relies on arg always being the first variable and last_offset 
	// always being the last variable
	last_offset = (unsigned long)&arg;
	as_offset = (unsigned long)&argsize;
	// as_offset = last_offset - 4;

	// Setup and Check for Errors
	
	proc_index = get_pos_int("c_proc/c_func", proc_ad); 
	if ((unsigned)proc_index >= c_routine_next) {
		sprintf(TempBuff, "c_proc/c_func: bad routine number (%d)", proc_index);
		RTFatal(TempBuff);
	}
	
	int_proc_address = c_routine[proc_index].address;
#if defined(EWINDOWS) && !defined(EWATCOM)
	cdecl_call = c_routine[proc_index].convention;
#endif
	if (IS_ATOM(arg_list)) {
		RTFatal("c_proc/c_func: argument list must be a sequence");
	}
	
	arg_list_ptr = SEQ_PTR(arg_list);
	next_arg_ptr = arg_list_ptr->base + arg_list_ptr->length;
	
	// only look at length of arg size sequence for now
	arg_size_ptr = c_routine[proc_index].arg_size;
	next_size_ptr = arg_size_ptr->base + arg_size_ptr->length;
	
	return_type = c_routine[proc_index].return_size; // will be INT
	
	if (func && return_type == 0 || !func && return_type != 0) {
		if (c_routine[proc_index].name->length < 100)
			MakeCString(NameBuff, MAKE_SEQ(c_routine[proc_index].name));
		else
			NameBuff[0] = '\0';
		sprintf(TempBuff, func ? "%s does not return a value" :
								 "%s returns a value",
								 NameBuff);
		RTFatal(TempBuff);
	}
		
	if (arg_list_ptr->length != arg_size_ptr->length) {
		if (c_routine[proc_index].name->length < 100)
			MakeCString(NameBuff, MAKE_SEQ(c_routine[proc_index].name));
		else
			NameBuff[0] = '\0';
		sprintf(TempBuff, "C routine %s() needs %d argument%s, not %d",
						  NameBuff,
						  arg_size_ptr->length,
						  (arg_size_ptr->length == 1) ? "" : "s",
						  arg_list_ptr->length);
		RTFatal(TempBuff);
	}
	
	argsize = arg_list_ptr->length << 2;
	
	// Push the Arguments
	
	for (i = 1; i <= arg_list_ptr->length; i++) {
	
		next_arg = *next_arg_ptr--;
		next_size = *next_size_ptr--;
		
		if (IS_ATOM_INT(next_size))
			size = INT_VAL(next_size);
		else if (IS_ATOM(next_size))
			size = (unsigned long)DBL_PTR(next_size)->dbl;
		else 
			RTFatal("This C routine was defined using an invalid argument type");

		if (size == C_DOUBLE || size == C_FLOAT) {
			/* push 8-byte double or 4-byte float */
			if (IS_ATOM_INT(next_arg))
				dbl_arg = (double)next_arg;
			else if (IS_ATOM(next_arg))
				dbl_arg = DBL_PTR(next_arg)->dbl;
			else { 
				arg = arg+argsize+9999; // 9999 = 270f hex - just a marker for asm code
				RTFatal("arguments to C routines must be atoms");
			}

			if (size == C_DOUBLE) {
				arg = *(1+(unsigned long *)&dbl_arg);

				push();  // push high-order half first
				argsize += 4;
				arg = *(unsigned long *)&dbl_arg;
				push(); // don't combine this with the push() below - Lcc bug
			}
			else {
				/* C_FLOAT */
				flt_arg = (float)dbl_arg;
				arg = *(unsigned long *)&flt_arg;
				push();
			}
		}
		else {
			/* push 4-byte integer */
			if (size >= E_INTEGER) {
				if (IS_ATOM_INT(next_arg)) {
					if (size == E_SEQUENCE)
						RTFatal("passing an integer where a sequence is required");
				}
				else {
					if (IS_SEQUENCE(next_arg)) {
						if (size != E_SEQUENCE && size != E_OBJECT)
							RTFatal("passing a sequence where an atom is required");
					}
					else {
						if (size == E_SEQUENCE)
							RTFatal("passing an atom where a sequence is required");
					}
					RefDS(next_arg);
				}
				arg = next_arg;
				push();
			} 
			else if (IS_ATOM_INT(next_arg)) {
				arg = next_arg;
				push();
			}
			else if (IS_ATOM(next_arg)) {
				// atoms are rounded to integers
				
				arg = (unsigned long)DBL_PTR(next_arg)->dbl; //correct
				// if it's a -ve f.p. number, Watcom converts it to int and
				// then to unsigned int. This is exactly what we want.
				// Works with the others too. 
				push();
			}
			else {
				arg = arg+argsize+9999; // just a marker for asm code
				RTFatal("arguments to C routines must be atoms");
			}
		}
	}    

	// Make the Call - The C compiler thinks it's a 0-argument call
	
	// might be VOID C routine, but shouldn't crash

	if (return_type == C_DOUBLE) {
		// expect double to be returned from C routine
#if defined(EWINDOWS) && !defined(EWATCOM)
		if (cdecl_call) {
			dresult = (*((double (  __cdecl *)())int_proc_address))();
			pop();
		}
		else
#endif          
			dresult = (*((double (__stdcall *)())int_proc_address))();

#ifdef EUNIX       
		pop();
#endif      
		return NewDouble(dresult);
	}
	
	else if (return_type == C_FLOAT) {
		// expect float to be returned from C routine
#if defined(EWINDOWS) && !defined(EWATCOM)
		if (cdecl_call) {
			fresult = (*((float (  __cdecl *)())int_proc_address))();
			pop();
		}
		else
#endif          
			fresult = (*((float (__stdcall *)())int_proc_address))();

#ifdef EUNIX       
		pop();
#endif      
		return NewDouble((double)fresult);
	}
	
	else {
		// expect integer to be returned
#if defined(EWINDOWS) && !defined(EWATCOM)
		if (cdecl_call) {
			iresult = (*((int (  __cdecl *)())int_proc_address))();
			pop();
		}
		else
#endif          
			iresult = (*((int (__stdcall *)())int_proc_address))();
#ifdef EUNIX       
		pop();
#endif      
		if ((return_type & 0x000000FF) == 04) {
			/* 4-byte integer - usual case */
			// check if unsigned result is required 
			if ((return_type & C_TYPE) == 0x02000000) {
				// unsigned integer result
				if ((unsigned)iresult <= (unsigned)MAXINT) {
					return iresult;
				}
				else
					return NewDouble((double)(unsigned)iresult);
			}
			else {
				// signed integer result
				if (return_type >= E_INTEGER ||
					(iresult >= MININT && iresult <= MAXINT)) {
					return iresult;
				}
				else
					return NewDouble((double)iresult);
			}
		}
		else if (return_type == 0) {
			return 0; /* void - procedure */
		}
		/* less common cases */
		else if (return_type == C_UCHAR) {
			return (unsigned char)iresult;
		}
		else if (return_type == C_CHAR) {
			return (signed char)iresult;
		}
		else if (return_type == C_USHORT) {
			return (unsigned short)iresult;
		}
		else if (return_type == C_SHORT) {
			return (short)iresult;
		}
		else
			return 0; // unknown function return type
	}
}

#endif //ifdef EMSVC

#ifdef EBORLAND // put this at the end of the source file
#pragma codeseg _DATA
void end_of_call_c()
/* end marker */
{
}
#pragma codeseg
#endif


