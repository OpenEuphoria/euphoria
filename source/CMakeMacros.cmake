#
# Setup the environment for Euphoria, also define some helpful
# Euphoria centric macros that are of use to the Euphoria project
# and end users who wish to use CMake with their projects as well.
#

#
# Compiler/Platform flags
#

SET( TRANSLATOR  "$ENV{EUDIR}/bin/euc" )
SET( INTERPRETER "$ENV{EUDIR}/bin/eui" )

# This hits Cygwin, MinGW and all Unixes
IF( CMAKE_COMPILER_IS_GNUCC AND NOT DEBUG )
  SET( C_FLAGS_RELEASE "-w -ffast-math -O3 -Os" )
  SET( C_FLAGS_DEBUG   "-g3 -O0 -Wall" )
ENDIF()

IF( WIN32 )
  # Window specific definitions
  ADD_DEFINITIONS( -DEWINDOWS )

  # Special compiler definitions
  IF( CYGWIN )
  ENDIF()

  IF( MINGW )
    SET( LIB_PATHS "/MinGW/lib" )
    ADD_DEFINITIONS( -DEMINGW -mno-cygwin -mwindows )
  ENDIF()

  IF( MSVC )
    ADD_DEFINITIONS( -D_CRT_NONSTDC_NO_WARNINGS -D_CRT_SECURE_NO_WARNINGS -DEMSVC )
  ENDIF()

  IF( WATCOM )
    ADD_DEFINITIONS( -DEWATCOM -DEOW )

    SET( LIB_PATHS          "$ENV{WATCOM}/lib386/nt" )
    SET( EXECUTABLE_FLAG    "WIN32" )
    SET( C_FLAGS_RELEASE    "/bt=nt /mf /w0 /zq /j /zp4 /fp5 /fpi87 /5r /otimra /s /ol /zp8 " )
    SET( C_FLAGS_DEBUG      "${CMAKE_C_FLAGS_RELEASE} /d2 /dEDEBUG /dHEAP_CHECK" )
    SET( LINK_FLAGS_RELEASE "OPTION QUIET OPTION CASEEXACT OPTION ELIMINATE" )
    SET( LINK_FLAGS_DEBUG   "${LINK_FLAGS_RELEASE} DEBUG ALL" )
  ENDIF()
ENDIF( WIN32 )

IF( UNIX )
  ADD_DEFINITIONS( -DEUNIX )
  SET( LIB_PATHS "/MinGW/lib;/lib;/usr/lib;/usr/local/lib;/opt/lib;/opt/local/lib" )

  # Platform specific
  IF( ${CMAKE_SYSTEM_NAME} MATCHES "Darwin" )
    ADD_DEFINITIONS( -DEBSD -DEBSD62 -DOSX )
  ENDIF()

  IF( ${CMAKE_SYSTEM_NAME} MATCHES "SunOS" )
    ADD_DEFINITIONS( -DEBSD -DEBSD62 -DESUNOS )
  ENDIF()

  IF( ${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD" )
    ADD_DEFINITIONS( -DEBSD -DEBSD62 -DEFREEBSD )
  ENDIF()

  IF( ${CMAKE_SYSTEM_NAME} MATCHES "OpenBSD" )
    ADD_DEFINITIONS( -DEBSD -DEBSD62 -DEOPENBSD )
  ENDIF()

  IF( ${CMAKE_SYSTEM_NAME} MATCHES "NetBSD" )
    ADD_DEFINITIONS( -DEBSD -DEBSD62 -DENETBSD )
  ENDIF()

  IF( ${CMAKE_SYSTEM_NAME} MATCHES "Linux" )
    ADD_DEFINITIONS( -DELINUX )
  ENDIF()
ENDIF()

# Let CMake find the libraries, if found, we need to link to it, if not
# then the said functionality appears in libc already, no extra lib needed.
SET( CMAKE_FIND_LIBRARY_PREFIXES "lib;" )
SET( CMAKE_FIND_LIBRARY_SUFFIXES ".lib;.a;.so;.dylib" )

FIND_LIBRARY( DL_LIB dl PATHS ${LIB_PATHS} )
IF( DL_LIB )
  MESSAGE( STATUS "dl library found, adding to linker" )
  LIST( APPEND EXTRA_LIBS "${DL_LIB}" )
ENDIF()

FIND_LIBRARY( RESOLV_LIB resolv PATHS ${LIB_PATHS} )
IF( RESOLV_LIB )
  MESSAGE( STATUS "resolv library found, adding to linker" )
  LIST( APPEND EXTRA_LIBS "${RESOLV_LIB}" )
ENDIF()

FIND_LIBRARY( NSL_LIB nsl PATHS ${LIB_PATHS} )
IF( NSL_LIB )
  MESSAGE( STATUS "nsl library found, adding to linker" )
  LIST( APPEND EXTRA_LIBS "${NSL_LIB}" )
ENDIF()

FIND_LIBRARY( MATH_LIB m PATHS ${LIB_PATHS} )
IF( MATH_LIB )
  MESSAGE( STATUS "math library found, adding to linker" )
  LIST( APPEND EXTRA_LIBS "${MATH_LIB}" )
ENDIF()

FIND_LIBRARY( WINSOCK_LIB ws2_32 PATHS ${LIB_PATHS} )
IF( WINSOCK_LIB )
  MESSAGE( STATUS "winsock library found, adding to linker" )
  LIST( APPEND EXTRA_LIBS "${WINSOCK_LIB}" )
ENDIF()

IF( CMAKE_BUILD_TYPE MATCHES "Debug" )
  ADD_DEFINITIONS( -DEDEBUG )
  SET( CMAKE_C_FLAGS ${C_FLAGS_DEBUG} )
  SET( LINK_FLAGS    ${LINK_FLAGS_DEBUG} )
ELSE()
  SET( CMAKE_C_FLAGS ${C_FLAGS_RELEASE} )
  SET( LINK_FLAGS    ${LINK_FLAGS_RELEASE} )
ENDIF()

#
# Helper Macros
#

MACRO( EUC SOURCE_FILES NAME )
  SET( _UPDATE 0 )
  FILE( MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${NAME}" )

  FOREACH( file ${SOURCE_FILES} )
    SET( _FULL_FILE "${CMAKE_CURRENT_SOURCE_DIR}/${file}" )
    CONFIGURE_FILE( "${_FULL_FILE}" "${CMAKE_CURRENT_BINARY_DIR}/${NAME}/${file}.flag" COPYONLY )
    IF( "${_FULL_FILE}" IS_NEWER_THAN "${CMAKE_CURRENT_BINARY_DIR}/${NAME}/${NAME}.cmake" )
      SET( _UPDATE 1 )
    ENDIF()
  ENDFOREACH()

  IF( _UPDATE )
    MESSAGE( STATUS "Translating ${NAME}.ex..." )
    EXECUTE_PROCESS(
      COMMAND ${TRANSLATOR} -cmakefile -o "${NAME}" "${CMAKE_CURRENT_SOURCE_DIR}/${NAME}.ex"
      WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}" )
  ENDIF()

  INCLUDE( "${CMAKE_CURRENT_BINARY_DIR}/${NAME}/${NAME}.cmake" )
ENDMACRO( EUC )
