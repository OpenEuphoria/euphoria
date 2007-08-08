/*****************************************************************************/
/*                                                                           */
/*                        STORAGE ALLOCATION MACROS                          */
/*                                                                           */
/*****************************************************************************/
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
#if defined(ELINUX) || defined(ESIMPLE_MALLOC)
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
#ifdef ELINUX 
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

#ifdef ESIMPLE_MALLOC
#define EMalloc(size) malloc(size)
#define EFree(ptr) free(ptr)
#define ERealloc(orig, newsize) realloc(orig, newsize)
#endif
