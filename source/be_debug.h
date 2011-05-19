#ifndef BE_DEBUG_H_
#define BE_DEBUG_H_

#include "object.h"

extern int external_debugger;
extern int in_external_debugger;

void ExternalShowDebug();
void ExternalDisplayVar( symtab_ptr s_ptr, int user_requested );
void ExternalUpdateGlobals();
void ExternalDebugScreen();
void ExternalEraseSymbol( symtab_ptr sym );
void ExternalErasePrivates( symtab_ptr proc_sym );

object init_debug_addr();
void set_debugger( char *name );
int load_debugger();
object eu_call_stack();

#endif
