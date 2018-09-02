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
#include <stdio.h>
#include <assert.h>
#ifdef _WIN32
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

