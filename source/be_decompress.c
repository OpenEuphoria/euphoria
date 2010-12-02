#include <stdio.h>
#include <stdlib.h>
#include "alldefs.h"
#include "be_alloc.h"

unsigned char *string_ptr;

// Compressed format of Euphoria objects
//
// First byte:
//          0..248  // immediate small integer, -9 to 239
					// since small negative integers -9..-1 might be common
#define I2B 249   // 2-byte signed integer follows
#define I3B 250   // 3-byte signed integer follows
#define I4B 251   // 4-byte signed integer follows
#define F4B 252   // 4-byte f.p. number follows
#define F8B 253   // 8-byte f.p. number follows
#define S1B 254   // sequence, 1-byte length follows, then elements
#define S4B 255   // sequence, 4-byte length follows, then elements

#define MIN1B (-2)
#define MIN2B (-0x00008000)
#define MIN3B (-0x00800000)
#define MIN4B (-0x80000000)


object decompress(unsigned int c)
// read a compressed Euphoria object
// if c is set, then c is not <= 248    
{
	s1_ptr s;
	object_ptr obj_ptr;
	unsigned int len, i;
	double d;
	
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
		i = *(unsigned int *)string_ptr;
		string_ptr += 4;
		return i + MIN4B;
	}
	
	else if (c == F4B) {
		d = (double)*(float *)string_ptr; 
		string_ptr += 4;
		return NewDouble(d);
	}
	
	else if (c == F8B) {
		d = *(double *)string_ptr; 
		string_ptr += 8;
		return NewDouble(d);
	}
	
	else {
		// sequence
		if (c == S1B) {
			len = *string_ptr++;
		}
		else {
			len = *(unsigned int *)string_ptr;
			string_ptr += 4;
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
