#ifndef BE_EXPAT_H_
#define BE_EXPAT_H_

#include "object.h"

object euexpat_create_parser(object x);
object euexpat_reset_parser(object x);
object euexpat_free_parser(object x);

#endif // BE_EXPAT_H_
