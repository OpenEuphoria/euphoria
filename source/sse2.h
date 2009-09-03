#define ALIGN_SIZE 8
#define BASE_ALIGN_SIZE 16
#if defined( ESIMPLE_MALLOC )
#	define EMalloc(size) malloc_aligned(size,16)
#	define ERealloc(orig,newsize) realloc_aligned(orig,newsize,16)
#	define free(ptr) free_aligned(ptr)
#endif
struct _128b_uint_st {
	unsigned int low;
	unsigned int lowmid;
	unsigned int highmid;
	unsigned int high;
};
void sse2_variable_init();
extern struct _128b_uint_st NOVALUE_128bit;
extern struct _128b_uint_st ONES_128bit;
extern struct _128b_uint_st ZEROS_128bit;
extern struct _128b_uint_st MAXINT_128bit;
extern struct _128b_uint_st MININT_128bit;
extern struct _128b_uint_st overunder_128bit;
extern struct _128b_uint_st integer_128bit, intermediate_128bit;
extern unsigned long iterate_over_double_words;
	void see2_load_registers(int * dest, object_ptr ptr1, object_ptr ptr2 );
	void sse2_padd_euphoria_values4(int * dest, int * ptr1, int * ptr2 );
#	ifdef EWATCOM	
#		if SSE2_ALIGNED
			#pragma aux sse2_load_registers = \
				"MOVAPS XMM0, [EAX]"\             
				"MOVAPS XMM4, [ECX]"\
				parm [EDX] [EAX] [ECX];
#		else
			#pragma aux sse2_load_registers = \
				"MOVUPS XMM0, [EAX]"\             
				"MOVUPS XMM4, [ECX]"\
				parm [EDX] [EAX] [ECX];
#		endif
		#pragma aux  sse2_padd_euphoria_values4 = \
				"MOVAPS XMM1, XMM0"\
				"MOVAPS XMM2, XMM0"/*MASK1*/\
				"MOVAPS XMM5, XMM4"/*MASK2*/\
				"MOVAPS XMM6, NOVALUE_128bit"\
				"MOVAPS XMM7, XMM6"\
				/*XMM2 = ((signed)ptr1[0..3] > (signed)NOVALUE_128bit[0..3])*/\
				/*XMM2[i] = 0 where ptr1[i] is a sequence   */\
				"PCMPGTD XMM2, XMM6"\
				\
				/* XMM5 = (ptr2[0..3] > NOVALUE_128bit[0..3])*/\
				/*   XMM5[i] = 0 where ptr1[i] is a sequence */\
				"PCMPGTD XMM5, XMM7"\
				\
				/* Sum vectors before masking: */\
				\
				"PADDD XMM1, XMM4"\
						/* Combine masks XMM5[i] is true iff ptr1[i] + ptr2[i] is a sum of two integers */\
						"ANDPS XMM5, XMM2"\
				"MOVAPS integer_128bit, XMM5"\
				/* Then apply mask to the sum of values */\
						"ANDPS XMM1, XMM5"\
				/* Now check for overflow and underflow*/\
				"MOVAPS XMM6, XMM1"\
				"PCMPGTD XMM6, MAXINT_128bit"\
				"MOVAPS XMM7, MININT_128bit"\
				"PCMPGTD XMM7, XMM1"\
				"MOVAPS XMM3, XMM6"\
				"ORPS XMM3, XMM7"\
				"MOVAPS overunder_128bit, XMM3"\		
				"MOVAPS XMM2, XMM5"\
				"ANDNPS XMM5, ONES_128bit"\
				"ORPS XMM3, XMM5"\
				"MOVAPS intermediate_128bit, XMM3"\
				"PSADBW XMM3, ZEROS_128bit"\
				"PEXTRW EBX, XMM3, 0"\
				"MOV iterate_over_double_words, EBX"\
				\
				/* Now apply these masks negatively to ptr1  mmx2 = (~xmm2) & ptr1 */\
				"ANDNPS XMM2, XMM0"\
				\
				/* Here XMM2 is a component-wise EUPHORIA style sum with the \
				 * non-integer values set to 0.  XMM5 is the mask for these values.\
				 * XMM1 is the original value of ptr1[0..3] with the integer values set to 0. */\
				/* Finally "or" the two possibilities together.  Sequences will be handled */\
				/* in the C code. */\
				"ORPS XMM2, XMM1"\
				"MOVAPS [EDX], XMM2"\
				"EMMS"\
				 modify [EBX] \
				 parm [EDX] [EAX] [ECX];
#	else
		SSE2 instructions not defined for this compiler
#	endif

