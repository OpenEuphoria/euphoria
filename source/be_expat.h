#ifndef BE_EXPAT_H_
#define BE_EXPAT_H_

#include "object.h"
#include "expat/expat.h"

typedef struct _euexpat {
    struct cleanup cleanup;
    XML_Parser p;
    object start_element_handler;
    object end_element_handler;
    object char_data_handler;
    object default_handler;
    object comment_handler;
} euexpat;

object euexpat_create_parser(object x);
object euexpat_reset_parser(object x);
object euexpat_free_parser(object x);
object euexpat_parse(object x);
object euexpat_set_callback(object x);
object euexpat_get_callback(object x);
object euexpat_get_current(object x);

#endif // BE_EXPAT_H_
