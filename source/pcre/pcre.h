#if defined(_WIN32) || defined(EDOS)
#	include "pcre.h.windows"
#else
#    if defined(EUNIX)
#    	include "pcre.h.unix"
#    else
#       error **
#       error ** No OS set!                              
#	error ** Please run configure and make utilities 
#	error ** from this directory s parent
#	error ** 
#    endif
#endif

