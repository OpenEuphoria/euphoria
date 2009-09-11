#define ALIGN_SIZE 8
#define BASE_ALIGN_SIZE 16
#if defined( ESIMPLE_MALLOC )
#	define EMalloc(size) malloc_aligned(size,16)
#	define ERealloc(orig,newsize) realloc_aligned(orig,newsize,16)
#	define free(ptr) free_aligned(ptr)
#endif
void sse2_variable_init();
extern object_ptr NOVALUE_128bit, ONES_128bit, ZEROS_128bit;
extern object_ptr MAXINT_128bit, MININT_128bit;
extern object_ptr overunder_128bit, integer_128bit, intermediate_128bit; 
extern signed long iterate_over_double_words;
#ifdef EWATCOM
void emms();
#pragma aux emms = \
	"EMMS";
#else
	SSE2 instructions not defined for this compiler
#endif
