#ifndef VERSION_H_

#define MAJ_VER 4 
#define MIN_VER 0 
#define PAT_VER 0 

#ifndef EREL_TYPE

#define REL_TYPE "development" 

#else

#define XSTR( S ) STR( S )
#define STR( S ) #S

#define REL_TYPE XSTR( EREL_TYPE )

#endif

#endif
