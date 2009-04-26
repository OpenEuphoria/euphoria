/*****************************************************************************/
/*                                                                           */
/*                        STORAGE ALLOCATION MACROS                          */
/*                                                                           */
/*****************************************************************************/
#ifndef _ALLOC_H_
#define _ALLOC_H_ 1
#define RESOLUTION 8            /* minimum size & increment before mapping */
#define LOG_RESOLUTION 3        /* log2 of RESOLUTION */
#define CACHE_LIMIT 2000        /* desired maximum size of storage cache. */
								/* doubles are 1, others are 2            */ 

#define MAGIC_FILLER ((int)0xFFFFFFF3) 
								/* magic 4-byte value that should never appear
								   prior to a block pointer, unless we put it 
								   there to align things on an 8-byte 
								   boundary. */
struct block_list {
	int size;             /* size of blocks on this list */
	free_block_ptr first; /* pointer to first free block of this size 
							 (or NULL if empty list) */
};

#ifdef HEAP_CHECK 
#define FreeD(p) freeD(p)
#else
#if defined(EUNIX) || defined(ESIMPLE_MALLOC)
#define FreeD(p) free(p);
#else
#define FreeD(p){ if (eu_dll_exists && cache_size > CACHE_LIMIT) { \
					  if (align4 && *(int *)((char *)p-4) == MAGIC_FILLER) \
						  free((char *)p-4); \
					  else \
						  free((char *)p); \
				  } \
				  else { \
					  ((free_block_ptr)p)->next = (free_block_ptr)d_list; \
					  d_list = (d_ptr)p; \
					  cache_size += 1; } \
				  }
#endif
#endif

// Size of the usable space in an allocated block
#ifdef EUNIX 
#ifdef EBSD
#define block_size(p) 1    // length is not stored with the block
#else
#define block_size(p) (malloc_usable_size(p))
#endif

#else
#ifdef EDJGPP
#define block_size(p) (((*(unsigned long *)((char *)(p) - 4)) & ~3))
#else
#ifdef EWINDOWS
#define block_size(p) HeapSize((void *)default_heap, 0, p)
#else
#define block_size(p) (_msize(p))
#endif
#endif
#endif

#if defined( ESIMPLE_MALLOC )
#define EMalloc(size) malloc(size)
#define EFree(ptr) free(ptr)
#define ERealloc(orig, newsize) realloc(orig, newsize)
#endif

#if defined(ELINUX) || defined(EMINGW) || (defined(__DJGPP__) && __DJGPP__ <= 2 && __DJGPP_MINOR__ < 4)
extern size_t strlcpy(char *dest, char *src, size_t maxlen);
extern size_t strlcat(char *dest, char *src, size_t maxlen);
#endif

#ifdef EBSD
extern char *malloc_options="A"; // abort
#endif

#ifdef EUNIX
extern int pagesize;  // needed for Linux only, not FreeBSD
#endif

extern int eu_dll_exists; // a Euphoria .dll is being used
extern int align4;
extern int low_on_space;  // are we almost out of memory?
extern unsigned cache_size;
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
extern long bytes_allocated;       /* current number of object blocks alloc'd */
extern long max_bytes_allocated;   /* high water mark */
#endif

extern s1_ptr d_list;
extern struct block_list *pool_map[MAX_CACHED_SIZE/RESOLUTION+1]; /* maps size desired 
                                                                     to appropriate list */

#endif
