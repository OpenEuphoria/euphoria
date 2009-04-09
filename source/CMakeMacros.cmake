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

IF( WIN32 )
  # Window specific definitions
  ADD_DEFINITIONS( -DEWINDOWS )

  # Special compiler definitions
  IF( MINGW )
    ADD_DEFINITIONS( -DEMINGW -O3 -Os -ffast-math -mno-cygwin -mwindows )
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
