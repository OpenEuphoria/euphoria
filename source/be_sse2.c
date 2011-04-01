/* Make sure this is included in be_alloc.h */
#define NOVALUE ((long)0xbfffffffL)
#include <conio.h>
#include <malloc.h>
#include "execute.h"
#include "reswords.h"
#include "be_alloc.h"
//#include "..\include\euphoria.h"
/* the following are pointers to 4 element arrays of their
 non-vector counter parts.
 For example:
 NOVALUE_128bit[0..3] = { NOVALUE, NOVALUE, NOVALUE, NOVALUE }
 */
object_ptr NOVALUE_128bit, MINUSONES_128bit, ZEROS_128bit;
object_ptr MAXINT_128bit, MININT_128bit, ONES_128bit;
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
	
	sse_data = (object_ptr)malloc(10*sizeof(vreg)+BASE_ALIGN_SIZE+512);
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
	VSET(ONES_128bit, 1);
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

/* routine saves the mmx register values into a variable */
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

	/* Returns true iff the four sequential elements pointed to by ptr1 are all ATOM_INTs */
unsigned long sse2_are_all_atom_ints( object_ptr ptr1 );
#pragma aux sse2_are_all_atom_ints = \
	/* edx = dest, eax = ptr1, ecx = ptr2 */\
	"movdqa xmm1, [eax]"\
	"mov ebx, NOVALUE_128bit"\
	"movdqa xmm7, [ebx]"\
	"pcmpgtd xmm1, xmm7"\
	/*XMM2 = ((signed)ptr1[0..3] > (signed)NOVALUE_128bit[0..3])*/\
	/*XMM2[i] = -1 where ptr1[i] is an atom integer  */\ 	
	"PACKSSDW XMM1, XMM1"\
	"PACKSSWB XMM1, XMM1"\
	"MOVD ebx, XMM1"\
	"EMMS"\
	modify [EBX]\
	parm [EAX]\
	value [EBX];

/* Sum the eight integers pointed to by ptr1 and ptr2 as if they were ATOM_INTs.  
   The results is written to the location pointed to by dest.   Overflow and 
   underflow is packed into a 32 bit value and returned.  The returned value, once put into
   a variable can be accessed as a string of bytes, str.  For i=0..3, if str[i] 
   is non 0 then there is an overflow at dest[i].  */
unsigned long sse2_paddi3( object_ptr dest, object_ptr ptr1, object_ptr ptr2);
#pragma aux sse2_paddi3 = \
	/* edx = dest, eax = ptr1, ecx = ptr2 */\
	/* load and do operation */\
	"movdqa xmm1, [eax]"\
	"movdqa xmm5, [ecx]"\
	"paddd xmm1, xmm5"\
	/* write sum to memory location */\
	"movdqa [edx], xmm1"\
	/* check for overflow */\
	"mov eax, MAXINT_128bit"\
	"mov ecx, MININT_128bit"\
	"movdqa xmm2, xmm1"\
	"movdqa xmm3, [ecx]"\
	"pcmpgtd xmm3, xmm1"\
	"pcmpgtd xmm1, [eax]"\
	"orps xmm1, xmm3"\
	"packssdw xmm1, xmm1"\
	"packsswb xmm1, xmm1"\
	"movd ebx, xmm1"\
	"EMMS"\
	modify [ebx]\
	parm [EDX] [EAX] [ECX]\
	value [ebx];
	
/* The set of possible values for ATOM_INT form a group under: OR, AND, and XOR.
 In plain English, once we know the inputs are ATOM_INTs the results will also
 be ATOM_INTs */
	
 unsigned long sse2_pori3( object_ptr dest, object_ptr ptr1, object_ptr ptr2);
 #pragma aux sse2_pori3 = \
	/* edx = dest, eax = ptr1, ecx = ptr2 */\
	"movdqa xmm1, [eax]"\
	"por xmm1, [ecx]"\
	/* write result to memory location */\
	"movdqa [edx], xmm1"\
	"EMMS"\
	modify [ebx]\
	parm [EDX] [EAX] [ECX]\
	value [ebx];
 
 unsigned long sse2_pandi3( object_ptr dest, object_ptr ptr1, object_ptr ptr2);
 #pragma aux sse2_pori3 = \
	/* edx = dest, eax = ptr1, ecx = ptr2 */\
	"movdqa xmm1, [eax]"\
	"movdqa xmm5, [ecx]"\
	"pand xmm1, xmm5"\
	/* write result to memory location */\
	"movdqa [edx], xmm1"\
	"EMMS"\
	modify [ebx]\
	parm [EDX] [EAX] [ECX]\
	value [ebx];
	
unsigned long sse2_pxori3( object_ptr dest, object_ptr ptr1, object_ptr ptr2);
 #pragma aux sse2_pxori3 = \
	/* edx = dest, eax = ptr1, ecx = ptr2 */\
	"movdqa xmm1, [eax]"\
	"movdqa xmm5, [ecx]"\
	"pxor xmm1, xmm5"\
	/* write result to memory location */\
	"movdqa [edx], xmm1"\
	"EMMS"\
	modify [ebx]\
	parm [EDX] [EAX] [ECX]\
	value [ebx];
	
	
unsigned long sse2_psrli3( object_ptr dest, object_ptr ptr1, unsigned char bl);
 #pragma aux sse2_psrli3 = \
	/* edx = dest, eax = ptr1, ecx = shift value */\
	"movdqa xmm1, [eax]"\
	"psrld xmm1, bl"\
	/* write result to memory location */\
	"movdqa [edx], xmm1"\
	"mov eax, MAXINT_128bit"\
	"mov ecx, MININT_128bit"\
	"movdqa xmm2, xmm1"\
	"movdqa xmm3, [ecx]"\
	"pcmpgtd xmm3, xmm1"\
	"pcmpgtd xmm1, [eax]"\
	"orps xmm1, xmm3"\
	"packssdw xmm1, xmm1"\
	"packsswb xmm1, xmm1"\
	"movd ebx, xmm1"\
	"EMMS"\
	modify [ebx]\
	parm [EDX] [EAX] [BL]\
	value [ebx];

unsigned long sse2_psli3( object_ptr dest, object_ptr ptr1, object ecx);
 #pragma aux sse2_psli3 = \
	/* edx = dest, eax = ptr1, ecx = shift value */\
	"movdqa xmm1, [eax]"\
	"mov ebx, ecx"\
	"pslld xmm1, bl"\
	/* write result to memory location */\
	"movdqa [edx], xmm1"\
	"mov eax, MAXINT_128bit"\
	"mov ecx, MININT_128bit"\
	"movdqa xmm2, xmm1"\
	"movdqa xmm3, [ecx]"\
	"pcmpgtd xmm3, xmm1"\
	"pcmpgtd xmm1, [eax]"\
	"orps xmm1, xmm3"\
	"packssdw xmm1, xmm1"\
	"packsswb xmm1, xmm1"\
	"movd ebx, xmm1"\
	"EMMS"\
	modify [ebx]\
	parm [EDX] [EAX] [ECX]\
	value [ebx];

unsigned long sse2_cmpi3( object_ptr dest, object_ptr ptr1, object_ptr ptr2 );
#pragma aux sse2_cmpi3 = \
	"movdqa xmm0, [eax]"\
	"movdqa xmm2, [eax]"\
	"movdqa xmm1, [ebx]"\
	"movdqa xmm3, [ebx]"\
	"movdqa xmm4, [ONES_128bit]"\
	"pcmpgtd xmm3, xmm0" /*xmm0[] < xmm1[] --> xmm3[] = -1*/\
	"pcmpeqd xmm1, xmm2"  /*xmm1[] = xmm2[] --> xmm1[] = -1*/\
	"movdqa xmm5, xmm3"\
	"orps xmm5, xmm1"  /* <= --> -1, > --> 0. */\
	"addps xmm5, xmm4" /* <= --> 0, > --> 1 */\
	"orps xmm5, xmm3" /*  < --> -1, = --> 0, > --> 1 */\
	/* write result to memory location */\
	"movdqa [edx], xmm5"\
	"xor ebx, ebx"\
	"emms"\
	modify [ebx]\
	parm [edx] [eax] [ebx]\
	value [ebx];

	/* dest = (eax[0..3] == ebx[0..3]) */
	/* After the op. dest[i] is -1 if eax[i] == ebx[i] and 0 otherwise for i = 0..3*/
void sse2_eqi3( object_ptr dest, object_ptr eax, object_ptr ebx );
#pragma aux sse2_eqi3 = \
	"movdqa xmm1, [eax]"\
	"pcmpeqd xmm1, [ebx]"  /*xmm1[] = xmm2[] --> xmm1[] = -1*/\
	/* write result to memory location */\
	"movdqa [edx], xmm1"\
	"emms"\
	parm [edx] [eax] [ebx];


object_ptr padds2(object a, object top) {
	struct s1 * dest;
	struct s1 * sa, * sb;
	int k, length;
	object_ptr dp,ap,bp, tempb;
	struct s1 * control;
	object controlobj;
	signed long int * ou;
	signed long int * in;
	signed long int j;
	unsigned long which_int_a, which_int_b;
	sa = SEQ_PTR(a);
	sb = SEQ_PTR(top);
	if (sa->length != sb->length) {
		RTFatal(
		"Sequences are of differing lenghts can not be added together.");
	}
	tempb = vreg_temp;	
	dest = NewS1(sa->length);
	dest->base[sa->length+1] = NOVALUE;
	ap = &sa->base[1];
	bp = &sb->base[1];
	dp = &dest->base[1];
	k = 0;
	iterate_over_double_words = 0;
	length = sa->length;
	while (k < length) {
		which_int_a = sse2_are_all_atom_ints(ap);
		if ( which_int_a == (unsigned int)-1 && 
			((which_int_b = sse2_are_all_atom_ints(bp)) == (unsigned int)-1) ) {
			unsigned char overflows[4];
			unsigned long iof;
			if (iof = sse2_paddi3( dp, ap, bp )) {
				unsigned char * ofptr;
				*(unsigned long*)(overflows) = iof;
				ofptr = &overflows[0];
				do {
					if (*(ofptr++)) { 
						*dp = NewDouble(*dp);
					}
					++dp;
				} while (++k%4);
			} else {
				dp += sizeof(vreg)/sizeof(object);
				k  += sizeof(vreg)/sizeof(object);
			}
			ap += sizeof(vreg)/sizeof(object);
			bp += sizeof(vreg)/sizeof(object);
		} else {
			do {
				if (((char*)&which_int_a)[k%4]) { // is atom_int(*ap)?
					if (IS_ATOM_INT(*bp)) {
						*dp = INT_VAL(*ap) + INT_VAL(*bp);
						if (*dp > MAXINT || *dp < MININT) {
							*dp = NewDouble(*dp);
						}				
					} else if (IS_ATOM(*bp)) {
						*dp = NewDouble(INT_VAL(*ap) + DBL_PTR(*bp)->dbl);
					} else {
						*dp = binary_op(PLUS,*ap,*bp);
					}
				} else if (*ap == NOVALUE) {
					*dp = *ap;
					break;	
				} else if (IS_ATOM(*ap)) {
					if (IS_ATOM_INT(*bp))
						*dp = NewDouble(DBL_PTR(*ap)->dbl + INT_VAL(*bp));
					else if (IS_ATOM(*bp))
						*dp = NewDouble(DBL_PTR(*ap)->dbl + DBL_PTR(*bp)->dbl);
					else
						*dp = binary_op(PLUS,*ap,*bp);
				} else {
					if (IS_SEQUENCE(*bp) && (((unsigned int)SEQ_PTR(*bp)->base) % 16 == 12)
						&& (((unsigned int)SEQ_PTR(*ap)->base) % 16 == 12)) 
							*dp = padds2(*ap,*bp);
					else
							*dp = binary_op(PLUS,*ap,*bp);
				}
				++ap, ++bp, ++dp, ++k;
			} while (k % 4);
		} // else 
	} // while
	dest->base[length+1] = NOVALUE;
#   ifdef EXTRA_CHECK
	/* Use the old way to check the answer for SSE2.... makes this slower than
	 * the original implementation. */
		if (compare(MAKE_SEQ(dest),controlobj = binary_op(PLUS,a,top))) {
			
			/* failure!  Now, this part will find where in the sequence we went wrong.
			 * */
			int j;
			control = SEQ_PTR(controlobj);
			for (j=1;j<=dest->length;++j) {
				if (dest->base[j] != control->base[j] &&
					(  (IS_ATOM_INT(dest->base[j]) && IS_ATOM_INT(control->base[j])) ||
						compare(dest->base[j],control->base[j])   )  )
					break;
			}
			RTFatal("SSE code discrepancy:"
				"results not consistent with old version. Index %d\n", j);																
		} else {
			DeRefDS(controlobj);
		}
#	endif
	return top = MAKE_SEQ(dest);
}

