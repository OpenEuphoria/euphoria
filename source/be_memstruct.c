#include <stdint.h>
#include <stdio.h>

#include "execute.h"
#include "object.h"
#include "reswords.h"
#include "symtab.h"
#include "be_alloc.h"
#include "be_machine.h"
#include "be_memstruct.h"
#include "be_runtime.h"

static object read_member( void *pointer, symtab_ptr member_sym );
static object read_memunion( void *pointer, symtab_ptr member_sym );

static object box_int( intptr_t x )
{
	if(x > NOVALUE && x < TOO_BIG_INT)
		return (object) x;
	else
		return (object)NewDouble((eudouble)x);
}	

object peek_member( object_ptr source, symtab_ptr memsym, int array_index, void *pointer ){
	int data_type;
	char is_signed;
	s1_ptr s;
	int i;
	
	data_type  = memsym->token;
	is_signed = memsym->u.memstruct.is_signed;
	if( pointer == 0 ){
		pointer = (void*) get_pos_int( "peek member", *source );
	}
	
	if( memsym->u.memstruct.pointer ){
		data_type = MS_OBJECT;
		is_signed = 0;
	}
	else if( array_index != -1 ){
		pointer = (void*) (((intptr_t)pointer) + (array_index * memsym->u.memstruct.size));
	}
	else if( memsym->u.memstruct.array ){
		s = NewS1( memsym->u.memstruct.array );
		for( i = 0; i < memsym->u.memstruct.array; ++i ){
			s->base[i+1] = peek_member( 0, memsym, i, pointer );
		}
		return MAKE_SEQ( s );
	}
	switch( data_type ){
		case MS_CHAR:
			if( is_signed ) return *(char*) pointer;
			else            return *(unsigned char*) pointer;
		case MS_SHORT:
			if( is_signed ) return *(short*) pointer;
			else            return *(unsigned short*) pointer;
		case MS_INT:
			if( is_signed ) return box_int( *(int*) pointer );
			else            return box_int( *(unsigned int*) pointer );
		case MS_LONG:
			if( is_signed ) return box_int( *(long*) pointer );
			else            return box_int( *(unsigned long*) pointer );
		case MS_LONGLONG:
			if( is_signed ) return box_int( *(long long int*) pointer );
			else            return box_int( *(unsigned long long int*) pointer );
		case MS_OBJECT:
			if( is_signed ) return box_int( *(intptr_t*) pointer );
			else            return box_int( *(uintptr_t*) pointer );
		case MS_FLOAT:
			return NewDouble( (eudouble) *(float*)pointer );
		case MS_DOUBLE:
			return NewDouble( (eudouble) *(double*)pointer );
		case MS_LONGDOUBLE:
			return NewDouble( (eudouble) *(long double*)pointer );
		default:
			return read_member( pointer, memsym );
	}
}

static object read_member( void *pointer, symtab_ptr member_sym ){
	
	int token;
	
	token      = member_sym->token;
	
	if( token >= MS_SIGNED && token <= MS_OBJECT ){
		// simple serialization of primitives
		return peek_member( 0, member_sym, -1, pointer );
	}
	
	token = member_sym->token;
	while(1){
		// should only go twice through at most
		if( token == MEMSTRUCT ){
			return read_memstruct( 0, pointer, member_sym );
		}
		else if( token == MEMUNION ){
			return read_memunion( pointer, member_sym );
		}
		
		// get the member's actual struct
		token = member_sym->u.memstruct.struct_type->token;
	}
}

static object read_memunion( void *pointer, symtab_ptr member_sym ){
	s1_ptr s;
	int size;
	int i;
	unsigned char *source;
	object_ptr target;
	
	source = (unsigned char*) pointer;
	size = member_sym->u.memstruct.size;
	s = NewS1( size );
	target = s->base;
	for( i = 1; i <= size; ++i ){
		*(++target) = *(source++);
	}
	return MAKE_SEQ( s );
}

object read_memstruct( object_ptr source, void *pointer, symtab_ptr member_sym ){
	symtab_ptr sym;
	int size;
	s1_ptr s;
	
	if( pointer == 0 ){
		pointer = (void*)get_pos_int( "serialize memstruct", *source );
	}
	if( member_sym->token != MEMSTRUCT ){
		member_sym = member_sym->u.memstruct.struct_type;
	}
	size = 0;
	for( sym = member_sym->u.memstruct.next; sym != 0; sym = sym->u.memstruct.next ){
		++size;
	}
	s = NewS1( size );
	size = 0;
	for( sym = member_sym->u.memstruct.next; sym != 0; sym = sym->u.memstruct.next ){
		s->base[++size] = peek_member( 0, sym, -1, pointer );
		pointer = (void*) ((uintptr_t)pointer + sym->u.memstruct.size);
	}
	return MAKE_SEQ( s );
}

object memstruct_access( int access_count, object_ptr source, symtab_ptr access_sym ){
	uintptr_t pointer;
	int i;
	
	pointer = (uintptr_t)get_pos_int( "memstruct access", *source );
	for( i = 0; i < access_count; ++i ){
		pointer += access_sym[i].u.memstruct.offset;
		if( access_sym[i].u.memstruct.pointer && (i+1) < access_count ){
			pointer = *(uintptr_t*)pointer;
		}
	}
	
	return box_int( pointer );
}

object memstruct_array( object_ptr source, symtab_ptr sym, object_ptr subscript ){
	uintptr_t pointer;
	int array_index;
	
	pointer = get_pos_int( "memstruct array", *source );
	array_index = get_pos_int( "memstruct array subscript", *subscript );
	
	pointer += sym->u.memstruct.size * array_index;
	return box_int( pointer );
}

void poke_member( object_ptr source, symtab_ptr sym, object_ptr val ){
	int data_type;
	int is_signed;
	eudouble d;
	void *pointer;
	
	data_type = sym->token;
	is_signed = sym->u.memstruct.is_signed;
	
	if( sym->u.memstruct.pointer ){
		data_type = MS_OBJECT;
		is_signed = 0;
	}
	
	pointer = (void*) get_pos_int( "storing memory data", *source );
	switch( data_type ){
		case MS_CHAR:
			if( is_signed) *(char*)pointer = (char) get_pos_int( "store char data", *val );
			else           *(unsigned char*)pointer = (unsigned char) get_pos_int( "store char data", *val );
			break;
		case MS_SHORT:
			if( is_signed) *(short*)pointer = (short) get_pos_int( "store short data", *val );
			else           *(unsigned short*)pointer = (unsigned short) get_pos_int( "store short data", *val );
			break;
		case MS_INT:
			if( is_signed) *(int*)pointer = (int) get_pos_int( "store int data", *val );
			else           *(unsigned int*)pointer = (unsigned int) get_pos_int( "store int data", *val );
			break;
		case MS_LONG:
			if( is_signed) *(long*)pointer =  (long) get_pos_int( "store long data", *val );
			else           *(unsigned long*)pointer = (unsigned long) get_pos_int( "store long data", *val );
			break;
		case MS_LONGLONG:
			if( is_signed) *(long long*)pointer = (long long) get_pos_int( "store long long int data", *val );
			else           *(unsigned long long*)pointer = (unsigned long long) get_pos_int( "store long long int data", *val );
			break;
		case MS_OBJECT:
			if( is_signed) *(intptr_t*)pointer = (intptr_t) get_pos_int( "store object data", *val );
			else           *(uintptr_t*)pointer = (uintptr_t) get_pos_int( "store object data", *val );
			break;
		case MS_FLOAT:
		case MS_DOUBLE:
		case MS_LONGDOUBLE:
		case MS_EUDOUBLE:
			if( IS_ATOM_INT( *val ) ){
				d = (eudouble) *val;
			}
			else if( IS_ATOM( *val ) ){
				d = DBL_PTR( *val )->dbl;
			}
			else{
				RTFatal( "Trying to store a sequence into a floating point memory location" );
			}
			if( data_type == MS_DOUBLE ){
				*(double*)pointer = d;
			}
			else if( data_type == MS_FLOAT ){
				*(float*)pointer = (float)d;
			}
			if( data_type == MS_EUDOUBLE ){
				*(eudouble*)pointer = d;
			}
			if( data_type == MS_LONGDOUBLE ){
#ifdef __GNUC__
				*(long double*)pointer = d;
#else
				RTFatal( "long doubles not implemented yet for storing into memory on non-gcc compilers" );
#endif
			}
			break;
		default:
			RTFatal( "Error assigning to a memstruct -- can only assign primitive data members" );
	}
}

#define CALCULATE( type ) \
		type a, c;\
		a = *( type *) pointer;\
		c = (type) get_pos_int( "assign op for object", *opnd );\
		switch( op ){\
			case MEMSTRUCT_PLUS:\
				a += c;\
				break;\
			case MEMSTRUCT_MINUS:\
				a -= c;\
				break;\
			case MEMSTRUCT_MULTIPLY:\
				a *= c;\
				break;\
			case MEMSTRUCT_DIVIDE:\
				if( !c ){\
					RTFatal("attempt to divide by zero");\
				}\
				a /= c;\
				break;\
			default:\
				RTFatal("illegal assign op");\
		}\
		*(type*) pointer = a;
void ms_char( intptr_t op, void* pointer, object_ptr opnd, char is_signed ){
	
	if( is_signed ){
		CALCULATE( char )
	}
	else{
		CALCULATE( unsigned char )
	}
}

void ms_short( intptr_t op, void* pointer, object_ptr opnd, char is_signed ){
	
	if( is_signed ){
		CALCULATE( short )
	}
	else{
		CALCULATE( unsigned short )
	}
}


void ms_int( intptr_t op, void* pointer, object_ptr opnd, char is_signed ){
	
	if( is_signed ){
		CALCULATE( int )
	}
	else{
		CALCULATE( unsigned int )
	}
}

void ms_long( intptr_t op, void* pointer, object_ptr opnd, char is_signed ){
	
	if( is_signed ){
		CALCULATE( long )
	}
	else{
		CALCULATE( unsigned long )
	}
}


void ms_longlong( intptr_t op, void* pointer, object_ptr opnd, char is_signed ){
	
	if( is_signed ){
		CALCULATE( long long int )
	}
	else{
		CALCULATE( unsigned long long int )
	}
}


void ms_object( intptr_t op, void* pointer, object_ptr opnd, char is_signed ){
	
	if( is_signed ){
		CALCULATE( intptr_t )
	}
	else{
		CALCULATE( uintptr_t )
	}
}

#define FLOAT_CALCULATE( type ) \
	type a, c;\
	if( IS_ATOM_INT(  *opnd ) ){\
		c = (type) *opnd;\
	}\
	else if( IS_ATOM( *opnd ) ){\
		c = (type) DBL_PTR( *opnd )->dbl;\
	}\
	else{\
		RTFatal( "Trying to assign a sequence to ##type data" );\
	}\
	a = *(type*)pointer;\
	switch( op ){\
		case MEMSTRUCT_PLUS:\
			a += c;\
			break;\
		case MEMSTRUCT_MINUS:\
			a -= c;\
			break;\
		case MEMSTRUCT_MULTIPLY:\
			a *= c;\
			break;\
		case MEMSTRUCT_DIVIDE:\
			if( c == (type) 0 ){\
				RTFatal("attempt to divide by zero");\
			}\
			a /= c;\
			break;\
		default:\
			RTFatal("illegal assign op");\
	}\
	*(type*)pointer = a;
	
void ms_float( intptr_t op, void* pointer, object_ptr opnd ){
	FLOAT_CALCULATE( float )
}

void ms_double( intptr_t op, void* pointer, object_ptr opnd ){
	FLOAT_CALCULATE( double )
}

void ms_longdouble( intptr_t op, void* pointer, object_ptr opnd ){
#ifdef __GNUC__
	FLOAT_CALCULATE( long double )
#else
	// TODO: convert to doubles and do arithmetic that way? Or more machine code hacks?
	RTFatal( "Extended precision arithmetic not available" );
#endif
}

void ms_eudouble( intptr_t op, void* pointer, object_ptr opnd ){
	FLOAT_CALCULATE( eudouble )
}

void memstruct_assignop( intptr_t op, object_ptr source, symtab_ptr sym, object_ptr opnd ){
	void *pointer;
	char is_signed;
	
	pointer   = (void*) get_pos_int( "memstruct assign op", *source );
	is_signed = sym->u.memstruct.is_signed;
	
	switch( sym->token ){
		case MS_CHAR:
			ms_char( op, pointer, opnd, is_signed );
			break;
		case MS_SHORT:
			ms_short( op, pointer, opnd, is_signed );
			break;
		case MS_INT:
			ms_int( op, pointer, opnd, is_signed );
			break;
		case MS_LONG:
			ms_long( op, pointer, opnd, is_signed );
			break;
		case MS_LONGLONG:
			ms_longlong( op, pointer, opnd, is_signed );
			break;
		case MS_OBJECT:
			ms_object( op, pointer, opnd, is_signed );
			break;
		case MS_FLOAT:
			ms_float( op, pointer, opnd );
			break;
		case MS_DOUBLE:
			ms_double( op, pointer, opnd );
			break;
		case MS_LONGDOUBLE:
			ms_longdouble( op, pointer, opnd );
			break;
		case MS_EUDOUBLE:
			ms_eudouble( op, pointer, opnd );
			break;
		default:
			RTFatal( "Target of the assignment must be a primitive data type" );
	}
	
}