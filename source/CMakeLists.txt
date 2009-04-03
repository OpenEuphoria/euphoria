#
# CMake build file for Euphoria (All Platforms)
#
# Quick Instructions:
#   1. cd C:\EUPHORIA\SOURCE
#   2. mkdir build
#   3. cd build
#   4. cmake -G "Watcom WMake" ..
#   5. wmake
#

CMAKE_MINIMUM_REQUIRED( VERSION 2.4 )
PROJECT(Euphoria C)

#
# Versioning
#

SET( VER_MAJ 4 )
SET( VER_MIN 0 )
SET( VER_PAT 0 )
SET( VER_TYPE "development" )

#
# Options
#

OPTION( USE_INT_CODES   "Use INT_CODES"      ON )
OPTION( USE_MANAGED_MEM "Use Managed Memory" ON  )
OPTION( USE_DEBUG       "Enable debug"       OFF )

#IF( USE_INT_CODES )
  ADD_DEFINITIONS( -DINT_CODES )
#ENDIF( USE_INT_CODES )

IF( NOT USE_MANAGED_MEM )
  ADD_DEFINITIONS( -DESIMPLE_MALLOC )
ENDIF( NOT USE_MANAGED_MEM )

IF( USE_DEBUG )
  ADD_DEFINITIONS( -DEDEBUG )
ENDIF( USE_DEBUG )

#
# Flags
#

INCLUDE_DIRECTORIES(..)
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/..)

IF( CMAKE_COMPILER_IS_GNUCC )
  SET( CMAKE_CXX_FLAGS "-pedantic -Wall" )
ENDIF( CMAKE_COMPILER_IS_GNUCC )

IF( WIN32 )
  IF( BORLAND )
    ADD_DEFINITIONS( -DBCPP )
  ENDIF( BORLAND )

  IF( CYGWIN )
  ENDIF( CYGWIN)

  IF( MINGW )
    ADD_DEFINITIONS( -DEMINGW -O3 -Os -ffast-math -mno-cygwin -mwindows )
  ENDIF( MINGW)

  IF( MSVC )
    ADD_DEFINITIONS( -D_CRT_NONSTDC_NO_WARNINGS -D_CRT_SECURE_NO_WARNINGS -DMSVC -DEMSVC -DELCC )
  ENDIF( MSVC )

  IF( WATCOM )
    ADD_DEFINITIONS( -DEWATCOM -DEOW )
    ADD_DEFINITIONS( /bt=nt /mf /w0 /zq /j /zp4 /fp5 /fpi87 /5r /otimra /s )
    ADD_DEFINITIONS( /ol )
  ENDIF( WATCOM )

  ADD_DEFINITIONS( -DEWINDOWS )

  SET( TRANSLATOR ecw.exe )
ENDIF( WIN32 )

IF( UNIX )
  ADD_DEFINITIONS( -DEUNIX )

  IF( ${CMAKE_SYSTEM_NAME} MATCHES "Linux" )
    ADD_DEFINITIONS( -DELINUX )
  ENDIF( ${CMAKE_SYSTEM_NAME} MATCHES "Linux" )

  IF( ${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD" )
    ADD_DEFINITIONS( -DEBSD -DEFREEBSD )
  ENDIF( ${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD" )

  IF( ${CMAKE_SYSTEM_NAME} MATCHES "Darwin" )
    ADD_DEFINITIONS( -DEBSD -DEOSX )
  ENDIF( ${CMAKE_SYSTEM_NAME} MATCHES "Darwin" )

  IF( ${CMAKE_SYSTEM_NAME} MATCHES "SunOS" )
    ADD_DEFINITIONS( -DEBSD -DSUNOS )
  ENDIF( ${CMAKE_SYSTEM_NAME} MATCHES "SunOS" )

  SET( TRANSLATOR ecu )
ENDIF( UNIX )

INCLUDE_DIRECTORIES( "${CMAKE_CURRENT_BINARY_DIR}" )

#
# Source File Lists
#

FILE( GLOB PCRE_SOURCES "pcre/*.c" )

SET( EU_CORE_FILES
  common.e 
  emit.e 
  error.e 
  fwdref.e 
  global.e 
  inline.e
  keylist.e 
  main.e
  mode.e 
  opnames.e 
  parser.e 
  pathopen.e 
  reswords.e 
  rev.e
  scanner.e 
  scinot.e 
  shift.e 
  symtab.e
  version.e
)

SET( EU_INTERPRETER_FILES
  compress.e
  backend.e
  c_out.e
  cominit.e
  intinit.e
  int.ex
)

SET( EU_BACKEND_SOURCES
  be_alloc.c
  be_callc.c
  be_decompress.c
  be_execute.c
  be_inline.c
  be_machine.c
  be_main.c
  be_pcre.c
  be_rterror.c
  be_runtime.c
  be_socket.c
  be_symtab.c
  be_syncolor.c
  be_task.c
  be_w.c
  version.h
)

SET( EU_LIB_SOURCES
  be_alloc.c
  be_callc.c
  be_decompress.c
  be_inline.c
  be_machine.c
  be_pcre.c
  be_runtime.c
  be_socket.c
  be_task.c
  be_w.c
  version.h
)

#
# Generators
#

CONFIGURE_FILE( version.h.in version.h )
CONFIGURE_FILE( version.e.in version.e )

FILE( MAKE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/int )
ADD_CUSTOM_COMMAND(
  OUTPUT int/main.c
  DEPENDS ${EU_CORE_FILES} ${EU_INTERPRETER_FILES}
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/int
  COMMAND ${TRANSLATOR} ${CMAKE_CURRENT_SOURCE_DIR}/int.ex
)
FILE( GLOB EU_INTERPRETER_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/int/*.c" )

FILE( MAKE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/trans )
ADD_CUSTOM_COMMAND(
  OUTPUT trans/main.c
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/trans
  COMMAND ${TRANSLATOR} ${CMAKE_CURRENT_SOURCE_DIR}/ec.ex
)
FILE( GLOB EU_TRANSLATOR_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/trans/*.c" )

FILE( MAKE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/back )
ADD_CUSTOM_COMMAND(
  OUTPUT back/main-.c
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/back
  COMMAND ${TRANSLATOR} ${CMAKE_CURRENT_SOURCE_DIR}/backend.ex
)
FILE( GLOB EU_BACKEND_RUNNER_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/back/*.c" )

#
# Targets
#

# Make a library of the PCRE sources, that way we only compile
# them once and link to it many times.
ADD_LIBRARY( eu_pcre STATIC ${PCRE_SOURCES} )

ADD_LIBRARY( eruntime STATIC ${EU_LIB_SOURCES} )
SET_TARGET_PROPERTIES( eruntime PROPERTIES COMPILE_FLAGS -DERUNTIME )

IF( WIN32 )
  FIND_LIBRARY( WINSOCK_LIB ws2_32 PATHS "$ENV{WATCOM}/lib386/nt")
  IF( NOT WINSOCK_LIB )
    MESSAGE( FATAL_ERROR  "Could not located the winsock library (ws2_32)")
  ENDIF( NOT WINSOCK_LIB )

  ADD_EXECUTABLE( eu WIN32 int/main.c ${EU_INTERPRETER_SOURCES} ${EU_BACKEND_SOURCES} )
  TARGET_LINK_LIBRARIES( eu eu_pcre ${WINSOCK_LIB} )

  ADD_EXECUTABLE( euc WIN32 trans/main.c ${EU_TRANSLATOR_SOURCES} ${EU_BACKEND_SOURCES} )
  TARGET_LINK_LIBRARIES( euc eu_pcre eruntime ${WINSOCK_LIB} )

  ADD_EXECUTABLE( eub WIN32 back/main-.c ${EU_BACKEND_RUNNER_SOURCES} ${EU_BACKEND_SOURCES} )
  SET_TARGET_PROPERTIES( eub PROPERTIES COMPILE_FLAGS -DEBACKEND )
  TARGET_LINK_LIBRARIES( eub eu_pcre eruntime ${WINSOCK_LIB} )

  #ADD_EXECUTABLE( backendc WIN32 ${EU_BACKEND_RUNNER_SOURCES} ${EU_BACKEND_SOURCES} ${PCRE_SOURCES} )
  #TARGET_LINK_LIBRARIES( backendc ws2_32 )

  IF( WATCOM )
    SET_TARGET_PROPERTIES( eu  PROPERTIES LINK_FLAGS " SYS nt_win " )
    SET_TARGET_PROPERTIES( euc PROPERTIES LINK_FLAGS " SYS nt_win " )
    SET_TARGET_PROPERTIES( eub PROPERTIES LINK_FLAGS " SYS nt_win " )
  ENDIF( WATCOM )
ENDIF( WIN32)

IF( UNIX )
  ADD_EXECUTABLE( eu ${EU_CORE_SOURCES_INTERP} ${EU_INTERPRETER_SOURCES} ${EU_BACKEND_SOURCES} )

  ADD_EXECUTABLE( euc ${EU_CORE_SOURCES_TRANS} ${EU_TRANSLATOR_SOURCES} ${EU_BACKEND_SOURCES} )

  ADD_EXECUTABLE( eub ${EU_BACKEND_RUNNER_SOURCES} ${EU_BACKEND_SOURCES} )
  SET_TARGET_PROPERTIES( eub PROPERTIES COMPILE_FLAGS -DEBACKEND )
ENDIF( UNIX )

# ADD_DEFINITIONS( -DERUNTIME )
# ADD_LIBRARY( $(EULIB) STATIC ${EU_LIB_SOURCES} )
