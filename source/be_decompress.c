
#include <stdint.h>
#if defined(EWINDOWS) && INTPTR_MAX == INT64_MAX
// MSVCRT doesn't handle long double output correctly
#define __USE_MINGW_ANSI_STDIO 1
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "alldefs.h"
#include "be_alloc.h"
#include "be_runtime.h"

unsigned char *string_ptr;

// Compressed format of Euphoria objects
//
// First byte:
//          0..246  // immediate small integer, -9 to 237
					// since small negative integers -9..-1 might be common
#define I2B  247   // 2-byte signed integer follows
#define I3B  248   // 3-byte signed integer follows
#define I4B  249   // 4-byte signed integer follows
#define I8B  250
#define F4B  251   // 4-byte f.p. number follows
#define F8B  252   // 8-byte f.p. number follows
#define F10B 253
#define S1B  254   // sequence, 1-byte length follows, then elements
#define S4B  255   // sequence, 4-byte length follows, then elements

#define MIN1B (int32_t)(-2)
#define MIN2B (int32_t)(-0x00008000)
#define MIN3B (int32_t)(-0x00800000)
#define MIN4B (int32_t)(-0x80000000)
#define MIN8B (int64_t)(-0x8000000000000000LL)

object decompress(uintptr_t c)
// read a compressed Euphoria object
// if c is set, then c is not <= 248    
{
	s1_ptr s;
	object_ptr obj_ptr;
	int32_t len;
	int32_t i;
	int64_t i8;
	float f;
	double d;
	long double ld;
	
	if (c == 0) {
		c = *string_ptr++;
		if (c < I2B) {
			return c + MIN1B;
		}
	}
	
	if (c == I2B) {
		i = (*string_ptr++);
		i = i + 256 * (*string_ptr++);
		return i + MIN2B;
	}
	
	else if (c == I3B) {
		i = *string_ptr++;
		i = i + 256 * (*string_ptr++);
		i = i + 65536 * (*string_ptr++);
		return i + MIN3B;
	}
	
	else if (c == I4B) {
		i = *(int32_t *)string_ptr;
		string_ptr += sizeof( int32_t );
		return i;
	}
	
	else if ( c == I8B ) {
		i8 = *(int64_t *)string_ptr;
		string_ptr += sizeof( int64_t );
		return i8;
	}
	else if (c == F4B) {
		d = (double)*(float*)memcpy((void*)&f, (void*)string_ptr, 4); 
		string_ptr += sizeof( float );
		return NewDouble((eudouble)d);
	}
	
	else if (c == F8B) {
		memcpy((void*)&d, (void*)string_ptr, sizeof(double)); 
		string_ptr += sizeof( double );
		return NewDouble((eudouble)d);
	}
	else if ( c == F10B ) {
		// long doubles may be greater than or less than 10
		// example: x86-64 GCC Linux  : sizeof(long double) = 16
		// example: x86-64 GCC Windows: sizeof(long double) = 12
		// example:    ARM GCC Linux  : sizeof(long double) = 8		
		// We shouldn't copy more than the data space available to ld,
		// but we shouldn't advance the string pointer more than 10 as 
		// the data stored here always only occupies exactly 10 bytes.
		memcpy((void*)&ld, (void*)string_ptr, 
			(10 <= sizeof(long double)) ? 10 : sizeof(long double));
		// FIXME:  Must convert the 80-bit value to 64-bit for versions that do not
		// have 80-bit long doubles.
		string_ptr += 10;
		return NewDouble( ld );
	}
	
	else {
		// sequence
		if (c == S1B) {
			len = *string_ptr++;
		}
		else {
			len = *(int32_t *)string_ptr;
			string_ptr += sizeof( int32_t );
		}
		s = NewS1(len);
		obj_ptr = s->base;
		obj_ptr++;
		for (i = 1; i <= len; i++) {
			// inline small integer for greater speed on strings
			c = *string_ptr++;
			if (c < I2B) {
				*obj_ptr = c + MIN1B;
			}
			else {
				*obj_ptr = decompress(c);
			}
			obj_ptr++;
		}
		return MAKE_SEQ(s);
	}
}
