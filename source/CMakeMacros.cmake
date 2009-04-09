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
SET( LINK_FLAGS "" )
SET( EXTRA_LIBS "" )
SET( EXECUTABLE_FLAG "" )

IF( CMAKE_COMPILER_IS_GNUCC AND NOT ENABLE_DEBUG )
  SET( CMAKE_C_FLAGS "-w -ffast-math -O3 -Os" )
ENDIF()

IF( WIN32 )
  # Window specific definitions
  ADD_DEFINITIONS( -DEWINDOWS )

  # Special compiler definitions
  IF( CYGWIN )
  ENDIF()

  IF( MINGW )
    ADD_DEFINITIONS( -DEMINGW -mno-cygwin -mwindows )
  ENDIF()

  IF( MSVC )
    ADD_DEFINITIONS( -D_CRT_NONSTDC_NO_WARNINGS -D_CRT_SECURE_NO_WARNINGS -DEMSVC )
  ENDIF()

  IF( WATCOM )
    SET( EXECUTABLE_FLAG "WIN32" )
    ADD_DEFINITIONS( -DEWATCOM -DEOW )

    SET( CMAKE_C_FLAGS "/bt=nt /mf /w0 /zq /j /zp4 /fp5 /fpi87 /5r /otimra /s /ol /zp8 " )
    SET( LINK_FLAGS "OPTION QUIET OPTION CASEEXACT OPTION ELIMINATE" )

    FIND_LIBRARY( WSOCK_LIB ws2_32 PATHS "$ENV{WATCOM}/lib386/nt")
    IF( NOT WSOCK_LIB )
      MESSAGE( FATAL_ERROR  "Could not located the winsock library (ws2_32)")
    ENDIF()

    LIST( APPEND EXTRA_LIBS "${WSOCK_LIB}" )
  ENDIF()
ENDIF( WIN32 )

IF( UNIX )
  ADD_DEFINITIONS( -DEUNIX )
  SET( CMAKE_FIND_LIBRARY_PREFIXES "lib" )
  SET( CMAKE_FIND_LIBRARY_SUFFIXES ".so;.dylib" )

  # Platform specific
  IF( ${CMAKE_SYSTEM_NAME} MATCHES "Darwin" )
    SET( BSD 1 )
    SET( OSX 1 )
    ADD_DEFINITIONS( -DEBSD -DEBSD62 -DOSX )
  ENDIF()

  IF( ${CMAKE_SYSTEM_NAME} MATCHES "SunOS" )
    SET( BSD 1 )
    SET( SUNOS 1 )
    ADD_DEFINITIONS( -DEBSD -DEBSD62 -DESUNOS )
  ENDIF()

  IF( ${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD" )
    SET( BSD 1 )
    SET( FREEBSD 1 )
    ADD_DEFINITIONS( -DEBSD -DEBSD62 -DEFREEBSD )
  ENDIF()

  IF( ${CMAKE_SYSTEM_NAME} MATCHES "OpenBSD" )
    SET( BSD 1 )
    SET( OPENBSD 1 )
    ADD_DEFINITIONS( -DEBSD -DEBSD62 -DEOPENBSD )
  ENDIF()

  IF( ${CMAKE_SYSTEM_NAME} MATCHES "NetBSD" )
    SET( BSD 1 )
    SET( NETBSD 1 )
    ADD_DEFINITIONS( -DEBSD -DEBSD62 -DENETBSD )
  ENDIF()

  IF( LINUX )
    ADD_DEFINITIONS( -DELINUX )
  ENDIF()

  # Let CMake find the libraries, if found, we need to link to it, if not
  # then the said functionality appears in libc already, no extra lib needed.
  FIND_LIBRARY( DL_LIB dl )
  IF( DL_LIB )
    LIST( APPEND EXTRA_LIBS "${DL_LIB}" )
  ENDIF()

  FIND_LIBRARY( RESOLV_LIB resolv )
  IF( RESOLV_LIB )
    LIST( APPEND EXTRA_LIBS "${RESOLV_LIB}" )
  ENDIF()

  FIND_LIBRARY( NSL_LIB nsl )
  IF( NSL_LIB )
    LIST( APPEND EXTRA_LIBS "${NSL_LIB}" )
  ENDIF()
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
