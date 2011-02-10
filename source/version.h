#ifndef VERSION_H_

/* If you change the version here also 
 * chnange the version in
 * 1. version_info.rc
 * 2. euphoria*.iss
*/

#define MAJ_VER 4 
#define MIN_VER 0 
#define PAT_VER 1 

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
