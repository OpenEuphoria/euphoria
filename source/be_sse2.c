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

inline int sse2_base_aligned_object(object s) {
	return (((unsigned long)SEQ_PTR(s)->base) % 16 == 12);
} 

inline int sse2_base_aligned_s1ptr(struct s1 * s) {
	return ((unsigned long)(s->base) % 16 == 12);
} 
inline int sse2_aligned_s1ptr(struct s1 * s) {
	return ((unsigned long)(s->base) % 16 == 12);
} 

void emms();
#pragma aux emms = \
	"emms";

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
	modify [ebx]\
	parm [EDX] [EAX] [ECX]\
	value [ebx];

unsigned long sse2_cmpi3( object_ptr dest, object_ptr ptr1, object_ptr ptr2 );
#pragma aux sse2_cmpi3 = \
	"movdqa xmm0, [eax]"\
	"movdqa xmm2, xmm0"\
	"movdqa xmm1, [ebx]"\
	"movdqa xmm3, xmm1"\
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
	modify [ebx]\
	parm [edx] [eax] [ebx]\
	value [ebx];

	/* dest = (eax[0..3] == ebx[0..3]) */
	/* After the op. dest[i] is -1 if eax[i] == ebx[i] and 0 otherwise for i = 0..3*/
unsigned long sse2_eqi3( object_ptr dest, object_ptr eax, object_ptr ebx );
#pragma aux sse2_eqi3 = \
	"movdqa xmm1, [eax]"\
	"pcmpeqd xmm1, [ebx]"  /*xmm1[] = xmm2[] --> xmm1[] = -1*/\
	/* write result to memory location */\
	"movdqa [edx], xmm1"\
	"xor edx, edx"\
	modify [edx]\
	parm [edx] [eax] [ebx]\
	value [edx];

/* Sets all i=0..3 vector_ptr[i] to value. */
/* Warning up tested code! */
void sse2_set( object_ptr vector_ptr, object value );
#pragma aux memset4 = \
	"mov ecx,4"\
	"rep stosd"\
	parm [edi] [eax];


double* cvtsi2sd(double * dp, object i);
#pragma aux cvtsi2sd = \
	"cvtsi2sd xmm0, ebx"\
	"movsd [eax], xmm0"\
	parm [eax] [ebx]\
	value [eax];

/* careful.  This modifies *dp.. */
double* saddDi(double * dp, object i);
#pragma aux saddDi = \
	"cvtsi2sd xmm0, ebx"\
	"movsd xmm1, [eax]"\
	"addsd xmm0, xmm1"\
	"movsd [eax], xmm0"\
	parm [eax] [ebx]\
	value [eax];


double * saddDD(double * da, double * db);
#pragma aux saddDD = \
	"movsd xmm0, [ebx]"\
	"movsd xmm1, [eax]"\
	"addsd xmm0, xmm1"\
	"movsd [eax], xmm0"\
	parm [eax] [ebx]\
	value [eax];

/* Compares 'dest' to 'b'.  Returns a fatal error if the differ.
 *
 * We use this to compare the result of our sse2 functions using the standard (plain C)
 * compare function to the output of standard function.   This only happens when
 * EXTRA_CHECK is turned on.  Don't benchmark with EXTRA_CHECK ! */
#ifdef EXTRA_CHECK
#define compare_check(dest,b) 	if (compare(MAKE_SEQ(dest),controlobj = b)) {\
		\
		/* failure!  Now, this part will find where in the sequence we went wrong.\
		 * */\
		int j;\
		control = SEQ_PTR(controlobj);\
		for (j=1;j<=dest->length;++j) {\
			if (dest->base[j] != control->base[j] &&\
				(  (IS_ATOM_INT(dest->base[j]) && IS_ATOM_INT(control->base[j])) ||\
					compare(dest->base[j],control->base[j])   )  )\
				break;\
		}\
		RTFatal("SSE code discrepancy:"\
			"results not consistent with old version. Index %d\n", j);\
	} else {\
		DeRefDS(controlobj);\
	} 0
#else
#define compare_check(dest,b) 0
#endif

/* Returns true if s->base[1] is aligned appropriately for our macros and functions
 * we have defined here. */
inline static int sse2_aligned(struct s1 * s) {
	return ((unsigned long)s->base) % 16 == 12;
}



// adds a sequence (and it should contain mostly integers), 'a', to the integer
// atom top. 
// Always allocates a new sequence
object paddsi(object a, object top) {
	struct s1 * dest;
	struct s1 * sa;
	double td;
	int sb;
	int k, length;
	object_ptr dp,ap;
	int OBJECTS_IN_VREG = sizeof(vreg)/sizeof(object);
	#ifdef EXTRA_CHECK
		struct s1 * control;
		object controlobj;
		signed long int j;
	#endif
	unsigned long which_int_a;
	sa = SEQ_PTR(a);
	sb = INT_VAL(top);
	memset4(vreg_temp,sb);
	dest = NewS1(sa->length);
	ap = &sa->base[1];
	dp = &dest->base[1];
	k = 0;
	iterate_over_double_words = 0;
	length = sa->length;
	while (k < length) {
		which_int_a = sse2_are_all_atom_ints(ap);
		if ( which_int_a == (unsigned int)-1 ) {
			unsigned char overflows[4];
			unsigned long iof;
			if (iof = sse2_paddi3( dp, ap, vreg_temp )) {
				unsigned char * ofptr;
				*(unsigned long*)(overflows) = iof;
				ofptr = &overflows[0];
				do {
					if (*(ofptr++)) {
						*dp = NewDouble(*cvtsi2sd(&td,*dp));
					}
					++dp;
				} while (++k%4);
			} else {
				dp += OBJECTS_IN_VREG;
				k  += OBJECTS_IN_VREG;
			}
			ap += OBJECTS_IN_VREG;
		} else {
			do {
				if (((char*)&which_int_a)[k%4]) { // is atom_int(*ap)?
					*dp = INT_VAL(*ap) + sb;
					if (INT_VAL(*dp) + HIGH_BITS >= 0) {
						*dp = NewDouble(*cvtsi2sd(&td,*dp));
					}
				} else if (*ap == NOVALUE) {
					*dp = *ap;
					break;
				} else if (IS_ATOM(*ap)) {
					td = DBL_PTR(*ap)->dbl;
					*dp = NewDouble(*saddDi(&td,sb));
				} else if (sse2_aligned(SEQ_PTR(*ap))) {
					*dp = paddsi(*ap,sb);
				} else {
					emms();
					*dp = binary_op(PLUS,*ap,sb);
				}
				++ap, ++dp, ++k;
			} while (k % 4);
		} // else 
	} // while
	compare_check(dest,binary_op(PLUS,a,top));
	return top = MAKE_SEQ(dest);
}

// adds an integer, 'a', to a sequence, 'top', and returns the result.
// Always allocates a new sequence
object paddis(object a, object top) {
	return paddsi(top,a);
}

// adds a sequence, 'a', to a sequence, 'top', and returns the result.
// Always allocates a new sequence
object padds2(object a, object top) {
	struct s1 * dest;
	struct s1 * sa, * sb;
	int k, length;
	object_ptr dp,ap,bp, tempb;
    #ifdef EXTRA_CHECK
		struct s1 * control;
		object controlobj;
		signed long int j;
	#endif
	unsigned long which_int_a, which_int_b;
	int OBJECTS_IN_VREG = sizeof(vreg)/sizeof(object);
	double td;
	sa = SEQ_PTR(a);
	sb = SEQ_PTR(top);
	if (sa->length != sb->length) {
		RTFatal(
		"Sequences are of differing lengths can not be added together.");
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
						*dp = NewDouble(*cvtsi2sd(&td,*dp));
					}
					++dp;
				} while (++k%4);
			} else {
				dp += OBJECTS_IN_VREG;
				k  += OBJECTS_IN_VREG;
			}
			ap += OBJECTS_IN_VREG;
			bp += OBJECTS_IN_VREG;
		} else {
			do {
				if (((char*)&which_int_a)[k%4]) { // is atom_int(*ap)?
					if (IS_ATOM_INT(*bp)) {
						*dp = INT_VAL(*ap) + INT_VAL(*bp);
						if (*dp > MAXINT || *dp < MININT) {
							*dp = NewDouble(*cvtsi2sd(&td,*dp));
						}				
					} else if (IS_ATOM(*bp)) {
						(td = DBL_PTR(*bp)->dbl);
						*dp = NewDouble(*saddDi(&td,INT_VAL(*ap)));
					} else {
						emms();
						*dp = binary_op(PLUS,*ap,*bp);
					}
				} else if (*ap == NOVALUE) {
					*dp = *ap;
					break;	
				} else if (IS_ATOM(*ap)) {
					if (IS_ATOM_INT(*bp)) {
						td = DBL_PTR(*ap)->dbl;
						*dp = NewDouble(*saddDi(&td, INT_VAL(*bp)));
					} else if (IS_ATOM(*bp)) {
						td = DBL_PTR(*ap)->dbl;
						*dp = NewDouble(*saddDD(&td, &DBL_PTR(*bp)->dbl));
					} else {
						emms();
						*dp = binary_op(PLUS,*ap,*bp);
					}
				} else {
					if (IS_SEQUENCE(*bp) && (((unsigned int)SEQ_PTR(*bp)->base) % 16 == 12)
						&& (((unsigned int)SEQ_PTR(*ap)->base) % 16 == 12)) 
							*dp = padds2(*ap,*bp);
					else {
								emms();
								*dp = binary_op(PLUS,*ap,*bp);
					}
				}
				++ap, ++bp, ++dp, ++k;
			} while (k % 4);
		} // else 
	} // while
	dest->base[length+1] = NOVALUE;
	compare_check(dest,binary_op(PLUS,a,top));
	return MAKE_SEQ(dest);
}



#if UNTESTED_FUNCTIONS
// Implementation Note: This is untested code that doesn't yet compile.
// Inspect, inspect, inspect
// Test test test

typedef unsigned long (*packedop_fn_t)(object_ptr destination, object_ptr p1, object_ptr p2);

struct function_row {
	object (*int_fn)(object a, object b);
	object (*dbl_fn)(d_ptr a, d_ptr b);
	packedop_fn_t packedop3;
};

extern object less(object, object);
extern object Dless(d_ptr, d_ptr);
extern object greatereq(object, object);
extern object Dgreatereq(d_ptr, d_ptr);
extern object add(object, object);
extern object Dadd(d_ptr, d_ptr);


// Note: apparently things defined with pragma aux are macros,
// we could rewrite pOpa2 as a macro...  
// If we do we can have one for where we need to check for overflow
// and another where we don't.  Then we only concentrate on working with
// the int[4] vectors.
struct function_row sse_op_table[12] = {
	{ NULL, NULL, NULL },
	{ less, Dless, NULL },
	{ greatereq, Dgreatereq, NULL },
	{NULL, NULL, NULL}, //{ equals, Dequals, NULL },
	{NULL, NULL, NULL}, // { noteq, Dnoteq, NULL },
	{NULL, NULL, NULL},//{ lesseq, Dlesseq, NULL },
	{NULL, NULL, NULL},//{ not, Dnot, NULL },
	{NULL, NULL, NULL},//{ and, Dand, NULL },
	{NULL, NULL, NULL},//{ or, Dor, NULL },
	{NULL, NULL, NULL},//{minus, Dminus, NULL},
	{add, Dadd, sse2_paddi3 }
};

// performs OP on a with top.  The caller must handle the INT,INT case.
// At least one should be a sequence.  Yet, the other can be object,
// an atom integer, an atom double or another sequence.
object_ptr pOPa2(int op, object a, object top) {
	struct s1 * dest;
	struct s1 * sa, * sb;
	long  k;
	short stepa, stepb;
	long length;
	object_ptr dp,ap,bp, tempb;
	struct s1 * control;
	object controlobj;
	d_ptr dbltemp_ptr;
	signed long int j;
	unsigned long which_int_a, which_int_b;
	length = -1;
#define setup_object_or_bail(sc,c,stepc,cp) \
	if (stepc = IS_SEQUENCE(c)) { \
		stepc = sizeof(vreg)/sizeof(object);\
		sc = SEQ_PTR(c);\
		if (!sse2_aligned(sc)) {\
			return binary_op(op,c,top);\
		} \
		length = sc->length;\
		cp = sc->base;\
		++cp;\
	} else {\
		sc = NULL;\
		stepc = 0;\
		sse2_set(vreg_temp, c);\
		cp = vreg_temp;\
	} 0
	// setup all objects
	setup_object_or_bail(sa,a,stepa,ap);
	setup_object_or_bail(sb,top,stepb,bp);
	if (length >= 0 && sa->length != sb->length) {
		RTFatal(
		"Sequences are of differing lengths can not be added together.");
	} else if (length == -1) {
		RTFatal("No sequences supplied.");
	}
	// Now, at least one is a sequence and all sequences are sse aligned.
	dest = NewS1(length);
	dest->base[length] = NOVALUE;
	dp = &dest->base[1];
	k = 0;
	
	while (k < length) {
		which_int_a = sse2_are_all_atom_ints(ap);
		if ( which_int_a == (unsigned int)-1 && 
			((which_int_b = sse2_are_all_atom_ints(bp)) == (unsigned int)-1) ) {
			unsigned char overflows[4];
			unsigned long iof;
			if (iof = (sse_op_table[op]).packedop3( dp, ap, bp )) {
				unsigned char * ofptr;
				*(unsigned long*)(overflows) = iof;
				ofptr = &overflows[0];
				if (*(ofptr++)) {
					*dp = NewDouble(*dp);
				}
				++dp;
				if (*(ofptr++)) {
					*dp = NewDouble(*dp);
				}
				++dp;
				if (*(ofptr++)) {
					*dp = NewDouble(*dp);
				}
				++dp;
				if (*(ofptr++)) {
					*dp = NewDouble(*dp);
				}
				++dp;
			} else {
				dp += sizeof(vreg)/sizeof(object);
				k  += sizeof(vreg)/sizeof(object);
			}
			ap += stepa;
			bp += stepb;
		} else {
			do {
				if (((char*)&which_int_a)[k%4]) { // is atom_int(*ap)?
					if (IS_ATOM_INT(*bp)) {
						*dp = (sse_op_table[op].int_fn)(INT_VAL(*ap),INT_VAL(*bp));
						if (*dp > MAXINT || *dp < MININT) {
							*dp = NewDouble(*dp);
						}	
					} else if (IS_ATOM(*bp)) {
						*dp = (sse_op_table[op].dbl_fn)(DBL_PTR(NewDouble((double)INT_VAL(*ap))),DBL_PTR(*bp));
					} else {
						*dp = pOPa2(op,*ap,*bp);
					}
				} else if (*ap == NOVALUE) {
					*dp = *ap;
					break;
				} else if (IS_ATOM(*ap)) {
					if (IS_ATOM_INT(*bp))
						*dp = (sse_op_table[op].dbl_fn)(DBL_PTR(*ap),DBL_PTR(NewDouble(INT_VAL(*bp))));
					else if (IS_ATOM(*bp))
						*dp = (*sse_op_table[op].dbl_fn)(DBL_PTR(*ap),DBL_PTR(*bp));
					else
						*dp = pOPa2(op,*ap,*bp);
				} else {
					if (IS_SEQUENCE(*bp) && (((unsigned int)SEQ_PTR(*bp)->base) % 16 == 12)
						&& (((unsigned int)SEQ_PTR(*ap)->base) % 16 == 12)) 
							*dp = pOPa2(op,*ap,*bp);
					else
							*dp = binary_op(op,*ap,*bp);
				}
				++ap, ++bp, ++dp, ++k;
			} while (k % 4);
		} // else 
	} // while
	dest->base[length+1] = NOVALUE;
	compare_check(dest,binary_op(op,a,top));
	return top = MAKE_SEQ(dest);
}
#endif
