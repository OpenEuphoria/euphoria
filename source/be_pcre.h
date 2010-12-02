#ifndef BE_PCRE_H_
#define BE_PCRE_H_

#include "object.h"
#include "pcre/pcre.h"

struct pcre_cleanup {
        struct cleanup cleanup;
        pcre *re;
        object errmsg;
};
typedef struct pcre_cleanup *pcre_cleanup_ptr;

object compile(object pattern, object eflags);
object compile_pcre(object x, object flags);
object pcre_error_message(object x);
object get_ovector_size(object x );
object exec_pcre(object x );
int replace_pcre(const char *rep, const char *Src, int len, int *ovector, int cnt,
                                 char **Dest, int *Dlen);
object find_replace_pcre(object x );
object pcre_error_message(object x);

#endif
