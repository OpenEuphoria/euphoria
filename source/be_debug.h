#ifndef BE_DEBUG_H_
#define BE_DEBUG_H_

#include "object.h"

extern int external_debugger;

void ExternalShowDebug();
void ExternalDisplayVar( symtab_ptr s_ptr, int user_requested );
void ExternalUpdateGlobals();
void ExternalDebugScreen();

object init_debug_addr();

#endif
