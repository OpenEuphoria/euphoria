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
    ADD_DEFINITIONS( -DEOSX )
  ENDIF( ${CMAKE_SYSTEM_NAME} MATCHES "Darwin" )

  SET( TRANSLATOR ecu )
ENDIF( UNIX )

INCLUDE_DIRECTORIES( "${CMAKE_CURRENT_BINARY_DIR}" )

#
# Source File Lists

SET( PCRE_SOURCES
  pcre/pcre_chartables.c
  pcre/pcre_compile.c
  pcre/pcre_config.c
  pcre/pcre_dfa_exec.c
  pcre/pcre_exec.c
  pcre/pcre_fullinfo.c
  pcre/pcre_get.c
  pcre/pcre_globals.c
  pcre/pcre_info.c
  pcre/pcre_maketables.c
  pcre/pcre_newline.c
  pcre/pcre_ord2utf8.c
  pcre/pcre_refcount.c
  pcre/pcre_study.c
  pcre/pcre_tables.c
  pcre/pcre_try_flipped.c
  pcre/pcre_ucd.c
  pcre/pcre_valid_utf8.c
  pcre/pcre_version.c
  pcre/pcre_xclass.c
  pcre/pcreposix.c
)

SET( EU_TRANSLATOR_SOURCES
  trans/ec.c trans/0rror.c trans/c_decl.c trans/c_dec0.c trans/c_dec1.c trans/c_out.c
  trans/cominit.c trans/compile.c trans/compil_0.c trans/compil_1.c trans/compil_2.c
  trans/compil_3.c trans/compil_4.c trans/compil_5.c trans/compil_6.c trans/compil_7.c
  trans/compil_8.c trans/compil_9.c trans/compil_A.c trans/compress.c trans/get.c
  trans/global.c trans/sort.c trans/symtab_0.c trans/traninit.c trans/tranplat.c
  trans/wildcard.c trans/sequence.c trans/text.c trans/types.c trans/dll.c
  trans/filesys.c trans/io.c trans/memory.c
)

SET( EU_BACKEND_RUNNER_SOURCES
  back/0ackend.c
  back/backend.c
  back/cominit.c
  back/compress.c
  back/convert.c
  back/dll.c
  back/error.c
  back/filesys.c
  back/init-.c
  back/intinit.c
  back/machine.c
  back/main-.c
  back/main-.h
  back/memory.c
  back/mode.c
  back/pathopen.c
  back/search.c
  back/sort.c
  back/text.c
  back/types.c
  back/wildcard.c
)

#SET( EU_CORE_SOURCES_PLAIN
#  main-.c main-0.c convert.c pathopen.c init-.c error.c mode.c symtab.c scanner.c scientific.c
#  scanne_0.c main.c emit.c emit_0.c emit_1.c parser.c parser_0.c parser_1.c parser_2.c parser_3.c
# search.c scanne_1.c
#)

SET( EU_CORE_SOURCES_INTERP
  int/backend.c
  int/cominit.c
  int/compress.c
  int/convert.c
  int/datetime.c
  int/dll.c
  int/emit.c
  int/emit_0.c
  int/emit_1.c
  int/error.c
  int/eumem.c
  int/filesys.c
  int/fwdref.c
  int/fwdref_0.c
  int/get.c
  int/init-.c
  int/inline.c
  int/inline_0.c
  int/int.c
  int/intinit.c
  int/machine.c
  int/main-.c
  int/main-0.c
  int/main.c
  int/map.c
  int/memory.c
  int/mode.c
  int/parser.c
  int/parser_0.c
  int/parser_1.c
  int/parser_2.c
  int/parser_3.c
  int/parser_4.c
  int/parser_5.c
  int/pathopen.c
  int/platform.c
  int/primes.c
  int/scanne_0.c
  int/scanne_1.c
  int/scanner.c
  int/scinot.c
  int/search.c
  int/shift.c
  int/shift_0.c
  int/sort.c
  int/symtab.c
  int/symtab_0.c
  int/symtab_1.c
  int/text.c
  int/types.c
  int/wildcard.c
)

SET( EU_CORE_SOURCES_TRANS
  trans/c_dec0.c
  trans/c_dec1.c
  trans/c_dec2.c
  trans/c_decl.c
  trans/c_out.c
  trans/cominit.c
  trans/compil_0.c
  trans/compil_1.c
  trans/compil_2.c
  trans/compil_3.c
  trans/compil_4.c
  trans/compil_5.c
  trans/compil_6.c
  trans/compil_7.c
  trans/compil_8.c
  trans/compil_9.c
  trans/compil_A.c
  trans/compil_B.c
  trans/compil_C.c
  trans/compil_D.c
  trans/compile.c
  trans/compress.c
  trans/convert.c
  trans/datetime.c
  trans/dll.c
  trans/ec.c
  trans/emit.c
  trans/emit_0.c
  trans/emit_1.c
  trans/error.c
  trans/eumem.c
  trans/filesys.c
  trans/fwdref.c
  trans/fwdref_0.c
  trans/get.c
  trans/init-.c
  trans/inline.c
  trans/inline_0.c
  trans/machine.c
  trans/main-.c
  trans/main-0.c
  trans/main-1.c
  trans/main.c
  trans/map.c
  trans/math.c
  trans/memory.c
  trans/mode.c
  trans/parser.c
  trans/parser_0.c
  trans/parser_1.c
  trans/parser_2.c
  trans/parser_3.c
  trans/parser_4.c
  trans/parser_5.c
  trans/pathopen.c
  trans/platform.c
  trans/primes.c
  trans/scanne_0.c
  trans/scanne_1.c
  trans/scanner.c
  trans/scinot.c
  trans/search.c
  trans/shift.c
  trans/shift_0.c
  trans/sort.c
  trans/symtab.c
  trans/symtab_0.c
  trans/symtab_1.c
  trans/text.c
  trans/traninit.c
  trans/types.c
  trans/wildcard.c
)

SET( EU_BACKEND_SOURCES
  be_execute.c be_decompress.c be_task.c be_main.c be_alloc.c be_callc.c be_inline.c be_machine.c
  be_pcre.c be_socket.c be_rterror.c be_syncolor.c be_runtime.c be_symtab.c be_w.c
)

SET( EU_LIB_SOURCES
  be_decompress.c be_machine.c be_w.c be_alloc.c be_inline.c be_runtime.c be_task.c be_pcre.c be_socket.c
  be_callc.c
)

#
# Generators
#

FILE( MAKE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/int )

ADD_CUSTOM_COMMAND(
  OUTPUT ${EU_INTERPRETER_SOURCES} ${EU_CORE_SOURCES_INTERP}
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/int
  COMMAND ${TRANSLATOR} ${CMAKE_CURRENT_SOURCE_DIR}/int.ex
)

FILE( MAKE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/trans )

ADD_CUSTOM_COMMAND(
  OUTPUT ${EU_TRANSLATOR_SOURCES} ${EU_CORE_SOURCES_TRANS}
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/trans
  COMMAND ${TRANSLATOR} ${CMAKE_CURRENT_SOURCE_DIR}/ec.ex
)

FILE( MAKE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/back )

ADD_CUSTOM_COMMAND(
  OUTPUT ${EU_BACKEND_RUNNER_SOURCES}
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/back
  COMMAND ${TRANSLATOR} ${CMAKE_CURRENT_SOURCE_DIR}/backend.ex
)

#
# Targets
#


IF( WIN32 )
  ADD_EXECUTABLE( exwc WIN32 ${EU_CORE_SOURCES_INTERP} ${EU_INTERPRETER_SOURCES} ${EU_BACKEND_SOURCES} ${PCRE_SOURCES} )
  ADD_EXECUTABLE( exw WIN32 ${EU_CORE_SOURCES_INTERP} ${EU_INTERPRETER_SOURCES} ${EU_BACKEND_SOURCES} ${PCRE_SOURCES} )
  ADD_EXECUTABLE( ecw WIN32 ${EU_CORE_SOURCES_TRANS} ${EU_TRANSLATOR_SOURCES} ${EU_BACKEND_SOURCES} ${PCRE_SOURCES} )
  ADD_EXECUTABLE( backendw WIN32 ${EU_BACKEND_RUNNER_SOURCES} ${EU_BACKEND_SOURCES} ${PCRE_SOURCES} )
  ADD_EXECUTABLE( backendc WIN32 ${EU_BACKEND_RUNNER_SOURCES} ${EU_BACKEND_SOURCES} ${PCRE_SOURCES} )
  TARGET_LINK_LIBRARIES( exwc ws2_32 )
  TARGET_LINK_LIBRARIES( exw ws2_32 )
  TARGET_LINK_LIBRARIES( ecw ws2_32 )
  TARGET_LINK_LIBRARIES( backendw ws2_32 )
  TARGET_LINK_LIBRARIES( backendc ws2_32 )
  ADD_LIBRARY( ecwl STATIC ${EU_LIB_SOURCES} )
  SET_TARGET_PROPERTIES( ecwl PROPERTIES COMPILE_FLAGS -DERUNTIME )
ENDIF( WIN32)

IF( UNIX )
  ADD_EXECUTABLE( exu ${EU_CORE_SOURCES_INTERP} ${EU_INTERPRETER_SOURCES} ${EU_BACKEND_SOURCES} )
  ADD_EXECUTABLE( ecu ${EU_CORE_SOURCES_TRANS} ${EU_TRANSLATOR_SOURCES} ${EU_BACKEND_SOURCES} )
  ADD_EXECUTABLE( backendu ${EU_BACKEND_RUNNER_SOURCES} ${EU_BACKEND_SOURCES} )
  ADD_LIBRARY( ecul STATIC ${EU_LIB_SOURCES} )
  SET_TARGET_PROPERTIES( ecul PROPERTIES COMPILE_FLAGS -DERUNTIME )
ENDIF( UNIX )

IF( WIN32 )
  IF( WATCOM )
    SET_TARGET_PROPERTIES( exw PROPERTIES LINK_FLAGS " SYS nt_win " )
    SET_TARGET_PROPERTIES( backendw PROPERTIES LINK_FLAGS " SYS nt_win " )
  ENDIF( WATCOM )

  SET_TARGET_PROPERTIES( backendc PROPERTIES COMPILE_FLAGS -DEBACKEND )
  SET_TARGET_PROPERTIES( backendw PROPERTIES COMPILE_FLAGS -DEBACKEND )
ENDIF( WIN32 )

IF( UNIX )
  SET_TARGET_PROPERTIES( backendu PROPERTIES COMPILE_FLAGS -DEBACKEND )
ENDIF( UNIX )

# ADD_DEFINITIONS( -DERUNTIME )
# ADD_LIBRARY( $(EULIB) STATIC ${EU_LIB_SOURCES} )
