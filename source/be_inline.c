/*****************************************************************************/
/*      (c) Copyright 2007 Rapid Deployment Software - See License.txt       */
/*****************************************************************************/
/*                                                                           */
/*                     COMPILED WITH IN-LINING TURNED ON                     */
/*                                                                           */
/*****************************************************************************/

/******************/
/* Included files */
/******************/
#include <stdio.h>
#ifdef EWINDOWS
#include <windows.h>
#endif
#include "alldefs.h"
#include "alloc.h"

/**********************/
/* Imported variables */
/**********************/
void RTInternal();
extern unsigned cache_size;
extern int align4;
#ifdef HEAP_CHECK
#ifdef EWINDOWS
extern unsigned default_heap;
#endif
#endif

/**********************/
/* Declared Functions */
/**********************/
#ifndef ESIMPLE_MALLOC
char *EMalloc(long);
#else
#ifdef EWINDOWS
extern unsigned default_heap;
#endif
#endif
/*********************/
/* Defined Functions */
/*********************/


object NewDouble(double d)
/* allocate space for a new double value */
{
	register d_ptr new;

#ifdef EUNIX

   new = EMalloc((long)D_SIZE);
#else
#ifdef HEAP_CHECK  
	char *q;
	int align;
#endif 
	if (d_list != NULL) {
		new = (d_ptr)d_list;
		d_list = (d_ptr)((free_block_ptr)new)->next;
		cache_size -= 1;
#ifdef HEAP_CHECK   
		q = (char *)new;
		if (align4 && *(int *)(q-4) == MAGIC_FILLER) 
			q = q - 4;
		Allocated(block_size(q));
#endif  
	}
	else {
		new = (d_ptr)EMalloc((long)D_SIZE);
#ifdef HEAP_CHECK
		if (((long)new & 3) != 0)
			RTInternal("NewDouble: bad alignment");
		Trash((char *)new, D_SIZE);
#endif
	}
#ifdef HEAP_CHECK
	if ((long)new % 8 != 0)
		RTInternal("NewDouble returns misaligned pointer");
#endif

#endif
	new->ref = 1;
	new->dbl = d;
	new->cleanup = 0;
	return MAKE_DBL(new);
}

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

