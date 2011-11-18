#ifndef BE_MEMSTRUCT_H_
#define BE_MEMSTRUCT_H_

#include "execute.h"
#include "object.h"
#include "symtab.h"

object peek_member( object_ptr source, symtab_ptr memsym, int array_index, void *pointer );
void poke_member( object_ptr source, symtab_ptr sym, object_ptr val );
void write_member( object_ptr source, symtab_ptr sym, object_ptr val );
void write_union( object_ptr source, symtab_ptr sym, object_ptr val );

object memstruct_array( object_ptr source, symtab_ptr sym, object_ptr subscript );
object memstruct_access( int access_count, object_ptr source, symtab_ptr access_sym );
object read_memstruct( object_ptr source, void *pointer, symtab_ptr member_sym );


void memstruct_assignop( intptr_t op, object_ptr source, symtab_ptr sym, object_ptr opnd );

#endif
