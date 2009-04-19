#
# source directory builds
#

#
# Source Compile Options
#

IF( USE_INT_CODES )
  ADD_DEFINITIONS( -DINT_CODES )
ENDIF()

IF( USE_MANAGED_MEM )
  ADD_DEFINITIONS( -DEU_MANAGED_MEM )
ELSE()
  ADD_DEFINITIONS( -DESIMPLE_MALLOC )
ENDIF()

IF( ENABLE_DEBUG )
  ADD_DEFINITIONS( -DEDEBUG )
ENDIF()

IF( BUILD_RELEASE )
  ADD_DEFINITIONS( -DEU_FULL_RELEASE )
ENDIF()

#
# Include our Euphoria macros
#

INCLUDE( CMakeMacros.cmake )

#
# Euphoria source requirements
#

INCLUDE(CheckFunctionExists)
CHECK_FUNCTION_EXISTS(strncpy HAS_STRNCPY)
CHECK_FUNCTION_EXISTS(strncat HAS_STRNCAT)
CHECK_FUNCTION_EXISTS(strlcpy HAS_STRLCPY)
CHECK_FUNCTION_EXISTS(strlcat HAS_STRLCAT)
CHECK_FUNCTION_EXISTS(snprintf HAS_SNPRINTF)
CHECK_FUNCTION_EXISTS(_snprintf HAS__SNPRINTF)

#
# Generators
#

FILE( GLOB PCRE_SOURCES "pcre/*.c" )

CONFIGURE_FILE( version.h.in version.h )

IF( WATCOM )
  # We have some tricky things we do with the jump table, we must call
  # findjmp.ex in order to pre-determine the jump table.
  ADD_CUSTOM_COMMAND(
    OUTPUT be_magic.c
    DEPENDS eu_back
    COMMAND
      ${INTERPRETER} "${CMAKE_SOURCE_DIR}/source/findjmp.ex"
      "${CMAKE_CURRENT_BINARY_DIR}/be_magic.c"
      "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/eu_back.dir/be_execute.obj" )

  ADD_LIBRARY( eu_back_magic STATIC be_magic.c )
  LIST( APPEND EXTRA_LIBS "eu_back_magic" )
ENDIF()

INCLUDE_DIRECTORIES( "${CMAKE_CURRENT_BINARY_DIR}" )
INCLUDE_DIRECTORIES( "${CMAKE_BINARY_DIR}" )
INCLUDE_DIRECTORIES( "$ENV{EUDIR}" )

ADD_CUSTOM_COMMAND(
	OUTPUT be_rev.c
	COMMAND ${INTERPRETER} "${CMAKE_SOURCE_DIR}/source/revget.ex"
	WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}" )

#
# Targets
#

# Core files (backend, translator and interpreter)
SET( EU_CORE_FILES block.e common.e emit.e error.e fwdref.e global.e inline.e keylist.e main.e mode.e
  opnames.e parser.e pathopen.e platform.e reswords.e scanner.e scinot.e shift.e symtab.e )

# Temporary backend library
SET( EU_BACKEND_SOURCES be_alloc.c be_callc.c be_decompress.c be_execute.c be_inline.c
  be_machine.c be_main.c be_pcre.c be_rev.c be_rterror.c be_runtime.c be_socket.c be_symtab.c
  be_syncolor.c be_task.c be_w.c version.h )
ADD_LIBRARY( eu_back STATIC ${EU_BACKEND_SOURCES} ${PCRE_SOURCES} )

# Euphoria runtime library
SET( EU_LIB_SOURCES be_alloc.c be_callc.c be_decompress.c be_inline.c be_machine.c be_pcre.c
  be_rev.c be_runtime.c be_socket.c be_task.c be_w.c version.h ${PCRE_SOURCES} )
ADD_LIBRARY( eu STATIC ${EU_LIB_SOURCES} )
SET_TARGET_PROPERTIES( eu PROPERTIES COMPILE_FLAGS -DERUNTIME=1 )

INSTALL( TARGETS eu ARCHIVE DESTINATION bin COMPONENT core )

#
# Interpreter
#

SET( EU_INTERPRETER_FILES int.ex compress.e backend.e c_out.e cominit.e intinit.e )

IF( USE_AMALGAMATION )
  ADD_CUSTOM_COMMAND(
    OUTPUT int.c int.h
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMAND ${TRANSLATOR} -con -am ${CMAKE_CURRENT_SOURCE_DIR}/int.ex
    DEPENDS ${EU_INTERPRETER_FILES} ${EU_CORE_FILES} )
  SET( INT_SOURCES int.c )
ELSE()
  EUC( "${EU_CORE_FILES};${EU_INTERPRETER_FILES}" "int" )
ENDIF()

ADD_EXECUTABLE( eui ${EXECUTABLE_FLAG} ${INT_SOURCES} )
TARGET_LINK_LIBRARIES( eui eu_back ${EXTRA_LIBS} )
IF( LINK_FLAGS )
  SET_TARGET_PROPERTIES( eui  PROPERTIES LINK_FLAGS ${LINK_FLAGS} )
ENDIF()

INSTALL( TARGETS eui RUNTIME DESTINATION bin COMPONENT core )


#
# Translator
#

SET( EU_TRANSLATOR_FILES ec.ex compile.e ec.ex c_decl.e c_out.e cominit.e traninit.e compress.e )
IF( USE_AMALGAMATION )
  ADD_CUSTOM_COMMAND(
    OUTPUT ec.c ec.h
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMAND ${TRANSLATOR} -con -am ${CMAKE_CURRENT_SOURCE_DIR}/ec.ex
    DEPENDS ${EU_TRANSLATOR_FILES} ${EU_CORE_FILES} )
  SET( EC_SOURCES ec.c ec.h )
ELSE()
  EUC( "${EU_CORE_FILES};${EU_TRANSLATOR_FILES}" "ec" )
ENDIF()

ADD_EXECUTABLE( euc ${EXECUTABLE_FLAG} ${EC_SOURCES} )
TARGET_LINK_LIBRARIES( euc eu_back ${EXTRA_LIBS} )
IF( LINK_FLAGS )
  SET_TARGET_PROPERTIES( euc  PROPERTIES LINK_FLAGS ${LINK_FLAGS} )
ENDIF()

INSTALL( TARGETS euc RUNTIME DESTINATION bin COMPONENT core )

#
# Backend
#

SET( EU_BACKEND_RUNNER_FILES backend.ex compress.e reswords.e common.e cominit.e pathopen.e )
IF( USE_AMALGAMATION )
  ADD_CUSTOM_COMMAND(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/backend.c ${CMAKE_CURRENT_BINARY_DIR}/backend.h
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMAND ${TRANSLATOR} -con -am ${CMAKE_CURRENT_SOURCE_DIR}/backend.ex
    DEPENDS ${EU_BACKEND_RUNNER_FILES} ${EU_CORE_FILES} )
  SET( BACKEND_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/backend.c" )
ELSE()
  EUC( "${EU_CORE_FILES};${EU_BACKEND_RUNNER_FILES}" "backend" )
ENDIF()
ADD_EXECUTABLE( eub ${EXECUTABLE_FLAG} ${BACKEND_SOURCES} )
TARGET_LINK_LIBRARIES( eub eu_back ${EXTRA_LIBS} )
IF( LINK_FLAGS )
  SET_TARGET_PROPERTIES( eub  PROPERTIES LINK_FLAGS ${LINK_FLAGS} )
ENDIF()

INSTALL( TARGETS eub RUNTIME DESTINATION bin COMPONENT core )

#
# Tools
#

IF( BUILD_TOOLS )
  IF( USE_AMALGAMATION )
    ADD_CUSTOM_COMMAND(
      OUTPUT eutest.c eutest.h
      WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
      COMMAND ${TRANSLATOR} -con -am ${CMAKE_CURRENT_SOURCE_DIR}/eutest.ex
      DEPENDS eutest.ex )
    SET( EUTEST_SOURCES eutest.c )
  ELSE()
    EUC( eutest.ex eutest )
  ENDIF()

  ADD_EXECUTABLE( eutest ${EXECUTABLE_FLAG} ${EUTEST_SOURCES} )
  TARGET_LINK_LIBRARIES( eutest eu_back ${EXTRA_LIBS} )
  IF( LINK_FLAGS )
    SET_TARGET_PROPERTIES( eutest PROPERTIES LINK_FLAGS ${LINK_FLAGS} )
  ENDIF()

  INSTALL( TARGETS eutest RUNTIME DESTINATION bin COMPONENT tool )
ENDIF()

#
# Docs
#

IF( BUILD_DOCS )
  MESSAGE( "Document target is not yet written" )
ENDIF()
