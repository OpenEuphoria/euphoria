#include <conio.h>
#include <malloc.h>
#include "execute.h"
typedef int symtab_ptr;
#include "alloc.h"
#include "sse2.h"
object_ptr NOVALUE_128bit, ONES_128bit, ZEROS_128bit;
object_ptr MAXINT_128bit, MININT_128bit;
object_ptr overunder_128bit, integer_128bit, intermediate_128bit; 
signed long iterate_over_double_words;
object sse_data[8*4+BASE_ALIGN_SIZE/sizeof(object)];

struct mem_list {
	struct mem_list * next;
	void * inptr;
	void * outptr;
} * mem_list;

void sse2_variable_init() {
	int j, i = 0;
	
	while (((unsigned int)&sse_data[i]) % BASE_ALIGN_SIZE != 0)
		++i;
#	define VSET( VN, VV )	do {VN = &sse_data[i];\
	for (j = 0; j < 4; ++j ) sse_data[i++] = VV;} while (0)
	
	VSET(NOVALUE_128bit, NOVALUE);
	VSET(ONES_128bit, 0xffffffff);
	VSET(ZEROS_128bit, 0);
	VSET(MAXINT_128bit, MAXINT);
	VSET(MININT_128bit, MININT);
	VSET(overunder_128bit, 0);
	VSET(integer_128bit, 0);
	VSET(intermediate_128bit, 0);
	mem_list = NULL;
#	undef VSET
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



