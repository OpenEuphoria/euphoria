#ifndef VERSION_H_

#define MAJ_VER 4 
#define MIN_VER 1
#define PAT_VER 0 

#ifndef EREL_TYPE
#  define REL_TYPE "development"
#else
#  if EREL_TYPE == 1
#    define REL_TYPE ""
#  else
#    define XSTR( S ) STR( S )
#    define STR( S ) #S
#    define REL_TYPE XSTR( EREL_TYPE )
#  endif
#endif

#endif
