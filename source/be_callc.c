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
#include "be_runtime.h"

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
#define push() _asm("pushl -8(%ebp)")
#define  pop() _asm("addl -36(%ebp), %esp")
#endif

#ifdef EDJGPP
#define push() asm("pushl -4(%ebp)")
#define pop() 
#endif

#ifdef EWATCOM
void wcpush(long X);
#define push() wcpush(last_offset);
#define pop()
#pragma aux wcpush = \
                "PUSH [EAX]" \
                modify [ESP] \
                parm [EAX];
#endif // EWATCOM


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
		RTFatal("c_proc/c_func: bad routine number (%d)", proc_index);
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
		if (c_routine[proc_index].name->length < TEMP_SIZE)
			MakeCString(TempBuff, MAKE_SEQ(c_routine[proc_index].name, TEMP_SIZE));
		else
			TempBuff[0] = '\0';
		RTFatal(func ? "%s does not return a value" :
				"%s returns a value",
				TempBuff);
	}
		
	if (arg_list_ptr->length != arg_size_ptr->length) {
		if (c_routine[proc_index].name->length < 100)
			MakeCString(TempBuff, MAKE_SEQ(c_routine[proc_index].name, TEMP_SIZE));
		else
			TempBuff[0] = '\0';
		RTFatal("C routine %s() needs %d argument%s, not %d",
				TempBuff,
				arg_size_ptr->length,
				(arg_size_ptr->length == 1) ? "" : "s",
				arg_list_ptr->length);
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
