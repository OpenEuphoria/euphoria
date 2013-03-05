/*****************************************************************************/
/*      (c) Copyright - See License.txt       */
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
#include <stdint.h>
#if defined(EWINDOWS) && INTPTR_MAX == INT64_MAX
// MSVCRT doesn't handle long double output correctly
#define __USE_MINGW_ANSI_STDIO 1
#endif
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <assert.h>
#include <inttypes.h>
#ifdef EWINDOWS
#include <windows.h>
#else
#include <unistd.h>
#endif
#include "alldefs.h"
#include "be_runtime.h"
#include "be_alloc.h"

/******************/
/* Local defines  */
/******************/
#define NUMBER_OF_FBL 14        /* number of lists in free block set */
#define STR_CHUNK_SIZE 4096     /* chars */
#define SYM_CHUNK_SIZE 50       /* entries */
#define TMP_CHUNK_SIZE 50       /* entries */


/**********************/
/* Imported variables */
/**********************/
extern int Argc;

/**********************/
/* Exported variables */
/**********************/

#ifdef EBSD
char *malloc_options="A"; // abort
#endif

long pagesize;  // needed for Linux or Windows only, not FreeBSD

int eu_dll_exists = FALSE; // a Euphoria .dll is being used
#if defined(EALIGN4)
int align4 = 0;
#endif

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
unsigned long bytes_allocated = 0;       /* current number of object blocks alloc'd */
unsigned long max_bytes_allocated = 0;   /* high water mark */
#endif

d_ptr d_list = NULL;
//static int dblcnt = 0;
static struct block_list *pool_map[MAX_CACHED_SIZE/RESOLUTION+1]; /* maps size desired
														  to appropriate list */


/*******************/
/* Local variables */
/*******************/
static struct block_list freeblk_list[NUMBER_OF_FBL]; /* set of free block lists */
						 /* elements not power of 2 - but not used much */

/**********************/
/* Declared functions */
/**********************/
#ifndef EWINDOWS
void free();
#endif

/*********************/
/* Defined functions */
/*********************/

#ifndef RUNTIME
void RTInternal(char *msg, ...)
// Internal error
{
	va_list ap;
	va_start(ap, msg);
	RTFatal_va(msg, ap);
	va_end(ap);
}
#endif

#if defined(HEAP_CHECK) || defined(EXTRA_CHECK)

void check_pool()
{
		int i;
		struct block_list *first_fbl;
		struct block_list *last_fbl;

		first_fbl = &freeblk_list[0];
		last_fbl = &freeblk_list[NUMBER_OF_FBL-1];
		for (i = 0; i < MAX_CACHED_SIZE/RESOLUTION; i++) {
			if (pool_map[i] < first_fbl || pool_map[i] > last_fbl) {
				RTInternal("Corrupt pool_map!");
			}
		}
}
#endif
symtab_ptr tmp_alloc()
/* return pointer to space for a temporary var/literal constant */
{
	return (symtab_ptr)EMalloc(sizeof(struct temp_entry));
}

#ifdef EWINDOWS
long getpagesize (void) {
    static long g_pagesize = 0;
    if (! g_pagesize) {
        SYSTEM_INFO system_info;
        GetSystemInfo (&system_info);
        g_pagesize = system_info.dwPageSize;
    }
    return g_pagesize;
}
#endif

void InitEMalloc()
/* initialize storage allocator */
{
	int i, j, p;
	static int done = 0 ;

	if (done) return;
	done = 1;
	pagesize = getpagesize();
#ifndef UNIX
	// DJP // eu_dll_exists = (Argc == 0);  // Argc is 0 only in Euphoria .dll
	freeblk_list[0].size = 8;
	freeblk_list[0].first = NULL;
	p = RESOLUTION * 2;
	for (i = 1; i < NUMBER_OF_FBL; i = i + 2) {
		freeblk_list[i].size = p;
		freeblk_list[i].first = NULL;
		if (i+1 < NUMBER_OF_FBL) {
			freeblk_list[i+1].size = 3 * p / 2;
			freeblk_list[i+1].first = NULL;
			p = p * 2;
		}
	}

	j = 0;
	for (i = 0; i <= MAX_CACHED_SIZE / RESOLUTION; i++) {
		if (freeblk_list[j].size < i * RESOLUTION)
			j++;
		pool_map[i] = &freeblk_list[j];
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

	assert(((unsigned long)d_list & 7) == 0);	
	s = (s1_ptr)d_list;
	n = 0;
	while (s != NULL) {
		n++;
		s = (s1_ptr)((free_block_ptr)s)->next;
		if ((unsigned long)s % 8 != 0)
			iprintf(stderr, "misaligned s1d pointer!\n");
	}
	printf("\nd_list: %ld   ", n);

	for (i = 0; i < NUMBER_OF_FBL; i++) {
		printf("%d:", freeblk_list[i].size);
		n = 0;
		p = freeblk_list[i].first;
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
#if !defined(NDEBUG)
	unsigned long prev_value;
#endif

	if (n == 0) return;

#if !defined(NDEBUG)
	assert(n > 0);
	prev_value = bytes_allocated;
#endif
	bytes_allocated += n;
#if !defined(NDEBUG)
	// Check for overflow
	assert(bytes_allocated > prev_value);
#endif

	if (bytes_allocated > max_bytes_allocated)
		max_bytes_allocated = bytes_allocated;

}

static void DeAllocated(long n)
/* record that n bytes were freed */
{
#if !defined(NDEBUG)
	unsigned long prev_value;
#endif

	if (n == 0) return;

#if !defined(NDEBUG)
	prev_value = bytes_allocated;
#endif
	bytes_allocated -= n;
#if !defined(NDEBUG)
	// Check for underflow
	assert(bytes_allocated < prev_value);
#endif
}

/* write garbage into freed storage block to prevent accidental reuse */
#endif // HEAP_CHECK

#ifndef ESIMPLE_MALLOC
static void Free_All()
/* release the entire storage cache back to the heap */
{
	int i;
	struct block_list *list;
	s1_ptr s;
	unsigned char *p;

	for (i = 0; i < NUMBER_OF_FBL; i++) {
		list = &freeblk_list[i];
		s = (s1_ptr)list->first;
		while (s != NULL) {
			p = (unsigned char *)s;
			s = (s1_ptr)((free_block_ptr)s)->next;
			#if defined(EALIGN4)
			if (align4 && *(int *)(p-4) == MAGIC_FILLER)
				p = p - 4;
			#endif
			free(p);
		}
		list->first = NULL;
	}
	/* now do the doubles list */
	assert(((uintptr_t)d_list & 7) == 0);		
	s = (s1_ptr)d_list;
	while (s != NULL) {
		p = (unsigned char *)s;
		s = (s1_ptr)((free_block_ptr)s)->next;
		#if defined(EALIGN4)
		if (align4 && *(int *)(p-4) == MAGIC_FILLER)
			p = p - 4;
		#endif
		free(p);
	}
	d_list = NULL;
	cache_size = 0;
}
#endif

// #ifndef ESIMPLE_MALLOC
// static void Recycle()
// /* Try to recycle some cached blocks back to heap.
//    With write-back CPU cache, it might be better
//    to free an older block on the list, not the most-recently freed,
//    but we only have a singly-linked list */
// {
// 	register struct block_list *list;
// 	char *p;
// 	int i;
//
// #ifdef EXTRA_STATS
// 	recycles++;
// #endif
// 	/* try to take one from D list */
// 	if (d_list != NULL) {
// 		p = (char *)d_list;
// 		d_list = (d_ptr)((free_block_ptr)d_list)->next;
// 		#if defined(EALIGN4)
// 		if (align4 && *(int *)(p-4) == MAGIC_FILLER)
// 			p = p - 4;
// 		#endif
// 		free(p); /* give it back to heap */
// 		cache_size--;
// 	}
//
// 	/* try to take one from each other list */
// 	for (i = 0; i < NUMBER_OF_FBL; i++) {
// 		list = &freeblk_list[i];
// 		if (list->first != NULL) {
// 			p = (char *)list->first;
// 			list->first = ((free_block_ptr)p)->next;
// 			#if defined(EALIGN4)
// 			if (align4 && *(int *)(p-4) == MAGIC_FILLER)
// 				p = p - 4;
// 			#endif
// 			free(p); /* give it back to heap */
// 			cache_size--;
// 		}
// 	}
// }
// #endif

void SpaceMessage()
{
	/* should we free up something first, to ensure iprintf's work? */
	RTFatal("Your program has run out of memory.\nOne moment please...");
}

#ifndef ESIMPLE_MALLOC
static char *Out_Of_Space(long nbytes)
/* allocation failed - make one last attempt */
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
#endif
#ifndef ESIMPLE_MALLOC
char *EMalloc(uintptr_t nbytes)
/* storage allocator */
/* Always returns a pointer that has 8-byte alignment (essential for our
   internal representation of an object). */
{
	char *p;
	free_block_ptr temp;
	register struct block_list *list;
#if defined(EALIGN4)
	int alignment;
#endif
	struct block_list * last_FBL;

#ifdef HEAP_CHECK
	long size;
#endif
#ifdef HEAP_CHECK
	check_pool();
#endif
#if defined(EALIGN4)
	nbytes += align4; // allow for 4-aligned addresses that are not always 8-aligned.
#endif

	if (nbytes <= MAX_CACHED_SIZE) {
		/* See if we have a block of this size in our cache.
		   Every block in the cache is 8-aligned. */

		list = pool_map[((nbytes + RESOLUTION - 1) >> LOG_RESOLUTION)];
#ifdef HEAP_CHECK
		if (list->size < nbytes) {
			RTInternal("Alloc - size is %d, nbytes is %d", list->size, nbytes);
		}
#endif
		temp = list->first;

		if (temp == NULL) {
			last_FBL = &freeblk_list[NUMBER_OF_FBL-1];
			if (list < last_FBL) {
				list++;
				temp = list->first;
			}
		}

		if (temp != NULL) {
			/* a cache hit */

#ifdef EXTRA_STATS
			a_hit++;
#endif
			list->first = temp->next;
			cache_size--;

#ifdef HEAP_CHECK
			if (cache_size > 100000000)
				RTInternal("cache size is bad");
			p = (char *)temp;
			#if defined(EALIGN4)
			if (align4 && *(int *)(p-4) == MAGIC_FILLER)
				p = p - 4;
			if (((unsigned long)temp) & 3)
				RTInternal("unaligned address in storage cache");
			#endif
			Allocated(block_size(p));
#endif
			return (char *)temp; /* will be 8-aligned */
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

// *** COMMENTED OUT (D.Parnell) because I'm not sure if this really helps anything.
// 	if (cache_size >= CACHE_LIMIT) {
// 		// cache is not helping, free some blocks back to general heap
// 		Recycle();
// 	}

	do {
		p = malloc((long)nbytes+8);
// 		assert(p);
		if (p == NULL) {
			printf("couldn't alloc %" PRIdPTR " bytes\n", nbytes );
			// Only triggered if asserts are turned off.
			p = Out_Of_Space(nbytes + 8);
		}

#ifdef HEAP_CHECK
		Allocated(block_size(p));
#endif

#if defined(EALIGN4)
		/* get 8-byte alignment */
		alignment = ((unsigned long)p) & 7;

		if (alignment == 0) {
			if (align4 && *(int *)(p-4) == MAGIC_FILLER)
				// don't free. grab a new one.
				continue;  // magic is there by chance!
						   // (this case is remotely possible on Win95 only)
			return p;   // already 8-aligned, should happen most of the time
		}

		if (alignment != 4) {
			RTFatal("malloc block NOT 4-byte aligned!\n");
		}

		if (align4) {
			*(int *)p = MAGIC_FILLER;
			assert((((unsigned int)p + 4) & 7) == 0);
			return p+4;
		}

		/* first occurrence of a 4-aligned block */
		free(p);
		align4 = 4;  // start handling 4-aligned blocks
		nbytes += align4;
#else
		assert(((uintptr_t)p & 7) == 0);
		return p;
#endif
	} while (TRUE);
}

void EFree(char *p)
/* free storage pointed to by p. p is an 8-byte aligned pointer */
{
	char *q;
	register long nbytes;
	register struct block_list *list;


#ifdef HEAP_CHECK
	check_pool();

	if (((long)p & 7) != 0)
		RTInternal("EFree: badly aligned pointer");
#endif // HEAP_CHECK
	q = p;
	#if defined(EALIGN4)
	if (align4 && *(int *)(p-4) == MAGIC_FILLER) {
		q = q - 4;
	}
	#endif
	nbytes = block_size(q);
#ifdef HEAP_CHECK
	if ((nbytes <= MAX_CACHED_SIZE) && ((nbytes & 1) != 0)) {
		RTInternal("EFree: already free?");
	}
	DeAllocated(nbytes);
	if (nbytes <= MAX_CACHED_SIZE && ((nbytes < RESOLUTION) || (nbytes % 4 != 0))) {
		RTInternal("Free - bad nbytes: %d\n", nbytes);
		/* what if compile time? */
	}
	Trash(p, nbytes - (p - q));
#endif // HEAP_CHECK

	if (nbytes > MAX_CACHED_SIZE || (cache_size > CACHE_LIMIT)) {
		free(q); /* too big to cache, or cache is full */
	}
	else {
		list = pool_map[((nbytes + RESOLUTION - 1) >> LOG_RESOLUTION)];
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
		cache_size++;
	}

}

#else
#if !defined(EWINDOWS) && !defined(EUNIX)
// Version of allocation routines for systems that might not return allocations
// that are 4-byte aligned.
char *EMalloc(unsigned long nbytes)
/* storage allocator */
/* Always returns a pointer that has 8-byte alignment (essential for our
   internal representation of an object). */
{
	char *p;
	char *a;
	unsigned long adj;

	// Add max possible adjustment (7) plus 1 to store adjustment value,
	// plus 4 to store the requested size.
	a = (char *)malloc(nbytes + 1 + sizeof(nbytes) + 7);
	assert(a);
	a += 1 + sizeof(nbytes);	// Skip over the stored stuff.
	adj = (unsigned long)a & 7;
	if (adj) {
		adj = 8 - adj;
		p = a + adj;
	}
	else
		p = a;
	assert( ((unsigned long)p & 7) == 0);
	*(p-1) = (char)adj;
	*((unsigned long*)(p - 1 - sizeof(nbytes))) = nbytes;
	return p;
}

void EFree(char *p)
{
	// 'p' must have been allocated by EMalloc.
	unsigned char adj;

	assert(p);
	adj = *(p-1);
	p = p - 1 - sizeof(unsigned long) - adj;
	free(p);
}

char *ERealloc(char *orig, uintptr_t newsize)
{
	char *newadr;
	uintptr_t oldsize;
	int res;

	newadr = EMalloc(newsize);
	oldsize = *((unsigned long*)(orig - 1 - sizeof(oldsize)));

    res = memcopy(newadr, newsize, orig, (oldsize > newsize ? newsize : oldsize));
	if (res != 0) {
		RTFatal("Internal error: ERealloc memcopy failed (%d).", res);
	}

	EFree(orig);

	return newadr;
}
#endif // not windows and not unix

#endif

#ifndef EUNIX
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
#endif // EXTRA_CHECK
#endif // EWINDOWS
#endif // EUNIX

#ifndef ESIMPLE_MALLOC
char *ERealloc(char *orig, uintptr_t newsize)
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
	int res;

	p = orig;
	#if defined(EALIGN4)
	if (align4 && *(int *)(p-4) == MAGIC_FILLER)
		p = p - 4;
	#endif
	oldsize = block_size(p);
	newsize += 8;

	if (newsize <= oldsize) {
		// make a smaller block
		q = realloc(p, newsize);
	}
	else {
		q = NULL;
	}

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
	else if (((uintptr_t)q & 0x07) == ((uintptr_t)p & 0x07)) {
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
    res = memcopy(q, newsize, orig, oldsize - (orig - p));
	if (res != 0) {
		RTFatal("Internal error: ERealloc memcopy failed (%d).", res);
	}
	EFree(orig);
	return q;
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
/* free double storage block */
void freeD(unsigned char *p)
{
	assert(((unsigned long)p & 7) == 0);		
	Trash(p, D_SIZE);
	AlreadyFree((free_block_ptr)d_list, (free_block_ptr)p);

	((free_block_ptr)p)->next = (free_block_ptr)d_list;
	d_list = (d_ptr)p;
}
#endif

s1_ptr NewS1(intptr_t size)
/* make a new s1 sequence block with a single reference count */
/* size is number of elements, NOVALUE is added as an end marker */
{
	register s1_ptr s1;

	assert(size >= 0);
	if ((unsigned long)size > MAX_SEQ_LEN) {
		// Ensure it doesn't overflow
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

object NewSequence(char *data, int len)
/* create a new sequence that may contain binary data */
{
	object_ptr obj_ptr;
	s1_ptr c1;

	c1 = NewS1((long)len);
	obj_ptr = (object_ptr)c1->base;
	for ( ; len > 0; --len) {
		*(++obj_ptr) = (unsigned char)*data++;
	}
	return MAKE_SEQ(c1);
}

object NewString(char *s)
/* create a new string sequence */
{
	return NewSequence(s, strlen(s));
}

object NewPreallocSeq(intptr_t size, s1_ptr s1)
/* fill in bookkeeping data for a new sequence with a single reference count with the data preallocated.*/
/* size is number of elements already in the data, which must start imediately after the s1 struct data.
   Note: The last element in the sequence is given the value NOVALUE as an end marker. */
{

	assert(size >= 0);
	if ((unsigned long)size > MAX_SEQ_LEN) {
		// Ensure it doesn't overflow
		SpaceMessage();
	}
	s1->ref = 1;
	s1->base = (object_ptr) (s1 + 1);
	s1->length = size-1;
	s1->postfill = 0; /* there may be some available but don't waste time */
					  /* prepend assumes this is set to 0 */
	s1->cleanup = 0;
	s1->base[s1->length] = NOVALUE; // Ensure end marker is present.
	s1->base--;  // point to "0th" element
	return MAKE_SEQ(s1);
}

s1_ptr SequenceCopy(register s1_ptr a)
/* take a single-ref copy of sequence 'a' */
{
	s1_ptr c;
	register object_ptr cp, ap;
	register int length;
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

/* ----------------------------------------------------------------------
  :: copy_string ::
 Returns 0 if destination cannot fit any source characters otherwise
 the absolute return value is the number of characters from source that
 have been copied. If the return value is negative, it means that not
 all of the source has been copied.

 To test if truncation occurred, the return value will be <= 0.
 
 src must be null terminated.
*/
long copy_string(char *dest, char *src, size_t bufflen)
{
	long n;
	n = 0;
	while (bufflen > 1 && *src != '\0') {
		*dest++ = *src++;
		n++;
		bufflen--;
	}
	if (n > 0) {	// At least one char was copied.
		*dest = '\0';
	 	if (*src != '\0')
	 		n = -n; // Only some of source was copied to the destination
 	}
	else {
		// Destination too small
		if (bufflen > 0)
			*dest = '\0';
	}
	return n;
}

/* ----------------------------------------------------------------------
  :: append_string ::
 Returns 0 if destination cannot fit any source characters otherwise
 the absolute return value is the number of characters from source that
 have been copied. If the return value is negative, it means that not
 all of the source has been copied.

 To test if truncation occurred, the return value will be <= 0.
*/
long append_string(char *dest, char *src, size_t bufflen)
{

	int dest_len;

	dest_len = strlen(dest);
	if ((size_t)dest_len + 1 < bufflen) {
		return copy_string(dest + dest_len, src, bufflen - dest_len);
	}

	if ((size_t)dest_len + 1 == bufflen)
		*(dest + dest_len) = '\0';

	return 0;
}

free_block_ptr *double_blocks = 0;
int double_blocks_allocated = 0;

static void new_dbl_block(unsigned int cnt)
{
	free_block_ptr dbl_block;
	d_ptr n;
	unsigned int dsize;
	unsigned int blksize;
	int chkcnt;
#ifdef HEAP_CHECK
	char *q;
#endif

	// Each element in the array must be on an 8-byte boundary.
	dsize = (D_SIZE + 7) & (~7);

	blksize = cnt * dsize;
	dbl_block = (free_block_ptr)EMalloc( blksize );
	assert(((uintptr_t)dbl_block & 7) == 0);

	if( double_blocks_allocated ){
		double_blocks = (free_block_ptr*) ERealloc( (char*) double_blocks, sizeof( free_block_ptr ) * ++double_blocks_allocated );
	}
	else{
		double_blocks = (free_block_ptr*) EMalloc( sizeof( free_block_ptr ) );
		++double_blocks_allocated;
	}
	double_blocks[double_blocks_allocated-1] = dbl_block;
	
#ifdef HEAP_CHECK
	Trash((char *)dbl_block, blksize);
	q = (char *)dbl_block;
	#if defined(EALIGN4)
	if (align4 && *(int *)(q-4) == MAGIC_FILLER)
		q = q - 4;
	#endif
	Allocated(block_size(q));
#endif

	chkcnt = 0;
	d_list = (d_ptr)dbl_block;
	while(cnt > 1) {
		--cnt;
		n = (d_ptr)((char *)dbl_block + dsize);
		dbl_block->next = (free_block_ptr)n;
		dbl_block = (free_block_ptr)n;
		chkcnt++;
	}
	dbl_block->next = NULL;
	chkcnt++;
}

object NewDouble(eudouble d)
/* allocate space for a new double value */
{
	register d_ptr new_dbl;

	if (d_list == NULL) {
		new_dbl_block(1024);
	}

	new_dbl = d_list;
	assert(((uintptr_t)new_dbl & 7) == 0);
	d_list = (d_ptr)((free_block_ptr)new_dbl)->next;

	new_dbl->ref = 1;
	new_dbl->dbl = d;
	new_dbl->cleanup = 0;
	return MAKE_DBL(new_dbl);
}

#ifdef ESIMPLE_MALLOC
char *ERealloc(char *orig, uintptr_t newsize)
/* Enlarge or shrink a malloc'd block.
   orig must not be NULL - not supported.
   Return a pointer to a storage area of the desired size
   containing all the original data.
   I don't think a shrink could ever become an expansion + copy
   by accident, but newsize might be less than the current size! */
{
	char *q;

	// make a smaller block
	q = realloc(orig, newsize);

	if (q == NULL) {
		SpaceMessage();
	}

	return q;
}

char *EMalloc(uintptr_t nbytes)
/* storage allocator */
/* Always returns a pointer that has 8-byte alignment (essential for our
   internal representation of an object). */
{
	char * p = malloc(nbytes);
	if (p == NULL)
		SpaceMessage();
	return p;
}
#endif
