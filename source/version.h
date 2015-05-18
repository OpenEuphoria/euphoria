#ifndef VERSION_H_

/* The following files all must be
 * changed when changing the patch version,
 * minor version or major version:
 * 1. /source/version_info.rc
 * 2. /packaging/win32/euphoria.iss
 * 3. /packaging/win32/euphoria-ow.iss
 * 4. /tests/t_condcmp.e
 * 5. /source/version.h
 * 6. /docs/refman_2.txt (Euphoria Version Definitions)
 * 7. /docs/release/ (Release notes)
 * 8. /docs/manual.af (add release notes)
*/

#define MAJ_VER 4 
#define MIN_VER 0 
#define PAT_VER 6

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
