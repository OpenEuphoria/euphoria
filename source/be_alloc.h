/*****************************************************************************/
/*                                                                           */
/*                        STORAGE ALLOCATION MACROS                          */
/*                                                                           */
/*****************************************************************************/
#ifndef BE_ALLOC_H_
#define BE_ALLOC_H_ 1

#include <limits.h>
#include "execute.h"
#include "symtab.h"

#ifndef MAX_SEQ_LEN
#if INTPTR_MAX == INT32_MAX
#	define MAX_SEQ_LEN ((((unsigned long)0xFFFFFFFF - sizeof(struct s1)) / sizeof(object)) - 1)
#else
#	define MAX_SEQ_LEN ((((unsigned long)0xFFFFFFFFFFFFFFFFLL - sizeof(struct s1)) / sizeof(object)) - 1)
#endif
#endif		                /* maximum sequence length set such that it doesn't overflow */
#define RESOLUTION 8            /* minimum size & increment before mapping */
#define LOG_RESOLUTION 3        /* log2 of RESOLUTION */
#define CACHE_LIMIT 2000        /* maximum number of cached allocations allowed. */

#ifdef EBSD
	#define MAX_CACHED_SIZE 0        /* don't use storage cache at all */
#else
	#define MAX_CACHED_SIZE 1024     /* this size (in bytes) or less are cached
									Note: other vars must change if this does */
#endif
#if defined(EALIGN4)
#undef ESIMPLE_MALLOC

#define MAGIC_FILLER ((int)0xFFFFFFF3)
								/* magic 4-byte value that should never appear
								   prior to a block pointer, unless we put it
								   there to align things on an 8-byte
								   boundary. */
#endif

/*
   The free_block structure overlays an allocated memory area that instead of
   being released back to the heap, is kept in a cache pool for quick allocation
*/
struct free_block {                /* a free storage block */
	struct free_block *next;       /* pointer to next free block */
};
typedef struct free_block *free_block_ptr;

struct block_list {
	int size;             /* size of blocks on this list */
	free_block_ptr first; /* pointer to first free block of this size
							 (or NULL if empty list) */
};
typedef struct block_list * block_list_ptr;

/*
	There are two types of pool caches, one for doubles (d_list) and one
	for all allocations that are no more than MAX_CACHED_SIZE bytes (pool_map).
	Allocations larger than that are not cached.

	The cache is a set of free-block lists (FBL). Each FBL contains a list
	of memory allocations that have been 'released' and are all of the same size.
	To make the algorithm simplier and to save overheads, the sizes for each FBL
	are organized in a semi-logarithmic manner.	The FBL sizes start at RESOLUTION
	bytes, the next two are in increments of (RESOLUTION * 2^1),  the next two
	are in increments of (RESOLUTION * 2^2),  the next two are in increments of
	(RESOLUTION * 2^3), etc until the MAX_CACHED_SIZE is reached.

	For example, given that RESOLUTION is 8 and MAX_CACHED_SIZE is 1024 then
	there will be 14 free-block lists, with their allocation sizes of
	{8,16,24,32,48,64,96,128,192,256,384,512,768,1024} respectively.

	When an allocation is requested, and there is not one of that size availble
	in the cache, the requested size is rounded up to the next FBL size before
	a new allocation is made from the heap. For example, if an allocation of 80
	bytes is requested, the actual allocation will be for 96 bytes. This is so
	that when the block is later released, it can be added to the appropriate
	FBL so that any future request for bytes from 65-96 can be serviced from it.

	The pool_map is an array of pointers where each element points to a free-block
	list. Its purpose is to speed up the algorithm that determines which FBL to
	use for a given requested allocation size. As each FBL size is a multiple of
	RESOLUTION, the pool_map contains elements for each multiple of RESOLUTION
	up to MAX_CACHED_SIZE, and each element contains the address of the FBL
	appropriate for that size. For example, using the given values above, the
	pool_map will contain ((1024 / 8) + 1)= 129 entries. And the pool_map will
	look like ...

	   Pool_map[]         --->   Free Block List
	   -------------------------------------
	      Index   byte-range    Index alloc-size
	      [0]       0            (not used)
	      [1]      1-8    --->   [0]  8
	      [2]      9-16   --->   [1]  16
	      [3]     17-24   --->   [2]  24
	      [4]     25-32   --->   [3]  32
	      [5]     33-40   --->   [4]  48
	      [6]     41-48   --->   [4]  48
	      [7]     49-56   --->   [5]  64
	      [8]     57-64   --->   [5]  64
	      [9]     65-72   --->   [6]  96
	      [10]    73-80   --->   [6]  96
	      [11]    81-88   --->   [6]  96
	      [12]    89-96   --->   [6]  96
          ...
	      [126] 1001-1008 --->  [13]  1024
	      [127] 1009-1016 --->  [13]  1024
	      [128] 1017-1024 --->  [13]  1024

	The algorithm to calculate the index for the pool_map is ...

	     floor((RequestedSize + RESOLUTION - 1) / RESOLUTION)

	This pool_map entry at this index contains the address of the FBL to use for
	the requested size.

	When releasing a block, the block becomes the new 'first' item in the FBL,
	and it gets updated to point to the previous 'first' block.

	When trying to allocate a memory block, the first block in the FBL is used,
	and if not null, the FBL is updated to point to the next 'released' block.

	The cache for doubles is simplier because all doubles have the same size.

	Note, all allocations are at least 8 bytes long and aligned on an 8-byte
	boundary.  We need this because the address of the block is stored in the
	lower 29-bits of an 'object' and so when getting the real address from an
	'object', we shift the object's value to the left by 3. This is the same as
	stripping off the higher 3 bits and multiplying by 8.

*/
#ifdef HEAP_CHECK
	#define FreeD(p) freeD(p)
	#define Trash(a,n) memset(a, (char)0x11, n)
#else
	extern d_ptr d_list;
	#define FreeD(p){ ((free_block_ptr)p)->next = (free_block_ptr)d_list; \
					  d_list = (d_ptr)p; \
					}
#endif

// Size of the usable space in an allocated block
#ifdef EUNIX
	#ifdef EBSD
		#define block_size(p) 1    // length is not stored with the block
	#else
		#define block_size(p) (malloc_usable_size(p))
	#endif

#else
	#ifdef EWINDOWS
		#define block_size(p) HeapSize((void *)default_heap, 0, p)
	#else
		#define block_size(p) (_msize(p))
	#endif
#endif

#ifdef EUNIX
#include <stdlib.h>
#endif
#if defined( ESIMPLE_MALLOC )

	#define EFree(ptr) free(ptr)
#else
	extern void EFree(char *ptr);
#endif
extern char *EMalloc(uintptr_t size);
extern char *ERealloc(char *orig, uintptr_t newsize);
#if defined(__GNU_LIBRARY__) || defined(__GLIBC__) \
	|| (defined(__DJGPP__) && __DJGPP__ <= 2 && __DJGPP_MINOR__ < 4)
size_t strlcpy(char *dest, char *src, size_t maxlen);
size_t strlcat(char *dest, char *src, size_t maxlen);
#endif

#ifdef EBSD
char *malloc_options;
#endif

extern long pagesize;  // needed for Linux only, not FreeBSD

extern int eu_dll_exists; // a Euphoria .dll is being used
extern int low_on_space;  // are we almost out of memory?
extern symtab_ptr call_back_arg1, call_back_arg2, call_back_arg3, call_back_arg4,
 		   call_back_arg5, call_back_arg6, call_back_arg7, call_back_arg8,
 		   call_back_arg9, call_back_result;

#ifdef EXTRA_STATS
extern unsigned recycles;          /* calls to Recycle() */
extern long a_miss;                /* cache list was empty */
extern long a_hit;                 /* found in cache */
extern long a_too_big;             /* too big - no caching */
extern long funny_expand;          /* _expand returns new pointer */
extern long funny_align;           /* number mallocs not 8-aligned */
#endif

#ifdef HEAP_CHECK
extern unsigned long bytes_allocated;       /* current number of object blocks alloc'd */
extern unsigned long max_bytes_allocated;   /* high water mark */
#endif

extern void InitEMalloc();
extern object NewSequence(char *data, int len);
extern object NewString(char *s);
extern s1_ptr NewS1(intptr_t size);
extern s1_ptr SequenceCopy(register s1_ptr a);
extern object NewDouble(eudouble d);
extern object NewPreallocSeq(intptr_t size, s1_ptr s1);
extern long copy_string(char *dest, char *src, size_t bufflen);
extern long append_string(char *dest, char *src, size_t bufflen);

extern void SpaceMessage()
#if defined(EUNIX) || defined(EMINGW)
__attribute__ ((noreturn))
#else
#pragma aux SpaceMessage aborts;
#endif
;
#endif
