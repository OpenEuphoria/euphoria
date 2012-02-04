/*****************************************************************************/
/*      (c) Copyright - See License.txt       */
/*****************************************************************************/
/*                                                                           */
/*                     COMPILED WITH IN-LINING TURNED ON                     */
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
#include <assert.h>
#ifdef EWINDOWS
#include <windows.h>
#endif
#include "alldefs.h"
#include "be_alloc.h"

/**********************/
/* Imported variables */
/**********************/
void RTInternal();

/**********************/
/* Declared Functions */
/**********************/
/*********************/
/* Defined Functions */
/*********************/


object Dadd(d_ptr a, d_ptr b)
/* double add */
{
	return (object)NewDouble(a->dbl + b->dbl);
}


object Dminus(d_ptr a, d_ptr b)
/* double subtract */
{
	return (object)NewDouble(a->dbl - b->dbl);
}


object Dmultiply(d_ptr a, d_ptr b)
/* double multiply */
{
	return (object)NewDouble(a->dbl * b->dbl); 
}

