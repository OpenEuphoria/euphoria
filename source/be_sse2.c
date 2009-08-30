#include <conio.h>
#include <malloc.h>
#include "execute.h"
typedef int symtab_ptr;
#include "alloc.h"
#include "sse2.h"
struct _128b_uint_st NOVALUE_128bit;
struct _128b_uint_st ONES_128bit;
struct _128b_uint_st ZEROS_128bit;
struct _128b_uint_st MAXINT_128bit;
struct _128b_uint_st MININT_128bit;
struct _128b_uint_st overunder_128bit;
struct _128b_uint_st integer_128bit, intermediate_128bit;
unsigned long iterate_over_double_words;

struct mem_list {
	struct mem_list * next;
	void * inptr;
	void * outptr;
} * mem_list;

void sse2_variable_init() {
	NOVALUE_128bit.low = NOVALUE;
	NOVALUE_128bit.lowmid = NOVALUE;
	NOVALUE_128bit.highmid = NOVALUE;
	NOVALUE_128bit.high = NOVALUE;
	ONES_128bit.low = 0xffffffff;
	ONES_128bit.lowmid = 0xffffffff;
	ONES_128bit.highmid = 0xffffffff;
	ONES_128bit.high = 0xffffffff;
	ZEROS_128bit.low = 0;
	ZEROS_128bit.lowmid = 0;
	ZEROS_128bit.highmid = 0;
	ZEROS_128bit.high = 0;
	MAXINT_128bit.low = MAXINT;
	MAXINT_128bit.lowmid = MAXINT;
	MAXINT_128bit.highmid = MAXINT;
	MAXINT_128bit.high = MAXINT;
	MININT_128bit.low = MININT;
	MININT_128bit.lowmid = MININT;
	MININT_128bit.highmid = MININT;
	MININT_128bit.high = MININT;
	mem_list = NULL;
}


void free_aligned(void * ptr) {
	struct mem_list * node, * temp;
	struct mem_list list;
	list.next = mem_list;
	for ( node = &list; node->next != NULL; node = node->next ) {
		if (node->next->outptr == ptr) {
			free( node->next->inptr );
			temp = node->next;
			node->next = node->next->next;
			free( temp );
			return;
		}
	}
	free( ptr );
}

void * malloc_aligned(unsigned long size, unsigned long alignment_size) {
	void * inptr, * outptr;
	struct mem_list * node;
	unsigned int remainder;
	inptr = malloc(size+alignment_size);
	remainder = (((unsigned int)inptr-1) % alignment_size)+1;
	/* remainder = 1..16 */
	node = (struct mem_list*)malloc(sizeof(struct mem_list));
		
	node->next = mem_list;
	node->inptr = inptr;
	node->outptr = (void*)(((char*)inptr)+alignment_size-remainder); 
	mem_list = node;
	
	return outptr;
}
