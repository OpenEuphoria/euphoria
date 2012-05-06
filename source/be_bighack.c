#include "be_bighack.h"

struct routine_list * _00;
int Argc;
char ** Argv;

void pre_init_backend_lib(struct routine_list * _00_, int argc, char ** argv)
{
	_00 = _00_;
	Argc = argc;
	Argv = argv;
}
