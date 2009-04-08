/*****************************************************************************/
/*      (c) Copyright 2007 Rapid Deployment Software - See License.txt       */
/*****************************************************************************/
/*                                                                           */
/*                         BACKEND STORAGE ALLOCATION                        */
/*                                                                           */
/*****************************************************************************/

/*
 * On Windows we use the WIN32 Heap functions on the default heap.
 * This lets us share the heap with any Euphoria .dlls. We serialize access
 * to this heap because of the warnings given in the WIN32 docs.
 * The internal representation of a Euphoria object requires blocks that
 * are 8-byte aligned. We can deal with 4-byte aligned blocks from malloc
 * on all systems, but we will only see 8-byte aligned blocks on Windows
 * (except Windows 95), and FreeBSD. A storage "cache" is used to cut down
 * on the number of calls to malloc. On FreeBSD we do not use the
 * storage cache because it's not easy to determine the block size
 * of freed blocks.
 */

/******************/
/* Included files */
/******************/
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#ifdef EWINDOWS
#include <windows.h>
#endif
#include "alldefs.h"
#include "alloc.h"
#include "be_runtime.h"

/******************/
/* Local defines  */
/******************/
#define NUMBER_OF_SIZES 14      /* number of size lists in pool */
#define RESOLUTION 8            /* minimum size & increment before mapping */
#define LOG_RESOLUTION 3        /* log2 of RESOLUTION */
#define STR_CHUNK_SIZE 4096     /* chars */
#define SYM_CHUNK_SIZE 50       /* entries */
#define TMP_CHUNK_SIZE 50       /* entries */


/**********************/
/* Imported variables */
/**********************/
extern int Executing;
extern symtab_ptr CurrentSub;
extern int temps_allocated;
extern IFILE obj_file;
extern unsigned char *src_buf;
extern int Argc;
#ifdef EWINDOWS
extern unsigned default_heap;
#endif

/**********************/
/* Exported variables */
/**********************/
#ifdef EBSD
char *malloc_options="A"; // abort
#endif

#ifdef EUNIX
int pagesize;  // needed for Linux only, not FreeBSD
#endif

int eu_dll_exists = FALSE; // a Euphoria .dll is being used
int align4 = 0;
int low_on_space = FALSE;  // are we almost out of memory?
unsigned cache_size = 0;
symtab_ptr call_back_arg1, call_back_arg2, call_back_arg3, call_back_arg4,
		   call_back_arg5, call_back_arg6, call_back_arg7, call_back_arg8,
		   call_back_arg9, call_back_result;

#ifdef EXTRA_STATS
unsigned recycles = 0;          /* calls to Recycle() */
long a_miss = 0;                /* cache list was empty */
long a_hit = 0;                 /* found in cache */
long a_too_big = 0;             /* too big - no caching */
long funny_expand = 0;          /* _expand returns new pointer */
long funny_align = 0;           /* number mallocs not 8-aligned */
#endif

#ifdef HEAP_CHECK
long bytes_allocated = 0;       /* current number of object blocks alloc'd */
long max_bytes_allocated = 0;   /* high water mark */
#endif

s1_ptr d_list = NULL;
struct block_list *pool_map[MAX_CACHED_SIZE/RESOLUTION+1]; /* maps size desired
														  to appropriate list */


/*******************/
/* Local variables */
/*******************/
static struct block_list pool[NUMBER_OF_SIZES]; /* pool of free blocks */
						 /* elements not power of 2 - but not used much */

static char *str_free_ptr;
static unsigned int chars_remaining = 0;

static symtab_ptr sym_free_ptr;
static unsigned int syms_remaining = 0;

static temp_ptr tmp_free_ptr;
static unsigned int tmps_remaining = 0;

/**********************/
/* Declared functions */
/**********************/
#ifndef ESIMPLE_MALLOC
char *EMalloc(unsigned long);
char *ERealloc(unsigned char *, unsigned long);
void EFree(unsigned char *);
#endif
#ifndef EWINDOWS
void free();
#endif
object NewString();
static void AlreadyFree();
size_t _msize();

/*********************/
/* Defined functions */
/*********************/

#ifdef HEAP_CHECK

void RTInternal(char *msg, ...)
// Internal error
{
	va_list ap;
	va_start(ap, msg);
	RTFatal_va(msg);
	va_end(ap);
}


void check_pool()
{
		int i;

		for (i = 0; i < MAX_CACHED_SIZE/RESOLUTION; i++) {
			if (pool_map[i] < pool || pool_map[i] > pool+NUMBER_OF_SIZES-1)
				RTInternal("Corrupt pool_map!");
		}
}
#endif

symtab_ptr tmp_alloc()
/* return pointer to space for a temporary var/literal constant */
{
	return (symtab_ptr)EMalloc(sizeof(struct temp_entry));
}

void InitEMalloc()
/* initialize storage allocator */
{
	int i, j, p;
#ifdef EUNIX
	pagesize = getpagesize();
#else
	eu_dll_exists = (Argc == 0);  // Argc is 0 only in Euphoria .dll
	pool[0].size = 8;
	pool[0].first = NULL;
	p = RESOLUTION * 2;
	for (i = 1; i < NUMBER_OF_SIZES; i = i + 2) {
		pool[i].size = p;
		pool[i].first = NULL;
		if (i+1 < NUMBER_OF_SIZES) {
			pool[i+1].size = 3 * p / 2;
			pool[i+1].first = NULL;
			p = p * 2;
		}
	}
	j = 0;
	for (i = 0; i <= MAX_CACHED_SIZE / RESOLUTION; i++) {
		if (pool[j].size < i * RESOLUTION)
			j++;
		pool_map[i] = &pool[j];
	}
#endif
	call_back_arg1 = tmp_alloc();
	call_back_arg1->mode = M_TEMP;
	call_back_arg1->obj = NOVALUE;

	call_back_arg2 = tmp_alloc();
	call_back_arg2->mode = M_TEMP;
	call_back_arg2->obj = NOVALUE;

	call_back_arg3 = tmp_alloc();
	call_back_arg3->mode = M_TEMP;
	call_back_arg3->obj = NOVALUE;

	call_back_arg4 = tmp_alloc();
	call_back_arg4->mode = M_TEMP;
	call_back_arg4->obj = NOVALUE;

	call_back_arg5 = tmp_alloc();
	call_back_arg5->mode = M_TEMP;
	call_back_arg5->obj = NOVALUE;

	call_back_arg6 = tmp_alloc();
	call_back_arg6->mode = M_TEMP;
	call_back_arg6->obj = NOVALUE;

	call_back_arg7 = tmp_alloc();
	call_back_arg7->mode = M_TEMP;
	call_back_arg7->obj = NOVALUE;

	call_back_arg8 = tmp_alloc();
	call_back_arg8->mode = M_TEMP;
	call_back_arg8->obj = NOVALUE;

	call_back_arg9 = tmp_alloc();
	call_back_arg9->mode = M_TEMP;
	call_back_arg9->obj = NOVALUE;

	call_back_result = tmp_alloc();
	call_back_result->mode = M_TEMP;
	call_back_result->obj = NOVALUE;
}

#ifdef EXTRA_STATS
void StorageStats()
{
	int i;
	long n;
	free_block_ptr p;
	s1_ptr s;

	s = d_list;
	n = 0;
	while (s != NULL) {
		n++;
		s = (s1_ptr)((free_block_ptr)s)->next;
		if ((long)s % 8 != 0)
			iprintf(stderr, "misaligned s1d pointer!\n");
	}
	printf("\nd_list: %ld   ", n);

	for (i = 0; i < NUMBER_OF_SIZES; i++) {
		printf("%d:", pool[i].size);
		n = 0;
		p = pool[i].first;
		while (p != NULL) {
			n++;
			p = p->next;
		}
		printf("%ld   ", n);
	}
	printf("cache_size: %d\n\n", cache_size);
}
#endif

#ifdef HEAP_CHECK
void Allocated(long n)
/* record that n bytes were allocated */
{
	if (n < 0 || n >= 40000000L) {
		RTInternal("bad value passed to Allocated (%d)", n);
	}
	bytes_allocated += n;
	if (bytes_allocated > max_bytes_allocated)
		max_bytes_allocated = bytes_allocated;
}

static DeAllocated(long n)
/* record that n bytes were freed */
{
	bytes_allocated -= n;
	if (n < 0 || n >= 40000000L)
		RTInternal("bad value passed to DeAllocated");
#ifdef FIX
	if (bytes_allocated < 0 || bytes_allocated >= 140000000L) {
		RTInternal("DeAllocated: bytes_allocated is %d, n is %d\n",
				bytes_allocated, n);
	}
#endif
}

void Trash(char *p, long nbytes)
/* write garbage into freed storage block to prevent accidental reuse */
{
	while (nbytes-- > 0)
		*p++ = (char)0x11;
}
#endif // HEAP_CHECK

static void Free_All()
/* free the entire storage cache back to the malloc arena */
{
	int i, alignment;
	struct block_list *list;
	s1_ptr s;
	unsigned char *p;

	for (i = 0; i < NUMBER_OF_SIZES; i++) {
		list = &pool[i];
		s = (s1_ptr)list->first;
		while (s != NULL) {
			p = (unsigned char *)s;
			s = (s1_ptr)((free_block_ptr)s)->next;
			if (align4 && *(int *)(p-4) == MAGIC_FILLER)
				p = p - 4;
			free(p);
		}
		list->first = NULL;
	}
	/* now do the S1D list */
	s = d_list;
	while (s != NULL) {
		p = (unsigned char *)s;
		s = (s1_ptr)((free_block_ptr)s)->next;
		if (align4 && *(int *)(p-4) == MAGIC_FILLER)
			p = p - 4;
		free(p);
	}
	d_list = NULL;
	cache_size = 0;
}

static void Recycle()
/* Try to recycle some cached blocks back to heap.
   With write-back CPU cache, it might be better
   to free an older block on the list, not the most-recently freed,
   but we only have a singly-linked list */
{
	register struct block_list *list;
	unsigned char *p;
	int i;

#ifdef EXTRA_STATS
	recycles++;
#endif
	/* try to take one from D list */
	if (d_list != NULL) {
		p = (unsigned char *)d_list;
		d_list = (s1_ptr)((free_block_ptr)d_list)->next;
		if (align4 && *(int *)(p-4) == MAGIC_FILLER)
			p = p - 4;
		free(p); /* give it back to malloc arena */
		cache_size -= 1;
	}

	/* try to take one from each other list */
	for (i = 0; i < NUMBER_OF_SIZES; i++) {
		list = &pool[i];
		if (list->first != NULL) {
			p = (char *)list->first;
			list->first = ((free_block_ptr)p)->next;
			if (align4 && *(int *)(p-4) == MAGIC_FILLER)
				p = p - 4;
			free(p); /* give it back to malloc arena */
			cache_size -= 2;
		}
	}
}

static void SpaceMessage()
{
	/* should we free up something first, to ensure iprintf's work? */

	RTFatal("Your program has run out of memory.\nOne moment please...");
}

static char *Out_Of_Space(long nbytes)
/* malloc failed - make one last attempt */
{
	long *p;

	Free_All();
	p = (long *)malloc(nbytes);
	if (p == NULL) {
		low_on_space = TRUE;
		SpaceMessage();
		return NULL; /* shouldn't need this */
	}
	else {
		return (char *)p;
	}
}

#ifndef ESIMPLE_MALLOC
char *EMalloc(unsigned long nbytes)
/* storage allocator */
/* Always returns a pointer that has 8-byte alignment (essential for our
   internal representation of an object). */
{
	unsigned char *p;
	unsigned char *temp;
	register struct block_list *list;
	int alignment;
	int min_align;

#if defined(EUNIX) || defined(ESIMPLE_MALLOC)

		return malloc(nbytes);
#else
#ifdef HEAP_CHECK
	long size;

	check_pool();
#endif
	nbytes += align4; // allow for possible 4-aligned malloc pointers

	if (nbytes <= MAX_CACHED_SIZE) {
		/* See if we have a block of this size in our cache.
		   Every block in the cache is 8-aligned. */

		list = pool_map[((nbytes & 7) != 0) + (nbytes >> LOG_RESOLUTION)];
#ifdef HEAP_CHECK
		if (list->size < nbytes) {
			RTInternal("Alloc - size is %d, nbytes is %d", list->size, nbytes);
		}
#endif
		temp = (char *)list->first;

		if (temp != NULL) {
			/* a cache hit */

#ifdef EXTRA_STATS
			a_hit++;
#endif
			list->first = ((free_block_ptr)temp)->next;
			cache_size -= 2;

#ifdef HEAP_CHECK
			if (cache_size > 100000000)
				RTInternal("cache size is bad");
			p = temp;
			if (align4 && *(int *)(p-4) == MAGIC_FILLER)
				p = p - 4;
			if (((unsigned long)temp) & 3)
				RTInternal("unaligned address in storage cache");
			Allocated(block_size(p));
#endif
			return temp; /* will be 8-aligned */
		}
		else {
			nbytes = list->size; /* better to grab bigger size
									so it can be reused for same purpose */
#ifdef EXTRA_STATS
			a_miss++;
#endif
		}
	}
#ifdef EXTRA_STATS
	else
		a_too_big++;
#endif

	if (cache_size > CACHE_LIMIT) {
		// cache is not helping, free some blocks back to general heap
		Recycle();
	}

	do {
		p = malloc(nbytes+8);

		if (p == NULL) {
			p = Out_Of_Space(nbytes);
		}

#ifdef HEAP_CHECK
		Allocated(block_size(p));
#endif
		/* get 8-byte alignment */
		alignment = ((unsigned long)p) & 7;

		if (alignment == 0) {
			if (align4 && *(int *)(p-4) == MAGIC_FILLER)
				// don't free. grab a new one.
				continue;  // magic is there by chance!
						   // (this case is remotely possible on Win95 only)
			return p;   // already 8-aligned, should happen most of the time
		}
		if (alignment != 4)
			RTFatal("malloc block NOT 4-byte aligned!\n");

		if (align4) {
			*(int *)p = MAGIC_FILLER;
			return p+4;
		}

		/* first occurrence of a 4-aligned block */
		free(p);
		align4 = 4;  // start handling 4-aligned blocks
		nbytes += align4;
	} while (TRUE);
#endif
// !EUNIX
}

void EFree(unsigned char *p)
/* free storage pointed to by p. p is an 8-byte aligned pointer */
{
	char *q;
	register long nbytes;
	register struct block_list *list;
	int align;

#if defined(EUNIX) || defined(ESIMPLE_MALLOC)
		free(p);
		return;
#else
#ifdef HEAP_CHECK
	check_pool();

	if (((long)p & 7) != 0)
		RTInternal("EFree: badly aligned pointer");
#endif // HEAP_CHECK
	q = p;
	if (align4 && *(int *)(p-4) == MAGIC_FILLER)
		q = q - 4;
	nbytes = block_size(q);
#ifdef HEAP_CHECK
	if ((nbytes & 1) != 0)
		RTInternal("EFree: already free?");
	DeAllocated(nbytes);
	if (nbytes < RESOLUTION || nbytes > 40000000L || (nbytes % 4 != 0)) {
		RTInternal("Free - bad nbytes: %d\n", nbytes);
		/* what if compile time? */
	}
	Trash(p, nbytes - ((char *)p - q));
#endif // HEAP_CHECK

	if (nbytes > MAX_CACHED_SIZE || (eu_dll_exists && cache_size > CACHE_LIMIT)) {
		free(q); /* too big to cache, or cache is full */
	}
	else {
		list = pool_map[((nbytes & 7) != 0) + (nbytes >> LOG_RESOLUTION)];
		if (list->size > nbytes) {
			/* only happens with non-standard size (from realloc maybe) */
			list--;
		}
#ifdef HEAP_CHECK
		if (list->size > nbytes)
			RTInternal("Free - list size greater than nbytes");
		if (list->size * 3 / 2 < nbytes - 2)
			RTInternal("Free - list size is small");

		AlreadyFree(list->first, (free_block_ptr)p);  /* can be very slow */
#endif // HEAP_CHECK
		((free_block_ptr)p)->next = list->first;
		list->first = (free_block_ptr)p;
		cache_size += 2;
	}
#endif // linux
}
#endif // !ESIMPLE_MALLOC

#ifndef EDJGPP
#ifndef EUNIX
#ifndef ELCC
#ifndef EWINDOWS
#ifdef EXTRA_CHECK
#include <malloc.h>

int heap_dump(char *ptr)
{
	struct _heapinfo h_info;
	int heap_status, found;

	found = FALSE;
	h_info._pentry = NULL;
	for (;;) {
		heap_status = _heapwalk(&h_info);
		if (heap_status != _HEAPOK)
			break;
		//printf("  %s block at %Fp of size %4.4X\n",
		//       (h_info._useflag == _USEDENTRY ? "USED" : "FREE"),
		//       h_info._pentry, h_info._size);
		if ((long)h_info._pentry == (long)(ptr-4))
			found = TRUE;
	}
	switch (heap_status) {
		case _HEAPEND:
			//printf("OK - end of heap\n");
			break;
		case _HEAPEMPTY:
			//printf("OK - heap is empty\n");
			break;
		case _HEAPBADBEGIN:
			printf("ERROR - heap is damaged\n");
			break;
		case _HEAPBADPTR:
			printf("ERROR - bad pointer to heap\n");
			break;
		case _HEAPBADNODE:
			printf("ERROR - bad node in heap\n");
			break;
	}
	return found;
}
#endif
#endif
#endif
#endif
#endif
#ifndef ESIMPLE_MALLOC
char *ERealloc(unsigned char *orig, unsigned long newsize)
/* Enlarge or shrink a malloc'd block.
   orig must not be NULL - not supported.
   Return a pointer to a storage area of the desired size
   containing all the original data.
   I don't think a shrink could ever become an expansion + copy
   by accident, but newsize might be less than the current size! */
{
	char *p;
	char *q;
	unsigned long oldsize;

#if defined(EUNIX) || defined(ESIMPLE_MALLOC)

	// we always have 8-alignment
	return realloc(orig, newsize);  // should do bookkeeping on block size?
#else
	p = orig;
	if (align4 && *(int *)(p-4) == MAGIC_FILLER)
		p = p - 4;
	oldsize = block_size(p);
	newsize += 8;

#if defined(EWATCOM) && defined(EDOS)
	// only available with WATCOM on DOS
	q = _expand(p, newsize);

#else
	if (newsize <= oldsize) {
		// make a smaller block
		q = realloc(p, newsize);
	}
	else {
		q = NULL;
	}
#endif

	if (q == NULL) {
		/*
		 * p only partially expanded, drop through
		 */
	}
	else if (q == p) {
		/* p was successfully expanded in-place */
#ifdef HEAP_CHECK
		if (newsize > oldsize)
			Allocated(block_size(p) - oldsize);
		else
			DeAllocated(oldsize - block_size(p));
#endif
		return orig;
	}
	else if (((long)q & 0x07) == ((long)p & 0x07)) {
		/* q is aligned the same way as p modulo 8 (almost always I think) */
		orig = orig + (q - p);
		return orig;
	}
	else {
		/* q is not aligned right (rare) - get rid of it */
		/* I've never seen this. */
		orig = orig + (q - p);
		p = q;
	}

#ifdef HEAP_CHECK
	Allocated(block_size(p) - oldsize);
#endif
	/* failed to expand in-place, malloc a new space */
	q = EMalloc(newsize);
	/* copy the data to it's new location */
	/* OPTIMIZE? we may be copying more than the actual live data */
	memcpy(q, orig, oldsize - (orig - (unsigned char *)p));
	EFree(orig);
	return q;
#endif
}
#endif // !ESIMPLE_MALLOC

#ifdef HEAP_CHECK
static void AlreadyFree(free_block_ptr q, free_block_ptr p)
/* see if p is already on the free list */
{
	while (q != NULL) {
		if (q == p)
			RTInternal("attempt to free again");
		q = q->next;
	}
}
#endif

#ifdef HEAP_CHECK
void freeD(p)
/* free double storage block */
unsigned char *p;
{
	long nbytes;
	char *q;
	int alignment;

	q = p;
	if (align4 && *(int *)(p-4) == MAGIC_FILLER)
		q = q - 4;
	nbytes = block_size(q);
	DeAllocated(nbytes);
	if ((long)p % 8 != 0)
		RTInternal("freeS1: misaligned pointer returned");
	if (nbytes < D_SIZE
#ifdef EDJGPP
	- 8
#endif
	|| nbytes > 1024)
		RTInternal("FreeD - bad nbytes ");
	Trash(p, D_SIZE);
	AlreadyFree((free_block_ptr)d_list, (free_block_ptr)p);

	((d_ptr)p)->dbl = 1e300;  // ->next overlaps with this anyway

	((free_block_ptr)p)->next = (free_block_ptr)d_list;
	d_list = (s1_ptr)p;
	cache_size += 1;
}
#endif

s1_ptr NewS1(long size)
/* make a new s1 sequence block with a single reference count */
/* size is number of elements, NOVALUE is added as an end marker */
{
	register s1_ptr s1;

	if (size > 1073741800) {
		// multiply by 4 could overflow 32 bits
		SpaceMessage();
	}
	s1 = (s1_ptr)EMalloc(sizeof(struct s1) + (size+1) * sizeof(object));
	s1->ref = 1;
	s1->base = (object_ptr)(s1 + 1);
	s1->length = size;
	s1->postfill = 0; /* there may be some available but don't waste time */
					  /* prepend assumes this is set to 0 */
	s1->cleanup = 0;
	s1->base[size] = NOVALUE;
	s1->base--;  // point to "0th" element
	return(s1);
}

object NewString(unsigned char *s)
/* create a new string sequence */
{
	int len;
	object_ptr obj_ptr;
	s1_ptr c1;

	len = strlen(s);
	c1 = NewS1((long)len);
	obj_ptr = (object_ptr)c1->base;
	if (len > 0) {
		do {
			*(++obj_ptr) = (unsigned char)*s++;
		} while (--len > 0);
	}
	return MAKE_SEQ(c1);
}

s1_ptr SequenceCopy(register s1_ptr a)
/* take a single-ref copy of sequence 'a' */
{
	s1_ptr c;
	register object_ptr cp, ap;
	register long length;
	register object temp_ap;

	/* a is a SEQ_PTR */
	length = a->length;
	c = NewS1(length);
	cp = c->base;
	ap = a->base;
	while (TRUE) {  // NOVALUE will be copied
		temp_ap = *(++ap);
		*(++cp) = temp_ap;
		if (!IS_ATOM_INT(temp_ap)) {
			if (temp_ap == NOVALUE)
				break;
			RefDS(temp_ap);
		}
	}
	DeRefSP(a);
	return c;
}

char *TransAlloc(unsigned long size){
// Convenience function for translated code to use EMalloc
	return EMalloc( size );
}

#if defined(ELINUX) || defined(EMINGW) || defined(EDJGPP) || defined(EMSVC)
size_t strlcpy(char *dest, char *src, size_t maxlen)
{
	int i;
	strncpy(dest, src, maxlen);
	dest[maxlen-1] = 0;

	i = strlen(src);
	return i > maxlen ? maxlen : i;
}

size_t strlcat(char *dest, char *src, size_t maxlen)
{
	strncat(dest, src, maxlen-1);
	dest[maxlen-1] = 0;
	return strlen(dest);
}
#endif

