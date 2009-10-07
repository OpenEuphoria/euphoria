#include <conio.h>
#include <malloc.h>
#include "execute.h"
#include "reswords.h"
typedef int symtab_ptr;
#include "alloc.h"
#include "sse2.h"
/* the following are pointers to 4 element arrays of their
 non-vector counter parts.
 For example:
 NOVALUE_128bit[0..3] = { NOVALUE, NOVALUE, NOVALUE, NOVALUE }
 */
object_ptr NOVALUE_128bit, MINUSONES_128bit, ZEROS_128bit;
object_ptr MAXINT_128bit, MININT_128bit;
object_ptr overunder_128bit, integer_128bit, intermediate_128bit;
/* variable for temporary storage */
object_ptr vreg_temp, vregs_temp;
signed long iterate_over_double_words;
object_ptr sse_data;

struct mem_list {
	struct mem_list * next;
	void * inptr;
	void * outptr;
} * mem_list;

/* The following routine initializes the object_ptr values above to point to vectors of objects
 sizeof(vreg)/sizeof(object) elements long each.  All aligned on a BASE_ALIGN_SIZE boundary.
 
 Assumption: sizeof(vreg)=16 and BASE_ALIGN_SIZE is a multiple of sizeof(object).*/  
void sse2_variable_init() { 
	int j, i = 0;
	
	sse_data = (object_ptr)malloc(9*sizeof(vreg)+BASE_ALIGN_SIZE+512);
	while (((unsigned int)&sse_data[i]) % BASE_ALIGN_SIZE != 0)
		++i;
#	define VSET( VN, VV )	do {VN = &sse_data[i];\
	for (j = 0; j < sizeof(vreg)/sizeof(object); ++j ) sse_data[i++] = VV;} while (0)

	VSET(NOVALUE_128bit,NOVALUE);
	VSET(MINUSONES_128bit, 0xffffffff);
	VSET(ZEROS_128bit, 0);
	VSET(MAXINT_128bit, MAXINT);
	VSET(MININT_128bit, MININT);
	VSET(overunder_128bit, 0);
	VSET(integer_128bit, 0);
	VSET(intermediate_128bit, 0);
	VSET(vreg_temp,0);
	VSET(vregs_temp,0);
	i+=512-16;
	
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



void load_vector_registers();
#pragma aux load_vector_registers = \
	"mov ebx, vregs_temp"\
	"movdqa xmm0, [ebx]"\
	"add ebx, 16"\
	"movdqa xmm1, [ebx]"\
	"add ebx, 16"\
	"movdqa xmm2, [ebx]"\
	"add ebx, 16"\
	"movdqa xmm3, [ebx]"\
	"add ebx, 16"\
	"movdqa xmm4, [ebx]"\
	"add ebx, 16"\
	"movdqa xmm5, [ebx]"\
	"add ebx, 16"\
	"movdqa xmm6, [ebx]"\
	"add ebx, 16"\
	"movdqa xmm7, [ebx]"\
	modify [ebx];

/* routine saves the mmx register values intoa variable */
void save_vector_registers();
#pragma aux save_vector_registers = \
	"mov ebx, vregs_temp"\
	"movdqa [ebx], xmm0"\
	"add ebx, 16"\
	"movdqa [ebx], xmm1"\
	"add ebx, 16"\
	"movdqa [ebx], xmm2"\
	"add ebx, 16"\
	"movdqa [ebx], xmm3"\
	"add ebx, 16"\
	"movdqa [ebx], xmm4"\
	"add ebx, 16"\
	"movdqa [ebx], xmm5"\
	"add ebx, 16"\
	"movdqa [ebx], xmm6"\
	"add ebx, 16"\
	"movdqa [ebx], xmm7"\
	modify [ebx];


/* The following operates on two 4-element arrays of objects and places the result in the array 
   pointed to by dest.  Repective elements of ptr1[i], and ptr2[i] both are ATOM_INT() type, they are 
   added and the sum is stored into dest[i].  If there is overflow overunder_128bit[i] is set to a
   non-zero number.  If either of the elements ptr1[i] or ptr2[i] are not integers the 
   integer_128bit[i] variable is set to a non-zero number.  If all four elements were added without
   overflow and were all integers then and only then will iterate_over_double_words be false.
   
	NB: can't move a variable value directly to MMX */
	unsigned long sse2_paddo3( object_ptr dest, object_ptr ptr1, object_ptr ptr2);
	#pragma aux sse2_paddo3 = \
		/* edx = dest, eax = ptr1, ecx = ptr2 */\
 		"movdqa xmm1, [eax]"\
		"MOVDQA XMM2, XMM1"\
		"MOVDQA XMM4, [ECX]"\
		"MOVDQA XMM5, XMM4"\
		"movdqa xmm6, xmm5"\
		"mov ebx, NOVALUE_128bit"\
		"movdqa xmm7, [ebx]"\
		"pcmpgtd xmm2, xmm7"\
		/*XMM2 = ((signed)ptr1[0..3] > (signed)NOVALUE_128bit[0..3])*/\
		/*XMM2[i] = -1 where ptr1[i] is an atom integer  */\ 	
		"pcmpgtd xmm6, xmm7"\
		/* XMM6 = (ptr2[0..3] > NOVALUE_128bit[0..3])*/\
		/* XMM6[i] = -1 where ptr2[i] is an atom integer*/\
		"andps xmm2, xmm6"\
		"mov ebx, integer_128bit"\
		"movdqa [ebx], xmm2"\
		"paddd xmm1, xmm5"\
		"andps xmm1, xmm2"\
		"movdqa [edx], xmm1"\
		"mov ebx, MININT_128bit"\
		"movdqa xmm6, [ebx]"\
		/* xmm6 = MININT, XMM2 is our int mask, XMM0 and XMM4 are *ptr1 and *ptr2 repectively.*/\
		/* xmm1 is the sum.*/\
		"movdqa xmm3, xmm1"\
		"pcmpgtd xmm6, xmm1"\
		"mov ebx, MAXINT_128bit"\
		"movdqa xmm5, [ebx]"\
		"pcmpgtd xmm3, xmm5"\
		"orps xmm6, xmm3"\
		"mov ebx, overunder_128bit"\
		"movdqa [ebx], xmm6"\
		/* Here xmm1, xmm4 are *ptr[12], xmm2 is our int mask, xmm6 is our over under mask */\
		"mov ebx, MINUSONES_128bit"\
		"andnps xmm2, [ebx]"\
		/* Here xmm2 is our negated int mask */\
		"orps xmm6, xmm2"\
		/* Here xmm6 is a mask that if it is true it needs to be handled in a DQ word loop 	*/\
		"PACKSSDW XMM6, XMM6"\
		"PACKSSWB XMM6, XMM6"\
		"MOVD iterate_over_double_words, XMM6"\
		"MOV ebx, iterate_over_double_words"\
		"EMMS"\
		modify [EBX]\
		parm [EDX] [EAX] [ECX]\
		value [EBX];


object * paddo3(object a, object top) {
	struct s1 * dest;
	struct s1 * sa, * sb;
	int k, length;
	object_ptr dp,ap,bp, tempb;
	struct s1 * control;
	object controlobj;
	signed long int * ou;
	signed long int * in;
	signed long int j;
	sa = SEQ_PTR(a);
	sb = SEQ_PTR(top);
	if (sa->length != sb->length) {
		RTFatal(
		"Sequences are of differing lenghts can not be added together.");
	}
	tempb = vreg_temp;	
	dest = NewS1(sa->length);
	dest->base[sa->length+1] = NOVALUE;
	top = MAKE_SEQ(dest);
	ap = &sa->base[1];
	bp = &sb->base[1];
	dp = &dest->base[1];
	k = 0;
	iterate_over_double_words = 0;
	length = sa->length  & -(sizeof(vreg)/sizeof(object));
	while (k < length) {
		sse2_paddo3( dp, ap, bp );
		if (iterate_over_double_words) {
				for (j = 0;	j < sizeof(vreg)/sizeof(object);
					++j ) {
						if (overunder_128bit[j] != 0) {
								dp[j] = NewDouble((double)INT_VAL(dp[j]));
						}	else								
						if (!integer_128bit[j]) {
								dp[j] = binary_op(PLUS, ap[j], bp[j] );
						}
				}
		}
		ap += sizeof(vreg)/sizeof(object);
		bp += sizeof(vreg)/sizeof(object);
		dp += sizeof(vreg)/sizeof(object);
		k  += sizeof(vreg)/sizeof(object);
	} // while
	sse2_paddo3(tempb, ap, bp );
	length = dest->length = sa->length;
	dest->base[sa->length+1] = NOVALUE;
	for (++k,j = 0; k <= length; ++k,++j ) {
			if (overunder_128bit[j]) 
				dest->base[k] = NewDouble( tempb[j] );
			else if (integer_128bit[j])
				dest->base[k] = tempb[j];
			else
				dest->base[k] = binary_op(PLUS, sa->base[k], sb->base[k]);
	}
#   ifdef EXTRA_CHECK					
		if (compare(MAKE_SEQ(dest),controlobj = binary_op(PLUS,a,top))) {
			int j;
			control = SEQ_PTR(controlobj);
			for (j=1;j<=dest->length;++j)
				if (dest->base[j] != control->base[j] && 
					compare(dest->base[j],control->base[j]))
					break;
			RTFatal("SSE code discrepancy:"
				"results not consistent with old version. Index %d\n", j);																
		}
#	endif
	return top;
}

